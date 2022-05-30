<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:math="http://www.w3.org/2005/xpath-functions/math"
    xmlns:nk="http://www.nkutsche.com/xpath-model"
    xmlns:map="http://www.w3.org/2005/xpath-functions/map"
    xmlns:sch="http://purl.oclc.org/dsdl/schematron"
    xmlns:sqf="http://www.schematron-quickfix.com/validator/process"
    exclude-result-prefixes="#all"
    version="3.0">
    
    <xsl:import href="../../src/main/resources/xsl/xpath-model.xsl"/>
    <xsl:import href="../../src/main/resources/xsl/xslt-3-avt.xsl"/>
    
    <xsl:mode name="nk:transfer-namespace" on-no-match="shallow-copy"/>
    
    
    <xsl:variable name="process-namespaces" select="
        'http://purl.oclc.org/dsdl/schematron', 
        'http://www.schematron-quickfix.com/validator/process', 
        'http://www.w3.org/1999/XSL/Transform'
        "/>
    
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
        <xsl:variable name="namespace" select="namespace-uri-from-QName($qname) => string()" as="xs:string"/>
        
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
    
<!--    
    Checks that a given $nodeTest asks for a node which was declared in a given XSD $schema.
    -->
    
    <xsl:function name="nk:get-xpath-models" as="map(xs:string, element()?)">
        <xsl:param name="schema" as="element(sch:schema)"/>
        <xsl:variable name="namespace-decl" select="$schema/sch:ns"/>
        <xsl:variable name="pConfig" select="map{
            'namespaces' : nk:sch-namespace-binding($namespace-decl),
            'parse-mode' : 'lax'
            }"/>
        <xsl:sequence select="nk:get-xpath-models($schema, $pConfig)"/>
    </xsl:function>
    
    <xsl:function name="nk:get-xpath-models" as="map(xs:string, element()?)">
        <xsl:param name="schema" as="element(sch:schema)"/>
        <xsl:param name="pConfig" as="map(*)"/>
        <xsl:variable name="models" as="map(xs:string, element()?)*">
            <xsl:apply-templates select="$schema/*" mode="nk:get-xpath-models">
                <xsl:with-param name="pConfig" select="$pConfig" tunnel="yes"/>
            </xsl:apply-templates>
        </xsl:variable>
        <xsl:sequence select="$models => map:merge()"/>
    </xsl:function>
    
    <xsl:template match="
        xsl:*/@version | 
        xsl:*/@exclude-result-prefixes | 
        xsl:*/@extension-element-prefixes | 
        xsl:*/@xpath-default-namespace | 
        xsl:*/@default-collation | 
        xsl:*/@use-when
        " mode="nk:get-xpath-models" priority="10"/>
    
    <xsl:template match="
        (: Schematron :)
        sch:rule/@context | 
        sch:report/@test | 
        sch:assert/@test | 
        sch:let/@value | 
        sch:value-of/@select | 
        sch:name/@path | 
        sch:*/@subject |
        (: SQF :)
        sqf:*/@match | 
        sqf:*/@select | 
        sqf:*/@default | 
        sqf:*/@use-when | 
        sqf:fix/@use-for-each |
        (: XSLT :)
        xsl:*/@select | 
        xsl:for-each-group/@group-by | 
        xsl:for-each-group/@group-adjacent |
        xsl:for-each-group/@group-starting-with | 
        xsl:for-each-group/@group-ending-with |
        xsl:if/@test | 
        xsl:when/@test | 
        xsl:key/@use | 
        xsl:number/@value | 
        xsl:template/@match | 
        xsl:key/@match | 
        xsl:number/@count | 
        xsl:number/@from
        " mode="nk:get-xpath-models">
        <xsl:param name="pConfig" as="map(*)" tunnel="yes"/>
        <xsl:sequence select="map{generate-id(.) : nk:xpath-model(., $pConfig)}"/>
    </xsl:template>


    <xsl:template match="
        sqf:add/@target | 
        sqf:replace/@target |
        sqf:add//*[not(namespace-uri() = $process-namespaces)]/@* | 
        sqf:replace//*[not(namespace-uri() = $process-namespaces)]/@* | 
        sqf:stringReplace//*[not(namespace-uri() = $process-namespaces)]/@* |
        sqf:stringReplace/@regex |
        sqf:stringReplace/@flags |
        
        (: XSLT :)
        xsl:analyze-string/@regex |
        xsl:analyze-string/@flags |
        xsl:attribute/@name |
        xsl:attribute/@namespace |
        xsl:attribute/@separator |
        xsl:element/@name |
        xsl:element/@namespace |
        xsl:namespace/@name |
        xsl:value-of/@separator |
        xsl:message/@terminate |
        xsl:for-each-group/@collation |
        
        xsl:result-document/@*[not(name() = ('validation', 'type', 'use-character-maps'))] |
        
        xsl:number/@level |
        xsl:sort/@*
        " mode="nk:get-xpath-models">
        <xsl:param name="pConfig" as="map(*)" tunnel="yes"/>
        <xsl:sequence select="map{generate-id(.) : nk:xpath-model-value-template(., $pConfig)}"/>
    </xsl:template>
    
    <xsl:template match="*" mode="nk:get-xpath-models">
        <xsl:apply-templates select="@*" mode="#current"/>
        <xsl:apply-templates select="*" mode="#current"/>
    </xsl:template>
    
    <xsl:template match="@* | text()" mode="nk:get-xpath-models"/>
    
    
</xsl:stylesheet>