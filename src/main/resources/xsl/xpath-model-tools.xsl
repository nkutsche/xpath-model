<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:nk="http://www.nkutsche.com/xpath-model" xmlns:math="http://www.w3.org/2005/xpath-functions/math"
    xmlns:p="http://www.nkutsche.com/xpath-parser" xmlns:map="http://www.w3.org/2005/xpath-functions/map"
    xmlns:err="http://www.w3.org/2005/xqt-errors" xmlns:avt="http://www.nkutsche.com/avt-parser"
    exclude-result-prefixes="#all" version="3.0">


    <xsl:key name="xsdecl-uriqname" match="xs:element[@name] | xs:attribute[@name]"
        use="
            @name/nk:xsdqname(.) ! nk:qname-matcher(.)
            "/>

    <xsl:key name="xsdref-uriqname" match="xs:element[@ref] | xs:attribute[@ref]"
        use="
            @ref/xs:QName(.)
            "/>
    <xsl:key name="xsd_group_ref-uriqname" match="xs:group[@ref]" use="@ref/xs:QName(.)"/>

    <xsl:key name="xsd_agroup_ref-uriqname" match="xs:attributeGroup[@ref]" use="@ref/xs:QName(.)"/>

    <xsl:key name="xsd_type_ref-uriqname" match="xs:element[@type] | xs:complexContent/xs:extension[@base]"
        use="(@type/xs:QName(.), @base/xs:QName(.))[1]"/>


    <xsl:function name="nk:get-schema-decl" as="element()*">
        <xsl:param name="nodeTest" as="element(nodeTest)"/>
        <xsl:param name="schema" as="element(xs:schema)*"/>
        <xsl:param name="exprContext" as="node()"/>
        <xsl:sequence select="nk:get-schema-decl($nodeTest, $schema, $exprContext, nk:xsl-context#2)"/>
    </xsl:function>

    <!--
    Returns all possible XSD declarations for a given $noteTest from a given $schema 
        Special cases:
        - If the nodeTest matches on non-declared nodes (text(), comment(), etc.), it returns a <nk:no-decl-needed/>.
        - If no matching declaration is available it returns an empty sequence.
        
        Other parameters:
        $exprContextNode as node() 
            => node to provide the context for the XPath expression which contains the nodeTest
        $contextGenerator as function(node(), element(expr)?)
            => function which converts context nodes into context object - a map with 
               the following fields:
               - 'parent' as function() as map(*)* - function which returns the next parent context object,
               - 'variable-context' as function($variableName as xs:QName) as map(*)? 
                    - function which returns the context object for a variable with the name $variableName ,
               - 'expr' as element()? - parsed XPath expression of the given context node,
                'node' as node()? - given context node
        
    -->
    <xsl:function name="nk:get-schema-decl" as="element()*">
        <xsl:param name="nodeTest" as="element(nodeTest)"/>
        <xsl:param name="schema" as="element(xs:schema)*"/>
        <xsl:param name="exprContextNode" as="node()"/>
        <xsl:param name="contextGenerator" as="function(node(), element(expr)?) as map(xs:string, item()*)"/>

        <xsl:variable name="name" select="($nodeTest/@name, '*')[1]"/>
        <xsl:variable name="kind" select="$nodeTest/@kind"/>
        <xsl:variable name="uriqname"
            select="
                if ($name castable as xs:QName)
                then
                    nk:uriqname(xs:QName($name))
                else
                    (: handles patterns like 'pfx:*' :)
                    if (matches($name, '^[^\*:]+:\*'))
                    then
                        'Q{' || $nodeTest/namespace::*[name() = substring-before($name, ':')] || '}*'
                    else
                        $name"/>

        <xsl:variable name="declCandidates" select="$schema/key('xsdecl-uriqname', $uriqname)"/>
        <xsl:choose>
            <!-- ToDO: foo/text() -> can foo contain text? -->
            <xsl:when test="$kind = 'text'">
                <nk:no-decl-needed kind="{$kind}"/>
            </xsl:when>
            <xsl:when
                test="not($kind = ('element', 'atttribute', 'document-node', 'schema-element', 'schema-attribute'))">
                <nk:no-decl-needed kind="{$kind}"/>
            </xsl:when>
            <xsl:when test="$kind = 'document-node'">
                <!-- ToDO: document-node(foo) -> does we have to respect this? -->
                <nk:no-decl-needed kind="{$kind}"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:variable name="declCandidates"
                    select="
                        $declCandidates/(if ($kind = ('attribute', 'schema-attribute')) then
                            self::xs:attribute
                        else
                            self::xs:element)
                        "/>
                <xsl:choose>
                    <xsl:when test="count($declCandidates) = 0"/>
                    <xsl:otherwise>
                        <xsl:variable name="context-provider"
                            select="nk:get-context-provider($nodeTest, $contextGenerator($exprContextNode, $nodeTest/ancestor::expr))"/>
                        <xsl:variable name="globalDecl" select="$declCandidates[parent::xs:schema]"/>


                        <xsl:variable name="locationStep" select="$nodeTest/parent::locationStep"/>
                        <xsl:choose>
                            <xsl:when test="empty($context-provider)">
                                <xsl:sequence select="$declCandidates"/>
                            </xsl:when>
                            <xsl:when
                                test="
                                    every $cp in $context-provider
                                        satisfies $cp?root-required">
                                <xsl:sequence select="$globalDecl"/>
                            </xsl:when>
                            <xsl:when test="not($locationStep)">
                                <xsl:sequence select="$declCandidates"/>
                            </xsl:when>
                            <xsl:when
                                test="
                                    every $cp in $context-provider
                                        satisfies exists($cp?nodeTest)
                                    ">
                                <xsl:variable name="context-schema-decl"
                                    select="
                                        for $cp in
                                        $context-provider
                                        return
                                            $cp?nodeTest ! nk:get-schema-decl(., $schema, $cp?context?node, $contextGenerator)
                                        "
                                    as="element()*"/>
                                <xsl:sequence
                                    select="
                                        $declCandidates[
                                        some $csd in $context-schema-decl
                                            satisfies
                                            nk:path-in-xsd-possible($csd, ., $locationStep/@axis)
                                        ]"
                                />
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:sequence select="$declCandidates"/>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>

    <xsl:function name="nk:path-in-xsd-possible" as="xs:boolean">
        <xsl:param name="from" as="element()"/>
        <xsl:param name="to" as="element()"/>
        <xsl:param name="axis" as="xs:string"/>
        <xsl:sequence select="nk:path-in-xsd-possible($from, $to, $axis, ())"/>
    </xsl:function>

    <xsl:function name="nk:path-in-xsd-possible" as="xs:boolean">
        <xsl:param name="from" as="element()"/>
        <xsl:param name="to" as="element()"/>
        <xsl:param name="axis" as="xs:string"/>
        <xsl:param name="ignores" as="element()*"/>

        <xsl:variable name="from-parents" select="
                $from/nk:get-usages(.)
                "/>
        <xsl:variable name="to-parents" select="
                $to/nk:get-usages(.)
                "/>

        <xsl:variable name="from-is-parent" select="exists($to-parents intersect $from)" as="xs:boolean"/>
        <xsl:variable name="to-is-parent" select="exists($from-parents intersect $to)" as="xs:boolean"/>
        <xsl:choose>
            <xsl:when test="($from | $to)/nk:no-decl-needed">
                <xsl:sequence select="true()"/>
            </xsl:when>
            <xsl:when test="$axis = 'self'">
                <xsl:sequence select="$from is $to"/>
            </xsl:when>
            <xsl:when test="$axis = 'attribute'">
                <xsl:sequence select="$to/self::xs:attribute and $from-is-parent"/>
            </xsl:when>
            <xsl:when test="$axis = 'child'">
                <xsl:sequence select="$to/self::xs:element and $from-is-parent"/>
            </xsl:when>
            <xsl:when test="$axis = 'parent'">
                <xsl:sequence select="$to-is-parent"/>
            </xsl:when>
            <xsl:when test="$axis = ('preceding-sibling', 'following-sibling')">
                <xsl:sequence select="exists($from-parents intersect $to-parents)"/>
            </xsl:when>
            <xsl:when test="$axis = 'descendant'">
                <xsl:sequence
                    select="
                        $from-is-parent or (
                        some $tp in ($to-parents except $ignores)
                            satisfies
                            nk:path-in-xsd-possible($from, $tp, $axis, ($to-parents, $ignores))
                        )"
                />
            </xsl:when>
            <xsl:when test="$axis = 'ancestor'">
                <xsl:sequence select="nk:path-in-xsd-possible($to, $from, 'descendant')"/>
            </xsl:when>
            <xsl:when test="$axis = 'descendant-or-self'">
                <xsl:sequence
                    select="
                        nk:path-in-xsd-possible($from, $to, 'descendant')
                        or
                        nk:path-in-xsd-possible($from, $to, 'self')
                        "
                />
            </xsl:when>
            <xsl:when test="$axis = 'ancestor'">
                <xsl:sequence select="nk:path-in-xsd-possible($to, $from, 'descendant')"/>
            </xsl:when>
            <xsl:when test="$axis = 'ancestor-or-self'">
                <xsl:sequence
                    select="
                        nk:path-in-xsd-possible($from, $to, 'ancestor')
                        or
                        nk:path-in-xsd-possible($from, $to, 'self')
                        "
                />
            </xsl:when>
            <xsl:otherwise>
                <xsl:sequence select="true()"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>

    <xsl:function name="nk:get-usages" as="element()*">
        <xsl:param name="decl" as="element()"/>
        <xsl:variable name="name" select="$decl/nk:xsdqname(@name)"/>
        <xsl:variable name="next-parent"
            select="
                if ($decl/parent::xs:schema) then
                    $decl/key('xsdref-uriqname', $name)
                else
                    $decl/parent::*
                "/>
        <xsl:apply-templates select="$next-parent" mode="nk:get-usages"/>
    </xsl:function>

    <xsl:template match="xs:group[@name]" mode="nk:get-usages">
        <xsl:apply-templates select="key('xsd_group_ref-uriqname', nk:xsdqname(@name))" mode="#current"/>
    </xsl:template>

    <xsl:template match="xs:schema/xs:complexType[@name]" mode="nk:get-usages">
        <xsl:apply-templates select="key('xsd_type_ref-uriqname', nk:xsdqname(@name))" mode="#current"/>
    </xsl:template>

    <xsl:template match="xs:schema/xs:attributeGroup[@name]" mode="nk:get-usages">
        <xsl:apply-templates select="key('xsd_agroup_ref-uriqname', nk:xsdqname(@name))" mode="#current"/>
    </xsl:template>

    <xsl:template match="xs:element[@name]" mode="nk:get-usages">
        <xsl:sequence select="."/>
    </xsl:template>

    <xsl:template match="*" mode="nk:get-usages">
        <xsl:apply-templates select="parent::*" mode="#current"/>
    </xsl:template>



    <xsl:function name="nk:xsdqname" as="xs:QName">
        <xsl:param name="name" as="attribute(name)"/>
        <xsl:variable name="declEl" select="$name/parent::*"/>
        <xsl:variable name="schema" select="$declEl/ancestor-or-self::xs:schema"/>
        <xsl:variable name="formDefault"
            select="
                if ($declEl/self::xs:element) then
                    $schema/@elementFormDefault
                else
                    $schema/@attributeFormDefault
                "/>
        <xsl:variable name="form"
            select="
                if ($declEl/parent::xs:schema) then
                    'qualified'
                else
                    ($declEl/@form, $formDefault, 'unqualified')[1]"/>
        <xsl:variable name="trgNamespace"
            select="
                ($schema/@targetNamespace[$form = 'qualified'], '')[1]
                "/>
        <xsl:sequence select="QName($trgNamespace, $name)"/>
    </xsl:function>

    <xsl:function name="nk:uriqname" as="xs:string">
        <xsl:param name="qname" as="xs:QName"/>
        <xsl:sequence
            select="'Q{' || namespace-uri-from-QName($qname) || '}' || local-name-from-QName($qname)"/>
    </xsl:function>

    <xsl:function name="nk:qname-matcher" as="xs:string*">
        <xsl:param name="qname" as="xs:QName"/>
        <xsl:sequence
            select="
                nk:uriqname($qname),
                'Q{' || namespace-uri-from-QName($qname) || '}*',
                '*:' || local-name-from-QName($qname),
                '*'
                
                "
        />
    </xsl:function>


    <xsl:function name="nk:get-context-provider" as="map(*)*">
        <xsl:param name="nodeTest" as="element()"/>
        <xsl:param name="exprContext" as="map(*)"/>

        <xsl:variable name="provider" as="element()*">
            <xsl:apply-templates select="$nodeTest" mode="nk:get-context-provider"/>
        </xsl:variable>

        <xsl:sequence select="$provider/nk:context-provider-handler(., $exprContext)"/>

    </xsl:function>

    <xsl:variable name="unspecified" as="element()">
        <nk:unspecified/>
    </xsl:variable>

    <xsl:function name="nk:xsl-context" as="map(xs:string, item()*)" xpath-default-namespace="">
        <xsl:param name="node" as="node()"/>
        <xsl:param name="expr" as="element(expr)?"/>

        <xsl:variable name="anc" select="$node/ancestor::xsl:*"/>
        <xsl:variable name="anc" select="$anc except $anc/ancestor-or-self::xsl:analyze-string"/>
        <xsl:variable name="context"
            select="$anc[local-name() = ('for-each', 'for-each-group', 'key', 'template')][last()]"/>


        <xsl:variable name="local-variables"
            select="
                $node/ancestor-or-self::*/
                (preceding-sibling::xsl:variable | preceding-sibling::xsl:param)
                "/>
        <xsl:variable name="global-variables"
            select="$anc[not(parent::*)]/(xsl:variable | xsl:param) except $node"/>

        <xsl:variable name="var-scope"
            select="($global-variables, $local-variables) ! map{xs:QName(@name) : .}"/>
        <xsl:variable name="var-scope" select="$var-scope => map:merge(map{'duplicates' : 'use-last'})"/>

        <xsl:variable name="xpm-config-gen"
            select="function($ctx){
                let $namespaces := $ctx/namespace::*/map{name() : string(.)},
                $default-ns := ('', $ctx/ancestor-or-self::*/(@xsl:xpath-default-namespace | self::xsl:*/@xpath-default-namespace))[last()]
                return
                    map{
                        'namespaces' : map:put(map:merge($namespaces), '', $default-ns)
                    }
            }"/>
        <!--                
        variable-context : function(element()) as map(+context-info+)
        parent : function() as map(+context-info+)
        expr : element(expr)
        -->
        <xsl:sequence
            select="map{
                'parent' : function(){
                    $context/(@select|@match)/nk:xsl-context(., nk:xpath-model(., $xpm-config-gen(.)))
                },
                'variable-context' : function($variableName as xs:QName){
                    $var-scope ! .($variableName)/@select/nk:xsl-context(., nk:xpath-model(., $xpm-config-gen(.)))
                },
                'expr' : $expr,
                'node' : $node
            
            }"/>

    </xsl:function>

    <xsl:function name="nk:context-provider-handler" as="map(*)*">
        <xsl:param name="provider" as="element()"/>
        <xsl:param name="exprContext" as="map(*)"/>

        <xsl:choose>
            <xsl:when test="$provider/self::self">
                <xsl:sequence select="nk:get-context-provider($provider, $exprContext)"/>
            </xsl:when>
            <xsl:when test="$provider/self::varRef">
                <xsl:variable name="varname" select="xs:QName($provider/@name)"/>
                <xsl:variable name="variable-decl-info" select="$exprContext?variable-context($varname)"/>
                <xsl:choose>
                    <xsl:when test="exists($variable-decl-info)">
                        <xsl:variable name="var-expr" select="$variable-decl-info?expr"/>
                        <xsl:variable name="var-return" select="$var-expr/nk:get-return-from-expr(.)"/>
                        <xsl:sequence select="nk:context-provider-handler($var-return, $variable-decl-info)"/>
                    </xsl:when>
                    <xsl:otherwise expand-text="true">
                        <xsl:sequence
                            select="map{
                                'nodeTest' : (),
                                'root-required' : false(),
                                'reason' : 'variable-' || $varname || '-not-declared',
                                'context' : $exprContext
                            }"
                        />
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <xsl:when test="$provider/self::expr">
                <xsl:variable name="parentExpr" select="$exprContext?parent()"/>
                <xsl:variable name="returnedObj" select="$parentExpr?expr/nk:get-return-from-expr(.)"/>
                <xsl:choose>
                    <xsl:when test="empty($parentExpr)">
                        <xsl:sequence
                            select="map{
                                'nodeTest' : (),
                                'root-required' : false(),
                                'reason' : 'no-parent-expression-provides-a-context',
                                'context' : $exprContext,
                                'pathObj' : ()
                            }"
                        />
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:for-each select="$returnedObj">
                            <xsl:choose>
                                <xsl:when test="self::self">
                                    <xsl:sequence select="nk:get-context-provider($returnedObj, $parentExpr)"
                                    />
                                </xsl:when>
                                <xsl:when test="self::nodeTest">
                                    <xsl:sequence
                                        select="map{
                                            'nodeTest' : .,
                                            'root-required' : false(),
                                            'context' : $exprContext,
                                            'pathObj' : .
                                        }"
                                    />
                                </xsl:when>
                                <xsl:when test="self::slash | self::root">
                                    <xsl:sequence
                                        select="map{
                                            'nodeTest' : (),
                                            'root-required' : true(),
                                            'reason' : 'root-is-expected',
                                            'context' : $exprContext,
                                            'pathObj' : .
                                        }"
                                    />
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:variable name="names"
                                        select="$returnedObj/name() => distinct-values() => string-join('|')"/>
                                    <xsl:sequence
                                        select="map{
                                            'nodeTest' : (),
                                            'root-required' : false(),
                                            'reason' : $names || '-is-context-provider',
                                            'context' : $exprContext,
                                            'pathObj' : .
                                        }
                                        "
                                    />
                                </xsl:otherwise>
                            </xsl:choose>
                        </xsl:for-each>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <xsl:when test="$provider/self::nodeTest">
                <xsl:sequence
                    select="map{
                        'nodeTest' : $provider,
                        'root-required' : false(),
                        'context' : $exprContext,
                        'pathObj' : $provider
                    }"
                />
            </xsl:when>
            <xsl:when test="$provider/self::slash | $provider/self::root">
                <xsl:sequence
                    select="map{
                        'nodeTest' : (),
                        'root-required' : true(),
                        'reason' : 'root-is-expected',
                        'context' : $exprContext,
                        'pathObj' : $provider
                    }"
                />
            </xsl:when>
            <xsl:otherwise>
                <xsl:variable name="names" select="$provider/name() => distinct-values() => string-join('|')"/>
                <xsl:sequence
                    select="map{
                        'nodeTest' : (),
                        'root-required' : false(),
                        'reason' : $names || '-is-context-provider',
                        'context' : $exprContext,
                        'pathObj' : $provider
                    }
                    "
                />
            </xsl:otherwise>
        </xsl:choose>

    </xsl:function>

    <xsl:template match="itemType" mode="nk:get-context-provider">
        <xsl:sequence select="$unspecified"/>
    </xsl:template>

    <xsl:template match="operation[@type = ('map', 'step')]/arg[preceding-sibling::arg]"
        mode="nk:get-context-provider" priority="30">
        <xsl:variable name="next-arg" select="preceding-sibling::arg[1]"/>
        <xsl:sequence select="nk:get-return-from-expr($next-arg/*)"/>
    </xsl:template>

    <xsl:template match="operation[@type = ('map', 'step')]/arg[preceding-sibling::slash]"
        mode="nk:get-context-provider" priority="20">
        <xsl:sequence select="preceding-sibling::slash"/>
    </xsl:template>

    <xsl:template match="locationStep/predicate" mode="nk:get-context-provider">
        <xsl:sequence select="nk:get-return-from-expr(parent::locationStep)"/>
    </xsl:template>

    <xsl:template match="operation[@type = 'postfix']/predicate" mode="nk:get-context-provider">
        <xsl:variable name="precPostfix"
            select="(preceding-sibling::* except preceding-sibling::predicate)[last()]"/>

        <xsl:sequence
            select="
                if ($precPostfix/self::arg) then
                    nk:get-return-from-expr($precPostfix)
                else
                    $precPostfix
                "
        />
    </xsl:template>

    <xsl:template match="*" mode="nk:get-context-provider" priority="-10">
        <xsl:apply-templates select="parent::*" mode="#current"/>
    </xsl:template>

    <xsl:template match="expr" mode="nk:get-context-provider">
        <xsl:sequence select="."/>
    </xsl:template>




    <xsl:function name="nk:get-return-from-expr" as="element()*">
        <xsl:param name="expr-content" as="element()"/>
        <xsl:apply-templates select="$expr-content" mode="nk:get-return-from-expr"/>
    </xsl:function>

    <xsl:template
        match="
            string | integer | decimal | double | varRef | empty | self | root
            | function-call
            | function
            | lookup
            | map
            | array
            | function-impl
            | locationStep/nodeTest
            | operation[@type = (
            'or',
            'and',
            'compare',
            'value-compare',
            'node-compare',
            'concat',
            'range',
            'additive',
            'multiplicativ',
            'instance-of',
            'castable',
            'some-satisfies',
            'every-satisfies',
            'unary'
            )]
            "
        mode="nk:get-return-from-expr">
        <xsl:sequence select="."/>
    </xsl:template>

    <xsl:template match="locationStep" mode="nk:get-return-from-expr">
        <xsl:apply-templates select="nodeTest" mode="#current"/>
    </xsl:template>

    <xsl:template match="operation[@type = 'postfix'][lookup | function-call]" mode="nk:get-return-from-expr"
        priority="10">
        <xsl:apply-templates select="(lookup | function-call)[last()]" mode="#current"/>
    </xsl:template>

    <xsl:template
        match="
            operation[@type = (
            'step',
            'map',
            'for-loop',
            'let-binding',
            'postfix',
            'treat-as',
            'cast'
            )]"
        mode="nk:get-return-from-expr">
        <xsl:apply-templates select="arg[last()]" mode="#current"/>
    </xsl:template>

    <xsl:template match="operation[@type = ('sequence', 'union')]" mode="nk:get-return-from-expr">
        <xsl:apply-templates select="arg" mode="#current"/>
    </xsl:template>

    <xsl:template match="operation[@type = 'condition']" mode="nk:get-return-from-expr">
        <xsl:apply-templates select="arg[@role = ('then', 'else')]" mode="#current"/>
    </xsl:template>

    <xsl:template match="operation[@type = 'intersect-except']" mode="nk:get-return-from-expr">

        <xsl:for-each-group select="*" group-ending-with="intersect">
            <xsl:variable name="args" select="current-group()/self::arg"/>
            <xsl:variable name="excepts" select="current-group()/self::except/following::arg"/>
            <xsl:apply-templates select="$args except $excepts" mode="#current"/>
        </xsl:for-each-group>

    </xsl:template>

    <xsl:template match="operation[@type = 'arrow']" mode="nk:get-return-from-expr">
        <xsl:apply-templates select="function-call[last()]" mode="#current"/>
    </xsl:template>

    <xsl:template match="value-template" mode="nk:get-return-from-expr">
        <xsl:apply-templates select="expr" mode="#current"/>
    </xsl:template>


    <xsl:template match="*" mode="nk:get-return-from-expr" priority="-10">
        <xsl:apply-templates select="*" mode="#current"/>
    </xsl:template>







</xsl:stylesheet>
