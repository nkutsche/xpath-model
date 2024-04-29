<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:nk="http://www.nkutsche.com/xpath-model" xmlns:math="http://www.w3.org/2005/xpath-functions/math"
    xmlns:p="http://www.nkutsche.com/xpath-parser" xmlns:r="http://maxtoroq.github.io/rng.xsl"
    xmlns:map="http://www.w3.org/2005/xpath-functions/map" xmlns:err="http://www.w3.org/2005/xqt-errors"
    xmlns:avt="http://www.nkutsche.com/avt-parser" exclude-result-prefixes="#all" version="3.0">

    <xsl:import href="xpath-31.xsl"/>
    <xsl:import href="xslt-3-avt.xsl"/>

    <xsl:mode name="nk:xpath-model" on-no-match="shallow-copy"/>

    <xsl:variable name="default-config" as="map(xs:string, item()*)"
        select="
            map {
                'validation-mode': 'lax',
                'namespaces': map {},
                'ignore-undeclared-namespaces' : true()
            }"/>


    <xsl:function name="nk:xpath-model-value-template" as="element()" visibility="final">
        <xsl:param name="value-template" as="xs:string"/>
        <xsl:sequence select="nk:xpath-model-value-template($value-template, $default-config)"/>
    </xsl:function>

    <xsl:function name="nk:xpath-model-value-template" as="element()" visibility="final">
        <xsl:param name="value-template" as="xs:string"/>
        <xsl:param name="config" as="map(xs:string, item()*)"/>
        <xsl:sequence
            select="
                nk:xpath-model-value-template($value-template, $config, false())
                "
        />
    </xsl:function>

    <xsl:function name="nk:xpath-model-value-template" as="element()" visibility="final">
        <xsl:param name="value-template" as="xs:string"/>
        <xsl:param name="config" as="map(xs:string, item()*)"/>
        <xsl:param name="fail-on-error" as="xs:boolean"/>
        
        <xsl:variable name="model" select="
            avt:parse-value-template($value-template)
            => nk:xpath-model-internal($config, 'value-template')
            "/>
        
        <xsl:sequence
            select="
                if ($model/self::ERROR and $fail-on-error) then
                    error(xs:QName('nk:xp-model-parse-error'), string($model) || ' (on value template: ' || $value-template || ')')
                else
                    $model
            "
        />
    </xsl:function>

    <xsl:function name="avt:parse-value-template" as="element(AVT)">
        <xsl:param name="value-template" as="xs:string"/>
        <xsl:variable name="parsed" select="avt:parse-AVT($value-template)"/>
        <xsl:sequence select="$parsed"/>
    </xsl:function>


    <xsl:function name="nk:xpath-type-model" as="element(itemType)?" visibility="final">
        <xsl:param name="type" as="xs:string"/>
        <xsl:variable name="namespaces" select="
            ($default-config?namespaces, map {'xs' : $build-in-namespaces('xs')}) 
            => map:merge()
            "/>
        <xsl:variable name="config" select="map:put($default-config, 'namespaces', $namespaces)"/>
        
        <xsl:sequence select="nk:xpath-type-model($type, $config)"/>
    </xsl:function>
    <xsl:function name="nk:xpath-type-model" as="element(itemType)?" visibility="final">
        <xsl:param name="type" as="xs:string"/>
        <xsl:param name="config" as="map(*)"/>
        <xsl:variable name="xpath" select="'. instance of ' || $type"/>
        <xsl:variable name="model" select="nk:xpath-model($xpath, $config, true())"/>
        <xsl:copy-of select="$model/operation/itemType"/>
    </xsl:function>
    
    <xsl:function name="nk:xpath-model" as="element()" visibility="final">
        <xsl:param name="xpath" as="xs:string"/>
        <xsl:sequence select="nk:xpath-model($xpath, $default-config)"/>
    </xsl:function>

    <xsl:function name="nk:xpath-model" as="element()" visibility="final">
        <xsl:param name="xpath" as="xs:string"/>
        <xsl:param name="config" as="map(xs:string, item()*)"/>
        <xsl:sequence select="nk:xpath-model($xpath, $config, false())"/>
    </xsl:function>
    <xsl:function name="nk:xpath-model" as="element()" visibility="final">
        <xsl:param name="xpath" as="xs:string"/>
        <xsl:param name="config" as="map(xs:string, item()*)"/>
        <xsl:param name="fail-on-error" as="xs:boolean"/>

        <xsl:variable name="parsed" select="p:parse-XPath($xpath)"/>
        <xsl:variable name="model"
            select="
                $parsed
                => nk:xpath-model-internal($config, 'expr')"/>
        <xsl:sequence
            select="
                if ($model/self::ERROR and $fail-on-error) then
                    error(xs:QName('nk:xp-model-parse-error'), string($model) || ' (on XPath: ' || $xpath || ')')
                else
                    $model
                "
        />
    </xsl:function>

    <xsl:function name="nk:effective-config" as="map(xs:string, item()*)">
        <xsl:param name="config" as="map(xs:string, item()*)"/>
        <xsl:sequence select="nk:effective-config($config, $default-config)"/>
    </xsl:function>
    <xsl:function name="nk:effective-config" as="map(xs:string, item()*)">
        <xsl:param name="config" as="map(xs:string, item()*)"/>
        <xsl:param name="default-config" as="map(xs:string, item()*)"/>
        <xsl:sequence
            select="(
            $config,
            $default-config,
            map {
                'validation-mode': 'lax',
                'namespaces': map {},
                'ignore-undeclared-namespaces' : true()
            }
            ) => map:merge()
            "
        />
    </xsl:function>

    <xsl:function name="nk:xpath-model-internal" as="element()">
        <xsl:param name="parsed" as="element()"/>
        <xsl:param name="config" as="map(xs:string, item()*)"/>
        <xsl:param name="root-element" as="xs:string"/>
        <xsl:variable name="parsed" select="nk:pre-parse-comments($parsed)"/>

        <xsl:variable name="config" select="nk:effective-config($config)"/>

        <xsl:variable name="validation-modes" select="('lax', 'strict')"/>
        <xsl:variable name="valmode" select="($config?validation-mode[. = $validation-modes], 'lax')[1]"/>
        <xsl:variable name="target-namespaces"
            select="
            nk:create-namespaces(
                $parsed, 
                ($config?namespaces, map {})[1],
                $config?ignore-undeclared-namespaces)
            "/>

        <xsl:variable name="model" as="element()">
            <xsl:try>
                <xsl:element name="{$root-element}">
                    <xsl:sequence select="$target-namespaces"/>
                    <xsl:apply-templates select="$parsed" mode="nk:xpath-model">
                        <xsl:with-param name="config"
                            select="map:put($config, 'target-namespaces', $target-namespaces)" tunnel="yes"/>
                    </xsl:apply-templates>
                </xsl:element>
                <xsl:catch errors="*">
                    <ERROR message="Invalid result:" code="{$err:code}">
                        <xsl:sequence select="$err:description"/>
                    </ERROR>
                </xsl:catch>
            </xsl:try>
        </xsl:variable>

        <xsl:choose>
            <xsl:when test="$parsed/self::ERROR">
                <xsl:sequence select="$parsed"/>
            </xsl:when>
            <xsl:when test="$model/self::ERROR or $valmode = 'lax'">
                <xsl:sequence select="$model"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:try>
                    <xsl:variable name="rng-validate" as="xs:boolean" 
                        select="r:is-valid($model, doc('../rnc/xpath-model.rng'))"/>
                    <xsl:choose>
                        <xsl:when test="$rng-validate">
                            <xsl:sequence select="$model"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:sequence select="error(xs:QName('Invalid-Result'))"/>
                        </xsl:otherwise>
                    </xsl:choose>
                    <xsl:catch>
                        <ERROR message="Invalid result:">
                            <xsl:sequence select="$model"/>
                        </ERROR>
                    </xsl:catch>
                </xsl:try>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>

    <xsl:function name="nk:pre-parse-comments" as="element()">
        <xsl:param name="parsed" as="element()"/>
        <xsl:apply-templates select="$parsed" mode="nk:pre-parse-comments"/>
    </xsl:function>


    <xsl:template
        match="
            Expr//text()[starts-with(normalize-space(.), '(:')]
            | XPath//text()[starts-with(normalize-space(.), '(:')]
            "
        mode="nk:pre-parse-comments">
        <xsl:sequence select="nk:parse-comment(.)"/>
    </xsl:template>

    <!-- 
        copies all nodes:
    -->
    <xsl:template match="node() | @*" mode="nk:pre-parse-comments">
        <xsl:copy>
            <xsl:apply-templates select="@*" mode="#current"/>
            <xsl:apply-templates select="node()" mode="#current"/>
        </xsl:copy>
    </xsl:template>


    <xsl:function name="nk:create-namespaces" as="namespace-node()*">
        <xsl:param name="parsed" as="element()"/>
        <xsl:param name="namespace-bindings" as="map(xs:string, xs:string)"/>
        <xsl:param name="allow-undeclared-prefixes" as="xs:boolean"/>

        <xsl:variable name="namespace-bindings"
            select="map:put($namespace-bindings, 'xml', 'http://www.w3.org/XML/1998/namespace')"/>

        <xsl:variable name="used-prefixes" as="xs:string*"
            select="$parsed//(QName[contains(., ':')] | NameTest/Wildcard[matches(., '^[^:]+:\*$')])/substring-before(., ':')[. != '*'] => distinct-values()"/>
        
        <xsl:if test="$used-prefixes = 'xmlns'">
            <xsl:sequence select="error(xs:QName('nk:xp-model-undeclared-prefix'), 'Don''t use prefix xmlns as it is reserved for namespace declarations.')"/>
        </xsl:if>
        
        <xsl:variable name="used-prefixes" select="$used-prefixes"/>

        <xsl:variable name="base-ns-uri" select="'http://www.nkutsche.com/xpath-model/dummy-namespace/'"/>

        <xsl:variable name="def-prefix" select="nk:get-default-ns-prefix($namespace-bindings)"/>

        <xsl:for-each select="$used-prefixes">
            <xsl:namespace name="{.}"
                select="
                    if (map:contains($namespace-bindings, .)) 
                    then $namespace-bindings(.) 
                    else if ($allow-undeclared-prefixes) 
                    then ($base-ns-uri || .) 
                    else error(xs:QName('nk:xp-model-undeclared-prefix'), 'Undeclared namespace for prefix ' || .)
                    "
            />
        </xsl:for-each>

        <xsl:if test="$def-prefix[not(. = $used-prefixes)] and $namespace-bindings('#default') != ''">
            <xsl:namespace name="{$def-prefix}" select="$namespace-bindings('#default')"/>
        </xsl:if>


    </xsl:function>

    <xsl:function name="nk:get-default-ns-prefix" as="xs:string?">
        <xsl:param name="namespace-bindings" as="map(xs:string, xs:string)"/>

        <xsl:variable name="dns" select="$namespace-bindings('#default')"/>

        <xsl:variable name="prefixes" select="map:keys($namespace-bindings)[. != '#default']"/>
        <xsl:variable name="exist-prefix" select="$prefixes[$namespace-bindings(.) = $dns]"/>

        <xsl:if test="exists($dns)">
            <xsl:variable name="dns-gen-pfx"
                select="
                    for $i in 1 to (count($prefixes) + 1)
                    return
                        (if ($i = 1) then
                            ('default')
                        else
                            ('default-' || $i))"/>

            <xsl:variable name="dns-gen-pfx" select="$dns-gen-pfx[not(. = $prefixes)][1]"/>

            <xsl:sequence select="($exist-prefix, $dns-gen-pfx)[1]"/>

        </xsl:if>

    </xsl:function>

    <xsl:function name="nk:add-default-ns-prefix">
        <xsl:param name="name" as="xs:string"/>
        <xsl:param name="config" as="map(*)"/>
        <xsl:param name="kind" as="xs:string"/>

        <xsl:variable name="default-namespace" select="$config?namespaces('#default')"/>

        <xsl:variable name="dns-prefix"
            select="$config?target-namespaces[string(.) = $default-namespace]/name()"/>

        <xsl:variable name="use-def-ns-prefix"
            select="
                $name castable as xs:NCName
                and
                $default-namespace[. != '']
                and
                $kind = ('element', 'type')
                "/>

        <xsl:variable name="name"
            select="
                if ($use-def-ns-prefix)
                then
                    $dns-prefix || ':' || $name
                else
                    $name
                "/>

        <xsl:sequence select="$name"/>
    </xsl:function>

    <!--    
    Value Templates
    -->
    <xsl:template match="AVTFix" mode="nk:xpath-model">
        <!-- unescape curly brackets -->
        <xsl:variable name="value" select="replace(., '(\{|\})\1', '$1')"/>
        <string value="{$value}"/>
    </xsl:template>

    <xsl:template match="AVTVar" mode="nk:xpath-model">
        <expr>
            <xsl:apply-templates select="* except TOKEN" mode="#current"/>
        </expr>
    </xsl:template>

    <xsl:template match="AVT | AVTExpr" mode="nk:xpath-model">
        <xsl:apply-templates mode="#current"/>
    </xsl:template>


    <!--    
    Primitives
    -->


    <xsl:template match="Literal" mode="nk:xpath-model">
        <xsl:apply-templates mode="#current"/>
    </xsl:template>

    <xsl:template match="StringLiteral" mode="nk:xpath-model">
        <xsl:variable name="value" select="string(.)"/>
        <xsl:variable name="quote" select="substring($value, 1, 1)"/>
        <xsl:variable name="value" select="substring($value, 2, string-length($value) - 2)"/>
        <xsl:variable name="value" select="nk:quote-unesc($value, $quote)"/>
        <string value="{$value}"/>
    </xsl:template>

    <xsl:template match="IntegerLiteral" mode="nk:xpath-model">
        <xsl:variable name="value" select="string(.)"/>
        <xsl:variable name="value" select="xs:integer($value)"/>
        <integer value="{$value}"/>
    </xsl:template>

    <xsl:template match="DecimalLiteral" mode="nk:xpath-model">
        <xsl:variable name="value" select="string(.)"/>
        <xsl:variable name="value" select="xs:decimal($value)"/>
        <decimal value="{$value}"/>
    </xsl:template>

    <xsl:template match="DoubleLiteral" mode="nk:xpath-model">
        <xsl:variable name="value" select="string(.)"/>
        <xsl:variable name="factor" select="xs:decimal(replace($value, '[eE].*$', ''))"/>
        <xsl:variable name="exp" select="xs:integer(replace($value, '^.*[eE]', ''))"/>
        <double factor="{$factor}" exp="{$exp}"/>
    </xsl:template>

    <xsl:template match="ParenthesizedExpr[not(* except (TOKEN | Comment))]" mode="nk:xpath-model">
        <empty>
            <xsl:apply-templates select="Comment" mode="#current"/>
        </empty>
    </xsl:template>

    <xsl:template match="ContextItemExpr" mode="nk:xpath-model">
        <self/>
    </xsl:template>

    <xsl:template match="PathExpr[not(* except TOKEN)][TOKEN = '/']" priority="100" mode="nk:xpath-model">
        <root/>
    </xsl:template>

    <xsl:template match="VarRef" mode="nk:xpath-model">
        <varRef name="{VarName/string(.)}"/>
    </xsl:template>

    <!--    
    Location Steps
    -->

    <xsl:template match="AxisStep" mode="nk:xpath-model">
        <xsl:variable name="step" select="(ReverseStep | ForwardStep)"/>
        <xsl:variable name="axis"
            select="
                if ($step/AbbrevForwardStep/TOKEN[1] = '@')
                then
                    ('attribute')
                else
                    if ($step/AbbrevForwardStep/NodeTest/KindTest/NamespaceNodeTest)
                    then
                        ('namespace')
                    else
                        if ($step/AbbrevForwardStep) then
                            ('child')
                        else
                            if ($step/AbbrevReverseStep) then
                                'parent'
                            else
                                $step/(ReverseAxis | ForwardAxis)/string(TOKEN[1])"
            as="xs:string"/>
        <xsl:variable name="leadingComments" select="Comment[. &lt;&lt; $step]"/>
        <xsl:apply-templates select="$leadingComments" mode="#current"/>
        <locationStep axis="{$axis}">
            <xsl:apply-templates select="$step/(Comment | NodeTest | AbbrevForwardStep | AbbrevReverseStep)"
                mode="#current">
                <xsl:with-param name="axis" select="$axis" tunnel="yes"/>
            </xsl:apply-templates>
            <xsl:apply-templates select="(Comment except $leadingComments) | PredicateList" mode="#current"/>
        </locationStep>
    </xsl:template>

    <xsl:template match="AbbrevReverseStep" mode="nk:xpath-model">
        <xsl:apply-templates select="Comment" mode="#current"/>
        <nodeTest kind="node"/>
    </xsl:template>

    <xsl:template match="AbbrevForwardStep" mode="nk:xpath-model">
        <xsl:apply-templates select="NodeTest | Comment" mode="#current"/>
    </xsl:template>

    <xsl:template match="NodeTest[NameTest]" mode="nk:xpath-model">
        <xsl:param name="axis" tunnel="yes" as="xs:string"/>
        <xsl:param name="config" tunnel="yes" as="map(xs:string, item()*)"/>


        <xsl:variable name="kind"
            select="
                if ($axis = 'attribute') then
                    'attribute'
                else
                    if ($axis = 'namespace') then
                        'namespace-node'
                    else
                        'element'
                "/>

        <xsl:variable name="name" select="string(NameTest/(EQName | Wildcard))"/>


        <nodeTest>
            <xsl:if test="NameTest/EQName or NameTest/Wildcard[not(normalize-space(.) = '*')]">
                <xsl:attribute name="name" select="nk:add-default-ns-prefix($name, $config, $kind)"/>
            </xsl:if>
            <xsl:attribute name="kind" select="$kind"/>
            <xsl:apply-templates select=".//Comment" mode="#current"/>
        </nodeTest>
    </xsl:template>
    <xsl:template match="NodeTest[KindTest]" mode="nk:xpath-model">
        <nodeTest>
            <xsl:apply-templates
                select="
                    KindTest/(
                    DocumentTest
                    | ElementTest
                    | AttributeTest
                    | SchemaElementTest
                    | SchemaAttributeTest
                    | PITest
                    | CommentTest
                    | TextTest
                    | NamespaceNodeTest
                    | AnyKindTest
                    )"
                mode="#current"/>
        </nodeTest>
    </xsl:template>

    <xsl:template match="KindTest//TOKEN" mode="nk:xpath-model"/>



    <xsl:template
        match="
            DocumentTest
            | ElementTest
            | AttributeTest
            | SchemaElementTest
            | SchemaAttributeTest
            | PITest
            | CommentTest
            | TextTest
            | NamespaceNodeTest
            | AnyKindTest
            "
        mode="nk:xpath-model" priority="10">
        <xsl:variable name="name" select="name()"/>
        <xsl:variable name="kind" select="replace($name, 'Test$', '') => lower-case()"/>
        <xsl:variable name="kind"
            select="
                if ($kind = 'pi')
                then
                    'processing-instruction'
                else
                    if ($kind = 'document')
                    then
                        'document-node'
                    else
                        if ($kind = 'namespacenode')
                        then
                            'namespace-node'
                        else
                            if (starts-with($kind, 'schema'))
                            then
                                replace($kind, '^schema', 'schema-')
                            else
                                if ($kind = 'anykind')
                                then
                                    'node'
                                else
                                    $kind
                "/>
        <xsl:attribute name="kind" select="$kind"/>
        <xsl:apply-templates select="*" mode="#current"/>
    </xsl:template>

    <xsl:template match="DocumentTest/ElementTest | DocumentTest/SchemaElementTest" mode="nk:xpath-model"
        priority="20">
        <nodeTest>
            <xsl:next-match/>
        </nodeTest>
    </xsl:template>

    <xsl:template
        match="
            ElementNameOrWildcard |
            AttribNameOrWildcard |
            ElementDeclaration |
            AttributeDeclaration"
        mode="nk:xpath-model">
        <xsl:apply-templates mode="#current"/>
    </xsl:template>

    <xsl:template match="ElementName" mode="nk:xpath-model">
        <xsl:param name="config" tunnel="yes" as="map(xs:string, item()*)"/>
        <xsl:attribute name="name" select="nk:add-default-ns-prefix(string(EQName), $config, 'element')"/>
    </xsl:template>
    <xsl:template match="AttributeName" mode="nk:xpath-model">
        <xsl:attribute name="name" select="string(EQName)"/>
    </xsl:template>
    <xsl:template match="TypeName" mode="nk:xpath-model">
        <xsl:param name="config" tunnel="yes" as="map(xs:string, item()*)"/>
        <xsl:attribute name="type" select="nk:add-default-ns-prefix(string(EQName), $config, 'type')"/>
    </xsl:template>

    <xsl:template match="PITest/NCName" mode="nk:xpath-model">
        <xsl:attribute name="name" select="string(.)"/>
    </xsl:template>

    <xsl:template match="PITest/StringLiteral" mode="nk:xpath-model">
        <xsl:variable name="next-match" as="element(string)">
            <xsl:next-match/>
        </xsl:variable>
        <xsl:attribute name="name" select="$next-match/@value"/>
    </xsl:template>


    <xsl:template match="PredicateList[empty(*)]" mode="nk:xpath-model"/>

    <xsl:template match="PredicateList" mode="nk:xpath-model">
        <xsl:apply-templates select="Predicate | Comment" mode="#current"/>
    </xsl:template>


    <xsl:template match="PredicateList/Predicate" mode="nk:xpath-model">
        <predicate>
            <xsl:apply-templates select="Expr | Comment" mode="#current"/>
        </predicate>
    </xsl:template>


    <!--    
    Operators
    -->


    <!--    regular operators -->
    <xsl:variable name="regularOperations"
        select="
            map {
                'AdditiveExpr': 'additive',
                'MultiplicativeExpr': 'multiplicativ',
                'OrExpr': 'or',
                'AndExpr': 'and',
                'StringConcatExpr': 'concat',
                'RangeExpr': 'range',
                'UnionExpr': 'union',
                'IntersectExceptExpr': 'intersect-except',
                'UnaryExpr': 'unary',
                'CastExpr': 'cast',
                'CastableExpr': 'castable',
                'InstanceofExpr': 'instance-of',
                'TreatExpr': 'treat-as',
                'SimpleMapExpr': 'map',
                'PathExpr': 'step',
                'RelativePathExpr': 'step',
                'PostfixExpr': 'postfix',
                'ArrowExpr': 'arrow',
                'Expr': 'sequence'
                
            }"/>

    <xsl:template match="*[map:contains($regularOperations, local-name(.))]" mode="nk:xpath-model">
        <operation type="{$regularOperations(local-name(.))}">
            <xsl:apply-templates select="*" mode="nk:xpath-operations"/>
        </operation>
    </xsl:template>
    
    <xsl:template match="PathExpr[TOKEN]" mode="nk:xpath-model" priority="10">
        <xsl:variable name="next-match" as="element(operation)">
            <xsl:next-match/>
        </xsl:variable>
        <xsl:copy select="$next-match">
            <xsl:variable name="lastArg" select="arg[last()]"/>
            <xsl:copy-of select="@*"/>
            <xsl:copy-of select="* except $lastArg"/>
            <xsl:choose>
                <xsl:when test="$lastArg/operation[@type = 'step']">
                    <xsl:copy-of select="$lastArg/operation[@type = 'step']/*"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:copy-of select="$lastArg"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="ComparisonExpr" mode="nk:xpath-model">
        <xsl:variable name="type-prefix"
            select="
                if (ValueComp) then
                    ('value-')
                else
                    if (NodeComp) then
                        ('node-')
                    else
                        ('')
                "/>

        <operation type="{$type-prefix}compare">
            <xsl:apply-templates select="*" mode="nk:xpath-operations"/>
        </operation>
    </xsl:template>

    <xsl:variable name="operatorMap"
        select="
            map {
                '+': 'plus',
                '-': 'minus',
                '*': 'x',
                '=': 'eq',
                'is': 'eq',
                '!=': 'ne',
                '>': 'gt',
                '>>': 'gt',
                '>=': 'ge',
                '=>': 'arrow',
                '&lt;': 'lt',
                '&lt;&lt;': 'lt',
                '&lt;=': 'le',
                '||': 'concat',
                '|': 'union',
                '!': 'map',
                '/': 'slash',
                ',': 'comma',
                'as': '#delete',
                'of': '#delete',
                'cast': 'castAs',
                'castable': 'castableAs',
                'treat': 'treatAs',
                'instance': 'instanceOf'
            }"/>

    <xsl:template match="TOKEN" priority="20" mode="nk:xpath-operations">
        <xsl:variable name="op" select="string(.)"/>
        <xsl:variable name="name" select="
                ($operatorMap($op), $op)[1]
                "/>
        <xsl:choose>
            <xsl:when test="$name castable as xs:NCName">
                <xsl:element name="{$name}"/>
            </xsl:when>
            <xsl:when test="$name = '#delete'"/>
            <xsl:otherwise>
                <xsl:copy-of select="."/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>


    <xsl:template match="ValueComp | NodeComp | GeneralComp" priority="25" mode="nk:xpath-operations">
        <xsl:apply-templates select="*" mode="#current"/>
    </xsl:template>

    <xsl:template match="TOKEN[. = 'idiv']" priority="25" mode="nk:xpath-operations">
        <div type="integer"/>
    </xsl:template>
    <xsl:template match="TOKEN[. = '//']" priority="25" mode="nk:xpath-operations">
        <slash/>
        <arg>
            <locationStep axis="descendant-or-self">
                <nodeTest kind="node"/>
            </locationStep>
        </arg>
        <slash/>
    </xsl:template>


    <xsl:template match="SequenceType[string-join(TOKEN, '') = 'empty-sequence()']" mode="nk:xpath-operations">
        <itemType occurrence="zero">
            <xsl:apply-templates select="Comment" mode="#current"/>
        </itemType>
    </xsl:template>

    <xsl:template match="SequenceType" mode="nk:xpath-operations">
        <xsl:apply-templates select="* except (OccurrenceIndicator | Comment)" mode="#current">
            <xsl:with-param name="token" select="OccurrenceIndicator/TOKEN"/>
        </xsl:apply-templates>
    </xsl:template>

    <xsl:template match="SingleType | ItemType" priority="25" mode="nk:xpath-operations">
        <xsl:param name="token" select="TOKEN" as="element(TOKEN)?"/>
        <xsl:variable name="occ" select="nk:itemTypeOcc($token)"/>
        <xsl:variable name="additionalComments" select="self::ItemType/parent::SequenceType/Comment"/>
        <itemType>
            <xsl:if test="not($occ = 'one')">
                <xsl:attribute name="occurrence" select="$occ"/>
            </xsl:if>
            <xsl:apply-templates select="(* except TOKEN) | $additionalComments" mode="#current"/>
        </itemType>
    </xsl:template>

    <xsl:template match="ParenthesizedItemType" mode="nk:xpath-operations">
        <xsl:apply-templates select="Comment | ItemType/*" mode="#current"/>
    </xsl:template>

    <xsl:template match="KindTest" mode="nk:xpath-operations">
        <nodeTest>
            <xsl:apply-templates select="*" mode="nk:xpath-model"/>
        </nodeTest>
    </xsl:template>

    <xsl:template match="MapTest" mode="nk:xpath-operations">
        <mapType>
            <xsl:apply-templates select="*" mode="#current"/>
        </mapType>
    </xsl:template>

    <xsl:template match="ArrayTest" mode="nk:xpath-operations">
        <arrayType>
            <xsl:apply-templates select="*" mode="#current"/>
        </arrayType>
    </xsl:template>

    <xsl:template match="FunctionTest" mode="nk:xpath-operations">
        <functType>
            <xsl:apply-templates select="*" mode="#current"/>
        </functType>
    </xsl:template>

    <xsl:template match="TypedMapTest | TypedArrayTest" mode="nk:xpath-operations">
        <xsl:apply-templates select="AtomicOrUnionType | SequenceType | Comment" mode="#current"/>
    </xsl:template>

    <xsl:template match="TypedFunctionTest" mode="nk:xpath-operations">
        <xsl:variable name="asToken" select="TOKEN[. = 'as']"/>
        <xsl:variable name="children" select="SequenceType | Comment"/>
        <xsl:variable name="followAs" select="$asToken/following-sibling::*"/>
        <xsl:apply-templates select="$children except $followAs" mode="#current"/>
        <as>
            <xsl:apply-templates select="$children intersect $followAs" mode="#current"/>
        </as>
    </xsl:template>




    <xsl:template match="AnyMapTest | AnyArrayTest | AnyFunctionTest" mode="nk:xpath-operations">
        <xsl:apply-templates select="Comment" mode="#current"/>
    </xsl:template>
    <xsl:template match="SimpleTypeName | AtomicOrUnionType" priority="25" mode="nk:xpath-operations">
        <xsl:param name="config" tunnel="yes" as="map(xs:string, item()*)"/>
        <xsl:variable name="typeName"
            select="nk:add-default-ns-prefix(string(TypeName/EQName | EQName), $config, 'type')"/>
        <atomic name="{$typeName}"/>
    </xsl:template>

    <xsl:template match="Predicate" priority="25" mode="nk:xpath-operations">
        <predicate>
            <xsl:apply-templates select="* except TOKEN" mode="nk:xpath-model"/>
        </predicate>
    </xsl:template>

    <!--ArrowFunctionSpecifier-->


    <xsl:template match="ArrowExpr/ArgumentList" priority="50" mode="nk:xpath-operations">
        <xsl:variable name="funct-spec" select="preceding-sibling::ArrowFunctionSpecifier[1]"/>
        <xsl:variable name="betweenComments"
            select="$funct-spec/following-sibling::Comment intersect preceding-sibling::*"/>
        <function-call>
            <xsl:apply-templates select="$funct-spec | $betweenComments" mode="nk:xpath-model"/>
            <xsl:apply-templates select="* except TOKEN" mode="nk:xpath-model"/>
        </function-call>
    </xsl:template>

    <xsl:template match="ArrowExpr/ArrowFunctionSpecifier" mode="nk:xpath-operations"/>


    <xsl:template
        match="ArrowExpr/Comment[preceding-sibling::ArrowFunctionSpecifier][following-sibling::ArgumentList]"
        mode="nk:xpath-operations"/>
    <xsl:template match="ArrowExpr/ArrowFunctionSpecifier[EQName]" priority="25" mode="nk:xpath-model">
        <function name="{EQName}"/>
    </xsl:template>

    <xsl:template match="ArrowExpr/ArrowFunctionSpecifier[VarRef | ParenthesizedExpr]" priority="25"
        mode="nk:xpath-model">
        <function>
            <xsl:apply-templates select="VarRef | ParenthesizedExpr/(* except TOKEN)" mode="#current"/>
        </function>
    </xsl:template>



    <xsl:template match="ArgumentList" priority="25" mode="nk:xpath-operations">
        <function-call>
            <xsl:apply-templates select="* except TOKEN" mode="nk:xpath-model"/>
        </function-call>
    </xsl:template>

    
    <xsl:template match="Lookup | UnaryLookup" priority="25" mode="nk:xpath-operations">
        <lookup>
            <xsl:apply-templates select="* except TOKEN" mode="#current"/>
        </lookup>
    </xsl:template>
    
    <xsl:template match="Lookup/KeySpecifier[ParenthesizedExpr]" priority="25" mode="nk:xpath-operations">
        <arg>
            <xsl:apply-templates select="ParenthesizedExpr/(* except TOKEN)" mode="nk:xpath-model"/>
        </arg>
    </xsl:template>
    
    <xsl:template match="Lookup/KeySpecifier[NCName]" priority="25" mode="nk:xpath-operations">
        <field name="{string(NCName)}"/>
    </xsl:template>

    <xsl:template match="Lookup/KeySpecifier" priority="20" mode="nk:xpath-operations">
        <xsl:apply-templates select="* except TOKEN" mode="nk:xpath-model"/>
    </xsl:template>
    
    <xsl:template match="UnaryLookup" priority="25" mode="nk:xpath-model">
        <lookup>
            <xsl:apply-templates select="* except TOKEN" mode="#current"/>
        </lookup>
    </xsl:template>
    
    <xsl:template match="UnaryLookup/KeySpecifier[ParenthesizedExpr]" priority="25" mode="nk:xpath-model">
        <arg>
            <xsl:apply-templates select="ParenthesizedExpr/(* except TOKEN)" mode="#current"/>
        </arg>
    </xsl:template>
    
    <xsl:template match="UnaryLookup/KeySpecifier[NCName]" priority="25" mode="nk:xpath-model">
        <field name="{string(NCName)}"/>
    </xsl:template>
    
    <xsl:template match="UnaryLookup/KeySpecifier" priority="20" mode="nk:xpath-model">
        <xsl:apply-templates select="* except TOKEN" mode="#current"/>
    </xsl:template>

    <xsl:function name="nk:itemTypeOcc" as="xs:string">
        <xsl:param name="token" as="element(TOKEN)?"/>
        <xsl:variable name="map"
            select="
                map {
                    '*': 'zero-or-more',
                    '+': 'one-or-more',
                    '?': 'zero-or-one',
                    '': 'one'
                }"/>
        <xsl:variable name="token" select="($token, '')[1]"/>
        <xsl:sequence select="
                $map($token)
                "/>

    </xsl:function>
    <xsl:template match="Comment" mode="nk:xpath-operations">
        <xsl:apply-templates select="." mode="nk:xpath-model"/>
    </xsl:template>

    <xsl:template match="*" mode="nk:xpath-operations">
        <arg>
            <xsl:apply-templates select="." mode="nk:xpath-model"/>
        </arg>
    </xsl:template>

    <!--  programming operators  -->

    <xsl:template match="IfExpr" mode="nk:xpath-model">
        <operation type="condition">
            <xsl:for-each-group select="*" group-starting-with="TOKEN[. = ('if', 'then', 'else')]">
                <xsl:variable name="tokens" select="current-group()[self::TOKEN]"/>
                <xsl:choose>
                    <xsl:when test="self::TOKEN[. = ('if', 'then', 'else')]">
                        <arg role="{string(.)}">
                            <xsl:apply-templates select="current-group() except $tokens" mode="nk:xpath-model"
                            />
                        </arg>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:apply-templates select="current-group() except $tokens" mode="nk:xpath-model"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:for-each-group>
        </operation>
    </xsl:template>
    <xsl:template match="LetExpr | ForExpr" mode="nk:xpath-model">
        <xsl:variable name="opType"
            select="
                if (self::LetExpr) then
                    ('let-binding')
                else
                    ('for-loop')"/>
        <operation type="{$opType}">
            <xsl:for-each-group select="*" group-starting-with="TOKEN[. = ('return')]">
                <xsl:variable name="tokens" select="current-group()[self::TOKEN]"/>
                <xsl:choose>
                    <xsl:when test="self::TOKEN[. = ('return')]">
                        <arg role="{string(.)}">
                            <xsl:apply-templates select="current-group() except $tokens" mode="#current"/>
                        </arg>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:apply-templates select="current-group() except $tokens" mode="#current"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:for-each-group>
        </operation>
    </xsl:template>

    <xsl:template match="QuantifiedExpr" mode="nk:xpath-model">
        <xsl:variable name="opType" select="string(TOKEN[. = ('some', 'every')])"/>
        <operation type="{$opType}-satisfies">
            <xsl:for-each-group select="*" group-starting-with="TOKEN[. = ('satisfies', '$')]">
                <xsl:variable name="tokens" select="current-group()[self::TOKEN]"/>
                <xsl:variable name="non-tokens" select="current-group() except $tokens"/>
                <xsl:choose>
                    <xsl:when test="self::TOKEN[. = ('satisfies')]">
                        <arg role="{string(.)}">
                            <xsl:apply-templates select="$non-tokens" mode="#current"/>
                        </arg>
                    </xsl:when>
                    <xsl:when test="self::TOKEN[. = ('$')]">
                        <xsl:variable name="varName" select="current-group()/self::VarName"/>
                        <let name="{string($varName)}">
                            <arg>
                                <xsl:apply-templates select="$non-tokens except $varName" mode="#current"/>
                            </arg>
                        </let>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:apply-templates select="$non-tokens" mode="#current"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:for-each-group>
        </operation>
    </xsl:template>

    <xsl:template match="SimpleLetClause | SimpleForClause" mode="nk:xpath-model">
        <xsl:apply-templates select="* except TOKEN" mode="#current"/>
    </xsl:template>

    <xsl:template match="SimpleLetClause/SimpleLetBinding | SimpleForClause/SimpleForBinding"
        mode="nk:xpath-model">
        <let name="{string(VarName)}">
            <xsl:variable name="children" select="* except TOKEN"/>
            <xsl:variable name="eq" select="TOKEN[. = (':=', 'in')]"/>
            <xsl:apply-templates select="$children except VarName intersect $eq/preceding-sibling::*"
                mode="#current"/>
            <arg>
                <xsl:apply-templates select="$children intersect $eq/following-sibling::*" mode="#current"/>
            </arg>
        </let>
    </xsl:template>

    <!--    
    Functions
    -->

    <xsl:template match="FunctionCall" mode="nk:xpath-model">
        <function-call>
            <xsl:apply-templates select="*" mode="#current"/>
        </function-call>
    </xsl:template>

    <xsl:template match="FunctionCall/FunctionEQName" mode="nk:xpath-model">
        <function name="{string(.)}"/>
    </xsl:template>

    <xsl:template match="ArgumentList" mode="nk:xpath-model">
        <xsl:apply-templates select="Argument | Comment" mode="#current"/>
    </xsl:template>

    <xsl:template match="Argument" priority="25" mode="nk:xpath-model">
        <arg>
            <xsl:apply-templates select="* except TOKEN" mode="#current"/>
        </arg>
    </xsl:template>

    <xsl:template match="Argument[ArgumentPlaceholder]" priority="30" mode="nk:xpath-model">
        <arg role="placeholder"/>
    </xsl:template>

    <!--    
    Constructors
    -->

    <xsl:template match="MapConstructor" mode="nk:xpath-model">
        <map>
            <xsl:apply-templates select="* except TOKEN" mode="#current"/>
        </map>
    </xsl:template>

    <xsl:template match="MapConstructorEntry" mode="nk:xpath-model">
        <entry>
            <xsl:apply-templates select="* except TOKEN" mode="#current"/>
        </entry>
    </xsl:template>

    <xsl:template match="MapKeyExpr" mode="nk:xpath-model">
        <arg role="key">
            <xsl:apply-templates select="* except TOKEN" mode="#current"/>
        </arg>
    </xsl:template>

    <xsl:template match="MapValueExpr" mode="nk:xpath-model">
        <arg role="value">
            <xsl:apply-templates select="* except TOKEN" mode="#current"/>
        </arg>
    </xsl:template>

    <xsl:template match="ArrayConstructor[CurlyArrayConstructor]" mode="nk:xpath-model">
        <xsl:variable name="non-tokens" select="CurlyArrayConstructor/(* except TOKEN)"/>
        <array type="member-per-item">
            <xsl:apply-templates select="Comment | $non-tokens" mode="#current"/>
        </array>
    </xsl:template>

    <xsl:template match="ArrayConstructor/CurlyArrayConstructor/EnclosedExpr" mode="nk:xpath-model">
        <xsl:choose>
            <xsl:when test="Expr">
                <arg role="value">
                    <xsl:apply-templates select="* except TOKEN" mode="#current"/>
                </arg>
            </xsl:when>
            <xsl:otherwise>
                <xsl:apply-templates select="* except TOKEN" mode="#current"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template match="ArrayConstructor[SquareArrayConstructor]" mode="nk:xpath-model">
        <xsl:variable name="non-tokens" select="SquareArrayConstructor/(* except TOKEN)"/>
        <array type="member-per-sequence">
            <xsl:apply-templates select="Comment | $non-tokens" mode="#current"/>
        </array>
    </xsl:template>

    <xsl:template match="ArrayConstructor/SquareArrayConstructor/ExprSingle" mode="nk:xpath-model">
        <arg role="value">
            <xsl:apply-templates select="* except TOKEN" mode="#current"/>
        </arg>
    </xsl:template>

    <xsl:template match="FunctionItemExpr" mode="nk:xpath-model">
        <xsl:apply-templates select="* except TOKEN" mode="#current"/>
    </xsl:template>

    <xsl:template match="FunctionItemExpr/InlineFunctionExpr" mode="nk:xpath-model">
        <function-impl>
            <xsl:apply-templates select="* except TOKEN" mode="#current"/>
        </function-impl>
    </xsl:template>

    <xsl:template match="FunctionItemExpr/NamedFunctionRef" mode="nk:xpath-model">
        <xsl:variable name="non-tokens" select="* except TOKEN"/>
        <xsl:variable name="attributes" select="FunctionEQName | IntegerLiteral"/>
        <function>
            <xsl:apply-templates select="$attributes" mode="nk:xpath-model"/>
            <xsl:apply-templates select="$non-tokens except $attributes" mode="#current"/>
        </function>
    </xsl:template>
    <xsl:template match="NamedFunctionRef/FunctionEQName" mode="nk:xpath-model">
        <xsl:attribute name="name" select="string(.)"/>
    </xsl:template>

    <xsl:template match="NamedFunctionRef/IntegerLiteral" mode="nk:xpath-model">
        <xsl:attribute name="arity" select="string(.)"/>
    </xsl:template>

    <xsl:template match="FunctionBody" mode="nk:xpath-model">
        <arg role="return">
            <xsl:apply-templates select="* except TOKEN" mode="#current"/>
        </arg>
    </xsl:template>

    <xsl:template match="InlineFunctionExpr/ParamList" mode="nk:xpath-model">
        <xsl:apply-templates select="* except TOKEN" mode="#current"/>
    </xsl:template>

    <xsl:template match="InlineFunctionExpr/ParamList/Param" mode="nk:xpath-model">
        <param name="{string(EQName)}">
            <xsl:apply-templates select="* except (TOKEN | EQName)" mode="#current"/>
        </param>
    </xsl:template>

    <xsl:template match="InlineFunctionExpr/SequenceType" mode="nk:xpath-model">
        <as>
            <xsl:apply-templates select="." mode="nk:xpath-operations"/>
        </as>
    </xsl:template>
    <xsl:template match="InlineFunctionExpr/ParamList/Param/TypeDeclaration" mode="nk:xpath-model">
        <as>
            <xsl:apply-templates select="* except TOKEN" mode="nk:xpath-operations"/>
        </as>
    </xsl:template>

    <xsl:template match="FunctionBody/EnclosedExpr" mode="nk:xpath-model">
        <xsl:apply-templates select="* except TOKEN" mode="#current"/>
    </xsl:template>

    <xsl:template match="FunctionBody/EnclosedExpr[not(* except TOKEN)]" mode="nk:xpath-model" priority="10">
        <empty/>
    </xsl:template>


    <!--    
    MISC
    -->

    <xsl:template match="ParenthesizedExpr" mode="nk:xpath-model">
        <xsl:apply-templates select="* except TOKEN" mode="#current"/>
    </xsl:template>

    <xsl:template match="Comment" mode="nk:xpath-model">
        <xsl:comment select="."/>
    </xsl:template>



    <xsl:function name="nk:parse-comment" as="element(Comment)*">
        <xsl:param name="text" as="xs:string"/>

        <xsl:variable name="text" select="replace($text, '^\s+|\s+$', '')"/>
        <xsl:variable name="split">
            <xsl:analyze-string select="$text" regex="\(:|:\)">
                <xsl:matching-substring>
                    <xsl:element name="{if(. = '(:') then 'start' else 'end'}"/>
                </xsl:matching-substring>
                <xsl:non-matching-substring>
                    <ph xsl:expand-text="yes">{.}</ph>
                </xsl:non-matching-substring>
            </xsl:analyze-string>
        </xsl:variable>

        <xsl:for-each-group select="$split/*"
            group-ending-with="
                end[
                (preceding-sibling::start/1, preceding-sibling::end/(-1)) => sum() eq 1
                ]
                ">
            <xsl:variable name="first.start" select="(current-group()/self::start)[1]"/>
            <xsl:variable name="last.end" select="(current-group()/self::end)[last()]"/>
            <xsl:variable name="excl"
                select="($first.start/(. | preceding-sibling::*), $last.end/(. | following-sibling::*))"/>
            <xsl:variable name="content" select="current-group() except $excl"/>
            <xsl:variable name="comment-content" as="xs:string*">
                <xsl:apply-templates select="$content" mode="nk:parse-comment"/>
            </xsl:variable>
            <Comment>
                <xsl:sequence select="$comment-content => string-join()"/>
            </Comment>
        </xsl:for-each-group>

    </xsl:function>

    <xsl:template match="start" mode="nk:parse-comment">
        <xsl:text>(:</xsl:text>
    </xsl:template>
    <xsl:template match="end" mode="nk:parse-comment">
        <xsl:text>:)</xsl:text>
    </xsl:template>
    <xsl:template match="ph" mode="nk:parse-comment">
        <xsl:value-of select="nk:xpath-to-xml-comment(.)"/>
    </xsl:template>




    <xsl:template
        match="
            XPath |
            ExprSingle |
            Expr |
            PrimaryExpr |
            NumericLiteral |
            EOF
            "
        mode="nk:xpath-model" priority="-5">
        <xsl:apply-templates mode="#current"/>
    </xsl:template>

    <xsl:template
        match="
            Expr[count(*) eq 1] |
            OrExpr[count(*) eq 1] |
            AndExpr[count(*) eq 1] |
            ComparisonExpr[count(*) eq 1] |
            StringConcatExpr[count(*) eq 1] |
            RangeExpr[count(*) eq 1] |
            AdditiveExpr[count(*) eq 1] |
            MultiplicativeExpr[count(*) eq 1] |
            UnionExpr[count(*) eq 1] |
            IntersectExceptExpr[count(*) eq 1] |
            InstanceofExpr[count(*) eq 1] |
            TreatExpr[count(*) eq 1] |
            CastableExpr[count(*) eq 1] |
            CastExpr[count(*) eq 1] |
            ArrowExpr[count(*) eq 1] |
            UnaryExpr[count(*) eq 1] |
            ValueExpr[count(*) eq 1] |
            SimpleMapExpr[count(*) eq 1] |
            PathExpr[count(*) eq 1] |
            RelativePathExpr[count(*) eq 1] |
            StepExpr[count(*) eq 1] |
            PostfixExpr[count(*) eq 1]
            "
        mode="nk:xpath-model" priority="50">
        <xsl:apply-templates mode="#current"/>
    </xsl:template>


</xsl:stylesheet>
