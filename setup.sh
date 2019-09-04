#!/usr/bin/env bash

set -e

SONAR_ENV=${1:-sonar}

conda env update --name "$SONAR_ENV" --file environment.yml
source "$CONDA_PREFIX/etc/profile.d/conda.sh"
conda activate "$SONAR_ENV"
# Adding more as per https://github.com/scharch/SONAR/blob/master/Dockerfile
R --vanilla -e 'install.packages("ptinpoly", repos="http://cran.cnr.berkeley.edu/")'
cd SONAR && yes N | ./setup.py
cd SONAR && ln -s $(pwd -P)/sonar $CONDA_PREFIX/bin

# Goofy install of Perl's PDL::LinearAlgebra to work with LAPACK 3.6.0+
# https://github.com/PDLPorters/pdl-linearalgebra/issues/3
# https://sourceforge.net/p/pdl/bugs/435/
curl -L http://cpanmin.us | perl - App::cpanminus
wget https://cpan.metacpan.org/authors/id/C/CH/CHM/PDL-LinearAlgebra-0.12.tar.gz
tar xzf PDL-LinearAlgebra-0.12.tar.gz
find PDL-LinearAlgebra-0.12  -type f -name '*.pd' -exec sed -i -r 's/(.ggsvd)_/\13_/g' {} \;
tar czf PDL-LinearAlgebra-0.12-mod.tar.gz PDL-LinearAlgebra-0.12
cpanm PDL-LinearAlgebra-0.12-mod.tar.gz --build-args="OTHERLDFLAGS=-llapack"
rm -f PDL-LinearAlgebra-0.12{,-mod}.tar.gz 
