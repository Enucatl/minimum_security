#!/usr/bin/env bash

apt-get install git puppet puppet-librarian
git clone https://github.com/Enucatl/minimum-security-puppet.git
cd minimum-security-puppet
librarian-puppet install
puppet apply minimum-security.pp
cd -
