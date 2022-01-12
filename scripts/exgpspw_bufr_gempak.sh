#!/bin/sh

# Modified to store data in ship file format 
# 3/20/2008 - MJB/HPC
# 04/28/11    Robson/HPC      RHEL5 Octal fix.
# 11/02/2011  Robson/HPC      Moved to Compute Farm
# 05/28/2013  Brill           Changes for WCOSS
# 01/29/2015  Earle/NCO       Modified for NCO production - ksh

set -x

YMD=$PDY
HH=$cyc
MM=$mm

SFOUTF=gpspw_${YMD}${HH}

if [ -f $COMIN/$SFOUTF ]; then
   cp $COMIN/$SFOUTF $DATA
fi

$USHgpspw/gpsdumpdata2.sh $YMD ${HH} ${HH}${MM}
export err=$?; err_chk

RAWFILE=$DATA/gpsout${YMD}${HH}

# Process $RAWFILE contents into two files required by gempak to create a surface file, the first file
# sfefile_gpspw.txt contains the stnid, date/time, and the obs value
# the second file gpspw.tbl contains the stnid attributes including lat lon - IT IS VERY IMPORTANT THAT THIS 
# TABLE FILE ADHERES TO A STRICT FORMAT

MAXLINE=`cat $RAWFILE | wc -l`
if [ $MAXLINE -le 30 ]; then
   echo "WARNING: No data available yet for $YMD ${HH}Z"
   exit 0
fi

cnt=1
flag=0
while [ $cnt -le $MAXLINE ]
do
   line=`head -n $cnt $RAWFILE | tail -n 1`
   if [ $flag == 1 ]; then
      temph=$HH
      station=`echo $line | awk '{print $1}'`
      tempraw=`echo $line | awk '{print $2}'`
      pwinl=`echo $line | awk '{print $5}'`
      if [ `echo $tempraw | cut -c 4-4` -le 5 ]; then
         temph="${temph}00"
         YMD2=`echo $YMD | cut -c 3-8`
         a=`echo $pwinl | wc -c`
         a=`expr $a - 4`
         b=`echo $pwinl | cut -c 1-$a`
         a=`expr $a + 2`
         d=`echo $pwinl | cut -c $a-$a`
         if [ $d -gt 4 ]; then
            b=`expr $b + 1`
         fi
         pwin=`expr $b \* 10000 / 254 + 5`
         pwin=`expr $pwin / 10`
         lat=`echo $line | awk '{print $3}'`
         lon=`echo $line | awk '{print $4}'`
         echo "$station ${YMD2}/${temph} $lat $lon $pwin" >> sfefile_gpspw.txt			
         echo "$station     999999 UNKNOWN                          XX XX  ${lat} ${lon}     0 94" >> gpspw.tbl
      fi
   fi
   if [[ $line == *"NTAB"* ]]; then
      flag=1
      echo "PARM = SLAT;SLON;GPPW" > sfefile_gpspw.txt
      echo "\!STID    STNM   NAME                             ST CO   LAT    LON  ELEV PRI" > gpspw.tbl
      echo "\!(8)     (6)    (32)                            (2)(2)   (5)    (6)   (5) (2)" >> gpspw.tbl
      echo "\!EXAMPLE" >> gpspw.tbl
      echo "\!1LSU     999999 UNKNOWN                          XX XX  3041  -9118     0 94" >> gpspw.tbl
   fi
   cnt=`expr $cnt + 1`
done

# once the two files have been created, run gempak program SFCFIL to create an empty sfc file
# then run sfedit to populate the sfc file with data
if [ ! -e $SFOUTF ]; then
	sfcfil << ENDSFC
	 SFOUTF   = $SFOUTF
	 SFPRMF   = GPPW
	 STNFIL   = 
	 SHIPFL   = YES
	 TIMSTN   = 24/1000
	 SFFSRC   =  
	 l
	 r

	 exit
ENDSFC
fi

sfedit << ENDSFE
 SFEFIL   = sfefile_gpspw.txt
 SFFILE   = $SFOUTF
 l
 r
 
 exit
ENDSFE

if [ "$SENDCOM" == YES ]; then
   cp $SFOUTF $COMOUT
   cp $SFOUTF $COMOUT/$SFOUTF.${HH}${MM}

   if [ "$SENDDBN" == YES ]; then
      $DBNROOT/bin/dbn_alert MODEL GPSPW_BUFR_GEMPAK $job ${COMOUT}/${SFOUTF}
   fi
fi

date
###############################################
msg='JOB COMPLETED NORMALLY'
postmsg "$jlogfile" "$msg"
###############################################

set +x
echo " ***** $job PROCESSING COMPLETED NORMALLY *****"
echo " ***** $job PROCESSING COMPLETED NORMALLY *****"
echo " ***** $job PROCESSING COMPLETED NORMALLY *****"
set -x
exit
