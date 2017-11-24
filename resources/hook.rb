property :name, String, required: true
property :event, String, required: true
property :source, String, required: true
property :variables, Hash, default: {}

load_current_value do

end

action :create do

  directory "#{node['gerrit']['install_dir']}/hooks" do
    owner node['gerrit']['user']
    group node['gerrit']['group']
    mode 0744
  end

  # create the wrapper script, which will call all files in the #{hook}.d/ directory
  template "#{node['gerrit']['install_dir']}/hooks/#{new_resource.event}" do
    cookbook 'gerrit'
    owner node['gerrit']['user']
    group node['gerrit']['group']
    mode 0755
    source "gerrit/hooks-wrapper.sh"
  end

  # create the directory containing the single hook files, which will
  # be executed by the wrappers
  directory "#{node['gerrit']['install_dir']}/hooks/#{new_resource.event}.d/" do
    owner node['gerrit']['user']
    group node['gerrit']['group']
    mode 0744
  end

  template "#{node['gerrit']['install_dir']}/hooks/#{new_resource.event}.d/#{new_resource.name}" do
    source new_resource.source
    variables new_resource.variables
    owner node['gerrit']['user']
    group node['gerrit']['group']
    mode 0755
    sensitive true
  end

end

action :delete do
  template "#{node['gerrit']['install_dir']}/hooks/#{new_resource.event}.d/#{new_resource.name}" do
    action :delete
  end
end
