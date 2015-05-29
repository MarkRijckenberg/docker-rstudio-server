# PREREQUISITES: Ubuntu 14.04 LTS
# Based on:  https://github.com/rocker-org/rocker/blob/master/rstudio/Dockerfile
# FROM r-base:latest
## Start with the official Ubuntu 14.04 LTS image:
FROM ubuntu:14.04
## This handle reaches Carl and Dirk
MAINTAINER "Carl Boettiger and Dirk Eddelbuettel" rocker-maintainers@eddelbuettel.com

## Add RStudio binaries to PATH
ENV PATH /usr/lib/rstudio-server/bin/:$PATH 
ENV LANG en_US.UTF-8

##########################################################################################################
# add base PPA repositories
##########################################################################################################
RUN DEBIAN_FRONTEND=noninteractive apt-get update && apt-get install -y --no-install-recommends software-properties-common
RUN DEBIAN_FRONTEND=noninteractive add-apt-repository --yes ppa:marutter/rrutter
RUN DEBIAN_FRONTEND=noninteractive add-apt-repository --yes ppa:marutter/c2d4u

## Download and install RStudio server & dependencies
## Attempts to get detect latest version, otherwise falls back to version given in $VER
## Symlink pandoc, pandoc-citeproc so they are available system-wide
RUN rm -rf /var/lib/apt/lists/ \
  && apt-get update \
  && apt-get install -y --no-install-recommends \
  r-base  \
  r-base-dev \
  gdebi-core \
  wget \ 
  r-cran-irtshiny \
  r-cran-shiny \
  r-cran-shinyace \
  r-cran-shinybs \
  ca-certificates \
  file \
  git \
  libapparmor1 \
  libcurl4-openssl-dev \
  libssl-dev \
  psmisc \
  supervisor \
  sudo \
  && VER=$(wget --no-check-certificate -qO- https://s3.amazonaws.com/rstudio-server/current.ver) \
  && wget -q http://download2.rstudio.org/rstudio-server-${VER}-amd64.deb \
  && dpkg -i rstudio-server-${VER}-amd64.deb \
  && rm rstudio-server-*-amd64.deb \
  && ln -s /usr/lib/rstudio-server/bin/pandoc/pandoc /usr/local/bin \
  && ln -s /usr/lib/rstudio-server/bin/pandoc/pandoc-citeproc /usr/local/bin \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/


## A default user system configuration. For historical reasons,
## we want user to be 'rstudio', but it is 'docker' in r-base
#RUN usermod -l rstudio docker \
#  && usermod -m -d /home/rstudio rstudio \
#  && groupmod -n rstudio docker \
#  && git config --system user.name rstudio \
#  && git config --system user.email rstudio@example.com \
#  && git config --system push.default simple \
#  && echo '"\e[5~": history-search-backward' >> /etc/inputrc \
#  && echo '"\e[6~": history-search-backward' >> /etc/inputrc \
#  && echo "rstudio:rstudio" | chpasswd

## User config and supervisord for persistant RStudio session
#COPY userconf.sh /usr/bin/userconf.sh
#COPY add-students.sh /usr/local/bin/add-students
#COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
RUN mkdir -p /var/log/supervisor \
  && chgrp staff /var/log/supervisor \
  && chmod g+w /var/log/supervisor \
  && chgrp staff /etc/supervisor/supervisord.conf
EXPOSE 8787

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/supervisord.conf"]

# Use Ubuntu 14.04 init system.
CMD ["/sbin/init"]
