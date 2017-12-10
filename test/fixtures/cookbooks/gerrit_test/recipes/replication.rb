gerrit_replication 'github.com' do
  uri 'git@github.com:TYPO3/TYPO3.CMS'
  ssh_key '123456'
end

gerrit_replication 'example.com' do
  uri 'git@example.com:test'
  ssh_key '123456'
  hostname 'localhost'
end
