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
require 'test_helper'

class ReferenceTest < ActiveSupport::TestCase

  def try_citation(ref, expected, msg = 'unexplained error', debug = false)
    ref.save!
    debug(ref) if debug
    assert ref.citation.match(Regexp.new(Regexp.escape(expected))), "#{msg}; \nexpected: #{expected}; \ngot:                         \"#{ref.citation}\""
  end

  def debug(ref)
    puts "ref.title: #{ref.title}" 
    puts "ref.author.name: #{ref.author.name}" if ref.author
    puts ref.parent ? 'ref has parent' : 'ref has no parent'
    puts "ref.parent.author.name: #{ref.parent.author.name}" if ref.parent
    puts "ref.parent_has_same_author?: #{ref.parent_has_same_author?}"
    puts "ref.citation: #{ref.citation}" 
  end

  test "test for has children" do
    assert references(:journal_with_children).has_children?, "Children not detected."
  end

  test "test for has no children" do
    assert_not references(:ref_without_children).has_children?, "Children found where none exist."
  end

# test "update title for citation:book:orphan:no year:no publication date:1:" do
#   ref = references(:orphan_book_edited_by_brassard_no_year_no_publication_date)
#   ref.title = 'New Title'
#   try_citation(ref,
#                'Brassard [x], (ed.) New Title.',
#                'book citation not set on update')
# end

# test "citation:section:parent:parent author same:2:" do
#   try_citation(references(:section_with_brassard_author_same_as_parent), 
#                'Brassard [x], book by brassard.', 
#                'citation not set correctly for section with same author as parent')
# end

# test "citation:section:parent:parent author different:parent author role is author:3:" do
#   try_citation(references(:section_with_heyland_author_different_from_parent), 
#                'Heyland [y] in Brassard [x], book by brassard.', 
#                'citation not set correctly for section with different author from parent')
# end

# test "citation:section:parent:parent author different:parent author is editor:4:" do
#   try_citation(references(:section_with_heyland_author_different_from_parent_editor),
#                           'Heyland [y] in Brassard [x], (ed.) parented book edited by brassard.', 
#                           'citation not set correctly')
# end

# test "citation:paper:with parent:year 1690:author brassard:5:" do
#   try_citation(references(:paper_within_journal),
#                'Brassard [x] in Blume, C.L. [von], (ed.) (1690) paper within journal. journal with papers Edn. 1, 2.',
#                'citation not set correctly')
# end

# test "citation:paper:author brassard:no parent:no year:no publication date:6:" do
#   try_citation(references(:paper_with_no_parent_no_year_no_publication_date),
#                'Brassard [x], paper with no parent no year no publication date Edn. 1, 2.',
#                'citation not set on paper reference title update')
# end

# test "citation:book:orphan:no year:no publication date:7:" do
#   try_citation(references(:orphan_book_edited_by_brassard_no_year_no_publication_date),
#                           'Brassard [x], (ed.) Orphan book edited by brassard no year no publication date.', 
#                           'book citation wrong')
# end

# test "citation:book:orphan:with year:no publication date:8:" do
#   try_citation(references(:orphan_book_edited_by_brassard_with_year_no_publication_date),
#                           'Brassard [x], (ed.) (1797) Orphan book edited by brassard with year and no publication date.', 
#                           'book citation wrong')
# end

# test "citation:book:orphan:with year:with publication date:9:" do
#   try_citation(references(:orphan_book_edited_by_brassard_with_year_and_publication_date),
#                           'Brassard [x], (ed.) (1790) Orphan book edited by brassard with year and publication date.', 
#                           'book citation wrong')
# end

# test "citation:book:orphan:without year:with publication date:10:" do
#   try_citation(references(:orphan_book_edited_by_brassard_with_no_year_but_publication_date),
#                           'Brassard [x], (ed.) (1870) Orphan book edited by brassard with no year but publication date.', 
#                           'book citation wrong')
# end

# test "citation:book:orphan:title is not set: no year: no publication date:11:" do
#   try_citation(references(:orphan_book_by_brassard_with_title_not_set),
#                           'Brassard [x].', 
#                           'book citation wrong')
# end

# test "citation:book:orphan:author blume c l von:12:" do
#   try_citation(references(:orphan_book_by_blume_c_l_von),
#                           'Blume, C.L. [von], Museum Botanicum Lugduno-Batavum sive.', 
#                           'book citation wrong')
# end

# test "citation:paper:author brassard:13:" do
#   try_citation(references(:paper_by_brassard),
#                           'Brassard [x], (1987) paper by brassard.', 
#                           'book citation wrong')
# end

# # Note: this test is passing because it allows for the extra space in the title to be removed.
# # TODO: discuss with users - is that ok?
# test "book:extra space in title:14:" do
#   try_citation(references(:book_with_extra_space_in_title),
#                           'Brassard [x], (1799) book  with extra space in title.', 
#                           'book citation wrong for extra space in title (perhaps)')
# end

# test "book:ellipses in title:14:" do
#   try_citation(references(:book_with_ellipses_in_title),
#                           'Brassard [x], (1799) book... with ellipses in title...', 
#                           'book citation wrong for ellipses in title (perhaps)')
# end

# test "citation:paper:with parent:year 1690:author brassard:paper title has full stop:15:" do
#   try_citation(references(:paper_within_journal_title_has_full_stop),
#                'Brassard [x] in Blume, C.L. [von], (ed.) (1690) paper within journal title has full stop. journal with papers Edn. 1, 2.',
#                'citation not set correctly')
# end

# test "paper:extra space in title:16:" do
#   try_citation(references(:paper_with_extra_space_in_title),
#                           'Brassard [x] in Blume, C.L. [von], (ed.) (1690) paper    with extra space in title. journal with papers Edn. 1, 2.', 
#                           'paper citation wrong for extra space in title (perhaps)')
# end

# test "citation:unknown:title not set:parent journal:parent author same:17:" do
#   try_citation(references(:unknown_in_journal_with_hooker_author_of_both), 
#                'Hooker, W.J., (1690) botanical magazine Edn. 1, 2.', 
#                'citation not set correctly for unknown with same author as parent')
# end

# test "citation:unknown:title not set:parent journal:parent author name dash:18:" do
#   try_citation(references(:burbidge_1946_JRSWA30), 
#                'Burbidge, N.T. in (1946) journal of the royal society of western australia 30.',
#                'citation not set correctly')
# end
# # Burbidge, N.T., (1946) Journal of the Royal Society of Western Australia 30

# test "citation:sturm:Enumerato Plantarum:198:" do
#   try_citation(references(:sturm_enumerato_plantarum), 
#                'Sturm, J.W., (1858) Enumeratio Plantarum Vascularum Cryptogamicarum Chilensium',
#                'citation not set correctly')
# end
# # Burbidge, N.T., (1946) Journal of the Royal Society of Western Australia 30
                 # /\AHooker, W\.J\., \(1690\) botanical magazine Edn\. 1, 2\.\z/, 
end
 
