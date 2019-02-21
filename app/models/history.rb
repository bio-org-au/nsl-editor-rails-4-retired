#   encoding: utf-8
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

#   Record significant changes and let users read about them.
class History
  def self.changes(year)
    load_changes_for(year)
  end

  # def self.changes_2015
    # load_changes_for(2015)
  # end
# 
  # def self.changes_2016
    # load_changes_for(2016)
  # end
# 
  # def self.changes_2017
    # load_changes_for(2017)
  # end
# 
  # def self.changes_2018
    # load_changes_for(2018)
  # end
# 
  # def self.changes_2019
    # load_changes_for(2019)
  # end
private
  def self.load_changes_for(year)
    YAML.load(File.read("config/changes-#{year}.yml"))
  end
end
