#
# Cookbook Name:: gerrit
# Recipe:: postgresql
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

include_recipe "postgresql::server"
include_recipe "database::postgresql"

postgresql_connection_info = {
  :host =>  '127.0.0.1',
  :port =>  node['postgresql']['config']['port'],
  :username => "postgres",
  :password => node['postgresql']['password']['postgres']
}

postgresql_database node['gerrit']['database']['name'] do
  connection postgresql_connection_info
  action :create
end

postgresql_database_user node['gerrit']['database']['username'] do
  connection postgresql_connection_info
  password node['gerrit']['database']['password']
  action :create
end

postgresql_database_user node['gerrit']['database']['username'] do
  connection postgresql_connection_info
  database_name node['gerrit']['database']['name']
  privileges [
    :all
  ]
  action :grant
end

postgresql_database "flushing postgresql privileges" do
  connection postgresql_connection_info
  action :query
  sql "FLUSH PRIVILEGES"
end

postgresql_database node['gerrit']['database']['name'] do
  connection postgresql_connection_info
  action :query
  sql "ALTER DATABASE " + node['gerrit']['database']['name'] + " OWNER TO " + node['gerrit']['database']['username']
end
