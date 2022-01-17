<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:nk="http://www.nkutsche.com/xpath-model" xmlns:math="http://www.w3.org/2005/xpath-functions/math" xmlns:p="http://www.nkutsche.com/xpath-parser" xmlns:r="http://maxtoroq.github.io/rng.xsl" xmlns:map="http://www.w3.org/2005/xpath-functions/map" exclude-result-prefixes="#all" version="3.0">
    
    <xsl:import href="../../main/resources/xsl/xpath-model.xsl"/>
    
    <xsl:output indent="yes"></xsl:output>
    
    <xsl:param name="xpath" as="xs:string">foo[@bar = 'baz']</xsl:param>
    
    <xsl:variable name="model" as="element(expr)">
        <expr>
            <operation type="node-compare">
                <arg>
                    <locationStep axis="child">
                        <nodeTest kind="element"/>
                    </locationStep>
                </arg>
                <eq/>
                <arg>
                    <locationStep axis="child">
                        <nodeTest name="foo" kind="element"/>
                    </locationStep>
                </arg>
            </operation>
        </expr>
    </xsl:variable>
    
    <xsl:template match="/">
        <xsl:variable name="xpmodel" select="nk:xpath-model($xpath)"/>
        <root>
            <ser>
                <xsl:sequence select="nk:xpath-serializer($model)"/>
            </ser>
            <xpath>
                <xsl:value-of select="$xpath"/>
            </xpath>
            <model>
                <xsl:sequence select="$xpmodel"/>
            </model>
            <re-ser>
                <xsl:sequence select="nk:xpath-serializer($xpmodel)"/>
            </re-ser>
            <raw>
                <xsl:sequence select="nk:pre-parse-comments(p:parse-XPath($xpath))"/>
            </raw>
        </root>
    </xsl:template>

</xsl:stylesheet>
