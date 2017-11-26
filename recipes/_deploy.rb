require 'uri'
require 'pathname'

####################################
# Deploy
####################################

war_path = "#{node['gerrit']['home']}/war/gerrit-#{node['gerrit']['version']}.war"

remote_file war_path do
  owner node['gerrit']['user']
  source node['gerrit']['war']['download_url'] % {version: node['gerrit']['version']}
  # checksum node['gerrit']['war']['checksum'][node['gerrit']['version']]
  notifies :run, "execute[gerrit-init]", :immediately
  # important during upgrade
  notifies :stop, "service[gerrit]", :immediately
  action :create_if_missing
end

####################################
# Core Plugins
####################################

# we have to explicitly list the core plugins that should be installed
plugin_command = ""
node['gerrit']['core_plugins'].each do |plugin|
  plugin_command << "  --install-plugin #{plugin}"
end

###################################
# External Libs
##################################

[
  'http://central.maven.org/maven2/org/bouncycastle/bcprov-jdk15on/1.56/bcprov-jdk15on-1.56.jar',
  'http://central.maven.org/maven2/org/bouncycastle/bcpkix-jdk15on/1.56/bcpkix-jdk15on-1.56.jar',
].each do |url,checksum|
  lib_filename = Pathname.new(URI.parse(url).path).basename.to_s
  remote_file "#{node['gerrit']['install_dir']}/lib/#{lib_filename}" do
    source url
    action :create_if_missing
    owner node['gerrit']['user']
    group node['gerrit']['group']
  end
end

####################################
# Gerrit init
####################################

execute "gerrit-init" do
  user node['gerrit']['user']
  group node['gerrit']['group']
  cwd "#{node['gerrit']['home']}/war"
  command "java -jar #{war_path} init --batch --no-auto-start -d #{node['gerrit']['install_dir']} #{plugin_command}"
  action :nothing
  notifies :restart, "service[gerrit]"
end

execute "gerrit-reindex" do
  user node['gerrit']['user']
  group node['gerrit']['group']
  cwd "#{node['gerrit']['home']}/war"
  command "java -jar #{war_path} reindex -d #{node['gerrit']['install_dir']}"
# we only have to do initial offline reindexing, if there is no index/ directory already
  not_if { File.directory?(File.join(node['gerrit']['install_dir'], "index")) }
end

####################################
# Static files
####################################

node['gerrit']['theme']['compile_files'].each do |file|
  cookbook_file "#{node['gerrit']['install_dir']}/etc/#{file}" do
    source "gerrit/#{file}"
    owner node['gerrit']['user']
    group node['gerrit']['group']
    mode 0644
    cookbook node['gerrit']['theme']['source_cookbook']
  end
end

node['gerrit']['theme']['static_files'].each do |file|
  cookbook_file node['gerrit']['install_dir'] + "/static/" + file do
    source "gerrit/static/#{file}"
    owner node['gerrit']['user']
    group node['gerrit']['group']
    cookbook node['gerrit']['theme']['source_cookbook']
  end
end
