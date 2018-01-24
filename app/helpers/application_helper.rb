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
module ApplicationHelper
  def disable_common_cultivar_checkbox
    !(params[:query_on].nil? || params[:query_on].match(/\Aname\z/i))
  end

  def parse_markdown(markdown)
    Kramdown::Document.new(markdown).to_html.html_safe
  end

  def nav_link(text, icon_name)
    "<div class='icon-for-menu'>#{menu_icon(icon_name)}</div>
    <div class='text-for-link'>#{text}</div>".html_safe
  end

  def increment_tab_index(increment = 1)
    @tab_index ||= 1
    @tab_index += increment
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

  def divider
    tag(:hr, class: "divider")
  end

  def lov_select_field(entity,
                       attribute,
                       cache,
                       options,
                       html_attributes,
                       label = "",
                       label_is = :description)
    content_tag(:section,
                select(entity,
                       attribute,
                       cache,
                       options,
                       html_attributes) +
                content_tag(:label,
                            treated_label(label, label_is),
                            class: "inline pull-right"),
                class: "editable-text-field block") +
      tag(:span,
          class: "field-error-message width-90-percent")
  end

  def formatted_timestamp(timestamp_with_timezone)
    l(timestamp_with_timezone, format: :default)
  end

  def as_date(timestamp_with_timezone)
    l(timestamp_with_timezone, format: :as_date)
  end

  def mapper_link(type, id)
    # we want to replace this with data pulled from the shard config table
    %(<a href="#{Rails.configuration.mapper_root_url}#{type}/#{Rails.configuration.mapper_shard}/#{id}" title="#{type.capitalize} #{id}"><i class="fa fa-link"></i></a>).html_safe
  end

  def page_title
    case Rails.configuration.try("environment")
    when /\Adev/i
      "Dev Editor"
    when /^test/i
      "Test Editor"
    when /^stag/i
      "Staging Ed"
    when /^prod/i
      ShardConfig.shard_group_name?+" Editor"
    else
      ShardConfig.shard_group_name?+" Editor"
    end
  end

  def badge
    page_title
  end

  def development?
    Rails.configuration.try("environment").match(/^development/i)
  end
end

# Some specific string methods.
class String
  def as_field_description
    tr("_", " ").gsub(/\bid\b/i, "ID")
  end

  def to_acronym
    tr("_", " ").upcase
  end
end
