## vagrant-broadleaf

This project aims to provision a simple [Broadleaf](http://www.broadleafcommerce.org/) instance
using Vagrant and Puppet.

This project specifically is an alternative to list of instructions documented in [Broadleaf's Getting Started](http://www.broadleafcommerce.com/docs/core/current/getting-started).
Rather than downloading Eclipse and a JDK, running some specific ant targets, Vagrant and Puppet automate those steps.

### Requirements

Warning: The virtual machine that will be provisioned by vagrant will have 2 GB of RAM.

1. Install [VirtualBox](https://www.virtualbox.org/)
2. Install [Vagrant](https://www.vagrantup.com/)
3. Clone or download this repository to the root of your project directory: `git clone https://github.com/nblair/vagrant-broadleaf.git`
4. In your project directory, run `vagrant up`

Be prepared to wait; the first launch of the site may take a good 15 minutes.

### Starting the site

TODO Work is in progress to obviate these steps.

Once the host is up, you will need to ssh into the host and start up the 2 applications.

Starting the site (current working directory of this project):

1. vagrant ssh
2. cd /vagrant/eclipse-workspace/DemoSite/site
3. ant jetty-demo

Starting the admin console (separate terminal, current working directory of this project):

1. vagrant ssh
2. cd /vagrant/eclipse-workspace/DemoSite/admin
3. ant jetty-demo

### Using

To access the site, point your browser at http://localhost:8080.
To access the admin console, point your browser at https://localhost:8444/admin. Log in with username *admin* and password *admin*.