<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:nk="http://www.nkutsche.com/xpath-model" xmlns:math="http://www.w3.org/2005/xpath-functions/math" xmlns:p="http://www.nkutsche.com/xpath-parser" xmlns:r="http://maxtoroq.github.io/rng.xsl" xmlns:map="http://www.w3.org/2005/xpath-functions/map" exclude-result-prefixes="#all" version="3.0">
    
    <xsl:function name="nk:xpath-serializer" as="xs:string">
        <xsl:param name="expr" as="element(expr)"/>
        <xsl:sequence select="nk:xpath-serializer($expr, map{})"/>
    </xsl:function>
    
    <xsl:function name="nk:xpath-serializer" as="xs:string">
        <xsl:param name="expr" as="element(expr)"/>
        <xsl:param name="config" as="map(*)"/>
        
        <xsl:variable name="content" as="xs:string*">
            <xsl:apply-templates select="$expr" mode="nk:xpath-serializer">
                <xsl:with-param name="config" select="$config" tunnel="yes"/>
            </xsl:apply-templates>
        </xsl:variable>
        <xsl:sequence select="string-join($content)"/>
    </xsl:function>
    
    <xsl:template match="expr" mode="nk:xpath-serializer">
        <xsl:apply-templates select="*" mode="#current"/>
    </xsl:template>
    
<!--    
    ### Primitive Expressions ###
    -->
    
<!--    
    
    Location Steps
    -->
    
    <xsl:template match="locationStep" mode="nk:xpath-serializer">
        <xsl:apply-templates select="@* | node()" mode="#current"/>
    </xsl:template>
    
    <xsl:template match="locationStep/@axis[. = 'child']" mode="nk:xpath-serializer" priority="50"/>

    <xsl:template match="locationStep[nodeTest/@kind = 'attribute']/@axis[. = 'attribute']" mode="nk:xpath-serializer" priority="50">
        <xsl:sequence select="'@'"/>
    </xsl:template>
    
    <xsl:template match="locationStep/@axis" mode="nk:xpath-serializer">
        <xsl:sequence select="string(.) || '::'"/>
    </xsl:template>

    <xsl:template match="locationStep[@axis = 'parent'][nodeTest[@kind = 'node']]" mode="nk:xpath-serializer"
        priority="50">
        <xsl:sequence select="'..'"/>
    </xsl:template>
    
    <xsl:template match="locationStep[@axis = 'attribute']/nodeTest[@kind = 'attribute']" mode="nk:xpath-serializer"
        priority="50">
        <xsl:sequence select="string((@name, '*')[1])"/>
    </xsl:template>

    <xsl:template match="locationStep[not(@axis = ('attribute', 'namespace'))]/nodeTest[@kind = 'element' or not(@kind)]" mode="nk:xpath-serializer" priority="50">
        <xsl:sequence select="string((@name, '*')[1])"/>
    </xsl:template>

    <xsl:template match="nodeTest[@type]" mode="nk:xpath-serializer" priority="100">
        <xsl:variable name="name" as="xs:string*" select="(@name, '*')[1], @type"/>
        <xsl:sequence select="@kind || '(' || string-join($name, ', ') || ')'"/>
    </xsl:template>
    
    <xsl:template match="nodeTest" mode="nk:xpath-serializer">
        <xsl:variable name="name" as="xs:string*">
            <xsl:apply-templates select="@name | nodeTest" mode="#current"/>
        </xsl:variable>
        <xsl:sequence select="@kind || '(' || string-join($name) || ')'"/>
    </xsl:template>
    
    
    
<!--    
    Literals
    -->
    
    <xsl:template match="string" mode="nk:xpath-serializer">
        <xsl:param name="config" as="map(*)" tunnel="yes"/>
        <xsl:variable name="quote-style" select="($config?literal-string-quote, 'auto')[1]"/>
        <xsl:variable name="value" select="@value/string()"/>
        
        <xsl:variable name="quote-style" select="
            if ($quote-style = 'auto') 
          then if (contains($value, '''') and not(contains($value, '&quot;'))) 
             then 'double' 
             else 'single' 
          else $quote-style
            "/>
        
        <xsl:variable name="quoteChars" select="map{
            'single' : '''',
            'double' : '&quot;'
            }"/>
        <xsl:variable name="quoteChar" select="$quoteChars($quote-style)"/>
        
        
        <xsl:sequence select="$quoteChar || replace($value, '(' || $quoteChar || ')', '$1$1') || $quoteChar"/>
    </xsl:template>
    
    <xsl:template match="decimal" mode="nk:xpath-serializer">
        <xsl:sequence select="string(@value/xs:decimal(.))"/>
    </xsl:template>

    <xsl:template match="double" mode="nk:xpath-serializer">
        <xsl:sequence select="nk:double-notation(@factor/xs:decimal(.), @exp/xs:integer(.))"/>
    </xsl:template>

    <xsl:template match="integer" mode="nk:xpath-serializer">
        <xsl:sequence select="string(@value/xs:integer(.))"/>
    </xsl:template>
    
    <!--    
    Misc Primitives
    -->
    <xsl:template match="empty" mode="nk:xpath-serializer">
        <xsl:sequence select="'()'"/>
    </xsl:template>

    <xsl:template match="self" mode="nk:xpath-serializer">
        <xsl:sequence select="'.'"/>
    </xsl:template>

    <xsl:template match="root" mode="nk:xpath-serializer">
        <xsl:sequence select="'/'"/>
    </xsl:template>

    <xsl:template match="varRef" mode="nk:xpath-serializer">
        <xsl:param name="config" as="map(*)" tunnel="yes"/>
        <xsl:sequence select="'$' || (@name => nk:as-qname() => nk:qname($config) )"/>
    </xsl:template>
    
    
    
<!--    
    ### ItemTypes ###
    -->

    <xsl:template match="operation/itemType" mode="nk:xpath-serializer" priority="90">
        <xsl:apply-templates select="*" mode="#current"/>
        <xsl:sequence select="nk:itemTypeOccSer(@occurrence)"/>
    </xsl:template>

    <xsl:template match="operation/itemType[not(*)]" mode="nk:xpath-serializer" priority="100">
        <xsl:sequence select="'item()', nk:itemTypeOccSer(@occurrence)"/>
    </xsl:template>
    
    
    <xsl:template match="itemType/atomic" mode="nk:xpath-serializer">
        <xsl:sequence select="@name/string()"/>
    </xsl:template>
    
    <xsl:function name="nk:itemTypeOccSer" as="xs:string">
        <xsl:param name="occurrence" as="attribute(occurrence)?"/>
        <xsl:variable name="map" select="map{
            'zero-or-more' : '*',
            'one-or-more' : '+',
            'zero-or-one' : '?',
            'one' : ''
            }"/>
        <xsl:variable name="token" select="($occurrence, 'one')[1]"/>
        <xsl:sequence select="
            $map($token)
            "/>
        
    </xsl:function>
    
    <!--    
    ### Operations ###
    -->

    <xsl:template match="operation" mode="nk:xpath-serializer">
        
        <xsl:variable name="needs-brackets" select="nk:needs-brackets(.)"/>
        
        <xsl:choose>
            <xsl:when test="$needs-brackets">
                <xsl:text>(</xsl:text>
                <xsl:apply-templates mode="#current"/>
                <xsl:text>)</xsl:text>
            </xsl:when>
            <xsl:otherwise>
                <xsl:apply-templates mode="#current"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    
    
    <xsl:function name="nk:get-preceding-operator" as="element()?">
        <xsl:param name="arg" as="element(arg)"/>
        <xsl:sequence select="
              if ($arg/preceding-sibling::*) 
            then ($arg/preceding-sibling::*[1]) 
            else if ($arg/parent::operation[nk:needs-brackets(.) or not(@type = parent::*/parent::operation/@type)]) 
               then () 
               else 
                    $arg/parent::operation/parent::arg/nk:get-preceding-operator(.)
            "/>
    </xsl:function>
    
    
    <xsl:function name="nk:needs-brackets" as="xs:boolean">
        <xsl:param name="operation" as="element(operation)"/>
        <xsl:variable name="parent-arg" select="$operation/parent::arg"/>
        <xsl:variable name="prec-operator" select="
            $parent-arg/nk:get-preceding-operator(.)
            "/>
        <xsl:variable name="logical-parent" select="
              if ($parent-arg) 
            then $parent-arg/parent::* 
            else $operation/parent::*
            "/>
        <xsl:variable name="op-type" select="$operation/@type"/>
        <xsl:variable name="logical-parent-name" select="$logical-parent/name()"/>
        <xsl:choose>
            <xsl:when test="$logical-parent-name = 'predicate' or $logical-parent-name = 'function-impl'">
                <xsl:sequence select="false()"/>
            </xsl:when>
            <xsl:when test="$logical-parent-name = 'let' and $op-type = 'sequence'">
                <xsl:sequence select="true()"/>
            </xsl:when>
            <xsl:when test="
                $logical-parent-name = 'array' and $logical-parent/@type = 'member-per-sequence' 
                    or 
                $logical-parent-name = 'function-call'
                ">
                <xsl:sequence select="$op-type = 'sequence'"/>
            </xsl:when>
            <xsl:when test="$logical-parent-name = 'operation'">
                <xsl:variable name="parent-op-type" select="$logical-parent/@type"/>
                
                <xsl:variable name="op-level" select="nk:op-type-level($op-type)"/>
                <xsl:variable name="parent-op-level" select="nk:op-type-level($parent-op-type)"/>
                <xsl:variable name="next-op" select="nk:get-follow-operator($parent-arg)"/>
                <xsl:choose>
                    <xsl:when test="$operation/itemType[(@occurrence, 'one')[1] = 'one'] and $next-op/name() = ('plus', 'x')">
                        <xsl:sequence select="true()"/>
                    </xsl:when>
                    <xsl:when test="$op-level lt $parent-op-level">
                        <xsl:sequence select="true()"/>
                    </xsl:when>
                    <xsl:when test="$op-level eq $parent-op-level">
                        <xsl:choose>
                            <xsl:when test="$op-type = $symetric-operations">
                                <xsl:sequence select="false()"/>
                            </xsl:when>
                            <xsl:when test="not($prec-operator)">
                                <xsl:sequence select="false()"/>
                            </xsl:when>
                            <xsl:when test="$prec-operator/name() = ('div', 'idiv', 'mod', 'except')">
                                <xsl:sequence select="true()"/>
                            </xsl:when>
                            <xsl:when test="$operation/(* except arg)/name() = ('div', 'idiv', 'mod')">
                                <xsl:sequence select="true()"/>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:sequence select="false()"/>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:sequence select="false()"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <xsl:otherwise>
                <xsl:sequence select="false()"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>
    
    
    <xsl:variable name="symetric-operations" select="
        'condition',
        'for-loop',
        'let-binding',
        'some-satisfies',
        'every-satisfies',
        'step',
        'concat',
        'union',
        'arrow',
        'unary',
        'map',
        'postfix'
        "/>
    
    <xsl:variable name="type-levels" select="
        'sequence',
        'for-loop|let-binding|some-satisfies|every-satisfies|condition',
        'or',
        'and',
        'compare|value-compare|node-compare',
        'concat',
        'range',
        'additive',
        'multiplicativ',
        'union',
        'intersect-except',
        'instance-of',
        'treat-as',
        'castable',
        'cast',
        'arrow',
        'unary',
        'map',
        'step',
        'postfix'
        "/>
    
    <xsl:variable name="symetric-operators" select="
        'x',
        'plus'
        "/>
    
    <xsl:function name="nk:op-type-level" as="xs:integer">
        <xsl:param name="type" as="xs:string"/>
        <xsl:variable name="type-id" select="exactly-one($type-levels[tokenize(., '\|') = $type])"/>
        <xsl:sequence select="index-of($type-levels, $type-id)"/>
    </xsl:function>
    
<!--    
    Serializes abbreviation '//' by skipping 'descendant-or-self::node()' between two slashes. 
    foo/descendant-or-self::node()/bar -> foo//bar 
    -->
    <xsl:template match="operation[@type = 'step']/arg[nk:is-desc-or-self-node-only-arg(.)]"
        mode="nk:xpath-serializer" priority="60"/>
    
    <xsl:template match="operation[@type = 'step']/slash[preceding-sibling::arg[1][nk:is-desc-or-self-node-only-arg(.)]]"
        mode="nk:xpath-serializer" priority="60"/>
    
    <xsl:template match="operation[@type = 'step']/slash[following-sibling::arg[1][nk:is-desc-or-self-node-only-arg(.)]]"
        mode="nk:xpath-serializer" priority="60">
        <xsl:next-match>
            <xsl:with-param name="operator-sign" select="'//'"/>
        </xsl:next-match>
    </xsl:template>
    
    <xsl:function name="nk:is-desc-or-self-node-only-arg" as="xs:boolean">
        <xsl:param name="arg" as="element(arg)"/>
        <xsl:sequence select="
            exists($arg
            [locationStep/@axis = 'descendant-or-self']
            [locationStep/nodeTest[@kind = 'node'][not(@name)]]
            [not(locationStep/predicate)]
            [preceding-sibling::slash]
            [following-sibling::slash]
            )"/>
    </xsl:function>
    
    
    <xsl:variable name="operatorMap" select="map{
        'plus' : '+',
        'minus' : '-',
        'x' : '*',
        'concat': '||',
        'union' : '|',
        'castAs' : 'cast as',
        'castableAs' : 'castable as',
        'treatAs' : 'treat as',
        'instanceOf' : 'instance of',
        'slash' : '/',
        'map' : '!',
        'comma': ',' 
        }"/>
    
    <xsl:template match="operation/*[$operatorMap(name())]" mode="nk:xpath-serializer" priority="40">
        <xsl:param name="config" as="map(*)" tunnel="yes"/>
        <xsl:param name="operator-sign" select="$operatorMap(name())"/>
        <xsl:next-match>
            <xsl:with-param name="operator-sign" select="$operator-sign"/>
        </xsl:next-match>
    </xsl:template>

    <xsl:template match="operation/div[@type = 'integer']" mode="nk:xpath-serializer" priority="40">
        <xsl:param name="config" as="map(*)" tunnel="yes"/>
        <xsl:next-match>
            <xsl:with-param name="operator-sign" select="'idiv'"/>
        </xsl:next-match>
    </xsl:template>
    
    <xsl:variable name="compareOperatorMap" select="map{
        'node-compare' : map{
            'lt' : '&lt;&lt;',
            'gt' : '>>',
            'eq' : 'is'
        },
        'compare' : map {
            'lt' : '&lt;',
            'gt' : '>',
            'le' : '&lt;=',
            'ge' : '>=',
            'ne' : '!=',
            'eq' : '='
        }
        }"/>
    <xsl:template match="operation[@type = map:keys($compareOperatorMap)]/*" mode="nk:xpath-serializer" priority="40">
        <xsl:param name="config" as="map(*)" tunnel="yes"/>
        <xsl:variable name="compareType" select="../@type"/>
        <xsl:variable name="operatorMap" select="$compareOperatorMap($compareType)"/>
        <xsl:variable name="operator-sign" select="$operatorMap(name())"/>
        
        <xsl:if test="not($operator-sign)">
            <xsl:message select="'Invalid operator ' || name() || ' for comparision type ' || $compareType" 
                terminate="yes"
            error-code="nk:XPXM001"
            />
        </xsl:if>
        
        <xsl:next-match>
            <xsl:with-param name="operator-sign" select="($operator-sign, '')[1]"/>
        </xsl:next-match>
    </xsl:template>

    <xsl:template match="operation/*" mode="nk:xpath-serializer" priority="-10">
        <xsl:param name="config" as="map(*)" tunnel="yes"/>
        <xsl:param name="operator-sign" select="name()" as="xs:string"/>
        <xsl:variable name="this" select="."/>
        <xsl:variable name="op-type" select="parent::operation/@type"/>
        <xsl:variable name="space-before" select="' '[nk:operator-space($operator-sign, $op-type, $this/preceding-sibling::arg[1], $config, true())]"/>
        <xsl:variable name="space-after" select="' '[nk:operator-space($operator-sign, $op-type, $this/following-sibling::arg[1], $config, false())]"/>
        <xsl:sequence select="$space-before || $operator-sign || $space-after"/>
    </xsl:template>

    
    
    
<!--    
    ### Helper Functions ###
    -->
    <xsl:function name="nk:as-qname" as="xs:QName">
        <xsl:param name="attr" as="attribute()"/>
        
        <xsl:variable name="element" select="$attr/parent::*"/>
        <xsl:variable name="name" select="string($attr)"/>
        <xsl:variable name="prefix" select="substring-before($name, ':')"/>
        <xsl:variable name="namespace" select="namespace-uri-for-prefix($prefix, $element)"/>
        <xsl:sequence select="QName($namespace, $name)"/>
    </xsl:function>
    
    <xsl:function name="nk:qname" as="xs:string">
        <xsl:param name="qname" as="xs:QName"/>
        <xsl:param name="config" as="map(*)"/>
        
        <xsl:variable name="namespace" select="namespace-uri-from-QName($qname)"/>
        <xsl:variable name="prefix" select="prefix-from-QName($qname)"/>
        <xsl:variable name="localname" select="local-name-from-QName($qname)"/>
        
        <xsl:variable name="prefixMappingMode" select="($config?prefix-mapping-mode, 'use-prefix-mapping'[exists($config?target-prefixes)], 'use-namespace-mapping'[exists($config?namespaces)], 'keep')[1]"/>
        
        <xsl:variable name="namespace-map" select="($config?namespaces, map{})[1]"/>
        
        <xsl:variable name="target-prefix" select="
            
            if ($namespace = '') 
          then '' 
          else if ($prefixMappingMode = 'keep') 
             then $prefix 
             else if ($prefixMappingMode = 'use-prefix-mapping')
                then ($config?target-prefixes($namespace)) 
                else if ($prefixMappingMode = 'use-namespace-mapping') 
                   then map:keys($namespace-map)[$namespace-map(.) = $namespace]
                   (: default and fallback mode is 'keep' :)
                   else $prefix
                   
            "/>
        
        <xsl:variable name="target-prefix" select="
            
            if (exists($target-prefix[. != ''])) 
            then $target-prefix || ':' 
            else if ($namespace = '') 
               then '' 
               else 'Q{' || $namespace || '}'
               
            "/>
        
        <xsl:sequence select="$target-prefix || $localname"/>
    </xsl:function>
    
    <xsl:function name="nk:double-notation" as="xs:string">
        <xsl:param name="factor" as="xs:decimal"/>
        <xsl:param name="exp" as="xs:integer"/>
        
        <xsl:choose>
            <xsl:when test="$factor = 0">
                <xsl:sequence select="'0e0'"/>
            </xsl:when>
            <xsl:when test="$factor lt 1">
                <xsl:sequence select="nk:double-notation($factor * 10, $exp - 1)"/>
            </xsl:when>
            <xsl:when test="$factor ge 10">
                <xsl:sequence select="nk:double-notation($factor div 10, $exp + 1)"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:sequence select="$factor || 'e' || $exp"/>
            </xsl:otherwise>
        </xsl:choose>
        
    </xsl:function>
    
    <xsl:variable name="operator-spacing" select="
        map{
            '#default' : map{
                ',' : map{
                    'before' : 'never'
                },
                '/' : map{
                    'before' : 'never',
                    'after' : 'never'
                },
                '-#unary' : map{
                    'before' : 'never',
                    'after' : 'never'
                },
                '+#unary' : map{
                    'before' : 'never',
                    'after' : 'never'
                },
                '//' : map{
                    'before' : 'never',
                    'after' : 'never'
                },
                '#other': map {
                    'before' : 'always',
                    'after' : 'always'
                },
                '#one-arg-operator': map {
                    'before' : 'never'
                }
            },
            'always' : map{
                '#other': map {
                    'before' : 'always',
                    'after' : 'always'
                }
            }
        }
        " as="map(xs:string, map(xs:string, map(xs:string, xs:string)))"/>
    
    <xsl:function name="nk:operator-space" as="xs:boolean">
        <xsl:param name="operator-sign" as="xs:string"/>
        <xsl:param name="opeation-type" as="xs:string"/>
        <xsl:param name="arg" as="element(arg)?"/>
        <xsl:param name="config" as="map(*)"/>
        <xsl:param name="before" as="xs:boolean"/>
        
        <xsl:variable name="spacing-strategy" select="($config?spacing-strategy, '#default')[1]"/>
        <xsl:variable name="op-spacing" select="$operator-spacing($spacing-strategy)"/>
        
        <xsl:variable name="op-sign-type" select="
            $operator-sign || '#' || $opeation-type
            "/>
        
        <xsl:variable name="isOneArgOperator" select="not($arg)"/>
        
        <xsl:variable name="op-sign-spacing" select="(
            (
                $op-spacing('#one-arg-operator'))[$isOneArgOperator], 
                $op-spacing($op-sign-type), 
                $op-spacing($operator-sign), 
                $op-spacing('#other')
            ) 
            => head()"/>
        
        <xsl:variable name="beforeAfter" select=" 
              if ($before) 
            then 'before' 
            else 'after'
            "/>
        
        
        <xsl:variable name="spacing" select="$op-sign-spacing($beforeAfter)"/>
        <xsl:sequence select="
              if ($spacing = 'always') 
            then true() 
            else if ($spacing = 'never') 
               then false() 
               else true() 
            "/>
    </xsl:function>
    
    
</xsl:stylesheet>