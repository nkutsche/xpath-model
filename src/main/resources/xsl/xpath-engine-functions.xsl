<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:math="http://www.w3.org/2005/xpath-functions/math"
    xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl"
    xmlns:xpf="http://www.nkutsche.com/xmlml/xpath-engine/functions"
    xmlns:xpe="http://www.nkutsche.com/xpath-model/engine"
    xmlns:mlml="http://www.nkutsche.com/xmlml"
    exclude-result-prefixes="xs math xd"
    version="3.0">
    <xsl:variable name="xpf:namespace-uri" select="'http://www.nkutsche.com/xmlml/xpath-engine/functions'"/>
    
    <xsl:variable name="function-lib-ns" select="$xpf:namespace-uri"/>
    
    <xd:doc scope="stylesheet">
        <xd:desc>
            <xd:p><xd:b>Created on:</xd:b> Nov 4, 2023</xd:p>
            <xd:p><xd:b>Author:</xd:b> Nico</xd:p>
            <xd:p></xd:p>
        </xd:desc>
    </xd:doc>
    
    <xsl:function name="xpf:number" as="xs:double">
        <xsl:param name="exec-context" as="map(*)"/>
        <xsl:sequence select="number(xpe:atomize($exec-context?context))"/>
    </xsl:function>

    <xsl:function name="xpf:compare" as="xs:integer?">
        <xsl:param name="exec-context" as="map(*)"/>
        <xsl:param name="comparand1" as="item()?"/>
        <xsl:param name="comparand2" as="item()?"/>
        <xsl:sequence select="compare(xpe:atomize($comparand1), xpe:atomize($comparand2), xpf:default-collation($exec-context))"/>
    </xsl:function>

    <xsl:function name="xpf:string-length" as="xs:integer">
        <xsl:param name="exec-context" as="map(*)"/>
        <xsl:sequence select="string-length(xpe:atomize($exec-context?context))"/>
    </xsl:function>
    
    <xsl:function name="xpf:normalize-space" as="xs:string">
        <xsl:param name="exec-context" as="map(*)"/>
        <xsl:sequence select="normalize-space(xpe:atomize($exec-context?context))"/>
    </xsl:function>

    <xsl:function name="xpf:contains" as="xs:boolean">
        <xsl:param name="exec-context" as="map(*)"/>
        <xsl:param name="arg1" as="item()?"/>
        <xsl:param name="arg2" as="item()?"/>
        <xsl:sequence select="contains(xpe:atomize($arg1), xpe:atomize($arg2), xpf:default-collation($exec-context))"/>
    </xsl:function>

    <xsl:function name="xpf:starts-with" as="xs:boolean">
        <xsl:param name="exec-context" as="map(*)"/>
        <xsl:param name="arg1" as="item()?"/>
        <xsl:param name="arg2" as="item()?"/>
        <xsl:sequence select="starts-with(xpe:atomize($arg1), xpe:atomize($arg2), xpf:default-collation($exec-context))"/>
    </xsl:function>
    
    <xsl:function name="xpf:ends-with" as="xs:boolean">
        <xsl:param name="exec-context" as="map(*)"/>
        <xsl:param name="arg1" as="item()?"/>
        <xsl:param name="arg2" as="item()?"/>
        <xsl:sequence select="ends-with(xpe:atomize($arg1), xpe:atomize($arg2), xpf:default-collation($exec-context))"/>
    </xsl:function>
    
    <xsl:function name="xpf:substring-before" as="xs:string">
        <xsl:param name="exec-context" as="map(*)"/>
        <xsl:param name="arg1" as="item()?"/>
        <xsl:param name="arg2" as="item()?"/>
        <xsl:sequence select="substring-before(xpe:atomize($arg1), xpe:atomize($arg2), xpf:default-collation($exec-context))"/>
    </xsl:function>
    
    <xsl:function name="xpf:substring-after" as="xs:string">
        <xsl:param name="exec-context" as="map(*)"/>
        <xsl:param name="arg1" as="item()?"/>
        <xsl:param name="arg2" as="item()?"/>
        <xsl:sequence select="substring-after(xpe:atomize($arg1), xpe:atomize($arg2), xpf:default-collation($exec-context))"/>
    </xsl:function>
    
    <xsl:function name="xpf:resolve-uri" as="xs:anyURI?">
        <xsl:param name="exec-context" as="map(*)"/>
        <xsl:param name="relative" as="item()?"/>
        <xsl:sequence select="resolve-uri(xpe:atomize($relative), xpf:static-base-uri($exec-context))"/>
    </xsl:function>
    
    <xsl:function name="xpf:resolve-QName" as="xs:QName?">
        <xsl:param name="exec-context" as="map(*)"/>
        <xsl:param name="qname" as="xs:string?"/>
        <xsl:param name="element" as="element()"/>
    </xsl:function>
    <xsl:function name="xpf:namespace-uri-for-prefix" as="xs:anyURI?">
        <xsl:param name="exec-context" as="map(*)"/>
        <xsl:param name="prefix" as="xs:string?"/>
        <xsl:param name="element" as="element()"/>
    </xsl:function>
    <xsl:function name="xpf:in-scope-prefixes" as="xs:string*">
        <xsl:param name="exec-context" as="map(*)"/>
        <xsl:param name="element" as="element()"/>
    </xsl:function>
    <xsl:function name="xpf:name" as="xs:string">
        <xsl:param name="exec-context" as="map(*)"/>
        <xsl:sequence select="xpf:name($exec-context, $exec-context?context)"/>
    </xsl:function>
    <xsl:function name="xpf:name" as="xs:string">
        <xsl:param name="exec-context" as="map(*)"/>
        <xsl:param name="arg" as="node()?"/>
        <xsl:sequence select="name($arg)"/>
    </xsl:function>
    <xsl:function name="xpf:local-name" as="xs:string">
        <xsl:param name="exec-context" as="map(*)"/>
        <xsl:sequence select="xpf:local-name($exec-context, $exec-context?context)"/>
    </xsl:function>
    <xsl:function name="xpf:local-name" as="xs:string">
        <xsl:param name="exec-context" as="map(*)"/>
        <xsl:param name="arg" as="node()?"/>
        <xsl:sequence select="local-name($arg)"/>
    </xsl:function>
    <xsl:function name="xpf:namespace-uri" as="xs:anyURI">
        <xsl:param name="exec-context" as="map(*)"/>
        <xsl:sequence select="xpf:namespace-uri($exec-context, $exec-context?context)"/>
    </xsl:function>
    <xsl:function name="xpf:namespace-uri" as="xs:anyURI">
        <xsl:param name="exec-context" as="map(*)"/>
        <xsl:param name="arg" as="node()?"/>
        <xsl:sequence select="namespace-uri($arg)"/>
    </xsl:function>
    <xsl:function name="xpf:lang" as="xs:boolean">
        <xsl:param name="exec-context" as="map(*)"/>
        <xsl:param name="testlang" as="xs:string?"/>
        <!--   TODO     -->
        <xsl:sequence select="false()"/>
    </xsl:function>
    <xsl:function name="xpf:lang" as="xs:boolean">
        <xsl:param name="exec-context" as="map(*)"/>
        <xsl:param name="testlang" as="xs:string?"/>
        <xsl:param name="node" as="node()"/>
        <!--   TODO     -->
        <xsl:sequence select="false()"/>
    </xsl:function>
    <xsl:function name="xpf:root" as="node()">
        <xsl:param name="exec-context" as="map(*)"/>
        <xsl:sequence select="xpf:root($exec-context, $exec-context?context)"/>
    </xsl:function>
    <xsl:function name="xpf:root" as="node()">
        <xsl:param name="exec-context" as="map(*)"/>
        <xsl:param name="arg" as="node()?"/>
        <xsl:sequence select="root($arg)"/>
    </xsl:function>
    <xsl:function name="xpf:path" as="xs:string?">
        <xsl:param name="exec-context" as="map(*)"/>
    </xsl:function>
    <xsl:function name="xpf:path" as="xs:string?">
        <xsl:param name="exec-context" as="map(*)"/>
        <xsl:param name="arg" as="node()?"/>
    </xsl:function>
    <xsl:function name="xpf:has-children" as="xs:boolean">
        <xsl:param name="exec-context" as="map(*)"/>
        <!--   TODO     -->
        <xsl:sequence select="false()"/>
    </xsl:function>
    <xsl:function name="xpf:has-children" as="xs:boolean">
        <xsl:param name="exec-context" as="map(*)"/>
        <xsl:param name="node" as="node()?"/>
        <!--   TODO     -->
        <xsl:sequence select="false()"/>
    </xsl:function>
    <xsl:function name="xpf:innermost" as="node()*">
        <xsl:param name="exec-context" as="map(*)"/>
        <xsl:param name="nodes" as="node()*"/>
        <!--   TODO     -->
    </xsl:function>
    <xsl:function name="xpf:outermost" as="node()*">
        <xsl:param name="exec-context" as="map(*)"/>
        <xsl:param name="nodes" as="node()*"/>
        <!--   TODO     -->
    </xsl:function>
    <xsl:function name="xpf:head" as="item()?">
        <xsl:param name="exec-context" as="map(*)"/>
        <xsl:param name="arg" as="item()*"/>
        <xsl:sequence select="head($arg)"/>
    </xsl:function>
    <xsl:function name="xpf:tail" as="item()*">
        <xsl:param name="exec-context" as="map(*)"/>
        <xsl:param name="arg" as="item()*"/>
        <xsl:sequence select="tail($arg)"/>
    </xsl:function>
    <xsl:function name="xpf:insert-before" as="item()*">
        <xsl:param name="exec-context" as="map(*)"/>
        <xsl:param name="target" as="item()*"/>
        <xsl:param name="position" as="xs:integer"/>
        <xsl:param name="inserts" as="item()*"/>
        <xsl:sequence select="insert-before($target, $position, $inserts)"/>
    </xsl:function>
    <xsl:function name="xpf:remove" as="item()*">
        <xsl:param name="exec-context" as="map(*)"/>
        <xsl:param name="target" as="item()*"/>
        <xsl:param name="position" as="xs:integer"/>
        <xsl:sequence select="remove($target, $position)"/>
    </xsl:function>
    <xsl:function name="xpf:reverse" as="item()*">
        <xsl:param name="exec-context" as="map(*)"/>
        <xsl:param name="arg" as="item()*"/>
        <xsl:sequence select="reverse($arg)"/>
    </xsl:function>
    <xsl:function name="xpf:unordered" as="item()*">
        <xsl:param name="exec-context" as="map(*)"/>
        <xsl:param name="sourceSeq" as="item()*"/>
        <xsl:sequence select="unordered($sourceSeq)"/>
    </xsl:function>
    <xsl:function name="xpf:distinct-values" as="xs:anyAtomicType*">
        <xsl:param name="exec-context" as="map(*)"/>
        <xsl:param name="arg" as="item()*"/>
        <xsl:sequence select="distinct-values(xpe:atomize($arg), xpf:default-collation($exec-context))"/>
    </xsl:function>
    
    <xsl:function name="xpf:index-of" as="xs:integer*">
        <xsl:param name="exec-context" as="map(*)"/>
        <xsl:param name="seq" as="item()*"/>
        <xsl:param name="search" as="item()"/>
        <xsl:sequence select="index-of(xpe:atomize($seq), xpe:atomize($search), xpf:default-collation($exec-context))"/>
    </xsl:function>
    
    <xsl:function name="xpf:deep-equal" as="xs:boolean">
        <xsl:param name="exec-context" as="map(*)"/>
        <xsl:param name="parameter1" as="item()*"/>
        <xsl:param name="parameter2" as="item()*"/>
        <xsl:sequence select="deep-equal($parameter1, $parameter2, xpf:default-collation($exec-context))"/>
    </xsl:function>
    <!--<xsl:function name="xpf:deep-equal" as="xs:boolean">
        <xsl:param name="exec-context" as="map(*)"/>
        <xsl:param name="parameter1" as="item()*"/>
        <xsl:param name="parameter2" as="item()*"/>
        <xsl:param name="collation" as="xs:string"/>
    </xsl:function>-->
    <xsl:function name="xpf:zero-or-one" as="item()?">
        <xsl:param name="exec-context" as="map(*)"/>
        <xsl:param name="arg" as="item()*"/>
        <xsl:sequence select="zero-or-one($arg)"/>
    </xsl:function>
    <xsl:function name="xpf:one-or-more" as="item()+">
        <xsl:param name="exec-context" as="map(*)"/>
        <xsl:param name="arg" as="item()*"/>
        <xsl:sequence select="one-or-more($arg)"/>
    </xsl:function>
    <xsl:function name="xpf:exactly-one" as="item()">
        <xsl:param name="exec-context" as="map(*)"/>
        <xsl:param name="arg" as="item()*"/>
        <xsl:sequence select="exactly-one($arg)"/>
    </xsl:function>
    <xsl:function name="xpf:max" as="xs:anyAtomicType?">
        <xsl:param name="exec-context" as="map(*)"/>
        <xsl:param name="arg" as="item()*"/>
        <xsl:sequence select="max(xpe:atomize($arg), xpf:default-collation($exec-context))"/>
    </xsl:function>
    
    <xsl:function name="xpf:min" as="xs:anyAtomicType?">
        <xsl:param name="exec-context" as="map(*)"/>
        <xsl:param name="arg" as="item()*"/>
        <xsl:sequence select="min(xpe:atomize($arg), xpf:default-collation($exec-context))"/>
    </xsl:function>
    
    <xsl:function name="xpf:id" as="element()*">
        <xsl:param name="exec-context" as="map(*)"/>
        <xsl:param name="arg" as="xs:string*"/>
    </xsl:function>
    <xsl:function name="xpf:id" as="element()*">
        <xsl:param name="exec-context" as="map(*)"/>
        <xsl:param name="arg" as="xs:string*"/>
        <xsl:param name="node" as="node()"/>
    </xsl:function>
    <xsl:function name="xpf:element-with-id" as="element()*">
        <xsl:param name="exec-context" as="map(*)"/>
        <xsl:param name="arg" as="xs:string*"/>
    </xsl:function>
    <xsl:function name="xpf:element-with-id" as="element()*">
        <xsl:param name="exec-context" as="map(*)"/>
        <xsl:param name="arg" as="xs:string*"/>
        <xsl:param name="node" as="node()"/>
    </xsl:function>
    <xsl:function name="xpf:idref" as="node()*">
        <xsl:param name="exec-context" as="map(*)"/>
        <xsl:param name="arg" as="xs:string*"/>
    </xsl:function>
    <xsl:function name="xpf:idref" as="node()*">
        <xsl:param name="exec-context" as="map(*)"/>
        <xsl:param name="arg" as="xs:string*"/>
        <xsl:param name="node" as="node()"/>
    </xsl:function>
    <xsl:function name="xpf:generate-id" as="xs:string">
        <xsl:param name="exec-context" as="map(*)"/>
        <xsl:sequence select="xpf:generate-id($exec-context, $exec-context?context)"/>
    </xsl:function>
    <xsl:function name="xpf:generate-id" as="xs:string">
        <xsl:param name="exec-context" as="map(*)"/>
        <xsl:param name="arg" as="node()?"/>
        <xsl:sequence select="generate-id($arg)"/>
    </xsl:function>
    <xsl:function name="xpf:doc" as="document-node()?">
        <xsl:param name="exec-context" as="map(*)"/>
        <xsl:param name="uri" as="xs:string?"/>
    </xsl:function>
    <xsl:function name="xpf:collection" as="node()*">
        <xsl:param name="exec-context" as="map(*)"/>
    </xsl:function>
    <xsl:function name="xpf:collection" as="node()*">
        <xsl:param name="exec-context" as="map(*)"/>
        <xsl:param name="arg" as="xs:string?"/>
    </xsl:function>
    <xsl:function name="xpf:uri-collection" as="xs:anyURI*">
        <xsl:param name="exec-context" as="map(*)"/>
    </xsl:function>
    <xsl:function name="xpf:uri-collection" as="xs:anyURI*">
        <xsl:param name="exec-context" as="map(*)"/>
        <xsl:param name="arg" as="xs:string?"/>
    </xsl:function>
    <xsl:function name="xpf:parse-xml" as="document-node(element(*))?">
        <xsl:param name="exec-context" as="map(*)"/>
        <xsl:param name="arg" as="xs:string?"/>
    </xsl:function>
    <xsl:function name="xpf:parse-xml-fragment" as="document-node()?">
        <xsl:param name="exec-context" as="map(*)"/>
        <xsl:param name="arg" as="xs:string?"/>
    </xsl:function>
    <xsl:function name="xpf:serialize" as="xs:string">
        <xsl:param name="exec-context" as="map(*)"/>
        <xsl:param name="arg" as="item()*"/>
        <xsl:sequence select="xpf:serialize($exec-context, $arg, ())"/>
    </xsl:function>
    <xsl:function name="xpf:serialize" as="xs:string">
        <xsl:param name="exec-context" as="map(*)"/>
        <xsl:param name="arg" as="item()*"/>
        <!--    TODO:    <xsl:param name="params" as="element(output:serialization-parameters)?"/>-->
        <xsl:param name="params" as="element()?"/>
        <!--        TODO-->
        <xsl:sequence select="''"/>
    </xsl:function>
    <xsl:function name="xpf:position" as="xs:integer">
        <xsl:param name="exec-context" as="map(*)"/>
        <xsl:sequence select="($exec-context?position, 1)[1]"/>
    </xsl:function>
    <xsl:function name="xpf:last" as="xs:integer">
        <xsl:param name="exec-context" as="map(*)"/>
        <xsl:sequence select="($exec-context?last, 1)[1]"/>
    </xsl:function>
    <xsl:function name="xpf:default-collation" as="xs:string">
        <xsl:param name="exec-context" as="map(*)"/>
        <xsl:sequence select="($exec-context?default-collation, default-collation())[1]"/>
    </xsl:function>
    <xsl:function name="xpf:static-base-uri" as="xs:anyURI?">
        <xsl:param name="exec-context" as="map(*)"/>
        <xsl:sequence select="($exec-context?base-uri, static-base-uri())[1]"/>
    </xsl:function>
    <xsl:function name="xpf:function-lookup" as="function(*)?">
        <xsl:param name="exec-context" as="map(*)"/>
        <xsl:param name="name" as="xs:QName"/>
        <xsl:param name="arity" as="xs:integer"/>
        
        <xsl:variable name="local-name" select="local-name-from-QName($name)"/>
        <xsl:variable name="ns-uri" select="namespace-uri-from-QName($name)"/>
        
        <xsl:variable name="function" select="
            if ($ns-uri = $fn_namespace-uri and function-available('xpf:' || $local-name, $arity + 1)) 
            then function-lookup(xs:QName('xpf:' || $local-name), $arity + 1) 
            else function-lookup($name, $arity)"/>
        <xsl:if test="empty($function)">
            <xsl:message expand-text="yes">Could not find funciton Q{{{$ns-uri}}}{$local-name}!</xsl:message>
        </xsl:if>
        <xsl:sequence select="
            $function
            "/>
    </xsl:function>
    <xsl:function name="xpf:function-name" as="xs:QName?">
        <xsl:param name="exec-context" as="map(*)"/>
        <xsl:param name="func" as="function(*)"/>
        
        <xsl:variable name="func-name" select="function-name($func)"/>
        <xsl:variable name="namespace" select="$func-name ! namespace-uri-from-QName(.)"/>
        <xsl:sequence select="
            if ($namespace = $xpf:namespace-uri) 
            then QName($fn_namespace-uri, local-name-from-QName($func-name)) 
            else $func-name
            "/>
        
    </xsl:function>
    <xsl:function name="xpf:for-each" as="item()*">
        <xsl:param name="exec-context" as="map(*)"/>
        <xsl:param name="seq" as="item()*"/>
        <xsl:param name="f" as="function(item()) as item()*"/>
        <xsl:sequence select="for-each($seq, $f)"/>
    </xsl:function>
    <xsl:function name="xpf:filter" as="item()*">
        <xsl:param name="exec-context" as="map(*)"/>
        <xsl:param name="seq" as="item()*"/>
        <xsl:param name="f" as="function(item()) as xs:boolean"/>
        <xsl:sequence select="filter($seq, $f)"/>
    </xsl:function>
    <xsl:function name="xpf:fold-left" as="item()*">
        <xsl:param name="exec-context" as="map(*)"/>
        <xsl:param name="seq" as="item()*"/>
        <xsl:param name="zero" as="item()*"/>
        <xsl:param name="f" as="function(item()*, item()) as item()*"/>
        <xsl:sequence select="fold-left($seq, $zero, $f)"/>
    </xsl:function>
    <xsl:function name="xpf:fold-right" as="item()*">
        <xsl:param name="exec-context" as="map(*)"/>
        <xsl:param name="seq" as="item()*"/>
        <xsl:param name="zero" as="item()*"/>
        <xsl:param name="f" as="function(item()*, item()) as item()*"/>
        <xsl:sequence select="fold-right($seq, $zero, $f)"/>
    </xsl:function>
    <xsl:function name="xpf:for-each-pair" as="item()*">
        <xsl:param name="exec-context" as="map(*)"/>
        <xsl:param name="seq1" as="item()*"/>
        <xsl:param name="seq2" as="item()*"/>
        <xsl:param name="f" as="function(item(), item()) as item()*"/>
        <xsl:sequence select="for-each-pair($seq1, $seq2, $f)"/>
    </xsl:function>

    
</xsl:stylesheet>