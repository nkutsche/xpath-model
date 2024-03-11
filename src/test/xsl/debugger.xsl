<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:nk="http://www.nkutsche.com/xpath-model" xmlns:math="http://www.w3.org/2005/xpath-functions/math" xmlns:p="http://www.nkutsche.com/xpath-parser" xmlns:r="http://maxtoroq.github.io/rng.xsl" xmlns:xpe="http://www.nkutsche.com/xpath-model/engine" xmlns:map="http://www.w3.org/2005/xpath-functions/map"     xmlns:err="http://www.w3.org/2005/xqt-errors" xmlns:fos="http://www.w3.org/xpath-functions/spec/namespace"
    xmlns:xpt="http://www.nkutsche.com/xmlml/xpath-engine/types" xmlns:array="http://www.w3.org/2005/xpath-functions/array"
    xmlns:test="http://www.nkutsche.com/testing"
    exclude-result-prefixes="#all" version="3.0">
    <xsl:use-package name="http://maxtoroq.github.io/rng-xsl" package-version="*"/>
    
    <xsl:import href="../../main/resources/xsl/xpath-model.xsl"/>
    
    <xsl:output indent="yes"></xsl:output>
    
    <xsl:variable name="add-namespaces" select="
        map{
            'myPrefix' : 'http://example.com/',
            'xpt' : 'http://www.nkutsche.com/xmlml/xpath-engine/types'
        }
        "/>
    <xsl:param name="xpath" as="xs:string"><![CDATA[
            //following-sibling::*/name()
    ]]></xsl:param>
    
    <xsl:variable name="exec-context">
        <asterix-universe>
            <group xml:id="galier">
                <name>Galier</name>
                <character xml:id="ast">
                    <name>Asterix</name>
                    <position>Warrior</position>
                </character>
                <character xml:id="obel">
                    <name>Obelix</name>
                    <position>Menhir supplier</position>
                </character>
                <character xml:id="idf">
                    <name>Idefix</name>
                    <position>Dog of Obelix</position>
                </character>
                <character xml:id="maj">
                    <name>Majestix</name>
                    <position>Chief</position>
                </character>
            </group>
        </asterix-universe>
    </xsl:variable>
    
    <xsl:function name="test:uri-resolver" as="document-node()?">
        <xsl:param name="relative" as="xs:string?"/>
        <xsl:param name="baseUri" as="xs:string"/>
        <xsl:if test="$relative != 'foo.xml'">
            <xsl:document>
                <dummy/>
            </xsl:document>
        </xsl:if>
    </xsl:function>
    
    
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
            'map' : 'http://www.w3.org/2005/xpath-functions/map',
            'array' : 'http://www.w3.org/2005/xpath-functions/array'
            }"/>
        <xsl:variable name="namespaces" select="($add-namespaces, $namespaces) => map:merge()"/>
        <xsl:variable name="xpmodel" select="nk:xpath-model($xpath, map{'namespaces' : $namespaces})"/>
        
<!--        <xsl:variable name="exec-context" select="$exec-context/ works / employee[4]"/>-->
        
        <root>
            <saxon-result>
                <xsl:try>
                    <xsl:variable name="namespace-context" as="element()" exclude-result-prefixes="">
                        <ns xmlns:fn="http://www.w3.org/2005/xpath-functions" xmlns:xs="http://www.w3.org/2001/XMLSchema">
                            <xsl:for-each select="map:keys($namespaces)">
                                <xsl:namespace name="{.}" select="$namespaces(.)"/>
                            </xsl:for-each>
                        </ns>
                    </xsl:variable>
                    <xsl:evaluate xpath="$xpath" context-item="$exec-context" namespace-context="$namespace-context"/>
                    <!--<xsl:sequence select='(concat("one ", ?, " three"), substring-before("one two three", ?), matches(?, "t.*o"), xs:NCName(?))("two")'/>-->
                    <!--<xsl:variable name="funct-sign" select="$function-signatures/fos:functions/fos:function[182]/fos:signatures[1]/fos:proto[2]"/>
                    <xsl:variable name="doubleType" select="$function-signatures/fos:functions/fos:type-model[18]/itemType[1]"/>
                    
                    <xsl:variable name="args" select="[1 to 100, 99 cast as xs:double, 2147483648 cast as xs:double]"/>
                    <xsl:variable name="args" select="trace($args, 'args before')"/>
<!-\-                    <xsl:variable name="args2" select="xpe:prepare-arguments($args, $funct-sign, QName('', 'foo'))"/>-\->
                    <xsl:variable name="args2" select="[$args?1], [()], [()]"/>
                    <xsl:variable name="args2" select="trace($args2, 'args between')"/>
                    <xsl:variable name="args2" select="[$args2?1, $args?2, $args?3]"/>
                    <xsl:variable name="args2" select="trace($args2, 'args after')"/>
                    <xsl:message select="deep-equal($args2, $args)"/>
                    <xsl:sequence select="apply(subsequence#3, $args2)"/>-->
                    
                    <xsl:catch>
                        <error code="{$err:code}" line="{$err:line-number}" base="{$err:module}"><xsl:value-of select="$err:description"/></error>
                    </xsl:catch>
                </xsl:try>
            </saxon-result>
            <exec>
                <xsl:try>
                    <xsl:variable name="result" select="xpe:xpath-evaluate($exec-context, $xpath, 
                        map{
                        'namespaces' : $namespaces,
                        'base-uri' : static-base-uri(),
                        'default-language' : 'en',
                        'uri-resolver' : test:uri-resolver#2
                        }
                        )"/>
                    <result>
                        <xsl:sequence select="$result"/>
                    </result>
                    <type-of>
                        <xsl:copy-of select="xpt:type-of-sequence($result)"/>
                    </type-of>
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
