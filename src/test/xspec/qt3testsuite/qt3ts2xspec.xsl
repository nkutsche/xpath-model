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
    
    <xsl:param name="focus" as="xs:string">fn-abs.*</xsl:param>
    <xsl:param name="dependency-spec" as="xs:string">^XP\d+\+?$</xsl:param>
    
    <xsl:template match="/catalog">
        <x:description stylesheet="{resolve-uri('../../../main/resources/xsl/xpath-model.xsl')}">
            <x:helper package-name="http://maxtoroq.github.io/rng-xsl" package-version="*"/>
            <x:helper stylesheet="{resolve-uri('qt3ts-helper.xsl')}"/>
            
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
            <x:variable name="execution-context" select="xpmt:execution-context(*)">
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
    
    <xsl:template match="test-case" priority="50">
        <xsl:param name="dep-spec" select="dependency[@type = 'spec']" tunnel="yes"/>
        <xsl:variable name="dep-spec-values" select="$dep-spec/@value/tokenize(., '\s')"/>
        <xsl:choose>
            <xsl:when test="
                empty($dep-spec-values) or
                (every $dsv in  $dep-spec-values satisfies matches($dsv, $dependency-spec))">
                <xsl:next-match/>
            </xsl:when>
            <xsl:otherwise/>
            
        </xsl:choose>
    </xsl:template>
    
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
            <x:scenario label="{@name}" catch="true">
                <!--<xsl:if test="tokenize($focus, ',') = @name">
                    <xsl:attribute name="focus" select="''"/>
                </xsl:if>-->
                <xsl:if test="$env/source/@validation = 'strict'">
                    <xsl:attribute name="pending">Ignored as test case seems to be schema-aware.</xsl:attribute>
                </xsl:if>
                <x:variable name="xpath" select="string(.)">
                    <xsl:value-of select="test"/>
                </x:variable>
                <x:variable name="result" select="*">
                    <xsl:copy-of select="xpmt:copy-for-xspec(result)"/>
                </x:variable>
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