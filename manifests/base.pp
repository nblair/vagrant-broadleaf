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
  require => [Package['oracle-java7-installer'], Exec['accept-java-license']]
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
file { '/etc/environment':
  content => inline_template("JAVA_HOME=/usr/lib/jvm/java-7-oracle")
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
  require => [Package['maven'], Exec['unzip DemoSite'], File['/etc/environment']],
  cwd => "/vagrant/eclipse-workspace/DemoSite",
  logoutput => true,
  timeout => 1200,
  creates => "/vagrant/eclipse-workspace/DemoSite/site/target/mycompany.war",
}

file { '/etc/init.d/broadleaf-demo':
  source => "/vagrant/broadleaf-demo.initscript",
  mode => "0755"
}

service { 'broadleaf-demo':
  ensure => running,
  enable => true,
  hasstatus => false,
  require => [File['/etc/init.d/broadleaf-demo'], Package['maven'], Exec['mvn install']]
}

#TODO: make a similar init script for the admin project
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

#TODO: consider setting up jetty or tomcat as a service
#package { 'jetty8':
#  ensure => installed
#}
#exec { 'copy war':
#  command => "/bin/ln -s /vagrant/eclipse-workspace/DemoSite/site/target/mycompany /usr/share/jetty8/webapps/",
#  require => [Package['jetty8'], Exec['mvn install']],
#  creates => "/usr/share/jetty8/webapps/mycompany",
#}
#exec { 'chown war':
#  command => "/bin/chown jetty:adm /usr/share/jetty8/webapps/mycompany",
#  require => [Exec['copy war']],
#}
#exec { 'autostart jetty':
#  command => "/bin/sed -i 's/NO_START=1/NO_START=0/' /etc/default/jetty8",
#  require => [Package['jetty8']],
#}
#exec { 'jvm args':
#  command => "/bin/sed -i 's|#JAVA_OPTIONS.*$|JAVA_OPTIONS=\"-XX:MaxPermSize=256M -Xmx512M -Xdebug -Xrunjdwp:transport=dt_socket,address=8000,server=y,suspend=n -javaagent:/vagrant/eclipse-workspace/DemoSite/lib/spring-instrument-3.2.12.RELEASE.jar -Druntime.environment=development\"|' /etc/default/jetty8",
#  require => [Package['jetty8']],
#}
