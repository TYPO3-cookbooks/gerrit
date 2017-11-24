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

####################################
# /etc
####################################

template "/etc/default/gerritcodereview" do
  source "system/default.gerritcodereview.erb"
  mode 0644
  notifies :restart, "service[gerrit]"
end

link "/etc/init.d/gerrit" do
  to "#{node['gerrit']['install_dir']}/bin/gerrit.sh"
  not_if { ::File.open('/proc/1/comm').gets.chomp == 'systemd' } # systemd
end

systemd_service 'gerrit' do
  description 'Web based code review and project management for Git based projects'
  after %w( network.target mysql.service)
  install do
    wanted_by 'multi-user.target'
  end
  service do
    type 'simple'
    user 'gerrit'
    environment_file '/etc/default/gerritcodereview'
    standard_output 'syslog'
    standard_error 'syslog'
    syslog_identifier 'gerrit'
    exec_start '@/usr/bin/java gerrit -DGerritCodeReview=1 $JAVA_OPTIONS -jar $GERRIT_JAR daemon -d $GERRIT_SITE --console-log'
    exec_stop '/bin/kill -s SIGINT $MAINPID'
    # stupid java exit codes
    success_exit_status '130 143 SIGINT SIGTERM'

  end
  only_if { ::File.open('/proc/1/comm').gets.chomp == 'systemd' } # systemd
end
