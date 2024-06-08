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
    xmlns:xpt="http://www.nkutsche.com/xmlml/xpath-engine/types"
    xmlns:fn="http://www.w3.org/2005/xpath-functions"
    xmlns:err="http://www.w3.org/2005/xqt-errors"
    xmlns:xpfs="http://www.nkutsche.com/xmlml/xpath-engine/xsd-constructors"
    exclude-result-prefixes="xs math xd"
    version="3.0">
    <xsl:import href="xpath-engine-functions.xsl"/>
    <xsl:import href="xpath-engine-types.xsl"/>
    
    
    <xsl:function name="xpe:xpath-evaluate" visibility="final">
        <xsl:param name="context" as="item()?"/>
        <xsl:param name="xpath" as="xs:string"/>
        <xsl:sequence select="xpe:xpath-evaluate($context, $xpath, map{})"/>
    </xsl:function>
    
    <xsl:function name="xpe:xpath-evaluate" visibility="final">
        <xsl:param name="context" as="item()?"/>
        <xsl:param name="xpath" as="xs:string"/>
        <xsl:param name="execution-context" as="map(*)"/>
        <xsl:try>
            <xsl:variable name="namespaces" select="($execution-context?namespaces, map{})[1]"/>
            <xsl:variable name="config" select="
                map{'namespaces' : $namespaces, 'ignore-undeclared-namespaces' : false()}
                "/>
            <xsl:variable name="model" select="
                xpm:xpath-model($xpath, $config, true())
                "/>
            <xsl:variable name="execution-context" select="map:put($execution-context, 'context', $context)"/>
            <xsl:variable name="model" select="$model => xpe:xpath-static-checks($execution-context)"/>
            <xsl:variable name="result" as="item()*">
                <xsl:apply-templates select="$model" mode="xpe:xpath-evaluate">
                    <xsl:with-param name="execution-context" select="$execution-context" tunnel="yes"/>
                </xsl:apply-templates>
            </xsl:variable>
            <xsl:sequence select="$result"/>
            <xsl:catch errors="xpm:xp-model-parse-error">
                <xsl:sequence select="error(xpe:error-code('XPST0003'), $err:description)"/>
            </xsl:catch>
            <xsl:catch errors="xpm:xp-model-undeclared-prefix">
                <xsl:sequence select="error(xpe:error-code('XPST0081'), $err:description)"/>
            </xsl:catch>
        </xsl:try>
        
    </xsl:function>
    
    <xsl:function name="xpe:xpath-static-checks" as="element(expr)">
        <xsl:param name="model" as="element(expr)"/>
        <xsl:param name="execution-context" as="map(*)"/>
        <xsl:apply-templates select="$model" mode="xpe:xpath-static-checks">
            <xsl:with-param name="execution-context" select="$execution-context" tunnel="yes"/>
        </xsl:apply-templates>
    </xsl:function>
    
    <xsl:mode name="xpe:xpath-static-checks" on-no-match="shallow-copy"/>
    
    <xsl:template match="function[@name]" mode="xpe:xpath-static-checks">
        <xsl:param name="arity" select="@arity"/>
        <xsl:variable name="qname" select="xpm:name-matcher(@name)"/>
        
        <xsl:variable name="function" as="function(*)">
            <xsl:apply-templates select="." mode="xpe:xpath-evaluate">
                <xsl:with-param name="arity" select="$arity" tunnel="yes"/>
            </xsl:apply-templates>
        </xsl:variable>
        
        <xsl:if test="exists($function)">
            <xsl:next-match/>
        </xsl:if>
        
    </xsl:template>
    
    <xsl:template match="function-call[function]" mode="xpe:xpath-static-checks">
        <xsl:variable name="arity" select="count(arg)"/>
        <xsl:variable name="arity" select="
            if (parent::operation[@type = 'arrow']) 
            then $arity + 1 
            else $arity
            "/>
        <xsl:copy>
            <xsl:apply-templates select="@*" mode="#current"/>
            <xsl:apply-templates select="node()" mode="#current">
                <xsl:with-param name="arity" select="$arity"/>
            </xsl:apply-templates>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="function-call/*" mode="xpe:xpath-static-checks" priority="-10">
        <xsl:copy>
            <xsl:apply-templates select="@*" mode="#current"/>
            <xsl:apply-templates select="node()" mode="#current"/>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="nodeTest[@kind = ('schema-element', 'schema-attribute')]" mode="xpe:xpath-static-checks" priority="10">
        <xsl:sequence select="error(xpe:error-code('XPST0008'), 
            'Node tests with ''' || @kind || '()'' are not supported!'
            )"/>
    </xsl:template>
    
    
    <xsl:variable name="xpe:operations" select="
        map{
            'or' : function($ctx, $arg1, $arg2){$arg1 or $arg2},
            'and' : function($ctx, $arg1, $arg2){$arg1 and $arg2},
            'union' : function($ctx, $arg1, $arg2){$arg1 | $arg2},
            'intersect' : function($ctx, $arg1, $arg2){$arg1 intersect $arg2},
            'except' : function($ctx, $arg1, $arg2){$arg1 except $arg2},
            'concat' : function($ctx, $arg1, $arg2){xpe:data($ctx, $arg1) || xpe:data($ctx, $arg2)},
            'sequence#comma' : function($ctx, $arg1, $arg2){$arg1, $arg2},
            'compare#gt' : function($ctx, $arg1, $arg2){xpe:data($ctx, $arg1) > xpe:data($ctx, $arg2)},
            'compare#lt' : function($ctx, $arg1, $arg2){xpe:data($ctx, $arg1) &lt; xpe:data($ctx, $arg2)},
            'compare#ge' : function($ctx, $arg1, $arg2){xpe:data($ctx, $arg1) >= xpe:data($ctx, $arg2)},
            'compare#le' : function($ctx, $arg1, $arg2){xpe:data($ctx, $arg1) &lt;= xpe:data($ctx, $arg2)},
            'compare#ne' : function($ctx, $arg1, $arg2){xpe:data($ctx, $arg1) != xpe:data($ctx, $arg2)},
            'compare#eq' : function($ctx, $arg1, $arg2){xpe:data($ctx, $arg1) = xpe:data($ctx, $arg2)},
            'value-compare#gt' : function($ctx, $arg1, $arg2){xpe:data($ctx, $arg1) gt xpe:data($ctx, $arg2)},
            'value-compare#lt' : function($ctx, $arg1, $arg2){xpe:data($ctx, $arg1) lt xpe:data($ctx, $arg2)},
            'value-compare#ge' : function($ctx, $arg1, $arg2){xpe:data($ctx, $arg1) ge xpe:data($ctx, $arg2)},
            'value-compare#le' : function($ctx, $arg1, $arg2){xpe:data($ctx, $arg1) le xpe:data($ctx, $arg2)},
            'value-compare#ne' : function($ctx, $arg1, $arg2){xpe:data($ctx, $arg1) ne xpe:data($ctx, $arg2)},
            'value-compare#eq' : function($ctx, $arg1, $arg2){xpe:data($ctx, $arg1) eq xpe:data($ctx, $arg2)},
            'node-compare#gt' : function($ctx, $arg1, $arg2){$arg1 >> $arg2},
            'node-compare#lt' : function($ctx, $arg1, $arg2){$arg1 &lt;&lt; $arg2},
            'node-compare#eq' : function($ctx, $arg1, $arg2){$arg1 is $arg2},
            'to' : function($ctx, $arg1, $arg2){xpe:data($ctx, $arg1) to xpe:data($ctx, $arg2)},
            'plus' : function($ctx, $arg1, $arg2){xpe:data($ctx, $arg1) + xpe:data($ctx, $arg2)},
            'minus' : function($ctx, $arg1, $arg2){xpe:data($ctx, $arg1) - xpe:data($ctx, $arg2)},
            'x' : function($ctx, $arg1, $arg2){xpe:data($ctx, $arg1) * xpe:data($ctx, $arg2)},
            'mod' : function($ctx, $arg1, $arg2){xpe:data($ctx, $arg1) mod xpe:data($ctx, $arg2)},
            'div' : function($ctx, $arg1, $arg2){xpe:data($ctx, $arg1) div xpe:data($ctx, $arg2)},
            'idiv' : function($ctx, $arg1, $arg2){xpe:data($ctx, $arg1) idiv xpe:data($ctx, $arg2)},
            
            'instance-of' : function($ctx, $arg, $itemType){xpt:instance-of($ctx, $arg, $itemType)},
            'treat-as' : function($ctx, $arg, $itemType){xpt:treat-as($ctx, $arg, $itemType)}
        }
        "
        as="map(xs:string, function(map(*), item()*, item()*) as item()*)"/>
    
<!--    
    Operations
    -->
    
    
    <xsl:function name="xpe:arg-array" as="array(*)">
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
        <xsl:param name="execution-context" as="map(*)"/>
        <xsl:param name="args" as="array(*)"/>
        <xsl:param name="operations" as="array(function(map(*), item()*, item()*) as item()*)"/>
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
                <xsl:sequence select="$op($execution-context, $args?1, $args?2)"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:variable name="last" select="$args($arg-sz)"/>
                <xsl:variable name="operation" select="$operations($arg-sz - 1)"/>
                <xsl:variable name="temp-result" select="xpe:fold-left-wizzard(
                    $execution-context,
                    array:remove($args, $arg-sz),
                    array:remove($operations, $arg-sz - 1)
                    )"/>
                <xsl:sequence select="$operation($execution-context, $temp-result, $last)"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>
    
    <xsl:template match="operation[count(arg) gt 2]" mode="xpe:xpath-evaluate">
        <xsl:variable name="second-arg" select="arg[2]"/>
        <xsl:variable name="first-two-args" select="node()[. &lt;&lt; $second-arg], $second-arg"/>
        <xsl:variable name="rest" select="node() except $first-two-args"/>
        
        <xsl:variable name="equivalent" as="element(operation)">
            <xsl:copy>
                <xsl:sequence select="@*"/>
                <arg>
                    <xsl:copy>
                        <xsl:sequence select="@*"/>
                        <xsl:copy-of select="$first-two-args"/>
                    </xsl:copy>
                </arg>
                <xsl:copy-of select="$rest"/>
            </xsl:copy>
        </xsl:variable>
        <xsl:apply-templates select="$equivalent" mode="#current"/>
    </xsl:template>
    
    <xsl:template match="operation[count(arg) eq 2]" mode="xpe:xpath-evaluate" priority="-5">
        <xsl:param name="execution-context" as="map(*)" tunnel="yes"/>
        <xsl:variable name="operator" select="* except arg" as="element()"/>
        
        <xsl:variable name="op-name" select="$operator/local-name(.)"/>
        <xsl:variable name="operator-key" select="@type || '#' || $op-name"/>
        <xsl:variable name="operator-key" select="
            if ($op-name = 'div' and $operator/@type = 'integer') 
            then 'idiv' 
            else if (map:contains($xpe:operations, $operator-key)) 
            then $operator-key 
            else $op-name
            "/>
        
        <xsl:variable name="arg1-result" as="item()*">
            <xsl:apply-templates select="arg[1]" mode="#current"/>
        </xsl:variable>
        <xsl:variable name="arg2-result" as="item()*">
            <xsl:apply-templates select="arg[2]" mode="#current"/>
        </xsl:variable>
        
        <xsl:sequence select="
            xpe:operation($execution-context, [$arg1-result, $arg2-result], $operator-key)
            "/>
        
    </xsl:template>
    
    <xsl:template match="operation[@type = ('instance-of', 'treat-as')]" mode="xpe:xpath-evaluate">
        <xsl:param name="execution-context" as="map(*)" tunnel="yes"/>
        <xsl:variable name="arg-result" as="item()*">
            <xsl:apply-templates select="arg" mode="#current"/>
        </xsl:variable>
        <xsl:variable name="itemType" select="itemType"/>
        <xsl:sequence select="
            xpe:operation($execution-context, [$arg-result, $itemType], @type)
            "/>
    </xsl:template>
    
    
    
    <xsl:function name="xpe:operation" as="item()*">
        <xsl:param name="execution-context" as="map(*)"/>
        <xsl:param name="args" as="array(*)"/>
        <xsl:param name="operator-key" as="xs:string"/>
        
        <xsl:variable name="extension-operators" select="($execution-context?extension-operators, map{})[1]"/>
        <xsl:variable name="op-functions" select="
            if (map:contains($extension-operators, $operator-key)) 
            then $extension-operators($operator-key) 
            else $xpe:operations($operator-key)
            "/>
        <xsl:sequence select="
            apply($op-functions, array:join(([$execution-context],$args)))
            "/>
    </xsl:function>
    
    <xsl:template match="operation[@type = 'unary']" mode="xpe:xpath-evaluate" priority="50">
        <xsl:param name="execution-context" tunnel="yes"/>
        <xsl:variable name="content" as="item()*">
            <xsl:apply-templates select="arg/*" mode="#current"/>
        </xsl:variable>
        <xsl:variable name="content" select="xpe:data($execution-context, $content)"/>
        <xsl:variable name="minus" select="minus"/>
        
        <xsl:sequence select="
            if (count($minus) mod 2 = 1) 
            then -($content) 
            else +($content)
            "/>
    </xsl:template>
    
    <xsl:template match="operation[@type = 'map'][count(arg) gt 2]" mode="xpe:xpath-evaluate" priority="100">
        <xsl:variable name="second-arg" select="arg[2]"/>
        <xsl:variable name="first-two-args" select="node()[. &lt;&lt; $second-arg], $second-arg"/>
        <xsl:variable name="rest" select="node() except $first-two-args"/>
        
        <xsl:variable name="equivalent" as="element(operation)">
            <xsl:copy>
                <xsl:sequence select="@*"/>
                <arg>
                    <xsl:copy>
                        <xsl:sequence select="@*"/>
                        <xsl:copy-of select="$first-two-args"/>
                    </xsl:copy>
                </arg>
                <xsl:copy-of select="$rest"/>
            </xsl:copy>
        </xsl:variable>
        <xsl:apply-templates select="$equivalent" mode="#current"/>
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
        <xsl:variable name="context" as="item()?" select="xpe:fn-apply($execution-context, 'root', [])"/>
        <xsl:variable name="result" as="item()*">
            <xsl:apply-templates select="arg/*" mode="#current">
                <xsl:with-param name="execution-context" select="map:put($execution-context, 'context', $context)" tunnel="yes"/>
            </xsl:apply-templates>
        </xsl:variable>
        <xsl:sequence select="xpe:xpath-step-result-reorder($result)"/>
    </xsl:template>

    <xsl:template match="operation[@type = 'step']" 
        mode="xpe:xpath-evaluate" priority="10">
        <xsl:param name="execution-context" tunnel="yes"/>
        <xsl:variable name="last-arg" select="arg[last()]"/>
        <xsl:variable name="context-expr" as="element(expr)">
            <expr>
                <xsl:choose>
                    <xsl:when test="slash[2]">
                        <xsl:copy>
                            <xsl:copy-of select="@*"/>
                            <xsl:copy-of select="slash[last()]/preceding-sibling::*"/>
                        </xsl:copy>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:sequence select="arg[1]/*"/>
                    </xsl:otherwise>
                </xsl:choose>
            </expr>
        </xsl:variable>
        <xsl:variable name="context" as="item()*">
            <xsl:apply-templates select="$context-expr" mode="#current">
                <xsl:with-param name="execution-context" select="$execution-context" tunnel="yes"/>
            </xsl:apply-templates>
        </xsl:variable>
        <xsl:variable name="last-arg" select="arg[last()]"/>
        <xsl:variable name="result" as="item()*">
            <xsl:for-each select="$context">
                <xsl:if test="not(. instance of node())">
                    
                    <xsl:sequence select="error(xpe:error-code('XPTY0019'), 
                        'The required item type of the first operand of ''/'' is node()! The supplied value has the type ' || (xpt:type-of(.) => xpm:xpath-serializer-sub()))"/>
                </xsl:if>
                <xsl:variable name="sub-context" select="map{
                    'context' : .,
                    'position' : position(),
                    'last' : last()
                    }"/>
                <xsl:variable name="execution-context" select="($execution-context, $sub-context) => map:merge(map{'duplicates' : 'use-last'})"/>
                <xsl:apply-templates select="$last-arg/*" mode="#current">
                    <xsl:with-param name="execution-context" select="$execution-context" tunnel="yes"/>
                </xsl:apply-templates>
            </xsl:for-each>
        </xsl:variable>
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
    
    <xsl:template match="operation[@type = 'postfix'][count(predicate|function-call|lookup) gt 1]" mode="xpe:xpath-evaluate" priority="50">
        <xsl:variable name="last" select="(predicate|function-call|lookup)[last()]"/>
        <xsl:variable name="equivalent" as="element(operation)">
            <xsl:copy>
                <xsl:sequence select="@*"/>
                <arg>
                    <xsl:copy>
                        <xsl:sequence select="@*"/>
                        <xsl:sequence select="* except $last"/>
                    </xsl:copy>
                </arg>
                <xsl:sequence select="$last"/>
            </xsl:copy>
        </xsl:variable>
        
        <xsl:apply-templates select="$equivalent" mode="#current"/>
    </xsl:template>
    
    <xsl:template match="operation[@type = 'postfix'][predicate]" mode="xpe:xpath-evaluate" priority="10">
        <xsl:param name="execution-context" as="map(*)" tunnel="yes"/>
        <xsl:variable name="content" as="item()*">
            <xsl:apply-templates select="arg/*" mode="#current"/>
        </xsl:variable>
        <xsl:sequence select="xpe:apply-predicate($execution-context, $content, predicate)"/>
    </xsl:template>

    <xsl:template match="operation[@type = 'postfix'][lookup]" mode="xpe:xpath-evaluate" priority="10">
        <xsl:variable name="target" as="item()*">
            <xsl:apply-templates select="arg/*" mode="#current"/>
        </xsl:variable>
        <xsl:variable name="lookup" select="lookup"/>
        <xsl:for-each select="$target">
            <xsl:apply-templates select="$lookup" mode="#current">
                <xsl:with-param name="target" select="."/>
            </xsl:apply-templates>
        </xsl:for-each>
    </xsl:template>

    <xsl:template match="operation[@type = 'postfix'][function-call]" mode="xpe:xpath-evaluate" priority="10">
        <xsl:param name="execution-context" as="map(*)" tunnel="yes"/>
        <xsl:variable name="function" as="item()*">
            <xsl:apply-templates select="arg/*" mode="#current"/>
        </xsl:variable>
        <xsl:variable name="args" select="function-call/arg"/>
        
        <xsl:variable name="itemType" as="element(itemType)">
            <itemType occurrence="zero-or-more"/>
        </xsl:variable>
        <xsl:variable name="function" select="
            if (xpe:is-function($function)) 
            then $function 
            else if (
                $function instance of function(*) 
                or $function instance of map(*) 
                or $function instance of array(*)) 
            then map {
                'function' : $function,
                'type' : QName($xpf:namespace-uri, 'function'),
                'name' : if ($function instance of function(*)) 
                        then function-name($function) 
                        else (),
                'arity' : function-arity($function),
                'return-type' : $itemType
            }
            else if (empty($function)) 
            then error(xpe:error-code('XPTY0004'), 'An empty sequence is not allowed as the target of dynamic function call.') 
            else if (count($function) gt 1) 
            then error(xpe:error-code('XPTY0004'), 'A sequence of more than one item is not allowed as the target of dynamic function call.') 
            else error(xpe:error-code('XPTY0004'), 'A function call requires a function, map or array.') 
            "/>
        
        <xsl:choose>
            <xsl:when test="empty($function)">
                <xsl:sequence select="
                    error(
                        xpe:error-code('XPTY0004'), 
                        'An empty sequence is not allowed as the target of dynamic function call.'
                        )
                    "/>
            </xsl:when>
            <xsl:when test="function-arity($function?function) ne count($args)">
                <xsl:sequence select="
                    error(
                    xpe:error-code('XPTY0004'), 
                    'Number of arguments required for function call ' || xpm:xpath-serializer-sub(.) || ' is ' || function-arity($function?function) || '; number supplied is ' || count($args))
                    "/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:variable name="arg-types" select="$function?arg-types"/>
                <xsl:variable name="args" as="array(*)">
                    <xsl:try>
                        <xsl:sequence select="xpe:arg-array($args, $execution-context)"/>
                        <xsl:catch errors="err:XPTY0004">
                            <xsl:variable name="descr-prefix" select="
                                if (empty($function?name)) 
                                then 'Fail to call anonym function' 
                                else 'Fail to call function ' || $function?name
                                "/>
                            <xsl:sequence select="error($err:code, $descr-prefix || ' - ' || $err:description)"/>
                        </xsl:catch>
                    </xsl:try>
                </xsl:variable>
                <xsl:variable name="return-type" select="$function?return-type"/>
                <xsl:variable name="return-value" select="apply($function?function, $args)"/>
                <xsl:try>
                    <xsl:variable name="return-value" select="
                        xpe:type-promotion($return-value, $return-type/atomic)
                        "/>
                    <xsl:sequence select="xpe:treat-as($execution-context, $return-value, $return-type)"/>
                    <xsl:catch errors="err:XPTY0004">
                        <xsl:variable name="descr-prefix" select="
                            if (empty($function?name)) 
                            then 'Bad value returned by anonym function call: ' 
                            else 'Bad value returned by call of function ' || $function?name || ': '
                            "/>
                        <xsl:sequence select="error($err:code, $descr-prefix || $err:description)"/>
                    </xsl:catch>
                </xsl:try>
            </xsl:otherwise>
        </xsl:choose>
        
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
    
    <xsl:template match="operation[@type = ('castable')]" mode="xpe:xpath-evaluate" priority="25">
        <xsl:param name="execution-context" as="map(*)" tunnel="yes"/>
        <xsl:variable name="context" as="item()*">
            <xsl:apply-templates select="arg/*" mode="#current"/>
        </xsl:variable>
        <xsl:variable name="context" select="xpe:data($execution-context, $context)"/>
        <xsl:sequence select="xpt:castable-as($context, itemType)"/>
    </xsl:template>
    
    <xsl:template match="operation[@type = ('cast')]
        [itemType/atomic/resolve-QName(@name, .) = xs:QName('xs:QName')]" mode="xpe:xpath-evaluate" priority="30">
        <xsl:param name="execution-context" as="map(*)" tunnel="yes"/>
        <xsl:variable name="context" as="item()*">
            <xsl:apply-templates select="arg/*" mode="#current"/>
        </xsl:variable>
        <xsl:choose>
            <!-- 
                ensures that wrong cardinality throws the correct error code
                or is accepted in case of '() cast as xs:QName?' 
            -->
            <xsl:when test="count($context) ne 1">
                <xsl:sequence select="xpt:cast-as($context, itemType)"/>
            </xsl:when>
            <!-- xs:QName can be casted to xs:QName-->
            <xsl:when test="$context instance of xs:QName">
                <xsl:sequence select="$context"/>
            </xsl:when>
            <xsl:when test="$context instance of xs:NOTATION">
                <xsl:sequence select="$context cast as xs:QName"/>
            </xsl:when>
            <xsl:when test="
                $context instance of xs:untypedAtomic 
                or $context instance of xs:string
                or $context instance of node()
                ">
                <xsl:sequence select="xpfs:QName($execution-context, $context)"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:variable name="curType" select="
                    xpt:type-of($context) => xpm:xpath-serializer-sub() => normalize-space()
                    "/>
                <xsl:sequence select="error(xpe:error-code('XPTY0004'), 
                    'Can not cast ' || $curType || ' to xs:QName.'
                    )"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <xsl:template match="operation[@type = ('cast')]" mode="xpe:xpath-evaluate" priority="25">
        <xsl:param name="execution-context" as="map(*)" tunnel="yes"/>
        <xsl:variable name="context" as="item()*">
            <xsl:apply-templates select="arg/*" mode="#current"/>
        </xsl:variable>
        <xsl:variable name="context" select="xpe:data($execution-context, $context)"/>
        <xsl:sequence select="xpt:cast-as($context, itemType)"/>
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
        <xsl:sequence select="xs:double(@factor || 'E' || @exp)"/>
    </xsl:template>

    <xsl:template match="empty" mode="xpe:xpath-evaluate">
        <xsl:sequence select="()"/>
    </xsl:template>

    <xsl:template match="self" mode="xpe:xpath-evaluate">
        <xsl:param name="execution-context" as="map(*)" tunnel="yes"/>
        <xsl:if test="empty($execution-context?context)">
            <xsl:sequence select="error(xpe:error-code('XPDY0002'), 'There is no given context in expression ''.'' ')"/>
        </xsl:if>
        <xsl:sequence select="$execution-context?context"/>
    </xsl:template>

    <xsl:template match="root" mode="xpe:xpath-evaluate" name="xpe:xpath-root">
        <xsl:param name="execution-context" as="map(*)" tunnel="yes"/>
        <xsl:variable name="context" select="$execution-context?context"/>
        <xsl:choose>
            <xsl:when test="empty($context) or not($context instance of node())">
                <xsl:sequence select="error(xpe:error-code('XPDY0002'), 'The context must be a node for using ''/'' or ''root(.)''')"/>
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
            <xsl:variable name="msg" expand-text="yes">Variable Q{{{namespace-uri-from-QName($varName)}}}{local-name-from-QName($varName)} not declared in this scope.</xsl:variable>
            <xsl:sequence select="error(xpe:error-code('XPST0008'),  $msg)"/>
        </xsl:if>
        <xsl:sequence select="$variables($varName)"/>
    </xsl:template>
    
    <xsl:template match="*[not(self::operation[@type = 'postfix'])]/lookup" 
        mode="xpe:xpath-evaluate" priority="10">
        <xsl:param name="execution-context" as="map(*)" tunnel="yes"/>
        <xsl:variable name="context" select="$execution-context?context"/>
        <xsl:choose>
            <xsl:when test="empty($context)">
                <xsl:sequence select="error(xpe:error-code('XPDY0002'), 'Context of an unary lookup is absent!')"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:next-match>
                    <xsl:with-param name="target" select="$context"/>
                </xsl:next-match>
            </xsl:otherwise>
        </xsl:choose>
        
    </xsl:template>
    

    <xsl:template match="lookup[not(*)]" mode="xpe:xpath-evaluate" priority="-10">
        <xsl:param name="execution-context" as="map(*)" tunnel="yes"/>
        <xsl:param name="target" as="item()"/>
        <xsl:choose>
            <xsl:when test="xpe:is-function($target)">
                <xsl:sequence select="error(xpe:error-code('XPTY0004'), 'Target of a lookup must be a map or array, not a function!')"/>
            </xsl:when>
            <xsl:when test="$target instance of map(*) or $target instance of array(*)">
                <xsl:sequence select="$target?*"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:sequence select="error(xpe:error-code('XPTY0004'), 'Target of a lookup must be a map or array!')"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <xsl:template match="lookup" mode="xpe:xpath-evaluate" priority="-15">
        <xsl:param name="execution-context" as="map(*)" tunnel="yes"/>
        <xsl:param name="target" as="item()"/>
        <xsl:variable name="key" as="item()*">
            <xsl:apply-templates select="integer | field | arg" mode="#current"/>
        </xsl:variable>
        <xsl:choose>
            <xsl:when test="xpe:is-function($target)">
                <xsl:sequence select="error(xpe:error-code('XPTY0004'), 'Target of a lookup must be a map or array, not a function!')"/>
            </xsl:when>
            <xsl:when test="$target instance of map(*) or $target instance of array(*)">
                <xsl:sequence select="$key ! $target(.)"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:sequence select="error(xpe:error-code('XPTY0004'), 'Target of a lookup must be a map or array!')"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <xsl:template match="lookup/field" mode="xpe:xpath-evaluate">
        <xsl:sequence select="string(@name)"/>
    </xsl:template>
    
    
<!--    
    Location Steps
    -->
    
    
    
    
    <xsl:template match="locationStep[nodeTest/@kind = ('schema-element', 'schema-attribute')]" mode="xpe:xpath-evaluate" priority="10">
        <xsl:sequence select="error(xpe:error-code('XPST0008'), 
            'Node tests with ''' || nodeTest/@kind || '()'' are not supported!'
            )"/>
    </xsl:template>
    <xsl:template match="locationStep" mode="xpe:xpath-evaluate">
        <xsl:param name="execution-context" as="map(*)" tunnel="yes"/>
        
        <xsl:variable name="context" select="$execution-context?context"/>
        
        <xsl:variable name="nodeTest" select="nodeTest"/>
        
        <xsl:variable name="expr" select="xpm:xpath-serializer-sub(.)"/>
        
        <xsl:variable name="context" select="
            if (empty($context)) 
            then error(xpe:error-code('XPDY0002'), 'Context of a location step must be a node! Context is empty. (' || $expr || ')') 
            else if (not($context instance of node())) 
            then error(xpe:error-code('XPTY0019'), 'Context of a location step must be a node! Context is from type ' || (xpt:type-of($context) => xpm:xpath-serializer-sub())) 
            else $context
            " as="node()"/>
        
        <xsl:variable name="nodes" select="
            xpe:tree-walk($context, @axis, $nodeTest)
            "/>
        <xsl:sequence select="$nodes"/>
    </xsl:template>
    
    <xsl:template match="locationStep[predicate]" name="xpe:locationstep-predicate" mode="xpe:xpath-evaluate" priority="10">
        <xsl:param name="execution-context" as="map(*)" tunnel="yes"/>
        <xsl:param name="nodes" as="item()*">
            <xsl:next-match/>
        </xsl:param>
        <xsl:param name="cPredicate" select="predicate[1]" as="element(predicate)?"/>
        <xsl:param name="reverse" select="@axis = ('preceding-sibling', 'preceding', 'ancestor', 'ancestor-or-self')"/>
        <xsl:choose>
            <xsl:when test="$cPredicate">
                <xsl:variable name="nodes" as="item()*">
                    <xsl:for-each select="$nodes">
                        <xsl:variable name="node" select="."/>
                        <xsl:variable name="pos" select="
                            if ($reverse) 
                            then last() - position()  + 1 
                            else position()
                            "/>
                        <xsl:variable name="sub-context" select="map{
                            'context' : $node,
                            'position' : $pos,
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
            if ($content instance of xs:numeric) 
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
                <xsl:sequence select="$context ! ancestor::node()[xpe:node-test(., $node-test)]"/>
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
                <xsl:sequence select="$context ! preceding::node()[xpe:node-test(., $node-test)]
                    "/>
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
            if ($kind-test = ('schema-element', 'schema-attribute')) 
            then error(xpe:error-code('XPST0008'), 
            'Node tests with ''' || $kind-test || '()'' are not supported!'
            ) 
            else if (not(($node-kind, 'node') = $kind-test))
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
            <xsl:when test="$name-matcher?namespace = 'http://www.w3.org/2000/xmlns/'">
                <xsl:sequence select="error(xpe:error-code('XQST0070'), 
                    'The string ''http://www.w3.org/2000/xmlns/'' cannot be used as a namespace URI.'
                    )"/>
            </xsl:when>
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
    
    
<!--    
    Partial Function Applications
    -->
    <xsl:template match="operation[@type = 'postfix'][function-call/arg/@role = 'placeholder']" mode="xpe:xpath-evaluate" priority="20">
        <xsl:apply-templates select="function-call" mode="#current"/>
    </xsl:template>
    
    <xsl:template match="function-call[arg/@role = 'placeholder']" mode="xpe:xpath-evaluate">
        <xsl:param name="execution-context" as="map(*)" tunnel="yes"/>
        <xsl:param name="first-arg" as="array(item()*)" select="[]"/>
        
        <xsl:variable name="has-addidtional-arg" select="array:size($first-arg) gt 0"/>
        
        <xsl:variable name="pfa-arity" select="
            if ($has-addidtional-arg) 
            then (count(arg) + 1) 
            else count(arg)
            "/>
        <xsl:variable name="abstract-function" as="map(*)">
            <xsl:choose>
                <xsl:when test="function">
                    <xsl:apply-templates select="function" mode="#current">
                        <xsl:with-param name="arity" select="$pfa-arity" tunnel="yes"/>
                    </xsl:apply-templates>
                </xsl:when>
                <xsl:when test="parent::operation[@type = 'postfix']">
                    <xsl:apply-templates select="preceding-sibling::arg/*" mode="#current">
                        <xsl:with-param name="arity" select="$pfa-arity" tunnel="yes"/>
                    </xsl:apply-templates>
                </xsl:when>
            </xsl:choose>
        </xsl:variable>
        
        <xsl:variable name="return-type" select="$abstract-function('return-type')"/>
        <xsl:variable name="fi-arity" select="$abstract-function('arity')"/>
        
        <xsl:if test="$pfa-arity ne $fi-arity">
            <xsl:sequence select="error(
                xpe:error-code('XPTY0004'),
                'The number of arguments supplied in the partial function application is ' || $pfa-arity || ', but the arity of the function item is ' || $fi-arity
                )"/>
        </xsl:if>

<!--        
        Creates equivalent:
        
        foo(?, 'bar', ?) -> function($xpe:p1, $xpe:2){foo($xpe:p1, 'bar', $xpe:p2)}
        -->
        <xsl:variable name="inline-equivalent" as="element(function-impl)">
            <function-impl>
                <xsl:for-each select="arg[@role = 'placeholder']">
                    <param name="xpe:p{position()}"/>
                </xsl:for-each>
                <xsl:variable name="return-content">
                    <xsl:variable name="args">
                        <xsl:if test="$has-addidtional-arg">
                            <arg>
                                <varRef name="xpe:p0"/>
                            </arg>
                        </xsl:if>
                        <xsl:for-each select="arg">
                            <xsl:choose>
                                <xsl:when test="@role = 'placeholder'">
                                    <xsl:variable name="plchld-idx" select="count(preceding-sibling::arg[@role = 'placeholder']) + 1"/>
                                    <arg>
                                        <varRef name="xpe:p{$plchld-idx}"/>
                                    </arg>
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:sequence select="."/>
                                </xsl:otherwise>
                            </xsl:choose>
                        </xsl:for-each>
                    </xsl:variable>

                    
                    <xsl:choose>
                        <xsl:when test="function">
                            <function-call>
                                <xsl:sequence select="function"/>
                                <xsl:sequence select="$args"/>
                            </function-call>
                        </xsl:when>
                        <xsl:when test="parent::operation[@type = 'postfix']">
                            <operation type="postfix">
                                <xsl:sequence select="preceding-sibling::arg"/>
                                <function-call>
                                    <xsl:sequence select="$args"/>
                                </function-call>
                            </operation>
                        </xsl:when>
                    </xsl:choose>
                </xsl:variable>
                <arg role="return">
                    <xsl:choose>
                        <xsl:when test="empty($execution-context?context)">
                            <xsl:sequence select="$return-content"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <operation type="map">
                                <arg>
                                    <varRef name="xpe:context"/>
                                </arg>
                                <map/>
                                <arg>
                                    <xsl:sequence select="$return-content"/>
                                </arg>
                            </operation>
                        </xsl:otherwise>
                    </xsl:choose>
                </arg>
                <as>
                    <xsl:copy-of select="$return-type"/>
                </as>
            </function-impl>
        </xsl:variable>
        <xsl:variable name="first-arg" select="
            if ($has-addidtional-arg) 
            then map{xs:QName('xpe:p0') : $first-arg?1} 
            else ()
            "/>
        <xsl:variable name="context" select="map{xs:QName('xpe:context') : $execution-context?context}"/>
        <xsl:variable name="variables" select="($execution-context?variable-context, $first-arg, $context) => map:merge(map{'duplicates' : 'use-last'})"/>
        <xsl:apply-templates select="$inline-equivalent" mode="xpe:xpath-evaluate">
            <xsl:with-param name="execution-context" select="
                map:put($execution-context, 'variable-context', $variables)
                " tunnel="yes"/>
        </xsl:apply-templates>
    </xsl:template>
    
    <xsl:template match="function-call" mode="xpe:xpath-evaluate">
        <xsl:param name="execution-context" as="map(*)" tunnel="yes"/>
        <xsl:param name="first-arg" as="array(item()*)" select="[]"/>

        <xsl:variable name="has-addidtional-arg" select="array:size($first-arg) gt 0"/>
        <xsl:variable name="arity" select="count(arg)"/>
        <xsl:variable name="function" as="item()*">
            <xsl:apply-templates select="function" mode="#current">
                <xsl:with-param name="arity" select="
                    if ($has-addidtional-arg) 
                    then ($arity + 1) 
                    else $arity
                    " tunnel="yes"/>
            </xsl:apply-templates>
        </xsl:variable>
        <xsl:variable name="function" select="
            if (xpe:is-function($function)) 
            then ($function) 
            else if ($function instance of map(*) or $function instance of array(*)) 
            then xpe:create-function-item($function) 
            else error(xpe:error-code('XPTY0004'), 'Fail to make a dynamic function call in ' || xpm:xpath-serializer-sub(.) || '. Item seems to be from type ' || xpm:xpath-serializer-sub(xpt:type-of($function)) || '. Required type is function(*).')
            "/>
        
        <xsl:variable name="return-type" select="$function?return-type"/>
        <xsl:variable name="arg-types" select="$function?arg-types"/>
        
        <xsl:variable name="arg-array" select="
            xpe:arg-array(arg, $execution-context) 
            "/>
        <xsl:variable name="arg-array" select="
            if ($has-addidtional-arg) 
            then array:insert-before($arg-array, 1, $first-arg?1) 
            else $arg-array
            "/>
        
        <xsl:variable name="raw-function" select="xpe:raw-function($function)"/>
        <xsl:variable name="return-value" select="apply($raw-function, $arg-array)"/>
        <xsl:variable name="return-value" select="xpe:type-promotion($return-value, $return-type/atomic)"/>
        <xsl:sequence select="
            xpe:treat-as($execution-context, $return-value, $return-type)
            "/>
    </xsl:template>
    
    <xsl:template match="function[@name]" mode="xpe:xpath-evaluate">
        <xsl:param name="execution-context" as="map(*)" tunnel="yes"/>
        <xsl:param name="arity" select="()" as="xs:integer?" tunnel="yes"/>
        <xsl:variable name="arity" select="(@arity, $arity)[1]" as="xs:integer"/>
        <xsl:variable name="qname" select="xpm:name-matcher(@name)"/>
        <xsl:variable name="local-name" select="$qname?local"/>
        <xsl:variable name="ns-uri" select="$qname?namespace"/>
        
        <xsl:variable name="ns-uri" select="
            if ($ns-uri = '') then $build-in-namespaces('fn') else $ns-uri
            "/>
        
        <xsl:variable name="funct-name" select="QName($ns-uri, $local-name)"/>
        <xsl:variable name="function" select="xpf:function-lookup($execution-context, $funct-name, $arity)"/>
        
        <xsl:sequence select="
            if ($arity > 1000000) 
            then error(xpe:error-code('FOAR0002'), 'Given arity of function look is out of range.') 
            else if (empty($function)) 
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
    
    <xsl:template match="function-impl" mode="xpe:xpath-evaluate">
        <xsl:param name="execution-context" as="map(*)" tunnel="yes"/>
        
        <!--
            TODO: Check for Q{} syntax? 
        -->
        <xsl:variable name="arity" select="count(param)"/>
        <xsl:variable name="param-names" select="param/xpm:varQName(@name)"/>
        <xsl:variable name="body" select="arg[@role = 'return']"/>

        <xsl:variable name="any-item-type" as="element(itemType)">
            <itemType occurrence="zero-or-more"/>
        </xsl:variable>
        <xsl:variable name="return-type" select="(./as/*, $any-item-type)[1]"/>
        
        <xsl:variable name="execution-context" select="map:remove($execution-context, 'context')"/>

        <xsl:variable name="arg-types" select="
            for $p in param return ($p/as/*, $any-item-type)[1]
            "/>
        
        <xsl:for-each-group select="$param-names" group-by=".">
            <xsl:if test="count(current-group()) gt 1">
                <xsl:variable name="ns" select="namespace-uri-from-QName(current-grouping-key())"/>
                <xsl:variable name="local" select="local-name-from-QName(current-grouping-key())"/>
                <xsl:sequence select="error(xpe:error-code('XQST0039'), 
                    'Duplicate parameter name ' || xpe:eqname(current-grouping-key()) || ' for inline function.'
                    )"/>
            </xsl:if>
        </xsl:for-each-group> 
        
        <xsl:variable name="function-body" select="xpe:function-inline-exec#6($execution-context, $body, $param-names, $arg-types, $return-type, ?)"/>
        
        <xsl:variable name="function" select="xpe:create-function($function-body, $arity)"/>
        
        
        
        
        <xsl:sequence select="xpe:create-function-item(
            $function,
            (),
            $arg-types,
            $return-type
            )"/>
        
    </xsl:template>
    
    <xsl:function name="xpe:function-inline-exec" as="item()*">
        <xsl:param name="execution-context" as="map(*)"/>
        <xsl:param name="body" as="element(arg)"/>
        <xsl:param name="param-names" as="xs:QName*"/>
        <xsl:param name="arg-types" as="element(itemType)*"/>
        <xsl:param name="result-type" as="element(itemType)?"/>
        <xsl:param name="arguments" as="array(*)"/>
        <xsl:variable name="arguments" select="xpe:prepare-arguments($execution-context, $arguments, $arg-types, ())"/>
        
        <xsl:variable name="parameter" select="
            for $i in 1 to array:size($arguments)
            return map{$param-names[$i] : $arguments($i)}
            "/>
        
        <xsl:variable name="variables" select="($execution-context?variable-context, $parameter) => map:merge(map{'duplicates' : 'use-last'})"/>
        <xsl:variable name="execution-context" select="map:put($execution-context, 'variable-context', $variables)"/>
        <xsl:variable name="return-value" as="item()*">
            <xsl:apply-templates select="$body/*" mode="xpe:xpath-evaluate">
                <xsl:with-param name="execution-context" select="$execution-context" tunnel="yes"/>
            </xsl:apply-templates>
        </xsl:variable>
        <xsl:try>
            <xsl:sequence select="
                if ($result-type) 
                then 
                    xpe:treat-as($execution-context, xpe:type-promotion($return-value, $result-type/atomic), $result-type)
                else 
                    $return-value
                "/>
            <xsl:catch errors="err:XPTY0004 err:XPDY0050">
                <xsl:sequence select="error(xpe:error-code('XPTY0004'), 'The result of a call of an anonym function does not match to the required result type; ' || $err:description)"/>
            </xsl:catch>
        </xsl:try>
    </xsl:function>
    
    
    <!-- 
        MAP / ARRAY
    -->
    
    <xsl:template match="map" mode="xpe:xpath-evaluate">
        <xsl:try>
            <xsl:map>
                <xsl:apply-templates select="entry" mode="#current"/>
            </xsl:map>
            <xsl:catch errors="err:XTDE3365">
                <xsl:sequence select="error(xpe:error-code('XQDY0137'), $err:description)"/>
            </xsl:catch>
        </xsl:try>
    </xsl:template>
    
    <xsl:template match="map/entry" mode="xpe:xpath-evaluate">
        <xsl:param name="execution-context" as="map(*)" tunnel="yes"/>
        <xsl:variable name="key" as="item()*">
            <xsl:apply-templates select="arg[@role = 'key']/*" mode="#current"/>
        </xsl:variable>
        <xsl:variable name="value" as="item()*">
            <xsl:apply-templates select="arg[@role = 'value']/*" mode="#current"/>
        </xsl:variable>
        <xsl:map-entry key="xpe:data($execution-context, $key)" select="$value"/>
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
    
    <xsl:function name="xpe:error-code" as="xs:QName" visibility="public">
        <xsl:param name="code" as="xs:string"/>
        
        <xsl:sequence select="QName('http://www.w3.org/2005/xqt-errors', $code)"/>
        
    </xsl:function>
    
    <xsl:function name="xpe:type-info" as="xs:string" visibility="final">
        <xsl:param name="items" as="item()*"/>
        <xsl:sequence select="
            xpt:type-of-sequence($items) => xpm:xpath-serializer-sub() => normalize-space()
            "/>
    </xsl:function>
    
</xsl:stylesheet>