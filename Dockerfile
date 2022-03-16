#
# Data Science Workbench Image
#

FROM ubuntu:20.04

#------------------------------------------------------------------------------
# Basic initial system configuration
#------------------------------------------------------------------------------

USER root

# install standard Ubuntu Server packages
RUN yes | unminimize

# we're going to create a non-root user at runtime and give the user sudo
RUN apt-get update && \
	apt-get -y install sudo \
	&& echo "Set disable_coredump false" >> /etc/sudo.conf
	
# set locale info
RUN echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen \
	&& apt-get update && apt-get install -y locales \
	&& locale-gen en_US.utf8 \
	&& /usr/sbin/update-locale LANG=en_US.UTF-8
ENV LC_ALL en_US.UTF-8
ENV LANG en_US.UTF-8
ENV TZ=America/New_York

WORKDIR /tmp

#------------------------------------------------------------------------------
# Install system tools and libraries via apt
#------------------------------------------------------------------------------

ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update \
	&& apt-get install \
		-y \
		#--no-install-recommends \
		ca-certificates \
		curl \
		less \
		libgomp1 \
		libpango-1.0-0 \
		libxt6 \
		libsm6 \
		make \
		texinfo \
		libtiff-dev \
		libpng-dev \
		libicu-dev \
		libpcre3 \
		libpcre3-dev \
		libbz2-dev \
		liblzma-dev \
		gcc \
		g++ \
		openjdk-8-jre \
		openjdk-8-jdk \
		gfortran \
		libreadline-dev \
		libx11-dev \
		libcurl4-openssl-dev \ 
		libssl-dev \
		libxml2-dev \
		wget \
		libtinfo5 \
		openssh-server \
		ssh \
		xterm \
		xauth \
		screen \
		tmux \
		git \
		libgit2-dev \
		nano \
		emacs \
		vim \
		man-db \
		zsh \
		unixodbc \
		unixodbc-dev \
		gnupg \
		krb5-user \
		python3-dev \
		python3 \ 
		python3-pip \
		alien \
		libaio1 \
		pkg-config \ 
		libkrb5-dev \
		unzip \
		cifs-utils \
		lsof \
		libnlopt-dev \
		libopenblas-openmp-dev \
		libpcre2-dev \
	&& rm -rf /var/lib/apt/lists/*


#------------------------------------------------------------------------------
# Configure system tools
#------------------------------------------------------------------------------

# required for ssh and sshd	
RUN mkdir /var/run/sshd	

# configure X11
RUN sed -i "s/^.*X11Forwarding.*$/X11Forwarding yes/" /etc/ssh/sshd_config \
    && sed -i "s/^.*X11UseLocalhost.*$/X11UseLocalhost no/" /etc/ssh/sshd_config \
    && grep "^X11UseLocalhost" /etc/ssh/sshd_config || echo "X11UseLocalhost no" >> /etc/ssh/sshd_config	

# tell git to use the cache credential helper and set a 1 day-expiration
RUN git config --system credential.helper 'cache --timeout 86400'


#------------------------------------------------------------------------------
# Install and configure database connectivity components
#------------------------------------------------------------------------------

# # install MS SQL Server ODBC driver -- not available for ARM64
# RUN curl https://packages.microsoft.com/keys/microsoft.asc | apt-key add - \
# 	&& echo "deb [arch=amd64] https://packages.microsoft.com/ubuntu/18.04/prod bionic main" | tee /etc/apt/sources.list.d/mssql-release.list \
# 	&& apt-get update \
# 	&& ACCEPT_EULA=Y apt-get install msodbcsql17

# install FreeTDS driver
WORKDIR /tmp
RUN wget ftp://ftp.freetds.org/pub/freetds/stable/freetds-1.1.40.tar.gz
RUN tar zxvf freetds-1.1.40.tar.gz
RUN cd freetds-1.1.40 && ./configure --enable-krb5 && make && make install
RUN rm -r /tmp/freetds*

# tell unixodbc where to find the FreeTDS driver shared object
RUN echo '\n\
[FreeTDS]\n\
Driver = /usr/local/lib/libtdsodbc.so \n\
' >> /etc/odbcinst.ini

# # install Oracle Instant Client and Oracle ODBC driver -- needs updating to condition on CPU architecture
# ARG ORACLE_RELEASE=18
# ARG ORACLE_UPDATE=5
# ARG ORACLE_RESERVED=3

# RUN wget https://download.oracle.com/otn_software/linux/instantclient/${ORACLE_RELEASE}${ORACLE_UPDATE}000/oracle-instantclient${ORACLE_RELEASE}.${ORACLE_UPDATE}-basic-${ORACLE_RELEASE}.${ORACLE_UPDATE}.0.0.0-${ORACLE_RESERVED}.x86_64.rpm \
#     && wget https://download.oracle.com/otn_software/linux/instantclient/${ORACLE_RELEASE}${ORACLE_UPDATE}000/oracle-instantclient${ORACLE_RELEASE}.${ORACLE_UPDATE}-devel-${ORACLE_RELEASE}.${ORACLE_UPDATE}.0.0.0-${ORACLE_RESERVED}.x86_64.rpm \
#     && wget https://download.oracle.com/otn_software/linux/instantclient/${ORACLE_RELEASE}${ORACLE_UPDATE}000/oracle-instantclient${ORACLE_RELEASE}.${ORACLE_UPDATE}-sqlplus-${ORACLE_RELEASE}.${ORACLE_UPDATE}.0.0.0-${ORACLE_RESERVED}.x86_64.rpm \
#     && wget https://download.oracle.com/otn_software/linux/instantclient/${ORACLE_RELEASE}${ORACLE_UPDATE}000/oracle-instantclient${ORACLE_RELEASE}.${ORACLE_UPDATE}-odbc-${ORACLE_RELEASE}.${ORACLE_UPDATE}.0.0.0-${ORACLE_RESERVED}.x86_64.rpm

# RUN alien -i oracle-instantclient${ORACLE_RELEASE}.${ORACLE_UPDATE}-basic-${ORACLE_RELEASE}.${ORACLE_UPDATE}.0.0.0-${ORACLE_RESERVED}.x86_64.rpm \
#    && alien -i oracle-instantclient${ORACLE_RELEASE}.${ORACLE_UPDATE}-devel-${ORACLE_RELEASE}.${ORACLE_UPDATE}.0.0.0-${ORACLE_RESERVED}.x86_64.rpm \
#    && alien -i oracle-instantclient${ORACLE_RELEASE}.${ORACLE_UPDATE}-sqlplus-${ORACLE_RELEASE}.${ORACLE_UPDATE}.0.0.0-${ORACLE_RESERVED}.x86_64.rpm \
#    && alien -i oracle-instantclient${ORACLE_RELEASE}.${ORACLE_UPDATE}-odbc-${ORACLE_RELEASE}.${ORACLE_UPDATE}.0.0.0-${ORACLE_RESERVED}.x86_64.rpm

# RUN rm oracle-instantclient*.rpm 

# # define the environment variables for oracle
# ENV LD_LIBRARY_PATH=/usr/lib/oracle/${ORACLE_RELEASE}.${ORACLE_UPDATE}/client64/lib/${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH} \
#     ORACLE_HOME=/usr/lib/oracle/${ORACLE_RELEASE}.${ORACLE_UPDATE}/client64 \
#     PATH=$PATH:$ORACLE_HOME/bin

# RUN echo "/usr/lib/oracle/${ORACLE_RELEASE}.${ORACLE_UPDATE}/client64/lib" | sudo tee /etc/ld.so.conf.d/oracle.conf

# # tell unixodbc where to find the Oracle driver shared object
# RUN echo '\n\
# [Oracle]\n\
# Driver = /usr/lib/oracle/'${ORACLE_RELEASE}'.'${ORACLE_UPDATE}'/client64/lib/libsqora.so.18.1 \n\
# ' >> /etc/odbcinst.ini

# install pyodbc
RUN pip3 install pyodbc


#------------------------------------------------------------------------------
# Install and configure R
#------------------------------------------------------------------------------

# declare R version to be installed, make it available at build and run time
ENV R_VERSION_MAJOR 4
ENV R_VERSION_MINOR 1
ENV R_VERSION_BUGFIX 3
ENV R_VERSION $R_VERSION_MAJOR.$R_VERSION_MINOR.$R_VERSION_BUGFIX
ENV R_HOME=/usr/local/lib/R

WORKDIR /tmp
RUN wget https://cran.r-project.org/src/base/R-4/R-$R_VERSION.tar.gz
RUN tar zxvf R-$R_VERSION.tar.gz
RUN cd R-$R_VERSION && ./configure -with-blas -with-lapack --enable-R-shlib && make && make install

# Clean up downloaded files
WORKDIR /tmp
RUN rm -r /tmp/R-$R_VERSION*

# set CRAN repository snapshot for standard package installs
ENV R_REPOSITORY=https://cran.microsoft.com/snapshot/2022-03-15
RUN echo 'options(repos = c(CRAN = "'$R_REPOSITORY'"))' >> $R_HOME/etc/Rprofile.site

# tell R to use wget (devtools::install_github aimed at HTTPS connections had problems with libcurl)
RUN echo 'options("download.file.method" = "wget")' >> $R_HOME/etc/Rprofile.site
RUN Rscript -e "install.packages(c('curl', 'httr'))"

#------------------------------------------------------------------------------
# Install R packages
#------------------------------------------------------------------------------

# use the remotes package to manage installations
RUN Rscript -e "install.packages('remotes')"

# configure and install rJava
RUN R CMD javareconf
RUN Rscript -e "remotes::install_cran('rJava', type='source')"

# install devtools, which for some reason depends on shiny
RUN Rscript -e "remotes::install_cran('shiny')"
RUN Rscript -e "remotes::install_cran('devtools')"

# install BioConductor
RUN Rscript -e "if (!requireNamespace('BiocManager', quietly = TRUE)) remotes::install_cran('BiocManager')"
RUN Rscript -e "BiocManager::install(version = '3.14', update=FALSE, ask=FALSE)"

# install standard data science and bioinformatics packages
RUN Rscript -e "remotes::install_cran('Rcpp')"
RUN Rscript -e "remotes::install_cran('roxygen2')"
RUN Rscript -e "remotes::install_cran('tidyverse')"
RUN Rscript -e "remotes::install_cran('git2r')"
RUN Rscript -e "remotes::install_cran('getPass')"
RUN Rscript -e "remotes::install_cran('xlsx')"
RUN Rscript -e "remotes::install_cran('data.table')"
RUN Rscript -e "remotes::install_cran('dplyr')"
RUN Rscript -e "remotes::install_cran('exactmeta')"
RUN Rscript -e "remotes::install_cran('fmsb')"
RUN Rscript -e "remotes::install_cran('forestplot')"
RUN Rscript -e "remotes::install_cran('metafor')"
RUN Rscript -e "remotes::install_cran('rtf')"
RUN Rscript -e "remotes::install_cran('splines')"
RUN Rscript -e "remotes::install_cran('tidyr')"
RUN Rscript -e "remotes::install_cran('stringr')"
RUN Rscript -e "remotes::install_cran('survival')"
RUN Rscript -e "remotes::install_cran('np')"
RUN Rscript -e "remotes::install_cran('codetools')"
RUN Rscript -e "remotes::install_cran('glmnet')"
RUN Rscript -e "remotes::install_cran('glmpath')"
RUN Rscript -e "remotes::install_cran('lars')"
RUN Rscript -e "remotes::install_cran('zoo')"
RUN Rscript -e "remotes::install_cran('testthat')"
RUN Rscript -e "remotes::install_cran('DBI')"
RUN Rscript -e "remotes::install_cran('odbc')"
RUN Rscript -e "remotes::install_cran('caret')"
RUN Rscript -e "remotes::install_cran('icd.data')"
RUN Rscript -e "remotes::install_cran('broom')"
RUN Rscript -e "remotes::install_cran('survminer')"
RUN Rscript -e "remotes::install_cran('lme4')"

# # this one is missing from newer snapshots, so revert to older version
RUN Rscript -e "remotes::install_cran('icd', repos='https://cran.microsoft.com/snapshot/2020-07-16')"

# install R packages for connecting to SQL Server and working with resulting data sets
RUN Rscript -e "devtools::install_github('https://github.com/nathan-palmer/FactToCube.git', ref='v1.0.0')"
RUN Rscript -e "devtools::install_github('https://github.com/nathan-palmer/MsSqlTools.git', ref='v1.0.0')"
RUN Rscript -e "devtools::install_github('https://github.com/nathan-palmer/SqlTools.git', ref='v1.0.0')"

# # the following steps are needed for Roracle package
# RUN mkdir $ORACLE_HOME/rdbms \
#     && mkdir $ORACLE_HOME/rdbms/public 
# RUN cp /usr/include/oracle/${ORACLE_RELEASE}.${ORACLE_UPDATE}/client64/* $ORACLE_HOME/rdbms/public \
#     && chmod -R 777  $ORACLE_HOME/rdbms/public

# # install ROracle
# RUN Rscript -e "remotes::install_cran('ROracle')" 

 # allow modification of these locations so users can install R packages without warnings
RUN chmod -R 777 $R_HOME/library
RUN chmod -R 777 $R_HOME/doc/html/packages.html


# #------------------------------------------------------------------------------
# # Install and configure RStudio Server
# #------------------------------------------------------------------------------

# RUN mkdir /opt/rstudioserver
# WORKDIR /opt/rstudioserver

# RUN wget http://archive.ubuntu.com/ubuntu/pool/main/o/openssl1.0/libssl1.0.0_1.0.2n-1ubuntu5.6_amd64.deb
# RUN dpkg -i ./libssl1.0.0_1.0.2n-1ubuntu5.6_amd64.deb

# RUN apt-get update && apt-get install -y gdebi-core

# # older RStudio version (try to deal with name / pwd prompt from git credential manager):
# # 1.2 works, later versions require modifying the GIT_ASKPASS environment variable
# # to suppress a prompt in R
# # RUN wget https://download2.rstudio.org/server/trusty/amd64/rstudio-server-1.2.5042-amd64.deb
# # RUN gdebi -n rstudio-server-1.2.5042-amd64.deb

# RUN wget https://download2.rstudio.org/server/bionic/amd64/rstudio-server-1.4.1106-amd64.deb
# RUN gdebi --non-interactive rstudio-server-1.4.1106-amd64.deb

# # Copy RStudio Config
# COPY rserver.conf /etc/rstudio/rserver.conf

# attempt build rstudio server from source
WORKDIR /tmp
RUN wget https://github.com/rstudio/rstudio/tarball/v2022.02.0+443
RUN tar zxvf v2022.02.0+443
RUN cd /tmp/rstudio-rstudio-9f79693/dependencies/linux && ./install-dependencies-focal 
RUN cd /tmp/rstudio-rstudio-9f79693 && mkdir build 
RUN cd /tmp/rstudio-rstudio-9f79693/build  && cmake .. -DRSTUDIO_TARGET=Server -DCMAKE_BUILD_TYPE=Release
RUN cd /tmp/rstudio-rstudio-9f79693/build && make install
RUN useradd -r rstudio-server

RUN cp /usr/local/extras/init.d/debian/rstudio-server /etc/init.d/
RUN update-rc.d rstudio-server defaults


#------------------------------------------------------------------------------
# Final odds and ends
#------------------------------------------------------------------------------

# Copy startup script
RUN mkdir /startup
COPY startup.sh /startup/startup.sh
RUN chmod 700 /startup/startup.sh

# Create a mount point for host filesystem data
RUN mkdir /HostData

# Set default kerberos configuration
COPY krb5.conf /etc/krb5.conf

RUN apt-get update \
	&& apt-get install \
		-y \
		systemd

RUN sed -i 's!^#PasswordAuthentication yes!PasswordAuthentication yes!' /etc/ssh/sshd_config
RUN systemctl enable ssh.service
EXPOSE 22

CMD ["/usr/sbin/init"]

# TODO: need to get it to run startup.sh 