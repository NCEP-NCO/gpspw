#!/bin/ksh
#########################################################################
#  Gets GPS PW data from the BUFR files.				#
# 									#
# 									#
#  Log:									#
#  P. Manousos              	Created					#
#  K. Brill         20130408	Changes for TIDE/GYRE			#
#  K. Brill         20130628    Cleanup gpstst files			#
#  S. Earle         20150129    Modified for NCO; ksh                   #
#########################################################################
 
set -x
yyyymmdd=$1
theCycle=$2
theTime=$3

if [ "$#" -ne 3 ]; then
   echo "Enter a date and ztime and stickytime as follows:"
   echo "${0} 20050601 12 1230"
   echo "where 20050601 is June 01 2005"
   echo "and 12 gets you obs arriving in the 12Z hour"
   echo "and 1230 gets you obs in the 12Z hour closest to 1230Z"
   echo " "
   err_exit
fi

echo $3 > selecttime

DAT1=$1
HR1=$2
BACK="on"
DUPC="on"
TANK="${DCOM}"

$DUMPJB ${1}${2} 1.0 012 004 >>${pgmout} 
export err=$?
#     00 - no problem encountered
#     11 - all groups dumped - missing data from at least one group
#     22 - at least one group had no data dumped
#     99 - catastrophic problem - thread script abort
if [ $err -eq "11" ]; then
   echo "WARNING: err=$err - all groups dumped - missing data from at least one group"
elif [ $err -eq "22" ]; then
   echo "WARNING: err=$err - at least one group had no data dumped"
else
   err_chk
fi

ln -sf $DATA/012.ibm fort.21
ln -sf $DATA/gpstst${1}${2} fort.50
ln -sf $DATA/gpsout${1}${2} fort.53

${EXECgpspw}/gpsselect <selecttime >>$pgmout 2>errfile
export err=$?; err_chk

exit
