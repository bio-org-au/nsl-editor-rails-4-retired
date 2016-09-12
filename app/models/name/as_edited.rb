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
class Name::AsEdited < Name::AsTypeahead
  def self.create(params, typeahead_params, username)
    name = Name::AsEdited.new(params)
    name.resolve_typeahead_params(typeahead_params)
    if name.save_with_username(username)
      name.set_names!
    else
      raise name.errors.full_messages.first.to_s
    end
    name
  rescue => e
    logger.error("Name::AsEdited:rescuing: #{e}")
    logger.error("Name::AsEdited#create; params: #{params};
                 typeahead params: #{typeahead_params}")
    raise
  end

  def update_if_changed(params, typeahead_params, username)
    # empty string "changes" null field
    params["verbatim_rank"] = nil if params["verbatim_rank"] == ""
    assign_attributes(params)
    resolve_typeahead_params(typeahead_params)
    if changed?
      self.updated_by = username
      save!
      set_names!
      "Updated"
    else
      "No change"
    end
  rescue => e
    logger.error("Name::AsEdited with params: #{params}")
    logger.error("Name::AsEdited with typeahead_params: #{typeahead_params}")
    logger.error("Name::AsEdited error: #{e}")
    raise
  end

  def resolve_typeahead_params(params)
    logger.debug("Name:AsEdited.resolve_typeahead_params for params: #{params}")

    if params.key?("author_id")
      self.author_id =
        Name::AsEdited.author_from_typeahead(params["author_id"],
                                             params["author_typeahead"],
                                             "Author")
    end

    if params.key?("ex_author_id")
      self.ex_author_id =
        Name::AsEdited.author_from_typeahead(params["ex_author_id"],
                                             params["ex_author_typeahead"],
                                             "Ex Author")
    end

    if params.key?("base_author_id")
      self.base_author_id =
        Name::AsEdited.author_from_typeahead(params["base_author_id"],
                                             params["base_author_typeahead"],
                                             "Base Author")
    end

    if params.key?("ex_base_author_id")
      self.ex_base_author_id =
        Name::AsEdited.author_from_typeahead(params["ex_base_author_id"],
                                             params["ex_base_author_typeahead"],
                                             "Ex Base Author")
    end

    if params.key?("sanctioning_author_id")
      self.sanctioning_author_id =
        Name::AsEdited
        .author_from_typeahead(params["sanctioning_author_id"],
                               params["sanctioning_author_typeahead"],
                               "Sanctioning Author")
    end

    if params.key?("parent_id")
      self.parent_id =
        Name::AsEdited.parent_from_typeahead(params["parent_id"],
                                             params["parent_typeahead"])
    end

    if params.key?("second_parent_id")
      self.second_parent_id =
        Name::AsEdited.parent_from_typeahead(params["second_parent_id"],
                                             params["second_parent_typeahead"])
    end

    if params.key?("duplicate_of_id")
      self.duplicate_of_id =
        Name::AsEdited
        .duplicate_of_from_typeahead(params["duplicate_of_id"],
                                     params["duplicate_of_typeahead"])
    end

  rescue => e
    logger.error("Name::AsEdited:resolve_typeahead_params:found error: #{e}")
    raise
  end

  def self.author_from_typeahead(id_string, text, field_name)
    logger.debug("Name::AsEdited:author_from_typeahead:
                 id_string: #{id_string}; text: #{text}")
    text = text.sub(/ *\|.*\z/, "")
    text.rstrip!
    case resolve_id_and_text(id_string, text)
    when :no_id_or_text
      value = ""
    when :id_only # assume delete
      value = ""
    when :text_only
      possibles = Author.lower_abbrev_equals(text)
      case possibles.size
      when 0
        possibles = Author.lower_abbrev_like(text + "%")
        case possibles.size
        when 1
          value = possibles.first.id
        else
          raise "please choose #{field_name} from suggestions"
        end
      when 1
        value = possibles.first.id
      else
        raise "please choose #{field_name} from suggestions (more than 1 match)"
      end
    when :id_and_text
      possibles = Author.lower_abbrev_equals(text)
      case possibles.size
      when 0
        possibles = Author.lower_abbrev_like(text + "%")
        case possibles.size
        when 1
          value = possibles.first.id
        else
          raise "please choose #{field_name} from suggestions"
        end
      when 1
        value = possibles.first.id
      else
        possibles_with_id = Author
                            .where(id: id_string.to_i)
                            .lower_abbrev_equals(text)
        if possibles_with_id.size == 1
          value = possibles_with_id.first.id
        else
          raise "please choose #{field_name} from suggestions (> 1 match)"
        end
      end
    else
      raise "please check the #{field_name}"
    end
    value
  end

  def self.parent_from_typeahead(id_string, text)
    logger.debug("Name::AsEdited:parent_from_typeahead:
                 id_string: #{id_string}; text: #{text}")
    text = text.sub(/ *\|.*\z/, "")
    text.rstrip!
    logger.debug("Name::AsEdited:parent_from_typeahead: text: #{text}")
    case resolve_id_and_text(id_string, text)
    when :no_id_or_text
      raise "please choose parent from suggestions"
    when :id_only # assume delete
      raise "please choose parent from suggestions"
    when :text_only
      logger.info("Name::AsEdited:parent_from_typeahead: check string")
      possibles = Name.lower_full_name_like(text).not_a_duplicate
      case possibles.size
      when 0
        possibles = Name.lower_full_name_like(text + "%").not_a_duplicate
        case possibles.size
        when 1
          value = possibles.first.id
        else
          raise "please choose parent from suggestions"
        end
      when 1
        value = possibles.first.id
      else
        raise "please choose parent from suggestions (more than 1 match)"
      end
    when :id_and_text
      # use the text
      logger.debug("Name::AsEdited:parent_from_typeahead: id and text")
      possibles = Name.lower_full_name_like(text).not_a_duplicate
      case possibles.size
      when 0
        possibles = Name.lower_full_name_like(text + "%").not_a_duplicate
        case possibles.size
        when 1
          value = possibles.first.id
        else
          raise "please choose parent from suggestions"
        end
      when 1
        value = possibles.first.id
      else
        possibles_with_id = Name
                            .where(id: id_string.to_i)
                            .lower_full_name_like(text)
                            .not_a_duplicate
        if possibles_with_id.size == 1
          value = possibles_with_id.first.id
        else
          raise "please choose parent from suggestions (more than 1 match)"
        end
      end
    else
      logger.debug("Name::AsEdited:parent_from_typeahead: strange data")
      raise "please check Parent"
    end
    logger.debug("Name::AsEdited:parent_from_typeahead:
                 returning value: #{value}")
    value
  end

  def self.duplicate_of_from_typeahead(id_string, text)
    logger.debug("Name::AsEdited:duplicate_of_from_typeahead:
                 id_string: #{id_string}; text: #{text}")
    text = text.sub(/ *\|.*\z/, "")
    text.rstrip!
    logger.debug("Name::AsEdited:duplicate_of_from_typeahead: text: #{text}")
    case resolve_id_and_text(id_string, text)
    when :no_id_or_text
      value = ""
    when :id_only # assume delete
      value = ""
    when :text_only
      logger.info("Name::AsEdited:duplicate_of_from_typeahead: string")
      possibles = Name.lower_full_name_like(text)
      case possibles.size
      when 0
        possibles = Name.lower_full_name_like(text + "%")
        case possibles.size
        when 1
          value = possibles.first.id
        else
          raise "please choose parent from suggestions"
        end
      when 1
        value = possibles.first.id
      else
        raise "please choose duplicate of from suggestions (more than 1 match)"
      end
    when :id_and_text
      logger.debug("Name::AsEdited:duplicate_of_from_typeahead: id and text")
      possibles = Name.lower_full_name_equals(text)
      case possibles.size
      when 0
        possibles = Name.lower_full_name_like(text + "%")
        case possibles.size
        when 1
          value = possibles.first.id
        else
          raise "please choose parent from suggestions"
        end
      when 1
        value = possibles.first.id
      else
        possibles_with_id = Name
                            .where(id: id_string.to_i)
                            .lower_full_name_equals(text)
        if possibles_with_id.size == 1
          value = possibles_with_id.first.id
        else
          raise "please pick duplicate of from suggestions (more than 1 match)"
        end
      end
    else
      logger.debug("Name::AsEdited:duplicate_of_from_typeahead: strange data")
      raise "unrecognized information"
    end
    logger.debug("Name::AsEdited:duplicate_of_from_typeahead:
                 returning value: #{value}")
    value
  end

  def self.resolve_id_and_text(id_string, text)
    if id_string.blank? && text.blank?
      return :no_id_or_text
    elsif id_string.blank? && text.present?
      return :text_only
    elsif id_string.present? && text.blank?
      return :id_only # assume intention was to remove the field value
    elsif id_string.present? && text.present?
      return :id_and_text
    else
      raise "please check your data"
    end
  end
end
