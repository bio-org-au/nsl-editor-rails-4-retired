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
class Search::OnName::CountQuery

  def initialize(parsed_query)
    @parsed_query = parsed_query
  end

  def sql
    Rails.logger.debug("xSearch::OnName::CountQuery#sql")
    #sql = Name.lower_full_name_like(@parsed_query.where_arguments.downcase)
    sql = Name.includes(:name_status).includes(:name_tags) 
    sql = Search::OnName::WhereClauses.new(@parsed_query,sql).sql
    sql = sql.not_common_or_cultivar unless @parsed_query.common_and_cultivar
    sql
  end

end



