#
# Cookbook Name:: gerrit
# Attributes:: default
#
# Copyright 2011, Myplanet Digital
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

default['gerrit']['flavor'] = "war"

default['gerrit']['version'] = "2.6.1"

default['gerrit']['war']['download_url'] = "http://gerrit-releases.storage.googleapis.com/gerrit-#{node['gerrit']['version']}.war"

default['gerrit']['source']['repository'] = "https://gerrit.googlesource.com/gerrit"

default['gerrit']['user'] = "gerrit"
default['gerrit']['group'] = "gerrit"
default['gerrit']['home'] = "/var/gerrit"
default['gerrit']['install_dir'] = "#{node['gerrit']['home']}/review"

default['gerrit']['auth']['type'] = "OPENID"

default['gerrit']['sendemail']['enable'] = true
default['gerrit']['sendemail']['smtpServer'] = "localhost"

default['gerrit']['hostname'] = node['fqdn']
default['gerrit']['canonicalWebUrl'] = "http://#{node['gerrit']['hostname']}/"
default['gerrit']['port'] = "29418"
default['gerrit']['proxy'] = true
default['gerrit']['canonicalGitUrl'] = nil

# if this is set, an entry in the ssl_certificates data bag matching the given name must exist
# this uses the ssl-certificates cookbook
# http://github.com/binarymarbles/chef-ssl-certificates
default['gerrit']['ssl'] = false
default['gerrit']['ssl_certificate'] = nil


override['mysql']['bind_address'] = "127.0.0.1"
default['gerrit']['database']['type'] = "MYSQL"
default['gerrit']['database']['host'] = "localhost"
default['gerrit']['database']['name'] = "gerrit"
default['gerrit']['database']['username'] = "gerrit"
default['gerrit']['database']['password'] = "gerrit"

default['gerrit']['theme']['compile_files'] = []
default['gerrit']['theme']['static_files'] = []

default['gerrit']['peer_keys']['enabled'] = false
default['gerrit']['peer_keys']['public'] = ""
default['gerrit']['peer_keys']['private'] = ""
