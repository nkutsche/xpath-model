<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:nk="http://www.nkutsche.com/xpath-model" xmlns:math="http://www.w3.org/2005/xpath-functions/math"
    xmlns:p="http://www.nkutsche.com/xpath-parser" xmlns:map="http://www.w3.org/2005/xpath-functions/map"
    xmlns:err="http://www.w3.org/2005/xqt-errors" xmlns:avt="http://www.nkutsche.com/avt-parser"
    xmlns:array="http://www.w3.org/2005/xpath-functions/array"
    xmlns:xpe="http://www.nkutsche.com/xpath-model/engine"
    xmlns:sch="http://purl.oclc.org/dsdl/schematron"
    xmlns:sqf="http://www.schematron-quickfix.com/validator/process" exclude-result-prefixes="#all"
    version="3.0">


    <xsl:function name="nk:get-path-in-expression" as="array(map(xs:string, xs:string))*" visibility="final">
        <xsl:param name="nodeTest" as="element(nodeTest)"/>
        <xsl:param name="exprContext" as="map(*)"/>

        <xsl:variable name="context-provider" select="nk:get-context-provider($nodeTest, $exprContext)"/>

        <xsl:variable name="axis" select="($nodeTest/parent::locationStep/@axis, 'self')[1]"/>
        <xsl:variable name="name-matcher" select="$nodeTest/nk:name-matcher(@name)"/>
        <xsl:variable name="kind" select="($nodeTest/@kind, 'node')[1]"/>

        <xsl:variable name="step"
            select="
            map{
                'axis': string($axis), 
                'local-name' : $name-matcher?local,
                'namespace' : $name-matcher?namespace,
                'kind' : string($kind)
            }"/>


        <xsl:for-each select="$context-provider">
            <xsl:choose>
                <xsl:when test="?nodeTest">
                    <xsl:variable name="nodeTest" select="?nodeTest"/>
                    <xsl:variable name="context" select="?context"/>

                    <xsl:variable name="parent-paths"
                        select="
                            nk:get-path-in-expression($nodeTest, $context)
                            "/>
                    <xsl:sequence select="$parent-paths ! array:append(., $step)"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:variable name="start-kind"
                        select="
                            if (?root-required) then
                                ('document-node')
                            else
                                ('node')
                            "/>
                    <xsl:variable name="start-axis"
                        select="
                            if (?unknown-context) then
                                'unknown'
                            else
                                'start'
                            "/>
                    <xsl:sequence
                        select="[map{
                            'axis': $start-axis, 
                            'local-name' : '*',
                            'namespace' : '*',
                            'kind' : $start-kind
                            },
                            $step]"
                    />
                </xsl:otherwise>
            </xsl:choose>
        </xsl:for-each>

    </xsl:function>


    <xsl:function name="nk:serialize-steps" as="xs:string" visibility="final">
        <xsl:param name="steps" as="array(map(xs:string, xs:string))"/>
        <xsl:sequence select="nk:serialize-steps($steps, map{'' : ''})"/>
    </xsl:function>

    <xsl:function name="nk:serialize-steps" as="xs:string" visibility="final">
        <xsl:param name="steps" as="array(map(xs:string, xs:string))"/>
        <xsl:param name="namespaces" as="map(xs:string, xs:string)"/>
        <xsl:sequence select="$steps?* ! nk:serialize-step(., $namespaces) => string-join('/')"/>
    </xsl:function>
    <xsl:function name="nk:serialize-step" as="xs:string?">
        <xsl:param name="step" as="map(xs:string, xs:string)"/>
        <xsl:param name="namespaces" as="map(xs:string, xs:string)"/>

        <xsl:variable name="namespaces"
            select="
            map:merge((map{'':''}, $namespaces))
            "/>
        <xsl:variable name="kind" select="$step?kind"/>
        <xsl:variable name="axis" select="$step?axis"/>
        <xsl:variable name="local-name" select="$step?local-name"/>
        <xsl:variable name="namespace" select="$step?namespace"/>

        <xsl:variable name="isAttribute" select="distinct-values(($kind, $axis)) = 'attribute'"/>


        <xsl:variable name="axis-part"
            select="
                if ($step?axis = 'child') then
                    ''
                else
                    if ($isAttribute) then
                        '@'
                    else
                        $step?axis || '::'"/>
        <xsl:variable name="ns-part"
            select="
                if ($namespace = '*') then
                    ('*:')
                else
                    if ($namespaces?* = $namespace)
                    then
                        map:keys($namespaces)[$namespaces(.) = $namespace][1] || ':'
                    else
                        'Q{' || $namespace || '}'
                "/>
        <xsl:variable name="ns-part" select="($ns-part[. != ':'], '')[1]"/>
        <xsl:variable name="name-part" select="
                $ns-part || $local-name
                "/>
        <xsl:variable name="nodeTest"
            select="
                if ($kind = 'element' or $isAttribute) then
                    $name-part
                else
                    $kind || '(' || $name-part || ')'
                "/>
        <xsl:variable name="nodeTest"
            select="
                if ($nodeTest = '*:*') then
                    '*'
                else
                    $nodeTest
                "/>
        <xsl:sequence
            select="
                if ($step?axis = 'start') then
                    if ($kind = 'document-node') then
                        ''
                    else
                        ()
                else
                    $axis-part || $nodeTest
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

    <xsl:variable name="unspecified" as="element()">
        <nk:unspecified/>
    </xsl:variable>

    <xsl:function name="nk:sch-context" as="map(xs:string, item()*)" visibility="final">
        <xsl:param name="node" as="node()"/>
        <xsl:param name="expr" as="element(expr)?"/>
        <xsl:variable name="local-variables"
            select="
                $node/ancestor-or-self::*/
                preceding-sibling::sch:let
                "/>
        <xsl:variable name="anc" select="$node/(ancestor::sch:* | ancestor::sqf:*)"/>

        <xsl:variable name="context-el"
            select="$anc[(self::sch:rule/@context | self::sqf:*/@match) except $node][last()]"/>

        <xsl:variable name="schema" select="$anc/self::sch:schema"/>
        <xsl:variable name="namespaces"
            select="$schema/sch:ns ! map{@prefix/string(.) : @uri/string(.)} => map:merge()"/>
        <xsl:variable name="global-variables" select="$schema/sch:let"/>
        <xsl:variable name="var-scope"
            select="($global-variables, $local-variables) ! 
            map{
                QName($namespaces(substring-before(@name, ':')), @name) : .
            }"/>

        <xsl:variable name="var-scope" select="$var-scope => map:merge(map{'duplicates' : 'use-last'})"/>

        <xsl:variable name="xpm-config" select="map{ 'namespaces' : $namespaces }"/>

        <xsl:sequence
            select="map{
                'parent' : function(){
                    $context-el/nk:sch-context(., nk:xpath-model((@context|@match), $xpm-config)/self::expr)
                },
                'variable-context' : function($variableName as xs:QName){
                $var-scope($variableName)/nk:sch-context(., nk:xpath-model(@value, $xpm-config)/self::expr)
                },
                'expr' : $expr,
                'node' : $node
            }"/>

    </xsl:function>
    <xsl:function name="nk:xsl-context" as="map(xs:string, item()*)" visibility="final">
        <xsl:param name="node" as="node()"/>
        <xsl:param name="expr" as="element(expr)?"/>

        <xsl:variable name="anc" select="$node/ancestor::xsl:*"/>
        <xsl:variable name="anc" select="$anc except $anc/ancestor-or-self::xsl:analyze-string"/>

        <xsl:variable name="context"
            select="
                $anc
                [
                (
                (self::xsl:for-each | self::xsl:for-each-group)/@select
                | (self::xsl:key | self::xsl:template)/@match
                ) except $node
                ][last()]"/>


        <xsl:variable name="local-variables"
            select="
                $node/ancestor-or-self::*/
                (preceding-sibling::xsl:variable | preceding-sibling::xsl:param)
                "/>
        <xsl:variable name="global-variables"
            select="$anc[not(parent::*)]/(xsl:variable | xsl:param) except $node"/>

        <xsl:variable name="var-scope"
            select="($global-variables, $local-variables) ! map{nk:varQName(@name) : .}"/>
        <xsl:variable name="var-scope" select="$var-scope => map:merge(map{'duplicates' : 'use-last'})"/>

        <xsl:variable name="xpm-config-gen"
            select="function($ctx){
            let $namespaces := $ctx/nk:parent-or-self-el(.)/namespace::*[name() != '']/map{name() : string(.)},
                $default-ns := ($ctx/ancestor-or-self::*/(@xsl:xpath-default-namespace | self::xsl:*/@xpath-default-namespace))[last()],
                $default-ns-map := if ($default-ns) then map{'#default' : string($default-ns)} else ()
                return
                    map{
                        'namespaces' : ($namespaces, $default-ns-map) => map:merge()
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
                    $context/(@select|@match)/nk:xsl-context(., nk:xpath-model(., $xpm-config-gen(.), true()))
                },
                'variable-context' : function($variableName as xs:QName){
                    $var-scope ! .($variableName)[@select]/nk:xsl-context(., nk:xpath-model(@select, $xpm-config-gen(.)))
                },
                'expr' : $expr,
                'node' : $node
            
            }"/>

    </xsl:function>
    
    <xsl:function name="nk:parent-or-self-el" as="element()?" visibility="final">
        <xsl:param name="node" as="node()"/>
        <xsl:sequence select="
            if ($node/self::element()) 
            then $node 
            else $node/parent::element()
            "/>
    </xsl:function>

    <xsl:function name="nk:context-provider-handler" as="map(*)*">
        <xsl:param name="provider" as="element()"/>
        <xsl:param name="exprContext" as="map(*)"/>

        <xsl:choose>
            <xsl:when test="$provider/self::self">
                <xsl:sequence select="nk:get-context-provider($provider, $exprContext)"/>
            </xsl:when>
            <xsl:when test="$provider/self::varRef">
                <xsl:variable name="varname" select="nk:QName($provider/@name)"/>
                <xsl:variable name="variable-decl-info" select="$exprContext?variable-context($varname)"/>
                <xsl:choose>
                    <xsl:when test="exists($variable-decl-info)">
                        <xsl:variable name="var-expr" select="$variable-decl-info?expr"/>
                        <xsl:variable name="var-return" select="$var-expr/nk:get-return-from-expr(.)"/>

                        <xsl:sequence
                            select="
                                if ($var-return) then
                                    $var-return ! nk:context-provider-handler(., $variable-decl-info)
                                else
                                    map {
                                        'nodeTest': (),
                                        'root-required': false(),
                                        'reason': 'variable-' || $varname || '-returns-nothing',
                                        'context': $exprContext
                                    }
                                "
                        />
                    </xsl:when>
                    <xsl:otherwise expand-text="true">
                        <xsl:sequence
                            select="map{
                                'nodeTest' : (),
                                'root-required' : false(),
                                'unknown-context' : true(),
                                'reason' : 'variable-' || $varname || '-not-declared-or-no-select',
                                'context' : $exprContext
                            }"
                        />
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <xsl:when test="$provider/self::expr">
                <xsl:variable name="parentContext" select="$exprContext?parent()"/>
                <xsl:variable name="returnedObj" select="$parentContext?expr/nk:get-return-from-expr(.)"/>
                <xsl:choose>
                    <xsl:when test="empty($parentContext)">
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
                                    <xsl:sequence select="nk:get-context-provider(., $parentContext)"/>
                                </xsl:when>
                                <xsl:when test="self::nodeTest">
                                    <xsl:sequence
                                        select="map{
                                            'nodeTest' : .,
                                            'root-required' : false(),
                                            'context' : $parentContext,
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
                                            'context' : $parentContext,
                                            'pathObj' : .
                                        }"
                                    />
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:sequence
                                        select="map{
                                            'nodeTest' : (),
                                            'root-required' : false(),
                                            'unknown-context' : true(),
                                            'reason' : name() || '-is-context-provider',
                                            'context' : $parentContext,
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
                <xsl:sequence
                    select="map{
                        'nodeTest' : (),
                        'root-required' : false(),
                        'unknown-context' : true(),
                        'reason' : $provider/name() || '-is-context-provider',
                        'context' : $exprContext,
                        'pathObj' : $provider
                    }
                    "
                />
            </xsl:otherwise>
        </xsl:choose>

    </xsl:function>



    <xsl:function name="nk:get-return-from-expr" as="element()*" visibility="final">
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


    <xsl:function name="nk:varQName" as="xs:QName" visibility="final">
        <xsl:param name="node" as="node()"/>
        <xsl:variable name="prefixed" select="contains($node, ':')"/>
        <xsl:sequence select="
            if (nk:is-eqname($node)) 
            then (nk:parse-eqname($node)) 
            else if ($prefixed) 
            then nk:QName($node) 
            else QName('', $node)
            "/>
    </xsl:function>
    
    <xsl:function name="nk:QName" as="xs:QName" visibility="final">
        <xsl:param name="node" as="node()"/>
        <xsl:variable name="el"
            select="
                if ($node instance of element()) then
                    $node
                else
                    $node/parent::*"/>

        <xsl:variable name="prefix" select="substring-before($node, ':')" as="xs:string"/>
        <xsl:variable name="namespace" select="$el/namespace::*[name() = $prefix]"/>
        <xsl:sequence select="QName($namespace, $node)"/>
    </xsl:function>

    <xsl:function name="nk:name-matcher" as="map(xs:string, xs:string)" visibility="final">
        <xsl:param name="name" as="attribute(name)?"/>
        <xsl:variable name="ns-ctx" select="$name/parent::*"/>

        <xsl:variable name="map" select="map{'local' : '*', 'namespace' : '*'}"/>

        <xsl:choose>
            <xsl:when test="not($name)">
                <xsl:sequence select="$map"/>
            </xsl:when>
            <xsl:when test="$name castable as xs:Name">
                <xsl:variable name="qname" select="nk:QName($name)"/>
                <xsl:sequence
                    select="
                        map:put($map, 'local', string(local-name-from-QName($qname)))
                        => map:put('namespace', string(namespace-uri-from-QName($qname)))
                        "
                />
            </xsl:when>
            <xsl:when test="matches($name, '^[^\*:]+:\*')">
                <xsl:variable name="prefix" select="substring-before($name, ':')"/>
                <xsl:if test="not(in-scope-prefixes($ns-ctx) = $prefix)">
                    <xsl:sequence select="error(xpe:error-code('XPST0081'), 'Undeclared prefix ' || $prefix)"/>
                </xsl:if>
                <xsl:sequence
                    select="map:put($map, 'namespace', string(namespace-uri-for-prefix($prefix, $ns-ctx)))"/>
            </xsl:when>
            <xsl:when test="matches($name, '^\*:[^\*:]+')">
                <xsl:variable name="local" select="substring-after($name, ':')"/>
                <xsl:sequence select="map:put($map, 'local', $local)"/>
            </xsl:when>
            <xsl:when test="matches($name, '^Q\{[^\}]*\}')">
                <xsl:variable name="local" select="replace($name, '^Q\{([^\}]*)\}(.*)', '$2')"/>
                <xsl:variable name="ns" select="replace($name, '^Q\{\s*([^\}\s]*)\s*\}(.*)', '$1')"/>
                <xsl:sequence
                    select="
                        map:put($map, 'local', $local)
                        => map:put('namespace', $ns)
                        "
                />
            </xsl:when>
            <xsl:otherwise>
                <xsl:message terminate="yes" expand-text="yes">Can not handle "{$name}" as node
                    matcher.</xsl:message>
            </xsl:otherwise>
        </xsl:choose>

    </xsl:function>




</xsl:stylesheet>
