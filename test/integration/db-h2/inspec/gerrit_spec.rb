control 'gerrit-1' do
  title 'Gerrit Setup'
  desc '
    Check that gerrit is installed and running
  '

  describe directory('/var/gerrit/review/etc') do
    it { should exist }
  end

  [8080, 29418].each do |listen_port|

    describe port(listen_port) do

      # this currently fails with inspec 1.6.0 when listening on 127.0.0.1
      # Could not parse 127.0.0.1:8080, bad URI(is not URI?): addr://[127.0.0.1]:8080
      skip
      # it { should be_listening }
      # its('protocols') { should include 'tcp6'}
    end
  end

  # port 8080 HTML
  describe command('curl http://localhost:8080') do
    its('exit_status') { should eq 0 }
    its('stdout') { should include '<title>Gerrit Code Review</title>' }
  end
end

control 'gerrit-2' do
  title 'Gerrit Hooks'

  describe file('/var/gerrit/review/hooks/patchset-created') do
    it { should exist }
    it { should be_executable }
  end

  command file('/var/gerrit/review/hooks/patchset-created') do
    its('exit_status') { should eq 0 }
    its('stdout') { should include 'Hello World'} # this comes from the test cookbook
  end

  describe file('/var/gerrit/review/hooks/patchset-created.d/test.sh') do
    it { should exist }
    it { should be_executable }
    its('content') { should include 'Hello World'}
  end

  command file('/var/gerrit/review/hooks/patchset-created.d/test.sh') do
    its('exit_status') { should eq 0 }
    its('stdout') { should include 'Hello World'}
  end
end

control 'gerrit-3' do
  title 'Gerrit System Daemon Setup'

  describe file('/etc/default/gerritcodereview') do
    its('content') { should include 'JAVA_OPTIONS=-Xmx1G' }
  end

  # check heap limit
  # jmap -heap <java-proc>
  describe command('jmap -heap $(pgrep java) | grep MaxHeapSize') do
    its('stdout') { should include '1024.0MB' }
  end
end

control 'gerrit-4' do
  title 'Gerrit Replication'

  describe file('/var/gerrit/.ssh/replication_github.com') do
    it { should exist }
    its('content') { should eq '123456' }
    its('owner') { should eq 'gerrit'}
  end

  describe file('/var/gerrit/.ssh/known_hosts') do
    it { should exist }
    its('content') { should include 'github.com' }
  end
end
