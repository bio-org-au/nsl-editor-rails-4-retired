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
module SearchTools

  # simple search because no field descriptors?
  def search_is_simple?(raw)
    raw.gsub(/[^:]/,'').length == 0
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


end

