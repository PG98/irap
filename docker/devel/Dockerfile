FROM fedora:20
MAINTAINER Nuno Fonseca email: nuno.fonseca at gmail.com

# Update the image with the latest packages (recommended)
# and install missing packages
RUN sed -i "s/failovermethod=priority/failovermethod=roundrobin/" /etc/yum.repos.d/fedora.repo  && yum update -y && yum install -y zlib-devel python-devel bzip2-devel python readline-devel libgfortran gcc-gfortran gcc-c++ libX11-devel libXt-devel numpy ksh gd-devel libxml2-devel libxml2 libpng libcurl-devel expat-devel  libpangocairo db-devel java python gcc g++ gfortran curl-config git which make bzip2 bison gettext-devel  unzip make wget sqlite sqlite-devel db4-devel libdb-devel graphviz texlive tar java-devel xorg-x11-server-Xvfb && yum clean all

# 
WORKDIR /opt

# Install and clean in a single layer
RUN git clone http://github.com/nunofonseca/irap.git  irap_clone  && cd /opt/irap_clone &&./scripts/irap_install.sh -a /irap_install -s . && cd / && rm -rf /irap_install/tmp /opt/irap_clone  /root/.cpan*

WORKDIR /
RUN echo source /irap_install/irap_setup.sh >> ~/.bash_profile && echo source /irap_install/irap_setup.sh >> ~/.bashrc

RUN echo '#!/usr/bin/env bash' > /usr/bin/irap
RUN echo 'source /irap_install/irap_setup.sh' >> /usr/bin/irap
RUN echo '/irap_install/scripts/irap "$@"' >> /usr/bin/irap
RUN chmod u+x /usr/bin/irap

#ENTRYPOINT ["irap"]

