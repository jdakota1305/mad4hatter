Bootstrap: docker
From: rocker/tidyverse:4.2.1
Stage: spython-base

%post

apt-get update && apt-get install -y build-essential python3-pip libbz2-dev && rm -rf /var/lib/apt/lists/*
pip install cutadapt

mkdir -p /usr/local/lib/R/etc/ /usr/lib/R/etc/
echo "options(repos = c(CRAN = 'https://cran.rstudio.com/'), download.file.method = 'libcurl', Ncpus = 4)" | tee /usr/local/lib/R/etc/Rprofile.site | tee /usr/lib/R/etc/Rprofile.site
R -e 'install.packages("remotes")'

# Update apt-get
Rscript -e 'install.packages("remotes", version = "2.4.2")'
Rscript -e 'remotes::install_cran("ggbeeswarm", upgrade="never", version="0.6.1")'
Rscript -e 'remotes::install_cran("gridExtra",upgrade="never", version = "2.3")'
Rscript -e 'remotes::install_cran("rmarkdown",upgrade="never", version = "2.17")'
Rscript -e 'remotes::install_cran("gridExtra",upgrade="never", version = "2.3")'
Rscript -e 'remotes::install_cran("foreach",upgrade="never", version = "1.5.2")'
Rscript -e 'remotes::install_cran("doMC",upgrade="never", version = "1.3.8")'

Rscript -e 'BiocManager::install("dada2", version = "3.15", ask = FALSE)'
Rscript -e 'BiocManager::install("muscle", ask = FALSE)'
Rscript -e 'BiocManager::install("BSgenome", ask = FALSE)'

%runscript
exec /bin/bash "$@"
%startscript
exec /bin/bash "$@"
