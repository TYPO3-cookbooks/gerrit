#
# Cookbook Name:: gerrit
# Recipe:: mysql
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

build_essential 'gerrit-mysql' do
  compile_time true
end

include_recipe "mysql::client"
include_recipe "mysql::server"
include_recipe "database::mysql"

# # TODO delete other occurrences of this file
# # the version can be found in gerrit-pgm/src/main/resources/com/google/gerrit/pgm/libraries.config
# remote_file "#{node['gerrit']['install_dir']}/lib/mysql-connector-java-5.1.21.jar" do
#   source "http://repo1.maven.org/maven2/mysql/mysql-connector-java/5.1.21/mysql-connector-java-5.1.21.jar"
#   action :create_if_missing
#   owner node['gerrit']['user']
#   group node['gerrit']['group']
# end

mysql_connection_info = {
  :host =>  node['mysql']['bind_address'],
  :username => "root",
  :password => node['mysql']['server_root_password']
}

mysql_database node['gerrit']['config']['database']['database'] do
  connection mysql_connection_info
  action :create
end

mysql_database "changing the charset of database" do
  connection mysql_connection_info
  database_name node['gerrit']['config']['database']['database']
  action :query
  sql "ALTER DATABASE #{node['gerrit']['config']['database']['database']} charset=latin1"
end

mysql_database_user node['gerrit']['config']['database']['username'] do
  username node['gerrit']['config']['database']['username']
  connection mysql_connection_info
  database_name node['gerrit']['config']['database']['database']
  password node['gerrit']['config']['database']['password']
  privileges [
    :all
  ]
  action :grant
end

mysql_database "flushing mysql privileges" do
  connection mysql_connection_info
  action :query
  sql "FLUSH PRIVILEGES"
end
