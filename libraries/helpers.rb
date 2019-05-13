#
# Cookbook Name:: gerrit
# Library:: helpers
#
# Copyright 2014, TYPO3 Association
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require 'timeout'

module Gerrit
  module Helpers

    class ConnectTimeout < Timeout::Error; end

    class ServiceNotReady < StandardError
      def initialize(endpoint, timeout)
        super "The service at '#{endpoint}' did not become ready within #{timeout} seconds."
      end
    end



    # Checks against the current gerrit version
    #
    # @return [Boolean]
    def gerrit_above?(version)
      require 'chef/version_constraint'

      # remove the garbage (like -rc1 etc.) from version numbers
      actual_version_cleaned = node['gerrit']['version'].split('-')[0]
      Chef::VersionConstraint.new(">= #{version}").include?(actual_version_cleaned)
    end

    # Checks if SSH connection succeeeds
    #
    # @return [Boolean]
    def ssh_can_connect?(user, key, host, port)
      ssh = Mixlib::ShellOut.new("ssh -o StrictHostKeyChecking=no -i #{key} -p #{port} -l #{user} #{host} gerrit version")
      ssh.run_command
      # return true if there was no error
      ! ssh.error?
    end

    def run_gsql (sql)
      war_path = "#{node['gerrit']['home']}/war/gerrit-#{node['gerrit']['version']}.war"
      cmd = "java -jar #{war_path} gsql --format JSON -c '#{sql}' -d #{node['gerrit']['install_dir']}"
      sql_shell = Mixlib::ShellOut.new(cmd, :user => node['gerrit']['user'], :cwd => "#{node['gerrit']['home']}/war")
      sql_shell.run_command
      if sql_shell.error?
        msg = "Gerrit::Helpers.run_gsql('#{sql}' execution error"
        sql_shell.invalid!(msg)
        #raise msg
      end
      lines = sql_shell.stdout.split("\n")
      result = Array.new
      # gerrit gsql returns *two* jsons separated by newline in case of success, first line is sufficient for us
      lines.each do |line|
        parsed = JSON.parse(line)
        if parsed && parsed['type'] == 'error'
          raise "Gerrt::Helpers.run_gsql('#{sql}') failed #{parsed}"
        elsif parsed && parsed['type'] == 'row'
          result.push(parsed['columns'])
        elsif parsed && parsed['type'] == 'query-stats' || parsed['type'] == 'update-stats'
          # ignore query-stats
        else
          msg = "unknown json type attribute in result '#{parsed}'"
          raise "Gerrit::Helpers.run_gsql('#{sql}') #{msg}"
        end
      end
      return result
    end

    def wait_until_ready!(endpoint, status)
      timeout = 300
      Timeout.timeout(timeout, ConnectTimeout) do
        begin
          open(endpoint)
        rescue SocketError,
          Errno::ECONNREFUSED,
          Errno::ECONNRESET,
          Errno::ENETUNREACH,
          Errno::EADDRNOTAVAIL,
          Timeout::Error,
          OpenURI::HTTPError => e
          return if e.message =~ /^#{status}/

          Chef::Log.debug("Gerrit is not accepting requests - #{e.message}")
          sleep(2)
          retry
        end
      end
    rescue ConnectTimeout
      raise ServiceNotReady.new(endpoint, timeout)
    end

  end
end

Chef::Node::Attribute.send(:include, ::Gerrit::Helpers)
Chef::Recipe.send(:include, ::Gerrit::Helpers)
Chef::Resource.send(:include, ::Gerrit::Helpers)
Chef::Provider.send(:include, ::Gerrit::Helpers)
