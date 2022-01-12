<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:math="http://www.w3.org/2005/xpath-functions/math"
    xmlns:nk="http://www.nkutsche.com/xpath-model"
    xmlns:map="http://www.w3.org/2005/xpath-functions/map"
    exclude-result-prefixes="xs math"
    version="3.0">
    
    <xsl:import href="../../src/main/resources/xsl/xpath-model.xsl"/>
    <xsl:import href="../../src/main/resources/xsl/xslt-3-avt.xsl"/>
    
    <xsl:function name="nk:sch-namespace-binding" as="map(xs:string, xs:string)" xmlns:sch="http://purl.oclc.org/dsdl/schematron">
        <xsl:param name="ns" as="element(sch:ns)*"/>
        
        <xsl:sequence select="$ns ! map{@prefix/string(.) : @uri/string(.)} => map:merge()"/>        
        
    </xsl:function>
    
</xsl:stylesheet>