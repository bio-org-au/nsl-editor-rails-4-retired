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
class Search::OnName::WhereClauses

  def initialize(parsed_query, sql)
    @parsed_query = parsed_query
    @sql = sql
  end

  def sql
    Rails.logger.debug("Search::OnName::WhereClause.sql")
    remaining_string = @parsed_query.where_arguments.downcase 
    x = 0 
    until remaining_string.blank?
      Rails.logger.debug("loop")
      field,value,remaining_string = Search::OnName::NextCriterion.new(remaining_string).get 
      puts("field: #{field}; value: #{value}; remaining_string: #{remaining_string}")
      add_clause(field,value)
      x += 1
      raise "endless loop #{x}" if x > 10
    end
    @sql
  end

  def xadd_clause(field,value)
    if field.blank? && value.blank?
      @sql
    elsif field.blank?
      @sql = @sql.lower_full_name_like(value.downcase)
    else
      case field
      when /\Aname-rank:\z/
        if value.split(/,/).size == 1
          @sql = @sql.where("name_rank_id in (select id from name_rank where lower(name) like ?)",value)
        else
          @sql = @sql.where("name_rank_id in (select id from name_rank where lower(name) in (?))",value.split(',').collect {|v| v.strip})
        end
      when /\Abelow-name-rank:\z/
        @sql = @sql.where("name_rank_id in (select id from name_rank where sort_order > (select sort_order from name_rank the_nr where lower(the_nr.name) like ?))",value)
      when /\Aabove-name-rank:\z/
        @sql = @sql.where("name_rank_id in (select id from name_rank where sort_order < (select sort_order from name_rank the_nr where lower(the_nr.name) like ?))",value)
      end
    end
  end

  def add_clause(field,value)
    if field.blank? && value.blank?
      @sql
    elsif field.blank?
      @sql = @sql.lower_full_name_like(value.downcase)
    elsif value.split(/,/).size > 1
      case field
      when /\Aname-rank:\z/
        @sql = @sql.where("name_rank_id in (select id from name_rank where lower(name) in (?))",value.split(',').collect {|v| v.strip})
      end
    else
      @sql = @sql.where(WHERE_VALUE_HASH[field],value)
    end
  end

  WHERE_VALUE_HASH = { 
    'name-rank:' => "name_rank_id in (select id from name_rank where lower(name) like ?)",
    'below-name-rank:' => "name_rank_id in (select id from name_rank where sort_order > (select sort_order from name_rank the_nr where lower(the_nr.name) like ?))",
    'above-name-rank:' => "name_rank_id in (select id from name_rank where sort_order < (select sort_order from name_rank the_nr where lower(the_nr.name) like ?))"
  }
end



