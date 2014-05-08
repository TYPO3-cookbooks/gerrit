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

require 'securerandom'

####################################
# User setup
####################################

group node['gerrit']['group']

user node['gerrit']['user'] do
  gid node['gerrit']['group']
  home node['gerrit']['home']
  comment "Gerrit system user"
  shell "/bin/bash"
  system true
end


####################################
# Directories & Files
####################################

dirs = [
  node['gerrit']['home'],
  node['gerrit']['home'] + "/war",
  node['gerrit']['install_dir'],
  node['gerrit']['install_dir'] + "/etc",
  node['gerrit']['install_dir'] + "/lib", 
  node['gerrit']['install_dir'] + "/static",
  node['gerrit']['install_dir'] + "/plugins"
]

dirs.each do |dir|
  directory dir do
    owner node['gerrit']['user']
    group node['gerrit']['group']
    recursive true
  end
end

template "#{node['gerrit']['install_dir']}/etc/gerrit.config" do
  source "gerrit/gerrit.config"
  owner node['gerrit']['user']
  group node['gerrit']['group']
  mode 0644
  notifies :restart, "service[gerrit]"
end

if Chef::Config[:solo]
  missing_attrs = %w[
    registerEmailPrivateKey
    restTokenPrivateKey
  ].select { |attr| node['gerrit']['auth'][attr].nil? }.map { |attr| %Q{node['gerrit']['auth']['#{attr}']} }

  unless missing_attrs.empty?
    Chef::Application.fatal! "You must set #{missing_attrs.join(', ')} in chef-solo mode."
  end
else

  # generate all passwords
  node.set_unless['gerrit']['auth']['registerEmailPrivateKey'] = SecureRandom::base64(32)
  node.set_unless['gerrit']['auth']['restTokenPrivateKey']   = SecureRandom::base64(32)
  node.save
end

template "#{node['gerrit']['install_dir']}/etc/secure.config" do
  source "gerrit/secure.config.erb"
  owner node['gerrit']['user']
  group node['gerrit']['group']
  mode 0600
  notifies :restart, "service[gerrit]"
end

template "/etc/default/gerritcodereview" do
  source "system/default.gerritcodereview.erb"
  mode 0644
  notifies :restart, "service[gerrit]"
end

node['gerrit']['theme']['compile_files'].each do |file|
  cookbook_file "#{node['gerrit']['install_dir']}/etc/#{file}" do
    source "gerrit/#{file}"
    owner node['gerrit']['user']
    group node['gerrit']['group']
    mode 0644
  end
end

node['gerrit']['theme']['static_files'].each do |file|
  cookbook_file node['gerrit']['install_dir'] + "/static/" + file do
    source "gerrit/static/" + file
    owner node['gerrit']['user']
    group node['gerrit']['group']
  end
end

####################################
# MySQL
####################################

if node['gerrit']['database']['type'] == "MYSQL"
  include_recipe "gerrit::mysql"
elsif node['gerrit']['database']['type'] == "POSTGRESQL"
  include_recipe "gerrit::postgresql"
end



####################################
# Proxy
####################################

if node['gerrit']['proxy']
  include_recipe "gerrit::proxy"
end

####################################
# Java
####################################
if platform?("ubuntu")
  package "openjdk-6-jre-headless"
else
  include_recipe "java"
end


####################################
# Deploy
####################################

include_recipe "java"
include_recipe "git"

#directory "#{node['gerrit']['home']}/war" do
#  owner node['gerrit']['user']
#  group node['gerrit']['group']
#end

if node['gerrit']['flavor'] == "war"
  filename = "#{node['gerrit']['home']}/war/gerrit-#{node['gerrit']['version']}.war"

  remote_file filename do
    owner node['gerrit']['user']
    source node['gerrit']['war']['download_url']
    # checksum node['gerrit']['war']['checksum'][node['gerrit']['version']]
    notifies :run, "execute[gerrit-init]", :immediately
    notifies :run, "execute[gerrit-reindex]", :immediately if node['gerrit']['version'] >= "2.9"
    action :create_if_missing
  end
else
  include_recipe "gerrit::source"
  
  filename = "#{node['gerrit']['home']}/war/gerrit-#{node['gerrit']['version']}-#{node['gerrit']['source']['reference']}.war"

  bash "copy war" do
    Chef::Log.info "Created " + filename
    user node['gerrit']['user']
    code "cp #{node['gerrit']['home']}/src/git/gerrit-war/target/gerrit-*.war #{filename}"
    notifies :run, "execute[gerrit-init]", :immediately
    creates filename
  end
end

if node['gerrit'].attribute?('replication')
  remote_file "#{node['gerrit']['home']}/review/plugins/replication.jar" do
    owner node['gerrit']['user']
    source node['gerrit']['replication']['plugin_download_url']
    action :create_if_missing
  end

  template "#{node['gerrit']['install_dir']}/etc/replication.config" do
    source "gerrit/replication.config"
    owner node['gerrit']['user']
    group node['gerrit']['group']
    mode 0644
    notifies :restart, "service[gerrit]"
  end
end

execute "gerrit-init" do
  user node['gerrit']['user']
  group node['gerrit']['group']
  cwd "#{node['gerrit']['home']}/war"
  command "java -jar #{filename} init --batch --no-auto-start -d #{node['gerrit']['install_dir']}"
  action :nothing
  notifies :restart, "service[gerrit]"
end

execute "gerrit-reindex" do
  user node['gerrit']['user']
  group node['gerrit']['group']
  cwd "#{node['gerrit']['home']}/war"
  command "java -jar #{filename} reindex -d #{node['gerrit']['install_dir']}"
  action :nothing
end

link "/etc/init.d/gerrit" do
  to "#{node['gerrit']['install_dir']}/bin/gerrit.sh"
end

service "gerrit" do
  supports :status => false, :restart => true, :reload => true
  action [ :enable, :start ]
end



####################################
# Cron-Job
####################################

directory "#{node['gerrit']['home']}/scripts" do
  owner node['gerrit']['user']
end

template "#{node['gerrit']['home']}/scripts/repack-repositories.sh" do
  source "scripts/repack-repositories.sh.erb"
  owner node['gerrit']['user']
  group node['gerrit']['group']
  mode 0744
end

cron "repack-repositories" do
  hour "2"
  minute "0"
  weekday "0"
  command "#{node['gerrit']['home']}/scripts/repack-repositories.sh"
  user node['gerrit']['user']
end


####################################
# peer_keys
####################################

if node['gerrit']['peer_keys']['enabled']
  include_recipe "gerrit::peer_keys"
end

