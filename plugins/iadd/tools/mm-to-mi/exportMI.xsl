<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

    <xsl:output method="text" encoding="UTF-8"/>
    <xsl:strip-space elements="*"/>
    <xsl:variable name="indent-spaces">§§§§</xsl:variable>

    <xsl:template match="/map">
        <xsl:apply-templates select="node"/>
    </xsl:template>

    <xsl:template match="node">
        <xsl:param name="indent" select="''"/>

        <xsl:value-of select="$indent"/>

        <xsl:if test="icon">
            <xsl:text>[</xsl:text>
            <xsl:for-each select="icon">
                <xsl:variable name="iconName" select="@BUILTIN"/>
                <xsl:variable name="shortcut">
                    <xsl:choose>
                        <xsl:when test="$iconName = 'element'">e</xsl:when>
                        <xsl:when test="$iconName = 'tag_green'">v</xsl:when>
                        <xsl:when test="$iconName = 'Descriptor.grouping'">g</xsl:when>
                        <xsl:when test="$iconName = 'bricks'">g</xsl:when>
                        <xsl:when test="$iconName = 'Package'">p</xsl:when>
                        <xsl:when test="$iconName = 'Descriptor.class'">c</xsl:when>
                        <xsl:when test="$iconName = 'Descriptor.bean'">b</xsl:when>
                        <xsl:when test="$iconName = 'Mapping.directToField'">d</xsl:when>
                        <xsl:when test="$iconName = 'Mapping.oneToOne'">r</xsl:when>
                        <xsl:when test="$iconName = 'Mapping.oneToMany'">o</xsl:when>
                        <xsl:when test="$iconName = 'Mapping.manyToOne'">m</xsl:when>
                        <xsl:when test="$iconName = 'Method.public'">x</xsl:when>
                        <xsl:when test="$iconName = 'tag_yellow'">y</xsl:when>
                        <xsl:when test="$iconName = 'elementOutput'">x</xsl:when>
                        <xsl:when test="$iconName = 'Mapping.directMap'">h</xsl:when>
                        <xsl:when test="$iconName = 'textNode'">t</xsl:when>
                        <xsl:when test="$iconName = 'bullet_key'">k</xsl:when>
                        <xsl:otherwise><xsl:value-of select="$iconName"/></xsl:otherwise>
                    </xsl:choose>
                </xsl:variable>
                <xsl:value-of select="$shortcut"/>
                <xsl:if test="position() != last()"><xsl:text>, </xsl:text></xsl:if>
            </xsl:for-each>
            <xsl:text>] </xsl:text>
        </xsl:if>

        <xsl:variable name="nodeText" select="@TEXT"/>
        
        <xsl:choose>
            <xsl:when test="contains($nodeText, '&#xA;')">
                <xsl:value-of select="substring-before($nodeText, '&#xA;')"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="$nodeText"/>
            </xsl:otherwise>
        </xsl:choose>
        <xsl:text>&#xA;</xsl:text> <xsl:if test="contains($nodeText, '&#xA;')">
            <xsl:call-template name="print-remaining-lines">
                <xsl:with-param name="text" select="substring-after($nodeText, '&#xA;')"/>
                <xsl:with-param name="indent" select="concat($indent, $indent-spaces)"/>
            </xsl:call-template>
        </xsl:if>
        <xsl:if test="@LINK">
            <xsl:value-of select="$indent"/>
            <xsl:text>    #&#xA;</xsl:text>
            <xsl:value-of select="$indent"/>
            <xsl:text>        </xsl:text>
            <xsl:value-of select="@LINK"/>
            <xsl:text>&#xA;</xsl:text>
        </xsl:if>
        <xsl:apply-templates select="node">
            <xsl:with-param name="indent" select="concat($indent, $indent-spaces)"/>
        </xsl:apply-templates>
    </xsl:template>

    <xsl:template name="print-remaining-lines">
        <xsl:param name="text"/>
        <xsl:param name="indent"/>
        
        <xsl:value-of select="substring($indent,1,string-length($indent)-2)"/>
        <xsl:text>| </xsl:text>
        
        <xsl:variable name="current-line">
            <xsl:choose>
                <xsl:when test="contains($text, '&#xA;')">
                    <xsl:value-of select="substring-before($text, '&#xA;')"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="$text"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        
        <xsl:value-of select="$current-line"/>
        <xsl:text>&#xA;</xsl:text> <xsl:if test="contains($text, '&#xA;')">
            <xsl:call-template name="print-remaining-lines">
                <xsl:with-param name="text" select="substring-after($text, '&#xA;')"/>
                <xsl:with-param name="indent" select="$indent"/>
            </xsl:call-template>
        </xsl:if>
    </xsl:template>

</xsl:stylesheet>