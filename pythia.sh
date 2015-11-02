package: pythia
version: "%(tag_basename)s"
source: https://github.com/alisw/pythia8
requires:
  - lhapdf
  - HepMC
  - boost
tag: alice/v8211pre
env:
  PYTHIA8DATA: "$PYTHIA_ROOT/share/Pythia8/xmldoc"
---
#!/bin/bash -e
rsync -a $SOURCEDIR/ ./

./configure --prefix=$INSTALLROOT \
            --enable-shared \
            --with-hepmc2=${HEPMC_ROOT} \
            --with-lhapdf6=${LHAPDF_ROOT} \
            --with-boost=${BOOST_ROOT}

if [[ $ARCHITECTURE =~ "slc5.*" ]]; then
    ln -s LHAPDF5.h include/Pythia8Plugins/LHAPDF5.cc
    ln -s LHAPDF6.h include/Pythia8Plugins/LHAPDF6.cc
    sed -i -e 's#\$(CXX) -x c++ \$< -o \$@ -c -MD -w -I\$(LHAPDF\$\*_INCLUDE) \$(CXX_COMMON)#\$(CXX) -x c++ \$(<:.h=.cc) -o \$@ -c -MD -w -I\$(LHAPDF\$\*_INCLUDE) \$(CXX_COMMON)#' Makefile
fi

make ${JOBS+-j $JOBS}
make install
chmod a+x $INSTALLROOT/bin/pythia8-config

# Modulefile
MODULEDIR="$INSTALLROOT/etc/modulefiles"
MODULEFILE="$MODULEDIR/$PKGNAME"
mkdir -p "$MODULEDIR"
cat > "$MODULEFILE" <<EoF
#%Module1.0
proc ModulesHelp { } {
  global version
  puts stderr "ALICE Modulefile for $PKGNAME $PKGVERSION-@@PKGREVISION@$PKGHASH@@"
}
set version $PKGVERSION-@@PKGREVISION@$PKGHASH@@
module-whatis "ALICE Modulefile for $PKGNAME $PKGVERSION-@@PKGREVISION@$PKGHASH@@"
# Dependencies
module load BASE/1.0 lhapdf/$LHAPDF_VERSION-$LHAPDF_REVISION boost/$BOOST_VERSION-$BOOST_REVISION HepMC/$HEPMC_VERSION-$HEPMC_REVISION
# Our environment
setenv PYTHIA_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
setenv PYTHIA8DATA \$::env(PYTHIA_ROOT)/share/Pythia8/xmldoc
prepend-path PATH \$::env(PYTHIA_ROOT)/bin
prepend-path LD_LIBRARY_PATH \$::env(PYTHIA_ROOT)/lib
EoF