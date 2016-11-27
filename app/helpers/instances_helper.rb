# frozen_string_literal: true

# Help for Instance display
module InstancesHelper
  def citation_summary(instance)
    instance.citations.collect do |c|
      c.instance_type.name
    end.collect.each_with_object(Hash.new(0)) do |o, h|
      h[o] += 1
    end.collect { |k, v| pluralize(v, k) }.join(" and ")
  end

  def show_field_as_linked_lookup(label,
                                  linked_entity,
                                  contents_method,
                                  url,
                                  title)
    if linked_entity
      show_field_as_linked_entity(label, linked_entity, contents_method, url,
                                  title)
    else # empty
      show_field_as_not_linked_entity(label)
    end
  end

  def show_field_as_linked_entity(label, linked_entity, contents_method, url,
                                  title)
    content_tag(:section,
                content_tag(:article,
                            content_tag(:a,
                                        linked_entity.send(contents_method),
                                        href: url,
                                        title: title),
                            class: "field-data inline") +
                field_label(label),
                class: "field-data")
  end

  def show_field_as_not_linked_entity(label)
    content_tag(:section,
                content_tag(:article,
                            content_tag(:span),
                            class: "field-data inline") +
                field_label(label),
                class: "field-data")
  end

  def field_label(label)
    content_tag(:label,
                label.as_field_description,
                class: "field-label inline pull-right")
  end

  def tab_for_instance_type(tab, row_type)
    if tab == "tab_show_1" ||
       tab == "tab_edit" ||
       tab == "tab_edit_notes" || tab == "tab_comments" ||
       tab == "tab_apc_placement"
      tab
    elsif row_type == "instance_as_part_of_concept_record"
      if tab == "tab_synonymy" ||
         tab == "tab_unpublished_citation" ||
         # TODO: remove this - NSL-2007
         tab == "tab_apc_placement" ||
         tab == "tab_classification" ||
         tab == "tab_copy_to_new_reference"
        tab
      else
        "tab_empty"
      end
    elsif row_type == "citing_instance_within_name_search"
      if tab == "tab_synonymy" ||
         tab == "tab_create_unpublished_citation" ||
         # TODO: remove this - NSL-2007
         tab == "tab_apc_placement"
        tab
      elsif tab == "tab_copy_to_new_reference"
        "tab_copy_to_new_reference_na"
      else
        "tab_empty"
      end
    else
      "tab_empty"
    end
  end
end
