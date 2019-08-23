#!/usr/bin/env bash

set -e

conda env update --name sonar --file environment.yml
source "$CONDA_PREFIX/etc/profile.d/conda.sh"
conda activate sonar
# Adding more as per https://github.com/scharch/SONAR/blob/master/Dockerfile
R --vanilla -e 'install.packages("ptinpoly", repos="http://cran.cnr.berkeley.edu/")'
cd SONAR && yes N | ./setup.py
