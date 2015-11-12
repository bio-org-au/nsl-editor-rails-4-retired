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
class Search

  UNLIMITED_QUERY_AMOUNT = 1000000000

  attr_reader :results, :search_string, :on, :clean_search_string, 
   :rejected_pairings, :limited, :focus_anchor_id, :limit, :info, :common_and_cultivar,
   :model, :field

  def initialize(search_string = "", query_on = 'name', query_limit = 100, query_common_and_cultivar = 'f', query_sort = '', query_field)
    Rails.logger.debug(%Q(New search for "#{search_string}" on #{query_on ||
                      '(query_on is nil!)'} up to #{query_limit || '(query_limit is nil!)'} with field: #{query_field}))
    Rails.logger.debug(%Q(query_common_and_cultivar: #{query_common_and_cultivar}))
    query_limit = 'all' if query_limit.blank?
    @search_string = search_string
    @on = query_on || 'name'
    @field = query_field || ''
    if query_limit.match(/\Aall\z/i)
      @limit = UNLIMITED_QUERY_AMOUNT
      @apply_limit = false
    else
      @apply_limit = true
      @limit = query_limit.to_i
      @limit = 100 if @limit == 0
    end
    @sort = query_sort || ''
    Rails.logger.debug("Init. query_sort: #{query_sort}")
    @common_and_cultivar = query_common_and_cultivar == 't' 
    @clean_search_string = clean_up_search_tokens(@search_string)
    Rails.logger.debug("before - @clean_search_string: #{@clean_search_string}; @on: #{@on}")
    @on, @clean_search_string = extract_search_target(@clean_search_string,@on)
    Rails.logger.debug("after - @clean_search_string: #{@clean_search_string}; @on: #{@on}")

    @results = []
    @limited = false
    @focus_anchor_id = nil
    @model = which_model
    # Ignore the query_field parameter if the search string starts with a query-field token.
    if @clean_search_string.match(/\A *[A-z-]+:/)
      @rejected_pairings ||= []
      @rejected_pairings.push([query_field,''])
    else
      @clean_search_string = "#{query_field}: #{@clean_search_string}" unless query_field.blank?
    end
    Rails.logger.debug("with field - @clean_search_string: #{@clean_search_string}; @on: #{@on}")
    @info = []
    @instance_note_key = instance_note_key?
    Rails.logger.debug("common_and_cultivar: #{@common_and_cultivar}")
    @count_wanted = false
    execute_query
  end 

  def clean_up_search_tokens(search_string)
    search_string.gsub(/ +:/,':')
  end

  # The search_string may be like: "ref: some text".
  # We want to pay attention to the search target ("ref:") but remove it from the search string.
  # If the search string has supplied a search target, we have to decide whether it takes
  # priority over the formal search target from the search form dropdown.  Ugly, I know.
  def extract_search_target(search_string,search_target)
    Rails.logger.debug("extract_search_target: from search_string: #{search_string}, with search target: #{search_target}")
    search_string =
        case search_string
          when /ref:/
            string_search_target = 'reference'
            search_string.gsub(/ref:/,'')
          when /name:/
            string_search_target = 'name'
            search_string.gsub(/name:/,'')
          when /[\s]author:/
            string_search_target = 'author'
            search_string.gsub(/author:/,'')
          when /instance:/
            string_search_target = 'instance'
            search_string.gsub(/instance:/,'')
          else
            string_search_target = nil
            search_string
        end
    string_search_target_takes_priority = true
    if string_search_target_takes_priority
      search_target = string_search_target || search_target || 'name'
    else
      if search_target.nil?
        search_target = string_search_target || 'name'
      end
    end
    Rails.logger.debug("extract_search_target: new search_string: #{search_string}, new search target: #{search_target}")
    return search_target, search_string
  end

  def execute_query
    Rails.logger.debug("\nSearch engine executing one #{@model} query.")
    Rails.logger.debug("-----------------------------------#{@model.to_s.gsub(/./,'-')}")
    Rails.logger.debug("@clean_search_string: #{@clean_search_string}")
    Rails.logger.debug("query_without_model: #{query_without_model}")
    if @model == Instance
      run_search
    elsif @model == Name && @field =~ /for.reference/
      Rails.logger.debug('name for reference query ......')
      run_search
    elsif @model == Author || @model == Name
      @results,
      @rejected_pairings,
      @limited,
      @focus_anchor_id,
      @info = @model::AsSearchEngine.search(query_without_model,@limit,@count_wanted,!@common_and_cultivar,!@retrieve_all_records)
    else
      @results,
      @rejected_pairings,
      @limited,
      @focus_anchor_id,
      @info = @model.search(query_without_model,@limit,@count_wanted,!@common_and_cultivar,!@retrieve_all_records)
    end
    @limited = @results.size == @limit
    Rails.logger.debug("\nAfter executing query: @limit: #{@limit}; @limited: #{@limited}; @results: #{results.size}; @limited: #{@limit == @results.size}; @info: #{@info}\n")
  end
 
  def record_type
    @model.to_s.downcase
  end

  def false_for(arg)
    false
  end
  
  def run_search
    Rails.logger.debug(%Q(Search model run_search for #{@model} for : "#{@search_string}" in "#{@field}", up to #{@limit} record(s)))
    Rails.logger.debug("Apply limit: #{@apply_limit}")
    Rails.logger.debug("@info: #{@info}")
    @results = []
    @rejected_pairings = []
    if @search_string.blank? && @field.nil?
      Rails.logger.error('Empty search string and search field')
    elsif @model == Name && @field.match(/\Afor-reference\z/i)
      @info.push("names for reference #{search_string} up to #{@limit} initial record(s)")
      Rails.logger.debug('found name(s) for-reference')
      Rails.logger.debug("@info: #{@info}")
      # This switches a name search to what it needs to be - an instance search.
      @results = Instance.ref_usages(@search_string,@limit,false_for(:show_instances))
    elsif @field.match(/\Aname-instances\z/i) 
      @results = Instance.name_instances(@search_string.sub(/.*name-instances: */,''),@limit,@apply_limit)
      if @apply_limit
        @info.push(%Q(Instances for name search on "#{@search_string}" for up to #{@limit} name(s).))
      else
        @info.push(%Q(Instances for name search on "#{@search_string}" for all matching names.))
      end
    elsif @field.match(/\Aname-usages\z/i)
      @results = Instance::AsSearchEngine.name_usages(@search_string)
      @info.push('instances for name id')
    elsif @field.match(/\Aname-id\z/i)
      @results = Instance::AsSearchEngine.name_usages(@search_string)
      @info.push('instances for name id')
    elsif @field.match(/^name-synonymy\z/i)
      @results = Instance.name_synonymy(@search_string)
      @info.push('name synonymy')
    elsif @field.match(/\Aref-instances|\sref-instances/i)
      Rails.logger.debug('found ref-instances')
      @results = Instance.ref_instances(@search_string.sub(/.*ref-instances: */,''),@limit)
      @info.push(%Q(up to #{@limit} #{'reference'.pluralize(@limit)} with instances.))
    elsif @field.match(/\Aref-usages\z/i)
      Rails.logger.debug('found ref-usages...')
      @results = Instance.ref_usages(@search_string,@limit,@sort)
      @info.push('Reference instances')
    elsif @field.match(/\Aref-names/i)
      Rails.logger.debug('found ref-names')
      @results = Instance.ref_usages(@search_string,@limit)
      @info.push('Ref names')
    elsif @field.match(/\Ainstance-context\z/i)
      @results = Instance.instance_context(@search_string.to_i)
      @info.push("Instance context for #{@search_string}")
    elsif @field.match(/\Aid\z/i)
      @results = Instance.where(id: @search_string)
      @info.push("Instance for id: #{@search_string}")
    elsif @field.match(/\Ansl-720\z/i)
      @results = Instance.nsl_720
      @info.push('instances for nsl 720')
    elsif @field.match(/\Areverse-of-cites-id-query\z/i)
      @results = Instance.reverse_of_cites_id_query(@search_string.to_i)
      @info.push("instances that cite id: #{@search_string}")
    elsif @field.match(/\Areverse-of-cited-by-id-query\z/i)
      @results = Instance.reverse_of_cited_by_id_query(@search_string.to_i)
      @info.push("instances that cited by id: #{@search_string}")
    elsif @model == Instance && @field.blank? && @search_string.gsub(/[^:]/,'').length == 0   # simple search because no field descriptors
      Rails.logger.debug('Inferred name-instances search')
      @results = Instance.name_instances(@search_string.sub(/.*name-instances: */,''),@limit,@apply_limit)
      if @apply_limit
        @info.push(%Q(Instances for name search on "#{@search_string}" for up to #{@limit} name(s).))
      else
        @info.push(%Q(Instances for name search on "#{@search_string}" for all matching names.))
      end
    else 
      Rails.logger.debug('run_search has checked all named instance searches...else')
      if @field.match(/note-key/)
        leading_search_descriptor = 'instance-note-key'
        @info.push(%Q(Instances search: "note-key: #{@search_string}".))
      elsif @field.match(/instance-type/)
        leading_search_descriptor = 'instance-type'
        @info.push(%Q(Instances search on instance type for "#{@search_string}".))
      elsif @field.match(/with-comments\z/)
        leading_search_descriptor = 'with-comments'
        @info.push(%Q(Instances search on comments for "#{@search_string}".))
      elsif @field.match(/with-comments-by/)
        leading_search_descriptor = 'with-comments-by'
        @info.push(%Q(Instances search on with-comments-by for "#{@search_string}".))
      elsif @field.match(/with-comments-by/)
        leading_search_descriptor = 'with-comments-by'
        @info.push(%Q(Instances search on with-comments-by for "#{@search_string}".))
      elsif @field.match(/cr-a/)
        leading_search_descriptor = 'cr-a'
        @info.push(%Q(Search for instances created less than #{ActionController::Base.helpers.pluralize(@search_string.to_i,'day')} ago.))
      elsif @field.match(/cr-b/)
        leading_search_descriptor = 'cr-b'
        @info.push(%Q(Search for instances created more than #{ActionController::Base.helpers.pluralize(@search_string.to_i,'day')} ago.))
      elsif @field.match(/upd-a/)
        leading_search_descriptor = 'upd-a'
        @info.push(%Q(Search for instances updated less than #{ActionController::Base.helpers.pluralize(@search_string.to_i,'day')} ago.))
      elsif @field.match(/upd-b/)
        leading_search_descriptor = 'upd-b'
        @info.push(%Q(Search for instances updated more than #{ActionController::Base.helpers.pluralize(@search_string.to_i,'day')} ago.))
      else
        leading_search_descriptor = 'instance-type' #Instance.new.default_descriptor
        @info.push(%Q(Instances search on instance type for "#{@search_string}".))
      end
      where,binds,@rejected_pairings = Instance.generic_bindings_to_where(self,format_search_terms(leading_search_descriptor,@search_string))
      Rails.logger.debug('after generic bindings to where')
      Rails.logger.debug("format_search_terms(#{leading_search_descriptor}): #{}; where: #{where}; binds: #{binds}")
      where,binds,@rejected_pairings = Instance.bindings_to_where(@rejected_pairings,where,binds)
      order_by_binds,@rejected_pairings = Instance.generic_bindings_to_order_by(@rejected_pairings,Instance.new.legal_to_order_by)
      order_by_binds.push(Instance.new.default_order_by)
      Rails.logger.debug("where: #{where}")
      if @rejected_pairings.size > 0
        @results = []
      else
        @results = Instance.includes(:instance_type, {name: :name_status}, :reference).where(binds.unshift(where)).order(order_by_binds).limit(limit)
      end
    end
    @focus_anchor_id = @results.size > 0 ? @results.first.anchor_id : nil
  end


  def which_model
    Rails.logger.debug("which_model: @clean_search_string: #{@clean_search_string}; @on: #{@on}")
    case @clean_search_string
    when /ref-name:/
      Instance
    when /ref-names:/
      Instance
    when /name-usages:/
      Instance
    when /name-synonymy/
      Instance
    when /ref-instances:/
      Instance
    when /name-instances:/
      Instance
    when /instance-note-key:/
      Instance
    when /usages.for.name:/
      Instance
    when /instance:/
      Instance
    when /ref:/
      Reference
    when /[^-]author:/
      Author
    when /name:/
      Name
    else
      case @on.downcase
      when /name/
        Name
      when /ref/
        Reference
      when /instance note key/
        Instance
      when /instance/
        Instance
      when /author/
        Author
      else
        Name
      end
    end
  end

  def instance_note_key?
    !!@on.match(/instance note key/i)
  end

  def query_without_model
    @clean_search_string.sub(/[\s]ref:/,'').sub(/instance:/,'').sub(/\sauthor:/,'').sub(/name:/,'')
  end

  def where
    case @search_string
    when /ref:/
      [" lower(citation) like ? ",@search_string.downcase.sub(/ref:/,'').strip.sub(/\A/,'%').sub(/\z/,'%')]
    else
      " full_name like '%#{@search_string}%' "
    end
  end

  def format_search_terms(default_descriptor,raw)
    raw.strip\
      .gsub(/\A:/,'')\
      .gsub(/\s([\S]+:)/,"\034"+'\1')\
      .sub(/^\034/,'')\
      .split("\034")\
      .collect {|term| term.include?(':') ? term\
        .strip\
        .split(/:/)\
        .collect {|e| e.strip} : [default_descriptor,term] }\
        .sort {|a,b| a[0] <=> b[0]}
  end

  def info_for_display
    if @limit == UNLIMITED_QUERY_AMOUNT
      info.join.sub(/for up to #{UNLIMITED_QUERY_AMOUNT}/,'for all')
    else
      info.join
    end
  end

end

