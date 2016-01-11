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
class Reference::AsEdited < Reference::AsTypeahead
  def self.create(params, typeahead_params, username)
    reference = Reference::AsEdited.new(params)
    reference.resolve_typeahead_params(typeahead_params)
    if reference.save_with_username(username)
      reference.set_citation!
    else
      fail "#{reference.errors.full_messages.first}"
    end
    reference
  rescue => e
    logger.error("Reference::AsEdited:rescuing: #{e}")
    logger.error("Reference::AsEdited#create; params: #{params}; typeahead params: #{typeahead_params}")
    raise
  end

  def debug(s)
    logger.debug("Reference::AsEdited: #{s}")
  end

  def update_if_changed(params, typeahead_params, username)
    params = empty_strings_should_be_nils(params)
    assign_attributes(params)
    resolve_typeahead_params(typeahead_params)
    if changed?
      if just_setting_duplicate_of_id
        just_set_duplicate_of_id(typeahead_params, username)
      else
        self.updated_by = username
        save!
        set_citation!
        "Updated"
      end
    else
      "No change."
    end
  rescue => e
    logger.error("Reference::AsEdited with params: #{params}, typeahead_params: #{typeahead_params}")
    logger.error("Reference::AsEdited with params: #{e}")
    raise
  end

  def just_setting_duplicate_of_id
    changed_attributes.size == 1 && changed_attributes.key?("duplicate_of_id")
  end

  def just_set_duplicate_of_id(params, username)
    if params["duplicate_of_typeahead"].blank?
      update_attribute(:duplicate_of_id, nil)
      update_attribute(:updated_by, username)
      "Duplicate cleared"
    else
      update_attribute(:duplicate_of_id, params["duplicate_of_id"])
      update_attribute(:updated_by, username)
      "Duplicate set"
    end
  end

  # Empty strings as parameters for string fields are interpreted as a change.
  def empty_strings_should_be_nils(params)
    params["edition"] = nil if params["edition"] == ""
    params["volume"] = nil if params["volume"] == ""
    params["notes"] = nil if params["notes"] == ""
    params["pages"] = nil if params["pages"] == ""
    params["publication_date"] = nil if params["publication_date"] == ""
    params["publisher"] = nil if params["publisher"] == ""
    params["published_location"] = nil if params["published_location"] == ""
    params["abbrev_title"] = nil if params["abbrev_title"] == ""
    params["display_title"] = nil if params["display_title"] == ""
    params["bhl_url"] = nil if params["bhl_url"] == ""
    params["doi"] = nil if params["doi"] == ""
    params["tl2"] = nil if params["tl2"] == ""
    params["isbn"] = nil if params["isbn"] == ""
    params["issn"] = nil if params["issn"] == ""
    params
  end

  def resolve_typeahead_params(params)
    self.author_id = Reference::AsEdited.author_from_typeahead(params["author_id"], params["author_typeahead"]) if params.key?("author_id")
    self.parent_id = Reference::AsEdited.parent_from_typeahead(params["parent_id"], params["parent_typeahead"]) if params.key?("parent_id")
    self.duplicate_of_id = Reference::AsEdited.duplicate_of_from_typeahead(params["duplicate_of_id"], params["duplicate_of_typeahead"]) if params.key?("duplicate_of_id")
  rescue => e
    logger.error("Reference::AsEdited:resolved_typeahead_params: rescuing exception: #{e}")
    raise
  end

  def self.author_from_typeahead(id_string, text)
    logger.debug("Reference::AsEdited:author_from_typeahead: id_string: #{id_string}; text: #{text}")
    name_text = text.sub(/ *\|.*\z/, "")
    name_text.rstrip!
    logger.debug("Reference::AsEdited:author_from_typeahead: name_text: #{name_text}")
    case resolve_id_and_text(id_string, name_text)
    when :no_id_or_text
      value = ""
    when :id_only # assume delete
      value = ""
    when :text_only
      logger.info("Reference::AsEdited:author_from_typeahead: string")
      possibles = Author.lower_name_equals(name_text)
      case possibles.size
      when 0
        possibles = Author.lower_name_like(name_text + "%")
        case possibles.size
        when 1
          value = possibles.first.id
        else
          fail "please choose author from suggestions"
        end
      when 1
        value = possibles.first.id
      else
        fail "please choose author from suggestions (more than 1 match)"
      end
    when :id_and_text
      logger.debug("Reference::AsEdited:author_from_typeahead: id and text")
      possibles = Author.lower_name_equals(name_text)
      case possibles.size
      when 0
        possibles = Author.lower_name_like(name_text + "%")
        case possibles.size
        when 1
          value = possibles.first.id
        else
          fail "please choose author from suggestions"
        end
      when 1
        value = possibles.first.id
      else
        possibles_with_id = Author.where(id: id_string.to_i).lower_name_equals(name_text)
        if possibles_with_id.size == 1
          value = possibles_with_id.first.id
        else
          fail "please choose author from suggestions (more than 1 match)"
        end
      end
    else
      logger.debug("Reference::AsEdited:author_from_typeahead: strange data")
      fail "unrecognized information"
    end
    logger.debug("Reference::AsEdited:author_from_typeahead: returning value: #{value}")
    value
  end

  def self.parent_from_typeahead(id_string, text)
    logger.debug("Reference::AsEdited:parent_from_typeahead: id_string: #{id_string}; text: #{text}")
    text = text.sub(/ *\|.*\z/, "")
    text.rstrip!
    logger.debug("Reference::AsEdited:parent_from_typeahead: text: #{text}")
    case resolve_id_and_text(id_string, text)
    when :no_id_or_text
      value = ""
    when :id_only # assume delete
      value = ""
    when :text_only
      logger.info("Reference::AsEdited:parent_from_typeahead: string")
      possibles = Reference.lower_citation_equals(text)
      case possibles.size
      when 0
        possibles = Reference.lower_citation_like(text + "%")
        case possibles.size
        when 1
          value = possibles.first.id
        else
          fail "please choose parent from suggestions"
        end
      when 1
        value = possibles.first.id
      else
        fail "please choose parent from suggestions (more than 1 match)"
      end
    when :id_and_text
      logger.debug("Reference::AsEdited:parent_from_typeahead: id and text")
      possibles = Reference.lower_citation_equals(text)
      case possibles.size
      when 0
        possibles = Reference.lower_citation_like(text + "%")
        case possibles.size
        when 1
          value = possibles.first.id
        else
          fail "please choose duplicate of from suggestions"
        end
      when 1
        value = possibles.first.id
      else
        possibles_with_id = Reference.where(id: id_string.to_i).lower_citation_equals(text)
        if possibles_with_id.size == 1
          value = possibles_with_id.first.id
        else
          fail "please choose parent from suggestions (more than 1 match)"
        end
      end
    else
      logger.debug("Reference::AsEdited:parent_from_typeahead: strange data")
      fail "unrecognized information"
    end
    logger.debug("Reference::AsEdited:parent_from_typeahead: returning value: #{value}")
    value
  end

  def self.duplicate_of_from_typeahead(id_string, text)
    logger.debug("Reference::AsEdited:duplicate_of_from_typeahead: id_string: #{id_string}; text: #{text}")
    citation_text = text.sub(/ *\|.*\z/, "")
    citation_text.rstrip!
    logger.debug("Reference::AsEdited:duplicate_of_from_typeahead: citation_text: #{citation_text}")
    case resolve_id_and_text(id_string, citation_text)
    when :no_id_or_text
      value = ""
    when :id_only # assume delete
      value = ""
    when :text_only
      logger.info("Reference::AsEdited:duplicate_of_from_typeahead: string")
      possibles = Reference.lower_citation_equals(citation_text)
      case possibles.size
      when 0
        possibles = Reference.lower_citation_like(citation_text + "%")
        case possibles.size
        when 1
          value = possibles.first.id
        else
          fail "please choose duplicate of from suggestions"
        end
      when 1
        value = possibles.first.id
      else
        fail "please choose duplicate of from suggestions (more than 1 match)"
      end
    when :id_and_text
      logger.debug("Reference::AsEdited:duplicate_of_from_typeahead: id and text")
      possibles = Reference.lower_citation_equals(citation_text)
      case possibles.size
      when 0
        possibles = Reference.lower_citation_like(citation_text + "%")
        case possibles.size
        when 1
          value = possibles.first.id
        else
          fail "please choose duplicate of from suggestions"
        end
      when 1
        value = possibles.first.id
      else
        possibles_with_id = Reference.where(id: id_string.to_i).lower_citation_equals(citation_text)
        if possibles_with_id.size == 1
          value = possibles_with_id.first.id
        else
          fail "please choose duplicate of from suggestions (more than 1 match)"
        end
      end
    else
      logger.debug("Reference::AsEdited:duplicate_of_from_typeahead: strange data")
      fail "unrecognized information"
    end
    logger.debug("Reference::AsEdited:duplicate_of_from_typeahead: returning value: #{value}")
    value
  end

  def self.resolve_id_and_text(id_string, text)
    if id_string.blank? && text.blank?
      return :no_id_or_text
    elsif id_string.blank? && text.present?
      return :text_only
    elsif id_string.present? && text.blank?
      return :id_only # assume intention was (ultimately) to remove the field value
    elsif id_string.present? && text.present?
      return :id_and_text
    else
      fail "please check your data"
    end
  end
end
