#!/bin/sh

if [ -f ../versions/build.ver ]; then . ../versions/build.ver ; fi

module reset 
module load intel/${intel_ver:?}
module load PrgEnv-intel/${PrgEnv_intel_ver:?}
module load bufr/${bufr_ver:?}
module load craype/${craype_ver:?}
module load cray-mpich/${cray_mpich_ver:?}
module load w3emc/${w3emc_ver:?}
module load w3nco/${w3nco_ver:?}

if [ $1 == "build" ]; then
module list
fi

if [ $# -ne 1 ]; then
   echo "argument must be one of build, install or clean"
   exit
fi

if [ $1 == "build" ]; then
   cd gpsselect.fd
   make clean
   make
   cd ../
   exit
elif [ $1 == "clean" ]; then
   cd gpsselect.fd
   make clean
   cd ../
   exit
elif [ $1 == "install" ]; then
   mv gpsselect.fd/gpsselect ../exec/
   exit
else
   echo "argument must be one of build, install or clean"
fi
exit
