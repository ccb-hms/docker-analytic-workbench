#
# Data Science Workbench Image
# Author: Nathan Palmer
# Copyright: Harvard Medical School
#

FROM hmsccb/rstudio-server

#------------------------------------------------------------------------------
# Install R packages
#------------------------------------------------------------------------------

# install shiny
RUN Rscript -e "remotes::install_cran('shiny')"

# install BioConductor
RUN Rscript -e "if (!requireNamespace('BiocManager', quietly = TRUE)) remotes::install_cran('BiocManager')"
RUN Rscript -e "BiocManager::install(version = '3.14', update=FALSE, ask=FALSE)"

# install standard data science and bioinformatics packages
RUN Rscript -e "remotes::install_cran('DBI')"
RUN Rscript -e "remotes::install_cran('odbc')"
RUN Rscript -e "remotes::install_cran('Rcpp')"
RUN Rscript -e "remotes::install_cran('roxygen2')"
RUN Rscript -e "remotes::install_cran('tidyverse')"
RUN Rscript -e "remotes::install_cran('git2r')"
RUN Rscript -e "remotes::install_cran('getPass')"
RUN Rscript -e "remotes::install_cran('xlsx')"
RUN Rscript -e "remotes::install_cran('data.table')"
RUN Rscript -e "remotes::install_cran('dplyr')"
RUN Rscript -e "remotes::install_cran('splines')"
RUN Rscript -e "remotes::install_cran('tidyr')"
RUN Rscript -e "remotes::install_cran('glmnet')"
RUN Rscript -e "remotes::install_cran('glmpath')"
RUN Rscript -e "remotes::install_cran('testthat')"
RUN Rscript -e "remotes::install_cran('survival')"
RUN Rscript -e "remotes::install_cran('survminer')"

# install R packages for connecting to SQL Server and working with resulting data sets
RUN Rscript -e "devtools::install_github('https://github.com/nathan-palmer/FactToCube.git', ref='v1.0.0')"
RUN Rscript -e "devtools::install_github('https://github.com/nathan-palmer/MsSqlTools.git', ref='v1.0.0')"
RUN Rscript -e "devtools::install_github('https://github.com/nathan-palmer/SqlTools.git', ref='v1.0.0')"


#------------------------------------------------------------------------------
# Final odds and ends
#------------------------------------------------------------------------------

# Set default kerberos configuration
COPY krb5.conf /etc/krb5.conf
