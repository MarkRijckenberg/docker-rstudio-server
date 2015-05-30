include wget
# Installs RStudio (user shiny, password shiny) and Shiny
# Change these if the version changes
# See http://www.rstudio.com/ide/download/server
# This is the standard installation (update it when a new release comes out)
$rstudioserver = 'rstudio-server-0.99.441-amd64.deb'
$urlrstudio = 'http://download2.rstudio.org/'

# See http://www.rstudio.com/shiny/server/install-opensource
$shinyserver = 'shiny-server-1.3.0.403-amd64.deb'
$urlshiny = 'http://download3.rstudio.org/ubuntu-12.04/x86_64/'


#http://projects.puppetlabs.com/projects/puppet/wiki/Simple_Text_Patterns/7
define line($file, $line, $ensure = 'present') {
    case $ensure {
        default : { err ( "unknown ensure value ${ensure}" ) }
        present: {
            exec { "/bin/echo '${line}' >> '${file}'":
                unless => "/bin/grep -qFx '${line}' '${file}'"
            }
        }
        absent: {
            exec { "/usr/bin/perl -ni -e 'print unless /^\\Q${line}\\E\$/' '${file}'":
                onlyif => "/bin/grep -qFx '${line}' '${file}'"
            }
        }
    }
}

# Update system for r install
class update_system {   
    exec {'add-repositories':
      provider => shell,
      command  =>
      'add-apt-repository "deb http://cran.rstudio.com/bin/linux/ubuntu trusty/";
      apt-key adv --keyserver keyserver.ubuntu.com --recv-keys E084DAB9;
      add-apt-repository ppa:opencpu/opencpu-1.4;
      add-apt-repository ppa:marutter/rrutter;
      add-apt-repository ppa:marutter/c2d4u;'
    }
    -> 
    exec {'apt_update':
        provider => shell,
        command  => 'apt-get update;',
    }
    ->
    package {['software-properties-common','libapparmor1',
              'libdbd-mysql', 'libmysqlclient-dev','libssl-dev',
              'libglu1-mesa-dev', # for rgl
              'python-software-properties', 
              'upstart', 'psmisc',
              'python', 'g++', 'make','vim', 'whois','mc','libcairo2-dev',
              'default-jdk', 'gdebi-core', 'libcurl4-gnutls-dev','libxml2-dev',
              'pandoc','r-cran-rmarkdown','r-cran-knitr']:
      ensure  => present,
    }
    ->
    exec {'upgrade-system':
      provider => shell,
	    timeout => 2000, # On slow machines, this needs some time
      command  =>'apt-get -y upgrade;apt-get -y autoremove;',
    }
    ->
    # Install host additions (following https://www.virtualbox.org/manual/ch04.html
    # this must be done after upgrading.
    package {'dkms':
        ensure => present,
    }    
}

class install_opencpu {
    package { 'opencpu' :
      ensure => installed,
    }
}


# Install r base and packages
class install_r {
    package {['r-base', 'r-base-dev']:
      ensure  => present,
      require => Package['dkms'],
    }    
    ->
    exec {'install-r-packages':
        provider => shell,
        timeout  => 3000,
        command  => 'Rscript /vagrant/usefulpackages.R'
    }
}

# Download and install shiny server and add users
class install_shiny_server {
    # Download shiny server
    wget::fetch {'shiny-server-download':
        require  => [Exec['install-r-packages'],
                    Package['software-properties-common',
                    'python-software-properties', 'g++']],
        destination => "${shinyserver}",
        timeout  => 300,
        source   => "${urlshiny}${shinyserver}",
    }
    ->    
    # Create rstudio_users group
    group {'rstudio_users':
        ensure => present,
    }
    ->
    # http://www.pindi.us/blog/getting-started-puppet
    user {'vagrant': 
       name => 'vagrant',
       groups => 'vboxsf'
    }
    ->
    user {'shiny':
        ensure  => present,
        groups   => ['rstudio_users', 'vagrant','vboxsf'], # adding to vagrant required for startup
        shell   => '/bin/bash',
        managehome => true,
        name    => 'shiny',
        home    => '/srv/shiny-server',
    }   
    ->
    # Install shiny server
    exec {'shiny-server-install':
        provider => shell,
        command  => "gdebi -n ${shinyserver}",
    }
    # Copy example shiny files
    file {'/srv/shiny-server/01_hello':
        source  => '/usr/local/lib/R/site-library/shiny/examples/01_hello',
        owner   => 'shiny',
        ensure  => 'directory',
        recurse => true,
    }   
    ->
   # Setting password during user creation does not work    
   # Password shiny is public; this is for local use only
   exec {'shinypassword':
        provider => shell,
        command => 'usermod -p `mkpasswd -H md5 shiny` shiny',
     }
    ->
    # Remove standard app
    file {'/srv/shiny-server/index.html':
        ensure => absent,
    } 
}

# install rstudio and start service
class install_rstudio_server_source {
    # Download rstudio server
    wget::fetch {'rstudio-server-download':
        require  => Package['r-base'],
        timeout  => 0,
        destination => "${rstudioserver}",
        source  => "${urlrstudio}${rstudioserver}",
    }
    ->
    exec {'rstudio-server-install':
        provider => shell,
        command  => "gdebi -n ${rstudioserver}",
    }
}

# other way to  rstudio and start service
class install_rstudio_server {
    package {'rstudio-server':
      ensure  => present,
    } 
}


# Make sure that both services are running
class check_services{
    service {'shiny-server':
        ensure    => running,
        require   => [User['shiny'], Exec['shiny-server-install']],
        hasstatus => true,
    }
    service {'rstudio-server':
        ensure    => running,
        require   => User['shiny'],
        hasstatus => true,
    }
}

class startupscript{
    file { '/etc/init/makeshinylinks.conf':
       require   => [Service['shiny-server'], Exec['shinypassword']],
       ensure => 'link',
       target => '/vagrant/makeshinylinks.conf',
    }
 ->
    exec{ 'reboot-makeshiny-links':
       #require   => File['/vagrant/makeshinylinks.sh'],
       provider  => shell,
       command   => '/vagrant/makeshinylinks.sh',
    }  
}



include update_system
include install_r
include install_opencpu
include install_shiny_server
include install_rstudio_server
include check_services
#include startupscript

