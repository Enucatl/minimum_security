file "minimum-security.tar.gz" => `git ls-files` do |t|
  sh "tar czf #{t.name} #{t.prerequisites.join(' ')}"
end

namespace :'puppet-bootstrap' do
  desc "Package and upload the configs"

  task :'install-packages' do
    packages = %w(puppet puppet-librarian)
    on roles(:root_role) do
      packages.each do |p|
        execute "dpkg -s #{p}; if [ $? -ne 0 ]; then apt-get install #{p}"
      end
    end
  end

  task :'upload-config' => ["minimum-security.tar.gz", :"install-packages"] do
    tarball = t.prerequisites.first
    on roles(:root_role) do
      execute :mkdir, '-p', "/tmp/puppet-conf"
      upload!(tarball, "/tmp/puppet-conf")
      execute :tar, 'xzf', "/tmp/puppet-conf/#{tarball}"
    end
  end
end
