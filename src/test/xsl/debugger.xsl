<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:nk="http://www.nkutsche.com/xpath-model" xmlns:math="http://www.w3.org/2005/xpath-functions/math" xmlns:p="http://www.nkutsche.com/xpath-parser" xmlns:r="http://maxtoroq.github.io/rng.xsl" xmlns:xpe="http://www.nkutsche.com/xpath-model/engine" xmlns:map="http://www.w3.org/2005/xpath-functions/map"
    xmlns:err="http://www.w3.org/2005/xqt-errors"
    exclude-result-prefixes="#all" version="3.0">
    <xsl:use-package name="http://maxtoroq.github.io/rng-xsl" package-version="*"/>
    
    <xsl:import href="../../main/resources/xsl/xpath-model.xsl"/>
    
    <xsl:output indent="yes"></xsl:output>
    
    
    <xsl:param name="xpath" as="xs:string"><![CDATA[
       trace(fn:number(trace(xs:float("-3.4028235E38"))), 'from-float') eq trace(-3.4028234663852885E38, 'from-literal')
    ]]></xsl:param>
    
<!--    
    3.4028234663852885E38
    3.4028234663852882E38
    -->
    
    <xsl:variable name="exec-context" select="()">
        <!--<xsl:sequence select="doc('file:/C:/Users/Nico/Work/Intern/XPath-Model/target/qt3-testsuite/docs/works-mod.xml')"/>-->
    </xsl:variable>
    
    <xsl:variable name="model" as="element(expr)">
        <expr>
            <operation type="arrow">
                <arg>
                    <operation type="sequence">
                        <arg>
                            <string value="3"/>
                        </arg>
                        <comma/>
                        <arg>
                            <string value="2"/>
                        </arg>
                        <comma/>
                        <arg>
                            <string value="1"/>
                        </arg>
                    </operation>
                </arg>
                <arrow/>
                <function-call>
                    <function>
                        <operation type="postfix">
                            <arg>
                                <function name="string-join" arity="1"/>
                            </arg>
                            <function-call>
                                <arg role="placeholder"/>
                            </function-call>
                        </operation>
                    </function>
                </function-call>
            </operation>
        </expr>
    </xsl:variable>
    
    <xsl:template match="/">
        <xsl:variable name="namespaces" select="map{
            'fn' : 'http://www.w3.org/2005/xpath-functions',
            'xs' : 'http://www.w3.org/2001/XMLSchema',
            'map' : 'http://www.w3.org/2005/xpath-functions/map'
            }"/>
        <xsl:variable name="xpmodel" select="nk:xpath-model($xpath, map{'namespaces' : $namespaces})"/>
        <root>
            <saxon-result>
                <xsl:try>
                    <xsl:variable name="namespace-context" as="element()" exclude-result-prefixes="">
                        <ns xmlns:fn="http://www.w3.org/2005/xpath-functions" xmlns:xs="http://www.w3.org/2001/XMLSchema">
                            <xsl:namespace name="xs">http://www.w3.org/2001/XMLSchema</xsl:namespace>
                        </ns>
                    </xsl:variable>
<!--                    <xsl:evaluate xpath="$xpath" context-item="$exec-context" namespace-context="$namespace-context"/>-->
                    <xsl:sequence select="
                        trace(number(trace(xs:float('-3.4028235E38')))) eq trace(-3.4028234663852885E38)
                        "/>
                    <xsl:catch>
                        <error code="{$err:code}" line="{$err:line-number}" base="{$err:module}"><xsl:value-of select="$err:description"/></error>
                    </xsl:catch>
                </xsl:try>
            </saxon-result>
            <exec>
                <xsl:try>
                    <xsl:sequence select="xpe:xpath-evaluate($exec-context, $xpath, 
                        map{
                            'namespaces' : $namespaces,
                            'base-uri' : static-base-uri()
                        }
                        )"/>
                    <xsl:catch>
                        <error code="{$err:code}" line="{$err:line-number}" base="{$err:module}"><xsl:value-of select="$err:description"/></error>
                    </xsl:catch>
                </xsl:try>
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
