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
class Ability
  include CanCan::Ability
  # The first argument to `can` is the action you are giving the user
  # permission to do.
  # If you pass :manage it will apply to every action. Other common actions
  # here are :read, :create, :update and :destroy.
  #
  # The second argument is the resource the user can perform the action on.
  # If you pass :all it will apply to every resource. Otherwise pass a Ruby
  # class of the resource.
  #
  # The third argument is an optional hash of conditions to further filter the
  # objects.
  # For example, here the user can only update published articles.
  #
  #   can :update, Article, :published => true
  #
  # See the wiki for details:
  # https://github.com/CanCanCommunity/cancancan/wiki/Defining-Abilities
  #
 
  def initialize(user)
    user ||= User.new(groups: []) # Some controller/actions are available to unauthenticated users.  This is for them.
    # A separate authentication check controls which pages are visible to non-authenticated users.
    # Some users can login but have no groups allocated.  By default they can "read" - search and view data.
    # We could theoretically relax authentication and have these authorization checks prevent non-editors changing data.
    can 'authors',            'tab_show_1'
    can 'help',               :all
    can 'instance_types',     'index'
    can 'instances',          'tab_show_1'
    can 'instances',          'update_reference_id_widgets'
    can 'menu',               'help'
    can 'menu',               'user'
    can 'names',              'rules'
    can 'names',              'tab_details'
    can 'references',         'tab_show_1'
    can 'search',             :all
    can 'services',           :all
    can 'sessions',           :all
    if user.edit?
      can 'authors',          :all
      can 'comments',         :all
      can 'instances',        :all
      cannot 'instances',     'copy_standalone'
      can 'instance_notes',   :all
      can 'menu',             'new'
      can 'name_tag_names',   :all
      can 'names',            :all
      can 'names_deletes',    :all
      can 'references',       :all
    end
    if user.qa?
      can 'instances',        'copy_standalone'
    end
    if user.apc?
      can 'apc',              'place'
    end
    if user.admin?
      can 'admin',            :all
      can 'menu',             'admin'
    end
  end

end

