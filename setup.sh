#!/usr/bin/env bash

set -e

SONAR_ENV=${1:-example-sonar}

type -P mamba > /dev/null && \
	mamba env update --file environment.yml || \
	conda env update --file environment.yml
source "$CONDA_PREFIX/etc/profile.d/conda.sh"
conda activate "$SONAR_ENV"
# Adding more as per https://github.com/scharch/SONAR/blob/master/Dockerfile
R --vanilla -e "install.packages('ptinpoly', lib='$CONDA_PREFIX/lib/R/library', repos='http://cran.us.r-project.org')"

git submodule init
git submodule update
pushd SONAR
yes N | ./setup.py
ln -s $(pwd -P)/sonar $CONDA_PREFIX/bin
popd

curl -L http://cpanmin.us | perl - App::cpanminus
cpanm PDL::LinearAlgebra::Trans --build-args="OTHERLDFLAGS=-llapack"
