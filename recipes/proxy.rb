#
# Cookbook Name:: gerrit
# Recipe:: proxy
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

include_recipe "apache2"
include_recipe "apache2::mod_proxy"
include_recipe "apache2::mod_proxy_http"

apache_site "default" do
  enable false
end

if node['gerrit']['ssl']
  include_recipe "apache2::mod_ssl"

  ssl_certfile_path = "/etc/ssl/certs/ssl-cert-snakeoil.pem"
  ssl_keyfile_path  = "/etc/ssl/private/ssl-cert-snakeoil.key"
  ssl_cabundle_path  = ""

  # don't use snakeoil CA, if specified otherwise
  if node['ssl_certificates']
    ssl_certfile_path = node['ssl_certificates']['ssl_certfile_path']
    ssl_keyfile_path  = node['ssl_certificates']['ssl_keyfile_path']
    ssl_cabundle_path = node['ssl_certificates']['ssl_cabundle_path'] \
        if node['ssl_certificates']['ssl_cabundle_path']
  end
end

web_app node['gerrit']['hostname'] do
  server_name node['gerrit']['hostname']
  server_aliases []
  docroot "/var/www"
  template "apache/web_app.conf.erb"
  if node['gerrit']['ssl']
    ssl_certfile         ssl_certfile_path
    ssl_keyfile          ssl_keyfile_path
    ssl_cabundle_used    ::File::exist?(ssl_cabundle_path)
    ssl_cabundle         ssl_cabundle_path
  end
end
