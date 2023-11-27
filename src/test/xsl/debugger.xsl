<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:nk="http://www.nkutsche.com/xpath-model" xmlns:math="http://www.w3.org/2005/xpath-functions/math" xmlns:p="http://www.nkutsche.com/xpath-parser" xmlns:r="http://maxtoroq.github.io/rng.xsl" xmlns:xpe="http://www.nkutsche.com/xpath-model/engine" xmlns:map="http://www.w3.org/2005/xpath-functions/map"
    exclude-result-prefixes="#all" version="3.0">
    <xsl:use-package name="http://maxtoroq.github.io/rng-xsl" package-version="*"/>
    
    <xsl:import href="../../main/resources/xsl/xpath-model.xsl"/>
    
    <xsl:output indent="yes"></xsl:output>
    
    <!--<xsl:param name="xpath" as="xs:string">function-name(function-lookup(QName('http://www.w3.org/2005/xpath-functions', 'position'), 0))</xsl:param>-->
    
    
    <xsl:param name="xpath" as="xs:string"><![CDATA[
      let $fn := /function-lookup(fn:QName('http://www.w3.org/2005/xpath-functions', 'document-uri'), 0)
      return parse-xml('<a/>')!$fn()
    ]]></xsl:param>
    
    <xsl:variable name="exec-context">
        <xsl:sequence select="doc('file:/C:/Users/Nico/Work/Intern/XPath-Model/target/qt3-testsuite/fn/function-lookup/function-lookup.xml')"/>
    </xsl:variable>
    
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
        <xsl:variable name="namespaces" select="map{
            'fn' : 'http://www.w3.org/2005/xpath-functions',
            'xs' : 'http://www.w3.org/2001/XMLSchema'
            }"/>
        <xsl:variable name="xpmodel" select="nk:xpath-model($xpath, map{'namespaces' : $namespaces})"/>
        <root>
            <saxon-result>
                <xsl:variable name="namespace-context" as="element()">
                    <ns xmlns:fn="http://www.w3.org/2005/xpath-functions" xmlns:xs="http://www.w3.org/2001/XMLSchema"/>
                </xsl:variable>
                <xsl:evaluate xpath="$xpath" context-item="$exec-context" namespace-context="$namespace-context"/>
            </saxon-result>
            <exec>
<!--                <xsl:sequence select="codepoint-equal('a')"/>-->
                <xsl:sequence select="xpe:xpath-evaluate($exec-context, $xpath, 
                    map{
                        'namespaces' : $namespaces,
                        'base-uri' : static-base-uri()
                    }
                    )"/>
            </exec>
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
