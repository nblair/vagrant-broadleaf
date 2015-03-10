$DemoSite_version = "3.1.12-GA"

Exec {
  path => [ "/usr/local/sbin", "/usr/local/bin", "/usr/sbin", "/usr/bin", "/sbin", "/bin" ],
}

package {
  ["unzip", "mktemp"]:
    ensure => installed;
}

Package {
  ensure => installed,
}
package { 'maven':
  install_options => ['--no-install-recommends'],
  before          => Package['oracle-java7-installer'],
}
package { "ant":
  before => Package['oracle-java7-installer'],
}

$webupd8src = '/etc/apt/sources.list.d/webupd8team.list'
 
file { $webupd8src:
  content => "deb http://ppa.launchpad.net/webupd8team/java/ubuntu lucid main\ndeb-src http://ppa.launchpad.net/webupd8team/java/ubuntu lucid main\n",
} ->
# Authorise the webupd8 ppa
# At the time of writing this key was correct, but check the PPA page on launchpad!
# https://launchpad.net/~webupd8team/+archive/java
exec { 'add-webupd8-key':
  command => 'apt-key adv --keyserver keyserver.ubuntu.com --recv-keys EEA14886',
} ->
exec { 'apt-key-update':
  command => 'apt-key update',
} ->
exec { 'apt-update':
  command => 'apt-get update',
} ->
exec { 'accept-java-license':
  command => '/bin/echo /usr/bin/debconf shared/accepted-oracle-license-v1-1 select true | sudo /usr/bin/debconf-set-selections;/bin/echo /usr/bin/debconf shared/accepted-oracle-license-v1-1 seen true | sudo /usr/bin/debconf-set-selections;',
} ->
package { 'oracle-java7-installer':
  ensure => present,
}
    
exec { 'download broadleaf DemoSite':
  command => "/bin/sh -c 'wget http://downloads.broadleafcommerce.org/DemoSite-${DemoSite_version}-eclipse-workspace.zip'",
  cwd => "/vagrant",
  timeout => 900,
  logoutput => true,
  creates => "/vagrant/DemoSite-${DemoSite_version}-eclipse-workspace.zip",
} 
exec { 'unzip DemoSite':
  command => "/usr/bin/unzip -o DemoSite-${DemoSite_version}-eclipse-workspace.zip",
  require => [Package["unzip"], Exec["download broadleaf DemoSite"]],
  cwd => "/vagrant",
  creates => "/vagrant/eclipse-workspace",
} 
exec { 'mvn install':
  command => "mvn -X install",
  require => [Package['maven'], Exec['unzip DemoSite']],
  cwd => "/vagrant/eclipse-workspace/DemoSite",
  logoutput => true,
  timeout => 1200,
  creates => "/vagrant/eclipse-workspace/DemoSite/site/target/mycompany.war",
}

# TODO: this is broken. it's valid form, but we get the following error from puppet during provisioning:
# ==> default: Info: /Service[jetty-site]: Unscheduling refresh on Service[jetty-site]
# and the service isn't started. We probably will need to write our own init script.
# it would also be nice to get log output from said init script.
#service { 'jetty-site':
#  provider => 'base',
#  ensure => running,
#  enable => true,
#  start => 'cd /vagrant/eclipse-workspace/DemoSite/site; ant jetty-demo',
#  stop => 'cd /vagrant/eclipse-workspace/DemoSite/site; ant jetty-stop',
#  hasstatus => false,
#  pattern => 'address=8000',
#  require => Exec['mvn install'],
#}
#service { 'jetty-admin':
#  provider => 'base',
#  ensure => running,
#  enable => true,
#  start => 'cd /vagrant/eclipse-workspace/DemoSite/admin; ant jetty-demo',
#  stop => 'cd /vagrant/eclipse-workspace/DemoSite/admin; ant jetty-stop',
#  hasstatus => false,
#  pattern => 'address=8001',
#  require => Service['jetty-site'],
#}
