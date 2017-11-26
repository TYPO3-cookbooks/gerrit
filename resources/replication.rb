property :name, required: true
property :uri, String, name_attribute: true
property :ssh_key, String
property :ssh_key_file, String
property :gerrit_auth_group, String
property :gerrit_mirror, TrueClass, default: true
property :gerrit_threads, Integer, default: 8
property :gerrit_timeout, Integer, default: 120

load_current_value do

end

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
  ssh_known_hosts host_uri.host do
    user node['gerrit']['user']
    hashed false
    notifies :restart, 'service[gerrit]' # read only on startup of Gerrit
  end

  ssh_key_file = new_resource.ssh_key_file || ::File.join(node['gerrit']['home'], '.ssh', "replication_#{new_resource.name}")
  file ssh_key_file do
    content ssh_key
    owner node['gerrit']['user']
    mode 0500
    not_if { ssh_key.nil? }
  end

  # ssh_config for remote
  ssh_config host_uri.host do
    options 'IdentityFile' => ssh_key_file, 'PreferredAuthentications' => 'publickey'
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
