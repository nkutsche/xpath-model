<?xml version="1.0" encoding="UTF-8"?>
<sch:schema xmlns:sch="http://purl.oclc.org/dsdl/schematron" queryBinding="xslt3"
    xmlns:sqf="http://www.schematron-quickfix.com/validator/process" xmlns:nk="http://www.nkutsche.com/xpath-model"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
    <xsl:import href="lib.xsl"/>
    
    <sch:ns uri="http://purl.oclc.org/dsdl/schematron" prefix="sch"/>
    <sch:ns uri="http://www.w3.org/2005/xpath-functions" prefix="fn"/>
    <sch:ns uri="http://www.schematron-quickfix.com/validator/process" prefix="sqf"/>
    <sch:ns uri="http://www.nkutsche.com/xpath-model" prefix="nk"/>
    <sch:ns uri="http://www.nkutsche.com/avt-parser" prefix="avt"/>
    
    <sch:let name="config" value="if(doc-available('config.xml')) then doc('config.xml')/* else ()"/>
    <sch:let name="namespace-config" value="$config/namespace-maping/map"/>
    
    <sch:let name="allow-null-namespace" value="
        not(/sch:schema/sch:ns) or /sch:schema/@nk:allow-null-namespace = 'true' or ($namespace-config and not($namespace-config[@invalid = '']))
        "/>
    
    <sch:let name="namespace-decl" value="/sch:schema/sch:ns"/>
    
    
    <sch:let name="allowed-namespaces" value="
        $namespace-decl[not(@uri = $namespace-config/@invalid)]/@uri, ''[$allow-null-namespace]
        "/>
    
    <sch:let name="focus" value="/sch:schema/(sch:pattern|sch:phase)[@nk:focus]/(@id, generate-id())[1]"/>
    
    
    <sch:let name="focusIDs" value=" (/sch:schema/sch:phase[@id = $focus]/sch:active/@pattern/string(), $focus)"/>
    <sch:let name="ignored-patterns" value="
        if(exists($focusIDs)) then
        /sch:schema/(sch:pattern except sch:pattern[(@id, generate-id())[1] = $focusIDs]) 
        else ()
        "/>
    
    <sch:let name="process-namespaces" value="
        'http://purl.oclc.org/dsdl/schematron', 
        'http://www.schematron-quickfix.com/validator/process', 
        'http://www.w3.org/1999/XSL/Transform'
        "/>
    
    <sch:pattern id="check-null-namespace">
        
<!--        
        ignore non-focused patterns
        -->
        <sch:rule context="sch:pattern[. intersect $ignored-patterns]//@*"/>
        
<!--        
            ignore standard attributes of XSLT elements
        -->
        <sch:rule context="
            xsl:*/@version | 
            xsl:*/@exclude-result-prefixes | 
            xsl:*/@extension-element-prefixes | 
            xsl:*/@xpath-default-namespace | 
            xsl:*/@default-collation | 
            xsl:*/@use-when
            "/>
        
        
        <sch:rule context="
            sch:rule/@context | sch:report/@test | sch:assert/@test | 
            sch:let/@value | sch:value-of/@select | sch:name/@path | sch:*/@subject |
            (: SQF :)
            sqf:*/@match | sqf:*/@select | sqf:*/@default | sqf:*/@use-when | sqf:fix/@use-for-each |
            (: XSLT :)
            xsl:*/@select | xsl:for-each-group/@group-by | xsl:for-each-group/@group-adjacent |
            xsl:for-each-group/@group-starting-with | xsl:for-each-group/@group-ending-with |
            xsl:if/@test | xsl:when/@test | xsl:key/@use | xsl:number/@value | 
            xsl:template/@match | xsl:key/@match | xsl:number/@count | xsl:number/@from
            ">
            
            <sch:let name="parser-funct" value="nk:xpath-model#2"/>
            <sch:let name="serializer-funct" value="nk:xpath-serializer#1"/>
            
            <sch:extends rule="xpath-check"/>
            
        </sch:rule>
        
        <sch:rule context="
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
            
            xsl:result-document/@*[name() = ('validation', 'type', 'use-character-maps')] |
            
            xsl:number/@*[name() = 'level'] |
            xsl:sort/@*
            "
            >
            
            <sch:let name="parser-funct" value="nk:xpath-model-value-template#2"/>
            <sch:let name="serializer-funct" value="nk:value-template-serializer#1"/>
            
            <sch:extends rule="xpath-check"/>
            
        </sch:rule>
        
        <sch:rule abstract="true" id="xpath-check">
            
            
            <sch:let name="as-model" value="$parser-funct(., map{'namespaces' : nk:sch-namespace-binding($namespace-decl)})"/>
            
            
            <sch:let name="locationStep" value="
                $as-model//locationStep
                [
                nodeTest[@name][@kind = 'element']
                [not(nk:as-qname(@name) ! namespace-uri-from-QName(.) = $allowed-namespaces)]
                ]"/>
            
            <sch:report test="$locationStep">The location step(s) <sch:value-of select="$locationStep/nk:xpath-serializer-sub(.) => string-join(', ')"/> uses the null namespace or an unknown namespace.</sch:report>
            
            <sch:let name="itemType" value="
                $as-model//itemType
                [
                nodeTest[@name][@kind = 'element']
                [not(nk:as-qname(@name) ! namespace-uri-from-QName(.) = $allowed-namespaces)]
                ]"/>
            
            <sch:report test="$itemType">The sequence type(s) <sch:value-of select="$itemType/nk:xpath-serializer-sub(.) => string-join(', ')"/> uses the null namespace or an unknown namespace.</sch:report>
            
        </sch:rule>
        
        
    </sch:pattern>
    
    
    
</sch:schema>