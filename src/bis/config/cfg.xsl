<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="2.0">
<xsl:output method="xhtml" omit-xml-declaration="yes"/>
<xsl:template match="*[not(*)]">
    <xsl:value-of select="local-name()"/> : <xsl:value-of select="."/>
</xsl:template>
<xsl:template match="*[(*)]">
    <xsl:value-of select="local-name()"/>
    <xsl:apply-templates/>
</xsl:template>
</xsl:stylesheet>