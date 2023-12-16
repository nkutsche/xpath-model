<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:math="http://www.w3.org/2005/xpath-functions/math"
    xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl"
    xmlns:xpf="http://www.nkutsche.com/xmlml/xpath-engine/functions"
    xmlns:xpfs="http://www.nkutsche.com/xmlml/xpath-engine/xsd-constructors"
    xmlns:xpe="http://www.nkutsche.com/xpath-model/engine"
    xmlns:mlml="http://www.nkutsche.com/xmlml"
    xmlns:xpm="http://www.nkutsche.com/xpath-model"
    xmlns:err="http://www.w3.org/2005/xqt-errors"
    xmlns:fn="http://www.w3.org/2005/xpath-functions"
    xmlns:fos="http://www.w3.org/xpath-functions/spec/namespace"
    xmlns:array="http://www.w3.org/2005/xpath-functions/array"
    xmlns:map="http://www.w3.org/2005/xpath-functions/map"
    exclude-result-prefixes="xs math xd"
    version="3.0">
    <xsl:variable name="xpf:namespace-uri" select="'http://www.nkutsche.com/xmlml/xpath-engine/functions'"/>
    <xsl:variable name="xpfs:namespace-uri" select="'http://www.nkutsche.com/xmlml/xpath-engine/xsd-constructors'"/>
    
    <xsl:variable name="function-lib-ns" select="$xpf:namespace-uri"/>
    
    <xsl:variable name="function-signatures" select="doc('xpath-functions/function-signatures.xml')"/>
    
    <xsl:variable name="build-in-namespaces" select="map{
        'fn' : 'http://www.w3.org/2005/xpath-functions',
        'xs' : 'http://www.w3.org/2001/XMLSchema',
        'array' : 'http://www.w3.org/2005/xpath-functions/array',
        'map' : 'http://www.w3.org/2005/xpath-functions/map',
        'math' : 'http://www.w3.org/2005/xpath-functions/math',
        'xpf' : $xpf:namespace-uri
        }"/>
    
    <xd:doc scope="stylesheet">
        <xd:desc>
            <xd:p><xd:b>Created on:</xd:b> Nov 4, 2023</xd:p>
            <xd:p><xd:b>Author:</xd:b> Nico</xd:p>
            <xd:p></xd:p>
        </xd:desc>
    </xd:doc>
    
    <xsl:function name="xpf:number" as="xs:double">
        <xsl:param name="exec-context" as="map(*)"/>
        <xsl:variable name="context" select="$exec-context?context"/>
        <xsl:sequence select="
            if (empty($context)) 
            then error(xpe:error-code('XPDY0002'), 'Context item is absent for function call number()') 
            else number(xpf:data($exec-context, $context))"/>
    </xsl:function>

    <xsl:function name="xpf:compare" as="xs:integer?">
        <xsl:param name="exec-context" as="map(*)"/>
        <xsl:param name="comparand1" as="item()?"/>
        <xsl:param name="comparand2" as="item()?"/>
        <xsl:sequence select="compare(xpe:atomize($comparand1), xpe:atomize($comparand2), xpf:default-collation($exec-context))"/>
    </xsl:function>

    <xsl:function name="xpf:string" as="xs:string">
        <xsl:param name="exec-context" as="map(*)"/>
        <xsl:variable name="context" select="$exec-context?context"/>
        <xsl:sequence select="
            if (empty($context)) 
            then error(xpe:error-code('XPDY0002'), 'Context item is absent for function call string()') 
            else string(xpf:data($exec-context, $context))"/>
    </xsl:function>

    <xsl:function name="xpf:node-name" as="xs:QName">
        <xsl:param name="exec-context" as="map(*)"/>
        <xsl:variable name="context" select="$exec-context?context"/>
        <xsl:sequence select="
            if (empty($context)) 
            then error(xpe:error-code('XPDY0002'), 'Context item is absent for function call node-name()') 
            else node-name($context)"/>
    </xsl:function>

    <xsl:function name="xpf:nilled" as="xs:boolean?">
        <xsl:param name="exec-context" as="map(*)"/>
        <xsl:variable name="context" select="$exec-context?context"/>
        <xsl:sequence select="
            if (empty($context)) 
            then error(xpe:error-code('XPDY0002'), 'Context item is absent for function call nilled()') 
            else nilled($context)
            "/>
    </xsl:function>

    <xsl:function name="xpf:data" as="item()*">
        <xsl:param name="exec-context" as="map(*)"/>
        <xsl:variable name="context" select="$exec-context?context"/>
        <xsl:sequence select="
            if (empty($context)) 
            then error(xpe:error-code('XPDY0002'), 'Context item is absent for function call data()') 
            else xpf:data($exec-context, $context)"/>
    </xsl:function>

    <xsl:function name="xpf:data" as="item()*">
        <xsl:param name="exec-context" as="map(*)"/>
        <xsl:sequence select="data($exec-context?context)"/>
    </xsl:function>

    <xsl:function name="xpf:document-uri" as="xs:anyURI?">
        <xsl:param name="exec-context" as="map(*)"/>
        <xsl:variable name="context" select="$exec-context?context"/>
        <xsl:sequence select="
            if (empty($context)) 
            then error(xpe:error-code('XPDY0002'), 'Context item is absent for function call document-uri()') 
            else document-uri($context)"/>
    </xsl:function>

    <xsl:function name="xpf:string-length" as="xs:integer">
        <xsl:param name="exec-context" as="map(*)"/>
        <xsl:variable name="context" select="$exec-context?context"/>
        <xsl:sequence select="
            if (empty($context)) 
            then error(xpe:error-code('XPDY0002'), 'Context item is absent for function call string-length()') 
            else string-length(xpf:data($exec-context, $context))"/>
    </xsl:function>
    
    <xsl:function name="xpf:normalize-space" as="xs:string">
        <xsl:param name="exec-context" as="map(*)"/>
        <xsl:variable name="context" select="$exec-context?context"/>
        <xsl:sequence select="
            if (empty($context)) 
            then error(xpe:error-code('XPDY0002'), 'Context item is absent for function call normalize-space()') 
            else normalize-space(xpf:data($exec-context, $context))"/>
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
        <xsl:param name="arg1" as="xs:string?"/>
        <xsl:param name="arg2" as="xs:string?"/>
        <xsl:sequence select="xpf:substring-before($exec-context, $arg1, $arg2, xpf:default-collation($exec-context))"/>
    </xsl:function>
    
    <xsl:function name="xpf:substring-before" as="xs:string">
        <xsl:param name="exec-context" as="map(*)"/>
        <xsl:param name="arg1" as="xs:string?"/>
        <xsl:param name="arg2" as="xs:string?"/>
        <xsl:param name="collation" as="xs:string"/>
        <xsl:variable name="collation" select="resolve-uri($collation, xpf:static-base-uri($exec-context))"/>
        <xsl:sequence select="substring-before($arg1, $arg2, $collation)"/>
    </xsl:function>
    
    <xsl:function name="xpf:substring-after" as="xs:string">
        <xsl:param name="exec-context" as="map(*)"/>
        <xsl:param name="arg1" as="xs:string?"/>
        <xsl:param name="arg2" as="xs:string?"/>
        <xsl:sequence select="xpf:substring-after($exec-context, $arg1, $arg2, xpf:default-collation($exec-context))"/>
    </xsl:function>
    
    <xsl:function name="xpf:substring-after" as="xs:string">
        <xsl:param name="exec-context" as="map(*)"/>
        <xsl:param name="arg1" as="xs:string?"/>
        <xsl:param name="arg2" as="xs:string?"/>
        <xsl:param name="collation" as="xs:string"/>
        <xsl:variable name="collation" select="resolve-uri($collation, xpf:static-base-uri($exec-context))"/>
        <xsl:sequence select="substring-after($arg1, $arg2, $collation)"/>
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
        <xsl:variable name="context" select="$exec-context?context"/>
        <xsl:sequence select="
            if (empty($context)) 
            then error(xpe:error-code('XPDY0002'), 'Context item is absent for function call name()') 
            else xpf:name($exec-context, $context)"/>
    </xsl:function>
    <xsl:function name="xpf:name" as="xs:string">
        <xsl:param name="exec-context" as="map(*)"/>
        <xsl:param name="arg" as="node()?"/>
        <xsl:sequence select="name($arg)"/>
    </xsl:function>
    <xsl:function name="xpf:local-name" as="xs:string">
        <xsl:param name="exec-context" as="map(*)"/>
        <xsl:variable name="context" select="$exec-context?context"/>
        <xsl:sequence select="
            if (empty($context)) 
            then error(xpe:error-code('XPDY0002'), 'Context item is absent for function call local-name()') 
            else xpf:local-name($exec-context, $context)"/>
    </xsl:function>
    <xsl:function name="xpf:local-name" as="xs:string">
        <xsl:param name="exec-context" as="map(*)"/>
        <xsl:param name="arg" as="node()?"/>
        <xsl:sequence select="local-name($arg)"/>
    </xsl:function>
    <xsl:function name="xpf:namespace-uri" as="xs:anyURI">
        <xsl:param name="exec-context" as="map(*)"/>
        <xsl:variable name="context" select="$exec-context?context"/>
        <xsl:sequence select="
            if (empty($context)) 
            then error(xpe:error-code('XPDY0002'), 'Context item is absent for function call namespace-uri()') 
            else xpf:namespace-uri($exec-context, $context)"/>
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
    <xsl:function name="xpf:root" as="node()?">
        <xsl:param name="exec-context" as="map(*)"/>
        <xsl:variable name="context" select="$exec-context?context"/>
        <xsl:sequence select="
            if (empty($context)) 
            then error(xpe:error-code('XPDY0002'), 'Context item is absent for function call root()') 
            else xpf:root($exec-context, $context)"/>
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
        <xsl:sequence select="xpf:id($exec-context, $arg, $exec-context?context)"/>
    </xsl:function>
    <xsl:function name="xpf:id" as="element()*">
        <xsl:param name="exec-context" as="map(*)"/>
        <xsl:param name="arg" as="xs:string*"/>
        <xsl:param name="node" as="node()"/>
        <xsl:sequence select="id(xpe:atomize($arg), $node)"/>
    </xsl:function>
    <xsl:function name="xpf:element-with-id" as="element()*">
        <xsl:param name="exec-context" as="map(*)"/>
        <xsl:param name="arg" as="xs:string*"/>
        <xsl:sequence select="xpf:element-with-id($exec-context, $arg, $exec-context?context)"/>
    </xsl:function>
    <xsl:function name="xpf:element-with-id" as="element()*">
        <xsl:param name="exec-context" as="map(*)"/>
        <xsl:param name="arg" as="xs:string*"/>
        <xsl:param name="node" as="node()"/>
        <xsl:sequence select="element-with-id(xpe:atomize($arg), $node)"/>
    </xsl:function>
    
    <xsl:function name="xpf:idref" as="node()*">
        <xsl:param name="exec-context" as="map(*)"/>
        <xsl:param name="arg" as="xs:string*"/>
        <xsl:sequence select="xpf:idref($exec-context, $arg, $exec-context?context)"/>
    </xsl:function>
    <xsl:function name="xpf:idref" as="node()*">
        <xsl:param name="exec-context" as="map(*)"/>
        <xsl:param name="arg" as="xs:string*"/>
        <xsl:param name="node" as="node()"/>
        <xsl:sequence select="idref(xpe:atomize($arg), $node)"/>
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
        <xsl:variable name="atomized" select="xpe:atomize($uri)"/>
        <xsl:variable name="baseUri" select="xpf:static-base-uri($exec-context)"/>
        <xsl:choose>
            <xsl:when test="empty($exec-context?uri-resolver)">
                <xsl:sequence select="
                    xpe:default-uri-resolver($atomized, $baseUri)
                    "/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:sequence select="$exec-context?uri-resolver($atomized, $baseUri)"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>
    <xsl:function name="xpf:collection" as="node()*">
        <xsl:param name="exec-context" as="map(*)"/>
        <xsl:sequence select="xpf:collection($exec-context, '')"/>
    </xsl:function>
    <xsl:function name="xpf:collection" as="node()*">
        <xsl:param name="exec-context" as="map(*)"/>
        <xsl:param name="arg" as="item()?"/>

        <xsl:sequence select="
            xpf:uri-collection($exec-context, $arg) ! xpf:doc($exec-context, .)
            "/>
        
    </xsl:function>
    
    <xsl:function name="xpf:uri-collection" as="xs:anyURI*">
        <xsl:param name="exec-context" as="map(*)"/>
    </xsl:function>
    <xsl:function name="xpf:uri-collection" as="xs:anyURI*">
        <xsl:param name="exec-context" as="map(*)"/>
        <xsl:param name="arg" as="xs:string?"/>
        
        <xsl:variable name="atomized" select="xpe:atomize($arg)"/>
        <xsl:variable name="baseUri" select="xpf:static-base-uri($exec-context)"/>
        
        <xsl:choose>
            <xsl:when test="empty($exec-context?uri-collection-resolver)">
                <xsl:sequence select="
                    xpe:default-collection-resolver($atomized, $baseUri)
                    "/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:sequence select="$exec-context?uri-collection-resolver($atomized, $baseUri)"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>
    
    <xsl:function name="xpe:default-uri-resolver" as="document-node()?">
        <xsl:param name="relative" as="xs:string?"/>
        <xsl:param name="baseUri" as="xs:string"/>
        <xsl:variable name="resolved" as="xs:anyURI?">
            <xsl:try>
                <xsl:sequence select="resolve-uri($relative, $baseUri)"/>
                <xsl:catch errors="err:FORG0002">
                    <xsl:sequence select="error(xpe:error-code('FODC0005'), 'Malformed URI ' || $relative)"/>
                </xsl:catch>
            </xsl:try>
        </xsl:variable>
        <xsl:sequence select="doc($resolved)"/>
    </xsl:function>
    
    <xsl:function name="xpe:default-collection-resolver" as="xs:anyURI*">
        <xsl:param name="relative" as="xs:string"/>
        <xsl:param name="baseUri" as="xs:string"/>
        <xsl:variable name="resolved" as="xs:anyURI">
            <xsl:try>
                <xsl:sequence select="resolve-uri($relative, $baseUri)"/>
                <xsl:catch errors="err:FORG0002">
                    <xsl:sequence select="error(xpe:error-code('FODC0004'), 'Malformed URI ' || $relative)"/>
                </xsl:catch>
            </xsl:try>
        </xsl:variable>
        <xsl:sequence select="uri-collection($resolved)"/>
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
    <xsl:function name="xpf:base-uri" as="xs:anyURI?">
        <xsl:param name="exec-context" as="map(*)"/>
        <xsl:sequence select="base-uri($exec-context?context)"/>
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
            then xpe:apply-static-context($exec-context, function-lookup(xs:QName('xpf:' || $local-name), $arity + 1)) 
            else function-lookup($name, $arity)"/>
        <xsl:if test="empty($function)">
            <xsl:message expand-text="yes">Could not find funciton Q{{{$ns-uri}}}{$local-name}!</xsl:message>
        </xsl:if>
        <xsl:sequence select="
            $function
            "/>
    </xsl:function>
    <xsl:function name="xpe:apply-static-context" as="function(*)">
        <xsl:param name="exec-context" as="map(*)"/>
        <xsl:param name="function" as="function(*)"/>
        
        <xsl:variable name="arity" select="function-arity($function)"/>
        <xsl:choose>
            <xsl:when test="$arity = 0">
                <xsl:sequence select="$function"/>
            </xsl:when>
            <xsl:when test="$arity = 1">
                <xsl:sequence select="function(){$function($exec-context)}"/>
            </xsl:when>
            <xsl:when test="$arity = 2">
                <xsl:sequence select="$function($exec-context, ?)"/>
            </xsl:when>
            <xsl:when test="$arity = 3">
                <xsl:sequence select="$function($exec-context, ?, ?)"/>
            </xsl:when>
            <xsl:when test="$arity = 4">
                <xsl:sequence select="$function($exec-context, ?, ?, ?)"/>
            </xsl:when>
            <xsl:when test="$arity = 5">
                <xsl:sequence select="$function($exec-context, ?, ?, ?, ?)"/>
            </xsl:when>
            <xsl:when test="$arity = 6">
                <xsl:sequence select="$function($exec-context, ?, ?, ?, ?, ?)"/>
            </xsl:when>
            <xsl:when test="$arity = 7">
                <xsl:sequence select="$function($exec-context, ?, ?, ?, ?, ?, ?)"/>
            </xsl:when>
            <xsl:when test="$arity = 8">
                <xsl:sequence select="$function($exec-context, ?, ?, ?, ?, ?, ?, ?)"/>
            </xsl:when>
            <xsl:when test="$arity = 9">
                <xsl:sequence select="$function($exec-context, ?, ?, ?, ?, ?, ?, ?, ?)"/>
            </xsl:when>
            <xsl:when test="$arity = 10">
                <xsl:sequence select="$function($exec-context, ?, ?, ?, ?, ?, ?, ?, ?, ?)"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:variable name="param-xpath" select="(1 to $arity) ! ('?') => string-join(', ')"/>
                <xsl:variable name="xpath" select="'$f($ec,' || $param-xpath || ')'"/>
                <xsl:evaluate xpath="$xpath" with-params="
                    map{
                    QName('','f') : $function,
                    QName('','ec') : $exec-context
                    }
                    "/>
            </xsl:otherwise>
        </xsl:choose>
        
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