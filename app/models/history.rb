#   encoding: utf-8
# frozen_string_literal: true
#   Copyright 2015 Australian National Botanic Gardens
#
#   This file is part of the NSL Editor.
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.
#
class History
  CHANGES_2016 = [
    { date: "07-Sep-2016",
      jira_id: "1952",
      description: %(Prevent any name being a synonym of itself.) },
    { date: "01-Sep-2016", release: true },
    { date: "29-Aug-2016",
      jira_id: "1956",
      description: %(Fix reference parent typeahead problem and improve error
      messages.) },
    { date: "25-Aug-2016", release: true },
    { date: "24-Aug-2016",
      jira_id: "1943",
      description: %(Fix color that is incorrect for some names on some
      instances.) },
    { date: "23-Aug-2016",
      jira_id: "1939",
      description: %(Show error message for attempt to create a duplicate
      synonym.) },
    { date: "23-Aug-2016",
      jira_id: "1937",
      description: %(When an author is deleted the confirmation message
      should once again show on the tab.) },
    { date: "22-Aug-2016",
      jira_id: "1936",
      description: %(Reference typeaheads now handle diacritics, e.g. "é"
      This includes typeaheads for changing the reference for instances,
      reference parent, and reference duplicate-of.) },
    { date: "19-Aug-2016", release: true },
    { date: "18-Aug-2016",
      jira_id: "1935",
      description: %(Delete reference confirm dialog should now reliably
      show the success message if the reference is deleted.) },
    { date: "18-Aug-2016", release: true },
    { date: "16-Aug-2016",
      jira_id: "1931",
      description: %(Show exception messages for instance create problems e.g. if
      synonym create double-enter bypasses application-level validation.) },
    { date: "15-Aug-2016",
      jira_id: "1928",
      description:
      %(Technical upgrade to code.) },
    { date: "12-Aug-2016",
      jira_id: "1929",
      description:
      %(Name > More > Refresh > Refresh Descendant names... works again.) },
    { date: "12-Aug-2016",
      jira_id: "1926",
      description:
      %(Fix error that prevents details tab displaying for references which
      are published but have no parent, no year and no publication date) },
    { date: "12-Aug-2016",
      jira_id: "1925",
      description:
      %(When creating a new reference you can once again add a parent from the
      typeahead. [Tests added too.]) },
    { date: "11-Aug-2016",
      jira_id: "1924",
      description:
      %(Enter key no longer bypasses confirmation dialog when changing the
      reference for an instance with synonyms. Also, escape key cancels
      the dialog.) },
    { date: "11-Aug-2016", release: true },
    { date: "09-Aug-2016",
      jira_id: "1918",
      description:
      %(Restore timezone setting lost on Rails upgrade.) },
    { date: "08-Aug-2016",
      jira_id: "478",
      description:
      %(Show a scrollbar for large search results in old versions of
      Firefox.) },
    { date: "08-Aug-2016",
      jira_id: "478",
      description:
      %(Work-around formatting problem for search field in old Firefox
      versions) },
    { date: "04-Aug-2016", release: true },
    { date: "03-Aug-2016",
      jira_id: "775",
      description:
      %(Upgrade to Rails 4.2, requiring JRuby 9.1.2.0) },
    { date: "28-Jul-2016",
      jira_id: "1900",
      description:
      %(You can now use letters with and without diacritics in author
      typeaheads and they will match authors with and without diacritics.
      E.g. "Doll" finds "Doll" and "Döll", "Döll" finds "Doll" and "Döll".) },
    { date: "28-Jul-2016",
      jira_id: "974",
      description:
      %(Report of synonymy instances and the instances that cite them matching
      the requirements in jira 974. Also a report that retrieves the names
      for those instances.) },
    { date: "28-Jul-2016", release: true },
    { date: "27-Jul-2016",
      jira_id: "1860",
      description:
      %(Force choice of instance type when copying standalone instance.
      With refinements) },
    { date: "26-Jul-2016",
      jira_id: "1872",
      description:
      %(Add new assertion searches for whether an author has authored names.) },
    { date: "26-Jul-2016",
      jira_id: "1872",
      description:
      %(Stop removal of abbreviation from authors who have authored a name.) },
    { date: "25-Jul-2016",
      jira_id: "1872",
      description:
      %(Allow authors marked as duplicates to have no name and/or
      abbreviation.) },
    { date: "22-Jul-2016",
      jira_id: "1828",
      description:
      %(Display reference parts correctly. Prevent entry of edition, volume,
      publication date and year for reference parts.) },
    { date: "22-Jul-2016", release: true },
    { date: "20-Jul-2016",
      jira_id: "1892",
      description:
      %(Add search on reference notes.  Includes field help and an example.) },
    { date: "18-Jul-2016",
      jira_id: "1889",
      description:
      %(Define new name query arguments "in-accepted-tree:" and
      "not-in-accepted-tree:". Added field help, name search example, and
      report example combining with "with-exactly-one_instance:" and
      "ref-title:".) },
    { date: "18-Jul-2016",
      jira_id: "1889",
      description:
    %(Define a new name query argument "ref-title:" that can be used to find
    names associated with a matching reference title.) },
    { date: "12-Jul-2016", release: true },
    { date: "11-Jul-2016",
      jira_id: "1882",
      description:
      %(Accept author names with accented characters in reference typeahead.
      (Remove f_unaccent call in sql that checks authors.) ) },
    { date: "28-Jun-2016",
      jira_id: "",
      description:
      %(Move the record-level drag-icons onto the details tabs.) },
    { date: "24-Jun-2016",
      jira_id: "",
      description:
      %(You can drag search result records into the tree editor.) },
    { date: "09-Jun-2016", release: true },
    { date: "08-Jun-2016",
      jira_id: "1840",
      description:
      %(Duplicate of authors now include those with diacritics.
      e.g. "Thumen" also retrieves "Thümen".) },
    { date: "07-Jun-2016",
      jira_id: "1834",
      description:
      %(Add <q>offset:</q> as a search token for name searches so that work
      using the is-orth-var-with-no-orth-var-instances report can continue.) },
    { date: "02-Jun-2016", release: true },
    { date: "23-May-2016",
      jira_id: "1810",
      description: %(Stop special characters (e.g. &amp;, &#39;) appearing
      with raw encoding (e.g. &amp;amp;, &amp;#39; ) in some typeahead fields
      immediately after update. Fixed for Author.duplicate-of field and
      Reference.parent field.) },
    { date: "20-May-2016",
      jira_id: "1807",
      description:
      %(Add an example of a correctly formatted name under the new Author
      name field.) },
    { date: "19-May-2016", release: true },
    { date: "18-May-2016",
      jira_id: "1803",
      description:
      %(Set Name.sort_name on save using service data.) },
    { date: "13-May-2016",
      jira_id: "1778",
      description:
      %(Assume first namespace record is the default namespace for the database.) },
    { date: "14-Apr-2016", release: true },
    { date: "13-Apr-2016",
      jira_id: "1756",
      description:
      %(Remove stray text on synonym instance details tab.) },
    { date: "12-Apr-2016", release: true },
    { date: "04-Apr-2016",
      jira_id: "1745",
      description:
      %(Include names without instances in the Name typeahead for unpublished
      citation - problem arose after NSL-945.) },
    { date: "31-Mar-2016", release: true },
    { date: "30-Mar-2016",
      jira_id: "1157",
      description:
      %(Report for names with earliest instance not primary.) },
    { date: "30-Mar-2016",
      jira_id: "1737",
      description:
      %(Adjust layout for laptop screen - to show bottom of pages.) },
    { date: "30-Mar-2016",
      jira_id: "945",
      description:
      %(Typeahead on full name (e.g. for adding instance to reference) now
      excludes names without instances.) },
    { date: "30-Mar-2016",
      jira_id: "1730",
      description:
      %(Fix validation error when editing APC distribution Instance Note.) },
    { date: "24-Mar-2016", release: true },
    { date: "17-Mar-2016",
      jira_id: "1712",
      description:
      %(Improve error message for duplicate Author abbreviations.) },
    { date: "10-Mar-2016", release: true },
    { date: "03-Mar-2016",
      jira_id: "1698",
      description:
      %(Author duplicate typeahead now excludes duplicates - all duplicate-of
      typeaheads now exclude duplicates.) },
    { date: "03-Mar-2016",
      jira_id: "1697",
      description:
      %(Prevent duplicate Author abbreviations.) },
    { date: "03-Mar-2016", release: true },
    { date: "02-Mar-2016",
      jira_id: "1687",
      description:
      %(Long Author names are now allowed.) },
    { date: "01-Mar-2016",
      jira_id: "1693",
      description:
      %(Add "rank:" as a query field for Instances.  See help and examples.) },
    { date: "01-Mar-2016",
      jira_id: "1691",
      description:
      %(Fix Instance Synonymy tab link which appears after a new synonym is
      created. Once again correctly queries all instances for the Name.) },
    { date: "01-Mar-2016",
      jira_id: "1690",
      description:
      %(Add exact search examples for Author showing how to find embedded
      substrings with spaces e.g. ' in ' etc.) },
    { date: "25-Feb-2016", release: true },
    { date: "24-Feb-2016",
      jira_id: "1672",
      description:
      %(Offer typehead name parents in descending taxonomic rank) },
    { date: "22-Feb-2016",
      jira_id: "1673",
      description:
      %(Add search for name with-exactly-one-instance. Examples on Reports
      tab) },
    { date: "22-Feb-2016",
      jira_id: "1674",
      description:
      %(Add return before Reference notes on Details tab.) },
    { date: "22-Feb-2016",
      jira_id: "1680",
      description:
      %(New Reference searches for not-type: and parent-type:.) },
    { date: "22-Feb-2016",
      jira_id: "1676",
      description:
      %(Name duplicate typeahead does not offer current name.) },
    { date: "22-Feb-2016",
      jira_id: "1679",
      description:
      %(Fix summary of totals for Name search.) },
    { date: "22-Feb-2016", release: true },
    { date: "22-Feb-2016",
      jira_id: "1675",
      description:
      %(Convert Names plus instances search to Names search with
      show-instances: directive.) },
    { date: "18-Feb-2016",
      jira_id: "1652",
      description:
      %(Modify is-orth-var-and-non-primary-ref-first: report query to
      include standalone instances only.) },
    { date: "18-Feb-2016",
      jira_id: "1666",
      description:
      %(Modify Help and Examples for Audit/Review to clarify created-at:,
      updated-at:, and by: queries.) },
    { date: "18-Feb-2016",
      jira_id: "1666",
      description:
      %(Modify Report page description for
      is-orth-var-and-non-primary-sec-ref-first:.) },
    { date: "18-Feb-2016", release: true },
    { date: "17-Feb-2016",
      jira_id: "1666",
      description:
      %(Fix Review list search and make Review count searches work.) },
    { date: "16-Feb-2016",
      jira_id: "1655",
      description:
      %(Added queries <strong>is-orth-var-and-non-primary-ref-first:</strong>
      and <strong>is-orth-var-and-non-primary-sec-ref-first:</strong>. Links
      on Reports tab.) },
    { date: "16-Feb-2016",
      jira_id: "1651",
      description:
      %(Also added query report for
      <strong>parent-ref-wrong-child-type:</strong>. Links on Reports tab.) },
    { date: "16-Feb-2016",
      jira_id: "1651",
      description:
      %(Warn of conflicts when changing type of parent reference -
      dropdown now shows unacceptable options in red with a comment.) },
    { date: "15-Feb-2016",
      jira_id: "1661",
      description:
      %(Fix "cited" and "cited by" links on the Instance edit tab.) },
    { date: "12-Feb-2016",
      jira_id: "1662",
      description: %(Order instance-type: search results by name.) },
    { date: "12-Feb-2016",
      jira_id: "1657",
      description: %(Adjust query for parent suggestions for unranked
      names. Should be faster.) },
    { date: "11-Feb-2016", release: true },
    { date: "10-Feb-2016",
      jira_id: "1650",
      description: %(Correctly show reference edit error.) },
    { date: "10-Feb-2016",
      jira_id: "1420",
      description: %(Report to find autonyms whose parent's epithet \
      is not at the end of the autonym's name.) },
    { date: "10-Feb-2016",
      jira_id: "1636",
      description: %(Add name-element-exact: and simple-name-exact: \
      searches.) },
    { date: "09-Feb-2016",
      jira_id: "1620",
      description: %(Reports tab for easier access to queries like \
      <q>is-orth-var-and-sec-ref-first: show-instances: \
      limit: 10</q>) },
    { date: "08-Feb-2016",
      jira_id: "1620",
      description: %(Option to <q>show-instances:</q> with the original \
      search for NSL-1620) },
    { date: "08-Feb-2016",
      jira_id: "1620",
      description: %(Add <q>show-instances:</q> directive for Name \
      searches.) },
    { date: "08-Feb-2016", release: true },
    { date: "08-Feb-2016",
      jira_id: "1647",
      description: %(Fix link to APC tree search on Name details tab.) },
    { date: "05-Feb-2016", release: true },
    { date: "02-Feb-2016",
      jira_id: "1637",
      description: %(Reinstate the Name search feature that replaced embedded
      spaces with wildcards.  Also reinstate no leading wildcard.) },
    { date: "02-Feb-2016",
      jira_id: "1644",
      description: %(Restore tokenized search function to Author
      name-or-abbrev and default searches.  Tokenized means "in any order".) },
    { date: "02-Feb-2016",
      jira_id: "1641",
      description: %(Clicking Help/Examples/Advanced after an Instance search
      now correctly shows Instance info.
      "Trees" search is now "Tree", avoiding an error.) },
    { date: "29-Jan-2016",
      jira_id: "474",
      description: "Add Instance search for species or below synonymised to a
      genus or above.  With help and examples." },
    { date: "28-Jan-2016",
      jira_id: "1636",
      description: "Add name searches for name-element and simple-name.  With
      help and examples." },
    { date: "27-Jan-2016",
      jira_id: "1620",
      description: "Add Name search for orth. vars whose first instance is a
      secondary reference. With help and examples" },
    { date: "22-Jan-2016",
      jira_id: "1618",
      description: "Add headings to Instance CSV output." },
    { date: "22-Jan-2016",
      jira_id: "1624",
      description: "Allow searches for instances with specified text in 'type'
      notes" },
    { date: "22-Jan-2016", release: true },
    { date: "21-Jan-2016",
      jira_id: "1608",
      description: "Allow one and only one <q>APC Dist.</q> field for each APC
      instance. If one already exists, only offer <q>APC comment</q> option." },
    { date: "20-Jan-2016",
      jira_id: "1618",
      description: "CSV output for instance queries." },
    { date: "14-Jan-2016",
      jira_id: "1608",
      description: "APC Comment and Dist. Instance Notes are now created and
      edited on the APC tab." },
    { date: "14-Jan-2016", release: true },
    { date: "13-Jan-2016",
      jira_id: "1612",
      description: "Help, examples now showing on initial query for instance
      sorted by page for ref id." },
    { date: "12-Jan-2016",
      jira_id: "1606",
      description: "For Reference > (new) Instance, the name typeahead is now
      ordered by rank." },
    { date: "11-Jan-2016",
      jira_id: "1602",
      description: "Query for tax. nov. instances with an orth. var. name." },
    { date: "08-Jan-2016", release: true },
    { date: "07-Jan-2016",
      jira_id: "447",
      description: "Instances for a reference query in page
      order refinement - put hyphenated ranges last . <br>
      e.g. '58-59' after '58'." },
    { date: "06-Jan-2016",
      jira_id: "1603",
      description: "Double-clicking text fields no
      longer selects the whole field. Default behaviour applies:
      triple click selects whole field." },
    { date: "05-Jan-2016",
      jira_id: "1601",
      description: "Split single history page into two yearly pages.
      Make minor layout and substantial coding changes." },
    { date: "04-Jan-2016",
      jira_id: "1004",
      description: "Add HTML titles to form fields on the Reference Page,
      New Instance tab." },
    { date: "04-Jan-2016",
      jira_id: "1505",
      description: "Duplicate Names are excluded from suggestions on the
      Reference page, New Instance tab, Name field." },
  ].freeze

  CHANGES_2015 = [
    { date: "24-Dec-2015",
      jira_id: "1302",
      description: "References can now be marked as duplicates without
      triggering validation errors - if the duplicate-of-id is the only
      value changed." },
    { date: "24-Dec-2015", release: true },
    { date: "23-Dec-2015",
      jira_id: "1598",
      description: "Reference text search on citation results now
      ordered by citation." },
    { date: "23-Dec-2015",
      jira_id: "1595",
      description: "Reinstate the orth.-var.-without-orthographic-
      variant-instance name search.  See NSL-1364." },
    { date: "23-Dec-2015",
      jira_id: "1586",
      description: "Author name typeahead no longer offers duplicates.
      E.g. Reference author 'Schlechter'" },
    { date: "22-Dec-2015",
      jira_id: "1585",
      description: "Reference 'children' query now shows the parent
      Reference as the first record." },
    { date: "22-Dec-2015",
      jira_id: "1249",
      description: "Changing a Name's name field silently adjusts the names
      of any children, hybrid children, or descendants. Runs in the
      background." },
    { date: "21-Dec-2015",
      jira_id: "1591",
      description: "Name second parent children now returns the correct
      number of records, including common/cultivars.  Likewise similar
      links." },
    { date: "16-Dec-2015",
      jira_id: "1579",
      description: "Start reference duplicates details on a new line." },
    { date: "14-Dec-2015",
      jira_id: "1571",
      description: "Cancelling a delete on a Comments tab with more than 1
      comment now re-enables the Delete Comment button." },
    { date: "11-Dec-2015",
      jira_id: "1561",
      description: "First cut of Reference shared names query; also fixed
      query error handling to show the query details." },
    { date: "08-Dec-2015",
      jira_id: "1564",
      description: "Load search help, examples and advanced content only when
      the tabs are selected." },
    { date: "02-Dec-2015",
      jira_id: "1250",
      description: "Word-based text search is now the default for Reference." },
    { date: "26-Nov-2015",
      jira_id: "1199",
      description: "Name and Reference details tabs now link to any
      duplicates." },
    { date: "26-Nov-2015", release: true },
    { date: "25-Nov-2015",
      jira_id: "1555",
      description: "Set TZ environmental variable to 'Australia/Melbourne' to
      correct jruby Time.now and stop timestamps being set in UTC." },
    { date: "24-Nov-2015",
      jira_id: "1556",
      description: "Add title attributes to links, fields and buttons." },
    { date: "24-Nov-2015",
      jira_id: "1552",
      description: "Clean up and improve advanced search forms.  Advanced
      search form now matches the current search target." },
    { date: "23-Nov-2015",
      jira_id: "1553",
      description: "Improve search form keyboard navigation." },
    { date: "20-Nov-2015",
      jira_id: "1551",
      description: "Fix links from reference on instance detail tab for
      relationship instances." },
    { date: "20-Nov-2015",
      jira_id: "578",
      description: "Instances for reference ID now obeys
      limit; count works." },
    { date: "20-Nov-2015", release: true },
    { date: "19-Nov-2015",
      jira_id: "1549",
      description: "Restore diacritic searching for author abbreviation and
      author name. e.g. search author for 'müLl'." },
    { date: "19-Nov-2015", release: true },
    { date: "18-Nov-2015",
      jira_id: "1542",
      description: "Make the [results, search help, search examples...] tabs
      more tabby with better label contrast." },
    { date: "18-Nov-2015",
      jira_id: "1431",
      description: "Review search now includes date-created, date-last-
      updated, and date-created-or-last-updated fields." },
    { date: "17-Nov-2015",
      jira_id: "1395",
      description: "Do not show superfluous '[manuscript]' when listing Names
      of status 'manuscript'." },
    { date: "17-Nov-2015",
      jira_id: "1479",
      description: "Added Name query assertions: has-instances: and has-no-
      instances:.  See Name search help and examples." },
    { date: "17-Nov-2015",
      jira_id: "1040",
      description: "Query instances by reference type.  Instance search help
      updated, examples added." },
    { date: "16-Nov-2015",
      jira_id: "1537",
      description: "Fix the Name Edit button 'Convert to cultivar hybrid'." },
    { date: "12-Nov-2015",
      jira_id: "1519",
      description: "Speed up APC tree view." },
    { date: "12-Nov-2015",
      jira_id: "1518",
      description: "Edit link from Services Search works again." },
    { date: "11-Nov-2015",
      jira_id: "1244",
      description: "Get more than the first 100 ref instances sorted by page.
      (Add &quot;limit: nnnn&quot; to query on &quot;Instances for Ref ID
      sort by page&quot;.)" },
    { date: "11-Nov-2015", release: true },
    { date: "11-Nov-2015",
      jira_id: "1484",
      description: "Basic version of review search is part of the new search
      engine and interface." },
    { date: "11-Nov-2015",
      jira_id: "1437",
      description: "New search engine and interface." },
    { date: "07-Oct-2015",
      jira_id: "1479",
      description: "Display children information on name details tab even if
      name has no instances." },
    { date: "01-Oct-2015", release: true },
    { date: "29-Sep-2015",
      jira_id: "1469",
      description: "Name with-author, with-base-author searches etc now match
      against author.abbrev rather than author.name." },
    { date: "29-Sep-2015",
      jira_id: "1468",
      description: "Authorise readers to see the APC tree." },
    { date: "25-Sep-2015", release: true },
    { date: "22-Sep-2015",
      jira_id: "1443",
      description: "Allow parents to be of any rank for [unranked] rank types
      for scientific names<br><span class='green'>(NSL-1449 is now resolved.)
      </span>" },
    { date: "21-Sep-2015",
      jira_id: "1454",
      description: "Internal adjustments to speed display of name details.
      These build slightly on the big gain from the new indexes - see
      NSL-1455." },
    { date: "21-Sep-2015",
      jira_id: "1455",
      description: "Added indexes in production to further speed up Name
      Details tab display." },
    { date: "21-Sep-2015",
      jira_id: "1448",
      description: "Add information about database connections for
      administrators." },
    { date: "21-Sep-2015", release: true },
    { date: "16-Sep-2015",
      jira_id: "1443",
      description: "[Withdrawn] Allow parents to be of any rank for
      [unranked] rank types for scientific names. Awaiting NSL-1449, name
      rules changes." },
    { date: "16-Sep-2015",
      jira_id: "1444",
      description: "Replace service calls for Name Details tab with database
      queries; also now showing APNI tree, APC tree, tweaking details
      display." },
    { date: "16-Sep-2015",
      jira_id: "1417",
      description: "Identify APC 'DeclaredBt' names and do not show them
      with APC tick or APC excluded. (Same change as for NSL-664 below.)" },
    { date: "16-Sep-2015",
      jira_id: "664",
      description: "Identify APC 'DeclaredBt' names and do
      not show them with APC tick or APC excluded." },
    { date: "11-Sep-2015",
      jira_id: "1429",
      description: "Allow cultivar hybrids to have both parents the same." },
    { date: "11-Sep-2015", release: true },
    { date: "10-Sep-2015",
      jira_id: "1429",
      description: "Prevent hybrid Name parent and second parent being the
      same." },
    { date: "09-Sep-2015",
      jira_id: "1249",
      description: "New Name tab labelled 'Refresh' has a button to refresh
      (i.e. reconstruct) children's names." },
    { date: "07-Sep-2015",
      jira_id: "1410",
      description: "Set updated_by when changing instance reference. Change
      updated_by in the dependent instances as well." },
    { date: "07-Sep-2015",
      jira_id: "1327",
      description: "Stop instance edit form updating when no change made." },
    { date: "07-Sep-2015",
      jira_id: "1406",
      description: "Improve GUI message when Author and Reference deleted.
      Now consistent with Name and Instance GUI message display." },
    { date: "04-Sep-2015",
      jira_id: "283",
      description: "Add instance note search." },
    { date: "04-Sep-2015",
      jira_id: "629",
      description: "Adjust labels of base name author and
      ex base name author." },
    { date: "03-Sep-2015",
      jira_id: "934",
      description: "Name tags ACRA, PBR, Trade now
      capitalised in query options." },
    { date: "03-Sep-2015",
      jira_id: "1400",
      description: "restore copy-instance tab to QA users." },
    { date: "03-Sep-2015", release: true },
    { date: "02-Sep-2015",
      jira_id: "1388",
      description: "add 'replaced synonym' into sorting rule for nested
      instances." },
    { date: "01-Sep-2015",
      jira_id: "1392",
      description: "review and improve instance searches.  e.g. created/
      updated since/before" },
    { date: "01-Sep-2015",
      jira_id: "1388",
      description: "add a page listing instance types, available from the
      Help menu." },
    { date: "31-Aug-2015",
      jira_id: "1389",
      description: "name instance ordering: sort primary instances first if
      year is the same." },
    { date: "31-Aug-2015",
      jira_id: "1386",
      description: "show or hide author dupe field based on new/existing
      record status not on action called." },
    { date: "31-Aug-2015",
      jira_id: "1385",
      description: "Let QA users once again change the reference for
      standalone instances with synonyms." },
    { date: "28-Aug-2015",
      jira_id: "1382",
      description: "Re-structure code for Instances-for-a-Name search." },
    { date: "28-Aug-2015",
      jira_id: "1381",
      description: "Adjust spacing of message on Name form." },
    { date: "28-Aug-2015", release: true },
    { date: "27-Aug-2015",
      jira_id: "1378",
      description: "Show raw service error messages when instance and name
      deletes go wrong." },
    { date: "26-Aug-2015",
      jira_id: "1373",
      description: "Add another choice to the list of reasons for deleting a
      name: 'Name is represented elsewhere in NSL'." },
    { date: "26-Aug-2015",
      jira_id: "1372",
      description: "Fix minor Standalone Instance Synonymy typeahead error
      caused by extracting an oversize year value from a full citation
      pasted into the typeahead." },
    { date: "25-Aug-2015",
      jira_id: "",
      description: "Added check for comments before showing
      Instance Delete button." },
    { date: "25-Aug-2015",
      jira_id: "1361",
      description: "Re-organise authorisations (permissions) while reviewing
      them." },
    { date: "24-Aug-2015",
      jira_id: "1368",
      description: "Correct navigation tabbing on new record forms." },
    { date: "20-Aug-2015", release: true },
    { date: "20-Aug-2015",
      jira_id: "1194",
      description: "Check user authorization on confirm delete." },
    { date: "20-Aug-2015",
      jira_id: "1339",
      description: "Allow up to 255 characters in Reference pages." },
    { date: "20-Aug-2015", release: true },
    { date: "19-Aug-2015",
      jira_id: "1357",
      description: "Added drop-down name query for orth. vars with no orth.
      var. instances." },
    { date: "19-Aug-2015",
      jira_id: "1363",
      description: "Reference typeaheads now exclude duplicates." },
    { date: "19-Aug-2015",
      jira_id: "1360",
      description: "Added drop-down name query: names without instances but
      with comment.  Any text in the search field restricts the comment
      text." },
    { date: "17-Aug-2015",
      jira_id: "1194",
      description: "Name delete.  Also second-level of name tabs." },
    { date: "17-Aug-2015",
      jira_id: "1355",
      description: "Name create/edit now uses second parent if supplied.
      e.g. hybrid formula" },
    { date: "17-Aug-2015",
      jira_id: "",
      description: "Synch LHS if Name tag added or removed." },
    { date: "14-Aug-2015",
      jira_id: "1351",
      description: "add child/parent links to Name details tab; add Name
      parent-id search." },
    { date: "14-Aug-2015",
      jira_id: "1350",
      description: "make Name tag field required using the HTML attribute;
      adjust the label to match. [See any Name record -&gt; Tag tab.]" },
    { date: "13-Aug-2015", release: true },
    { date: "12-Aug-2015",
      jira_id: "1333",
      description: "can now delete instances that have or have had a simple
      name entry as a protologue instance." },
    { date: "11-Aug-2015",
      jira_id: "1345",
      description: "warning people not running Firefox." },
    { date: "11-Aug-2015",
      jira_id: "1331",
      description: "convert author name typeahead on the Reference Edit tab
      to ordered fragment search with frequency search." },
    { date: "11-Aug-2015",
      jira_id: "1316",
      description: "on update ensure [Duplicate] flag is retained for
      references; refresh author LHS on update." },
    { date: "10-Aug-2015",
      jira_id: "1251",
      description: "when sorting instances by page, also sort by name.
      full_name within page." },
    { date: "10-Aug-2015",
      jira_id: "1341",
      description: "reverse disabling of Create button after instance
      created." },
    { date: "10-Aug-2015",
      jira_id: "1340",
      description: "increase the validation limit on reference.pages to 100
      chars to match the database." },
    { date: "07-Aug-2015", release: true },
    { date: "05-Aug-2015",
      jira_id: "1311",
      description: "major upgrade to typeaheads" },
    { date: "04-Aug-2015",
      jira_id: "1324",
      description: "stop automatically adding leading wildcard to search
      strings.  Should make searching faster." },
    { date: "27-Jul-2015", release: true },
    { date: "27-Jul-2015",
      jira_id: "1205",
      description: "direct link from instance to APNI search now opens in a
      separate, named, tab or window (depending on browser settings)." },
    { date: "27-Jul-2015",
      jira_id: "1285",
      description: "instance delete." },
    { date: "24-Jul-2015", release: true },
    { date: "24-Jul-2015",
      jira_id: "1303",
      description: "added 'Refresh' button on Name edit tab - as first-aid
      for the problem of cultivar names not being formed correctly on
      insert." },
    { date: "23-Jul-2015",
      jira_id: "1304",
      description: "show error messages again when creating names if
      something goes wrong." },
    { date: "22-Jul-2015",
      jira_id: "1300",
      description: "fix refresh of LHS when name is updated." },
    { date: "21-Jul-2015",
      jira_id: "1294",
      description: "improve error handling in reference forms for both new
      and edited records." },
    { date: "21-Jul-2015",
      jira_id: "1295",
      description: "make reference.year an integer only field with min and
      max values matching the current validations." },
    { date: "21-Jul-2015",
      jira_id: "1293",
      description: "fixed bug in name form (successive errors could lose
      context) and fixed the update of reference citation on LHS after
      saving details." },
    { date: "20-Jul-2015",
      jira_id: "1283",
      description: "url encode query in customised bloodhound JS methods -
      percent signs will work now for reference duplicate and others." },
    { date: "20-Jul-2015",
      jira_id: "1292",
      description: "typeahead suggestions for editing relationship instances
      should now autoreduce." },
    { date: "17-Jul-2015",
      jira_id: "1203",
      description: "enforce reference parent type rules - upgrade to use
      current data, not saved data." },
    { date: "17-Jul-2015",
      jira_id: "926",
      description: "clean up html." },
    { date: "15-Jul-2015",
      jira_id: "1220",
      description: "show search summary even if no results found; add
      search summary for instance type, comments and with-comments-by
      searches." },
    { date: "15-Jul-2015",
      jira_id: "1066",
      description: "fix refresh link that appears on synonymy tab after
      successful create." },
    { date: "15-Jul-2015",
      jira_id: "1203",
      description: "enforce reference parent type rules." },
    { date: "09-Jul-2015",
      jira_id: "1271",
      description: "a reference of unknown type can be a duplicate of any
      type of reference - not just duplicate of unknown type references." },
    { date: "09-Jul-2015",
      jira_id: "1205",
      description: "link to Name APNI output from instance details tab." },
    { date: "09-Jul-2015",
      jira_id: "926",
      description: "change parent suggestions for cultivar and cultivar
      hybrids to allow Genus and below or unranked if unranked.
      See updated" },
    { date: "08-Jul-2015",
      jira_id: "1264",
      description: "if user's login expires from inactivity (e.g.
      overnight), minor actions like choosing a menu option will trigger
      the sign-in page." },
    { date: "07-Jul-2015",
      jira_id: "1263",
      description: "improve name edit form layout - top button, heading
      take up too much vertical space." },
    { date: "07-Jul-2015", release: true },
    { date: "06-Jul-2015",
      jira_id: "1255",
      description: "do not allow creation of new instances for duplicate
      names." },
    { date: "30-Jun-2015",
      jira_id: "1193",
      description: "instance sort by page now handles ranges like
      <q>19-20</q> - this example would sort as if it was  page <q>19</q>." },
    { date: "30-Jun-2015",
      jira_id: "1239",
      description: "add tests to confirm duplicates are not offered in name
      typeaheads." },
    { date: "29-Jun-2015",
      jira_id: "1234",
      description: "improved error handling and error message when user
      enters text into reference typeahead fields without selecting from the
      typeahead." },
    { date: "29-Jun-2015",
      jira_id: "1231",
      description: "distinguish more obviously between test and production
      - change to banner background colour and top left badge text, only
      affects test env." },
    { date: "26-Jun-2015",
      jira_id: "1195",
      description: "reference records offered in the duplicate-of typeahead
      are now only of the same type as the record itself or of unknown
      type." },
    { date: "25-Jun-2015",
      jira_id: "975",
      description: "do not offer deprecated instance types
      for new or updated instances." },
    { date: "25-Jun-2015", release: true },
    { date: "24-Jun-2015",
      jira_id: "1223",
      description: "restore instance unpublished citation tab." },
    { date: "23-Jun-2015",
      jira_id: "1188",
      description: "indicate that a reference/name/author is a duplicate
      entry in left-hand pane." },
    { date: "23-Jun-2015",
      jira_id: "1209",
      description: "remove usage of name.primary_instance_id.  For example,
      no longer prevents deleting an instance." },
    { date: "22-Jun-2015",
      jira_id: "1214",
      description: "make correct call to rebuild name strings after name
      update." },
    { date: "19-Jun-2015", release: true },
    { date: "19-Jun-2015",
      jira_id: "1153",
      description: "user able to copy standalone instances retrieved in a
      Name search along with all attached synonyms/unpublished citations." },
    { date: "17-Jun-2015",
      jira_id: "1190",
      description: "fix reference duplicate typeahead - it now offers a list
      again; also exclude current reference from the offered list." },
    { date: "12-Jun-2015",
      jira_id: "1180",
      description: "avoid error when user tries to open New > Reference in a
      new tab; same for other new options; opens a new home page." },
    { date: "05-Jun-2015",
      jira_id: "478",
      description: "fix css problem on FireFox 17 - which obscures the top
      search result on departmental PCs." },
    { date: "05-Jun-2015", release: true },
    { date: "04-Jun-2015",
      jira_id: "1164",
      description: "remove integer appearing at the top left of instance
      tabs." },
    { date: "04-Jun-2015",
      jira_id: "1165",
      description: "fix name instance tab label - <q>synonym</q> is now
      correctly <q>instance</q>; also add tab headings and remove copy
      tab." },
    { date: "02-Jun-2015",
      jira_id: "1149",
      description: "Various fixes to the APC placement form" },
    { date: "02-Jun-2015",
      jira_id: "992",
      description: "APC Parent kept when using a new concept for an existing
      APC name. Within NSL-1149" },
    { date: "02-Jun-2015",
      jira_id: "993",
      description: "'Reset Form' button removed. Within NSL-1149" },
    { date: "02-Jun-2015",
      jira_id: "1003",
      description: "APC Distribution and Comment removed from the APC edit
      form. Within NSL-1149" },
    { date: "02-Jun-2015",
      jira_id: "559",
      description: "APC tab now displays current placement of the name even
      when the instance selected is not the current instance. Within
      NSL-1149" },
    { date: "02-Jun-2015",
      jira_id: "1150",
      description: "change the title of the Name 'Summary' tab to 'Details'
      for consistency." },
    { date: "02-Jun-2015",
      jira_id: "1126",
      description: "allow keyboard access to the 'Create Instance' button on
      the Instance>Unpublished Citation tab." },
    { date: "02-Jun-2015",
      jira_id: "1126",
      description: "allow keyboard access to the 'Create Instance' button on
      the Instance>Unpublished Citation tab." },
    { date: "29-May-2015", release: true },
    { date: "28-May-2015",
      jira_id: "1145",
      description: "Restore the step that refreshes the reference citation
      after an update." },
    { date: "28-May-2015",
      jira_id: "1102",
      description: "Search for authors whose name or abbreviations contain
      diacritics using the diacritics' English replacements: <br>e.g.
      Search for 'Fr.Müll.' by entering" },
    { date: "28-May-2015",
      jira_id: "1135",
      description: "Minor adjustments to the help page." },
    { date: "28-May-2015", release: true },
    { date: "27-May-2015",
      jira_id: "972",
      description: "Add instance count to name parent typeahead
      suggestions." },
    { date: "26-May-2015",
      jira_id: "963",
      description: "Adjust ordering of instances in name-based search
      when year is the same.  e.g. Casuarina inophloia, Podosperma
      gnaphaloides" },
    { date: "26-May-2015",
      jira_id: "1134",
      description: "Speed up second and subsequent name summary details
      display by caching service call results." },
    { date: "25-May-2015",
      jira_id: "1122",
      description: %(Change "between" in name summary tab to "within" if
      there is one and only one parent.) },
    { date: "25-May-2015",
      jira_id: "1123",
      description: %(Remove "Clear/Delete" from reference typeaheads.) },
    { date: "25-May-2015",
      jira_id: "1127",
      description: "Allow users to edit and view pagination of unpublished
      citations such as common names.  Could previously insert only." },
    { date: "25-May-2015",
      jira_id: "1025",
      description: "Allow QA users to change the reference for standalone
      instances - even if the instance has synonyms attached." },
    { date: "25-May-2015",
      jira_id: "803",
      description: "Allow entry of instance BHL URLs.  Display instance BHL
      URLS." },
    { date: "25-May-2015",
      jira_id: "1133",
      description: "Convert button links on the tabs to text links with
      icons (e.g. the search icon) to show that they are links." },
    { date: "25-May-2015",
      jira_id: "1132",
      description: "Fixed instance-type search - it works again now when you
      select instance type from the drop-down." },
    { date: "22-May-2015", release: true },
    { date: "21-May-2015",
      jira_id: "1025",
      description: "Added a synonymy model diagram in an Instances models
      page available from the Help menu. <br>I hope this diagram helps make
      clear the task being attempted in NSL-1025." },
    { date: "20-May-2015",
      jira_id: "1103",
      description: "Synonymy typeahead suggestions are now ordered by name.
      full_name then year (previously just name.full_name)." },
    { date: "19-May-2015",
      jira_id: "1081",
      description: %(The three reference forms now respond with "no change"
      if you hit Save without having made a change.) },
    { date: "15-May-2015",
      jira_id: "1115",
      description: "New reference form field tabbing was fixed as part of
      NSL-576." },
    { date: "15-May-2015",
      jira_id: "1111",
      description: "Author duplicate-of is (once again) correctly saved." },
    { date: "15-May-2015",
      jira_id: "576",
      description: "Adjust reference fields and labels." },
    { date: "14-May-2015",
      jira_id: "1102",
      description: "Search for names that contain diacritics using their
      English replacements: e.g. Search for 'kröb' by entering 'krob'." },
    { date: "14-May-2015",
      jira_id: "1110",
      description: "Added a page showing the history of changes to the
      editor." },
  ].freeze
end
