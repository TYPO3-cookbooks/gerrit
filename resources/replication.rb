property :name, required: true
property :uri, String, name_attribute: true
property :ssh_key, String
property :ssh_key_file, String
property :hostname, String

#############
# Warning: This is only a helper. It does NOT write the replication.config file!
#############

action :create do

  raise "Either 'ssh_key' or 'ssh_key_file' must be given!" if new_resource.ssh_key.nil? && new_resource.ssh_key_file.nil?
  raise "Only one of 'ssh_key' and 'ssh_key_file' must be given!" unless new_resource.ssh_key.nil? || new_resource.ssh_key_file.nil?

  raise "Expecting a git+ssh URL in the scheme 'user@example.com:repo', got: '#{new_resource.uri}'" unless new_resource.uri.include?(':')
  # split the repo from the host in case of git+ssh URL (e.g. 'git@github.com:foo/bar.git')
  uri_without_repo = new_resource.uri.split(':').first
  repo_path = new_resource.uri.split(':').last
  # enforce SSH scheme if URL has no scheme specified
  host_uri = URI(uri_without_repo).scheme ? URI(uri_without_repo) : URI('ssh://' + uri_without_repo)

  # add ssh_known_hosts for ssh
  ssh_known_hosts new_resource.hostname || host_uri.host do
    user node['gerrit']['user']
    hashed false
    notifies :restart, 'service[gerrit]' # read only on startup of Gerrit
  end

  ssh_key_file = new_resource.ssh_key_file || ::File.join(node['gerrit']['home'], '.ssh', "replication_#{host_uri.host}")
  file ssh_key_file do
    content ssh_key
    owner node['gerrit']['user']
    mode 0500
    not_if { ssh_key.nil? }
  end

  ssh_options = {'User' => host_uri.user, 'IdentityFile' => ssh_key_file, 'PreferredAuthentications' => 'publickey'}
  ssh_options['Hostname'] = new_resource.hostname if new_resource.hostname

  # ssh_config for remote
  ssh_config host_uri.host do
    options ssh_options
    user node['gerrit']['user']
    notifies :restart, 'service[gerrit]' # read only on startup of Gerrit
  end

end

action :delete do
  ssh_known_hosts "#{uri.host}:#{uri.port}" do
    user node['gerrit']['user']
    action :delete
  end

  ssh_config uri.host do
    user node['gerrit']['user']
    action :delete
  end
end
