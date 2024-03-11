<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:math="http://www.w3.org/2005/xpath-functions/math"
    xmlns:t="http://www.w3.org/xpath-functions/spec/types"
    xmlns:xpt="http://www.nkutsche.com/xmlml/xpath-engine/types"
    xmlns:xpe="http://www.nkutsche.com/xpath-model/engine"
    xmlns:xpf="http://www.nkutsche.com/xmlml/xpath-engine/functions"
    xmlns:map="http://www.w3.org/2005/xpath-functions/map"
    xmlns:array="http://www.w3.org/2005/xpath-functions/array"
    xmlns:xpm="http://www.nkutsche.com/xpath-model"
    xmlns:err="http://www.w3.org/2005/xqt-errors"
    exclude-result-prefixes="math"
    version="3.0">
    <xsl:import href="xpath-functions/type-system.xsl"/>
    
    <xsl:variable name="xpt:xsd-namespace" select="'http://www.w3.org/2001/XMLSchema'"/>
    
    
    <xsl:function name="xpt:ancestor-type" as="element(itemType)">
        <xsl:param name="types" as="element(itemType)+"/>
        <xsl:variable name="type-count" select="count($types)"/>
        <xsl:choose>
            <xsl:when test="$type-count eq 1 ">
                <xsl:copy-of select="$types"/>
            </xsl:when>
            <xsl:when test="$type-count eq 2 ">
                <xsl:copy-of select="xpt:ancestor-type($types[1], $types[2])"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:variable name="first-half" select="$types[position() le ($type-count idiv 2)]"/>
                <xsl:copy-of select="xpt:ancestor-type(
                    xpt:ancestor-type($first-half), 
                    xpt:ancestor-type($types except $first-half)
                    )"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>
    
    <xsl:function name="xpt:is-type-ancestor-of" as="xs:boolean">
        <xsl:param name="explicit" as="element(itemType)"/>
        <xsl:param name="base" as="element(itemType)"/>
        
        <xsl:variable name="ancestor" select="xpt:ancestor-type(($explicit, $base))"/>
        
        <xsl:sequence select="deep-equal(xpt:normalize-type($ancestor), xpt:normalize-type($base))"/>
        
    </xsl:function>
    
    <xsl:function name="xpt:normalize-type" as="element(itemType)">
        <xsl:param name="type" as="element(itemType)"/>
        <xsl:apply-templates select="$type" mode="xpt:normalize-type"/>
    </xsl:function>
    <xsl:mode name="xpt:normalize-type" on-no-match="shallow-copy"/>
    
    <xsl:template match="itemType[not(@occurrence)]" mode="xpt:normalize-type">
        <xsl:copy>
            <xsl:attribute name="occurrence" select="'one'"/>
            <xsl:apply-templates select="@*" mode="#current"/>
            <xsl:apply-templates select="node()" mode="#current"/>
        </xsl:copy>
    </xsl:template>

    <xsl:template match="text()" mode="xpt:normalize-type"/>
    
    
    <xsl:function name="xpt:ancestor-type" as="element(itemType)">
        <xsl:param name="typeA" as="element(itemType)"/>
        <xsl:param name="typeB" as="element(itemType)"/>
        <xsl:variable name="type-categories" select="
            ($typeA/*/name(), $typeB/*/name())
            "/>
        <xsl:variable name="distinct-type-categories" select="
            $type-categories => distinct-values()
            "/>
        
        <xsl:variable name="a-occur" select="($typeA/@occurrence, 'one')[1]"/>
        <xsl:variable name="b-occur" select="($typeB/@occurrence, 'one')[1]"/>
        
        <xsl:variable name="occurrence" select="if ($a-occur = $b-occur) 
            then $a-occur
            (: 'one' or 'zero':)
            else (
            (if (exists(($a-occur, $b-occur)[starts-with(., 'zero')])) then 'zero' else 'one')
            || '-or-'
            || (if (exists(($a-occur, $b-occur)[ends-with(., '-more')])) then 'more' else 'one')
            )"/>
        <itemType>
            <xsl:if test="$occurrence != 'one'">
                <xsl:attribute name="occurrence" select="$occurrence"/>
            </xsl:if>
            <xsl:choose>
                <!-- a or b is empty-sequence() -->
                <xsl:when test="($a-occur, $b-occur) = 'zero'">
                    <!-- use the type content of the other type, as empty-sequence() | fooType -> fooType? -->
                    <xsl:copy-of select="($typeA, $typeB)/*"/>
                </xsl:when>
                <!-- a or b is already item() -->
                <xsl:when test="not($typeA/*) or not($typeB/*)">
                    <!-- empty -->
                </xsl:when>
                <!-- 
                    exception for both are deriving from function (function, map, array) 
                    but from different categories -> function(*) -->
                <xsl:when test="count($distinct-type-categories) gt 1 and (every $tc in $type-categories satisfies $tc = ('mapType', 'arrayType', 'functType'))">
                    <xsl:variable name="typeA" as="element(itemType)">
                        <itemType>
                            <xsl:copy-of select="xpt:arrayMap-as-funct($typeA/*)"/>
                        </itemType>
                    </xsl:variable>
                    <xsl:variable name="typeB" as="element(itemType)">
                        <itemType>
                            <xsl:copy-of select="xpt:arrayMap-as-funct($typeB/*)"/>
                        </itemType>
                    </xsl:variable>
                    <xsl:sequence select="xpt:ancestor-type($typeA, $typeB)/*"/>
                </xsl:when>
                <xsl:when test="count($distinct-type-categories) gt 1">
                    <!-- empty -->
                </xsl:when>
                <!-- both are atomic values: -->
                <xsl:when test="$distinct-type-categories = 'atomic'">
                    <xsl:variable name="a-name" select="$typeA/atomic/@name"/>
                    <xsl:variable name="a-name" select="resolve-QName($a-name, $typeA/atomic)"/>
                    <xsl:variable name="a-ns" select="namespace-uri-from-QName($a-name)"/>
                    
                    <xsl:variable name="a-xpt-type-name" select="
                        if ($a-ns = $xpt:xsd-namespace) 
                        then ('xs:' || local-name-from-QName($a-name)) 
                        else ('xs:anyAtomicType')
                        "/>
                    <xsl:variable name="a-xpt-type" select="$xpt:type-system//xpt:type[@name = $a-xpt-type-name]"/>
    
                    <xsl:variable name="b-name" select="$typeB/atomic/@name"/>
                    <xsl:variable name="b-name" select="resolve-QName($b-name, $typeB/atomic)"/>
                    <xsl:variable name="b-ns" select="namespace-uri-from-QName($b-name)"/>
                    
                    <xsl:variable name="b-xpt-type-name" select="
                        if ($b-ns = $xpt:xsd-namespace) 
                        then ('xs:' || local-name-from-QName($b-name)) 
                        else ('xs:anyAtomicType')
                        "/>
                    <xsl:variable name="b-xpt-type" select="$xpt:type-system//xpt:type[@name = $b-xpt-type-name]"/>
                    
                    <xsl:variable name="anc-type" select="($a-xpt-type/ancestor-or-self::xpt:type intersect $b-xpt-type/ancestor-or-self::xpt:type)[last()]"/>
                    
                    <atomic name="{($anc-type/@name, 'xs:anyAtomicType')[1]}">
                        <xsl:namespace name="xs" select="$build-in-namespaces('xs')"/>
                    </atomic>
                    
                </xsl:when>
                <!-- both are nodes -->
                <xsl:when test="$distinct-type-categories = 'nodeTest'">
                    <xsl:variable name="a-nodeTest" select="$typeA/nodeTest"/>
                    <xsl:variable name="b-nodeTest" select="$typeB/nodeTest"/>
                    <xsl:variable name="kind-equal" select="$a-nodeTest/@kind = $b-nodeTest/@kind"/>
                    <nodeTest>
                        <xsl:attribute name="kind" select="
                            if ($kind-equal) then ($a-nodeTest/@kind) else 'node'
                            "/>
                        <xsl:if test="$kind-equal">
                            <xsl:variable name="a-name" select="$a-nodeTest/@name/resolve-QName(., ..)"/>
                            <xsl:variable name="b-name" select="$b-nodeTest/@name/resolve-QName(., ..)"/>
                            <xsl:variable name="name-equal" select="$a-name = $b-name"/>
                            <xsl:if test="$name-equal">
                                <xsl:attribute name="name" select="$a-name"/>
                            </xsl:if>
                            <xsl:if test="$a-nodeTest/@kind = 'document-node'">
                                <xsl:variable name="root-types" as="element(itemType)*">
                                    <itemType>
                                        <xsl:copy-of select="$a-nodeTest/nodeTest"/>
                                    </itemType>
                                    <itemType>
                                        <xsl:copy-of select="$b-nodeTest/nodeTest"/>
                                    </itemType>
                                </xsl:variable>
                                <xsl:sequence select="xpt:ancestor-type($root-types)/nodeTest"/>
                            </xsl:if>
                        </xsl:if>
                    </nodeTest>
                </xsl:when>
                
                <xsl:when test="$distinct-type-categories = 'functType'">
                    <xsl:variable name="a-functType" select="$typeA/functType"/>
                    <xsl:variable name="b-functType" select="$typeB/functType"/>
                    <functType>
                        <xsl:variable name="a-args" select="$a-functType/(* except child::as)"/>
                        <xsl:variable name="b-args" select="$b-functType/(* except child::as)"/>
                        <xsl:variable name="a-arity" select="count($a-args)"/>
                        <xsl:variable name="b-arity" select="count($b-args)"/>
                        
                        <xsl:variable name="sign-available" select="
                            $a-arity eq $b-arity
                            and
                            (
                                every $i in (1 to $a-arity) 
                                satisfies
                                    (
                                        xpt:is-type-ancestor-of($a-functType/*[$i], $b-functType/*[$i])
                                        or
                                        xpt:is-type-ancestor-of($b-functType/*[$i], $a-functType/*[$i])
                                    )
                            )
                            "/>
                        
                        <xsl:variable name="args">
                            <xsl:for-each select="1 to max(($a-arity, $b-arity))">
                                <xsl:variable name="i" select="."/>
                                <xsl:variable name="a-arg" select="$a-args[$i]"/>
                                <xsl:variable name="b-arg" select="$b-args[$i]"/>
                                <xsl:choose>
                                    <xsl:when test="not($a-arg) or not($b-arg)">
                                        <NULL/>
                                    </xsl:when>
                                    <xsl:when test="xpt:is-type-ancestor-of($a-arg, $b-arg)">
                                        <xsl:sequence select="$a-arg"/>
                                    </xsl:when>
                                    <xsl:when test="xpt:is-type-ancestor-of($b-arg, $a-arg)">
                                        <xsl:sequence select="$b-arg"/>
                                    </xsl:when>
                                    <xsl:otherwise>
                                        <NULL/>
                                    </xsl:otherwise>
                                </xsl:choose>
                            </xsl:for-each>
                        </xsl:variable>
                        
                        <xsl:if test="not($args/NULL)">
                            <xsl:sequence select="$args"/>
                            <as>
                                <xsl:sequence select="xpt:ancestor-type(($a-functType, $b-functType)/as/*)"/>
                            </as>
                        </xsl:if>
                    </functType>
                </xsl:when>

                <xsl:when test="$distinct-type-categories = 'mapType'">
                    <xsl:variable name="a-mapType" select="$typeA/mapType"/>
                    <xsl:variable name="b-mapType" select="$typeB/mapType"/>
                    <mapType>
                        <xsl:if test="not(($a-mapType, $b-mapType)[empty(*)])">
                            <xsl:variable name="a-keyType" as="element(itemType)">
                                <itemType>
                                    <xsl:copy-of select="$a-mapType/atomic"/>
                                </itemType>
                            </xsl:variable>
                            <xsl:variable name="b-keyType" as="element(itemType)">
                                <itemType>
                                    <xsl:copy-of select="$b-mapType/atomic"/>
                                </itemType>
                            </xsl:variable>
                            <xsl:variable name="keyType" select="
                                xpt:ancestor-type($a-keyType, $b-keyType)"/>
                            <xsl:variable name="valueType" select="
                                xpt:ancestor-type(($a-mapType, $b-mapType)/itemType)"/>
                            <xsl:if test="
                                some $t in ($keyType, $valueType) satisfies 
                                    $t/* or $t[@occurrence != 'one']
                                ">
                                <xsl:copy-of select="$keyType/atomic, $valueType"/>
                            </xsl:if>
                        </xsl:if>
                    </mapType>
                </xsl:when>
                <xsl:when test="$distinct-type-categories = 'arrayType'">
                    <xsl:variable name="a-arrayType" select="$typeA/arrayType"/>
                    <xsl:variable name="b-arrayType" select="$typeB/arrayType"/>
                    <arrayType>
                        <xsl:variable name="memberTypes" select="($a-arrayType, $b-arrayType)/*"/>
                        <xsl:variable name="valueType" select="
                            if (empty($memberTypes)) 
                            then () 
                            else xpt:ancestor-type(($a-arrayType, $b-arrayType)/*)"/>
                        <xsl:sequence select="$valueType[* or @occurrence != 'one']"/>
                    </arrayType>
                </xsl:when>
                <xsl:otherwise>
                    <!-- empty -->
                </xsl:otherwise>
            </xsl:choose>
        </itemType>
    </xsl:function>
    
    <xsl:function name="xpt:arrayMap-as-funct" as="element(functType)">
        <xsl:param name="arrayMapType" as="element()"/>
        <xsl:apply-templates select="$arrayMapType" mode="xpt:arrayMap-as-funct"/>
    </xsl:function>
    
    <xsl:template match="functType" mode="xpt:arrayMap-as-funct">
        <xsl:sequence select="."/>
    </xsl:template>
    
    <xsl:template match="arrayType" mode="xpt:arrayMap-as-funct">
        <functType>
            <itemType>
                <atomic name="xs:integer"/>
            </itemType>
            <as>
                <xsl:copy-of select="itemType"/>
            </as>
        </functType>
    </xsl:template>

    <xsl:template match="mapType" mode="xpt:arrayMap-as-funct">
        <functType>
            <itemType>
                <atomic name="xs:anyAtomicType">
                    <xsl:namespace name="xs" select="$build-in-namespaces('xs')"/>
                </atomic>
            </itemType>
            <as>
                <xsl:copy-of select="itemType"/>
            </as>
        </functType>
    </xsl:template>
    
    
    <xsl:function name="xpt:type-of-sequence" as="element(itemType)">
        <xsl:param name="items" as="item()*"/>
        <xsl:choose>
            <xsl:when test="empty($items)">
                <itemType occurrence="zero"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:variable name="more-than-one" select="count($items) gt 1"/>
                <xsl:variable name="item-types" select="$items ! xpt:type-of(.)"/>
                <xsl:variable name="anc-type" select="xpt:ancestor-type($item-types)"/>
                <xsl:choose>
                    <xsl:when test="$more-than-one">
                        <xsl:copy select="$anc-type">
                            <xsl:sequence select="@*"/>
                            <xsl:attribute name="occurrence" select="'one-or-more'"/>
                            <xsl:sequence select="node()"/>
                        </xsl:copy>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:sequence select="$anc-type"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:otherwise>
        </xsl:choose>
        
    </xsl:function>
    
    <xsl:function name="xpt:type-of" as="element(itemType)">
        <xsl:param name="item" as="item()"/>
        <itemType>
            <xsl:apply-templates select="$xpt:type-system/*" mode="xpt:type-of">
                <xsl:with-param name="item" select="$item" tunnel="yes"/>
            </xsl:apply-templates>
        </itemType>
    </xsl:function>

    <xsl:function name="xpt:castable-as" as="xs:boolean">
        <xsl:param name="input" as="item()*"/>
        <xsl:param name="type" as="element(itemType)"/>
        
        <xsl:variable name="qname" select="$type/atomic/resolve-QName(@name, .)"/>
        <xsl:variable name="validator" select="xpt:get-type-validator($qname)"/>
        
        <xsl:choose>
            <xsl:when test="not($validator?is-castable)">
                <!-- If the type is not castable, this will throwing always an error:-->
                <xsl:sequence select="$validator?castable-as(())"/>
            </xsl:when>
            <xsl:when test="empty($input) and $type/@occurrence = 'zero-or-one'">
                <xsl:sequence select="true()"/>
            </xsl:when>
            <xsl:when test="empty($input)">
                <xsl:sequence select="false()"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:sequence select="$validator?castable-as($input)"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>
    
    <xsl:function name="xpt:cast-as" as="item()?">
        <xsl:param name="input" as="item()?"/>
        <xsl:param name="type" as="element(itemType)"/>
        
        <xsl:variable name="qname" select="$type/atomic/resolve-QName(@name, .)"/>
        <xsl:variable name="validator" select="xpt:get-type-validator($qname)"/>
        <xsl:variable name="req-type" select="xpm:xpath-serializer-sub($type) => normalize-space()"/>
        
        <xsl:choose>
            <xsl:when test="not($validator?is-castable)">
                <!-- If the type is not castable, this will throwing always an error:-->
                <xsl:sequence select="$validator?cast-as(())"/>
            </xsl:when>
            <xsl:when test="empty($input) and $type/@occurrence = 'zero-or-one'">
                <xsl:sequence select="()"/>
            </xsl:when>
            <xsl:when test="empty($input)">
                <xsl:sequence select="error(xpe:error-code('XPTY0004'), 'Can not cast empty sequence to ' || $req-type || '.')"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:try>
                    <xsl:sequence select="$validator?cast-as($input)"/>
                    <xsl:catch errors="err:XPTY0004">
                        <xsl:variable name="deliverded-type" select="
                            xpt:type-of($input) => xpm:xpath-serializer-sub() => normalize-space()
                            "/>
                        <xsl:sequence select="error(xpe:error-code('XPTY0004'), 'Can not cast delivered type ' || $deliverded-type || ' to ' || $req-type || '.')"/>
                    </xsl:catch>
                    <xsl:catch errors="err:FORG0001">
                        <xsl:variable name="deliverded-type" select="
                            xpt:type-of($input) => xpm:xpath-serializer-sub() => normalize-space()
                            "/>
                        <xsl:sequence select="error(xpe:error-code('FORG0001'), 'Can not cast delivered type ' || $deliverded-type || ' to ' || $req-type || '.')"/>
                    </xsl:catch>
                </xsl:try>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>
    
    
    <xsl:function name="xpe:treat-as" as="item()*">
        <xsl:param name="exec-context" as="map(*)"/>
        <xsl:param name="input" as="item()*"/>
        <xsl:param name="type" as="element(itemType)"/>
        <xsl:sequence select="xpe:operation($exec-context, [$input, $type], 'treat-as')"/>
    </xsl:function>
    <xsl:function name="xpt:treat-as" as="item()*">
        <xsl:param name="exec-context" as="map(*)"/>
        <xsl:param name="input" as="item()*"/>
        <xsl:param name="type" as="element(itemType)"/>
        <xsl:choose>
            <xsl:when test="not(xpe:instance-of($exec-context, $input, $type))">
                <xsl:variable name="req-type" select="xpm:xpath-serializer-sub($type) => normalize-space()"/>
                <xsl:variable name="deliverded-type" select="
                    xpt:type-of-sequence($input) => xpm:xpath-serializer-sub() => normalize-space()
                    "/>
                <xsl:sequence select="error(xpe:error-code('XPDY0050'), 'Required type was ' || $req-type || ' but delivered was ' || $deliverded-type)"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:apply-templates select="$type" mode="xpt:treat-as">
                    <xsl:with-param name="input" select="$input" tunnel="yes"/>
                    <xsl:with-param name="exec-context" select="$exec-context" tunnel="yes"/>
                </xsl:apply-templates>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>
    
    <xsl:template match="itemType[*]" mode="xpt:treat-as" priority="10">
        <xsl:param name="input" tunnel="yes" as="item()*"/>
        <xsl:variable name="this" select="."/>
        <xsl:for-each select="$input">
            <xsl:apply-templates select="$this/*" mode="#current">
                <xsl:with-param name="input" select="." tunnel="yes"/>
            </xsl:apply-templates>
        </xsl:for-each>
    </xsl:template>

    <xsl:template match="itemType" mode="xpt:treat-as">
        <xsl:param name="input" tunnel="yes" as="item()*"/>
        <xsl:sequence select="$input"/>
    </xsl:template>
    
    <xsl:template match="functType[./as]" mode="xpt:treat-as" priority="30">
        <xsl:param name="input" tunnel="yes" as="map(*)"/>
        <xsl:variable name="result" as="map(*)">
            <xsl:next-match>
                <xsl:with-param name="input" select="$input" tunnel="yes"/>
            </xsl:next-match>
        </xsl:variable>
        <xsl:sequence select="map:put($result, 'return-type', ./as/*)"/>
    </xsl:template>

    <xsl:template match="functType[* except ./as]" mode="xpt:treat-as" priority="20">
        <xsl:param name="input" tunnel="yes" as="map(*)"/>
        <xsl:variable name="arg-types" select="* except ./as"/>
        <xsl:variable name="result" as="map(*)">
            <xsl:next-match>
                <xsl:with-param name="input" select="$input" tunnel="yes"/>
            </xsl:next-match>
        </xsl:variable>
        <xsl:sequence select="map:put($result, 'arg-types', $arg-types)"/>
    </xsl:template>
    
    <xsl:template match="mapType[*]" mode="xpt:treat-as">
        <xsl:param name="exec-context" tunnel="yes" as="map(*)"/>
        <xsl:param name="input" tunnel="yes" as="map(*)"/>
        <xsl:variable name="keyType" as="element(itemType)">
            <itemType>
                <xsl:copy-of select="atomic"/>
            </itemType>
        </xsl:variable>
        <xsl:variable name="valueType" select="itemType | empty" as="element(itemType)"/>
        <xsl:map>
            <xsl:for-each select="map:keys($input)">
                <xsl:variable name="key" select="."/>
                <xsl:variable name="value" select="$input($key)"/>
                <xsl:map-entry key="xpe:treat-as($exec-context, $key, $keyType)" 
                    select="xpe:treat-as($exec-context, $value, $valueType)"
                />
            </xsl:for-each>
        </xsl:map>
    </xsl:template>
    
    <xsl:template match="arrayType[*]" mode="xpt:treat-as">
        <xsl:param name="exec-context" tunnel="yes" as="map(*)"/>
        <xsl:param name="input" tunnel="yes" as="array(*)"/>
        <xsl:variable name="memberType" select="*"/>
        <xsl:variable name="sub-arrays" select="
            for $i in 1 to array:size($input)
            return [xpe:treat-as($exec-context, $input($i), $memberType)]
            "/>
        <xsl:sequence select="array:join($sub-arrays)"/>
    </xsl:template>
    
    <xsl:template match="itemType/*" mode="xpt:treat-as" priority="-10">
        <xsl:param name="input" tunnel="yes" as="item()"/>
        <xsl:sequence select="$input"/>
    </xsl:template>
    
    
    <xsl:function name="xpe:instance-of" as="item()*">
        <xsl:param name="exec-context" as="map(*)"/>
        <xsl:param name="input" as="item()*"/>
        <xsl:param name="type" as="element(itemType)"/>
        <xsl:sequence select="xpe:operation($exec-context, [$input, $type], 'instance-of')"/>
    </xsl:function>
    <xsl:function name="xpt:instance-of" as="xs:boolean" visibility="final">
        <xsl:param name="exec-context" as="map(*)"/>
        <xsl:param name="input" as="item()*"/>
        <xsl:param name="type" as="element(itemType)"/>
        <xsl:apply-templates select="$type" mode="xpt:instance-of">
            <xsl:with-param name="input" select="$input" tunnel="yes"/>
        </xsl:apply-templates>
    </xsl:function>
    
    <xsl:template match="itemType" mode="xpt:instance-of">
        <xsl:param name="input" as="item()*" tunnel="yes"/>
        <xsl:variable name="occur" select="(@occurrence, 'one')[1]"/>
        <xsl:variable name="more" select="
            if (matches($occur, '-more$')) 
            then true() 
            else false()
            "/>
        <xsl:variable name="zero" select="
            if (matches($occur, '^zero')) 
            then true() 
            else false()
            "/>
        <xsl:choose>
            <xsl:when test="$occur = 'zero' and exists($input)">
                <xsl:sequence select="false()"/>
            </xsl:when>
            <xsl:when test="empty($input) and not($zero)">
                <xsl:sequence select="false()"/>
            </xsl:when>
            <xsl:when test="count($input) gt 1 and not($more)">
                <xsl:sequence select="false()"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:variable name="this" select="."/>
                <xsl:variable name="item-valids" as="xs:boolean*">
                    <xsl:for-each select="$input">
                        <xsl:apply-templates select="$this/*" mode="#current">
                            <xsl:with-param name="input" select="." tunnel="yes"/>
                        </xsl:apply-templates>
                    </xsl:for-each>
                </xsl:variable>
                <xsl:sequence select="empty($input) or (every $iv in $item-valids satisfies $iv)"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    
    <xsl:template match="atomic[@name]" mode="xpt:instance-of">
        <xsl:param name="input" as="item()" tunnel="yes"/>
        <xsl:variable name="qname" select="resolve-QName(@name, .)"/>
        <xsl:variable name="validator" select="xpt:get-type-validator($qname)"/>
        <xsl:sequence select="$validator?instance-of($input)"/>
    </xsl:template>
    
    <xsl:template match="nodeTest" mode="xpt:instance-of" priority="20">
        <xsl:param name="input" as="item()" tunnel="yes"/>
        <xsl:variable name="kind" select="(@kind, 'node')[1]"/>
        <!--  Mapping: document-node -> document, namespace-node -> namespace     -->
        <xsl:variable name="basic-type" select="replace($kind, '-node$', '')"/>
        <xsl:variable name="qname" select="QName('', $basic-type)"/>
        <xsl:variable name="validator" select="xpt:get-type-validator($qname)"/>
        <xsl:choose>
            <xsl:when test="not($validator?instance-of($input))">
                <xsl:sequence select="false()"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:next-match/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <xsl:template match="nodeTest[@kind = 'document-node'][nodeTest]" mode="xpt:instance-of" priority="15">
        <xsl:param name="input" as="document-node()" tunnel="yes"/>
        <xsl:apply-templates select="nodeTest" mode="#current">
            <xsl:with-param name="input" select="$input/*" tunnel="yes"/>
        </xsl:apply-templates>
    </xsl:template>
    
    <xsl:template match="nodeTest[@name]" mode="xpt:instance-of" priority="10">
        <xsl:param name="input" as="node()" tunnel="yes"/>
        <xsl:variable name="qname" select="
            if (@kind = 'processing-instruction') 
            then QName('', @name) 
            else resolve-QName(@name, .) (: default namespace? :)
            "/>
        <xsl:sequence select="node-name($input) eq $qname"/>
    </xsl:template>
    
    <xsl:template match="nodeTest" mode="xpt:instance-of" priority="-10">
        <xsl:sequence select="true()"/>
    </xsl:template>
    
    <xsl:template match="mapType" mode="xpt:instance-of" priority="20">
        <xsl:param name="input" as="item()" tunnel="yes"/>
        <xsl:choose>
            <xsl:when test="xpe:is-function($input)">
                <xsl:sequence select="false()"/>
            </xsl:when>
            <xsl:when test="not($input instance of map(*))">
                <xsl:sequence select="false()"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:next-match/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <xsl:template match="mapType[atomic]" mode="xpt:instance-of" priority="10">
        <xsl:param name="input" as="map(*)" tunnel="yes"/>
        <xsl:variable name="keys" select="map:keys($input)"/>
        <xsl:variable name="this" select="."/>
        <xsl:variable name="entry-valids" as="xs:boolean*">
            <xsl:for-each select="$keys">
                <xsl:variable name="key" select="."/>
                <xsl:variable name="key-valid" as="xs:boolean">
                    <xsl:apply-templates select="$this/atomic" mode="#current">
                        <xsl:with-param name="input" select="$key" tunnel="yes"/>
                    </xsl:apply-templates>
                </xsl:variable>
                <xsl:choose>
                    <xsl:when test="not($key-valid)">
                        <xsl:sequence select="false()"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:apply-templates select="$this/itemType" mode="#current">
                            <xsl:with-param name="input" select="$input($key)" tunnel="yes"/>
                        </xsl:apply-templates>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:for-each>
        </xsl:variable>
        <xsl:sequence select="empty($entry-valids) or (every $ev in $entry-valids satisfies $ev)"/>
    </xsl:template>
    
    <xsl:template match="mapType[not(*)]" mode="xpt:instance-of" priority="-10">
        <xsl:sequence select="true()"/>
    </xsl:template>
    
    <xsl:template match="arrayType" mode="xpt:instance-of" priority="20">
        <xsl:param name="input" as="item()" tunnel="yes"/>
        <xsl:choose>
            <xsl:when test="not($input instance of array(*))">
                <xsl:sequence select="false()"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:next-match/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <xsl:template match="arrayType[itemType]" mode="xpt:instance-of" priority="10">
        <xsl:param name="input" as="array(*)" tunnel="yes"/>
        <xsl:variable name="this" select="."/>
        
        <xsl:variable name="member-valids" as="xs:boolean*">
            <xsl:for-each select="1 to array:size($input)">
                <xsl:variable name="i" select="."/>
                <xsl:apply-templates select="$this/itemType" mode="#current">
                    <xsl:with-param name="input" select="$input($i)" tunnel="yes"/>
                </xsl:apply-templates>
            </xsl:for-each>
        </xsl:variable>
        <xsl:sequence select="empty($member-valids) or (every $ev in $member-valids satisfies $ev)"/>
    </xsl:template>
    
    <xsl:template match="arrayType[not(*)]" mode="xpt:instance-of" priority="-10">
        <xsl:sequence select="true()"/>
    </xsl:template>
    
    <xsl:template match="functType" mode="xpt:instance-of" priority="20">
        <xsl:param name="input" as="item()" tunnel="yes"/>
        <xsl:variable name="is-map" select="$input instance of map(*)"/>
        <xsl:variable name="is-array" select="$input instance of array(*)"/>
        <xsl:variable name="is-function" select="xpe:is-function($input)"/>
        <xsl:choose>
            <xsl:when test="not($is-function or $is-map or $is-array)">
                <xsl:sequence select="false()"/>
            </xsl:when>
            <xsl:when test="$is-function">
                <xsl:next-match/>
            </xsl:when>
            <xsl:when test="$is-map or $is-array">
                <xsl:choose>
                    <xsl:when test="not(./as)">
                        <xsl:sequence select="true()"/>
                    </xsl:when>
                    <xsl:when test="count(itemType) ne 1">
                        <xsl:sequence select="false()"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:variable name="as" select="./as/itemType"/>
                        <xsl:variable name="type-of" select="xpt:type-of($input)"/>
                        <xsl:variable name="valueType" select="$type-of/(mapType|arrayType)/itemType"/>
                        <xsl:variable name="valueType" as="element(itemType)">
                            <xsl:choose>
                                <xsl:when test="$valueType">
                                    <xsl:copy select="$valueType">
                                        <xsl:variable name="occurrence" select="@occurrence"/>
                                        <xsl:attribute name="occurrence" select="
                                            if ($occurrence = 'one-or-more') 
                                            then 'zero-or-more' 
                                            else if (matches($occurrence, '^zero')) 
                                            then $occurrence 
                                            else 'zero-or-one'
                                            "/>
                                        <xsl:copy-of select="@* | namespace::*"/>
                                        <xsl:copy-of select="node()"/>
                                    </xsl:copy>
                                </xsl:when>
                                <xsl:otherwise>
                                    <itemType occurrence="zero"/>
                                </xsl:otherwise>
                            </xsl:choose>
                        </xsl:variable>
                        <xsl:sequence select="xpt:is-type-ancestor-of($valueType, $as)"/>
                    </xsl:otherwise>
                </xsl:choose>
                <xsl:sequence select="true()"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:next-match/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template match="functType[as]" mode="xpt:instance-of" priority="10">
        <xsl:param name="input" as="map(*)" tunnel="yes"/>
        <xsl:variable name="function-type" select="xpt:type-of($input)"/>
        <xsl:variable name="this-type" as="element(itemType)">
            <itemType>
                <xsl:copy-of select="."/>
            </itemType>
        </xsl:variable>
        <xsl:sequence select="xpt:is-type-ancestor-of($function-type, $this-type)"/>
    </xsl:template>
    
    <xsl:template match="functType[not(*)]" mode="xpt:instance-of" priority="-10">
        <xsl:sequence select="true()"/>
    </xsl:template>
    
    
    
        
    <xsl:template match="xpt:type" mode="xpt:type-of" priority="50">
        <xsl:param name="item" as="item()" tunnel="yes"/>
        <xsl:variable name="name" select="@name"/>
        <xsl:variable name="instance-of-test" select="
            ancestor-or-self::*[@test][1] ! replace(@test, '\$n', $name)
            "/>
        <xsl:variable name="content" as="element()*">
            <xsl:apply-templates mode="#current"/>
        </xsl:variable>
        <!-- function is implemented as map(*) containing an entry with the raw function-->
        <xsl:variable name="item" select="xpe:raw-function($item)"/>
        
        <xsl:variable name="raw-type-validator" select="function-lookup(xpe:get-function-name-by-type(.), 0)()"/>
        <xsl:choose>
            <xsl:when test="not($raw-type-validator?instance-of($item))"/>
            <xsl:when test="$content">
                <xsl:sequence select="$content[1]"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:next-match/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <xsl:template match="xpt:type[@name = 'xs:anyAtomicType'] | xpt:type[@name = 'xs:anyAtomicType']//xpt:type" mode="xpt:type-of">
        <xsl:param name="item" as="item()" tunnel="yes"/>
        <atomic name="{@name}">
            <xsl:copy-of select="namespace::*"/>
        </atomic>
    </xsl:template>
    
    
    <xsl:template match="xpt:type[@name = 'node']//xpt:type" mode="xpt:type-of">
        <xsl:param name="item" as="node()" tunnel="yes"/>
        
        <xsl:variable name="node-kind" select="
            if (@name = ('document', 'namespace')) 
            then @name || '-node' 
            else @name
            "/>
        <nodeTest kind="{$node-kind}">
            <xsl:if test="$node-kind = ('element', 'attribute', 'processing-instruction')">
                <xsl:variable name="name" select="name($item)"/>
                <xsl:variable name="namespace" select="namespace-uri($item)"/>
                <xsl:attribute name="name" select="$name"/>
                <xsl:if test="$namespace != ''">
                    <xsl:variable name="prefix" select="
                        if (contains($name, ':')) then substring-before($name, ':') else ('def')
                        "/>
                    <xsl:namespace name="{$prefix}" select="$namespace"/>
                </xsl:if>
            </xsl:if>
            
            <xsl:if test="$node-kind = 'document-node'">
                <xsl:variable name="types" select="$item/*/xpt:type-of(.)"/>
                <xsl:sequence select="xpt:ancestor-type($types)/nodeTest"/>
            </xsl:if>
        </nodeTest>
        
    </xsl:template>

    <xsl:template match="xpt:type[@name = 'function']" mode="xpt:type-of">
        <xsl:param name="item" as="item()" tunnel="yes"/>
        <functType>
            <xsl:sequence select="$item?arg-types"/>
            <as>
                <xsl:sequence select="$item?return-type"/>
            </as>
        </functType>
    </xsl:template>

    <xsl:template match="xpt:type[@name = 'map']" mode="xpt:type-of">
        <xsl:param name="item" as="map(*)" tunnel="yes"/>
        
        <mapType>
            <xsl:variable name="keys" select="map:keys($item)"/>
            <xsl:if test="exists($keys)">
                <xsl:variable name="keyItemTypes" select="$keys ! xpt:type-of(.) => xpt:ancestor-type()"/>
                <xsl:copy-of select="$keyItemTypes/atomic"/>
                <xsl:variable name="value-types" select="
                    $keys ! xpt:type-of-sequence($item(.))
                    "/>
                <xsl:sequence select="xpt:ancestor-type($value-types)"/>
            </xsl:if>
        </mapType>
            
        
    </xsl:template>

    <xsl:template match="xpt:type[@name = 'array']" mode="xpt:type-of">
        <xsl:param name="item" as="item()" tunnel="yes"/>
        <!-- the array could be wrapped into a function wrapper -->
        <xsl:variable name="item" select="xpe:raw-function($item)"/>
        <arrayType>
            <xsl:variable name="value-types" select="$item?* ! xpt:type-of(.)"/>
            <xsl:if test="exists($value-types)">
                <xsl:sequence select="xpt:ancestor-type($value-types)"/>
            </xsl:if>
        </arrayType>
        
    </xsl:template>
    
    <xsl:function name="xpt:get-type-validator" as="map(*)">
        <xsl:param name="qname" as="xs:QName"/>
        <xsl:variable name="validator-constructor"
            select="function-lookup(xpe:get-function-name-by-type-name($qname), 0)"/>
        <xsl:sequence select="
            if (empty($validator-constructor)) 
            then error(xpe:error-code('XPST0051'), 'Unknown atomic type ' || $qname || '.') 
            else $validator-constructor()
            "/>
    </xsl:function>
    
    
</xsl:stylesheet>