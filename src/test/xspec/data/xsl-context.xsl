<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:math="http://www.w3.org/2005/xpath-functions/math"
    exclude-result-prefixes="xs math"
    version="3.0">
    
    <xsl:variable name="var-w-content" xml:id="var-w-content">
        <some>
            <content>
                <xsl:apply-templates select="/*" mode="var-w-content"/>
            </content>
        </some>
    </xsl:variable>
    
    <xsl:variable name="var" select="global-var-value"/>

    <xsl:variable name="var_recursive" select="$var"/>
    
    <xsl:variable name="global-dummy" select="dummy"/>
    
    <xsl:template match="/" xml:id="template-match">
        <xsl:variable name="root-level-dummy" select="'foo'"/>
        <xsl:for-each select="for-each-context">
            <xsl:variable name="self" select="."/>
            <xsl:variable name="var" select="local-var-value"/>
            <xsl:variable name="local-dummy-1" select="$self"/>
            <xsl:for-each select="inner-context">
                
                <xsl:variable name="local-dummy-2" select="$self"/>
                
            </xsl:for-each>
        </xsl:for-each>
    </xsl:template>
    
    <xsl:template match="/ | *">
        <xsl:variable name="relative-dummy" select="'foo'"/>
    </xsl:template>
    
    
</xsl:stylesheet>