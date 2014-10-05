tmp_dir = "/tmp/puppet-conf"

file "minimum-security.tar.gz" => `git ls-files`.split("\n") do |t|
  sh "tar czf #{t.name} #{t.prerequisites.join(' ')}"
end

namespace :'puppet-bootstrap' do

  desc "install the ubuntu packages"
  task :'install-packages' do
    packages = %w(puppet ruby-dev make)
    on roles(:root) do
      packages.each do |p|
        execute "dpkg -s #{p} &> /dev/null; if [ $? -ne 0 ]; then apt-get -y install #{p}; fi"
      end
    end
  end

  desc "install puppet librarian"
  task :'install-librarian' => :'install-packages' do
    on roles(:root) do
      execute "if [ -z $(which librarian-puppet) ]; then gem install librarian-puppet; fi"
    end
  end

  desc "Package and upload the configs"
  task :'upload-config' => ["minimum-security.tar.gz", :'install-librarian'] do |t|
    tarball = t.prerequisites.first
    on roles(:root) do
      execute :mkdir, '-p', tmp_dir
      upload!(tarball, tmp_dir)
      within tmp_dir do
        execute :tar, 'xzf', tarball
      end
    end
  end

  desc "run puppet librarian"
  task :'puppet-librarian' => :"upload-config" do
    on roles(:root) do
      within tmp_dir do
        execute :"librarian-puppet", "install"
      end
    end
  end

  desc "puppet apply"
  task :'puppet-apply' => :"puppet-librarian" do
    on roles(:root) do
      within tmp_dir do
        execute :puppet, "apply", "--modulepath=./modules", "minimum-security.pp"
      end
    end
  end
end

task :bootstrap => 'puppet-bootstrap:puppet-apply'
