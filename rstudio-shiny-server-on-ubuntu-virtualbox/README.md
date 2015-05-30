Running R Shiny and RStudio Server in a Virtual Box
===================================================
dieter.menne@menne-biomed.de


The original intent of this project was to create and easy-to-install Shiny/RStudio environment for hospitals. It works, but installation via vagrant is not as easy as I had hoped, in practice non-professional users do not like anything that includes typing into a black box.

Using an OVA build from Virtual Box worked better, but does not allow for easy updating.

I am currently working on more light-weight solution using Docker, but without RStudio integration; (https://github.com/dmenne/gastro-docker). Currently (April 2015) using it via Boot2Docker is somewhat messy on Windows, requiring an virtual Mini-Linux. Following Microsoft's announcements, there is hope that one day Docker will run natively on Windows.


Thanks to Joe Cheng, Yihui Xie, and Jeff Allen for resolving problem with language locales and upstart delays on virtual machines; and all the other RStudio/Shiny stuff, evidently.

Why
---

The Shiny server (http://shiny.rstudio.com) and the RStudio IDE server (http://rstudio.com) only run in Linux systems. If you are working in Windows, you have to connect to an external Linux server, or configure a virtual system.
With vagrant (http://www.vagrantup.com/), the installation and configuration of a virtual system can be automated; all required files are downloaded from the Internet using the Puppet (http://puppetlabs.com/) configuration system.

A vagrant-package does not contain the virtual machine and the installation, but rather the rules to construct one. Therefore, it is a small download, about 15kB zipped.

All features described here have only been tested with Windows as the host operating system.

No attempts have been made to create a secure installation; passwords are well-known (`vagrant/vagrant` and `shiny/shiny`).

Installation Instructions
------------

All commands starting with _vagrant_ should be given on the command line (i.e. the _black box_ in Windows).  If the command `vagrant` fails, please add the path to the directory with `vagrant.exe` to the  PATH environment variable.

This installation has been tested with Oracle VirtualBox, version 4.3.8, 4.3.12, 4.3.20 and 4.3.24 on a Windows 7/64 host; and Vagrant 1.5.4 and 1.7.2. There is a major issue with synchronized folders in Virtual Box 4.3.10; see  [here](http://stackoverflow.com/questions/22717428/vagrant-error-failed-to-mount-folders-in-linux-guest) and [here](https://github.com/mitchellh/vagrant/issues/3341); __do not use this version__. 


* Install [Oracle Virtual Box](https://www.virtualbox.org/wiki/Downloads). Do not use version 4.3.10! Last version successfully tested is 4.3.24.
* Install [Vagrant](http://www.vagrantup.com/downloads.html); best install it into folder `D:\vagrant` or `C:\vagrant` to avoid the `HashiCorp`-super-folder. 
* Create a subfolder of `\vagrant`; we assumed it is called `\vagrant\rstudio-shiny-server-on-ubuntu`, but you can choose any name you like.
* When you have `git` installed, clone the project into this subfolder: `git clone git@bitbucket.org:dmenne/rstudio-shiny-server-on-ubuntu.git`.
* When you do not have `git` installed, [download the zip file](https://bitbucket.org/dmenne/rstudio-shiny-server-on-ubuntu/downloads/rstudio-shiny-server-on-ubuntu.zip) and unzip it into the `\vagrant\rstudio-shiny-server-on-ubuntu` directory. Note that the zip file may be a few revisions behind the git version.
* Open a Command Window in the repository folder, e.g `cd \vagrant\rstudio-shiny-server-on-ubuntu`; this is the folder that contains a file named `Vagrantfile`.
* Run: `vagrant up` from the command line in this directory; this will need some time on the first start, because all packages are downloaded. With a good Internet connection, the first installation will need about 40 minutes, or 20 minutes when the Ubuntu box has been cached.
* If there are no errors, continue running Shiny or RStudio. If there are errors, read below "Troubleshooting and additional info"


Running Shiny 
-------------

* In your browser, use `localhost:3838` to connect to the Shiny servers. To edit your Shiny project, use the mapped folder in `vagrant\rstudio-shiny-server-on-ubuntu\shiny-server`; you do not have to do any work in the Ubuntu-box.
* You can connect to Shiny in your network, if the port 3838 is open. See the RStudio server installation instructions how to change the port.
* On each system start, a script checks if there are new user-installed Shiny applications in the `vagrant/R` path, and creates links to these displayed in the index page when Shiny is started. When you install a new application with Shiny apps, these are only visible in the index after a `vagrant reload`. The script tries to find a useful name, avoiding the ubiquitous `shiny` for display in the index page.


Running RStudio
-------------

* In your browser, use `localhost:8787` to connect to RStudio.  The user name is `shiny` and the password is also `shiny`. Your home directory map to `vagrant\rstudio-shiny-server-on-ubuntu\shiny-server` in the host operating system (assumed Windows).

Running OpenCPU
---------------

* The OpenCPU server is installed and redirected to port 8080 on the host. Try localhost:8080/ocpu. For details, see https://www.opencpu.org/ .

Installing R packages
-------------------
* Use RStudio to install packages from the CRAN server; see the RStudio documentation for details.
* To install from a local source package (`xxx.tar.gz`), copy the file to `vagrant\rstudio-shiny-server-on-ubuntu\shiny-server`, and use the package installation (Packages/Install/Install from: Package archive). 
* If the installed package has a Shiny app, after a `vagrant reload` the app will be listed on the home page of Shiny; see file `makeshinylinks.sh` how this magic happens on system reboot. You only have to do the reload once after installation of a new packages, not after installing updates.



Troubleshooting and additional info
------------------------------------

* If you see error messages, try again: `vagrant reload` and/or `vagrant provision`.  
* When in doubt run: `vagrant destroy` followed by  `vagrant up`.
* To connect to the Ubuntu system, use `vagrant ssh`; no password required. This is an insecure connection, and intended to be used on a local machine only. You must have SSH installed on your computer, e.g. from git or MinGW.
* To re-run the installation of the R-related components, use `vagrant provision`
* For more detailed debugging information, uncomment the line  `#:options => ["--verbose", "--debug"] do |puppet|` 
in file `Vagrantfile` by removing the `#`and prepending a `# to `:options => [] do |puppet|``.
* The important information controlling the installation is in file `Vagrantfile`, `usefulpackages.R`, and `puppet/manifests/rstudio-shiny-server.pp`.
* If you want to map additional directories to your Windows host, add lines following the pattern `config.vm.synced_folder  "etc", "/etc/shiny-server", create:true` to `Vagrantfile`, and do a `vagrant reload`.
* If you want additional R-packages installed, add these to the list in `usefulpackages.R`; do not forget to make a copy of the changes, this file will be overridden when you update to a more recent version of  `rstudio-shiny-server-on-ubuntu`.
* Check the top lines in `puppet/manifests/rstudio-shiny-server.pp` if you want to change the installed server versions; details are given here: for [RStudio](http://www.rstudio.com/shiny/server/install-opensource) and for [Shiny](http://www.rstudio.com/ide/download/server)
* The default installation gives 2048MB memory to the VM. This might be too much, forcing smaller host systems to a crawl, so check the line `v.memory = 2048` in `Vagrantfile`
* It is not necessary to keept the "black box" open to run the server. The system can run totally in the background.
* Once everything works ok, you can start and stop the Virtual Box system in your Oracle VM Virtual Box manager; use `rstudio-shiny-server-on-ubuntu_default`. Only use `vagrant reload` when you have changed settings.
* When you have in installed the optional snapshot plugin (see above), you can take a snapshot with `vagrant snapshot take <name>`, `vagrant snapshot list` to list them, and `vagrant snapshot go <name>` to restore a snapshot.

More 
------
* A tutorial to get to know [Vagrant](http://docs.vagrantup.com/v1/docs/getting-started/index.html)
* For a reference visit [Puppet](https://puppetlabs.com/)
