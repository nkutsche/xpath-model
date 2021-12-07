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
    
    
</xsl:stylesheet>