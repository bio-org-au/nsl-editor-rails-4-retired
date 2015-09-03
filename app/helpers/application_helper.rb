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
module ApplicationHelper

  def disable_common_cultivar_checkbox
    !(params[:query_on].nil? || params[:query_on].match(/\Aname\z/i))
  end

  def display_pages(pages = '')
    if pages.blank?
      ''
    elsif pages.match(/null - null/)
      ''
    else
      " : #{pages}"
    end
  end

  def menu_icon(entity)
    '' # entity_icon(entity, 10,6)
  end
  
  def record_icon(entity)
    entity_icon(entity,13,7)
  end

  def entity_icon(entity, height = 10, width = 10 )
    color_for = {'name' => "rgba(102,183,39,1.0)", 'author' => "rgba(52,114,218,1.0)", 'reference' => "rgba(245,172,0,1.0)", 'instance' => "rgba(197,151,203,1.0)"}
    content_tag(:svg,
      tag(:polygon, class:"svgpolygon", points:"2,3, #{2 + width},3,  #{2 + width},23  2,23", fill:color_for[entity]),
      class:"icon name-icon", 
      height:"#{height}px",
      width:"#{width}px", 
      xmlns:"http://www.w3.org/2000/svg",
      title:entity.capitalize)    
  end

  def create_button
    return ''
  end

  def changed_link
    ''
  end

  def help_about
    help_topic_marked_up_text("About the NSL Editor")
  end

  def help_topic_marked_up_text(name)
    help_topic = HelpTopic.where(["lower(name) like ?",name.downcase]).first
    help_topic ? parse_markdown(help_topic.marked_up_text) : "No help found. Expected: #{name}"
  end

  def help_fields_for_searching
    help_topic_marked_up_text("Fields for searching #{params[:controller]}")
  end

  def parse_markdown(markdown)
    Kramdown::Document.new(markdown).to_html.html_safe
  end

  def nav_link(text,icon_name)
    "<div class='icon-for-menu'>#{menu_icon(icon_name)}</div><div class='text-for-link'>#{text}</div>".html_safe
  end

  def show_path(controller)
    case controller
    when 'authors'
      author_path(1)
    when 'references'
      reference_path(1)
    when 'help_topics'
      help_topic_path(1)
    else
      ''     
    end 
  end


  def increment_tab_index(increment = 1)
    @tab_index ||= 1
    @tab_index = @tab_index + increment
  end

  def title(*parts)
    unless parts.empty? 
      content_for :title do
        (parts.unshift("NSL")).join(" - ") unless parts.empty? 
      end
    end 
  end
  
#  def toolbar_heading(which_one = '')
#    case which_one
#      when :new_reference
#        content_for :toolbar_heading do
#          'New Reference'
#        end
#      else
#        content_for :toolbar_heading do
#          'NSL Entity'
#        end
#      end
#  end
#
#  def create_button
#    return ''
#  end
#
#  def sidebar_changed_link
#    ''
#  end
#
#  def markdown(text)
#    @markdown.render(text).html_safe
#  end
#
#  def show_path(controller)
#    case controller
#    when 'authors'
#      author_path(1)
#    when 'references'
#      reference_path(1)
#    when 'help_topics'
#      help_topic_path(1)
#    else
#      ''     
#    end 
#  end
#
  def index_path(controller)
    case controller
    when 'authors'
      authors_path(1)
    when 'references'
      references_path(1)
    when 'help_topics'
      help_topics_path(1)
    else
      ''     
    end 
  end

#
#  def help_about
#    help_topic_marked_up_text("About the NSL Editor")
#  end
#
#  def help_topic_marked_up_text(name)
#    help_topic = HelpTopic.where(["lower(name) like ?",name.downcase]).first
#    help_topic ? BlueFeather.parse(help_topic.marked_up_text).html_safe : "No help found. Expected: #{name}"
#  end
#
#  def show_timestamp(label,date,user,label_is = :description)
#    content_tag(:section,content_tag(:article,%Q(#{date.strftime("%d-%b-%Y")} #{user}) ,class:'field-data inline') + content_tag(:label,treated_label(label,label_is),class:'field-label inline pull-right'),class:'field-data') 
#  end
#
  def show_ref_parent_link(label,reference,contents_method,url,title)
    if reference.parent 
        content_tag(:section,content_tag(:article,
                  content_tag(:a,"#{reference.parent.title}",href:url,title: title),class:'field-data inline') + 
                  content_tag(:label,label.as_field_description,class:'field-label inline pull-right'),class:'field-data')
    else # empty
      content_tag(:section,content_tag(:article,
        content_tag(:span),class:'field-data inline') + 
        content_tag(:label, label.as_field_description,class:'field-label inline pull-right'),class:'field-data')
    end
  end

  def show_ref_children_link(label,reference,contents_method,url,title)
    if reference.children && reference.children.size != 0
        ref_string = reference.children.size == 1 ? 'reference' : 'references'
        content_tag(:section,content_tag(:article,
                  content_tag(:a,"#{reference.children.size} #{ref_string}",href:url,title: title),class:'field-data inline') + 
                  content_tag(:label,label.as_field_description,class:'field-label inline pull-right'),class:'field-data')
    else # empty
      content_tag(:section,content_tag(:article,
        content_tag(:span),class:'field-data inline') + 
        content_tag(:label, label.as_field_description,class:'field-label inline pull-right'),class:'field-data')
    end
  end

  def show_children_query_link(label,parent,children_method,url,title,descriptor_singular,descriptor_plural)
    if parent.send(children_method) && parent.send(children_method).size != 0
        ref_string = parent.send(children_method).size == 1 ? descriptor_singular : descriptor_plural
        content_tag(:section,content_tag(:article,
                  content_tag(:a,"#{parent.send(children_method).size} #{ref_string}",href:url,title: title),class:'field-data inline') + 
                  content_tag(:label,label.as_field_description,class:'field-label inline pull-right'),class:'field-data')
    else # empty
      content_tag(:section,content_tag(:article,
        content_tag(:span),class:'field-data inline') + 
        content_tag(:label, label.as_field_description,class:'field-label inline pull-right'),class:'field-data')
    end
  end
  
  def show_field_as_linked_lookup(label,linked_entity,contents_method,url,title)
    if linked_entity
      content_tag(:section,content_tag(:article,
        content_tag(:a,linked_entity.send(contents_method),href:url,title: title),class:'field-data inline') + 
        content_tag(:label, label.as_field_description,class:'field-label inline pull-right'),class:'field-data') 
    else # empty
      content_tag(:section,content_tag(:article,
        content_tag(:span),class:'field-data inline') + 
        content_tag(:label, label.as_field_description,class:'field-label inline pull-right'),class:'field-data') 
    end
  end

  def show_field_as_link(text,url,title,label,label_is = :description, content_is = :text)
    content_tag(:section,
                content_tag(:article,
                            treated_content(Hash[text: text, 
                                                 url: url, 
                                                 title: title],
                                                 :link),
                            class:'field-data inline') + content_tag(:label,
                                                                       treated_label(label,label_is),
                                                                       class:'field-label inline pull-right'),
                class:'field-data') 
  end

  # Deprecate.  Prefer render partial: 'detail_line'.
  def show_field(label,contents,label_is = :description, content_is = :text, field_class = 'width-50-percent', label_class = '')
    if label.length > 8
      field_width_class = 'width-50-percent'
      label_width_class = 'width-50-percent'
    else
      field_width_class = 'width-80-percent'
      label_width_class = 'width-10-percent'
    end
    content_tag(:section,content_tag(:article,treated_content(contents,content_is),class:"field-data inline-block #{field_class}") + 
      content_tag(:label,treated_label(label,label_is),class:"field-label inline pull-right #{label_class}"),class:'field-data') 
  end
  
  def treated_label(label, treatment = :description)
    case treatment
    when :description
      label.as_field_description
    when :acronym
      label.to_acronym
    else
      label
    end
  end

  def treated_content(contents, treatment = :text)
    case treatment
    when :date 
      contents.strftime("%d-%b-%Y")
    when :link
      content_tag(:a,contents[:text],href:contents[:url],title: contents[:title])
    else
      contents
    end
  end
  
  def divider
    tag(:hr,class: 'divider')
  end
  
  def editable_text_field(form_field,label,label_is = :description)
    content_tag(:section,form_field + 
                         content_tag(:label,treated_label(label,label_is),class: 'inline pull-right') +
                         tag(:div,class: 'field-error-message width-80-percent'),
                         class:'editable-text-field block')
   
  end
  
  def typeahead_field(form_field,label,label_is = :description)
    content_tag(:section,
                form_field + 
                content_tag(:label,
                            treated_label(label,label_is),
                            class: 'block-inline field-label align-right width-20-percent pull-right'),
                class:'block width-100-percent')
   
  end

  def lov_select_field(entity,attribute,cache,options,html_attributes,label = '',label_is = :description)
    content_tag(:section,select(entity,attribute, cache, options,html_attributes) + content_tag(:label,treated_label(label,label_is),
      class: 'inline pull-right'),class:'editable-text-field block') +
    tag(:span,class: 'field-error-message width-90-percent')
  end
                           
  def formatted_timestamp(timestamp_with_timezone)
    l(timestamp_with_timezone,format: :default)
  end
                           
  def as_date(timestamp_with_timezone)
    l(timestamp_with_timezone,format: :as_date)
  end

  def icon(icon, text="", html_options={})
    content_class = "fa fa-#{icon}"
    content_class << " #{html_options[:class]}" if html_options.key?(:class)
    html_options[:class] = content_class
    html = content_tag(:i, nil, html_options)
    html << " #{text}" unless text.blank?
    html.html_safe
  end

  def search_icon_on_tab
    icon('search')
  end

  def gray_search_icon
    icon('search','',{class:'darkgray'})
  end

  def tab_for_instance_type(tab,row_type)
    if tab == 'tab_show_1'  || tab == 'tab_edit' || tab == 'tab_edit_notes' || tab == 'tab_comments'
      tab
    elsif row_type == 'instance_as_part_of_concept_record'
      if tab == 'tab_synonymy' || tab == 'tab_unpublished_citation' || tab == 'tab_apc_placement' || tab == 'tab_copy_to_new_reference'
        tab
      else
        'tab_empty'
      end
    elsif row_type == 'citing_instance_within_name_search'
      if tab == 'tab_synonymy' || tab == 'tab_create_unpublished_citation' || tab == 'tab_apc_placement' 
        tab
      elsif tab == 'tab_copy_to_new_reference'
        'tab_copy_to_new_reference_na'
      else
        'tab_empty'
      end
    else
      'tab_empty'
    end
  end

  def citation_summary(instance)
    instance.citations.collect{|c| c.instance_type.name}.collect.each_with_object(Hash.new(0)) {|o,h| h[o] += 1}.collect { |k,v| pluralize(v,k) }.join(' and ')
  end

end


class String
  
  def as_field_description
    self.gsub(/_/,' ').gsub(/\bid\b/i,'ID')
  end

 def to_acronym
   self.gsub(/_/,' ').upcase
 end

end
