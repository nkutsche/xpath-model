<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:math="http://www.w3.org/2005/xpath-functions/math"
    xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl"
    xmlns:xpmt="http://www.nkutsche.com/xpath-model/test-helper"  
    xmlns:qt="http://www.w3.org/2010/09/qt-fots-catalog"
    xmlns:map="http://www.w3.org/2005/xpath-functions/map"
    xmlns:xpe="http://www.nkutsche.com/xpath-model/engine"
    exclude-result-prefixes="xs math xd"
    version="3.0">
    <xd:doc scope="stylesheet">
        <xd:desc>
            <xd:p><xd:b>Created on:</xd:b> Oct 23, 2023</xd:p>
            <xd:p><xd:b>Author:</xd:b> Nico</xd:p>
            <xd:p></xd:p>
        </xd:desc>
    </xd:doc>
    <!--<xsl:decimal-format name="ch" decimal-separator="·" grouping-separator="ʹ"/>
    <xsl:decimal-format name="fortran" exponent-separator="E"/>
    <xsl:decimal-format name="myminus" minus-sign="_"/>
    <xsl:decimal-format xmlns:foo="http://foo.ns" name="foo:decimal1" decimal-separator="!" grouping-separator="*"/>
    <xsl:decimal-format name="decimal1" decimal-separator="*" grouping-separator="!"/>
    <xsl:decimal-format name="decimal2" zero-digit="0" NaN="not a number" decimal-separator="."/>
    <xsl:decimal-format xmlns:a="http://a.ns/" name="a:test" decimal-separator="," grouping-separator="."/>-->
    
    <xsl:variable name="predef-ns" as="map(*)">
        <xsl:map>
            <xsl:map-entry key="'fn'" select="'http://www.w3.org/2005/xpath-functions'"/>
            <xsl:map-entry key="'xs'" select="'http://www.w3.org/2001/XMLSchema'"/>
            <xsl:map-entry key="'map'" select="'http://www.w3.org/2005/xpath-functions/map'"/>
            <xsl:map-entry key="'array'" select="'http://www.w3.org/2005/xpath-functions/array'"/>
            <xsl:map-entry key="'math'" select="'http://www.w3.org/2005/xpath-functions/math'"/>
            <xsl:map-entry key="'xpe'" select="'http://www.nkutsche.com/xpath-model/engine'"/>
            <!-- TODO: needs to be retrieved from env!!! -->
            <xsl:map-entry key="'j'" select="'http://www.w3.org/2005/xpath-functions'"/>
        </xsl:map>
    </xsl:variable>
    <xsl:variable name="predef-nscontext-for-saxon" as="element()">
        <dummy>
            <xsl:for-each select="$predef-ns => map:keys()">
                <xsl:namespace name="{.}" select="$predef-ns(.)"/>
            </xsl:for-each>
        </dummy>
    </xsl:variable>
    
    <xsl:function name="xpmt:execution-context" as="map(*)">
        <xsl:param name="environment" as="element(qt:environment)"/>
        <xsl:param name="base-uri" as="xs:string"/>
        <xsl:sequence select="xpmt:execution-context($environment, $base-uri, false())"/>
    </xsl:function>
    <xsl:function name="xpmt:execution-context" as="map(*)">
        <xsl:param name="environment" as="element(qt:environment)"/>
        <xsl:param name="base-uri" as="xs:string"/>
        <xsl:param name="transform-workaround" as="xs:boolean"/>
        <xsl:map>
            <xsl:map-entry key="'namespaces'">
                <xsl:variable name="env-ns" as="map(*)">
                    <xsl:map>
                        <xsl:apply-templates select="$environment/qt:namespace" mode="xpmt:execution-context"/>
                    </xsl:map>
                </xsl:variable>
                <xsl:sequence select="($predef-ns, $env-ns) => map:merge(map{'duplicates' : 'use-last'})"/>
            </xsl:map-entry>
            <xsl:map-entry key="'default-language'" select="'en'"/>
            <xsl:if test="$environment/qt:collection">
                <xsl:map-entry key="'uri-collection-resolver'" 
                    select="xpmt:env-collection-resolver(?,?, $environment/qt:collection)"/>
            </xsl:if>
            <xsl:if test="$environment/qt:source">
                <xsl:map-entry key="'uri-resolver'" 
                    select="xpmt:env-uri-resolver(?,?, $environment/qt:source, $transform-workaround)"/>
            </xsl:if>
            <xsl:if test="$environment/qt:resource">
                <xsl:map-entry key="'unparsed-text-resolver'" 
                    select="xpmt:env-unparsed-text-resolver(?,?, ?, $environment/qt:resource)"/>
            </xsl:if>
            <xsl:if test="$environment/qt:param | $environment/qt:source[matches(@role, '^\$')]">
                <xsl:map-entry key="'variable-context'">
                    <xsl:map>
                        <xsl:apply-templates select="
                            $environment/qt:param | $environment/qt:source[matches(@role, '^\$')]
                            " mode="xpmt:execution-context"/>
                    </xsl:map>
                </xsl:map-entry>
            </xsl:if>
            <xsl:if test="$environment/qt:decimal-format">
                <xsl:map-entry key="'decimal-formats'">
                    <xsl:for-each select="$environment/qt:decimal-format">
                        <xsl:variable name="df" select="."/>
                        <xsl:map>
                            <xsl:for-each select="@*">
                                <xsl:map-entry key="name()" select="
                                    if (name() = 'name') 
                                    then if (contains(., ':')) 
                                        then resolve-QName(., $df) 
                                        else QName('', .) 
                                    else string(.)
                                    "/>
                            </xsl:for-each>
                        </xsl:map>
                    </xsl:for-each>
                </xsl:map-entry>
            </xsl:if>

            <xsl:variable name="default-collation" select="$environment/qt:collation[@default = 'true']"/>
            <xsl:if test="$default-collation">
                <xsl:map-entry key="'default-collation'">
                    <xsl:sequence select="$default-collation/@uri"/>
                </xsl:map-entry>
            </xsl:if>
            
            <xsl:variable name="base-uri" select="($environment/qt:static-base-uri/@uri, $base-uri)[1]"/>
            <xsl:map-entry key="'base-uri'" select="
                    if ($base-uri = '#UNDEFINED') 
                    then () 
                    else xs:anyURI($base-uri)
                "/>
            
            <xsl:map-entry key="'environment-variables'" 
                select="map{
                    'QTTEST' : '42',
                    'QTTEST2' : 'other',
                    'QTTESTEMPTY' : ''
                }"/>
            
        </xsl:map>
    </xsl:function>
    
    
    
   <!-- <xsl:function name="xpf:format-number" xmlns:xpf="http://www.nkutsche.com/xmlml/xpath-engine/functions" 
        as="xs:string">
        <xsl:param name="exec-context" as="map(*)"/>
        <xsl:param name="value" as="xs:numeric?"/>
        <xsl:param name="picture" as="xs:string"/>
        <xsl:sequence select="xpf:format-number($exec-context, $value, $picture, ())"/>
    </xsl:function>
    <xsl:function name="xpf:format-number" xmlns:xpf="http://www.nkutsche.com/xmlml/xpath-engine/functions" 
        as="xs:string">
        <xsl:param name="exec-context" as="map(*)"/>
        <xsl:param name="value" as="xs:numeric?"/>
        <xsl:param name="picture" as="xs:string"/>
        <xsl:param name="decimal-format-name" as="xs:string?"/>
        
        <xsl:variable name="decimal-formats" select="$exec-context?decimal-formats"/>
        <xsl:choose>
            <xsl:when test="$decimal-formats">
                <xsl:variable name="stylesheet">
                    <xsl:element name="xsl:stylesheet">
                        <xsl:attribute name="version" select="'3.0'"/>
                        <xsl:for-each select="$decimal-formats">
                            <xsl:element name="xsl:decimal-format">
                                <xsl:copy-of select="@* | namespace::*"/>
                            </xsl:element>
                        </xsl:for-each>
                        <xsl:sequence select="doc(static-base-uri()) ! id('format-number', .)"/>
                    </xsl:element>
                </xsl:variable>
                <xsl:sequence select="transform(map{
                    'stylesheet-node' : $stylesheet,
                    'delivery-format' : 'raw',
                    'function-params' : [$value, $picture, $decimal-format-name],
                    'initial-function' : xs:QName('xpmt:format-number')
                    })?output"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:sequence select="format-number($value, $picture, $decimal-format-name)"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>
    
    <xsl:function name="xpmt:format-number" as="xs:string" xml:id="format-number" visibility="public">
        <xsl:param name="value" as="xs:numeric?"/>
        <xsl:param name="picture" as="xs:string"/>
        <xsl:param name="decimal-format-name" as="xs:string?"/>
        <xsl:sequence select="format-number($value, $picture, $decimal-format-name)"/>
    </xsl:function>-->
    
    <!--<xsl:function name="xpmt:external-invoker" as="function(*)">
        <xsl:param name="decimal-formats" as="element(qt:decimal-format)+"/>
        
        
    </xsl:function>-->
    
    <xsl:function name="xpmt:env-collection-resolver" as="xs:anyURI*">
        <xsl:param name="relative" as="xs:string?"/>
        <xsl:param name="baseUri" as="xs:string"/>
        <xsl:param name="collections" as="element(qt:collection)+"/>
        <xsl:sequence select="xpmt:env-uri-mapper($relative, $baseUri, $collections)"/>
    </xsl:function>

    <xsl:function name="xpmt:env-uri-mapper" as="xs:anyURI*">
        <xsl:param name="relative" as="xs:string?"/>
        <xsl:param name="baseUri" as="xs:string"/>
        <xsl:param name="sources" as="element()+"/>
        
        
        <xsl:variable name="resolved" select=" if ($relative = '' or empty($relative)) then '' else resolve-uri($relative, $baseUri)"/>
        <xsl:variable name="source" select="
            if ($relative = '' or empty($relative)) 
            then $sources[@uri = ''] 
            else (
                $sources[resolve-uri(@uri, base-uri(.)) = $resolved]
            )
            "/>
        <xsl:variable name="source" select="
            if ($source/self::qt:collection) 
            then ($source/qt:source) 
            else ($source)
            "/>
        <xsl:sequence select="
            if ($source) 
            then $source/resolve-uri(@file, base-uri(.))
            else $resolved[. != '']
            "/>
        
    </xsl:function>
    
    <xsl:function name="xpmt:env-uri-resolver" as="document-node()?">
        <xsl:param name="relative" as="xs:string?"/>
        <xsl:param name="baseUri" as="xs:string"/>
        <xsl:param name="sources" as="element(qt:source)+"/>
        <xsl:param name="transform-workaround" as="xs:boolean"/>
        
        <xsl:variable name="base-uri" select="resolve-uri($relative, $baseUri)"/>
        <xsl:variable name="uris" select="xpmt:env-uri-mapper($relative, $baseUri, $sources)"/>
        <xsl:variable name="docs" select="$uris ! (
            if ($transform-workaround) 
            then (unparsed-text(.) => parse-xml() => xpmt:attach-base-uri($base-uri)) 
            else doc(.))"/>
        <xsl:sequence select="$docs"/>
    </xsl:function>
    
    
    
    <xsl:function name="xpmt:attach-base-uri" as="document-node()">
        <xsl:param name="document" as="document-node()"/>
        <xsl:param name="base-uri" as="xs:string"/>
        <xsl:variable name="copysheet" as="xs:string">
            <![CDATA[
            <xsl:stylesheet version="3.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"><xsl:mode on-no-match="shallow-copy"/></xsl:stylesheet>
            ]]>
        </xsl:variable>
        <xsl:variable name="result" select="transform(map{
            'source-node' : $document,
            'stylesheet-text' : $copysheet,
            'base-output-uri' : $base-uri
            })($base-uri)
            "/>
        <xsl:sequence select="$result"/>
    </xsl:function>
    
    <xsl:function name="xpmt:env-unparsed-text-resolver" as="xs:string?">
        <xsl:param name="relative" as="xs:string?"/>
        <xsl:param name="baseUri" as="xs:string"/>
        <xsl:param name="encoding" as="xs:string?"/>
        <xsl:param name="sources" as="element(qt:resource)+"/>
        
        <xsl:if test="exists($relative)">
            <xsl:variable name="resolved" select=" if ($relative = '') then ('', resolve-uri($relative, $baseUri)) else resolve-uri($relative, $baseUri)"/>
            <xsl:variable name="source" select="$sources[resolve-uri(@uri, base-uri(.)) = $resolved]"/>
            <xsl:variable name="encoding" select="($source/@encoding, $encoding)[1]"/>
            <xsl:variable name="resolved" select="($source/resolve-uri(@file, base-uri(.)), $resolved)[1]"/>
            <xsl:sequence select="
                if (empty($encoding)) 
                then unparsed-text($resolved) 
                else unparsed-text($resolved, $encoding)
                "/>
        </xsl:if>
        
    </xsl:function>
    
    <xsl:template match="*" mode="xpmt:execution-context"/>
    
    <xsl:template match="qt:namespace" mode="xpmt:execution-context">
        <xsl:map-entry key="string(@prefix)" select="string(@uri)"/>
    </xsl:template>
    
    <xsl:template match="qt:static-base-uri" mode="xpmt:execution-context">
        <xsl:map-entry key="'base-uri'" select="string(@uri)"/>
    </xsl:template>
    
    <xsl:template match="qt:param[@name][@select]" mode="xpmt:execution-context">
        <xsl:variable name="name" select="@name"/>
        <xsl:variable name="prefix" select=" substring-before($name, ':')"/>
        <xsl:variable name="ns-uri" select="if (contains($name, ':')) then namespace-uri-for-prefix($prefix, .) else ''"/>
        <xsl:map-entry key="QName($ns-uri, $name)">
            <xsl:evaluate xpath="@select" namespace-context="$predef-nscontext-for-saxon"/>
        </xsl:map-entry>
    </xsl:template>

    <xsl:template match="qt:source[matches(@role, '^\$')]" mode="xpmt:execution-context">
        <xsl:variable name="name" select="replace(@role, '^\$', '')"/>
        <xsl:variable name="prefix" select=" substring-before($name, ':')"/>
        <xsl:variable name="ns-uri" select="if (contains($name, ':')) then namespace-uri-for-prefix($prefix, .) else ''"/>
        <xsl:variable name="location" select="resolve-uri(@file, base-uri(.))"/>
        <xsl:variable name="base-uri" select="(@uri, $location)[1]"/>
        <xsl:map-entry key="QName($ns-uri, $name)">
            <xsl:sequence select="doc($location) => xpmt:attach-base-uri($base-uri)"/>
        </xsl:map-entry>
    </xsl:template>
    
    
    <xsl:function name="xpmt:result-compare" as="xs:boolean">
        <xsl:param name="expected" as="element(qt:result)"/>
        <xsl:param name="result" as="item()*"/>
        
        <xsl:apply-templates select="$expected/*" mode="xpmt:result-compare">
            <xsl:with-param name="result" select="$result" tunnel="yes"/>
        </xsl:apply-templates>
    </xsl:function>
    
    <xsl:template match="qt:all-of" mode="xpmt:result-compare" as="xs:boolean">
        <xsl:variable name="sub-results" as="xs:boolean*">
            <xsl:apply-templates mode="#current"/>
        </xsl:variable>
        <xsl:variable name="result" select="every $sr in $sub-results satisfies $sr"/>
        <xsl:if test="not($result)">
            <xsl:message select="$sub-results"/>
        </xsl:if>
        <xsl:sequence select="$result"/>
    </xsl:template>

    <xsl:template match="qt:any-of" mode="xpmt:result-compare" as="xs:boolean">
        <xsl:variable name="sub-results" as="xs:boolean*">
            <xsl:apply-templates mode="#current"/>
        </xsl:variable>
        <xsl:sequence select="some $sr in $sub-results satisfies $sr"/>
    </xsl:template>
    
    <xsl:template match="qt:assert-empty | qt:assert-string-value | qt:assert-true | qt:assert-false" priority="100" mode="xpmt:result-compare" as="xs:boolean">
        <xsl:param name="result" as="item()*" tunnel="yes"/>
        <xsl:choose>
            <xsl:when test="$result instance of map(*)">
                <xsl:sequence select="false()"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:next-match/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <xsl:template match="qt:assert-count" mode="xpmt:result-compare" as="xs:boolean">
        <xsl:param name="result" as="item()*" tunnel="yes"/>
        <xsl:sequence select="count($result) = xs:integer(.)"/>
    </xsl:template>

    <xsl:template match="qt:assert-empty" mode="xpmt:result-compare" as="xs:boolean">
        <xsl:param name="result" as="item()*" tunnel="yes"/>
        <xsl:sequence select="empty($result)"/>
    </xsl:template>

    <xsl:template match="qt:assert-deep-eq" mode="xpmt:result-compare" as="xs:boolean">
        <xsl:param name="result" as="item()*" tunnel="yes"/>
        <xsl:variable name="compare" as="item()*">
            <xsl:evaluate xpath="." namespace-context="$predef-nscontext-for-saxon"/>
        </xsl:variable>
        <xsl:sequence select="
            deep-equal($result, $compare)"/>
    </xsl:template>

    <xsl:template match="qt:assert-eq" mode="xpmt:result-compare" as="xs:boolean">
        <xsl:param name="result" as="item()*" tunnel="yes"/>
        <xsl:variable name="compare" as="item()*">
            <xsl:evaluate xpath="." namespace-context="$predef-nscontext-for-saxon"/>
        </xsl:variable>
        <xsl:try>
            <xsl:sequence select="$result = $compare"/>
            <xsl:catch xmlns:err="http://www.w3.org/2005/xqt-errors">
                <xsl:message select="$err:description"/>
                <xsl:sequence select="false()"/>
            </xsl:catch>
        </xsl:try>
    </xsl:template>

    <xsl:template match="qt:assert" mode="xpmt:result-compare" as="xs:boolean">
        <xsl:param name="result" as="item()*" tunnel="yes"/>
        <xsl:try>
            <xsl:variable name="compare" as="item()*">
                <xsl:evaluate xpath="." namespace-context="$predef-nscontext-for-saxon" with-params="
                        map{QName('', 'result') : $result}
                    "/>
            </xsl:variable>
            <xsl:sequence select="boolean($compare)"/>
            <xsl:catch xmlns:err="http://www.w3.org/2005/xqt-errors">
                <xsl:message select="'MESSAGE: ' || $err:description"/>
                <xsl:sequence select="false()"/>
            </xsl:catch>
        </xsl:try>
    </xsl:template>

    <xsl:template match="qt:assert-permutation" mode="xpmt:result-compare" as="xs:boolean">
        <xsl:param name="result" as="item()*" tunnel="yes"/>
        <xsl:variable name="compare" as="item()*">
            <xsl:evaluate xpath="." namespace-context="$predef-nscontext-for-saxon"/>
        </xsl:variable>
        <xsl:sequence select="xpmt:assert-permutation($result, $compare)"/>
    </xsl:template>
    
    <xsl:function name="xpmt:assert-permutation" as="xs:boolean">
        <xsl:param name="result" as="item()*"/>
        <xsl:param name="compare" as="item()*"/>
        <xsl:variable name="item-count" select="count($result)"/>
        <xsl:choose>
            <xsl:when test="$item-count != count($compare)">
                <xsl:sequence select="false()"/>
            </xsl:when>
            <xsl:when test="$item-count = 0">
                <xsl:sequence select="true()"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:variable name="head" select="head($result)"/>
                <xsl:variable name="index-of" select="
                    for $i in (1 to $item-count) 
                    return if(deep-equal($head, $compare[$i])) then $i else ()
                    "/>
                <xsl:variable name="index-of" select="$index-of[1]"/>
                <xsl:sequence select="
                    if (empty($index-of)) 
                    then false() 
                    else xpmt:assert-permutation(tail($result), $compare[position() != $index-of])
                    "/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>

    <xsl:template match="qt:assert-string-value[@normalize-space = 'true']" mode="xpmt:result-compare" as="xs:boolean">
        <xsl:param name="result" as="item()*" tunnel="yes"/>
        <xsl:variable name="result" select="$result"/>
        <xsl:variable name="result" select="$result  ! normalize-space(string(.))[. != '']"/>
        <xsl:next-match>
            <xsl:with-param name="result" select="$result" tunnel="yes"/>
            <xsl:with-param name="expected" select="normalize-space(.)" tunnel="yes"/>
        </xsl:next-match>
    </xsl:template>
    
    <xsl:template match="qt:assert-string-value" mode="xpmt:result-compare" as="xs:boolean">
        <xsl:param name="result" as="item()*" tunnel="yes"/>
        <xsl:param name="expected" select="." tunnel="yes"/>
        <xsl:sequence select="
            if ($result instance of function(*)+) 
            then 
            false() 
            else 
            ($result => string-join(' ')) = $expected
                "/>
    </xsl:template>

    <xsl:template match="qt:assert-true" mode="xpmt:result-compare" as="xs:boolean">
        <xsl:param name="result" as="item()*" tunnel="yes"/>
        <xsl:sequence select="$result instance of xs:boolean and $result"/>
    </xsl:template>

    <xsl:template match="qt:assert-false" mode="xpmt:result-compare" as="xs:boolean">
        <xsl:param name="result" as="item()*" tunnel="yes"/>
        <xsl:sequence select="$result instance of xs:boolean and not($result)"/>
    </xsl:template>
    
    <xsl:template match="qt:not" mode="xpmt:result-compare" as="xs:boolean">
        <xsl:variable name="content" as="xs:boolean">
            <xsl:apply-templates select="*" mode="#current"/>
        </xsl:variable>
        <xsl:sequence select="not($content)"/>
    </xsl:template>
    
    <xsl:template match="qt:assert-type" mode="xpmt:result-compare" as="xs:boolean">
        <xsl:param name="result" as="item()*" tunnel="yes"/>
        
        <!--        
            Exception for results which are representations of functions, but implemented as map(*)
        -->
        
        <xsl:variable name="context" select="map{
            'variable-context' : map{QName('', 'result') : $result},
            'namespaces' : $predef-ns
            }"/>
        
        <xsl:variable name="xpath" select="'$result instance of ' || ."/>
        <xsl:sequence select="xpe:xpath-evaluate((), $xpath, $context)"/>
        
    </xsl:template>
    
    <xsl:template match="qt:error" mode="xpmt:result-compare" as="xs:boolean">
        <xsl:param name="result" as="item()*" tunnel="yes"/>
        <xsl:choose>
            <xsl:when test="$result instance of map(*) and $result?err instance of map(*)">
                <xsl:variable name="code" select="$result?err?code" as="xs:QName"/>
                <xsl:sequence select="
                    if (@code = '*') 
                    then 
                        true() 
                    else
                    if (matches(@code, '^Q\{.*\}'))
                    then 
                        local-name-from-QName($code) = replace(@code, '^Q\{(.*)\}(.*)', '$2')
                        and namespace-uri-from-QName($code) = replace(@code, '^Q\{(.*)\}(.*)', '$1')
                    else
                        local-name-from-QName($code) = @code
                        and namespace-uri-from-QName($code) = 'http://www.w3.org/2005/xqt-errors'
                    "/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:sequence select="false()"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <xsl:template match="qt:assert-xml[@file]" mode="xpmt:result-compare" priority="10" as="xs:boolean">
        <xsl:variable name="text" select="unparsed-text(resolve-uri(@file, base-uri(.)))"/>
        <xsl:next-match>
            <xsl:with-param name="xml" select="parse-xml-fragment($text)"/>
        </xsl:next-match>
    </xsl:template>
    
    <xsl:template match="qt:assert-xml" mode="xpmt:result-compare" as="xs:boolean">
        <xsl:param name="result" as="item()*" tunnel="yes"/>
        <xsl:param name="xml" select="parse-xml-fragment(replace(., '^\s+|\s+$', ''))" as="node()*"/>
        
        
        <xsl:sequence select="
            if ($result instance of document-node()) 
            then xpmt:xml-equal($result, $xml, @ignore-prefixes = 'true') 
            else if ($result instance of node()*) 
            then xpmt:xml-equal($result, $xml/node(), @ignore-prefixes = 'true') 
            else false()
            "/>
        
    </xsl:template>
    
    <xsl:function name="xpmt:xml-equal" as="xs:boolean">
        <xsl:param name="result" as="node()*"/>
        <xsl:param name="compare" as="node()*"/>
        <xsl:param name="ignore-prefix" as="xs:boolean"/>
        <xsl:sequence select="xpmt:xml-equal($result, $compare, $ignore-prefix, false())"/>
    </xsl:function>
    
    <xsl:function name="xpmt:xml-equal" as="xs:boolean">
        <xsl:param name="result" as="node()*"/>
        <xsl:param name="compare" as="node()*"/>
        <xsl:param name="ignore-prefix" as="xs:boolean"/>
        <xsl:param name="unordered" as="xs:boolean"/>
        
        <xsl:variable name="sorts" select="function($n){name($n)}"/>
        <xsl:variable name="sorting" select="sort(?, (), $sorts)"/>
        
        <xsl:variable name="node-count" select="count($result)"/>
        <xsl:variable name="compare-count" select="count($compare)"/>
        <xsl:choose>
            <xsl:when test="$unordered">
                <xsl:sequence select="xpmt:xml-equal($sorting($result), $sorting($compare), $ignore-prefix)"/>
            </xsl:when>
            <xsl:when test="$node-count ne $compare-count">
                <xsl:message select="'Different node count: ' || ($node-count - $compare-count)"/>
                <xsl:message select=" if ($compare-count gt $node-count) 
                    then ('Missing node at ' || path($compare[position() = $node-count + 1])) 
                    else ('Unexpected node at ' || path($result[position() = $compare-count + 1])) 
                    "/>
                <xsl:sequence select="false()"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:sequence select="
                    every $i in (1 to $node-count)
                    satisfies
                        xpmt:node-equal($result[$i], $compare[$i], $ignore-prefix)
                    "/>
            </xsl:otherwise>
        </xsl:choose>
        
        
    </xsl:function>
    
    <xsl:function name="xpmt:node-equal" as="xs:boolean">
        <xsl:param name="result" as="node()"/>
        <xsl:param name="compare" as="node()"/>
        <xsl:param name="ignore-prefix" as="xs:boolean"/>
        <xsl:variable name="result-type" select="xpmt:node-type($result)"/>
        <xsl:variable name="expect-type" select="xpmt:node-type($compare)"/>
        <xsl:variable name="type-equal" select="$result-type = $expect-type"/>
        <xsl:variable name="ln-equal" select="local-name($result) = local-name($compare)"/>
        <xsl:variable name="ns-equal" select="namespace-uri($result) = namespace-uri($compare)"/>
        <xsl:variable name="name-equal" select="
            if ($ignore-prefix) then true() else name($result) = name($compare)
            "/>
        
        <xsl:variable name="content-equal" select="
            if ($result-type = ('element', 'document-node')) 
            then (
                xpmt:xml-equal($result/node(), $compare/node(), $ignore-prefix)
                and 
                xpmt:xml-equal($result/@*, $compare/@*, $ignore-prefix, true())
            ) 
            else if ($result-type = 'document-node') 
            then (
                xpmt:xml-equal($result/node(), $compare/node(), $ignore-prefix)
            ) 
            else true()
            "/>
        
        <xsl:variable name="is-equal" select="$type-equal and $ln-equal and $ns-equal and $name-equal and $content-equal"/>
        
        <xsl:if test="not($is-equal)">
            <xsl:message select="'Unequal at: ' || path($result) || ' vs ' || path($compare)"/>
            <xsl:message select="
                    ('They have different types; expected:' || $expect-type || ', found: ' || $result-type)[not($type-equal)],
                    ('They have different local names; expected: ' || local-name($compare) || ', found: ' || local-name($result))[not($ln-equal)],
                    ('They are in different namespaces; expected: ' || namespace-uri($compare) || ', found: ' || namespace-uri($result))[not($ns-equal)],
                    ('They have different content')[not($content-equal)]
                "/>
        </xsl:if>
        
        <xsl:sequence select="$is-equal"/>
    </xsl:function>
    
    <xsl:function name="xpmt:node-type" as="xs:string">
        <xsl:param name="node" as="node()"/>
        <xsl:sequence select="
            if ($node instance of document-node()) 
            then 'document-node' 
            else 
            if ($node instance of element()) 
            then 'element' 
            else 
            if ($node instance of attribute()) 
            then 'attribute' 
            else 
            if ($node instance of text()) 
            then 'text' 
            else 
            if ($node instance of comment()) 
            then 'comment' 
            else 
            if ($node instance of processing-instruction()) 
            then 'processing-instruction' 
            else 
            if ($node instance of namespace-node()) 
            then 'namespace-node' 
            else 
                'unknown'
            "/>
    </xsl:function>
    

    <xsl:template match="qt:*" mode="xpmt:result-compare" as="xs:boolean">
        <xsl:param name="result" as="item()*" tunnel="yes"/>
        <xsl:message expand-text="yes">Unsupported result requirement {name()}</xsl:message>
        <xsl:sequence select="false()"/>
    </xsl:template>
    
    <xsl:template match="text()" mode="xpmt:result-compare" priority="-10"/>
        
    
    
    
</xsl:stylesheet>