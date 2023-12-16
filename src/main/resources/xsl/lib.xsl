<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:nk="http://www.nkutsche.com/xpath-model" xmlns:math="http://www.w3.org/2005/xpath-functions/math" xmlns:p="http://www.nkutsche.com/xpath-parser" xmlns:r="http://maxtoroq.github.io/rng.xsl" xmlns:map="http://www.w3.org/2005/xpath-functions/map" exclude-result-prefixes="#all" version="3.0">
    
    <xsl:function name="nk:xpath-to-xml-comment" as="xs:string">
        <xsl:param name="comment-content" as="xs:string"/>
        <xsl:sequence select="
            $comment-content 
            => nk:escape-xml-comment-content() 
            => nk:unescape-xpath-comment-content()
            "/>
    </xsl:function>
    
    <xsl:function name="nk:xml-to-xpath-comment" as="xs:string">
        <xsl:param name="comment-content" as="xs:string"/>
        <xsl:sequence select="
            $comment-content 
            => nk:escape-xpath-comment-content()
            => nk:unescape-xml-comment-content() 
            "/>
    </xsl:function>
    
    <xsl:function name="nk:escape-xml-comment-content" as="xs:string">
        <xsl:param name="comment-content" as="xs:string"/>
        <xsl:sequence select="replace($comment-content, '-(/*)-', '-/$1-')"/>
    </xsl:function>
    
    <xsl:function name="nk:escape-xpath-comment-content" as="xs:string">
        <xsl:param name="comment-content" as="xs:string"/>
        
        <xsl:variable name="split">
            <xsl:analyze-string select="$comment-content" regex="\(:|:\)">
                <xsl:matching-substring>
                    <xsl:element name="{if(. = '(:') then 'start' else 'end'}" expand-text="yes">{.}</xsl:element>
                </xsl:matching-substring>
                <xsl:non-matching-substring>
                    <ph xsl:expand-text="yes">{replace(., ':(/+)\)', ':/$1)')}</ph>
                </xsl:non-matching-substring>
            </xsl:analyze-string>
        </xsl:variable>
        
        <xsl:variable name="split-quoted" select="
            $split/*/(
              if (self::end[
                    (preceding-sibling::start/1, preceding-sibling::end/(-1)) => sum() le 0
                 ]) 
            then ':/)' 
            else string(.)
            )
            "/>
        <xsl:sequence select="$split-quoted => string-join()"/>
        
    </xsl:function>
        
    
    <xsl:function name="nk:unescape-xml-comment-content" as="xs:string">
        <xsl:param name="comment-content" as="xs:string"/>
        <xsl:sequence select="replace($comment-content, '-/(/*)-', '-$1-')"/>
    </xsl:function>
    
    <xsl:function name="nk:unescape-xpath-comment-content" as="xs:string">
        <xsl:param name="comment-content" as="xs:string"/>
        <xsl:sequence select="replace($comment-content, ':/(/*)\)', ':$1)')"/>
    </xsl:function>
    
    
    <xsl:function name="nk:quote-unesc">
        <xsl:param name="escaped" as="xs:string"/>
        <xsl:param name="quote" as="xs:string"/>
        
        <xsl:sequence select="replace($escaped, '([' || $quote || '])\1', '$1')"/>
        
    </xsl:function>
    
</xsl:stylesheet>