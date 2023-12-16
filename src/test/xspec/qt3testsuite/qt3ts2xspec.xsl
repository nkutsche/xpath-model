<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:math="http://www.w3.org/2005/xpath-functions/math"
    xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl"
    xmlns:x="http://www.jenitennison.com/xslt/xspec"
    xmlns:xpe="http://www.nkutsche.com/xpath-model/engine"
    xmlns:xpmt="http://www.nkutsche.com/xpath-model/test-helper"  
    xmlns:map="http://www.w3.org/2005/xpath-functions/map"
    xmlns:qt="http://www.w3.org/2010/09/qt-fots-catalog"
    xpath-default-namespace="http://www.w3.org/2010/09/qt-fots-catalog"
    exclude-result-prefixes="xs math xd"
    version="3.0">
    <xd:doc scope="stylesheet">
        <xd:desc>
            <xd:p><xd:b>Created on:</xd:b> Oct 23, 2023</xd:p>
            <xd:p><xd:b>Author:</xd:b> Nico</xd:p>
            <xd:p></xd:p>
        </xd:desc>
    </xd:doc>
    
    <xsl:param name="focus" as="xs:string">.*</xsl:param>
    
    
    <xsl:variable name="dependency-settings" as="element(xpmt:dependency)*">
        <xpmt:dependency type="spec" match="^XP([1-3]\.?\d\+|31|3\.1)$" only="true"/>
        <xpmt:dependency type="feature" value="fn-load-xquery-module" satisfied="false"/>
        <xpmt:dependency type="feature" value="staticTyping" satisfied="false"/>
        <xpmt:dependency type="feature" value="advanced-uca-fallback" satisfied="false"/>
        <xpmt:dependency type="xml-version" value="1.1" satisfied="false"/>
        <xpmt:dependency type="feature" value="fn-transform-XSLT" satisfied="partial">
            <xpmt:ignore test="fn-transform-err-9">TODO</xpmt:ignore>
            <xpmt:ignore test="fn-transform-err-9a">TODO</xpmt:ignore>
        </xpmt:dependency>
        <xpmt:dependency type="feature" value="remote_http" satisfied="partial">
            <xpmt:ignore test="fn-unparsed-text-054">requires: Feature.STABLE_UNPARSED_TEXT which leads to problems with other test cases...</xpmt:ignore>
            <xpmt:ignore test="fn-unparsed-text-054a">requires: Feature.STABLE_UNPARSED_TEXT which leads to problems with other test cases...</xpmt:ignore>
        </xpmt:dependency>
        <xpmt:dependency>
            <xpmt:ignore test="fn-unparsed-text-056">Saxon-HE throws FOUT1170 instead of FOUT1190!</xpmt:ignore>
            <xsl:if test="not(available-environment-variables() = 'QTTEST')">
                <xpmt:ignore test="fn-available-environment-variables-011">Its hard to ensure that an env variable is set by the calling system...</xpmt:ignore>
            </xsl:if>
        </xpmt:dependency>
        
        
    </xsl:variable>
    
    <xsl:template match="/catalog">
        <x:description stylesheet="{resolve-uri('../../../main/resources/xsl/xpath-model.xsl')}">
            <x:helper package-name="http://maxtoroq.github.io/rng-xsl" package-version="*"/>
            <x:helper stylesheet="{resolve-uri('qt3ts-helper.xsl')}"/>
            
            <x:variable name="fn-transform-workaround" select="false()"/>
            
            <xsl:apply-templates>
                <xsl:with-param name="envs" select="environment" tunnel="yes"/>
            </xsl:apply-templates>
            
        </x:description>
        
    </xsl:template>
    
    <xsl:template match="environment">
        <x:scenario label="{generate-id(.)}" shared="true">
            <x:variable name="sources">
                <xsl:attribute name="select">
                    <xsl:text>(</xsl:text>
                    <xsl:if test="source[@role = '.']">
                        <xsl:text>'</xsl:text>
                        <xsl:value-of select="source[@role = '.']/resolve-uri(@file, base-uri(.))"/>
                        <xsl:text>'</xsl:text>
                    </xsl:if>
                    <xsl:text>)</xsl:text>
                </xsl:attribute>
            </x:variable>
            <x:variable name="context" select="$sources ! doc(.)"/>
            <x:variable name="execution-context" select="xpmt:execution-context(*, $base-uri, $fn-transform-workaround)">
                <xsl:copy-of select="xpmt:copy-for-xspec(.)"/>
            </x:variable>
            <x:call function="xpe:xpath-evaluate">
                <x:param select="$context"/>
                <x:param select="$xpath"/>
                <x:param select="$execution-context"/>
            </x:call>
            <x:expect label="expected compare" test="xpmt:result-compare($result, $x:result)"/>
        </x:scenario>
    </xsl:template>
    
    <xsl:template match="test-set[@file]">
        <xsl:apply-templates select="doc(resolve-uri(@file, base-uri(.)))/*"/>
    </xsl:template>
    
    <xsl:template match="test-set[environment]" priority="50">
        <xsl:param name="envs" as="element(qt:environment)*" tunnel="yes"/>
        <xsl:next-match>
            <xsl:with-param name="envs" select="$envs, environment" tunnel="yes"/>
        </xsl:next-match>
    </xsl:template>

    <xsl:template match="test-set[dependency] | test-case[dependency]" priority="60">
        <xsl:param name="test-dependencies" tunnel="yes" as="element(dependency)*"/>
        <xsl:next-match>
            <xsl:with-param name="test-dependencies" select="$test-dependencies, dependency" tunnel="yes"/>
        </xsl:next-match>
    </xsl:template>
    
    <xsl:template match="test-case" priority="50">
        <xsl:param name="test-dependencies" tunnel="yes" as="element(dependency)*"/>
        <xsl:variable name="focus" select="$focus => tokenize(',')"/>
        <xsl:variable name="focus" select="$focus[. != ''] ! ('^' || . || '$')"/>
        <xsl:choose>
            <xsl:when test="exists($focus) and (every $f in $focus satisfies not(matches(@name, $f)))"/>
            <xsl:when test="not($test-dependencies)">
                <xsl:next-match/>
            </xsl:when>
            <xsl:when test="
                $test-dependencies => xpmt:merge-dependencies() => xpmt:verify-test-dependencies()">
                <xsl:next-match/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:message expand-text="yes">Skiped test case {@name}</xsl:message>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    
    <xsl:function name="xpmt:merge-dependencies" as="element(dependency)*">
        <xsl:param name="test-dependencies" as="element(dependency)*"/>
        <xsl:for-each-group select="$test-dependencies" group-by=" 
            if (@type = 'spec') 
            then ('spec') 
            else (@type || ';' || @value) ">
            <xsl:sequence select="current-group()[last()]"/>
        </xsl:for-each-group> 
    </xsl:function>
    
    <xsl:function name="xpmt:verify-test-dependencies" as="xs:boolean">
        <xsl:param name="test-dependencies" as="element(dependency)*"/>
        <xsl:sequence select="xpmt:verify-test-dependencies($test-dependencies, $dependency-settings)"/>
    </xsl:function>
    
    
    <xsl:function name="xpmt:verify-test-dependencies" as="xs:boolean">
        <xsl:param name="test-dependencies" as="element(dependency)*"/>
        <xsl:param name="dependency-settings" as="element(xpmt:dependency)*"/>
        <xsl:variable name="satisfied" select="every $td in $test-dependencies
            satisfies xpmt:verify-test-dependency($td, $dependency-settings)"/>
        <xsl:choose>
            <xsl:when test="$dependency-settings[@only = 'true']">
                <xsl:sequence select="
                    $satisfied and (
                        every $odps in $dependency-settings[@only = 'true'] 
                        satisfies exists($test-dependencies[xpmt:verify-test-dependency(., $odps, true())])
                    )
                    "/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:sequence select="$satisfied"/>
            </xsl:otherwise>
        </xsl:choose>
        
    </xsl:function>

    <xsl:function name="xpmt:verify-test-dependency" as="xs:boolean">
        <xsl:param name="test-dependency" as="element(dependency)"/>
        <xsl:param name="dependency-settings" as="element(xpmt:dependency)*"/>
        <xsl:sequence select="xpmt:verify-test-dependency($test-dependency, $dependency-settings, false())"/>
    </xsl:function>
    <xsl:function name="xpmt:verify-test-dependency" as="xs:boolean">
        <xsl:param name="test-dependency" as="element(dependency)"/>
        <xsl:param name="dependency-settings" as="element(xpmt:dependency)*"/>
        <xsl:param name="false-if-no-match" as="xs:boolean"/>
        <xsl:variable name="type" select="$test-dependency/@type"/>
        <xsl:variable name="dependency-settings" select="$dependency-settings[@type = $type]"/>
        <xsl:variable name="values" select="
            if ($test-dependency/@type = 'spec') 
            then tokenize($test-dependency/@value, '\s+') 
            else $test-dependency/@value
            "/>
        <xsl:variable name="dependency-settings" select="$dependency-settings[
            if (@match) 
            then some $v in $values
            satisfies matches($v, @match) 
            else ($values = @value)
            ]"/>
        
        <xsl:variable name="test-dep-satisfied" select="($test-dependency/@satisfied, 'true')[1]"/>
        <xsl:variable name="test-dep-satisfied" select="
            if ($test-dep-satisfied = 'true') then ('true', 'partial') else $test-dep-satisfied
            "/>
        <xsl:variable name="dep-settings-satisfied" select="($dependency-settings/@satisfied, 'true')[1]"/>
        
        <xsl:choose>
            <xsl:when test="not($dependency-settings) and $false-if-no-match">
                <xsl:sequence select="false()"/>
            </xsl:when>
            <xsl:when test="not($dependency-settings)">
                <xsl:sequence select="$test-dep-satisfied = 'true'"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:sequence select="$dep-settings-satisfied = $test-dep-satisfied"/>
            </xsl:otherwise>
        </xsl:choose>
        
            
        
    </xsl:function>
    
    <xsl:template match="test-case">
        <xsl:param name="envs" as="element(qt:environment)*" tunnel="yes"/>
        <xsl:variable name="custom-env" select="environment[not(@ref)]"/>
        
        <xsl:apply-templates select="$custom-env"/>
        
        <xsl:variable name="env-ref" select="(environment/@ref, 'empty')[1]"/>
        <xsl:variable name="env" select="
            if ($custom-env) 
            then $custom-env 
            else $envs[@name = $env-ref]
            "/>
        <xsl:if test="$focus = '' or tokenize($focus, ',') = @name or (some $f in $focus satisfies matches(@name, $f))">
            
            <x:scenario label="{@name}: {description}" catch="true">
                <xsl:if test="$env/source/@validation = 'strict'">
                    <xsl:attribute name="pending">Ignored as test case seems to be schema-aware.</xsl:attribute>
                </xsl:if>
                <xsl:variable name="test-name" select="@name"/>
                <xsl:variable name="ignore-reaons" select="$dependency-settings//xpmt:ignore[@test = $test-name]"/>
                <xsl:if test="$ignore-reaons">
                    <xsl:attribute name="pending" expand-text="yes"
                        >Ignored by dependency settings. Reason: {$ignore-reaons}</xsl:attribute>
                </xsl:if>
                <x:variable name="base-uri" select="'{base-uri(.)}'"/>
                <x:variable name="xpath" select="string(.)">
                    <xsl:value-of select="test"/>
                </x:variable>
                <x:variable name="result" select="*">
                    <xsl:copy-of select="xpmt:copy-for-xspec(result)"/>
                </x:variable>
                <xsl:if test="
                    dependency[@type = 'feature'][(@satisfied, 'true')[1]= 'true']/@value = 'fn-transform-XSLT'
                    ">
                    <x:variable name="fn-transform-workaround" select="true()"/>
                </xsl:if>
                <xsl:if test="$env">
                    <x:like label="{$env[last()]/generate-id(.)}"/>
                </xsl:if>
            </x:scenario>
            
        </xsl:if>
    </xsl:template>
    
    <xsl:template match="text()[normalize-space() = '']"/>
        
    
    
    <xsl:template match="description"/>
    
    <xsl:mode name="xpmt:copy-for-xspec" on-no-match="shallow-copy"/>
    
    <xsl:function name="xpmt:copy-for-xspec" as="node()*">
        <xsl:param name="node" as="node()*"/>
        <xsl:apply-templates select="$node" mode="xpmt:copy-for-xspec"/>
    </xsl:function>
    
    <xsl:template match="environment" mode="xpmt:copy-for-xspec">
        <xsl:copy>
            <xsl:attribute name="xml:base" select="base-uri(.)"/>
            <xsl:apply-templates select="@*" mode="#current"/>
            <xsl:apply-templates select="node()" mode="#current"/>
        </xsl:copy>
    </xsl:template>
    
    <xsl:template match="@*" mode="xpmt:copy-for-xspec">
        <xsl:attribute name="{name()}" select="replace(., '(\{|\})', '$1$1')"/>
    </xsl:template>
    
    
</xsl:stylesheet>