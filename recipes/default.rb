#
# Cookbook Name:: gerrit
# Recipe:: default
#
# Copyright 2012, Steffen Gebert / TYPO3 Association
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

include_recipe "git"
include_recipe "java"
# used later on to restart after JRE update
include_recipe "java::notify"

include_recipe "gerrit::_system"
include_recipe "gerrit::_config"
include_recipe "gerrit::_database"

include_recipe "gerrit::_deploy"

if node['gerrit']['peer_keys']['enabled']
  include_recipe "gerrit::peer_keys"
end

if node['gerrit']['batch_admin_user']['enabled']
  include_recipe "gerrit::batch_admin"
end

# we have to split up the service because of the immediate notification
service "gerrit-without-readiness-check" do
  service_name "gerrit"
  supports :status => false, :restart => true, :reload => true
  action :enable
end

service "gerrit" do
  action :start
  subscribes :restart, 'log[jdk-version-changed]', :delayed
  # proceed only after finished restart
  notifies :run, 'ruby_block[wait_until_ready]', :immediately
end

ruby_block "wait_until_ready" do
  block do
     # listenUri = URI()
#     # uri = "#{listenUri.scheme}://localhost:#{listenUri.port}"
    # FIXME do not hardcode
     uri = "http://localhost:8080"
     Chef::Log.info "Waiting for #{uri}"
     wait_until_ready!(uri, 301)
  end
end
