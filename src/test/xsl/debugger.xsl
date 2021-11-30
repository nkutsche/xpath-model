<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:nk="http://www.nkutsche.com/xpath-model" xmlns:math="http://www.w3.org/2005/xpath-functions/math" xmlns:p="http://www.nkutsche.com/xpath-parser" xmlns:r="http://maxtoroq.github.io/rng.xsl" xmlns:map="http://www.w3.org/2005/xpath-functions/map" exclude-result-prefixes="#all" version="3.0">
    
    <xsl:import href="../../main/resources/xsl/xpath-model.xsl"/>
    
    <xsl:output indent="yes"></xsl:output>
    
    <xsl:template match="/">
        <xsl:variable name="xpath" as="xs:string">string-join#2('foo', 'bar')</xsl:variable>
        <root>
            <xpath>
                <xsl:value-of select="$xpath"/>
            </xpath>
            <model>
                <xsl:sequence select="nk:xpath-model($xpath)"/>
            </model>
            <raw>
                <xsl:sequence select="nk:pre-parse-comments(p:parse-XPath($xpath))"/>
            </raw>
        </root>
    </xsl:template>

</xsl:stylesheet>
