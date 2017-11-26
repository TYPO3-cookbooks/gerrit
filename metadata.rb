name             "gerrit"
maintainer       "Steffen Gebert"
maintainer_email "steffen.gebert@typo3.org"
license          "Apache 2.0"
description      "Installs/Configures gerrit"
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          IO.read(File.join(File.dirname(__FILE__), 'VERSION')) rescue '0.0.1'

depends "apache2"
depends "build-essential"
depends "database", "= 1.3.12"
depends "mysql", "= 1.3.0"
depends "java"
depends "git"
depends "ssh"
depends "systemd", "< 3.0"
