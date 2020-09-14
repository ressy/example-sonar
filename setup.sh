#!/usr/bin/env bash

set -e

SONAR_ENV=${1:-sonar}

# Ideally we'd use environment.yml and let the dependencies get figured out,
# but something's not quite right with my list of packages there.  This exact
# list does work, though.
conda create --name "$SONAR_ENV" --file build.txt
source "$CONDA_PREFIX/etc/profile.d/conda.sh"
conda activate "$SONAR_ENV"
# Adding more as per https://github.com/scharch/SONAR/blob/master/Dockerfile
R --vanilla -e 'install.packages("ptinpoly", repos="http://cran.cnr.berkeley.edu/")'

git submodule init
git submodule update
pushd SONAR
yes N | ./setup.py
ln -s $(pwd -P)/sonar $CONDA_PREFIX/bin
popd

# Goofy install of Perl's PDL::LinearAlgebra to work with LAPACK 3.6.0+
# https://github.com/PDLPorters/pdl-linearalgebra/issues/3
# https://sourceforge.net/p/pdl/bugs/435/
curl -L http://cpanmin.us | perl - App::cpanminus
wget https://cpan.metacpan.org/authors/id/C/CH/CHM/PDL-LinearAlgebra-0.12.tar.gz
tar xzf PDL-LinearAlgebra-0.12.tar.gz
find PDL-LinearAlgebra-0.12  -type f -name '*.pd' -exec sed -i -r 's/(.ggsvd)_/\13_/g' {} \;
tar czf PDL-LinearAlgebra-0.12-mod.tar.gz PDL-LinearAlgebra-0.12
cpanm PDL-LinearAlgebra-0.12-mod.tar.gz --build-args="OTHERLDFLAGS=-llapack"
rm -rf PDL-LinearAlgebra-0.12/
rm -f PDL-LinearAlgebra-0.12{,-mod}.tar.gz 
