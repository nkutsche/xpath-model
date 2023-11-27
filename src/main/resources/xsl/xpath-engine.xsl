<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:math="http://www.w3.org/2005/xpath-functions/math"
    xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl"
    xmlns:xpm="http://www.nkutsche.com/xpath-model"
    xmlns:mlml="http://www.nkutsche.com/xmlml"
    xmlns:xpe="http://www.nkutsche.com/xpath-model/engine"
    xmlns:array="http://www.w3.org/2005/xpath-functions/array"
    xmlns:map="http://www.w3.org/2005/xpath-functions/map"
    xmlns:xpf="http://www.nkutsche.com/xmlml/xpath-engine/functions"
    xmlns:fn="http://www.w3.org/2005/xpath-functions"
    exclude-result-prefixes="xs math xd"
    version="3.0">
    <xsl:import href="xpath-engine-functions.xsl"/>
    
    
    <xsl:function name="xpe:xpath-evaluate">
        <xsl:param name="context" as="item()?"/>
        <xsl:param name="xpath" as="xs:string"/>
        <xsl:param name="execution-context" as="map(*)"/>
        
        <xsl:variable name="namespaces" select="($execution-context?namespaces, map{})[1]"/>
        <xsl:variable name="model" select="xpm:xpath-model($xpath, map{'namespaces' : $namespaces})"/>
        <xsl:variable name="execution-context" select="map:put($execution-context, 'context', $context)"/>
        <xsl:variable name="result" as="item()*">
            <xsl:apply-templates select="$model" mode="xpe:xpath-evaluate">
                <xsl:with-param name="execution-context" select="$execution-context" tunnel="yes"/>
            </xsl:apply-templates>
        </xsl:variable>
<!--        <xsl:sequence select="$model"/>-->
        <xsl:sequence select="$result"/>
        
    </xsl:function>
    
    
    <xsl:variable name="xpe:operations" select="
        map{
            'or' : function($arg1, $arg2){$arg1 or $arg2},
            'and' : function($arg1, $arg2){$arg1 and $arg2},
            'union' : function($arg1, $arg2){$arg1 | $arg2},
            'intersect' : function($arg1, $arg2){$arg1 intersect $arg2},
            'except' : function($arg1, $arg2){$arg1 except $arg2},
            'concat' : function($arg1, $arg2){xpe:atomize($arg1) || xpe:atomize($arg2)},
            'sequence#comma' : function($arg1, $arg2){$arg1, $arg2},
            'compare#gt' : function($arg1, $arg2){xpe:atomize($arg1) > xpe:atomize($arg2)},
            'compare#lt' : function($arg1, $arg2){xpe:atomize($arg1) &lt; xpe:atomize($arg2)},
            'compare#ge' : function($arg1, $arg2){xpe:atomize($arg1) >= xpe:atomize($arg2)},
            'compare#le' : function($arg1, $arg2){xpe:atomize($arg1) &lt;= xpe:atomize($arg2)},
            'compare#ne' : function($arg1, $arg2){xpe:atomize($arg1) != xpe:atomize($arg2)},
            'compare#eq' : function($arg1, $arg2){xpe:atomize($arg1) = xpe:atomize($arg2)},
            'value-compare#gt' : function($arg1, $arg2){xpe:atomize($arg1) gt xpe:atomize($arg2)},
            'value-compare#lt' : function($arg1, $arg2){xpe:atomize($arg1) lt xpe:atomize($arg2)},
            'value-compare#ge' : function($arg1, $arg2){xpe:atomize($arg1) ge xpe:atomize($arg2)},
            'value-compare#le' : function($arg1, $arg2){xpe:atomize($arg1) le xpe:atomize($arg2)},
            'value-compare#ne' : function($arg1, $arg2){xpe:atomize($arg1) ne xpe:atomize($arg2)},
            'value-compare#eq' : function($arg1, $arg2){xpe:atomize($arg1) eq xpe:atomize($arg2)},
            'node-compare#gt' : function($arg1, $arg2){$arg1 >> $arg2},
            'node-compare#lt' : function($arg1, $arg2){$arg1 &lt;&lt; $arg2},
            'node-compare#eq' : function($arg1, $arg2){$arg1 is $arg2},
            'to' : function($arg1, $arg2){xpe:atomize($arg1) to xpe:atomize($arg2)},
            'plus' : function($arg1, $arg2){xpe:atomize($arg1) + xpe:atomize($arg2)},
            'minus' : function($arg1, $arg2){xpe:atomize($arg1) - xpe:atomize($arg2)},
            'x' : function($arg1, $arg2){xpe:atomize($arg1) * xpe:atomize($arg2)},
            'mod' : function($arg1, $arg2){xpe:atomize($arg1) mod xpe:atomize($arg2)},
            'div' : function($arg1, $arg2){xpe:atomize($arg1) div xpe:atomize($arg2)},
            'idiv' : function($arg1, $arg2){xpe:atomize($arg1) idiv xpe:atomize($arg2)}
        }
        "
        as="map(xs:string, function(item()*, item()*) as item()*)"/>
    
    <xsl:function name="xpe:atomize" as="item()*" visibility="public">
        <xsl:param name="items" as="item()*"/>
        <xsl:sequence select="$items"/>
    </xsl:function>

    <xsl:function name="xpe:arg-array-atomize" as="array(*)">
        <xsl:param name="args" as="array(*)"/>
        <xsl:variable name="args" select="for $i in 1 to array:size($args) return [xpe:atomize($args($i))]"/>
        <xsl:sequence select="array:join($args)"/>
    </xsl:function>
    
<!--    
    Operations
    -->
    
    <xsl:function name="xpe:arg-array" as="array(*)" >
        <xsl:param name="args" as="element(arg)*"/>
        <xsl:param name="execution-context" as="map(*)"/>
        <xsl:variable name="single-arrs" as="array(*)*">
            <xsl:for-each select="$args">
                <xsl:variable name="content" as="item()*">
                    <xsl:apply-templates select="." mode="xpe:xpath-evaluate">
                        <xsl:with-param name="execution-context" select="$execution-context" tunnel="yes"/>
                    </xsl:apply-templates>
                </xsl:variable>
                <xsl:sequence select="[$content]"/>
            </xsl:for-each>
        </xsl:variable>
        <xsl:sequence select="array:join($single-arrs)"/>
    </xsl:function>

    <xsl:function name="xpe:fold-left-wizzard" as="item()*" >
        <xsl:param name="args" as="array(*)"/>
        <xsl:param name="operations" as="array(function(item()*, item()*) as item()*)"/>
        <xsl:variable name="arg-sz" select="array:size($args)"/>
        <xsl:choose>
            <xsl:when test="$arg-sz eq array:size($operations)">
                <xsl:sequence select="error(QName('', 'TODO'), 'Internal error!')"/>
            </xsl:when>
            <xsl:when test="$arg-sz lt 2">
                <xsl:sequence select="error(QName('', 'TODO'), 'Internal error!')"/>
            </xsl:when>
            <xsl:when test="$arg-sz eq 2">
                <xsl:variable name="op" select="$operations?1"/>
                <xsl:sequence select="$op($args?1, $args?2)"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:variable name="last" select="$args($arg-sz)"/>
                <xsl:variable name="operation" select="$operations($arg-sz - 1)"/>
                <xsl:variable name="temp-result" select="xpe:fold-left-wizzard(
                    array:remove($args, $arg-sz),
                    array:remove($operations, $arg-sz - 1)
                    )"/>
                <xsl:sequence select="$operation($temp-result, $last)"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>
    
    <xsl:template match="operation[count(arg) gt 1]" mode="xpe:xpath-evaluate">
        <xsl:param name="execution-context" as="map(*)" tunnel="yes"/>
        <xsl:variable name="arg-array"  select="xpe:arg-array(arg, $execution-context)"/>
        <xsl:variable name="operators" select="* except arg"/>
        <xsl:variable name="type" select="@type"/>
        <xsl:variable name="op-functions" as="(function(item()*, item()*) as item()*)*">
            <xsl:apply-templates select="$operators" mode="xpe:xpath-operator"/>
        </xsl:variable>
        
        <xsl:sequence select="xpe:fold-left-wizzard($arg-array, array{$op-functions})"/>
        
    </xsl:template>
    
    <xsl:template match="operation/*[exists($xpe:operations(../@type || '#' || local-name()))]" mode="xpe:xpath-operator" as="function(item()*, item()*) as item()*" priority="10">
        <xsl:sequence select="$xpe:operations(../@type || '#' || local-name())"/>
    </xsl:template>

    <xsl:template match="operation/*[exists($xpe:operations(local-name()))]" mode="xpe:xpath-operator" as="function(item()*, item()*) as item()*">
        <xsl:sequence select="$xpe:operations(local-name())"/>
    </xsl:template>
    
    <xsl:template match="operation/div[@type = 'integer']" mode="xpe:xpath-operator">
        <xsl:variable name="type" select="@type"/>
        <xsl:sequence select="$xpe:operations('idiv')"/>
    </xsl:template>
    
    <xsl:template match="operation[@type = 'unary']" mode="xpe:xpath-evaluate" priority="50">
        <xsl:param name="execution-context" tunnel="yes"/>
        <xsl:variable name="content" as="item()*">
            <xsl:apply-templates select="arg/*" mode="#current"/>
        </xsl:variable>
        <xsl:variable name="content" select="xpe:atomize($content)"/>
        <xsl:variable name="minus" select="minus"/>
        
        <xsl:sequence select="
            if (count($minus) mod 2 = 1) 
            then -($content) 
            else +($content)
            "/>
    </xsl:template>
    
    <xsl:template match="operation[@type = 'map']" mode="xpe:xpath-evaluate" name="xpe:xpath-map-operation" priority="50">
        <xsl:param name="execution-context" tunnel="yes"/>
        <xsl:param name="args" select="arg"/>
        
        <xsl:variable name="head-arg" select="head($args)"/>
        <xsl:variable name="tail-arg" select="tail($args)"/>
        
        <xsl:variable name="context" as="item()*">
            <xsl:apply-templates select="$head-arg/*" mode="#current"/>
        </xsl:variable>
        
        <xsl:choose>
            <xsl:when test="count($args) = 1">
                <xsl:sequence select="$context"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:for-each select="$context">
                    <xsl:variable name="sub-context" select="map{
                        'context' : .,
                        'position' : position(),
                        'last' : last()
                        }"/>
                    <xsl:variable name="execution-context" select="($execution-context, $sub-context) => map:merge(map{'duplicates' : 'use-last'})"/>
                    <xsl:call-template name="xpe:xpath-map-operation">
                        <xsl:with-param name="execution-context" select="$execution-context" tunnel="yes"/>
                        <xsl:with-param name="args" select="$tail-arg"/>
                    </xsl:call-template>
                </xsl:for-each>
            </xsl:otherwise>
        </xsl:choose>
        
    </xsl:template>
    
    <xsl:template match="operation[@type = 'step'][count(arg) = 1]" mode="xpe:xpath-evaluate" priority="20">
        <xsl:param name="execution-context" tunnel="yes"/>
        <xsl:variable name="context" as="item()?" select="xpf:root($execution-context)"/>
        <xsl:variable name="result" as="item()*">
            <xsl:apply-templates select="arg/*" mode="#current">
                <xsl:with-param name="execution-context" select="map:put($execution-context, 'context', $context)" tunnel="yes"/>
            </xsl:apply-templates>
        </xsl:variable>
        <xsl:sequence select="xpe:xpath-step-result-reorder($result)"/>
    </xsl:template>

    <xsl:template match="operation[@type = 'step']" mode="xpe:xpath-evaluate" priority="10">
        <xsl:param name="execution-context" tunnel="yes"/>
        <xsl:variable name="context" as="item()*">
            <xsl:apply-templates select="arg[1]/*" mode="#current">
                <xsl:with-param name="execution-context" select="$execution-context" tunnel="yes"/>
            </xsl:apply-templates>
        </xsl:variable>
        <xsl:variable name="sub-expr" as="element(expr)">
            <expr>
                <xsl:choose>
                    <xsl:when test="slash[2]">
                        <xsl:copy>
                            <xsl:sequence select="@*"/>
                            <xsl:sequence select="slash[1]/following-sibling::*"/>
                        </xsl:copy>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:sequence select="arg[2]/*"/>
                    </xsl:otherwise>
                </xsl:choose>
            </expr>
        </xsl:variable>
        <xsl:variable name="result" as="item()*">
            <xsl:for-each select="$context">
                <xsl:variable name="sub-context" select="map{
                    'context' : .,
                    'position' : position(),
                    'last' : last()
                    }"/>
                <xsl:variable name="execution-context" select="($execution-context, $sub-context) => map:merge(map{'duplicates' : 'use-last'})"/>
                <xsl:apply-templates select="$sub-expr" mode="#current">
                    <xsl:with-param name="execution-context" select="$execution-context" tunnel="yes"/>
                </xsl:apply-templates>
            </xsl:for-each>
        </xsl:variable>
        <!--<xsl:if test="empty($result)">
            <xsl:message expand-text="yes"
                >Empty result for operation {xpm:xpath-serializer-sub(.)} -> {xpm:xpath-serializer-sub($sub-expr)}</xsl:message>
            <xsl:message expand-text="yes">Count context nodes: {count($context)} ({xpm:xpath-serializer-sub(arg[1]/*)})</xsl:message>
        </xsl:if>-->
        <xsl:sequence select="xpe:xpath-step-result-reorder($result)"/>
    </xsl:template>
    
    <xsl:function name="xpe:xpath-step-result-reorder" as="item()*">
        <xsl:param name="result" as="item()*"/>
        <xsl:choose>
            <xsl:when test="every $r in $result satisfies $r instance of node()">
                <xsl:sequence select="$result/."/>
            </xsl:when>
            <xsl:when test="every $r in $result satisfies not($r instance of node())">
                <xsl:sequence select="$result"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:sequence select="error(QName('', 'TODO'), 'Can not mix nodes and atomic values in the result of a path expression')"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>
    
    <xsl:template match="operation[@type = 'postfix'][predicate]" mode="xpe:xpath-evaluate" priority="10">
        <xsl:param name="execution-context" as="map(*)" tunnel="yes"/>
        <xsl:variable name="content" as="item()*">
            <xsl:apply-templates select="arg/*" mode="#current"/>
        </xsl:variable>
        <xsl:sequence select="xpe:apply-predicate($execution-context, $content, predicate)"/>
    </xsl:template>

    <xsl:template match="operation[@type = 'postfix'][function-call]" mode="xpe:xpath-evaluate" priority="10">
        <xsl:param name="execution-context" as="map(*)" tunnel="yes"/>
        <xsl:variable name="function" as="function(*)">
            <xsl:apply-templates select="arg/*" mode="#current"/>
        </xsl:variable>
        <xsl:variable name="args" select="xpe:arg-array(function-call/arg, $execution-context)"/>
        
        <xsl:variable name="funct-namespace" select="function-name($function) ! namespace-uri-from-QName(.)"/>
        
        <xsl:sequence select="xpe:function-apply($function, $args)"/>
    </xsl:template>

    <xsl:template match="operation[@type = 'let-binding']" mode="xpe:xpath-evaluate" name="xpe:xpath-let-operation" priority="10">
        <xsl:param name="execution-context" as="map(*)" tunnel="yes"/>
        <xsl:param name="lets" select="let" as="element(let)*"/>
        
        <xsl:choose>
            <xsl:when test="not($lets)">
                <xsl:apply-templates select="arg[@role = 'return']/*" mode="#current"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:variable name="let-head" select="head($lets)"/>
                <xsl:variable name="let-tail" select="tail($lets)"/>
                <xsl:variable name="let-value" as="item()*">
                    <xsl:apply-templates select="$let-head/arg/*" mode="#current"/>
                </xsl:variable>
                <!-- TODO Q{}: -->
                <xsl:variable name="let-name" select="xpm:varQName($let-head/@name)"/>
                <xsl:variable name="variables" select="($execution-context?variable-context, map{})[1]"/>
                <xsl:variable name="variables" select="map:put($variables, $let-name, $let-value)"/>
                <xsl:variable name="execution-context" select="map:put($execution-context, 'variable-context', $variables)"/>
                <xsl:call-template name="xpe:xpath-let-operation">
                    <xsl:with-param name="execution-context" select="$execution-context" tunnel="yes"/>
                    <xsl:with-param name="lets" select="$let-tail"/>
                </xsl:call-template>
            </xsl:otherwise>
        </xsl:choose>
        
    </xsl:template>

    <xsl:template match="operation[@type = 'for-loop']" mode="xpe:xpath-evaluate" name="xpe:xpath-for-operation" priority="10">
        <xsl:param name="execution-context" as="map(*)" tunnel="yes"/>
        <xsl:param name="lets" select="let" as="element(let)*"/>
        <xsl:param name="this" select="."/>
        
        <xsl:choose>
            <xsl:when test="not($lets)">
                <xsl:apply-templates select="$this/arg[@role = 'return']/*" mode="#current"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:variable name="let-head" select="head($lets)"/>
                <xsl:variable name="let-tail" select="tail($lets)"/>
                <xsl:variable name="let-values" as="item()*">
                    <xsl:apply-templates select="$let-head/arg/*" mode="#current"/>
                </xsl:variable>
                <!-- TODO Q{}: -->
                <xsl:variable name="let-name" select="xpm:varQName($let-head/@name)"/>
                <xsl:variable name="variables" select="($execution-context?variable-context, map{})[1]"/>
                
                <xsl:for-each select="$let-values">
                    <xsl:variable name="variables" select="map:put($variables, $let-name, .)"/>
                    <xsl:variable name="execution-context" select="map:put($execution-context, 'variable-context', $variables)"/>
                    <xsl:call-template name="xpe:xpath-for-operation">
                        <xsl:with-param name="execution-context" select="$execution-context" tunnel="yes"/>
                        <xsl:with-param name="lets" select="$let-tail"/>
                        <xsl:with-param name="this" select="$this"/>
                    </xsl:call-template>
                </xsl:for-each>
            </xsl:otherwise>
        </xsl:choose>
        
    </xsl:template>

    <xsl:template match="operation[@type = 'condition']" mode="xpe:xpath-evaluate" priority="10">
        <xsl:variable name="if" as="item()*">
            <xsl:apply-templates select="arg[@role = 'if']/*" mode="#current"/>
        </xsl:variable>
        <xsl:choose>
            <xsl:when test="boolean($if)">
                <xsl:apply-templates select="arg[@role = 'then']/*" mode="#current"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:apply-templates select="arg[@role = 'else']/*" mode="#current"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <xsl:template match="operation[@type = ('some-satisfies', 'every-satisfies')]" mode="xpe:xpath-evaluate" name="xpe:xpath-satisfies-operation" priority="10">
        <xsl:param name="execution-context" as="map(*)" tunnel="yes"/>
        <xsl:param name="lets" select="let" as="element(let)*"/>
        <xsl:param name="this" select="."/>
        <xsl:variable name="type" select="$this/@type"/>
        
        <xsl:choose>
            <xsl:when test="not($lets)">
                <xsl:variable name="return" as="item()*">
                    <xsl:apply-templates select="$this/arg[@role = 'satisfies']/*" mode="#current"/>
                </xsl:variable>
                <xsl:sequence select="boolean($return)"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:variable name="let-head" select="head($lets)"/>
                <xsl:variable name="let-tail" select="tail($lets)"/>
                <xsl:variable name="let-values" as="item()*">
                    <xsl:apply-templates select="$let-head/arg/*" mode="#current"/>
                </xsl:variable>
                <!-- TODO Q{}: -->
                <xsl:variable name="let-name" select="xpm:varQName($let-head/@name)"/>
                <xsl:variable name="variables" select="($execution-context?variable-context, map{})[1]"/>
                <xsl:variable name="result" as="xs:boolean*">
                    <xsl:for-each select="$let-values">
                        <xsl:variable name="variables" select="map:put($variables, $let-name, .)"/>
                        <xsl:variable name="execution-context" select="map:put($execution-context, 'variable-context', $variables)"/>
                        <xsl:call-template name="xpe:xpath-satisfies-operation">
                            <xsl:with-param name="execution-context" select="$execution-context" tunnel="yes"/>
                            <xsl:with-param name="lets" select="$let-tail"/>
                            <xsl:with-param name="this" select="$this"/>
                        </xsl:call-template>
                    </xsl:for-each>
                </xsl:variable>
                <xsl:sequence select="
                    if ($type = 'some-satisfies') 
                    then (
                        some $r in $result
                        satisfies $r
                    ) 
                    else (
                        every $r in $result
                        satisfies $r
                    )
                    "/>
            </xsl:otherwise>
        </xsl:choose>
        
    </xsl:template>
    
    
    <xsl:template match="operation[@type = 'instance-of'][itemType/nodeTest]" mode="xpe:xpath-evaluate" name="xpe:xpath-instance-of-op" priority="50">
        <xsl:param name="arg-value" as="item()*">
            <xsl:apply-templates select="arg/*" mode="#current"/>
        </xsl:param>
        
        <xsl:variable name="occur" select="itemType/@occurrence"/>
        
        <xsl:choose>
            <xsl:when test="not($arg-value instance of node()*)">
                <xsl:sequence select="false()"/>
            </xsl:when>
            <xsl:when test="$occur = ('one', 'zero-or-one') and count($arg-value) gt 1">
                <xsl:sequence select="false()"/>
            </xsl:when>
            <xsl:when test="$occur = ('one', 'one-or-more') and empty($arg-value)">
                <xsl:sequence select="false()"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:sequence select="every $n in $arg-value satisfies xpe:node-test($n, itemType/nodeTest)"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <xsl:template match="operation[@type = 'treat-as'][itemType/nodeTest]" mode="xpe:xpath-evaluate" priority="50">
        <xsl:param name="arg-value" as="item()*">
            <xsl:apply-templates select="arg/*" mode="#current"/>
        </xsl:param>
        <xsl:variable name="instance-of" as="xs:boolean">
            <xsl:call-template name="xpe:xpath-instance-of-op">
                <xsl:with-param name="arg-value" select="$arg-value"/>
            </xsl:call-template>
        </xsl:variable>
        <xsl:sequence select="
            if ($instance-of) 
            then ($arg-value) 
            else error(QName('', 'treat-as-fail'), 'Can not treat value ' || $arg-value || ' as ' || xpm:xpath-serializer-sub(itemType))
            "/>
    </xsl:template>
    
    
    <xsl:template match="operation[@type = ('castable', 'cast', 'instance-of', 'treat-as')]" mode="xpe:xpath-evaluate" priority="10">
        <xsl:variable name="context" as="item()*">
            <xsl:apply-templates select="arg/*" mode="#current"/>
        </xsl:variable>
        <xsl:variable name="subst-expr" as="element(expr)">
            <expr>
                <xsl:copy>
                    <xsl:sequence select="@*"/>
                    <arg>
                        <self/>
                    </arg>
                    <xsl:sequence select="* except arg"/>
                </xsl:copy>
            </expr>
        </xsl:variable>
        <xsl:variable name="subst-xpath" select="xpm:xpath-serializer($subst-expr)"/>
        <xsl:evaluate xpath="$subst-xpath" context-item="xpe:atomize($context)"/>
    </xsl:template>
    
    <xsl:template match="itemType | itemType//*" mode="xpe:xpath-evaluate">
        <xsl:copy>
            <xsl:apply-templates select="@*" mode="#current"/>
            <xsl:apply-templates select="node()" mode="#current"/>
        </xsl:copy>
    </xsl:template>
    
    
    
    <xsl:template match="itemType/nodeTest" mode="xpe:xpath-evaluate">
        <xsl:sequence select="."/>
    </xsl:template>
    
    <xsl:template match="*" mode="xpe:xpath-operator" priority="-100">
        <xsl:sequence select="error(QName('', 'TODO'), 'Unsupported XPath operation: ' || name(.))"/>
    </xsl:template>
    
    <xsl:template match="text()" mode="xpe:xpath-evaluate"/>
        
    
    
<!--    
    Primitives
    -->
    <xsl:template match="string" mode="xpe:xpath-evaluate">
        <xsl:sequence select="string(@value)"/>
    </xsl:template>

    <xsl:template match="integer" mode="xpe:xpath-evaluate">
        <xsl:sequence select="xs:integer(@value)"/>
    </xsl:template>

    <xsl:template match="decimal" mode="xpe:xpath-evaluate">
        <xsl:sequence select="xs:decimal(@value)"/>
    </xsl:template>

    <xsl:template match="double" mode="xpe:xpath-evaluate">
        <xsl:sequence select="xs:double(@factor) * math:pow(1E1, @exp)"/>
    </xsl:template>

    <xsl:template match="empty" mode="xpe:xpath-evaluate">
        <xsl:sequence select="()"/>
    </xsl:template>

    <xsl:template match="self" mode="xpe:xpath-evaluate">
        <xsl:param name="execution-context" as="map(*)" tunnel="yes"/>
        <xsl:if test="empty($execution-context?context)">
            <xsl:sequence select="error(QName('', 'TODO'), 'There is no given context in expression ''.'' ')"/>
        </xsl:if>
        <xsl:sequence select="$execution-context?context"/>
    </xsl:template>

    <xsl:template match="root" mode="xpe:xpath-evaluate" name="xpe:xpath-root">
        <xsl:param name="execution-context" as="map(*)" tunnel="yes"/>
        <xsl:variable name="context" select="$execution-context?context"/>
        <xsl:choose>
            <xsl:when test="empty($context) or not($context instance of node())">
                <xsl:sequence select="error(QName('', 'TODO'), 'The context must be a node for using ''/'' or ''root(.)''')"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:sequence select="xpf:root($execution-context)"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    
    <xsl:template match="varRef" mode="xpe:xpath-evaluate">
        <xsl:param name="execution-context" as="map(*)" tunnel="yes"/>
        <xsl:variable name="variables" select="($execution-context?variable-context, map{})[1]"/>
        
        <!--
            TODO: Check for Q{} syntax? 
        -->
        <xsl:variable name="varName" select="xpm:varQName(@name)" as="xs:QName"/>
        <xsl:if test="not(map:contains($variables, $varName))">
            <xsl:message expand-text="yes" terminate="yes"
                >Variable Q{{{namespace-uri-from-QName($varName)}}}{local-name-from-QName($varName)} not declared in this scope.</xsl:message>
        </xsl:if>
        <xsl:sequence select="$variables($varName)"/>
    </xsl:template>
    

    <xsl:template match="lookup" mode="xpe:xpath-evaluate" priority="-10">
        <xsl:param name="execution-context" as="map(*)" tunnel="yes"/>
        <xsl:variable name="context" select="$execution-context?context"/>
        <xsl:variable name="key" as="item()">
            <xsl:apply-templates select="integer | field | arg" mode="#current"/>
        </xsl:variable>
        <xsl:choose>
            <xsl:when test="$context instance of map(*) or $context instance of array(*)">
                <xsl:sequence select="$context($key)"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:sequence select="error(QName('', 'TODO'), 'Context of an unary lookup must be a map or array!')"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <xsl:template match="lookup/field" mode="xpe:xpath-evaluate">
        <xsl:sequence select="string(@name)"/>
    </xsl:template>
    
    
<!--    
    Location Steps
    -->
    
    
    <xsl:template match="locationStep" mode="xpe:xpath-evaluate">
        <xsl:param name="execution-context" as="map(*)" tunnel="yes"/>
        
        <xsl:variable name="context" select="$execution-context?context"/>
        
        <xsl:variable name="nodeTest" select="nodeTest"/>
        
        <xsl:variable name="expr" select="xpm:xpath-serializer-sub(.)"/>
        
        <xsl:variable name="nodes" select="
            if (empty($context)) 
            then error(QName('', 'TODO'), 'Context of a location step must be a node! Context is empty. (' || $expr || ')') 
            else if (not($context instance of node()) or empty($context)) 
            then error(QName('', 'TODO'), 'Context of a location step must be a node! Context: ' || $context) 
            else xpe:tree-walk($context, @axis, $nodeTest)
            "/>
        <xsl:sequence select="$nodes"/>
    </xsl:template>
    
    <xsl:template match="locationStep[predicate]" name="xpe:locationstep-predicate" mode="xpe:xpath-evaluate" priority="10">
        <xsl:param name="execution-context" as="map(*)" tunnel="yes"/>
        <xsl:param name="nodes" as="item()*">
            <xsl:next-match/>
        </xsl:param>
        <xsl:param name="cPredicate" select="predicate[1]" as="element(predicate)?"/>
        <xsl:choose>
            <xsl:when test="$cPredicate">
                <xsl:variable name="nodes" as="item()*">
                    <xsl:for-each select="$nodes">
                        <xsl:variable name="node" select="."/>
                        <xsl:variable name="sub-context" select="map{
                            'context' : $node,
                            'position' : position(),
                            'last' : last()
                            }"/>
                        <xsl:variable name="execution-context" select="($execution-context, $sub-context) => map:merge(map{'duplicates' : 'use-last'})"/>
                        
                        <xsl:variable name="predicate-result" as="xs:boolean">
                            <xsl:apply-templates select="$cPredicate" mode="#current">
                                <xsl:with-param name="execution-context" select="$execution-context" tunnel="yes"/>
                            </xsl:apply-templates>
                        </xsl:variable>
                        <xsl:sequence select="$node[$predicate-result]"/>
                    </xsl:for-each>
                </xsl:variable>
                <xsl:call-template name="xpe:locationstep-predicate">
                    <xsl:with-param name="nodes" select="$nodes"/>
                    <xsl:with-param name="cPredicate" select="predicate[. >> $cPredicate][1]"/>
                </xsl:call-template>
            </xsl:when>
            <xsl:otherwise>
                <xsl:sequence select="$nodes"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <xsl:function name="xpe:apply-predicate" as="item()*">
        <xsl:param name="execution-context" as="map(*)"/>
        <xsl:param name="items" as="item()*"/>
        <xsl:param name="predicates" as="element(predicate)*"/>
        <xsl:variable name="cPredicate" select="head($predicates)"/>
        <xsl:variable name="restPred" select="tail($predicates)"/>
        <xsl:choose>
            <xsl:when test="$predicates">
                <xsl:variable name="items" as="item()*">
                    <xsl:for-each select="$items">
                        <xsl:variable name="context" select="."/>
                        <xsl:variable name="sub-context" select="map{
                            'context' : $context,
                            'position' : position(),
                            'last' : last()
                            }"/>
                        <xsl:variable name="execution-context" select="($execution-context, $sub-context) => map:merge(map{'duplicates' : 'use-last'})"/>
                        <xsl:variable name="predicate-result" as="xs:boolean">
                            <xsl:apply-templates select="$cPredicate" mode="xpe:xpath-evaluate">
                                <xsl:with-param name="execution-context" select="$execution-context" tunnel="yes"/>
                            </xsl:apply-templates>
                        </xsl:variable>
                        <xsl:sequence select="$context[$predicate-result]"/>
                    </xsl:for-each>
                </xsl:variable>
                <xsl:sequence select="xpe:apply-predicate($execution-context, $items, $restPred)"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:sequence select="$items"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>
    
    <xsl:template match="predicate" mode="xpe:xpath-evaluate" as="xs:boolean">
        <xsl:param name="execution-context" as="map(*)" tunnel="yes"/>
        <xsl:variable name="content" as="item()*">
            <xsl:apply-templates mode="#current"/>
        </xsl:variable>
        <xsl:sequence select="
            if ($content instance of xs:integer) 
            then ($execution-context?position = $content) 
            else boolean($content)
           "/>
    </xsl:template>
    
    <xsl:function name="xpe:tree-walk" as="node()*" visibility="public">
        <xsl:param name="context" as="node()"/>
        <xsl:param name="axis" as="xs:string"/>
        <xsl:param name="node-test" as="element()?"/>
        
        <xsl:choose>
            <xsl:when test="$axis = 'child'">
                <xsl:sequence select="$context/node()[xpe:node-test(., $node-test)]"/>
            </xsl:when>
            <xsl:when test="$axis = 'self'">
                <xsl:sequence select="$context[xpe:node-test(., $node-test)]"/>
            </xsl:when>
            <xsl:when test="$axis = 'attribute'">
                <xsl:sequence select="$context/@*[xpe:node-test(., $node-test)]"/>
            </xsl:when>
            <xsl:when test="$axis = 'namespace'">
                <xsl:sequence select="$context/namespace::*[xpe:node-test(., $node-test)]"/>
            </xsl:when>
            <xsl:when test="$axis = 'parent'">
                <xsl:sequence select="$context/parent::node()[xpe:node-test(., $node-test)]"/>
            </xsl:when>
            <xsl:when test="$axis = 'descendant'">
                <xsl:sequence select="$context/descendant::node()[xpe:node-test(., $node-test)]"/>
            </xsl:when>
            <xsl:when test="$axis = 'descendant-or-self'">
                <xsl:sequence select="
                    xpe:tree-walk($context, 'self', $node-test),
                    xpe:tree-walk($context, 'descendant', $node-test) 
                    "/>
            </xsl:when>
            <xsl:when test="$axis = 'ancestor'">
                <xsl:sequence select="$context/ancestor::node()[xpe:node-test(., $node-test)]"/>
            </xsl:when>
            <xsl:when test="$axis = 'ancestor-or-self'">
                <xsl:sequence select="
                    xpe:tree-walk($context, 'self', $node-test),
                    xpe:tree-walk($context, 'ancestor', $node-test) 
                    "/>
            </xsl:when>
            <xsl:when test="$axis = 'following-sibling'">
                <xsl:sequence select="$context/following-sibling::node()[xpe:node-test(., $node-test)]"/>
            </xsl:when>
            <xsl:when test="$axis = 'preceding-sibling'">
                <xsl:sequence select="$context ! preceding-sibling::node()[xpe:node-test(., $node-test)]"/>
            </xsl:when>
            <xsl:when test="$axis = 'following'">
                <xsl:sequence select="$context/following::node()[xpe:node-test(., $node-test)]"/>
            </xsl:when>
            <xsl:when test="$axis = 'preceding'">
                <xsl:sequence select="$context ! preceding::node()[xpe:node-test(., $node-test)]"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:sequence select="error(QName('', 'TODO'), 'Axis ' || $axis || ' not supported yet.')"/>
            </xsl:otherwise>
        </xsl:choose>
        
    </xsl:function>
    
    <xsl:function name="xpe:node-test" as="xs:boolean">
        <xsl:param name="node" as="node()"/>
        <xsl:param name="node-test" as="element(nodeTest)?"/>
        <xsl:variable name="node-kind" select="
            if ($node instance of processing-instruction()) 
            then 'processing-instruction' 
            else if ($node instance of attribute()) 
            then 'attribute' 
            else if ($node instance of comment()) 
            then 'comment' 
            else if ($node instance of namespace-node()) 
            then 'namespace-node' 
            else if ($node instance of element()) 
            then 'element' 
            else if ($node instance of document-node()) 
            then 'document-node' 
            else if ($node instance of text()) 
            then 'text' 
            else error(QName('', 'TODO'), 'Unknown node kind for ' || $node || '.')
            "/>
        <xsl:variable name="kind-test" select="($node-test/@kind, 'node')[1]"/>
        
        <xsl:sequence select="
            if (not(($node-kind, 'node') = $kind-test))
            then false()
            else 
            if ($node-kind = 'document-node' and $node-test/nodeTest) 
            then (xpe:node-test($node/*, $node-test/nodeTest))  
            else xpe:node-test-name($node, $node-test/@name)
            "/>
    </xsl:function>
    
    <xsl:function name="xpe:node-test-name" as="xs:boolean">
        <xsl:param name="node" as="node()"/>
        <xsl:param name="name-test" as="attribute()?"/>
        <xsl:variable name="name-matcher" select="xpm:name-matcher($name-test)"/>
        
        <xsl:variable name="node-local" select="($node/local-name(.), '*')"/>
        <xsl:variable name="node-ns" select="($node/namespace-uri(.), '*')"/>
        
        <xsl:choose>
            <xsl:when test="not($name-test)">
                <xsl:sequence select="true()"/>
            </xsl:when>
            <xsl:when test="
                $node instance of document-node() or $node instance of comment() or $node instance of text()
                ">
                <xsl:sequence select="true()"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:sequence select="
                    $node-local = $name-matcher?local and $node-ns = $name-matcher?namespace
                    "/>
            </xsl:otherwise>
        </xsl:choose>
        
    </xsl:function>
    
    
<!--    
    FUNCTIONS
    -->
    
    <xsl:variable name="fn_namespace-uri" select="'http://www.w3.org/2005/xpath-functions'"/>
    
    <xsl:template match="function-call" mode="xpe:xpath-evaluate">
        <xsl:param name="execution-context" as="map(*)" tunnel="yes"/>
        <xsl:param name="first-arg" as="array(item()*)" select="[]"/>

        <xsl:variable name="arg-array" select="xpe:arg-array(arg, $execution-context)"/>
        <xsl:variable name="arg-array" select="
            if (array:size($first-arg) gt 0) 
            then array:insert-before($arg-array, 1, $first-arg?1) 
            else $arg-array
            "/>
        <xsl:variable name="function" as="function(*)">
            <xsl:apply-templates select="function | expr" mode="#current">
                <xsl:with-param name="arity" select="array:size($arg-array)" tunnel="yes"/>
            </xsl:apply-templates>
        </xsl:variable>
        
        <xsl:variable name="funct-namespace" select="function-name($function) ! namespace-uri-from-QName(.)"/>
        
        <xsl:sequence select="xpe:function-apply($function, $arg-array)"/>
    </xsl:template>
    
    <xsl:template match="function[@name]" mode="xpe:xpath-evaluate">
        <xsl:param name="execution-context" as="map(*)" tunnel="yes"/>
        <xsl:param name="arity" select="@arity" as="xs:integer" tunnel="yes"/>
        
        <xsl:variable name="qname" select="xpm:name-matcher(@name)"/>
        <xsl:variable name="local-name" select="$qname?local"/>
        <xsl:variable name="ns-uri" select="$qname?namespace"/>
        
        <xsl:variable name="ns-uri" select="
            if ($ns-uri = '') then $fn_namespace-uri else $ns-uri
            "/>
        
        <xsl:variable name="funct-name" select="QName($ns-uri, $local-name)"/>
        <xsl:variable name="function" select="xpf:function-lookup($execution-context, $funct-name, $arity)"/>
        
        <xsl:sequence select="
            if (empty($function)) 
            then error(xpe:error-code('XPST0017'), 'Can not find a ' || $arity || '-argument function named Q{' || $ns-uri || '}' || $local-name)
            else 
                $function
            "/>
        
    </xsl:template>
    
    <xsl:template match="operation[@type = 'arrow']" mode="xpe:xpath-evaluate" name="xpe:xpath-arrow-operation">
        <xsl:param name="function-call" select="function-call" as="element(function-call)*"/>
        <xsl:param name="first-arg" as="item()*">
            <xsl:apply-templates select="arg/*" mode="#current"/>
        </xsl:param>
        <xsl:variable name="head" select="head($function-call)"/>
        <xsl:variable name="tail" select="tail($function-call)"/>
        
        <xsl:variable name="temp-result" as="item()*">
            <xsl:apply-templates select="$head" mode="#current">
                <xsl:with-param name="first-arg" select="[$first-arg]"/>
            </xsl:apply-templates>
        </xsl:variable>
        
        <xsl:choose>
            <xsl:when test="not($tail)">
                <xsl:sequence select="$temp-result"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:call-template name="xpe:xpath-arrow-operation">
                    <xsl:with-param name="function-call" select="$tail"/>
                    <xsl:with-param name="first-arg" select="$temp-result"/>
                </xsl:call-template>
            </xsl:otherwise>
        </xsl:choose>
        
    </xsl:template>
    
    <xsl:function name="xpe:function-apply" as="item()*">
        <xsl:param name="function" as="function(*)"/>
        <xsl:param name="params" as="array(item()*)"/>
        
        <xsl:variable name="arity" select="array:size($params)"/>
        <xsl:choose>
            <xsl:when test="$arity = 0">
                <xsl:sequence select="$function()"/>
            </xsl:when>
            <xsl:when test="$arity = 1">
                <xsl:sequence select="$function($params?1)"/>
            </xsl:when>
            <xsl:when test="$arity = 2">
                <xsl:sequence select="$function($params?1, $params?2)"/>
            </xsl:when>
            <xsl:when test="$arity = 3">
                <xsl:sequence select="$function($params?1, $params?2, $params?3)"/>
            </xsl:when>
            <xsl:when test="$arity = 4">
                <xsl:sequence select="$function($params?1, $params?2, $params?3, $params?4)"/>
            </xsl:when>
            <xsl:when test="$arity = 5">
                <xsl:sequence select="$function($params?1, $params?2, $params?3, $params?4, $params?5)"/>
            </xsl:when>
            <xsl:when test="$arity = 6">
                <xsl:sequence select="$function($params?1, $params?2, $params?3, $params?4, $params?5, $params?6)"/>
            </xsl:when>
            <xsl:when test="$arity = 7">
                <xsl:sequence select="$function($params?1, $params?2, $params?3, $params?4, $params?5, $params?6, $params?7)"/>
            </xsl:when>
            <xsl:when test="$arity = 8">
                <xsl:sequence select="$function($params?1, $params?2, $params?3, $params?4, $params?5, $params?6, $params?7, $params?8)"/>
            </xsl:when>
            <xsl:when test="$arity = 9">
                <xsl:sequence select="$function($params?1, $params?2, $params?3, $params?4, $params?5, $params?6, $params?7, $params?8, $params?9)"/>
            </xsl:when>
            <xsl:when test="$arity = 10">
                <xsl:sequence select="$function($params?1, $params?2, $params?3, $params?4, $params?5, $params?6, $params?7, $params?8, $params?9, $params?10)"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:variable name="param-xpath" select="(1 to $arity) ! ('$p?' || .) => string-join(', ')"/>
                <xsl:variable name="xpath" select="'$f(' || $param-xpath || ')'"/>
                <xsl:evaluate xpath="$xpath" with-params="
                    map{
                        QName('','f') : $function,
                        QName('','p') : $params
                    }
                    "/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>
    
    <!-- 
        MAP / ARRAY
    -->
    
    <xsl:template match="map" mode="xpe:xpath-evaluate">
        <xsl:map>
            <xsl:apply-templates select="entry" mode="#current"/>
        </xsl:map>
    </xsl:template>
    
    <xsl:template match="map/entry" mode="xpe:xpath-evaluate">
        <xsl:variable name="key" as="item()*">
            <xsl:apply-templates select="arg[@role = 'key']/*" mode="#current"/>
        </xsl:variable>
        <xsl:variable name="value" as="item()*">
            <xsl:apply-templates select="arg[@role = 'value']/*" mode="#current"/>
        </xsl:variable>
        <xsl:map-entry key="xpe:atomize($key)" select="$value"/>
    </xsl:template>

    <!--    
        constructor: array{...}
    -->
    <xsl:template match="array[@type = 'member-per-item']" mode="xpe:xpath-evaluate">
        <xsl:variable name="members" as="item()*">
            <xsl:apply-templates select="arg/*" mode="#current"/>
        </xsl:variable>
        <xsl:sequence select="array{$members}"/>
    </xsl:template>

    <!--    
        constructor: [...]
    -->
    <xsl:template match="array[@type = 'member-per-sequence']" mode="xpe:xpath-evaluate">
        <xsl:variable name="members" as="array(item()*)*">
            <xsl:apply-templates select="arg" mode="#current"/>
        </xsl:variable>
        <xsl:sequence select="array:join($members)"/>
    </xsl:template>
    
    <xsl:template match="array[@type = 'member-per-sequence']/arg" mode="xpe:xpath-evaluate" priority="50">
        <xsl:variable name="members" as="item()*">
            <xsl:apply-templates select="*" mode="#current"/>
        </xsl:variable>
        <xsl:sequence select="[$members]"/>
    </xsl:template>
    
    <xsl:function name="xpe:error-code" as="xs:QName">
        <xsl:param name="code" as="xs:string"/>
        
        <xsl:sequence select="QName('http://www.w3.org/2005/xqt-errors', $code)"/>
        
    </xsl:function>
    
</xsl:stylesheet>