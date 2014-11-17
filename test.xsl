<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.1" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

    <!-- all grammar_tables, and bibliography; furthermore some colorization CSS and JavaScript -->
    <xsl:template match="/grammar_tables">
        <html>
            <style type="text/css">
            .form_family_1 { background-color: #ff96a4 }
            .form_family_2 { background-color: #dee7ff }
            .form_family_3 { background-color: #00ff97 }
            .form_family_4 { background-color: #ffd41a }
            .form_family_5 { background-color: #ffb1ff }
            .form_family_6 { background-color: #00ffff }
            .form_family_7 { background-color: #00ff00 }
            .form_family_8 { background-color: #d1ff00 }
            .form_family_9 { background-color: #ffd6a0 }
            .form_family_10 { background-color: #ffdfff }
            .form_family_11 { background-color: #b9ffff }
            .form_family_12 { background-color: #b8ff99 }
            .form_family_13 { background-color: #fffc9c }
            .form_family_14 { background-color: #ff9332 }
            </style>
            <xsl:apply-templates select="grammar_table"/>
            <h1>Bibliography</h1>
            <ul>
                <xsl:apply-templates select="bibliography/book" />
            </ul>
        </html>
    </xsl:template>

    <!-- individual grammar_table: header, table proper, footnotes -->
    <xsl:template match="/grammar_tables/grammar_table">
        <h1><xsl:value-of select="@title"/></h1>
        <p><xsl:apply-templates select="description" mode="source" /></p>
        <xsl:apply-templates select="." mode="table" />
        <ul>
            <xsl:apply-templates select="paradigm" />
        </ul>
    </xsl:template>

    <!-- grammar_table: rows of declension headers, then case-paradigm rows -->
    <xsl:template match="/grammar_tables/grammar_table" mode="table">
        <xsl:variable name="case_defs_depth">
            <xsl:apply-templates select="." mode="defs_depth">
                <xsl:with-param name="name" select="'case_def'" />
            </xsl:apply-templates>
        </xsl:variable>
        <xsl:variable name="declension_defs_depth">
            <xsl:apply-templates select="." mode="defs_depth">
                <xsl:with-param name="name" select="'declension_def'" />
            </xsl:apply-templates>
        </xsl:variable>
        <table border="1" style="empty-cells: hide;">
            <xsl:apply-templates select="." mode="declension_headers">
                <xsl:with-param name="depth" select="0" />
                <xsl:with-param name="max_depth" select="$declension_defs_depth" />
                <xsl:with-param name="indent_depth" select="$case_defs_depth" />
            </xsl:apply-templates>
            <xsl:apply-templates select=".//case_def[not(parent::case_def) or position() > 1]">
                <xsl:with-param name="case_defs_depth" select="$case_defs_depth" />
            </xsl:apply-templates>
        </table>
    </xsl:template>

    <!-- depth of tree of def elements of $name below grammar_table/ -->
    <xsl:template match="/grammar_tables/grammar_table" mode="defs_depth">
        <xsl:param name="name" />
        <xsl:for-each select=".//*[name()=$name]">
            <xsl:sort select="count(ancestor::*[not(name()=$name) or @short_title])" order="descending"/>
            <xsl:if test="position()=1">
                <xsl:value-of select="count(ancestor::*[not(name()=$name) or @short_title]) - count(ancestor::grammar_table/ancestor::*)" />
            </xsl:if>
        </xsl:for-each>
    </xsl:template>

    <!-- grammar_table's declension header row (recursively calls itself growing $depth towards $max_depth) -->
    <xsl:template match="/grammar_tables/grammar_table" mode="declension_headers">
        <xsl:param name="depth" />
        <xsl:param name="max_depth" />
        <xsl:param name="indent_depth" />
        <xsl:if test=".//declension_def[count(ancestor::declension_def[@short_title])=$depth]">
            <tr>
                <th>
                    <xsl:attribute name="colspan">
                        <xsl:value-of select="$indent_depth" />
                    </xsl:attribute>
                </th>
                <xsl:apply-templates select=".//declension_def[count(ancestor::declension_def[@short_title])=$depth and @short_title]">
                    <xsl:with-param name="depth" select="$max_depth - $depth" />
                </xsl:apply-templates>
            </tr>
        </xsl:if>
        <xsl:if test="1 &lt; ($max_depth - $depth)">
            <xsl:apply-templates select="." mode="declension_headers">
                <xsl:with-param name="depth" select="$depth + 1" />
                <xsl:with-param name="max_depth" select="$max_depth" />
                <xsl:with-param name="indent_depth" select="$indent_depth" />
            </xsl:apply-templates>
        </xsl:if>
    </xsl:template>

    <!-- grammar_table's declension header row's individual declension_def cell (rowspan of $depth if no children else 1, colspan of descendant end nodes) -->
    <xsl:template match="/grammar_tables/grammar_table//declension_def">
        <xsl:param name="depth" />
        <th style="overflow:hidden;">
            <xsl:attribute name="colspan">
                <xsl:value-of select="count(descendant-or-self::declension_def[not(declension_def)])" />
            </xsl:attribute>
            <xsl:attribute name="rowspan">
                <xsl:value-of select="(count(declension_def) &gt; 0) + ((count(declension_def)=0) * $depth)" />
            </xsl:attribute>
            <abbr style="padding:100em; margin:-100em;">
                <xsl:attribute name="title">
                    <xsl:value-of select="@title" />
                </xsl:attribute>
                <xsl:value-of select="@short_title" />
            </abbr>
        </th>
    </xsl:template>

    <!-- grammar_table's case-paradigms row: case_def cells, followed by paradigms sorted by declension -->
    <xsl:template match="/grammar_tables/grammar_table//case_def">
        <xsl:param name="case_defs_depth" />
        <xsl:variable name="case" select="@id" />
        <tr>
            <xsl:apply-templates select="." mode="row_case_headers">
                <xsl:with-param name="max_depth" select="$case_defs_depth" />
            </xsl:apply-templates>
            <xsl:apply-templates select="." mode="paradigms_for_case" />
        </tr>
    </xsl:template>

    <!-- grammar_table's case-paradigms row's case_def cell, followed by its first-position child (colspan of 1 if parent, else of $max_depth minus number of case_def ancestors) -->
    <xsl:template match="/grammar_tables/grammar_table//case_def" mode="row_case_headers">
        <xsl:param name="max_depth" />
        <xsl:if test="@short_title">
            <th style="overflow:hidden;">
                <xsl:attribute name="rowspan">
                    <xsl:value-of select="count(descendant-or-self::case_def[not(case_def)])" />
                </xsl:attribute>
                <xsl:attribute name="colspan">
                    <xsl:choose>
                        <xsl:when test="case_def">
                            <xsl:text>1</xsl:text>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:value-of select="$max_depth - count(ancestor::case_def[@short_title])" />
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:attribute>
                <abbr style="padding:100em; margin:-100em;">
                    <xsl:attribute name="title">
                        <xsl:value-of select="@title" />
                    </xsl:attribute>
                    <xsl:value-of select="@short_title" />
                </abbr>
            </th>
        </xsl:if>
        <xsl:apply-templates select="case_def[position()=1]" mode="row_case_headers">
            <xsl:with-param name="max_depth" select="$max_depth" />
        </xsl:apply-templates>
    </xsl:template>

    <!-- grammar_table's case-paradigms row's paradigms -->
    <xsl:template match="/grammar_tables/grammar_table//case_def" mode="paradigms_for_case">
        <xsl:variable name="case" select="@id" />
        <xsl:for-each select="ancestor::grammar_table/declension_def">
            <xsl:apply-templates select="ancestor::grammar_table" mode="try_cell_building">
                <xsl:with-param name="case" select="$case" />
                <xsl:with-param name="declension" select="@id" />
            </xsl:apply-templates>
        </xsl:for-each>
    </xsl:template>

    <!-- grammar_table's paradigm of $case and $declension data (super-)cell --> 
    <xsl:template match="/grammar_tables/grammar_table" mode="try_cell_building">
        <xsl:param name="case" />
        <xsl:param name="declension" />
        <xsl:variable name="case_select">
            <xsl:apply-templates select=".//case_def[@id=$case]" mode="select_case">
                <xsl:with-param name="declension" select="$declension" />
            </xsl:apply-templates>
        </xsl:variable>
        <xsl:choose>
            <xsl:when test="$case_select != ''">
                <xsl:apply-templates select="." mode="end_node_cell">
                    <xsl:with-param name="case" select="$case_select" />
                    <xsl:with-param name="declension" select="$declension" />
                </xsl:apply-templates>
            </xsl:when>
            <xsl:otherwise>
                <xsl:apply-templates select="." mode="unused_cell_level">
                    <xsl:with-param name="case" select="$case" />
                    <xsl:with-param name="declension" select="$declension" />
                </xsl:apply-templates>
          </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- grammar_table's case_def matched by grammar_table's paradigm of $declension either directly or via a case_def in its 1st-children line -->
    <xsl:template match="/grammar_tables/grammar_table//case_def" mode="select_case">
        <xsl:param name="declension" />
        <xsl:variable name="case" select="@id" />
        <xsl:choose>
            <xsl:when test="ancestor::grammar_table/paradigm[@declension=$declension and @case=$case]">
                <xsl:value-of select="@id" />
            </xsl:when>
            <xsl:otherwise>
                <xsl:apply-templates select="case_def[position()=1]" mode="select_case">
                    <xsl:with-param name="declension" select="$declension" />
                </xsl:apply-templates>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
  
    <!-- grammar_table's paradigm of $case and $declension data (super-)cell as of unused level (necessitating further descent into categories tree, or, if impossible, treatment as an empty cell), or as pre-filled by case_defs further up in the case_defs list --> 
    <xsl:template match="/grammar_tables/grammar_table" mode="unused_cell_level">
        <xsl:param name="case" />
        <xsl:param name="declension" />
        <xsl:variable name="cell_prefilled">
            <xsl:for-each select=".//case_def[@id=$case]/ancestor::case_def">
                <xsl:variable name="test_case" select="@id" />
                <xsl:if test="ancestor::grammar_table/paradigm[@declension=$declension and @case=$test_case]">
                    1
                </xsl:if>
            </xsl:for-each>
        </xsl:variable>
        <xsl:choose>
            <xsl:when test="contains($cell_prefilled, '1')" />
            <xsl:when test=".//declension_def[@id=$declension]//declension_def">
                <xsl:for-each select=".//declension_def[@id=$declension]/declension_def">
                    <xsl:apply-templates select="ancestor::grammar_table" mode="try_cell_building">
                        <xsl:with-param name="case" select="$case" />
                        <xsl:with-param name="declension" select="@id" />
                    </xsl:apply-templates>
                </xsl:for-each>
            </xsl:when>
            <xsl:otherwise>
                <xsl:apply-templates select="." mode="empty_cell">
                    <xsl:with-param name="declension_def" mode="$declension" />
                </xsl:apply-templates>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- grammar_table's paradigm of $case and $declension (super-)cell as non-empty end node cell -->
    <xsl:template match="/grammar_tables/grammar_table" mode="end_node_cell">
        <xsl:param name="case" />
        <xsl:param name="declension" />
        <xsl:variable name="linkname">
            <xsl:apply-templates select="." mode="linkname">
                <xsl:with-param name="case" select="$case"/>
                <xsl:with-param name="declension" select="$declension"/>
            </xsl:apply-templates>
        </xsl:variable>
        <xsl:variable name="form_id" select="paradigm[@declension=$declension and @case=$case]/@form" />
        <td style="overflow:hidden; ">
            <xsl:apply-templates select="." mode="end_node_cell_attributes">
                <xsl:with-param name="form_id" select="$form_id" />
                <xsl:with-param name="case" select="$case" />
                <xsl:with-param name="declension" select="$declension" />
                <xsl:with-param name="linkname" select="$linkname" />
            </xsl:apply-templates>
            <a style="display:block; padding:100em; margin:-100em; ">
                <xsl:attribute name="href">
                    <xsl:text>#fn_</xsl:text>
                    <xsl:value-of select="$linkname"/>
                </xsl:attribute>
                <xsl:choose>
                    <xsl:when test="count(paradigm[@form=$form_id]) &gt; 1">
                        <xsl:if test="paradigm[@form=$form_id][1]/@case = $case and paradigm[@form=$form_id][1]/@declension = $declension">
                            <xsl:value-of select="form[$form_id=@id]" />
                        </xsl:if>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="form[$form_id=@id]" />
                    </xsl:otherwise>
                </xsl:choose>
                
            </a>
        </td>
    </xsl:template>

    <!-- grammar table's paradigm end node cell's attributes -->
    <xsl:template match="/grammar_tables/grammar_table" mode="end_node_cell_attributes">
        <xsl:param name="form_id" />
        <xsl:param name="case" />
        <xsl:param name="declension" />
        <xsl:param name="linkname" />
        <xsl:if test="count(paradigm[@form=$form_id]) &gt; 1">
            <xsl:attribute name="class">
                <xsl:text>form_family_</xsl:text>
                <xsl:variable name="form_family">
                    <xsl:apply-templates select="form[1]" mode="nth_multiparadigm_form">
                        <xsl:with-param name="stop_at" select="$form_id" />
                        <xsl:with-param name="nth" select="0" />
                    </xsl:apply-templates>
                </xsl:variable>
                <xsl:value-of select="$form_family" />
            </xsl:attribute>
        </xsl:if>
        <xsl:attribute name="rowspan">
            <xsl:value-of select="count(.//case_def[@id=$case]/descendant-or-self::case_def[not(case_def)])"/>
        </xsl:attribute>
        <xsl:attribute name="colspan">
                <xsl:value-of select="count(.//declension_def[@id=$declension]//descendant-or-self::declension_def[not(declension_def)])"/>
            </xsl:attribute>
            <xsl:attribute name="id">
                <xsl:value-of select="$linkname" />
            </xsl:attribute>
    </xsl:template>

    <!-- position of "stop_at" in multi-paradigm forms (i.e. don't count single-paradigm ones) -->
    <xsl:template match="/grammar_tables/grammar_table/form" mode="nth_multiparadigm_form">
        <xsl:param name="stop_at" />
        <xsl:param name="nth" />
        <xsl:variable name="form_id" select="@id" />
        <xsl:variable name="new_nth" select="$nth + (count(../paradigm[@form=$form_id]) &gt; 1)" />
        <xsl:choose>
            <xsl:when test="$stop_at=@id">
                <xsl:value-of select="$new_nth" />
            </xsl:when>
            <xsl:otherwise>
                <xsl:apply-templates select="following-sibling::form[1]" mode="nth_multiparadigm_form">
                    <xsl:with-param name="stop_at" select="$stop_at" />
                    <xsl:with-param name="nth" select="$new_nth" />
                </xsl:apply-templates>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- empty cell of colspan of end nodes below $declension_def in grammar_table/ if non-empty, else 1 -->
    <xsl:template match="/grammar_tables/grammar_table" mode="empty_cell">
        <xsl:param name="declension_def" />
        <td>
            <xsl:attribute name="colspan">
                <xsl:choose>
                    <xsl:when test="$declension_def">
                        <xsl:value-of select="count(.//declension_def[@id=$declension_def]/descendant-or-self::declension_def[not(declension_def)])"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:text>1</xsl:text>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:attribute>
        </td>
    </xsl:template>

    <!-- grammar_table's paradigm's footnote -->
    <xsl:template match="/grammar_tables/grammar_table/paradigm">
        <xsl:variable name="linkname">
            <xsl:apply-templates select="ancestor::grammar_table" mode="linkname">
                <xsl:with-param name="case" select="@case" />
                <xsl:with-param name="declension" select="@declension" />
            </xsl:apply-templates>
        </xsl:variable>
        <li>
            <xsl:attribute name="id">
                <xsl:text>fn_</xsl:text>
                <xsl:value-of select="$linkname" />
            </xsl:attribute>
            <a>
                <xsl:attribute name="href">
                    <xsl:text>#</xsl:text><xsl:value-of select="$linkname" />
                </xsl:attribute>
                <xsl:apply-templates select="." mode="paradigm_title" />
            </a>
            <xsl:text>: </xsl:text>
            <strong>
                <xsl:variable name="form_id" select="@form" />
                <xsl:value-of select="../form[@id=$form_id]" />
            </strong>
            <xsl:if test="@footnote">
                <xsl:variable name="footnote_id" select="@footnote" />
                <xsl:text> · </xsl:text>
                <xsl:apply-templates select="../footnote[@id=$footnote_id]" mode="source" />
            </xsl:if>
        </li>
    </xsl:template>

    <!-- grammar_table table's footnote's paradigm title (built from paradigm's @case, and @declension)-->
    <xsl:template match="/grammar_tables/grammar_table/paradigm" mode="paradigm_title">
        <xsl:variable name="declension" select="@declension" />
        <xsl:variable name="case" select="@case" />
        <strong>
            <xsl:value-of select="ancestor::grammar_table//declension_def[$declension=@id]/@title" />
            <xsl:text> </xsl:text>
            <xsl:value-of select="ancestor::grammar_table//case_def[$case=@id]/@title" />
        </strong>
    </xsl:template>

    <!-- grammar_table's paradigm link name (built from grammar_table's @id, and paradigm's $case, and $declension) -->
    <xsl:template match="/grammar_tables/grammar_table" mode="linkname">
        <xsl:param name="case" />
        <xsl:param name="declension" />
        <xsl:value-of select="@id"/>
        <xsl:text>_</xsl:text>
        <xsl:value-of select="$case" />
        <xsl:if test="$declension">
            <xsl:text>_</xsl:text>
            <xsl:value-of select="$declension" />
        </xsl:if>
    </xsl:template>

    <!-- any source link (translating @id into link anchor and name) -->
    <xsl:template match="source" mode="source">
        <xsl:variable name="book" select="@book" />
        <a>
            <xsl:attribute name="href">
                <xsl:text>#bibliography_</xsl:text><xsl:value-of select="$book" />
            </xsl:attribute>
            <xsl:value-of select="ancestor::grammar_tables/bibliography/book[@id=$book]/@title"/>
        </a>
    </xsl:template>

    <!-- bibliography's book list entry -->
    <xsl:template match="/grammar_tables/bibliography/book">
        <li>
            <xsl:attribute name="id">
                <xsl:text>bibliography_</xsl:text><xsl:value-of select="@id" />
            </xsl:attribute>
            <xsl:value-of select="." />
        </li>
    </xsl:template>

    <!-- catch-all for unmatched text / attributes (ignore them) -->
    <xsl:template match="text()|@*" />

</xsl:stylesheet>