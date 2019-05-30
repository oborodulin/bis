<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
<xsl:output method="text" omit-xml-declaration="yes"/>
<xsl:template match="*[not(*)]">
    <xsl:value-of select="ancestor-or-self::*"/> : <xsl:value-of select="."/>
</xsl:template>
</xsl:stylesheet>