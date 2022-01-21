<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:math="http://www.w3.org/2005/xpath-functions/math"
    xmlns:nk="http://www.nkutsche.com/xpath-model"
    xmlns:map="http://www.w3.org/2005/xpath-functions/map"
    xmlns:sch="http://purl.oclc.org/dsdl/schematron"
    exclude-result-prefixes="#all"
    version="3.0">
    
    <xsl:import href="../../src/main/resources/xsl/xpath-model.xsl"/>
    <xsl:import href="../../src/main/resources/xsl/xslt-3-avt.xsl"/>
    
    <xsl:mode name="nk:transfer-namespace" on-no-match="shallow-copy"/>
    
    <xsl:function name="nk:sch-namespace-binding" as="map(xs:string, xs:string)">
        <xsl:param name="ns" as="element(sch:ns)*"/>
        
        <xsl:sequence select="$ns ! map{@prefix/string(.) : @uri/string(.)} => map:merge()"/>        
    </xsl:function>
    
    <xsl:function name="nk:transfer-namespace" as="element()">
        <xsl:param name="expr" as="element()"/>
        <xsl:param name="namespace-mapping" as="element(map)*"/>
        <xsl:param name="prefix-binding" as="element(sch:ns)*"/>
        
        <xsl:apply-templates select="$expr" mode="nk:transfer-namespace">
            <xsl:with-param name="namespace-mapping" select="$namespace-mapping" tunnel="yes"/>
            <xsl:with-param name="prefix-binding" select="$prefix-binding" tunnel="yes"/>
        </xsl:apply-templates>
    </xsl:function>
    
    <xsl:template match="nodeTest[@kind = 'element']/@name" mode="nk:transfer-namespace">
        <xsl:param name="namespace-mapping" as="element(map)*" tunnel="yes"/>
        <xsl:param name="prefix-binding" as="element(sch:ns)*" tunnel="yes"/>
        
        <xsl:variable name="qname" select="nk:as-qname(.)" as="xs:QName"/>
        <xsl:variable name="namespace" select="namespace-uri-from-QName($qname)" as="xs:string"/>
        
        <xsl:choose>
            <xsl:when test="$namespace-mapping/@invalid = $namespace">
                <xsl:variable name="trg-namespace" select="$namespace-mapping[@invalid = $namespace][1]/@valid"/>
                
                <xsl:variable name="new-prefix" select="($prefix-binding[@uri = $trg-namespace]/@prefix, '')[1]"/>
                <xsl:variable name="local-name" select="local-name-from-QName($qname)"/>
                <xsl:variable name="new-qname" select="nk:qname($new-prefix, $local-name, $trg-namespace)"/>    
                
                <xsl:variable name="ser-qname" select="
                    if ($new-prefix eq '' and $trg-namespace ne '') 
                    then ('Q{' || $trg-namespace || '}' || $local-name) 
                    else string($new-qname)
                    "/>
                
                <xsl:attribute name="name" select="$ser-qname"/>
                
            </xsl:when>
            <xsl:otherwise>
                <xsl:sequence select="."/>
            </xsl:otherwise>
        </xsl:choose>
        
        
    </xsl:template>
    
    <xsl:function name="nk:qname" as="xs:QName">
        <xsl:param name="prefix" as="xs:string"/>
        <xsl:param name="localname" as="xs:string"/>
        <xsl:param name="namespace" as="xs:string"/>
        
        <xsl:variable name="name" select="
            if ($prefix = '') then ($localname) else ($prefix || ':' || $localname)
            "/>
        
        <xsl:sequence select="QName($namespace, $name)"/>
        
    </xsl:function>
    
</xsl:stylesheet>