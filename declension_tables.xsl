<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.1" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

    <xsl:output method="html"  doctype-system="about:legacy-compat"/>

    <!-- all grammar_tables, and bibliography; furthermore some colorization CSS and JavaScript -->
    <xsl:template match="/grammar_tables">
        <html>
            <meta charset="utf-8"/>
            <title><xsl:value-of select="@title" /></title>
            <link id="styleA" rel="stylesheet" type="text/css" href="style_nocolors.css" title="no colors" />
            <link id="styleB" rel="alternate stylesheet" type="text/css" href="style_coloredforms.css" title="each form one color (pattern)" />
            <link id="styleC" rel="alternate stylesheet" type="text/css" href="style_coloredchanges.css" title="colored per-stage changes" />
            <h1><xsl:value-of select="@title" /></h1>
            <p>
                <xsl:apply-templates select="description" mode="source" />
            </p>
            <xsl:apply-templates select="grammar_table"/>
            <h2>Bibliography</h2>
            <ul class="bibliography">
                <xsl:apply-templates select="bibliography/book" />
            </ul>
            <script type="text/javascript">
                function add_coloring_button(color_char, name, css_picker) {
                    var button = document.createElement("span");
                    button.id = "button" + color_char;
                    button.style.textDecoration = "underline";
                    button.onclick = function() {
                        document.getElementById("styleA").disabled = true;
                        document.getElementById("styleB").disabled = true;
                        document.getElementById("styleC").disabled = true;
                        document.getElementById("style" + color_char).disabled = false;
                        document.getElementById("buttonA").style.textDecoration = "none";
                        document.getElementById("buttonB").style.textDecoration = "none";
                        document.getElementById("buttonC").style.textDecoration = "none";
                        document.getElementById("button" + color_char).style.textDecoration = "underline";
                    };
                    var text = document.createTextNode(name)
                    button.appendChild(text);
                    css_picker.appendChild(button);
                }
                var css_picker = document.createElement("div");
                css_picker.style.position = "fixed";
                css_picker.style.bottom = "0px";
                css_picker.style.width = "100%";
                css_picker.style.borderTop = "1px solid black";
                css_picker.style.backgroundColor = "white";
                document.documentElement.appendChild(css_picker);
                css_picker.appendChild(document.createTextNode("table coloring: "));
                add_coloring_button("A", "no colors", css_picker);
                <xsl:if test="54>count(/grammar_tables/forms/form)">
                css_picker.appendChild(document.createTextNode(" / "));
                add_coloring_button("B", "each form one color (pattern)", css_picker);
                </xsl:if>
                css_picker.appendChild(document.createTextNode(" / "));
                <xsl:if test="54>count(/grammar_tables/forms/form)">
                document.getElementById("buttonB").style.textDecoration = "none";
                </xsl:if>
                add_coloring_button("C", "colored per-stage changes", css_picker);
                document.getElementById("buttonC").style.textDecoration = "none";
                var pickerStyle = window.getComputedStyle(css_picker, null);
                var picker_height = parseInt(pickerStyle.getPropertyValue("height"), 10);
                console.log(picker_height);
                document.getElementsByClassName('bibliography')[0].style.paddingBottom = 1.5 * picker_height + "px";
            </script>
        </html>
    </xsl:template>

    <!-- individual grammar_table: header, table proper, footnotes -->
    <xsl:template match="/grammar_tables/grammar_table">
        <h2><xsl:value-of select="@title"/></h2>
        <p><xsl:apply-templates select="description" mode="source" /></p>
        <xsl:apply-templates select="." mode="table" />
        <ul class="paradigms">
            <xsl:apply-templates select="/grammar_tables/footnotes/footnote">
                <xsl:with-param name="grammar_table" select="@id" />
            </xsl:apply-templates>
            <li>
                <ul class="nongrouped_footnotes" >
                    <xsl:apply-templates select="paradigm[not(@footnote)]" />
                </ul>
            </li>
        </ul>
    </xsl:template>

    <!-- all paradigm footnotes referencing one footnote element -->
    <xsl:template match="/grammar_tables/footnotes/footnote">
        <xsl:param name="grammar_table" />
        <xsl:variable name="footnote_id" select="@id" />
        <xsl:choose>
            <xsl:when test="count(/grammar_tables/grammar_table[@id=$grammar_table]/paradigm[@footnote=$footnote_id]) &gt; 1">
                <li>
                    <ul class="footnote_grouping">
                        <xsl:apply-templates select="/grammar_tables/grammar_table[@id=$grammar_table]/paradigm[@footnote=$footnote_id]">
                            <xsl:with-param name="with_source" select="0" />
                        </xsl:apply-templates>
                    </ul>
                    <p class="footnote_grouping">
                        <xsl:text>(</xsl:text>
                        <xsl:apply-templates select="." mode="source" />
                        <xsl:text>)</xsl:text>
                    </p>
                    <div class="clearboth" />
                </li>
            </xsl:when>
            <xsl:otherwise>
                <xsl:apply-templates select="/grammar_tables/grammar_table[@id=$grammar_table]/paradigm[@footnote=$footnote_id]">
                    <xsl:with-param name="with_source" select="1" />
                </xsl:apply-templates>
            </xsl:otherwise>
        </xsl:choose>
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
        <table>
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
        <th>
            <xsl:attribute name="colspan">
                <xsl:value-of select="count(descendant-or-self::declension_def[not(declension_def)])" />
            </xsl:attribute>
            <xsl:attribute name="rowspan">
                <xsl:value-of select="(count(declension_def) &gt; 0) + ((count(declension_def)=0) * $depth)" />
            </xsl:attribute>
            <abbr>
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
            <th>
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
                <abbr>
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
        <xsl:variable name="form_id">
            <xsl:apply-templates select="paradigm[@declension=$declension and @case=$case]" mode="form_search" />
        </xsl:variable>
        <td>
            <xsl:apply-templates select="." mode="end_node_cell_attributes">
                <xsl:with-param name="form_id" select="$form_id" />
                <xsl:with-param name="case" select="$case" />
                <xsl:with-param name="declension" select="$declension" />
                <xsl:with-param name="linkname" select="$linkname" />
            </xsl:apply-templates>
            <a>
                <xsl:attribute name="href">
                    <xsl:text>#fn_</xsl:text>
                    <xsl:value-of select="$linkname"/>
                </xsl:attribute>
                <span>
                    <xsl:value-of select="/grammar_tables/forms/form[$form_id=@id]" />
                </span>
            </a>
        </td>
    </xsl:template>

    <!-- grammar table's paradigm end node cell's attributes -->
    <xsl:template match="/grammar_tables/grammar_table" mode="end_node_cell_attributes">
        <xsl:param name="form_id" />
        <xsl:param name="case" />
        <xsl:param name="declension" />
        <xsl:param name="linkname" />
        <xsl:attribute name="class">
            <xsl:text>endnode form_family_</xsl:text>
            <xsl:value-of select="count(/grammar_tables/forms/form[$form_id=@id]/preceding-sibling::form)" />
            <xsl:if test="not(paradigm[@case=$case and @declension=$declension]/@continues)">
                <xsl:text> premiere</xsl:text>
            </xsl:if>
        </xsl:attribute>
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

    <!-- form ID mapped to paradigm either directly or (via continue attribute) indirectly -->
    <xsl:template match="/grammar_tables/grammar_table/paradigm" mode="form_search">
        <xsl:choose>
            <xsl:when test="@continues">
                 <xsl:variable name="prev_id" select="substring-before(@continues,' ')" />
                 <xsl:variable name="prev_declension" select="substring-before(substring-after(@continues,' '), ' ')" />
                 <xsl:variable name="prev_case" select="substring-after(substring-after(@continues,' '), ' ')" />
                 <xsl:value-of select="/grammar_tables/grammar_table[@id=$prev_id]/paradigm[@declension=$prev_declension and @case=$prev_case]/@form" />
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="@form" />
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- grammar_table's paradigm's footnote -->
    <xsl:template match="/grammar_tables/grammar_table/paradigm">
        <xsl:param name="with_source" />
        <xsl:variable name="linkname">
            <xsl:apply-templates select="ancestor::grammar_table" mode="linkname">
                <xsl:with-param name="case" select="@case" />
                <xsl:with-param name="declension" select="@declension" />
            </xsl:apply-templates>
        </xsl:variable>
        <xsl:variable name="form_id">
            <xsl:apply-templates select="." mode="form_search" />
        </xsl:variable>
        <li class="single_paradigm">
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
                <xsl:value-of select="/grammar_tables/forms/form[@id=$form_id]" />
            </strong>
            <xsl:apply-templates select="@continues" />
            <xsl:if test="@footnote and 1=$with_source">
                <xsl:variable name="footnote_id" select="@footnote" />
                <xsl:text> (</xsl:text>
                <xsl:apply-templates select="/grammar_tables/footnotes/footnote[@id=$footnote_id]" mode="source" />
                <xsl:text>)</xsl:text>
            </xsl:if>
        </li>
        <div class="clearboth" />
    </xsl:template>

    <!-- footnote link to paradigm refered to by "continues" paradigm attribute -->
    <xsl:template match="/grammar_tables/grammar_table/paradigm/@continues" >
        <xsl:variable name="prev_id" select="substring-before(.,' ')" />
        <xsl:variable name="prev_declension" select="substring-before(substring-after(.,' '), ' ')" />
        <xsl:variable name="prev_case" select="substring-after(substring-after(.,' '), ' ')" />
        <xsl:text> (</xsl:text>
        <a>
        <xsl:attribute name="href">
            <xsl:text>#fn_</xsl:text>
            <xsl:apply-templates select="/grammar_tables/grammar_table[@id=$prev_id]" mode="linkname">
                <xsl:with-param name="case" select="$prev_case" />
                <xsl:with-param name="declension" select="$prev_declension" />
            </xsl:apply-templates>
        </xsl:attribute>
        <xsl:text>older</xsl:text>
        </a>
        <xsl:text>)</xsl:text>
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
