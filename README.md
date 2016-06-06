***Note***: This cookbook is still a work in progress!

Description
===========

Installs the [Gerrit](http://code.google.com/p/gerrit/) review system. Optional support for MySQL database and Apache2 as proxy server is included.

Requirements
============

## Platform:

* Debian 6.0 and 7.0
* other platforms untested

## Cookbooks:

* build-essential
* mysql
* database
* java
* git
* maven
* apache2
* Optional: [git-daemon](http://github.com/typo3-cookbooks/git-daemon)

Attributes
==========

These attributes are set by the cookbook by default.

Deployment
----------

* `node['gerrit']['version']` - Gerrit version to deploy.
* `node['gerrit']['download_url']` - URL to download the `.war` file from. Defaults to `http://gerrit.googlecode.com/files/gerrit-#{node['gerrit']['version']}.war`
* `node['gerrit']['reference']` - Git revision or branch name to checkout.

User and path setup
-------------------

* `node['gerrit']['user']` - User, under which Gerrit runs ([container.user](http://gerrit-documentation.googlecode.com/svn/Documentation/2.5/config-gerrit.html#container.user)). Defaults to `gerrit`.
* `node['gerrit']['group']` -  Group name of the `gerrit` user. Defaults to `gerrit`.
* `node['gerrit']['home']` - Home directory of the `gerrit` user. Defaults to `/var/gerrit`.
* `node['gerrit']['install_dir']` - Directory, where Gerrit is installed into. Defaults to `node['gerrit']['home']/review`.

HTTP and friends
----------------

* `node['gerrit']['hostname']` - The default hostname for Gerrit to be accessed through. Defaults to `fqdn`.
* `node['gerrit']['canonicalWebUrl']` - The default URL for Gerrit to be accessed through. Typically this would be set to "http://review.example.com/" or "http://example.com/gerrit/" so Gerrit can output links that point back to itself. ([gerrit.canonicalWebUrl](http://gerrit-documentation.googlecode.com/svn/Documentation/2.5/config-gerrit.html#gerrit.canonicalWebUrl)). Defaults to `http://#{node['fqdn']}/`.
connections on ([sshd.listenAddress](http://gerrit-documentation.googlecode.com/svn/Documentation/2.5/config-gerrit.html#sshd.listenAddress)).
* `node['gerrit']['canonicalGitUrl']` - The URL under which the repositories are available through the Git protocol ([gerrit.canonicalGitUrl](http://gerrit-documentation.googlecode.com/svn/Documentation/2.5/config-gerrit.html#gerrit.canonicalGitUrl)). Has to include the protocol (`git://`). As Gerrit does _not_ support the Git protocol, such a server has to be managed through another cookbook, e.g. [git-daemon](http://github.com/typo3-cookbooks/git-daemon).
* `node['gerrit']['proxy']['enable']` - Enable Apache2 reverse proxy in front of Gerrit. Defaults to `true`, which makes Gerrit available on port 80.
* `node['gerrit']['proxy']['ssl']` - Enable SSL for the reverse proxy. Defaults to `true` and uses snakeoile self-signed certificate
* `node['gerrit']['proxy']['ssl_certfile']` - set path to a custom ssl_certfile.
* `node['gerrit']['proxy']['ssl_keyfile']` - set path to a custom ssl_keyfile.
* `node['gerrit']['proxy']['ssl_cabundle']` - set path to a custom ssl_bundle.

SSHD
----

* `node['gerrit']['port']` - Specifies the local addresses the internal SSHD should listen for 
 
Database configuration
----------------------

* `node['gerrit']['database']['type']` - Type of database server to connect to ([database.type](http://gerrit-documentation.googlecode.com/svn/Documentation/2.5/config-gerrit.html#database.type)). Defaults to `MYSQL`.
* `node['gerrit']['database']['hostname']` - Hostname of the database server ([database.hostname](http://gerrit-documentation.googlecode.com/svn/Documentation/2.5/config-gerrit.html#database.hostname)). Defaults to `localhost`.
* `node['gerrit']['database']['name']` - For `POSTGRESQL` or `MYSQL`, the name of the database on the server. For `H2`, this is the path to the database, and if not absolute is relative to `$site_path ` ([database.database](http://gerrit-documentation.googlecode.com/svn/Documentation/2.5/config-gerrit.html#database.database)). Defaults to `gerrit`.

* `node['gerrit']['database']['username']` - Username to connect to the database server as ([database.username](http://gerrit-documentation.googlecode.com/svn/Documentation/2.5/config-gerrit.html#database.username)). Defaults to `gerrit`.
* `node['gerrit']['database']['password']` - Password to authenticate to the database server with ([database.password](http://gerrit-documentation.googlecode.com/svn/Documentation/2.5/config-gerrit.html#database.password)). Defaults to `gerrit`.

Gerrit Auth
----
* `node['gerrit']['auth']['type']` - Set auth type ([auth.type](http://gerrit-documentation.googlecode.com/svn/Documentation/2.5/config-gerrit.html#auth.type)). Defaults to `OPENID`.
* `node['gerrit']['auth']['url']` - Value of `openIdSsoUrl` if the auth type is 'OpenID_SSO'.

E-mail
----

Set the options for the [sendemail](http://gerrit-documentation.googlecode.com/svn/Documentation/2.5/config-gerrit.html#_a_id_sendemail_a_section_sendemail) section. All attributes below `node['gerrit']['sendemail']` are rendered into the `gerrit.config`'s `[sendemail]` section.

E.g. to change the [sendemail.enable](http://gerrit-documentation.googlecode.com/svn/Documentation/2.5/config-gerrit.html#sendemail.enable) setting, set `node['gerrit']['sendemail']['smtpServer']`.

Theme
-----

* `node['gerrit']['theme']['compile_files]` - Hash of files deployed to `etc/`. Possible file names are `GerritSite(Header|Footer).html` and `GerritSite.css`. See [Gerrit docs](http://gerrit-documentation.googlecode.com/svn/Documentation/2.5/config-headerfooter.html#_html_header_footer). Gerrit will automatically reload these files, as long as not deactivated explicitly.
* `node['gerrit']['static_files']` - Hash of files deployed to `static/`. Files, which can be used in a custom theme and are available through `#{node['gerrit']['canonicalWebUrl']}/static/`. See [Gerrit docs](http://gerrit-documentation.googlecode.com/svn/Documentation/2.5/config-headerfooter.html#_static_images).

Replication
-----------

* `node['gerrit']['replication']['remotes']` - Hash of remotes to populate to `replication.config`. Keys should be the remote name, while values should be a hash of options to apply to that remote, such as `url`, `threads`, etc.`.  See [Gerrit docs](http://gerrit.googlecode.com/svn/documentation/2.0/config-replication.html).
* `node['gerrit']['replication']['plugin_download_url']` - URL to download the `replication.jar` plugin file from.  The build must be compatible with the Gerrit version specified in `node['gerrit']['version']`.  See [Gerrit docs](http://gerrit.googlecode.com/svn/documentation/2.0/config-replication.html).

Tuning
------
* `node['gerrit']['receive']['checkReferencedObjectsAreReachable']` - If set to true, Gerrit will validate that all referenced objects that are not included in the received pack are reachable by the user.  See [Gerrit docs](http://gerrit-documentation.googlecode.com/svn-history/r63/ReleaseNotes/ReleaseNotes-2.6.html).

Recipes
=======

default
-------
Sets up Gerrit. **Includes other recipes, if needed (no need to add them to your run list on your own)**.

mysql
-----
Configures the MySQL server, if `node['gerrit']['database']['type'] == "MYSQL"`.

proxy
-----
Installs Apache2 as reverse proxy in front of Gerrit, if enabled through `node['gerrit']['proxy']`. This also binds Gerrit's HTTPD to `localhost` on port 8080.
HTTPS support is available, if `node['gerrit']['proxy']` is set.

peer_keys
---------
Deploys an SSH key-pair for the magic _Gerrit Code Review_ user. See [suexec](http://gerrit-documentation.googlecode.com/svn/Documentation/2.5/cmd-suexec.html) and [File etc/peer_keys](http://gerrit-documentation.googlecode.com/svn/Documentation/2.5/config-gerrit.html#_file_tt_etc_peer_keys_tt).
Intended to be used in scripts.

source
------
Checks out the Git repository configured in `node['gerrit']['repository']` and runs the `tools/release.sh` script, which builds Gerrit. **Note**: This is *not* intended for production use, but might be useful while developing Gerrit!


Usage
=====

Create a role for the Gerrit server. See above for attributes that can be entered here.

    % cat roles/gerrit.rb
    name 'gerrit'
    description 'A Gerrit server'
    run_list(
      'recipe[gerrit]',
      'recipe[git-daemon]'
    )
    override_attributes(
      'gerrit' => {
        'version' => 'full-2.5.0',
      }
    )

Using the `git-daemon` cookbook is suggested, if you want to make your repositories available also through the Git protocol. Gerrit itself only supports SSH and HTTP(S).

Deployment Process
==================

war
---
When `flavor` `war` is specified, the `.war` file is downloaded into `node['gerrit']['install_dir']/war`.. This triggers to run `java -jar gerrit.war init -d /path/to/gerrit`, which initializes the Gerrit installation.

source
------
When the Git repository changes, a new build through Gerrit's `tools/release.sh` is triggered and created through Maven. Afterwards, the resulting `.war` file is processed as described above for `war` deplyoment.

Upgrading Gerrit
-----------------
A new Gerrit version is installed, as soon as a new `.war` file is available through one of the methods described above.
The `init` command is called automatically and if schema migrations have to be made, they are executed automatically.

License and Author
==================

Author:: Steffen Gebert (<steffen.gebert@typo3.org>)

Copyright:: 2012, Steffen Gebert / TYPO3 Association

Licensed under the Apache License, Version 2.0 (the 'License');
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an 'AS IS' BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
