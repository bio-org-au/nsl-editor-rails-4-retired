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
# Author Editing
class Author::AsEdited < Author::AsTypeahead
  AED = "Author::AsEdited:"
  def self.create(params, typeahead_params, username)
    author = Author::AsEdited.new(params)
    author.resolve_typeahead_params(typeahead_params)
    if author.save_with_username(username)
      author
    else
      raise author.errors.full_messages.first.to_s
    end
  rescue => e
    logger.error("#{AED}rescuing: #{e}")
    logger.error("Author::AsEdited#create; params: #{params};
                 typeahead params: #{typeahead_params}")
    raise
  end

  def update_if_changed(params, typeahead_params, username)
    logger.debug("#{AED}:update_if_changed params: #{params};
                 typeahead_params: #{typeahead_params}")
    params = empty_strings_should_be_nils(params)
    assign_attributes(params)
    resolve_typeahead_params(typeahead_params)
    if changed?
      logger.debug("Author::AsEdited has changed!")
      logger.debug("Author::AsEdited #{inspect}")
      self.updated_by = username
      save!
      "Updated"
    else
      "No change"
    end
  rescue => e
    logger.error("#{AED} params: #{params},
                 typeahead_params: #{typeahead_params}")
    logger.error("#{AED} error: #{e}")
    raise
  end

  # Empty strings as parameters for string fields are interpreted as a change.
  def empty_strings_should_be_nils(params)
    params["abbrev"] = nil if params["abbrev"] == ""
    params["name"] = nil if params["name"] == ""
    params["full_name"] = nil if params["full_name"] == ""
    params["notes"] = nil if params["notes"] == "" #
    params
  end

  def resolve_typeahead_params(params)
    logger.debug("#{AED}resolve_typeahead_params for params: #{params}")
    return unless params.key?(:duplicate_of_id)
    self.duplicate_of_id =
      Author::AsEdited.duplicate_of_from_typeahead(
        params[:duplicate_of_id],
        params[:duplicate_of_typeahead],
        id
      )
  rescue => e
    logger.error("#{AED}resolve_typeahead_params:found error: #{e}")
    raise
  end

  def self.duplicate_of_from_typeahead(id_string, text, current_id)
    logger.debug("#{AED}duplicate_of_from_typeahead:
                 id_string: #{id_string}; text: #{text};
                 current_id: #{current_id}")
    name_text = text.sub(/ *\|.*\z/, "")
    name_text.rstrip!
    logger.debug("#{AED}duplicate_of_from_typeahead: name_text: #{name_text}")
    case resolve_id_and_text(id_string, name_text)
    when :no_id_or_text
      value = ""
    when :id_only # assume delete
      value = ""
    when :text_only
      logger.info("#{AED}duplicate_of_from_typeahead: string")
      possibles = Author.lower_name_equals(name_text).not_this_id(current_id)
      case possibles.size
      when 0
        possibles = Author
                    .lower_name_like(name_text + "%")
                    .not_this_id(current_id)
        case possibles.size
        when 1
          value = possibles.first.id
        else
          raise "please choose duplicate of from suggestions"
        end
      when 1
        value = possibles.first.id
      else
        raise "please choose duplicate of from suggestions (more than 1 match)"
      end
    when :id_and_text
      logger.debug("#{AED}duplicate_of_from_typeahead: id and text")
      possibles = Author.lower_name_equals(name_text).not_this_id(current_id)
      case possibles.size
      when 0
        possibles =
          Author.lower_name_like(name_text + "%").not_this_id(current_id)
        case possibles.size
        when 1
          value = possibles.first.id
        else
          raise "please choose duplicate of from suggestions"
        end
      when 1
        value = possibles.first.id
      else
        possibles_with_id = Author
                            .where(id: id_string.to_i)
                            .lower_name_equals(name_text)
                            .not_this_id(current_id)
        if possibles_with_id.size == 1
          value = possibles_with_id.first.id
        else
          raise "please choose duplicate of from suggestions (more than 1 match)"
        end
      end
    else
      logger.debug("#{AED}duplicate_of_from_typeahead: strange data")
      raise "unrecognized information"
    end
    logger.debug("#{AED}duplicate_of_from_typeahead: returning value: #{value}")
    value
  end

  def self.resolve_id_and_text(id_string, text)
    if id_string.blank? && text.blank?
      return :no_id_or_text
    elsif id_string.blank? && text.present?
      return :text_only
    elsif id_string.present? && text.blank?
      return :id_only
    elsif id_string.present? && text.present?
      return :id_and_text
    else
      raise "please check your data"
    end
  end
end
