<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:math="http://www.w3.org/2005/xpath-functions/math"
    xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl"
    xmlns:xpf="http://www.nkutsche.com/xmlml/xpath-engine/functions"
    xmlns:xpfs="http://www.nkutsche.com/xmlml/xpath-engine/xsd-constructors"
    xmlns:xpfa="http://www.nkutsche.com/xmlml/xpath-engine/array"
    xmlns:xpfm="http://www.nkutsche.com/xmlml/xpath-engine/map"
    xmlns:xpe="http://www.nkutsche.com/xpath-model/engine"
    xmlns:mlml="http://www.nkutsche.com/xmlml"
    xmlns:xpm="http://www.nkutsche.com/xpath-model"
    xmlns:err="http://www.w3.org/2005/xqt-errors"
    xmlns:fn="http://www.w3.org/2005/xpath-functions"
    xmlns:fos="http://www.w3.org/xpath-functions/spec/namespace"
    xmlns:array="http://www.w3.org/2005/xpath-functions/array"
    xmlns:map="http://www.w3.org/2005/xpath-functions/map"
    xmlns:xpt="http://www.nkutsche.com/xmlml/xpath-engine/types"
    exclude-result-prefixes="xs math xd"
    version="3.0">
    <xsl:variable name="xpf:namespace-uri" select="'http://www.nkutsche.com/xmlml/xpath-engine/functions'"/>
    <xsl:variable name="xpfm:namespace-uri" select="'http://www.nkutsche.com/xmlml/xpath-engine/map'"/>
    <xsl:variable name="xpfa:namespace-uri" select="'http://www.nkutsche.com/xmlml/xpath-engine/array'"/>
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
    
    <xsl:function name="xpfs:QName">
        <xsl:param name="exec-context" as="map(*)"/>
        <xsl:param name="arg" as="item()?"/>
        
        <xsl:variable name="namespaces" select="($exec-context?namespaces, map{})[1]"/>
        
        <xsl:variable name="arg" select="xpe:atomize($arg)"/>
        <xsl:variable name="prefix" select=" 
            if (contains($arg, ':')) 
            then substring-before($arg, ':') 
            else '' "/>
        
        <xsl:variable name="namespace-uri" select="
            if ($prefix = '') 
            then '' 
            else if (map:contains($namespaces, $prefix)) 
            then $namespaces($prefix) 
            else error(xpe:error-code('FONS0004'), 'Undeclared prefix ' || $prefix || '.') 
            "/>
        
        
        <xsl:sequence select="
            QName($namespace-uri,  $arg)"/>
        
    </xsl:function>
    
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
        <xsl:param name="arg" as="item()*"/>
        <xsl:choose>
            <xsl:when test="xpe:is-function($arg)">
                <xsl:sequence select="error(xpe:error-code('err:FOTY0013'), 'An atomic value is required, but the supplied type is a function ' || $arg?name || '#' || $arg?arity || ', which cannot be atomized')"/>
            </xsl:when>
            <xsl:when test="$arg instance of map(*)*">
                <xsl:sequence select="error(xpe:error-code('err:FOTY0013'), 'An atomic value is required, but the supplied type is a map, which cannot be atomized')"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:sequence select="data($arg)"/>
            </xsl:otherwise>
        </xsl:choose>
        
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
        <xsl:sequence select="resolve-uri(xpf:data($exec-context, $relative), xpf:static-base-uri($exec-context))"/>
    </xsl:function>
    
    <xsl:function name="xpf:name" as="xs:string">
        <xsl:param name="exec-context" as="map(*)"/>
        <xsl:variable name="context" select="$exec-context?context"/>
        <xsl:sequence select="
            if (empty($context)) 
            then error(xpe:error-code('XPDY0002'), 'Context item is absent for function call name()') 
            else name($context)"/>
    </xsl:function>
    <xsl:function name="xpf:local-name" as="xs:string">
        <xsl:param name="exec-context" as="map(*)"/>
        <xsl:variable name="context" select="$exec-context?context"/>
        <xsl:sequence select="
            if (empty($context)) 
            then error(xpe:error-code('XPDY0002'), 'Context item is absent for function call local-name()') 
            else local-name($context)"/>
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
        <xsl:sequence select="lang($testlang, $exec-context?context)"/>
    </xsl:function>
    <xsl:function name="xpf:root" as="node()?">
        <xsl:param name="exec-context" as="map(*)"/>
        <xsl:variable name="context" select="$exec-context?context"/>
        <xsl:sequence select="
            if (empty($context)) 
            then error(xpe:error-code('XPDY0002'), 'Context item is absent for function call root()') 
            else root($context)"/>
    </xsl:function>
    <xsl:function name="xpf:path" as="xs:string?">
        <xsl:param name="exec-context" as="map(*)"/>
        <xsl:variable name="context" select="$exec-context?context"/>
        <xsl:sequence select="
            if (empty($context)) 
            then error(xpe:error-code('XPDY0002'), 'Context item is absent for function call path()') 
            else path($context)"/>
    </xsl:function>
    <xsl:function name="xpf:has-children" as="xs:boolean">
        <xsl:param name="exec-context" as="map(*)"/>
        <xsl:variable name="context" select="$exec-context?context"/>
        <xsl:sequence select="
            if (empty($context)) 
            then error(xpe:error-code('XPDY0002'), 'Context item is absent for function call has-children()') 
            else has-children($context)
            "/>
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
        <xsl:sequence select="index-of($seq ! xpf:data($exec-context, .), xpf:data($exec-context, $search), xpf:default-collation($exec-context))"/>
    </xsl:function>
    
    <xsl:function name="xpf:deep-equal" as="xs:boolean">
        <xsl:param name="exec-context" as="map(*)"/>
        <xsl:param name="parameter1" as="item()*"/>
        <xsl:param name="parameter2" as="item()*"/>
        <xsl:sequence select="deep-equal($parameter1, $parameter2, xpf:default-collation($exec-context))"/>
    </xsl:function>
    <xsl:function name="xpf:max" as="xs:anyAtomicType?">
        <xsl:param name="exec-context" as="map(*)"/>
        <xsl:param name="arg" as="item()*"/>
        <xsl:sequence select="max(xpf:data($exec-context, $arg), xpf:default-collation($exec-context))"/>
    </xsl:function>
    
    <xsl:function name="xpf:min" as="xs:anyAtomicType?">
        <xsl:param name="exec-context" as="map(*)"/>
        <xsl:param name="arg" as="item()*"/>
        <xsl:sequence select="min(xpf:data($exec-context, $arg), xpf:default-collation($exec-context))"/>
    </xsl:function>
    
    <xsl:function name="xpf:id" as="element()*">
        <xsl:param name="exec-context" as="map(*)"/>
        <xsl:param name="arg" as="xs:string*"/>
        <xsl:sequence select="id($arg, $exec-context?context)"/>
    </xsl:function>
    <xsl:function name="xpf:element-with-id" as="element()*">
        <xsl:param name="exec-context" as="map(*)"/>
        <xsl:param name="arg" as="xs:string*"/>
        <xsl:sequence select="element-with-id($arg, $exec-context?context)"/>
    </xsl:function>
    
    <xsl:function name="xpf:idref" as="node()*">
        <xsl:param name="exec-context" as="map(*)"/>
        <xsl:param name="arg" as="xs:string*"/>
        <xsl:sequence select="idref($arg, $exec-context?context)"/>
    </xsl:function>
    
    <xsl:function name="xpf:generate-id" as="xs:string">
        <xsl:param name="exec-context" as="map(*)"/>
        <xsl:sequence select="generate-id($exec-context?context)"/>
    </xsl:function>
    <xsl:function name="xpf:doc" as="document-node()?">
        <xsl:param name="exec-context" as="map(*)"/>
        <xsl:param name="uri" as="xs:string?"/>
        <xsl:variable name="atomized" select="xpe:atomize($uri)"/>
        <xsl:variable name="baseUri" select="xpf:static-base-uri($exec-context)"/>
        <xsl:try>
            <xsl:choose>
                <xsl:when test="empty($uri)"/>
                <xsl:when test="empty($exec-context?uri-resolver)">
                    <xsl:sequence select="
                        xpe:default-uri-resolver($exec-context, $atomized, $baseUri)
                        "/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:sequence select="$exec-context?uri-resolver($atomized, $baseUri)"/>
                </xsl:otherwise>
            </xsl:choose>
            <xsl:catch errors="err:FORG0002">
                <xsl:sequence select="error(xpe:error-code('FODC0005'), 'Malformed URI ' || $atomized)"/>
            </xsl:catch>
        </xsl:try>
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
        <xsl:sequence select="xpf:uri-collection($exec-context, '')"/>
    </xsl:function>
    <xsl:function name="xpf:uri-collection" as="xs:anyURI*">
        <xsl:param name="exec-context" as="map(*)"/>
        <xsl:param name="arg" as="xs:string?"/>
        
        <xsl:variable name="atomized" select="xpe:atomize($arg)"/>
        <xsl:variable name="baseUri" select="xpf:static-base-uri($exec-context)"/>
        <xsl:try>
            <xsl:choose>
                <xsl:when test="empty($exec-context?uri-collection-resolver)">
                    <xsl:sequence select="
                        xpe:default-collection-resolver($exec-context, $atomized, $baseUri)
                        "/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:sequence select="$exec-context?uri-collection-resolver($atomized, $baseUri)"/>
                </xsl:otherwise>
            </xsl:choose>
            <xsl:catch errors="err:FORG0002">
                <xsl:sequence select="error(xpe:error-code('FODC0004'), 'Malformed URI ' || $atomized)"/>
            </xsl:catch>
        </xsl:try>
    </xsl:function>
    
<!--    
    Unparsed text functions
    -->
    <xsl:function name="xpf:unparsed-text-lines" as="xs:string*">
        <xsl:param name="exec-context" as="map(*)"/>
        <xsl:param name="href" as="xs:string?"/>
        <xsl:sequence select="xpf:unparsed-text-lines($exec-context, $href, ())"/>
    </xsl:function>
    
    <xsl:function name="xpf:unparsed-text-lines" as="xs:string*">
        <xsl:param name="exec-context" as="map(*)"/>
        <xsl:param name="href" as="xs:string?"/>
        <xsl:param name="encoding" as="xs:string?"/>
        <xsl:variable name="unparsed-text" select="xpf:unparsed-text($exec-context, $href, $encoding)"/>
        <xsl:sequence select="tokenize($unparsed-text, '\r\n|\r|\n')[not(position()=last() and .='')]"/>
    </xsl:function>

    
    <xsl:function name="xpf:unparsed-text" as="xs:string?">
        <xsl:param name="exec-context" as="map(*)"/>
        <xsl:param name="href" as="xs:string?"/>
        <xsl:sequence select="xpf:unparsed-text($exec-context, $href, ())"/>
    </xsl:function>
    <xsl:function name="xpf:unparsed-text" as="xs:string?">
        <xsl:param name="exec-context" as="map(*)"/>
        <xsl:param name="href" as="xs:string?"/>
        <xsl:param name="encoding" as="xs:string?"/>
        
        <xsl:variable name="encoding" select="
            xpe:verify-encoding($encoding)
            "/>
        
        <xsl:variable name="baseUri" select="xpf:static-base-uri($exec-context)"/>
        
        <xsl:variable name="atomized" select="xpe:atomize($href)"/>
        
        <xsl:try>
            <xsl:choose>
                <xsl:when test="empty($exec-context?unparsed-text-resolver)">
                    <xsl:sequence select="
                        xpe:default-unparsed-text-resolver($exec-context, $atomized, $baseUri, $encoding)
                        "/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:sequence select="$exec-context?unparsed-text-resolver($atomized, $baseUri, $encoding)"/>
                </xsl:otherwise>
            </xsl:choose>
            <xsl:catch errors="err:FORG0002">
                <xsl:sequence select="error(xpe:error-code('FOUT1170'), 'Malformed URI ' || $atomized)"/>
            </xsl:catch>
        </xsl:try>
        
        
    </xsl:function>
    
    <xsl:function name="xpe:verify-encoding" as="xs:string?">
        <xsl:param name="encoding" as="xs:string?"/>
        <xsl:choose>
            <xsl:when test="empty($encoding)">
                <xsl:sequence select="$encoding"/>
            </xsl:when>
            <xsl:when test="matches($encoding, '^utf-(8|16)$', 'i')">
                <xsl:sequence select="$encoding"/>
            </xsl:when>
            <xsl:when test="matches($encoding, '^iso-8859-\d$', 'i')">
                <xsl:sequence select="$encoding"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:try>
                    <xsl:sequence select="
                        if (exists(unparsed-text('xpath-functions/dummy-for-encoding-verifyer.txt', $encoding))) 
                        then ($encoding) 
                        else error(xpe:error-code('FOUT1190'), 'Unsupported encoding ' || $encoding)
                        "/>
                    <xsl:catch>
                        <xsl:sequence select="
                            error(xpe:error-code('FOUT1190'), 'Unsupported encoding ' || $encoding)
                            "/>
                    </xsl:catch>
                </xsl:try>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>
    
    <xsl:function name="xpf:unparsed-text-available" as="xs:boolean">
        <xsl:param name="exec-context" as="map(*)"/>
        <xsl:param name="href" as="xs:string?"/>
        <xsl:sequence select="xpf:unparsed-text-available($exec-context, $href, ())"/>
    </xsl:function>
    
    <xsl:function name="xpf:unparsed-text-available" as="xs:boolean">
        <xsl:param name="exec-context" as="map(*)"/>
        <xsl:param name="href" as="xs:string?"/>
        <xsl:param name="encoding" as="xs:string?"/>
        <xsl:try>
            <xsl:sequence select="xpf:unparsed-text($exec-context, $href, $encoding) => exists()"/>
            <xsl:catch>
                <xsl:sequence select="false()"/>
            </xsl:catch>
        </xsl:try>
    </xsl:function>
    
    
    <xsl:function name="xpe:default-unparsed-text-resolver" as="xs:string?">
        <xsl:param name="exec-context" as="map(*)"/>
        <xsl:param name="relative" as="xs:string?"/>
        <xsl:param name="baseUri" as="xs:string"/>
        <xsl:param name="encoding" as="xs:string?"/>
        
        <xsl:variable name="resolved" as="xs:anyURI?" select="xpe:default-uri-mapper($exec-context, $relative, $baseUri)"/>
        
        <xsl:sequence select="
            if (empty($encoding)) 
            then unparsed-text($resolved) 
            else unparsed-text($resolved, $encoding)
            "/>
    </xsl:function>
    
    <xsl:function name="xpe:default-uri-resolver" as="document-node()?">
        <xsl:param name="exec-context" as="map(*)"/>
        <xsl:param name="relative" as="xs:string?"/>
        <xsl:param name="baseUri" as="xs:string"/>
        <xsl:variable name="resolved" as="xs:anyURI?">
            <xsl:sequence select="xpe:default-uri-mapper($exec-context, $relative, $baseUri)"/>
        </xsl:variable>
        <xsl:sequence select="doc($resolved)"/>
    </xsl:function>
    
    <xsl:function name="xpe:default-collection-resolver" as="xs:anyURI*">
        <xsl:param name="exec-context" as="map(*)"/>
        <xsl:param name="relative" as="xs:string"/>
        <xsl:param name="baseUri" as="xs:string"/>
        <xsl:variable name="resolved" as="xs:anyURI">
            <xsl:sequence select="xpe:default-uri-mapper($exec-context, $relative, $baseUri)"/>
        </xsl:variable>
        <xsl:sequence select="uri-collection($resolved)"/>
    </xsl:function>
    
    <xsl:function name="xpe:default-uri-mapper" as="xs:anyURI">
        <xsl:param name="exec-context" as="map(*)"/>
        <xsl:param name="relative" as="xs:string"/>
        <xsl:param name="base-uri" as="xs:string"/>
        <xsl:choose>
            <xsl:when test="empty($exec-context?uri-mapper)">
                <xsl:sequence select="resolve-uri($relative, $base-uri)"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:sequence select="$exec-context?uri-mapper($relative, $base-uri)"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>
    
    <xsl:function name="xpf:json-doc" as="item()?">
        <xsl:param name="exec-context" as="map(*)"/>
        <xsl:param name="href" as="xs:string?"/>
        <xsl:sequence select="xpf:json-doc($exec-context, $href, map{})"/>
    </xsl:function>
    
    <xsl:function name="xpf:json-doc" as="item()?">
        <xsl:param name="exec-context" as="map(*)"/>
        <xsl:param name="href" as="xs:string?"/>
        <xsl:param name="options" as="map(*)"/>
        <xsl:sequence select="xpf:parse-json($exec-context, xpf:unparsed-text($exec-context, $href), $options)"/>
    </xsl:function>
    
    <xsl:function name="xpf:parse-json" as="item()?">
        <xsl:param name="exec-context" as="map(*)"/>
        <xsl:param name="json-text" as="xs:string?"/>
        <xsl:param name="options" as="map(*)"/>
        <xsl:variable name="fallback" select="$options?fallback ! xpe:raw-function(.)"/>
        <xsl:variable name="options" select="
            if (exists($fallback)) 
            then map:put($options, 'fallback', $fallback) 
            else $options
            "/>
        <xsl:sequence select="parse-json($json-text, $options)"/>
    </xsl:function>
    
    <xsl:function name="xpf:transform" as="map(*)">
        <xsl:param name="exec-context" as="map(*)"/>
        <xsl:param name="options" as="map(*)"/>
        
        <!--        
            $options?post-process is a function
        -->
        <xsl:variable name="options" select="
            if (exists($options?post-process)) 
            then map:put($options, 'post-process', xpe:raw-function($options?post-process)) 
            else $options
            "/>

        <!--        
            Replace $options?stylesheet-location by $options?stylesheet-node and use URI resolver
        -->
        <xsl:variable name="stylesheet-location" select="$options?stylesheet-location"/>
        <xsl:variable name="replace-style-loc" select="exists($stylesheet-location)"/>
        <xsl:variable name="options" select="
            if ($replace-style-loc) 
            then 
                xpf:doc($exec-context, $options?stylesheet-location) 
                ! map:put($options, 'stylesheet-node', .)
                => map:remove('stylesheet-location')
            else $options
            "/>
        <!--
            In case of stylesheet location replacement, set the static-base-uri 
        -->
        <xsl:variable name="options" select="
            if ($replace-style-loc and empty($options?stylesheet-base-uri)) 
            then map:put($options, 'stylesheet-base-uri', $stylesheet-location) 
            else $options
            "/>

        <!--        
            Replace $options?package-location by $options?package-node and use URI resolver
        -->
        <xsl:variable name="options" select="
            if (exists($options?package-location)) 
            then 
                map:put($options, 'package-node', xpf:doc($exec-context, $options?package-location))
                => map:remove('package-location')
            else $options
            "/>
        <xsl:sequence select="transform($options)"/>
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
    
    <xsl:function name="xpf:load-xquery-module" as="map(*)">
        <xsl:param name="exec-context" as="map(*)"/>
        <!-- 
            TODO: original type of $uri is xs:string  
            Workaround for https://github.com/w3c/qt3tests/issues/58
        -->
        <xsl:param name="uri" as="item()"/>
        <xsl:sequence select="error(xpe:error-code('FOQM0006'), 'XQuery module is not available in this XPath engine.')"/>
    </xsl:function>
    <xsl:function name="xpf:load-xquery-module" as="map(*)">
        <xsl:param name="exec-context" as="map(*)"/>
        <!-- 
            TODO: original type of $uri is xs:string  
            Workaround for https://github.com/w3c/qt3tests/issues/58
        -->
        <xsl:param name="uri" as="item()"/>
        <xsl:param name="options" as="map(*)"/>
        <xsl:sequence select="error(xpe:error-code('FOQM0006'), 'XQuery module is not available in this XPath engine.')"/>
    </xsl:function>
    
    <xsl:variable name="unsupported-functions" select="
        map{
            (:
            Add a here a name of an unsupported function and asign a function which 
            throws an error with a corresponding error message, e.g.:
            xs:QName('fn:load-xquery-module') : function(){error(QName('', 'code'), '')}
            :)
        }
        " as="map(xs:QName, function(xs:string) as empty-sequence())"/>
    
    <xsl:key name="functSign-qname" match="fos:function" use="
        QName(
            $build-in-namespaces(@prefix),
            @name
        )
        "/>
    
    <!--<xsl:function name="xpe:log">
        <xsl:param name="msg" as="xs:string"/>
        <xsl:message expand-text="yes">{$msg}</xsl:message>
    </xsl:function>-->
    
    <xsl:function name="xpf:function-lookup" as="map(*)?">
        <xsl:param name="exec-context" as="map(*)"/>
        <xsl:param name="name" as="xs:QName"/>
        <xsl:param name="arity" as="xs:integer"/>
        
        <xsl:variable name="local-name" select="local-name-from-QName($name)"/>
        <xsl:variable name="ns-uri" select="namespace-uri-from-QName($name)"/>
        
        <xsl:variable name="xsd-constructor" select="$ns-uri = $xs_namespace-uri"/>
        <xsl:variable name="function" select="
            (:if (exists($unsupported-functions($name))) 
            then ($unsupported-functions($name)()) 
            else :)
            if ($ns-uri = $fn_namespace-uri and function-available('xpf:' || $local-name, $arity + 1)) 
            then function-lookup(xs:QName('xpf:' || $local-name), $arity + 1) 
            else if ($ns-uri = $array_namespace-uri and function-available('xpfa:' || $local-name, $arity + 1)) 
            then function-lookup(xs:QName('xpfa:' || $local-name), $arity + 1) 
            else if ($ns-uri = $map_namespace-uri and function-available('xpfm:' || $local-name, $arity + 1)) 
            then function-lookup(xs:QName('xpfm:' || $local-name), $arity + 1) 
            else if ($xsd-constructor and function-available('xpfs:' || $local-name, $arity + 1)) 
            then function-lookup(xs:QName('xpfs:' || $local-name), $arity + 1) 
            else function-lookup($name, $arity)"/>
        
        
        <xsl:choose>
            <xsl:when test="empty($function)">
<!--                <xsl:message expand-text="yes">Could not find funciton Q{{{$ns-uri}}}{$local-name}!</xsl:message>-->
            </xsl:when>
            <xsl:otherwise>
                <xsl:variable name="apply-static-context" select="
                    namespace-uri-from-QName(function-name($function)) = ($xpf:namespace-uri, $xpfs:namespace-uri)
                    "/>
                
                <xsl:variable name="funct-sign" select="
                    ((function-name($function), $name) ! key('functSign-qname', ., $function-signatures))[1]"/>
                <xsl:variable name="funct-sign" select="$funct-sign/fos:signatures/fos:proto[count(fos:arg) = $arity]"/>
                
                <xsl:variable name="underline-funct-body" select="
                    function($args){
                        let $args := xpe:prepare-arguments($args, $funct-sign, $name)
                        return
                        let $args2 := if ($apply-static-context) then array:join(([$exec-context],$args)) else $args
                        return
                        (
                        apply($function, $args2)
                        )
                    }
                    "/>
                <xsl:sequence select="
                    map{
                        'type' : QName($xpf:namespace-uri, 'function'),
                        'function' : xpe:create-function($underline-funct-body, $arity),
                        'name' : $name,
                        'arity' : $arity
                    }
                    "/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>
    
    <xsl:key name="fosTypeModel-typeName" match="fos:type-model" use="@name"/>
    
    
    
    <xsl:function name="xpe:prepare-arguments" as="array(*)">
        <xsl:param name="arguments" as="array(*)"/>
        <xsl:param name="funct-sign" as="element(fos:proto)?"/>
        <xsl:param name="origin-funct-name" as="xs:QName"/>
        <xsl:variable name="single-args" as="array(*)*">
            <xsl:for-each select="1 to array:size($arguments)">
                <xsl:variable name="i" select="."/>
                <xsl:variable name="argDef" select="($funct-sign/fos:arg[$i], $funct-sign/fos:arg[@name = '...'])[1]"/>
                <xsl:variable name="typeDef" select="$argDef/key('fosTypeModel-typeName', @type)/itemType"/>
                <xsl:try>
                    <xsl:sequence select="[xpe:prepare-argument($arguments($i), $typeDef)]"/>
                    <xsl:catch>
                        <xsl:variable name="arg-no" select="
                            if ($i le 3) 
                            then ('first', 'second', 'third')[$i] 
                            else ($i || 'th')
                            "/>
                        <xsl:variable name="message-pre" select="'Bad value as ' || $arg-no || ' argument of ' || $origin-funct-name || '(): '"/>
                        <xsl:sequence select="error($err:code, $message-pre || $err:description)"/>
                    </xsl:catch>
                </xsl:try>
            </xsl:for-each>
        </xsl:variable>
        <xsl:sequence select="$single-args => array:join()"/>
    </xsl:function>
    
    <xsl:function name="xpe:prepare-argument" as="item()*">
        <xsl:param name="arg" as="item()*"/>
        <xsl:param name="typeDef" as="element(itemType)?"/>
        <xsl:variable name="occurrence" select="$typeDef/@occurrence"/>
        <xsl:choose>
            <xsl:when test="not($typeDef)">
                <xsl:sequence select="$arg"/>
            </xsl:when>
            <xsl:when test="$occurrence = 'zero-or-more'">
                <xsl:variable name="single-type" as="element()">
                    <xsl:copy select="$typeDef">
                        <xsl:sequence select="@* except @occurrence"/>
                        <xsl:sequence select="node()"/>
                    </xsl:copy>
                </xsl:variable>
                <xsl:sequence select="$arg ! xpe:prepare-argument(., $single-type)"/>
            </xsl:when>
            <xsl:when test="$occurrence = 'zero-or-one' and empty($arg)">
                <xsl:sequence select="()"/>
            </xsl:when>
            <xsl:when test="count($arg) = 0">
                <xsl:variable name="type-serialized" select="
                    $typeDef 
                    => xpm:xpath-serializer-sub(map{'namespaces' : $build-in-namespaces}) 
                    => normalize-space()
                    "/>
                <xsl:sequence select="
                    error(
                        xpe:error-code('XPTY0004'), 
                        'An empty sequence occurred where type ' || $type-serialized || ' was expected.'
                    )
                    "/>
            </xsl:when>
            <xsl:when test="count($arg) gt 1">
                <xsl:variable name="type-serialized" select="
                    $typeDef 
                    => xpm:xpath-serializer-sub(map{'namespaces' : $build-in-namespaces}) 
                    => normalize-space()
                    "/>
                <xsl:sequence select="
                    error(
                        xpe:error-code('XPTY0004'), 
                        'More than one item occurred where type ' || $type-serialized || ' was expected.'
                    )
                    "/>
            </xsl:when>
            <!-- for type item() -->
            <xsl:when test="not($typeDef/*)">
                <xsl:sequence select="$arg"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:variable name="single-type" select="$typeDef/*"/>
                <xsl:apply-templates select="$single-type" mode="xpe:prepare-argument">
                    <xsl:with-param name="arg" select="$arg" tunnel="yes"/>
                </xsl:apply-templates>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>
    
    <xsl:template match="atomic" mode="xpe:prepare-argument">
        <xsl:param name="arg" tunnel="yes" as="item()"/>
        <xsl:sequence select="xpf:data(map{}, $arg)"/>
    </xsl:template>
    
    <xsl:template match="nodeTest" mode="xpe:prepare-argument">
        <xsl:param name="arg" tunnel="yes" as="item()"/>
        <xsl:sequence select="$arg"/>
    </xsl:template>

    <xsl:template match="arrayType" mode="xpe:prepare-argument">
        <xsl:param name="arg" tunnel="yes" as="item()"/>
        <xsl:sequence select="$arg"/>
    </xsl:template>

    <xsl:template match="mapType" mode="xpe:prepare-argument">
        <xsl:param name="arg" tunnel="yes" as="item()"/>
        <xsl:sequence select="$arg"/>
    </xsl:template>
    
    <xsl:template match="functType[count(* except as) le 1]" mode="xpe:prepare-argument">
        <xsl:param name="arg" tunnel="yes" as="item()"/>
        <xsl:choose>
            <xsl:when test="xpe:is-function($arg)">
                <xsl:sequence select="xpe:raw-function($arg)"/>
            </xsl:when>
            <xsl:when test="$arg instance of map(*)">
                <xsl:sequence select="$arg"/>
            </xsl:when>
            <xsl:when test="$arg instance of array(*)">
                <xsl:sequence select="$arg"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:next-match/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template match="functType" mode="xpe:prepare-argument">
        <xsl:param name="arg" tunnel="yes" as="item()"/>
        <xsl:sequence select="
            if (xpe:is-function($arg)) 
            then 
                xpe:raw-function($arg)
            else if ($arg instance of function(*)) 
            then $arg 
            else 
                error(
                    xpe:error-code('XPTY0004'),
                    'Can not convert ' || $arg || ' to a function from type ' || normalize-space(xpm:xpath-serializer-sub(parent::*))
                ) 
            "/>
    </xsl:template>
    
    <xsl:function name="xpe:create-function">
        <xsl:param name="function-body" as="function(array(*)) as item()*"/>
        <xsl:param name="arity" as="xs:integer"/>
        
        <xsl:choose>
            <xsl:when test="$arity = 0">
                <xsl:sequence select="function(){$function-body([])}"/>
            </xsl:when>
            <xsl:when test="$arity = 1">
                <xsl:sequence select="function($p1){$function-body([$p1])}"/>
            </xsl:when>
            <xsl:when test="$arity = 2">
                <xsl:sequence select="function($p1, $p2){$function-body([$p1, $p2])}"/>
            </xsl:when>
            <xsl:when test="$arity = 3">
                <xsl:sequence select="function($p1, $p2, $p3){$function-body([$p1, $p2, $p3])}"/>
            </xsl:when>
            <xsl:when test="$arity = 4">
                <xsl:sequence select="function($p1, $p2, $p3, $p4){$function-body([$p1, $p2, $p3, $p4])}"/>
            </xsl:when>
            <xsl:when test="$arity = 5">
                <xsl:sequence select="function($p1, $p2, $p3, $p4, $p5){$function-body([$p1, $p2, $p3, $p4, $p5])}"/>
            </xsl:when>
            <xsl:when test="$arity = 6">
                <xsl:sequence select="function($p1, $p2, $p3, $p4, $p5, $p6){$function-body([$p1, $p2, $p3, $p4, $p5, $p6])}"/>
            </xsl:when>
            <xsl:when test="$arity = 7">
                <xsl:sequence select="function($p1, $p2, $p3, $p4, $p5, $p6, $p7){$function-body([$p1, $p2, $p3, $p4, $p5, $p6, $p7])}"/>
            </xsl:when>
            <xsl:when test="$arity = 8">
                <xsl:sequence select="function($p1, $p2, $p3, $p4, $p5, $p6, $p7, $p8){$function-body([$p1, $p2, $p3, $p4, $p5, $p6, $p7, $p8])}"/>
            </xsl:when>
            <xsl:when test="$arity = 9">
                <xsl:sequence select="function($p1, $p2, $p3, $p4, $p5, $p6, $p7, $p8, $p9){$function-body([$p1, $p2, $p3, $p4, $p5, $p6, $p7, $p8, $p9])}"/>
            </xsl:when>
            <xsl:when test="$arity = 10">
                <xsl:sequence select="function($p1, $p2, $p3, $p4, $p5, $p6, $p7, $p8, $p9, $p10){$function-body([$p1, $p2, $p3, $p4, $p5, $p6, $p7, $p8, $p9, $p10])}"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:variable name="param-defs" select="((1 to $arity) ! ('$p' || .)) => string-join(', ')"/>
                <xsl:variable name="xpath" select="'function(' || $param-defs || '){$function-body([' || $param-defs || '])}'"/>
                <xsl:evaluate xpath="$xpath" with-params="map{QName('', 'function-body') : $function-body}"/>
            </xsl:otherwise>
        </xsl:choose>
        
    </xsl:function>
    
    <xsl:function name="xpf:function-name" as="xs:QName?">
        <xsl:param name="exec-context" as="map(*)"/>
        <xsl:param name="func" as="map(*)"/>
        <xsl:sequence select="$func?name"/>
    </xsl:function>
    
    
    
    <xsl:function name="xpe:is-function" as="xs:boolean">
        <xsl:param name="item" as="item()*"/>
        <xsl:sequence select="
            if ($item instance of map(*)) 
            then ($item?type = QName($xpf:namespace-uri, 'function')) 
            else false()
            "/>
    </xsl:function>
    
    <xsl:function name="xpe:raw-function" as="item()">
        <xsl:param name="item" as="item()"/>
        <xsl:sequence select="
            if (xpe:is-function($item)) 
            then $item?function 
            else $item
            "/>
        
    </xsl:function>
    

    
</xsl:stylesheet>