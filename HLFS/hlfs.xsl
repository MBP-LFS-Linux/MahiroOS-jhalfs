<?xml version="1.0"?>
<!DOCTYPE xsl:stylesheet [
 <!ENTITY % general-entities SYSTEM "FAKEDIR/general.ent">
  %general-entities;
]>

<!-- $Id$ -->

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:exsl="http://exslt.org/common"
    extension-element-prefixes="exsl"
    version="1.0">

<!-- XSLT stylesheet to create shell scripts from HLFS books. -->

  <!-- What libc implentation must be used? -->
  <xsl:param name="model" select="glibc"/>

  <!-- Is the host kernel using grsecurity? -->
  <xsl:param name="grsecurity_host" select="0"/>

  <!-- Compile the keymap into the kernel? -->
  <xsl:param name="keymap" select="none"/>

  <!-- Run test suites?
       0 = none
       1 = only chapter06 Glibc, GCC and Binutils testsuites
       2 = all chapter06 testsuites
       3 = all chapter05 and chapter06 testsuites-->
  <xsl:param name="testsuite" select="1"/>

  <!-- Time zone -->
  <xsl:param name="timezone" select="America/Toronto"/>

  <!-- Page size -->
  <xsl:param name="page" select="letter"/>

  <!-- Locale settings -->
  <xsl:param name="lang" select="en_ca"/>
  <xsl:param name="lc_all" select="en_ca"/>

  <xsl:template match="/">
    <xsl:apply-templates select="//sect1"/>
  </xsl:template>

  <xsl:template match="sect1">
    <xsl:if test="(../@id='chapter-temporary-tools' or
                  ../@id='chapter-building-system' or
                  ../@id='chapter-bootable') and
                  ((@condition=$model or not(@condition)) and
                  count(descendant::screen/userinput) &gt; 0 and
                  count(descendant::screen/userinput) &gt;
                  count(descendant::screen[@role='nodump']))">
        <!-- The dirs names -->
      <xsl:variable name="pi-dir" select="../processing-instruction('dbhtml')"/>
      <xsl:variable name="pi-dir-value" select="substring-after($pi-dir,'dir=')"/>
      <xsl:variable name="quote-dir" select="substring($pi-dir-value,1,1)"/>
      <xsl:variable name="dirname" select="substring-before(substring($pi-dir-value,2),$quote-dir)"/>
        <!-- The file names -->
      <xsl:variable name="pi-file" select="processing-instruction('dbhtml')"/>
      <xsl:variable name="pi-file-value" select="substring-after($pi-file,'filename=')"/>
      <xsl:variable name="filename" select="substring-before(substring($pi-file-value,2),'.html')"/>
        <!-- The build order -->
      <xsl:variable name="position" select="position()"/>
      <xsl:variable name="order">
        <xsl:choose>
          <xsl:when test="string-length($position) = 1">
            <xsl:text>00</xsl:text>
            <xsl:value-of select="$position"/>
          </xsl:when>
          <xsl:when test="string-length($position) = 2">
            <xsl:text>0</xsl:text>
            <xsl:value-of select="$position"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:value-of select="$position"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:variable>
        <!-- Creating dirs and files -->
      <exsl:document href="{$dirname}/{$order}-{$filename}" method="text">
        <xsl:choose>
          <xsl:when test="@id='ch-system-changingowner' or
                    @id='ch-system-creatingdirs' or
                    @id='ch-system-createfiles'">
            <xsl:text>#!/tools/bin/bash&#xA;set -e&#xA;&#xA;</xsl:text>
          </xsl:when>
          <xsl:when test="@id='ch-tools-stripping' or
                    @id='ch-system-strippingagain'">
            <xsl:text>#!/bin/sh&#xA;</xsl:text>
          </xsl:when>
          <xsl:otherwise>
            <xsl:text>#!/bin/sh&#xA;set -e&#xA;&#xA;</xsl:text>
          </xsl:otherwise>
        </xsl:choose>
        <xsl:if test="(sect2[@role='installation'] and
                     not(@id='bootable-kernel')) or
                     @id='ch-tools-adjusting' or
                     @id='ch-system-readjusting'">
          <xsl:text>cd $PKGDIR&#xA;</xsl:text>
          <xsl:if test="@id='ch-tools-uclibc' or @id='ch-system-uclibc'">
             <xsl:text>pushd ../; tar -xvf gettext-&gettext-version;.*; popd; &#xA;</xsl:text>
          </xsl:if>
          <xsl:if test="@id='ch-tools-glibc' or @id='ch-system-glibc'">
             <xsl:text>tar -xvf ../glibc-libidn-&glibc-version;.*&#xA;</xsl:text>
          </xsl:if>
          <xsl:if test="@id='ch-tools-gcc' or @id='ch-system-gcc'">
             <xsl:text>pushd ../; tar -xvf gcc-g++-&gcc-version;.*; popd; &#xA;</xsl:text>
          </xsl:if>
          <xsl:if test="@id='ch-tools-gcc' and $testsuite = '3'">
            <xsl:text>pushd ../; tar -xvf gcc-testsuite-&gcc-version;.*; popd; &#xA;</xsl:text>
          </xsl:if>
          <xsl:if test="@id='ch-system-gcc' and $testsuite != '0'">
            <xsl:text>pushd ../; tar -xvf gcc-testsuite-&gcc-version;.*; popd; &#xA;</xsl:text>
          </xsl:if>
          <xsl:if test="@id='bootable-bootscripts'">
             <xsl:text>pushd ../; tar -xvf blfs-bootscripts-&blfs-bootscripts-version;.* ; popd; &#xA;</xsl:text>
          </xsl:if>
        </xsl:if>
        <xsl:if test="@id='ch-system-kernfs'">
          <xsl:text>export HLFS=$LFS&#xA;</xsl:text>
        </xsl:if>
        <xsl:apply-templates select=".//para/userinput | .//screen"/>
        <xsl:text>exit</xsl:text>
      </exsl:document>
    </xsl:if>
  </xsl:template>

  <xsl:template match="screen">
    <xsl:if test="(@condition=$model or not(@condition)) and
                  child::* = userinput and not(@role = 'nodump')">
      <xsl:apply-templates select="userinput" mode="screen"/>
    </xsl:if>
  </xsl:template>

  <xsl:template match="para/userinput">
    <xsl:if test="(contains(string(),'test') or
            contains(string(),'check')) and
            (($testsuite = '1' and
            (ancestor::sect1[@id='ch-system-gcc'] or
            ancestor::sect1[@id='ch-system-glibc'])) or
            ($testsuite = '2' and
            ancestor::chapter[@id='chapter-building-system']) or
            $testsuite = '3')">
      <xsl:choose>
        <xsl:when test="ancestor::sect1[@id='ch-system-gcc']">
          <xsl:text>make -k check || true&#xA;</xsl:text>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="substring-before(string(),'make')"/>
          <xsl:text>make -k</xsl:text>
          <xsl:value-of select="substring-after(string(),'make')"/>
          <xsl:text> || true&#xA;</xsl:text>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:if>
  </xsl:template>

  <xsl:template match="userinput" mode="screen">
    <xsl:choose>
      <!-- Estandarized package formats -->
      <xsl:when test="contains(string(),'tar.gz')">
        <xsl:value-of select="substring-before(string(),'tar.gz')"/>
        <xsl:text>tar.*</xsl:text>
        <xsl:value-of select="substring-after(string(),'tar.gz')"/>
        <xsl:text>&#xA;</xsl:text>
      </xsl:when>
      <!-- Avoiding a race condition in a patch -->
      <xsl:when test="contains(string(),'debian_fixes')">
        <xsl:value-of select="substring-before(string(),'patch')"/>
        <xsl:text>patch -Z</xsl:text>
        <xsl:value-of select="substring-after(string(),'patch')"/>
        <xsl:text>&#xA;</xsl:text>
      </xsl:when>
      <!-- grsecurity kernel in the host? -->
      <xsl:when test="ancestor::sect1[@id='ch-system-kernfs'] and
                contains(string(),'sysctl')
                and $grsecurity_host ='0'"/>
      <!-- Setting $LC_ALL and $LANG for /etc/profile -->
      <xsl:when test="ancestor::sect1[@id='bootable-profile'] and
                contains(string(),'export LANG=')">
        <xsl:value-of select="substring-before(string(),'export LC_ALL=')"/>
        <xsl:text>export LC_ALL=</xsl:text>
        <xsl:value-of select="$lc_all"/>
        <xsl:text>&#xA;export LANG=</xsl:text>
        <xsl:value-of select="$lang"/>
        <xsl:text>&#xA;export INPUTRC</xsl:text>
        <xsl:value-of select="substring-after(string(),'INPUTRC')"/>
        <xsl:text>&#xA;</xsl:text>
      </xsl:when>
      <!-- Fixing bootscripts installation -->
      <xsl:when test="ancestor::sect1[@id='bootable-bootscripts'] and
                string() = 'make install'">
        <xsl:text>make install&#xA;</xsl:text>
        <xsl:text>cd ../blfs-bootscripts-&blfs-bootscripts-version;&#xA;</xsl:text>
      </xsl:when>
      <!-- Compile the keymap into the kernel? -->
      <xsl:when test="contains(string(),'defkeymap') and
                $keymap = 'none'"/>
      <!-- Copying the kernel config file -->
      <xsl:when test="string() = 'make mrproper'">
        <xsl:text>make mrproper&#xA;</xsl:text>
        <xsl:text>cp -v /sources/kernel-config .config&#xA;</xsl:text>
      </xsl:when>
      <!-- No interactive commands are allowed -->
      <xsl:when test="string() = 'make menuconfig'">
        <xsl:text>make oldconfig&#xA;</xsl:text>
      </xsl:when>
      <!-- For uClibc we need to cd to the Gettext package -->
      <xsl:when test="contains(string(),'cd gettext-runtime/')">
        <xsl:text>cd ../gettext-*/gettext-runtime</xsl:text>
        <xsl:value-of select="substring-after(string(),'gettext-runtime')"/>
        <xsl:text>&#xA;</xsl:text>
      </xsl:when>
      <!-- The Coreutils and Module-Init-Tools test suites are optional -->
      <xsl:when test="($testsuite = '0' or $testsuite = '1') and
                (ancestor::sect1[@id='ch-system-coreutils'] or
                ancestor::sect1[@id='ch-system-module-init-tools']) and
                (contains(string(),'check') or
                contains(string(),'distclean') or
                contains(string(),'dummy'))"/>
      <!-- Fixing toolchain test suites run -->
      <xsl:when test="string() = 'make check' or
                string() = 'make -k check'">
        <xsl:choose>
          <xsl:when test="(($testsuite = '1' or $testsuite = '2') and
                    ancestor::chapter[@id='chapter-building-system']) or
                    $testsuite = '3'">
            <xsl:text>make -k check || true</xsl:text>
            <xsl:text>&#xA;</xsl:text>
          </xsl:when>
        </xsl:choose>
      </xsl:when>
      <xsl:when test="contains(string(),'make check') and
                ancestor::sect1[@id='ch-system-binutils']">
        <xsl:choose>
          <xsl:when test="$testsuite != '0'">
            <xsl:value-of select="substring-before(string(),'make check')"/>
            <xsl:text>make -k check || true&#xA;</xsl:text>
          </xsl:when>
        </xsl:choose>
      </xsl:when>
      <xsl:when test="contains(string(),'hardened-specs') and
                ancestor::sect1[@id='ch-system-binutils']
                and $testsuite = '0'"/>
      <!-- Don't stop on strip run and chapter05 GCC installation test-->
      <xsl:when test="contains(string(),'strip ') or
                ancestor::sect2[@id='testing-gcc'] and
                not(contains(string(),'EOF'))">
        <xsl:apply-templates/>
        <xsl:text> || true&#xA;</xsl:text>
      </xsl:when>
      <!-- The rest of commands -->
      <xsl:otherwise>
        <xsl:apply-templates/>
        <xsl:text>&#xA;</xsl:text>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template match="replaceable">
    <xsl:choose>
      <xsl:when test="ancestor::sect1[@id='ch-system-glibc'] or
                      ancestor::sect1[@id='ch-system-uclibc']">
        <xsl:value-of select="$timezone"/>
      </xsl:when>
      <xsl:when test="ancestor::sect1[@id='ch-system-groff']">
        <xsl:value-of select="$page"/>
      </xsl:when>
      <xsl:when test="ancestor::sect1[@id='bootable-kernel']">
        <xsl:value-of select="$keymap"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:text>**EDITME</xsl:text>
        <xsl:apply-templates/>
        <xsl:text>EDITME**</xsl:text>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

</xsl:stylesheet>
