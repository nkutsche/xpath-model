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
    exclude-result-prefixes="math xd"
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
    
    <xsl:function name="xpfs:error" as="xs:error?">
        <xsl:param name="exec-context" as="map(*)"/>
        <xsl:param name="arg" as="item()?"/>
        <xsl:sequence select="
            if (empty($arg)) 
            then () 
            else error(xpe:error-code('FORG0001'), 
                    'Can not cast any value except of an empty sequence to xs:error')
            "/>
    </xsl:function>
    <xsl:function name="xpfs:QName" as="xs:QName">
        <xsl:param name="exec-context" as="map(*)"/>
        <xsl:param name="arg" as="item()?"/>
        
        <xsl:variable name="namespaces" select="($exec-context?namespaces, map{})[1]"/>
        
        <xsl:variable name="arg" select="xpe:data($exec-context, $arg)"/>
        
        <xsl:variable name="arg" select="normalize-space($arg)"/>
        
        <xsl:variable name="prefix" select=" 
            if (contains($arg, ':')) 
            then substring-before($arg, ':') 
            else '' "/>
        
        <xsl:variable name="namespace-uri" select="
            if (map:contains($namespaces, $prefix)) 
            then $namespaces($prefix) 
            else if ($prefix = '') 
            then '' 
            else error(xpe:error-code('FONS0004'), 'Undeclared prefix ' || $prefix || '.') 
            "/>
        <xsl:try>
            <xsl:sequence select="
                QName($namespace-uri,  $arg)"/>
            <xsl:catch errors="err:FOCA0002">
                <xsl:sequence select="error(xpe:error-code('FORG0001'), $err:description, $err:value)"/>
            </xsl:catch>
        </xsl:try>
        
    </xsl:function>
    
    <xsl:function name="xpf:number" as="xs:double">
        <xsl:param name="exec-context" as="map(*)"/>
        <xsl:variable name="context" select="$exec-context?context"/>
        <xsl:sequence select="
            if (empty($context)) 
            then error(xpe:error-code('XPDY0002'), 'Context item is absent for function call number()') 
            else xpe:fn-apply($exec-context, 'number', [$context])
            "/>
    </xsl:function>
    
    <xsl:function name="xpf:compare" as="xs:integer?">
        <xsl:param name="exec-context" as="map(*)"/>
        <xsl:param name="comparand1" as="item()?"/>
        <xsl:param name="comparand2" as="item()?"/>
        <xsl:sequence select="compare(xpe:data($exec-context, $comparand1), xpe:data($exec-context, $comparand2), xpe:default-collation($exec-context))"/>
    </xsl:function>

    <xsl:function name="xpf:string" as="xs:string">
        <xsl:param name="exec-context" as="map(*)"/>
        <xsl:variable name="context" select="$exec-context?context"/>
        <xsl:sequence select="
            if (empty($context)) 
            then error(xpe:error-code('XPDY0002'), 'Context item is absent for function call string()') 
            else xpe:fn-apply($exec-context, 'string', [$context])
            "/>
    </xsl:function>

    <xsl:function name="xpf:string" as="xs:string">
        <xsl:param name="exec-context" as="map(*)"/>
        <xsl:param name="arg" as="item()?"/>
        <xsl:variable name="stringType" as="element(itemType)">
            <itemType>
                <atomic name="xs:string"/>
            </itemType>
        </xsl:variable>
        <xsl:sequence select="
            if (empty($arg)) 
            then '' 
            else if ($arg instance of node()) 
            then string($arg) 
            else if ($arg instance of xs:anyAtomicType) 
            then (xpt:cast-as($arg, $stringType)) 
            else if ($arg instance of array(*)) 
            then error(xpe:error-code('FOTY0014'), 'An array has not string value') 
            else if ($arg instance of map(*)) 
            then error(xpe:error-code('FOTY0014'), 'A map has not string value') 
            else if ($arg instance of function(*)) 
            then error(xpe:error-code('FOTY0014'), 'A function item has not string value') 
            else error(xs:QName('xpe:internal-error'), 'This should never happen.')
            "/>
    </xsl:function>

    <xsl:function name="xpf:node-name" as="xs:QName">
        <xsl:param name="exec-context" as="map(*)"/>
        <xsl:variable name="context" select="$exec-context?context"/>
        <xsl:sequence select="
            if (empty($context)) 
            then error(xpe:error-code('XPDY0002'), 'Context item is absent for function call node-name()') 
            else xpe:fn-apply($exec-context, 'node-name', [$context])
            "/>
    </xsl:function>

    <xsl:function name="xpf:nilled" as="xs:boolean?">
        <xsl:param name="exec-context" as="map(*)"/>
        <xsl:variable name="context" select="$exec-context?context"/>
        <xsl:sequence select="
            if (empty($context)) 
            then error(xpe:error-code('XPDY0002'), 'Context item is absent for function call nilled()') 
            else xpe:fn-apply($exec-context, 'nilled', [$context])
            "/>
    </xsl:function>

    <xsl:function name="xpf:data" as="item()*">
        <xsl:param name="exec-context" as="map(*)"/>
        <xsl:variable name="context" select="$exec-context?context"/>
        <xsl:sequence select="
            if (empty($context)) 
            then error(xpe:error-code('XPDY0002'), 'Context item is absent for function call data()') 
            else xpe:data($exec-context, $context)
            "/>
    </xsl:function>

    <xsl:function name="xpf:data" as="item()*">
        <xsl:param name="exec-context" as="map(*)"/>
        <xsl:param name="arg" as="item()*"/>
        <xsl:choose>
            <xsl:when test="xpe:is-function($arg)">
                <xsl:sequence select="error(xpe:error-code('err:FOTY0013'), 'An atomic value is required, but the supplied type is a function ' || $arg?name || '#' || $arg?arity || ', which cannot be atomized')"/>
            </xsl:when>
            <xsl:when test="$arg instance of map(*)+">
                <xsl:sequence select="error(xpe:error-code('err:FOTY0013'), 'An atomic value is required, but the supplied type is a map, which cannot be atomized')"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:sequence select="data($arg)"/>
            </xsl:otherwise>
        </xsl:choose>
        
    </xsl:function>
    
    <xsl:function name="xpe:data" as="item()*">
        <xsl:param name="exec-context" as="map(*)"/>
        <xsl:param name="arg" as="item()*"/>
        <xsl:sequence select="xpe:fn-apply($exec-context, 'data', [$arg])"/>
    </xsl:function>

    <xsl:function name="xpf:document-uri" as="xs:anyURI?">
        <xsl:param name="exec-context" as="map(*)"/>
        <xsl:variable name="context" select="$exec-context?context"/>
        <xsl:sequence select="
            if (empty($context)) 
            then error(xpe:error-code('XPDY0002'), 'Context item is absent for function call document-uri()') 
            else xpe:fn-apply($exec-context, 'document-uri', [$context])
            "/>
    </xsl:function>

    <xsl:function name="xpf:string-length" as="xs:integer">
        <xsl:param name="exec-context" as="map(*)"/>
        <xsl:variable name="context" select="$exec-context?context"/>
        <xsl:sequence select="
            if (empty($context)) 
            then error(xpe:error-code('XPDY0002'), 'Context item is absent for function call string-length()') 
            else xpe:fn-apply($exec-context, 'string-length', [$context])
            "/>
    </xsl:function>
    
    <xsl:function name="xpf:normalize-space" as="xs:string">
        <xsl:param name="exec-context" as="map(*)"/>
        <xsl:variable name="context" select="$exec-context?context"/>
        <xsl:sequence select="
            if (empty($context)) 
            then error(xpe:error-code('XPDY0002'), 'Context item is absent for function call normalize-space()') 
            else xpe:fn-apply($exec-context, 'normalize-space', [$context])
            "/>
    </xsl:function>

    <xsl:function name="xpf:contains" as="xs:boolean">
        <xsl:param name="exec-context" as="map(*)"/>
        <xsl:param name="arg1" as="item()?"/>
        <xsl:param name="arg2" as="item()?"/>
        <xsl:variable name="arg1" select="xpe:data($exec-context, $arg1)"/>
        <xsl:variable name="arg2" select="xpe:data($exec-context, $arg2)"/>
        <xsl:sequence select="contains($arg1, $arg2, xpf:default-collation($exec-context))"/>
    </xsl:function>

    <xsl:function name="xpf:starts-with" as="xs:boolean">
        <xsl:param name="exec-context" as="map(*)"/>
        <xsl:param name="arg1" as="item()?"/>
        <xsl:param name="arg2" as="item()?"/>
        <xsl:variable name="arg1" select="xpe:data($exec-context, $arg1)"/>
        <xsl:variable name="arg2" select="xpe:data($exec-context, $arg2)"/>
        <xsl:sequence select="starts-with($arg1, $arg2, xpe:default-collation($exec-context))"/>
    </xsl:function>
    
    <xsl:function name="xpf:ends-with" as="xs:boolean">
        <xsl:param name="exec-context" as="map(*)"/>
        <xsl:param name="arg1" as="item()?"/>
        <xsl:param name="arg2" as="item()?"/>
        <xsl:variable name="arg1" select="xpe:data($exec-context, $arg1)"/>
        <xsl:variable name="arg2" select="xpe:data($exec-context, $arg2)"/>
        <xsl:sequence select="ends-with($arg1, $arg2, xpe:default-collation($exec-context))"/>
    </xsl:function>
    
    <xsl:function name="xpf:substring-before" as="xs:string">
        <xsl:param name="exec-context" as="map(*)"/>
        <xsl:param name="arg1" as="xs:string?"/>
        <xsl:param name="arg2" as="xs:string?"/>
        <xsl:sequence select="xpf:substring-before($exec-context, $arg1, $arg2, xpe:default-collation($exec-context))"/>
    </xsl:function>
    
    <xsl:function name="xpf:substring-before" as="xs:string">
        <xsl:param name="exec-context" as="map(*)"/>
        <xsl:param name="arg1" as="xs:string?"/>
        <xsl:param name="arg2" as="xs:string?"/>
        <xsl:param name="collation" as="xs:string"/>
        <xsl:variable name="collation" select="resolve-uri($collation, xpe:static-base-uri($exec-context))"/>
        <xsl:sequence select="substring-before($arg1, $arg2, $collation)"/>
    </xsl:function>
    
    <xsl:function name="xpf:substring-after" as="xs:string">
        <xsl:param name="exec-context" as="map(*)"/>
        <xsl:param name="arg1" as="xs:string?"/>
        <xsl:param name="arg2" as="xs:string?"/>
        <xsl:sequence select="xpf:substring-after($exec-context, $arg1, $arg2, xpe:default-collation($exec-context))"/>
    </xsl:function>
    
    <xsl:function name="xpf:substring-after" as="xs:string">
        <xsl:param name="exec-context" as="map(*)"/>
        <xsl:param name="arg1" as="xs:string?"/>
        <xsl:param name="arg2" as="xs:string?"/>
        <xsl:param name="collation" as="xs:string"/>
        <xsl:variable name="collation" select="resolve-uri($collation, xpe:static-base-uri($exec-context))"/>
        <xsl:sequence select="substring-after($arg1, $arg2, $collation)"/>
    </xsl:function>

    <xsl:function name="xpf:subsequence" as="item()*">
        <xsl:param name="exec-context" as="map(*)"/>
        <xsl:param name="sourceSeq" as="item()*"/>
        <xsl:param name="startingLoc" as="xs:double"/>
        <xsl:param name="length" as="xs:double"/>
        <xsl:variable name="input-length" select="count($sourceSeq)"/>
        <xsl:variable name="length" select="
            if ($input-length lt $startingLoc + $length -1) 
            then ($input-length - $startingLoc + 1) 
            else ($length)
            "/>
        <xsl:sequence select="subsequence($sourceSeq, $startingLoc, $length)"/>
    </xsl:function>
    
    <xsl:function name="xpf:resolve-uri" as="xs:anyURI?">
        <xsl:param name="exec-context" as="map(*)"/>
        <xsl:param name="relative" as="item()?"/>
        <xsl:sequence select="resolve-uri(xpe:data($exec-context, $relative), xpe:static-base-uri($exec-context))"/>
    </xsl:function>
    
    <xsl:function name="xpf:name" as="xs:string">
        <xsl:param name="exec-context" as="map(*)"/>
        <xsl:variable name="context" select="$exec-context?context"/>
        <xsl:sequence select="
            if (empty($context)) 
            then error(xpe:error-code('XPDY0002'), 'Context item is absent for function call name()') 
            else xpe:fn-apply($exec-context, 'name', [$context])"/>
    </xsl:function>
    <xsl:function name="xpf:local-name" as="xs:string">
        <xsl:param name="exec-context" as="map(*)"/>
        <xsl:variable name="context" select="$exec-context?context"/>
        <xsl:sequence select="
            if (empty($context)) 
            then error(xpe:error-code('XPDY0002'), 'Context item is absent for function call local-name()') 
            else xpe:fn-apply($exec-context, 'local-name', [$context])"/>
    </xsl:function>
    <xsl:function name="xpf:namespace-uri" as="xs:anyURI">
        <xsl:param name="exec-context" as="map(*)"/>
        <xsl:variable name="context" select="$exec-context?context"/>
        <xsl:sequence select="
            if (empty($context)) 
            then error(xpe:error-code('XPDY0002'), 'Context item is absent for function call namespace-uri()') 
            else xpe:fn-apply($exec-context, 'namespace-uri', [$context]) 
            "/>
    </xsl:function>
    <xsl:function name="xpf:namespace-uri" as="xs:anyURI">
        <xsl:param name="exec-context" as="map(*)"/>
        <xsl:param name="arg" as="node()?"/>
        <xsl:sequence select="namespace-uri($arg)"/>
    </xsl:function>
    
    <xsl:function name="xpe:default-language" as="xs:language">
        <xsl:param name="exec-context" as="map(*)"/>
        <xsl:sequence select="xpe:fn-apply($exec-context, 'default-language', [])"/>
    </xsl:function>
    <xsl:function name="xpf:default-language" as="xs:language">
        <xsl:param name="exec-context" as="map(*)"/>
        <xsl:sequence select="($exec-context?default-language ! xs:language(.), default-language())[1]"/>
    </xsl:function>
    <xsl:function name="xpf:format-date" as="xs:string?">
        <xsl:param name="exec-context" as="map(*)"/>
        <xsl:param name="value" as="xs:date?"/>
        <xsl:param name="picture" as="xs:string"/>
        <xsl:sequence select="
            xpe:fn-apply($exec-context, 'format-date', [$value, $picture, (), (), ()]) 
            "/>
    </xsl:function>
    <xsl:function name="xpf:format-date" as="xs:string?">
        <xsl:param name="exec-context" as="map(*)"/>
        <xsl:param name="value" as="xs:date?"/>
        <xsl:param name="picture" as="xs:string"/>
        <xsl:param name="language" as="xs:string?"/>
        <xsl:param name="calendar" as="xs:string?"/>
        <xsl:param name="place" as="xs:string?"/>
        <xsl:variable name="language" select="
            if (empty($language)) then xpe:default-language($exec-context) else $language
            "/>
        <xsl:variable name="calendar" select="
            if (empty($calendar)) then $exec-context?default-calendar else $calendar
            "/>
        <xsl:variable name="place" select="
            if (empty($place)) then $exec-context?default-place else $place
            "/>
        <xsl:sequence select="format-date($value, $picture, $language, $calendar, $place)"/>
    </xsl:function>

    <xsl:function name="xpf:format-dateTime" as="xs:string?">
        <xsl:param name="exec-context" as="map(*)"/>
        <xsl:param name="value" as="xs:dateTime?"/>
        <xsl:param name="picture" as="xs:string"/>
        <xsl:sequence select="
            xpe:fn-apply($exec-context, 'format-dateTime', [$value, $picture, (), (), ()]) 
            "/>
    </xsl:function>
    <xsl:function name="xpf:format-dateTime" as="xs:string?">
        <xsl:param name="exec-context" as="map(*)"/>
        <xsl:param name="value" as="xs:dateTime?"/>
        <xsl:param name="picture" as="xs:string"/>
        <xsl:param name="language" as="xs:string?"/>
        <xsl:param name="calendar" as="xs:string?"/>
        <xsl:param name="place" as="xs:string?"/>
        <xsl:variable name="language" select="
            if (empty($language)) then xpe:default-language($exec-context) else $language
            "/>
        <xsl:variable name="calendar" select="
            if (empty($calendar)) then $exec-context?default-calendar else $calendar
            "/>
        <xsl:variable name="place" select="
            if (empty($place)) then $exec-context?default-place else $place
            "/>
        <xsl:sequence select="format-dateTime($value, $picture, $language, $calendar, $place)"/>
    </xsl:function>

    <xsl:function name="xpf:format-time" as="xs:string?">
        <xsl:param name="exec-context" as="map(*)"/>
        <xsl:param name="value" as="xs:time?"/>
        <xsl:param name="picture" as="xs:string"/>
        <xsl:sequence select="
            xpe:fn-apply($exec-context, 'format-time', [$value, $picture, (), (), ()]) 
            "/>
    </xsl:function>
    <xsl:function name="xpf:format-time" as="xs:string?">
        <xsl:param name="exec-context" as="map(*)"/>
        <xsl:param name="value" as="xs:time?"/>
        <xsl:param name="picture" as="xs:string"/>
        <xsl:param name="language" as="xs:string?"/>
        <xsl:param name="calendar" as="xs:string?"/>
        <xsl:param name="place" as="xs:string?"/>
        <xsl:variable name="language" select="
            if (empty($language)) then xpe:default-language($exec-context) else $language
            "/>
        <xsl:variable name="calendar" select="
            if (empty($calendar)) then $exec-context?default-calendar else $calendar
            "/>
        <xsl:variable name="place" select="
            if (empty($place)) then $exec-context?default-place else $place
            "/>
        <xsl:sequence select="format-time($value, $picture, $language, $calendar, $place)"/>
    </xsl:function>
    
    <xsl:function name="xpf:format-integer" as="xs:string">
        <xsl:param name="exec-context" as="map(*)"/>
        <xsl:param name="value" as="xs:integer?"/>
        <xsl:param name="picture" as="xs:string"/>
        <xsl:sequence select="
            xpe:fn-apply($exec-context, 'format-integer', [$value, $picture, ()]) 
            "/>
    </xsl:function>

    <xsl:function name="xpf:format-integer" as="xs:string">
        <xsl:param name="exec-context" as="map(*)"/>
        <xsl:param name="value" as="xs:integer?"/>
        <xsl:param name="picture" as="xs:string"/>
        <xsl:param name="language" as="xs:string?"/>
        <xsl:variable name="language" select="
            if (empty($language)) then xpe:default-language($exec-context) else $language
            "/>
        <xsl:sequence select="format-integer($value, $picture, $language)"/>
    </xsl:function>
    
    <xsl:function name="xpf:format-number" xmlns:xpf="http://www.nkutsche.com/xmlml/xpath-engine/functions" 
        as="xs:string">
        <xsl:param name="exec-context" as="map(*)"/>
        <xsl:param name="value" as="xs:numeric?"/>
        <xsl:param name="picture" as="xs:string"/>
        <xsl:sequence select="
            xpe:fn-apply($exec-context, 'format-number', [$value, $picture, ()]) 
            "/>
    </xsl:function>
    
    <xsl:function name="xpf:format-number" xmlns:xpf="http://www.nkutsche.com/xmlml/xpath-engine/functions" 
        as="xs:string">
        <xsl:param name="exec-context" as="map(*)"/>
        <xsl:param name="value" as="xs:numeric?"/>
        <xsl:param name="picture" as="xs:string"/>
        <xsl:param name="decimal-format-name" as="xs:string?"/>
        
        <xsl:variable name="decimal-format-name" select=" $decimal-format-name ! normalize-space(.)"/>
        
        <xsl:variable name="decimal-format-qname" as="item()?">
            <xsl:try>
                <xsl:sequence select="
                    if (exists($decimal-format-name)) 
                    then 
                        if (xpm:is-eqname($decimal-format-name)) 
                        then xpm:parse-eqname($decimal-format-name) 
                        else 
                            QName(
                            if (contains($decimal-format-name, ':')) 
                            then $exec-context?namespaces(substring-before($decimal-format-name, ':')) 
                            else ''
                            , $decimal-format-name) 
                    else ()
                    "/>
                <xsl:catch errors="err:FOCA0002">
                    <xsl:sequence select="error(xpe:error-code('FODF1280'), 
                        'Invalid decimal format name ' || $decimal-format-name || '.'
                        )"/>
                </xsl:catch>
            </xsl:try>
        </xsl:variable>
        
        
        
        <xsl:variable name="decimal-format" select="$exec-context?decimal-formats[
            if (exists($decimal-format-qname)) 
            then ?name = $decimal-format-qname 
            else empty(?name)
            ]"/>
        <xsl:choose>
            <xsl:when test="exists($decimal-format)">
                <xsl:variable name="stylesheet">
                    <xsl:element name="xsl:stylesheet">
                        <xsl:attribute name="version" select="'3.0'"/>
                        <xsl:element name="xsl:decimal-format">
                            <xsl:for-each select="map:keys($decimal-format)[. != 'name']">
                                <xsl:attribute name="{.}" select="$decimal-format(.)"/>
                            </xsl:for-each>
                        </xsl:element>
                        <xsl:copy select="doc(static-base-uri()) ! id('format-number', .)">
                            <xsl:attribute name="visibility" select="'public'"/>
                            <xsl:copy-of select="@*"/>
                            <xsl:copy-of select="node()"/>
                        </xsl:copy>
                    </xsl:element>
                </xsl:variable>
                <xsl:sequence select="transform(map{
                    'stylesheet-node' : $stylesheet,
                    'delivery-format' : 'raw',
                    'function-params' : [$value, $picture],
                    'initial-function' : xs:QName('xpe:format-number'),
                    'cache' : false()
                    })?output"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:sequence select="format-number($value, $picture, $decimal-format-name)"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>
    
    <xsl:function name="xpe:format-number" as="xs:string" xml:id="format-number">
        <xsl:param name="value" as="xs:numeric?"/>
        <xsl:param name="picture" as="xs:string"/>
        <xsl:sequence select="format-number($value, $picture)"/>
    </xsl:function>
    
    <xsl:function name="xpf:lang" as="xs:boolean">
        <xsl:param name="exec-context" as="map(*)"/>
        <xsl:param name="testlang" as="xs:string?"/>
        <xsl:sequence select="
            xpe:fn-apply($exec-context, 'lang', [$testlang, $exec-context?context]) 
            "/>
    </xsl:function>
    <xsl:function name="xpf:root" as="node()?">
        <xsl:param name="exec-context" as="map(*)"/>
        <xsl:variable name="context" select="$exec-context?context"/>
        <xsl:sequence select="
            if (empty($context)) 
            then error(xpe:error-code('XPDY0002'), 'Context item is absent for function call root()') 
            else xpe:fn-apply($exec-context, 'root', [$context])
            "/>
    </xsl:function>
    <xsl:function name="xpf:path" as="xs:string?">
        <xsl:param name="exec-context" as="map(*)"/>
        <xsl:variable name="context" select="$exec-context?context"/>
        <xsl:sequence select="
            if (empty($context)) 
            then error(xpe:error-code('XPDY0002'), 'Context item is absent for function call path()') 
            else xpe:fn-apply($exec-context, 'path', [$context])"/>
    </xsl:function>
    <xsl:function name="xpf:has-children" as="xs:boolean">
        <xsl:param name="exec-context" as="map(*)"/>
        <xsl:variable name="context" select="$exec-context?context"/>
        <xsl:sequence select="
            if (empty($context)) 
            then error(xpe:error-code('XPDY0002'), 'Context item is absent for function call has-children()') 
            else xpe:fn-apply($exec-context, 'has-children', [$context])
            "/>
    </xsl:function>
    <xsl:function name="xpf:distinct-values" as="xs:anyAtomicType*">
        <xsl:param name="exec-context" as="map(*)"/>
        <xsl:param name="arg" as="item()*"/>
        <xsl:sequence select="
            xpe:fn-apply($exec-context, 'distinct-values', 
            [xpe:data($exec-context, $arg), xpe:default-collation($exec-context)]
            )
            "/>
    </xsl:function>
    
    <xsl:function name="xpf:index-of" as="xs:integer*">
        <xsl:param name="exec-context" as="map(*)"/>
        <xsl:param name="seq" as="item()*"/>
        <xsl:param name="search" as="item()"/>
        <xsl:variable name="seq" select="xpe:data($exec-context, $seq)"/>
        <xsl:variable name="search" select="xpe:data($exec-context, $search)"/>
        <xsl:sequence select="
            xpe:fn-apply($exec-context, 'index-of', [$seq, $search, xpe:default-collation($exec-context)])
            "/>
    </xsl:function>
    
    <xsl:function name="xpf:deep-equal" as="xs:boolean">
        <xsl:param name="exec-context" as="map(*)"/>
        <xsl:param name="parameter1" as="item()*"/>
        <xsl:param name="parameter2" as="item()*"/>
        <xsl:sequence select="
            xpe:fn-apply($exec-context, 'deep-equal', [$parameter1, $parameter2, xpe:default-collation($exec-context)])
            "/>
    </xsl:function>
    <xsl:function name="xpf:max" as="xs:anyAtomicType?">
        <xsl:param name="exec-context" as="map(*)"/>
        <xsl:param name="arg" as="item()*"/>
        <xsl:sequence select="
            xpe:fn-apply($exec-context, 'max', [$arg, xpe:default-collation($exec-context)])
            "/>
    </xsl:function>
    
    <xsl:function name="xpf:min" as="xs:anyAtomicType?">
        <xsl:param name="exec-context" as="map(*)"/>
        <xsl:param name="arg" as="item()*"/>
        <xsl:sequence select="
            xpe:fn-apply($exec-context, 'min', [$arg, xpe:default-collation($exec-context)])
            "/>
    </xsl:function>
    
    <xsl:function name="xpf:id" as="element()*">
        <xsl:param name="exec-context" as="map(*)"/>
        <xsl:param name="arg" as="xs:string*"/>
        <xsl:variable name="context" select="$exec-context?context"/>
        <xsl:sequence select="
            xpe:fn-apply($exec-context, 'id', [$arg, $context])
            "/>
    </xsl:function>
    <xsl:function name="xpf:element-with-id" as="element()*">
        <xsl:param name="exec-context" as="map(*)"/>
        <xsl:param name="arg" as="xs:string*"/>
        <xsl:variable name="context" select="$exec-context?context"/>
        <xsl:sequence select="
            xpe:fn-apply($exec-context, 'element-with-id', [$arg, $context])
            "/>
    </xsl:function>
    
    <xsl:function name="xpf:idref" as="node()*">
        <xsl:param name="exec-context" as="map(*)"/>
        <xsl:param name="arg" as="xs:string*"/>
        <xsl:variable name="context" select="$exec-context?context"/>
        <xsl:sequence select="
            xpe:fn-apply($exec-context, 'idref', [$arg, $context])
            "/>
    </xsl:function>
    
    <xsl:function name="xpf:generate-id" as="xs:string">
        <xsl:param name="exec-context" as="map(*)"/>
        <xsl:variable name="context" select="$exec-context?context"/>
        <xsl:sequence select="
            if (empty($context)) 
            then 
                error(xpe:error-code('XPDY0002'), 'There is no context item for the call of the zero-argument function generate-id().') 
            else 
                xpe:fn-apply($exec-context, 'generate-id', [$context])
                "/>
    </xsl:function>
    <xsl:function name="xpf:doc" as="document-node()?">
        <xsl:param name="exec-context" as="map(*)"/>
        <xsl:param name="uri" as="xs:string?"/>
        <xsl:variable name="baseUri" select="xpe:static-base-uri($exec-context)"/>
        <xsl:try>
            <xsl:choose>
                <xsl:when test="empty($uri)"/>
                <xsl:otherwise>
                    <xsl:variable name="resolved" select="
                        if (exists($exec-context?uri-resolver)) 
                        then $exec-context?uri-resolver($uri, $baseUri) 
                        else ()
                        "/>
                    <xsl:variable name="resolved" select="
                        if (empty($resolved)) 
                        then xpe:default-uri-resolver($exec-context, $uri, $baseUri) 
                        else $resolved
                        "/>
                    <xsl:sequence select="
                        if (exists($resolved)) 
                        then $resolved 
                        else error(xpe:error-code('FODC0002'), 'Resource ' || $uri || ' is not available or is not well-formed XML.')
                        "/>
                </xsl:otherwise>
            </xsl:choose>
            <xsl:catch errors="err:FORG0002">
                <xsl:sequence select="error(xpe:error-code('FODC0005'), 'Malformed URI ' || $uri)"/>
            </xsl:catch>
        </xsl:try>
    </xsl:function>
    <xsl:function name="xpf:doc-available" as="xs:boolean">
        <xsl:param name="exec-context" as="map(*)"/>
        <xsl:param name="uri" as="xs:string?"/>
        <xsl:try>
            <xsl:variable name="result" select="xpe:fn-apply($exec-context, 'doc', [$uri])"/>
            <xsl:sequence select="exists($result)"/>
            <xsl:catch>
                <xsl:sequence select="false()"/>
            </xsl:catch>
        </xsl:try>
    </xsl:function>
    <xsl:function name="xpf:collection" as="node()*">
        <xsl:param name="exec-context" as="map(*)"/>
        <xsl:sequence select="
            xpe:fn-apply($exec-context, 'collection', [()])
            "/>
    </xsl:function>
    <xsl:function name="xpf:collection" as="node()*">
        <xsl:param name="exec-context" as="map(*)"/>
        <xsl:param name="arg" as="item()?"/>

        <xsl:variable name="uri-collection" select="
            xpe:fn-apply($exec-context, 'uri-collection', [$arg])
            "/>
        <xsl:sequence select="
            $uri-collection ! xpe:fn-apply($exec-context, 'doc', [.])
            "/>
        
    </xsl:function>
    
    <xsl:function name="xpf:uri-collection" as="xs:anyURI*">
        <xsl:param name="exec-context" as="map(*)"/>
        <xsl:sequence select="
            xpe:fn-apply($exec-context, 'uri-collection', [()])
            "/>
    </xsl:function>
    <xsl:function name="xpf:uri-collection" as="xs:anyURI*">
        <xsl:param name="exec-context" as="map(*)"/>
        <xsl:param name="arg" as="xs:string?"/>
        
        <xsl:variable name="baseUri" select="xpe:static-base-uri($exec-context)"/>
        <xsl:try>
            <xsl:choose>
                <xsl:when test="empty($exec-context?uri-collection-resolver)">
                    <xsl:sequence select="
                        xpe:default-collection-resolver($exec-context, $arg, $baseUri)
                        "/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:sequence select="$exec-context?uri-collection-resolver($arg, $baseUri)"/>
                </xsl:otherwise>
            </xsl:choose>
            <xsl:catch errors="err:FORG0002">
                <xsl:sequence select="error(xpe:error-code('FODC0004'), 'Malformed URI ' || $arg)"/>
            </xsl:catch>
        </xsl:try>
    </xsl:function>
    
<!--    
    Unparsed text functions
    -->
    <xsl:function name="xpf:unparsed-text-lines" as="xs:string*">
        <xsl:param name="exec-context" as="map(*)"/>
        <xsl:param name="href" as="xs:string?"/>
        <xsl:sequence select="
            xpe:fn-apply($exec-context, 'unparsed-text-lines', [$href, ''])
            "/>
    </xsl:function>
    
    <xsl:function name="xpf:unparsed-text-lines" as="xs:string*">
        <xsl:param name="exec-context" as="map(*)"/>
        <xsl:param name="href" as="xs:string?"/>
        <xsl:param name="encoding" as="xs:string"/>
        <xsl:variable name="unparsed-text" select="
            xpe:fn-apply($exec-context, 'unparsed-text', [$href, $encoding])
            "/>
        <xsl:sequence select="tokenize($unparsed-text, '\r\n|\r|\n')[not(position()=last() and .='')]"/>
    </xsl:function>

    
    <xsl:function name="xpf:unparsed-text" as="xs:string?">
        <xsl:param name="exec-context" as="map(*)"/>
        <xsl:param name="href" as="xs:string?"/>
        <xsl:sequence select="
            xpe:fn-apply($exec-context, 'unparsed-text', [$href, ''])
            "/>
    </xsl:function>
    <xsl:function name="xpf:unparsed-text" as="xs:string?">
        <xsl:param name="exec-context" as="map(*)"/>
        <xsl:param name="href" as="xs:string?"/>
        <xsl:param name="encoding" as="xs:string"/>
        
        <xsl:variable name="encoding" select="
            xpe:verify-encoding($encoding)
            "/>
        
        <xsl:variable name="baseUri" select="xpe:static-base-uri($exec-context)"/>
        
        <xsl:try>
            <xsl:choose>
                <xsl:when test="empty($href)"/>
                <xsl:when test="empty($exec-context?unparsed-text-resolver)">
                    <xsl:sequence select="
                        xpe:default-unparsed-text-resolver($exec-context, $href, $baseUri, $encoding)
                        "/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:sequence select="$exec-context?unparsed-text-resolver($href, $baseUri, $encoding)"/>
                </xsl:otherwise>
            </xsl:choose>
            <xsl:catch errors="err:FORG0002">
                <xsl:sequence select="error(xpe:error-code('FOUT1170'), 'Malformed URI ' || $href)"/>
            </xsl:catch>
        </xsl:try>
        
        
    </xsl:function>
    
    <xsl:function name="xpe:verify-encoding" as="xs:string?">
        <xsl:param name="encoding" as="xs:string"/>
        <xsl:choose>
            <xsl:when test="$encoding = ''">
                <xsl:sequence select="()"/>
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
        <xsl:sequence select="
            xpe:fn-apply($exec-context, 'unparsed-text-available', [$href, ''])
            "/>
    </xsl:function>
    
    <xsl:function name="xpf:unparsed-text-available" as="xs:boolean">
        <xsl:param name="exec-context" as="map(*)"/>
        <xsl:param name="href" as="xs:string?"/>
        <xsl:param name="encoding" as="xs:string"/>
        <xsl:try>
            <xsl:variable name="unparsed-text" select="
                xpe:fn-apply($exec-context, 'unparsed-text', [$href, $encoding])
                "/>
            <xsl:sequence select="exists($unparsed-text)"/>
            <xsl:catch>
                <xsl:sequence select="false()"/>
            </xsl:catch>
        </xsl:try>
    </xsl:function>
    
    
    <xsl:function name="xpe:default-unparsed-text-resolver" as="xs:string?" visibility="public">
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
    
    <xsl:function name="xpe:default-uri-resolver" as="document-node()?" visibility="public">
        <xsl:param name="exec-context" as="map(*)"/>
        <xsl:param name="relative" as="xs:string?"/>
        <xsl:param name="baseUri" as="xs:string"/>
        <xsl:variable name="resolved" as="xs:anyURI?">
            <xsl:sequence select="xpe:default-uri-mapper($exec-context, $relative, $baseUri)"/>
        </xsl:variable>
        <xsl:sequence select="doc($resolved)"/>
    </xsl:function>
    
    <xsl:function name="xpe:default-collection-resolver" as="xs:anyURI*" visibility="public">
        <xsl:param name="exec-context" as="map(*)"/>
        <xsl:param name="relative" as="xs:string?"/>
        <xsl:param name="baseUri" as="xs:string"/>
        <xsl:choose>
            <xsl:when test="empty($relative)">
                <xsl:sequence select="error(xpe:error-code('FODC0002'), 'No default collection has been defined')"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:variable name="resolved" as="xs:anyURI">
                    <xsl:sequence select="xpe:default-uri-mapper($exec-context, $relative, $baseUri)"/>
                </xsl:variable>
                <xsl:sequence select="uri-collection($resolved)"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>
    
    <xsl:function name="xpe:default-uri-mapper" as="xs:anyURI" visibility="public">
        <xsl:param name="exec-context" as="map(*)"/>
        <xsl:param name="relative" as="xs:string"/>
        <xsl:param name="base-uri" as="xs:string"/>
        <xsl:choose>
            <xsl:when test="empty($exec-context?uri-mapper)">
                <xsl:sequence select="
                    resolve-uri($relative, $base-uri)
                    "/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:sequence select="$exec-context?uri-mapper($relative, $base-uri)"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>
    
    <xsl:function name="xpf:json-doc" as="item()?">
        <xsl:param name="exec-context" as="map(*)"/>
        <xsl:param name="href" as="xs:string?"/>
        <xsl:sequence select="
            xpe:fn-apply($exec-context, 'json-doc', [$href, map{}])
            "/>
    </xsl:function>
    
    <xsl:function name="xpf:json-doc" as="item()?">
        <xsl:param name="exec-context" as="map(*)"/>
        <xsl:param name="href" as="xs:string?"/>
        <xsl:param name="options" as="map(*)"/>
        <xsl:variable name="unparsed-text" select="
            xpe:fn-apply($exec-context, 'unparsed-text', [$href])
            "/>
        <xsl:sequence select="
            xpe:fn-apply($exec-context, 'parse-json', [$unparsed-text, $options])
            "/>
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

    <xsl:function name="xpf:json-to-xml" as="document-node()?">
        <xsl:param name="exec-context" as="map(*)"/>
        <xsl:param name="json-text" as="xs:string?"/>
        <xsl:sequence select="
            xpe:fn-apply($exec-context, 'json-to-xml', [$json-text, map{}])
            "/>
    </xsl:function>
    <xsl:function name="xpf:json-to-xml" as="document-node()?">
        <xsl:param name="exec-context" as="map(*)"/>
        <xsl:param name="json-text" as="xs:string?"/>
        <xsl:param name="options" as="map(*)"/>
        <xsl:variable name="fallback" select="$options?fallback ! xpe:raw-function(.)"/>
        <xsl:variable name="options" select="
            if (exists($fallback)) 
            then map:put($options, 'fallback', $fallback) 
            else $options
            "/>
        
        <xsl:variable name="static-base-uri" select="xpe:static-base-uri($exec-context)"/>
        <xsl:sequence select="transform(map{
            'stylesheet-node' : $xpe:to-xml-stylesheet,
            'stylesheet-base-uri' : $static-base-uri,
            'delivery-format' : 'raw',
            'function-params' : [$json-text, $options],
            'initial-function' : xs:QName('xpe:json-to-xml'),
            'cache' : false()
            })?output"/>
    </xsl:function>
    <xsl:function name="xpe:json-to-xml" as="document-node(element(*))?" xml:id="json-to-xml">
        <xsl:param name="json-text" as="xs:string?"/>
        <xsl:param name="options" as="map(*)"/>
        <xsl:sequence select="json-to-xml($json-text, $options)"/>
    </xsl:function>

    <xsl:variable name="xpe:to-xml-stylesheet">
        <xsl:element name="xsl:stylesheet">
            <xsl:attribute name="version" select="'3.0'"/>
            <xsl:for-each select="doc(static-base-uri()) ! id(('parse-xml', 'json-to-xml'), .)">
                <xsl:copy>
                    <xsl:attribute name="visibility" select="'public'"/>
                    <xsl:copy-of select="@*"/>
                    <xsl:copy-of select="node()"/>
                </xsl:copy>
            </xsl:for-each>
        </xsl:element>
    </xsl:variable>
    <xsl:function name="xpf:parse-xml" as="document-node(element(*))?">
        <xsl:param name="exec-context" as="map(*)"/>
        <xsl:param name="arg" as="xs:string?"/>
        
        <xsl:variable name="static-base-uri" select="xpe:static-base-uri($exec-context)"/>
        <xsl:sequence select="transform(map{
            'stylesheet-node' : $xpe:to-xml-stylesheet,
            'stylesheet-base-uri' : $static-base-uri,
            'delivery-format' : 'raw',
            'function-params' : [$arg],
            'initial-function' : xs:QName('xpe:parse-xml'),
            'cache' : false()
            })?output"/>
        
    </xsl:function>
    
    <xsl:function name="xpe:parse-xml" as="document-node(element(*))?" xml:id="parse-xml">
        <xsl:param name="arg" as="xs:string?"/>
        <xsl:sequence select="parse-xml($arg)"/>
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
                (: TODO, not clear if xpe:fn-apply instead of xpf:doc should used:)
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
                (: TODO, not clear if xpe:fn-apply instead of xpf:doc should used:)
                => map:remove('package-location')
            else $options
            "/>
        <xsl:sequence select="transform($options)"/>
    </xsl:function>
    
    <xsl:function name="xpf:position" as="xs:integer">
        <xsl:param name="exec-context" as="map(*)"/>
        <xsl:sequence select="
            if (empty($exec-context?context)) 
            then error(xpe:error-code('XPDY0002'), 'There is no context item for the call of the zero-argument function position().')  
            else ($exec-context?position, 1)[1]
            "/>
    </xsl:function>
    <xsl:function name="xpf:last" as="xs:integer">
        <xsl:param name="exec-context" as="map(*)"/>
        
        <xsl:sequence select="
            if (empty($exec-context?context)) 
            then error(xpe:error-code('XPDY0002'), 'There is no context item for the call of the zero-argument function last().')  
            else ($exec-context?last, 1)[1]
            "/>
    </xsl:function>
    <xsl:function name="xpe:default-collation" as="xs:string">
        <xsl:param name="exec-context" as="map(*)"/>
        <xsl:sequence select="xpe:fn-apply($exec-context, 'default-collation', [])"/>
    </xsl:function>
    <xsl:function name="xpf:default-collation" as="xs:string">
        <xsl:param name="exec-context" as="map(*)"/>
        <xsl:sequence select="($exec-context?default-collation, default-collation())[1]"/>
    </xsl:function>
    <xsl:function name="xpf:base-uri" as="xs:anyURI?">
        <xsl:param name="exec-context" as="map(*)"/>
        <xsl:sequence select="
            xpe:fn-apply($exec-context, 'base-uri', [$exec-context?context])
            "/>
    </xsl:function>
    <xsl:function name="xpf:static-base-uri" as="xs:anyURI?">
        <xsl:param name="exec-context" as="map(*)"/>
        <xsl:sequence select="($exec-context?base-uri ! xs:anyURI(.), static-base-uri())[1]"/>
    </xsl:function>
    <xsl:function name="xpe:static-base-uri" as="xs:anyURI?">
        <xsl:param name="exec-context" as="map(*)"/>
        <xsl:sequence select="
            xpe:fn-apply($exec-context, 'static-base-uri', [])
            "/>
    </xsl:function>
    
    <xsl:function name="xpf:available-environment-variables" as="xs:string*">
        <xsl:param name="exec-context" as="map(*)"/>
        <xsl:sequence select="
            if (map:contains($exec-context, 'environment-variables')) 
            then map:keys($exec-context?environment-variables) 
            else available-environment-variables()
            "/>
    </xsl:function>

    <xsl:function name="xpf:environment-variable" as="xs:string?">
        <xsl:param name="exec-context" as="map(*)"/>
        <xsl:param name="name" as="xs:string"/>
        
        <xsl:sequence select="
            if (map:contains($exec-context, 'environment-variables')) 
            then $exec-context?environment-variables($name) 
            else environment-variable($name)
            "/>
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
            xs:QName('xs:NOTATION') : function(){error(xpe:error-code('XPST0017'), 'xs:NOTATION can not be constructed.')}
        }
        " as="map(xs:QName, function(*))"/>
    
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
    
    <xsl:function name="xpe:fn-apply" as="item()*" visibility="final">
        <xsl:param name="exec-context" as="map(*)"/>
        <xsl:param name="func-name" as="xs:string"/>
        <xsl:param name="args" as="array(*)"/>
        
        <xsl:variable name="arity" select="array:size($args)"/>
        <xsl:variable name="function" select="
            xpf:function-lookup($exec-context, xs:QName('fn:' || $func-name), $arity)
            "/>
        <xsl:choose>
            <xsl:when test="exists($function)">
                <xsl:sequence select="xpf:apply($exec-context, $function, $args)"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:sequence select="error(xs:QName('xpe:unknown-function'), 
                    'No function fn:' || $func-name || '#' || $arity || ' available!' 
                    )"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>
    <xsl:function name="xpf:function-lookup" as="map(*)?">
        <xsl:param name="exec-context" as="map(*)"/>
        <xsl:param name="name" as="xs:QName"/>
        <xsl:param name="arity" as="xs:integer"/>
        
        <xsl:variable name="local-name" select="local-name-from-QName($name)"/>
        <xsl:variable name="ns-uri" select="namespace-uri-from-QName($name)"/>
        
        <xsl:variable name="xsd-constructor" select="$ns-uri = $build-in-namespaces('xs')"/>
        
        <xsl:variable name="ext-functions" select="($exec-context?extension-functions, map{})[1]"/>
        
        <xsl:variable name="extension-name" select="
            if ($ns-uri = $build-in-namespaces('fn')) 
            then xs:QName('xpf:' || $local-name) 
            else if ($ns-uri = $build-in-namespaces('array')) 
            then xs:QName('xpfa:' || $local-name) 
            else if ($ns-uri = $build-in-namespaces('map')) 
            then xs:QName('xpfm:' || $local-name) 
            else if ($xsd-constructor) 
            then xs:QName('xpfs:' || $local-name) 
            else ()
            "/>
        
        <xsl:variable name="function" select="
            if (map:contains($ext-functions, $name) and exists($ext-functions($name)[?arity = $arity])) 
            then $ext-functions($name)[?arity = $arity] 
            else if (exists($unsupported-functions($name))) 
            then ($unsupported-functions($name)()) 
            else if (exists($extension-name) and exists(function-lookup($extension-name, $arity + 1))) 
            then function-lookup($extension-name, $arity + 1) 
            else function-lookup($name, $arity)
            "/>
        
        
        
        <xsl:choose>
            <xsl:when test="empty($function)">
<!--                <xsl:message expand-text="yes">Could not find funciton Q{{{$ns-uri}}}{$local-name}!</xsl:message>-->
            </xsl:when>
            <xsl:when test="xpe:is-function($function)">
                
                <xsl:variable name="apply-static-context" select="
                        ($function?context-dependent, false())[1]
                    " as="xs:boolean"/>
                <xsl:variable name="raw-function" select="xpe:raw-function($function)"/>
                <xsl:variable name="arg-types" select="$function?arg-types"/>
                <xsl:variable name="underline-funct-body" select="
                    function($args){
                        let $args := xpe:prepare-arguments($exec-context, $args, $arg-types, $name)
                        return
                        let $args2 := if ($apply-static-context) then array:join(([$exec-context],$args)) else $args
                        return
                        (
                        apply($raw-function, $args2)
                        )
                    }
                    "/>
                <xsl:variable name="exec-function" select="xpe:create-function($underline-funct-body, $arity)"/>
                <xsl:sequence select="
                    xpe:create-function-item($exec-function, $name, $arg-types, $function?return-type)
                    "/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:variable name="apply-static-context" select="
                    function-arity($function) eq $arity + 1
                    "/>
                <xsl:variable name="funct-sign" select="
                    ((function-name($function), $name) ! key('functSign-qname', ., $function-signatures))[1]"/>
                <xsl:variable name="funct-sign" select="$funct-sign/fos:signatures/fos:proto[
                    if (fos:arg[@name='...']) 
                    then (count(fos:arg[@name != '...']) le $arity) 
                    else count(fos:arg) = $arity
                    ]"/>
                
                <xsl:variable name="arg-types" as="element(itemType)*">
                    <xsl:choose>
                        <xsl:when test="$xsd-constructor and not($funct-sign)">
                            <itemType occurrence="zero-or-one">
                                <atomic name="xs:anyAtomicType">
                                    <xsl:namespace name="xs" select="$build-in-namespaces('xs')"/>
                                </atomic>
                            </itemType>
                        </xsl:when>
                        <xsl:when test="not($funct-sign)">
                            <xsl:sequence select="error(xpe:error-code('XPST0017'), 'Unsupported function ' || $name || '#' || $arity)"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:sequence select="xpe:arg-types-by-function-sign($funct-sign, $arity)"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:variable>
                <xsl:variable name="underline-funct-body" select="
                    function($args){
                        let $args := xpe:prepare-arguments($exec-context, $args, $arg-types, $name)
                        return
                        let $args2 := if ($apply-static-context) then array:join(([$exec-context],$args)) else $args
                        return
                        (
                        apply($function, $args2)
                        )
                    }
                    "/>
                
                <xsl:variable name="return-type" as="element(itemType)">
                    <xsl:choose>
                        <xsl:when test="$xsd-constructor and not($funct-sign)">
                            <itemType occurrence="zero-or-one">
                                <atomic name="xs:{$local-name}">
                                    <xsl:namespace name="xs" select="$ns-uri"/>
                                </atomic>
                            </itemType>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:sequence select="$funct-sign/key('fosTypeModel-typeName', @return-type)/itemType"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:variable>
                
                <xsl:sequence select="
                    xpe:create-function-item(
                        xpe:create-function($underline-funct-body, $arity),
                        $name,
                        $arg-types,
                        $return-type
                    )
                    "/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>
    
    <xsl:key name="fosTypeModel-typeName" match="fos:type-model" use="@name"/>
    
    
    
    <xsl:function name="xpe:arg-types-by-function-sign" as="element(itemType)*">
        <xsl:param name="funct-sign" as="element(fos:proto)"/>
        <xsl:param name="arity" as="xs:integer"/>
        <xsl:sequence select="
            for $i in 1 to $arity
            return
                let $argDef := ($funct-sign/fos:arg[$i], $funct-sign/fos:arg[@name = '...'])[1]
                return
                $argDef/key('fosTypeModel-typeName', @type)/itemType
            "/>
    </xsl:function>
    <xsl:function name="xpe:prepare-arguments" as="array(*)">
        <xsl:param name="exec-context" as="map(*)"/>
        <xsl:param name="arguments" as="array(*)"/>
        <xsl:param name="types" as="element(itemType)*"/>
        <xsl:param name="origin-funct-name" as="xs:QName?"/>
        <xsl:variable name="single-args" as="array(*)*">
            <xsl:for-each select="1 to array:size($arguments)">
                <xsl:variable name="i" select="."/>
                <xsl:try>
                    <xsl:sequence select="[xpe:prepare-argument($exec-context, $arguments($i), $types[$i])]"/>
                    <xsl:catch>
                        <xsl:variable name="arg-no" select="
                            if ($i le 10) 
                            then format-integer($i, 'w;o') 
                            else ($i || 'th')
                            "/>
                        <xsl:variable name="function-descr" select="
                            if (exists($origin-funct-name)) 
                            then $origin-funct-name || '()' 
                            else 'anonym function call'"/>
                        <xsl:variable name="message-pre" select="'Bad value as ' || $arg-no || ' argument of ' || $function-descr || ': '"/>
                        <xsl:variable name="message-suffix" select="'Origin: ' || $err:module || '#' || $err:line-number"/>
                        <xsl:sequence select="error($err:code, $message-pre || $err:description || '&#xA;' || $message-suffix, $err:value)"/>
                    </xsl:catch>
                </xsl:try>
            </xsl:for-each>
        </xsl:variable>
        <xsl:sequence select="$single-args => array:join()"/>
    </xsl:function>
    
    <xsl:function name="xpe:prepare-argument" as="item()*">
        <xsl:param name="exec-context" as="map(*)"/>
        <xsl:param name="arg" as="item()*"/>
        <xsl:param name="typeDef" as="element(itemType)?"/>
        <xsl:variable name="occurrence" select="$typeDef/@occurrence"/>
        
        <xsl:variable name="arg" select="
            if ($typeDef/atomic) 
            then xpe:data($exec-context, $arg) 
            else $arg
            "/>
        <xsl:choose>
            <xsl:when test="not($typeDef)">
                <xsl:sequence select="$arg"/>
            </xsl:when>
            <xsl:when test="matches($occurrence, '^zero') and empty($arg)">
                <xsl:sequence select="()"/>
            </xsl:when>
            <xsl:when test="empty($arg)">
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
            <xsl:when test="$occurrence = ('zero-or-more', 'one-or-more')">
                <xsl:variable name="single-type" as="element()">
                    <xsl:copy select="$typeDef">
                        <xsl:sequence select="@* except @occurrence"/>
                        <xsl:sequence select="node()"/>
                    </xsl:copy>
                </xsl:variable>
                
                <xsl:sequence select="$arg ! xpe:prepare-argument($exec-context, ., $single-type)"/>
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
            <xsl:otherwise>
                <xsl:apply-templates select="$typeDef" mode="xpe:prepare-argument">
                    <xsl:with-param name="exec-context" select="$exec-context" tunnel="yes"/>
                    <xsl:with-param name="arg" select="$arg" tunnel="yes"/>
                </xsl:apply-templates>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>
    
    <xsl:template match="itemType" mode="xpe:prepare-argument" priority="100">
        <xsl:param name="exec-context" tunnel="yes" as="map(*)"/>
        <xsl:variable name="arg" as="item()">
            <xsl:next-match/>
        </xsl:variable>
        <xsl:try>
            <xsl:sequence select="xpe:treat-as($exec-context, $arg, .)"/>
            <xsl:catch errors="err:XPDY0050">
                <xsl:sequence select="error(xpe:error-code('XPTY0004'), $err:description)"/>
            </xsl:catch>
        </xsl:try>
    </xsl:template>
    
    <xsl:template match="itemType" mode="xpe:prepare-argument">
        <xsl:apply-templates select="*" mode="#current"/>
    </xsl:template>
    
    <xsl:template match="itemType[atomic]" mode="xpe:prepare-argument">
        <xsl:variable name="arg" as="item()">
            <xsl:apply-templates select="*" mode="#current"/>
        </xsl:variable>
        <xsl:variable name="typeName" select="atomic/resolve-QName(@name, .)"/>
        <xsl:variable name="namespace-sensitive" select="xs:QName('xs:QName'), xs:QName('xs:NOTATION')"/>
        <xsl:sequence select="
            if ($arg instance of xs:untypedAtomic) 
            then 
            if ($typeName = xs:QName('xs:anyAtomicType')) 
            then $arg 
            else if ($typeName = $namespace-sensitive) 
             then error(xpe:error-code('XPTY0117'), 
                    'An untyped atomic value cannot be converted to a QName or NOTATION') 
             else xpt:cast-as($arg, .)
            else ($arg)
            "/>
    </xsl:template>
    <xsl:variable name="promotion-types" select="
        map{
            xs:QName('xs:double') : (xs:QName('xs:float'), xs:QName('xs:decimal')),
            xs:QName('xs:float') : (xs:QName('xs:decimal')),
            xs:QName('xs:string') : (xs:QName('xs:anyURI'))
        }
        
        "/>
    <xsl:template match="itemType[atomic[exists($promotion-types(resolve-QName(@name, .)))]]" mode="xpe:prepare-argument"
        priority="20">
        <xsl:variable name="arg" as="item()">
            <xsl:next-match/>
        </xsl:variable>
        <xsl:variable name="typeName" select="atomic/resolve-QName(@name, .)"/>
        <xsl:variable name="promoteableTypes" select="$promotion-types($typeName)"/>
        <xsl:variable name="validators" select="
            $promoteableTypes ! xpt:get-type-validator(.)
            "/>
        <xsl:sequence select="
            if (some $ptv in $validators satisfies $ptv?instance-of($arg)) 
            then xpt:cast-as($arg, .) 
            else $arg
            "/>
    </xsl:template>
    
    <xsl:function name="xpe:type-promotion" as="item()*">
        <xsl:param name="values" as="item()*"/>
        <xsl:param name="atomic" as="element(atomic)?"/>
        <xsl:variable name="typeName" select="$atomic/resolve-QName(@name, .)"/>
        <xsl:variable name="allowed-src-typeNames" select="$typeName ! $promotion-types(.)"/>
        <xsl:variable name="validators" select="
            $allowed-src-typeNames ! xpt:get-type-validator(.)
            "/>
        <xsl:variable name="target-type" as="element(itemType)">
            <itemType>
                <xsl:copy-of select="$atomic"/>
            </itemType>
        </xsl:variable>
        <xsl:for-each select="$values">
            <xsl:variable name="value" select="."/>
            <xsl:sequence select="
                if (some $ptv in $validators satisfies $ptv?instance-of($value)) 
                then xpt:cast-as($value, $target-type) 
                else $value
                "/>
        </xsl:for-each>
    </xsl:function>

    <xsl:template match="itemType[functType]" mode="xpe:prepare-argument">
        <xsl:param name="arg" tunnel="yes" as="item()"/>
        <xsl:apply-templates select="*" mode="#current"/>
    </xsl:template>

    <xsl:template match="itemType[not(*)]" mode="xpe:prepare-argument">
        <xsl:param name="arg" tunnel="yes" as="item()"/>
        <xsl:sequence select="$arg"/>
    </xsl:template>

    <xsl:template match="itemType/*" mode="xpe:prepare-argument" priority="-10">
        <xsl:param name="arg" tunnel="yes" as="item()"/>
        <xsl:sequence select="$arg"/>
    </xsl:template>
    
    <xsl:template match="mapType" mode="xpe:prepare-argument">
        <xsl:param name="arg" tunnel="yes" as="item()"/>
        <xsl:choose>
            <xsl:when test="xpe:is-function($arg)">
                <xsl:variable name="type" select="xpm:xpath-serializer-sub(parent::*) => normalize-space()"/>
                <xsl:sequence select="error(xpe:error-code('XPTY0004'), 'The required item type is ' || $type || ' but the received value is a function()')"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:sequence select="$arg"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <xsl:template match="functType[count(itemType) le 1]" mode="xpe:prepare-argument" priority="20">
        <xsl:param name="arg" tunnel="yes" as="item()"/>
        <xsl:variable name="anyItemType" as="element(itemType)">
            <itemType occurrence="zero-or-more"/>
        </xsl:variable>
        <xsl:choose>
            <xsl:when test="
                ($arg instance of map(*) and not(xpe:is-function($arg)))
                or $arg instance of array(*)
                ">
                <xsl:variable name="mapKeyType" as="element(itemType)">
                    <itemType>
                        <atomic name="xs:anyAtomicType"/>
                    </itemType>
                </xsl:variable>
                <xsl:next-match>
                    <xsl:with-param name="arg" select="
                        xpe:create-function-item(function($p){$arg($p)}, (), $anyItemType, $anyItemType)
                        " tunnel="yes"/>
                </xsl:next-match>
            </xsl:when>
            <xsl:otherwise>
                <xsl:next-match/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <xsl:template match="functType[itemType | as]" mode="xpe:prepare-argument" priority="10">
        <xsl:param name="arg" tunnel="yes" as="item()"/>
        <xsl:variable name="req-arity" select="count(itemType)"/>
        <xsl:choose>
            <xsl:when test="xpe:is-function($arg) and $req-arity ne $arg?arity">
                <xsl:sequence select="
                    error(xpe:error-code('XPTY0004'), 'Required function arity is ' || $req-arity || 'but the delivered function has the arity ' || $arg?arity)
                    "/>
            </xsl:when>
            <xsl:when test="xpe:is-function($arg)">
                <xsl:variable name="type" select="."/>
                <xsl:sequence select="
                    $arg 
                    => map:put('return-type', $type/as/itemType)
                    => map:put('arg-types', $type/itemType)
                    "/>
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
                $arg
            else if ($arg instance of function(*)) 
            then 
                xpe:create-function-item($arg)
            else 
                error(
                    xpe:error-code('XPTY0004'),
                    'Can not convert ' || $arg || ' to a function from type ' || normalize-space(xpm:xpath-serializer-sub(parent::*))
                ) 
            "/>
    </xsl:template>
    
    <xsl:function name="xpe:create-function-item" as="map(*)">
        <xsl:param name="raw-function" as="function(*)"/>
        <xsl:variable name="anyItemType" as="element(itemType)">
            <itemType occurrence="zero-or-more"/>
        </xsl:variable>
        <xsl:variable name="arg-types" select="
            (1 to function-arity($raw-function)) ! $anyItemType
            "/>
        
        <xsl:sequence select="xpe:create-function-item($raw-function, (), $arg-types, $anyItemType)"/>
    </xsl:function>
    
    <xsl:function name="xpe:create-function-item" as="map(*)" visibility="final">
        <xsl:param name="raw-function" as="function(*)"/>
        <xsl:param name="function-name" as="xs:QName?"/>
        <xsl:param name="arg-types" as="element(itemType)*"/>
        <xsl:param name="return-type" as="element(itemType)"/>
        <xsl:sequence select="
            map{
            'type' : QName($xpf:namespace-uri, 'function'),
            'function' : $raw-function,
            'name' : ($function-name, function-name($raw-function))[1],
            'arity' : count($arg-types),
            'arg-types' : $arg-types,
            'return-type' : $return-type
            }
            "/>
    </xsl:function>
    
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
    

    <xsl:function name="xpf:function-arity" as="xs:integer">
        <xsl:param name="exec-context" as="map(*)"/>
        <xsl:param name="func" as="map(*)"/>
        <xsl:sequence select="$func?arity"/>
    </xsl:function>

    <xsl:function name="xpf:for-each" as="item()*">
        <xsl:param name="exec-context" as="map(*)"/>
        <xsl:param name="seq" as="item()*"/>
        <!-- function(item()) as item()* -->
        <xsl:param name="action" as="map(*)"/>
        <xsl:variable name="action" select="xpe:raw-function($action)"/>
        <xsl:sequence select="for-each($seq, $action)"/>
    </xsl:function>
    
    <xsl:function name="xpf:filter" as="item()*">
        <xsl:param name="exec-context" as="map(*)"/>
        <xsl:param name="seq" as="item()*"/>
        <!--    function(item()) as xs:boolean    -->
        <xsl:param name="f" as="map(*)"/>
        <xsl:variable name="f" select="xpe:raw-function($f)"/>
        <xsl:sequence select="filter($seq, $f)"/>
    </xsl:function>
    
    <xsl:function name="xpf:fold-left" as="item()*">
        <xsl:param name="exec-context" as="map(*)"/>
        <xsl:param name="seq" as="item()*"/>
        <xsl:param name="zero" as="item()*"/>
        <!-- function(item()*, item()) as item()* -->
        <xsl:param name="f" as="map(*)"/>
        <xsl:variable name="f" select="xpe:raw-function($f)"/>
        <xsl:sequence select="fold-left($seq, $zero, $f)"/>
    </xsl:function>
    
    <xsl:function name="xpf:fold-right" as="item()*">
        <xsl:param name="exec-context" as="map(*)"/>
        <xsl:param name="seq" as="item()*"/>
        <xsl:param name="zero" as="item()*"/>
        <!-- function(item(), item()*) as item()* -->
        <xsl:param name="f" as="map(*)"/>
        <xsl:variable name="f" select="xpe:raw-function($f)"/>
        <xsl:sequence select="fold-right($seq, $zero, $f)"/>
    </xsl:function>
    
    <xsl:function name="xpf:for-each-pair" as="item()*">
        <xsl:param name="exec-context" as="map(*)"/>
        <xsl:param name="seq1" as="item()*"/>
        <xsl:param name="seq2" as="item()*"/>
        <!-- function(item(), item()) as item()* -->
        <xsl:param name="action" as="map(*)"/>
        <xsl:variable name="action" select="xpe:raw-function($action)"/>
        <xsl:sequence select="for-each-pair($seq1, $seq2, $action)"/>
    </xsl:function>
    
    <xsl:function name="xpf:sort" as="item()*">
        <xsl:param name="exec-context" as="map(*)"/>
        <xsl:param name="input" as="item()*"/>
        <xsl:param name="collation" as="xs:string?"/>
        <!-- function(item()) as xs:anyAtomicType* -->
        <xsl:param name="key" as="map(*)"/>
        <xsl:variable name="key" select="xpe:raw-function($key)"/>
        <xsl:sequence select="sort($input, $collation, $key)"/>
    </xsl:function>
    
    <xsl:function name="xpf:apply" as="item()*">
        <xsl:param name="exec-context" as="map(*)"/>
        <!-- function(*) -->
        <xsl:param name="function" as="map(*)"/>
        <xsl:param name="array" as="array(*)"/>
        <xsl:variable name="function" select="xpe:raw-function($function)"/>
        <xsl:sequence select="apply($function, $array)"/>
    </xsl:function>
    
    <xsl:function name="xpf:random-number-generator" as="map(xs:string, item())">
        <xsl:param name="exec-context" as="map(*)"/>
        <xsl:sequence select="
            xpe:fn-apply($exec-context, 'random-number-generator', [()])
            "/>
    </xsl:function>
    <xsl:function name="xpf:random-number-generator" as="map(xs:string, item())">
        <xsl:param name="exec-context" as="map(*)"/>
        <xsl:param name="seed" as="xs:anyAtomicType?"/>
        <xsl:variable name="underline-rng" select="random-number-generator($seed)"/>
        <xsl:sequence select="xpe:random-nr-gen-wrapper($underline-rng)"/>
    </xsl:function>
    
    <xsl:function name="xpe:random-nr-gen-wrapper" as="map(xs:string, item())">
        <xsl:param name="underline-random-gen" as="map(xs:string, item())"/>
        <xsl:variable name="next-funct" select="
            function(){xpe:random-nr-gen-wrapper($underline-random-gen?next())}
            "/>
        <!--        map(xs:string, item())-->
        <xsl:variable name="next-funct-return-type" as="element(itemType)">
            <itemType>
                <mapType>
                    <atomic name="xs:string">
                        <xsl:namespace name="xs" select="$build-in-namespaces('xs')"/>
                    </atomic>
                    <itemType/>
                </mapType>
            </itemType>
        </xsl:variable>
        <xsl:variable name="any-seq-type" as="element(itemType)">
            <itemType occurrence="zero-or-more"/>
        </xsl:variable>
        <xsl:variable name="next-funct" select="
            xpe:create-function-item($next-funct, (), (), $next-funct-return-type)
            "/>
        <xsl:variable name="permute-funct" select="
            function($seq){$underline-random-gen?permute($seq)}
            "/>
        <xsl:variable name="permute-funct" select="
            xpe:create-function-item($permute-funct, (), $any-seq-type, $any-seq-type)
            "/>
        
        <xsl:sequence select="
            map{
                'number' : $underline-random-gen?number,
                'next' : $next-funct,
                'permute' : $permute-funct
            }
            "/>
    </xsl:function>
    
<!--    
    Array/Map high-order-functions 
    -->
    <xsl:function name="xpfa:for-each" as="array(*)">
        <xsl:param name="exec-context" as="map(*)"/>
        <xsl:param name="array" as="array(*)"/>
        <!-- function(item()*) as item()* -->
        <xsl:param name="action" as="map(*)"/>
        <xsl:sequence select="array:for-each($array, xpe:raw-function($action))"/>
    </xsl:function>
    <xsl:function name="xpfa:filter" as="array(*)">
        <xsl:param name="exec-context" as="map(*)"/>
        <xsl:param name="array" as="array(*)"/>
        <!-- function(item()*) as xs:boolean -->
        <xsl:param name="function" as="map(*)"/>
        <xsl:sequence select="array:filter($array, xpe:raw-function($function))"/>
    </xsl:function>
    <xsl:function name="xpfa:fold-left" as="item()*">
        <xsl:param name="exec-context" as="map(*)"/>
        <xsl:param name="array" as="array(*)"/>
        <xsl:param name="zero" as="item()*"/>
        <!-- function(item()*, item()*) as item()* -->
        <xsl:param name="function" as="map(*)"/>
        <xsl:sequence select="array:fold-left($array, $zero, xpe:raw-function($function))"/>
    </xsl:function>
    <xsl:function name="xpfa:fold-right" as="item()*">
        <xsl:param name="exec-context" as="map(*)"/>
        <xsl:param name="array" as="array(*)"/>
        <xsl:param name="zero" as="item()*"/>
        <!-- function(item()*, item()*) as item()* -->
        <xsl:param name="function" as="map(*)"/>
        <xsl:sequence select="array:fold-right($array, $zero, xpe:raw-function($function))"/>
    </xsl:function>
    <xsl:function name="xpfa:for-each-pair" as="array(*)">
        <xsl:param name="exec-context" as="map(*)"/>
        <xsl:param name="array1" as="array(*)"/>
        <xsl:param name="array2" as="array(*)"/>
        <!-- function(item()*, item()*) as item()* -->
        <xsl:param name="function" as="map(*)"/>
        <xsl:sequence select="array:for-each-pair($array1, $array2, xpe:raw-function($function))"/>
    </xsl:function>
    <xsl:function name="xpfa:sort" as="array(*)">
        <xsl:param name="exec-context" as="map(*)"/>
        <xsl:param name="array" as="array(*)"/>
        <xsl:param name="collation" as="xs:string?"/>
        <!-- function(item()*) as xs:anyAtomicType* -->
        <xsl:param name="key" as="map(*)"/>
        
        <xsl:sequence select="array:sort($array, $collation, xpe:raw-function($key))"/>
    </xsl:function>
    
    <xsl:function name="xpfm:for-each" as="item()*">
        <xsl:param name="exec-context" as="map(*)"/>
        <xsl:param name="map" as="map(*)"/>
        <!-- function(xs:anyAtomicType, item()*) as item()* -->
        <xsl:param name="action" as="map(*)"/>
        <xsl:sequence select="map:for-each($map, xpe:raw-function($action))"/>
    </xsl:function>
    
    
    <xsl:function name="xpe:is-function" as="xs:boolean" visibility="final">
        <xsl:param name="item" as="item()*"/>
        <xsl:sequence select="
            if ($item instance of map(*)) 
            then ($item?type[. instance of xs:QName] = QName($xpf:namespace-uri, 'function')) 
            else false()
            "/>
    </xsl:function>
    
    <xsl:function name="xpe:raw-function" as="item()" visibility="final">
        <xsl:param name="item" as="item()"/>
        <xsl:sequence select="
            if (xpe:is-function($item)) 
            then $item?function 
            else $item
            "/>
        
    </xsl:function>
    

    
</xsl:stylesheet>