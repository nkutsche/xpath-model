<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:math="http://www.w3.org/2005/xpath-functions/math"
    xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl"
    xmlns:xpmt="http://www.nkutsche.com/xpath-model/test-helper"  
    xmlns:qt="http://www.w3.org/2010/09/qt-fots-catalog"
    exclude-result-prefixes="xs math xd"
    version="3.0">
    <xd:doc scope="stylesheet">
        <xd:desc>
            <xd:p><xd:b>Created on:</xd:b> Oct 23, 2023</xd:p>
            <xd:p><xd:b>Author:</xd:b> Nico</xd:p>
            <xd:p></xd:p>
        </xd:desc>
    </xd:doc>
    
    <xsl:function name="xpmt:execution-context" as="map(*)">
        <xsl:param name="environment" as="element(qt:environment)"/>
        <xsl:param name="base-uri" as="xs:string"/>
        <xsl:sequence select="xpmt:execution-context($environment, $base-uri, false())"/>
    </xsl:function>
    <xsl:function name="xpmt:execution-context" as="map(*)">
        <xsl:param name="environment" as="element(qt:environment)"/>
        <xsl:param name="base-uri" as="xs:string"/>
        <xsl:param name="transform-workaround" as="xs:boolean"/>
        <xsl:map>
            <xsl:map-entry key="'namespaces'">
                <xsl:map>
                    <xsl:map-entry key="'fn'" select="'http://www.w3.org/2005/xpath-functions'"/>
                    <xsl:map-entry key="'xs'" select="'http://www.w3.org/2001/XMLSchema'"/>
                    <xsl:apply-templates select="$environment/qt:namespace" mode="xpmt:execution-context"/>
                </xsl:map>
            </xsl:map-entry>
            
            <xsl:if test="$environment/qt:collection">
                <xsl:map-entry key="'uri-collection-resolver'" 
                    select="xpmt:env-collection-resolver(?,?, $environment/qt:collection)"/>
            </xsl:if>
            <xsl:if test="$environment/qt:source">
                <xsl:map-entry key="'uri-resolver'" 
                    select="xpmt:env-uri-resolver(?,?, $environment/qt:source, $transform-workaround)"/>
            </xsl:if>
            <xsl:if test="$environment/qt:param">
                <xsl:map-entry key="'variable-context'">
                    <xsl:map>
                        <xsl:apply-templates select="$environment/qt:param" mode="xpmt:execution-context"/>
                    </xsl:map>
                </xsl:map-entry>
            </xsl:if>
            
            <xsl:variable name="base-uri" select="($environment/qt:static-base-uri/@uri, base-uri($environment))[1]"/>
            <xsl:map-entry key="'base-uri'" select="xs:anyURI($base-uri)"/>
            
        </xsl:map>
    </xsl:function>
    
    <xsl:function name="xpmt:env-collection-resolver" as="xs:anyURI*">
        <xsl:param name="relative" as="xs:string?"/>
        <xsl:param name="baseUri" as="xs:string"/>
        <xsl:param name="collections" as="element(qt:collection)+"/>
        <xsl:sequence select="xpmt:env-uri-mapper($relative, $baseUri, $collections)"/>
    </xsl:function>

    <xsl:function name="xpmt:env-uri-mapper" as="xs:anyURI*">
        <xsl:param name="relative" as="xs:string?"/>
        <xsl:param name="baseUri" as="xs:string"/>
        <xsl:param name="sources" as="element()+"/>
        
        
        <xsl:variable name="resolved" select=" if ($relative = '' or empty($relative)) then '' else resolve-uri($relative, $baseUri)"/>
        <xsl:variable name="source" select="
            if ($relative = '' or empty($relative)) 
            then $sources[@uri = ''] 
            else (
                $sources[resolve-uri(@uri, base-uri(.)) = $resolved]
            )
            "/>
        <xsl:variable name="source" select="
            if ($source/self::qt:collection) 
            then ($source/qt:source) 
            else ($source)
            "/>
        <xsl:sequence select="
            if ($source) 
            then $source/resolve-uri(@file, base-uri(.))
            else $resolved[. != '']
            "/>
        
    </xsl:function>
    
    <xsl:function name="xpmt:env-uri-resolver" as="document-node()?">
        <xsl:param name="relative" as="xs:string?"/>
        <xsl:param name="baseUri" as="xs:string"/>
        <xsl:param name="sources" as="element(qt:source)+"/>
        <xsl:param name="transform-workaround" as="xs:boolean"/>
        
        <xsl:variable name="base-uri" select="resolve-uri($relative, $baseUri)"/>
        <xsl:variable name="uris" select="xpmt:env-uri-mapper($relative, $baseUri, $sources)"/>
        <xsl:variable name="docs" select="$uris ! (
            if ($transform-workaround) 
            then (unparsed-text(.) => parse-xml() => xpmt:attach-base-uri($base-uri)) 
            else doc(.))"/>
        <xsl:sequence select="$docs"/>
    </xsl:function>
    
    
    
    <xsl:function name="xpmt:attach-base-uri" as="document-node()">
        <xsl:param name="document" as="document-node()"/>
        <xsl:param name="base-uri" as="xs:string"/>
        <xsl:variable name="copysheet" as="xs:string">
            <![CDATA[
            <xsl:stylesheet version="3.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"><xsl:mode on-no-match="shallow-copy"/></xsl:stylesheet>
            ]]>
        </xsl:variable>
        <xsl:variable name="result" select="transform(map{
            'source-node' : $document,
            'stylesheet-text' : $copysheet,
            'base-output-uri' : $base-uri
            })($base-uri)
            "/>
        <xsl:sequence select="$result"/>
    </xsl:function>
    
    <xsl:template match="*" mode="xpmt:execution-context"/>
    
    <xsl:template match="qt:namespace" mode="xpmt:execution-context">
        <xsl:map-entry key="string(@prefix)" select="string(@uri)"/>
    </xsl:template>
    
    <xsl:template match="qt:static-base-uri" mode="xpmt:execution-context">
        <xsl:map-entry key="'base-uri'" select="string(@uri)"/>
    </xsl:template>
    
    <xsl:template match="qt:param[@name][@select]" mode="xpmt:execution-context">
        <xsl:map-entry key="xs:QName(@name)">
            <xsl:evaluate xpath="@select"/>
        </xsl:map-entry>
    </xsl:template>
    
    
    <xsl:function name="xpmt:result-compare" as="xs:boolean">
        <xsl:param name="expected" as="element(qt:result)"/>
        <xsl:param name="result" as="item()*"/>
        
        <xsl:apply-templates select="$expected/*" mode="xpmt:result-compare">
            <xsl:with-param name="result" select="$result" tunnel="yes"/>
        </xsl:apply-templates>
    </xsl:function>
    
    <xsl:template match="qt:all-of" mode="xpmt:result-compare">
        <xsl:variable name="sub-results" as="xs:boolean*">
            <xsl:apply-templates mode="#current"/>
        </xsl:variable>
        <xsl:variable name="result" select="every $sr in $sub-results satisfies $sr"/>
        <xsl:if test="not($result)">
            <xsl:message select="$sub-results"/>
        </xsl:if>
        <xsl:sequence select="$result"/>
    </xsl:template>

    <xsl:template match="qt:any-of" mode="xpmt:result-compare">
        <xsl:variable name="sub-results" as="xs:boolean*">
            <xsl:apply-templates mode="#current"/>
        </xsl:variable>
        <xsl:sequence select="some $sr in $sub-results satisfies $sr"/>
    </xsl:template>
    
    <xsl:template match="qt:assert-count | qt:assert-empty | qt:assert-eq | qt:assert-deep-eq | qt:assert-string-value | qt:assert-true | qt:assert-false | qt:assert-type" priority="100" mode="xpmt:result-compare">
        <xsl:param name="result" as="item()*" tunnel="yes"/>
        <xsl:choose>
            <xsl:when test="$result instance of map(*)">
                <xsl:sequence select="false()"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:next-match/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <xsl:template match="qt:assert-count" mode="xpmt:result-compare">
        <xsl:param name="result" as="item()*" tunnel="yes"/>
        <xsl:sequence select="count($result) = xs:integer(.)"/>
    </xsl:template>

    <xsl:template match="qt:assert-empty" mode="xpmt:result-compare">
        <xsl:param name="result" as="item()*" tunnel="yes"/>
        <xsl:sequence select="empty($result)"/>
    </xsl:template>

    <xsl:template match="qt:assert-eq | qt:assert-deep-eq" mode="xpmt:result-compare">
        <xsl:param name="result" as="item()*" tunnel="yes"/>
        <xsl:variable name="namespace-context" as="element()">
            <xsl:copy copy-namespaces="yes">
                <xsl:namespace name="fn">http://www.w3.org/2005/xpath-functions</xsl:namespace>
                <xsl:namespace name="xs">http://www.w3.org/2001/XMLSchema</xsl:namespace>
            </xsl:copy>
        </xsl:variable>
        <xsl:variable name="compare" as="item()*">
            <xsl:evaluate xpath="." namespace-context="$namespace-context"/>
        </xsl:variable>
        <xsl:sequence select="deep-equal($result, $compare)"/>
    </xsl:template>

    <xsl:template match="qt:assert-permutation" mode="xpmt:result-compare">
        <xsl:param name="result" as="item()*" tunnel="yes"/>
        <xsl:variable name="namespace-context" as="element()">
            <xsl:copy copy-namespaces="yes">
                <xsl:namespace name="fn">http://www.w3.org/2005/xpath-functions</xsl:namespace>
                <xsl:namespace name="xs">http://www.w3.org/2001/XMLSchema</xsl:namespace>
            </xsl:copy>
        </xsl:variable>
        <xsl:variable name="compare" as="item()*">
            <xsl:evaluate xpath="." namespace-context="$namespace-context"/>
        </xsl:variable>
        <xsl:sequence select="xpmt:assert-permutation($result, $compare)"/>
    </xsl:template>
    
    <xsl:function name="xpmt:assert-permutation" as="xs:boolean">
        <xsl:param name="result" as="item()*"/>
        <xsl:param name="compare" as="item()*"/>
        <xsl:variable name="item-count" select="count($result)"/>
        <xsl:choose>
            <xsl:when test="$item-count != count($compare)">
                <xsl:sequence select="false()"/>
            </xsl:when>
            <xsl:when test="$item-count = 0">
                <xsl:sequence select="true()"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:variable name="head" select="head($result)"/>
                <xsl:variable name="index-of" select="
                    for $i in (1 to $item-count) 
                    return if(deep-equal($head, $compare[$i])) then $i else ()
                    "/>
                <xsl:variable name="index-of" select="$index-of[1]"/>
                <xsl:sequence select="
                    if (empty($index-of)) 
                    then false() 
                    else xpmt:assert-permutation(tail($result), $compare[position() != $index-of])
                    "/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>

    <xsl:template match="qt:assert-string-value" mode="xpmt:result-compare">
        <xsl:param name="result" as="item()*" tunnel="yes"/>
        <xsl:sequence select="
            if ($result instance of function(*)+) 
            then 
                false() 
            else 
                ($result => string-join(' ')) = .
                "/>
    </xsl:template>

    <xsl:template match="qt:assert-true" mode="xpmt:result-compare">
        <xsl:param name="result" as="item()*" tunnel="yes"/>
        <xsl:sequence select="$result instance of xs:boolean and $result"/>
    </xsl:template>

    <xsl:template match="qt:assert-false" mode="xpmt:result-compare">
        <xsl:param name="result" as="item()*" tunnel="yes"/>
        <xsl:sequence select="$result instance of xs:boolean and not($result)"/>
    </xsl:template>

    <xsl:template match="qt:assert-type" mode="xpmt:result-compare">
        <xsl:param name="result" as="item()*" tunnel="yes"/>
        <xsl:variable name="context" as="element()">
            <xsl:copy copy-namespaces="yes">
                <xsl:namespace name="xs" select="'http://www.w3.org/2001/XMLSchema'"/>
            </xsl:copy>
        </xsl:variable>
        <xsl:variable name="xpath" select="'$result instance of ' || ."/>
        <xsl:evaluate xpath="$xpath" namespace-context="$context" with-params="map{QName('', 'result') : $result}"/>
    </xsl:template>
    
    <xsl:template match="qt:error" mode="xpmt:result-compare">
        <xsl:param name="result" as="item()*" tunnel="yes"/>
        <xsl:choose>
            <xsl:when test="$result instance of map(*) and $result?err instance of map(*)">
                <xsl:variable name="code" select="$result?err?code" as="xs:QName"/>
                <xsl:sequence select="
                    if (@code = '*') 
                    then 
                        true() 
                    else
                        local-name-from-QName($code) = @code
                        and namespace-uri-from-QName($code) = 'http://www.w3.org/2005/xqt-errors'
                    "/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:sequence select="false()"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <xsl:template match="qt:assert-xml" mode="xpmt:result-compare">
        <xsl:param name="result" as="item()*" tunnel="yes"/>
        <xsl:variable name="xml" select="parse-xml-fragment(.)"/>
        
        
        <xsl:sequence select="
            if ($result instance of document-node()) 
            then xpmt:xml-equal($result, $xml, @ignore-prefixes = 'true', false()) 
            else if ($result instance of node()*) 
            then xpmt:xml-equal($result, $xml/node(), @ignore-prefixes = 'true', false()) 
            else false()
            "/>
        
    </xsl:template>
    
    <xsl:function name="xpmt:xml-equal" as="xs:boolean">
        <xsl:param name="result" as="node()*"/>
        <xsl:param name="compare" as="node()*"/>
        <xsl:param name="ignore-prefix" as="xs:boolean"/>
        <xsl:param name="unordered" as="xs:boolean"/>
        
        <xsl:variable name="sorts" select="function($n){name($n)}"/>
        <xsl:variable name="sorting" select="sort(?, (), $sorts)"/>
        
        <xsl:variable name="node-count" select="count($result)"/>
        <xsl:choose>
            <xsl:when test="$unordered">
                <xsl:sequence select="xpmt:xml-equal($sorting($result), $sorting($compare), $ignore-prefix, false())"/>
            </xsl:when>
            <xsl:when test="$node-count ne count($compare)">
                <xsl:message select="'Different node count: ' || ($node-count - count($compare))"></xsl:message>
                <xsl:sequence select="false()"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:sequence select="
                    every $i in (1 to $node-count)
                    satisfies
                        xpmt:node-equal($result[$i], $compare[$i], $ignore-prefix)
                    "/>
            </xsl:otherwise>
        </xsl:choose>
        
        
    </xsl:function>
    
    <xsl:function name="xpmt:node-equal" as="xs:boolean">
        <xsl:param name="result" as="node()"/>
        <xsl:param name="compare" as="node()"/>
        <xsl:param name="ignore-prefix" as="xs:boolean"/>
        <xsl:variable name="result-type" select="xpmt:node-type($result)"/>
        <xsl:variable name="type-equal" select="$result-type = xpmt:node-type($compare)"/>
        <xsl:variable name="ln-equal" select="local-name($result) = local-name($compare)"/>
        <xsl:variable name="ns-equal" select="namespace-uri($result) = namespace-uri($compare)"/>
        <xsl:variable name="name-equal" select="
            if ($ignore-prefix) then true() else name($result) = name($compare)
            "/>
        
        <xsl:variable name="content-equal" select="
            if ($result-type = ('element', 'document-node')) 
            then (
                xpmt:xml-equal($result/node(), $compare/node(), $ignore-prefix, true())
                and 
                xpmt:xml-equal($result/@*, $compare/@*, $ignore-prefix, false())
            ) 
            else if ($result-type = 'document-node') 
            then (
                xpmt:xml-equal($result/node(), $compare/node(), $ignore-prefix, true())
            ) 
            else true()
            "/>
        
        <xsl:variable name="is-equal" select="$type-equal and $ln-equal and $ns-equal and $name-equal and $content-equal"/>
        
        <xsl:if test="not($is-equal)">
            <xsl:message select="'Unequal at: ' || path($result) || ' vs ' || path($compare)"/>
        </xsl:if>
        
        <xsl:sequence select="$is-equal"/>
    </xsl:function>
    
    <xsl:function name="xpmt:node-type" as="xs:string">
        <xsl:param name="node" as="node()"/>
        <xsl:sequence select="
            if ($node instance of document-node()) 
            then 'document-node' 
            else 
            if ($node instance of element()) 
            then 'element' 
            else 
            if ($node instance of attribute()) 
            then 'attribute' 
            else 
            if ($node instance of text()) 
            then 'text' 
            else 
            if ($node instance of comment()) 
            then 'comment' 
            else 
            if ($node instance of processing-instruction()) 
            then 'processing-instruction' 
            else 
            if ($node instance of namespace-node()) 
            then 'namespace-node' 
            else 
                'unknown'
            "/>
    </xsl:function>
    

    <xsl:template match="qt:*" mode="xpmt:result-compare">
        <xsl:param name="result" as="item()*" tunnel="yes"/>
        <xsl:message expand-text="yes">Unsupported result requirement {name()}</xsl:message>
        <xsl:sequence select="false()"/>
    </xsl:template>
    
    
</xsl:stylesheet>