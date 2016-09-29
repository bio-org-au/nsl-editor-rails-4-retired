# frozen_string_literal: true

# Name scopes
module NameScopable
  extend ActiveSupport::Concern
  included do
    scope :not_common_or_cultivar,
          (lambda do
             where([" name_type_id in (select id from
                    name_type where not (cultivar or
                    lower(name_type.name) = 'common'))"])
           end)
    scope :not_a_duplicate, -> { where(duplicate_of_id: nil) }
    scope :full_name_like,
          (lambda do |string|
             where("lower(f_unaccent(full_name)) like lower(f_unaccent(?)) ",
                   string.tr("*", "%") + "%")
           end)
    scope :lower_full_name_equals,
          (lambda do |string|
             where("lower(f_unaccent(full_name)) = lower(f_unaccent(?)) ",
                   string)
           end)
    scope :lower_full_name_like,
          (lambda do |string|
             where("lower(f_unaccent(full_name)) like lower(f_unaccent(?)) ",
                   string.tr("*", "%"))
           end)
    scope :order_by_full_name, -> { order("lower(full_name)") }
    scope :order_by_rank_and_full_name,
          -> { order("name_rank.sort_order, lower(full_name)") }
    scope :select_fields_for_typeahead,
          (lambda do
             select(" name.id, name.full_name, name_rank.name name_rank_name,
                    name_status.name name_status_name")
           end)
    scope :select_fields_for_parent_typeahead,
          (lambda do
             select(" name.id, name.full_name, name_rank.name name_rank_name,
                    name_status.name name_status_name, count(instance.id)
                    instance_count")
           end)
    scope :from_a_higher_rank,
          (lambda do |rank_id|
             joins(:name_rank).where("name_rank.sort_order < (select sort_order
                                     from name_rank where id = ?)", rank_id)
           end)
    scope :ranks_for_unranked,
          (lambda do
             joins(:name_rank)
              .where("name_rank.id in (select id from name_rank where
             sort_order <= (select sort_order from name_rank where name =
             'Subforma') or name_rank.name = '[unranked]') ")
           end)
    scope :ranks_for_unranked_assumes_join,
          (lambda do
             where("name_rank.sort_order <= (select sort_order from name_rank
                   where name = 'Subforma') or name_rank.name = '[unranked]' ")
           end)
    scope :but_rank_not_too_high,
          (lambda do |rank_id|
             where("name_rank.id in (select id from name_rank where sort_order
                  >= (select max(sort_order) from name_rank where major and name
                   not in ('Tribus','Ordo','Classis','Division') and sort_order
                   <  (select sort_order from name_rank where id = ?)))",
                   rank_id)
           end)
    scope :name_rank_not_deprecated, -> { where("not name_rank.deprecated") }
    scope :name_rank_not_infra,
          (lambda do
             where("name_rank.name not in
                   ('[infrafamily]','[infragenus]','[infrasp.]') ")
           end)
    scope :name_rank_not_na, -> { where("name_rank.name != '[n/a]' ") }
    scope :name_rank_not_unknown, -> { where("name_rank.name != '[unknown]' ") }
    scope :name_rank_not_unranked,
          -> { where("name_rank.name != '[unranked]' ") }
    scope :name_rank_species_and_below,
          (lambda do
             where("name_rank.sort_order >= (select sort_order from name_rank sp
                   where sp.name = 'Species')")
           end)
    scope :name_rank_genus_and_below,
          (lambda do
             where("name_rank.sort_order >= (select sort_order from name_rank
                   genus where genus.name = 'Genus')")
           end)
    scope :avoids_id, ->(avoid_id) { where("name.id != ?", avoid_id) }
    scope :all_children,
          (lambda do |parent_id|
             where("name.parent_id = ? or name.second_parent_id = ?",
                   parent_id, parent_id)
           end)
    scope :for_id, ->(id) { where("name.id = ?", id) }
  end
end
