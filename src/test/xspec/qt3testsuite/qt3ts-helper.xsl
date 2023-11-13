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
        <xsl:map>
            <xsl:map-entry key="'namespaces'">
                <xsl:map>
                    <xsl:map-entry key="'fn'" select="'http://www.w3.org/2005/xpath-functions'"/>
                    <xsl:map-entry key="'xs'" select="'http://www.w3.org/2001/XMLSchema'"/>
                    <xsl:apply-templates select="$environment/qt:namespace" mode="xpmt:execution-context"/>
                </xsl:map>
            </xsl:map-entry>
        </xsl:map>
    </xsl:function>
    
    <xsl:template match="*" mode="xpmt:execution-context"/>
    
    <xsl:template match="qt:namespace" mode="xpmt:execution-context">
        <xsl:map-entry key="string(@prefix)" select="string(@uri)"/>
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
        <xsl:variable name="compare" as="item()*">
            <xsl:evaluate xpath="."/>
        </xsl:variable>
        <xsl:if test="not(deep-equal($result, $compare))">
            <xsl:message select="$compare instance of node()*"/>
            <xsl:message select="$result instance of node()*"/>
        </xsl:if>
        <xsl:sequence select="deep-equal($result, $compare)"/>
    </xsl:template>

    <xsl:template match="qt:assert-string-value" mode="xpmt:result-compare">
        <xsl:param name="result" as="item()*" tunnel="yes"/>
        <xsl:sequence select="($result ! string()) = ."/>
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
        <xsl:variable name="xpath" select="'. instance of ' || ."/>
        <xsl:choose>
            <xsl:when test="empty($result)">
                <xsl:evaluate xpath="'() instance of ' || ." namespace-context="$context"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:evaluate xpath="$xpath" context-item="$result" namespace-context="$context"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <xsl:template match="qt:error" mode="xpmt:result-compare">
        <xsl:param name="result" as="item()*" tunnel="yes"/>
        <xsl:choose>
            <xsl:when test="$result instance of map(*) and $result?err instance of map(*)">
                <xsl:variable name="code" select="$result?err?code" as="xs:QName"/>
                <xsl:sequence select="
                    local-name-from-QName($code) = @code
                    and namespace-uri-from-QName($code) = 'http://www.w3.org/2005/xqt-errors'
                    "/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:sequence select="false()"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    

    <xsl:template match="qt:*" mode="xpmt:result-compare">
        <xsl:param name="result" as="item()*" tunnel="yes"/>
        <xsl:message expand-text="yes">Unsupported result requirement {name()}</xsl:message>
        <xsl:sequence select="false()"/>
    </xsl:template>
    
    
</xsl:stylesheet>