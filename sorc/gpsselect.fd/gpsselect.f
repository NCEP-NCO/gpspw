      PROGRAM GPSSELECT
C this program reads a dump of GPS PW data and selects those
C reports closest in time to the desired time ISELT to be read in
      PARAMETER (MXTB=99999)
      REAL*8 TIME(2,MXTB),RCTM(2,MXTB)
      REAL*8 ZLAT(MXTB)
      REAL*8 ZLON(MXTB)
      REAL*8 TPW(MXTB)
C*
      DIMENSION OBTIME(MXTB),SOBTIME(MXTB)
      DIMENSION TZLAT(MXTB),SZLAT(MXTB)
      DIMENSION TZLON(MXTB),SZLON(MXTB)
      DIMENSION TTPW(MXTB),STPW(MXTB)
c TPW is an array with the original total preciptal water
c TTPW is a temporary array with the total preciptal water (used in the sort)
c STPW is an array with the sorted total preciptal water
      DIMENSION INDX(MXTB)
      CHARACTER*25 KEY1,KEY2,KEY3,KEY4,KEY5,KEY6
      CHARACTER*12 CHARGPS(MXTB),SCHARGPS(MXTB)
      CHARACTER*8  STID(MXTB)
      CHARACTER*4  OLDID
c input is from unit 21
      DATA LUN1 /21/
c bufr routine UFBTAB gives you all reports in dump
c with Mneumonics asked for
c NTAB is the number of values returned

c read the optimal selection time from unit 5
C this time is UTC with 2315 being 23 hours and 15 minutes UTC
C with 1230 being 12 hours and 30 minutes UTC, etc.
      READ(5,7) ISELT
 7    FORMAT(I4)
      WRITE(50,315) ISELT
 315  FORMAT('ISELT= ',I4)
      ISELT=ISELT +1
c one minute is added to favor the latest ob time over the one half hour older
c there could be draws as obs have times 15 and 45 minutes after the hour

      XHOUR=FLOAT(ISELT/100)
      XMINT=FLOAT(ISELT) - 100*XHOUR
      XSELT=XHOUR + XMINT/60.0
      WRITE(50,316) ISELT,XHOUR,XMINT,XSELT
 316  FORMAT('ISELT,XHOUR,XMINT,XSELT= ',I6,3(F7.2,' '))
C XSELT is a decimal version of the select time

      IGPS=0
c use UFBTAB to get arrays of various types from the dump
c     KEY1='RPID '
      KEY1='STSN '
      CALL UFBTAB(LUN1,STID,1,MXTB,NTAB,KEY1)
      KEY2='HOUR MINU '
      CALL UFBTAB(LUN1,TIME,2,MXTB,NTAB,KEY2)
      KEY3='RCHR RCMI '
      CALL UFBTAB(LUN1,RCTM,2,MXTB,NTAB,KEY3)
c     KEY4='CLAT '
      KEY4='CLATH '
      CALL UFBTAB(LUN1,ZLAT,1,MXTB,NTAB,KEY4)
c     KEY5='CLON '
      KEY5='CLONH '
      CALL UFBTAB(LUN1,ZLON,1,MXTB,NTAB,KEY5)
      KEY6='TPWT '
      CALL UFBTAB(LUN1,TPW,1,MXTB,NTAB,KEY6)
      WRITE(53,444) NTAB
 444  FORMAT(' NTAB= ',I8)

      WRITE(50,317) NTAB
 317  FORMAT('NTAB= ',I6)
      DO 33 I=1,NTAB 

      IF(TPW(I) .LT. 5.0E+10) THEN
      ZTIME=TIME(1,I) + TIME(2,I)/60.0
      RTIME=RCTM(1,I) + RCTM(2,I)/60.0
C ZTIME is a floating point version of the observation time
C RTIME is a floating point version of the receipt time
C XSELT is a floating point version of the select time

c since we want the observations closest to time ISELT
c but noting for observations with the same time, we want the latest
c receipt time.
c Therefore we make a character*12 variable that has characters
c 1-4 the station ID, characters 5-8 the difference between
c XSELT and ZTIME, with characters 9-12 the function of the
c difference between RTIME and ZTIME.
c This array CHARGPS is later sorted to help us find the select observations
      IGPS=IGPS+1
      CHARGPS(IGPS)(1:4)=STID(I)(1:4)
      TZLAT(IGPS)=ZLAT(I)
      TZLON(IGPS)=ZLON(I)
      TTPW(IGPS)=TPW(I)
      OBTIME(IGPS)=ZTIME
      TDIF1=ABS(ZTIME - XSELT)
      IF(TDIF1 .GT. 12.0) TDIF1=24.0 - TDIF1
      TDIF2=ABS(RTIME - ZTIME)
      IF(TDIF2 .GT. 12.0) TDIF2=24.0 - TDIF2
      IDIF1=NINT(100*TDIF1)
      IDIF2=9999 - NINT(100*TDIF2)
      WRITE(CHARGPS(IGPS)(5:8),45) IDIF1
      WRITE(CHARGPS(IGPS)(9:12),45) IDIF2
      WRITE(50,321) CHARGPS(IGPS),ZTIME,RTIME,TDIF1,TDIF2
 321  FORMAT('CHARGPS,ZTIME,RTIME,TDIF1,TDIF2= ',A12,' ',4F8.3)
 45   FORMAT(I4.4)
      ENDIF

 33   CONTINUE

      WRITE(50,318) IGPS
 318  FORMAT('IGPS= ',I6)
      IF(IGPS .GT. 0) THEN
c use heap sort to sort array CHARGPS
c sorted order is in array INDX
      CALL INDEXF(IGPS,CHARGPS,INDX)

      DO 200 K=1,IGPS
      SZLAT(K)=TZLAT(INDX(K))
      SZLON(K)=TZLON(INDX(K))
      STPW(K)=TTPW(INDX(K))
      SOBTIME(K)=OBTIME(INDX(K))
      SCHARGPS(K)=CHARGPS(INDX(K))
 200  CONTINUE

      DO 210 K=1,IGPS
      WRITE(50,319) K,SCHARGPS(K)
 319  FORMAT(I4,' ',A12)
 210  CONTINUE

      OLDID='    '
      DO 300 K=1,IGPS

C when SCHARGPS(K)(1:4) changes, then it gives the select report

      IF(SCHARGPS(K)(1:4) .NE. OLDID) THEN
      WRITE(53,125) SCHARGPS(K)(1:4),SOBTIME(K),SZLAT(K),SZLON(K),
     &STPW(K)
      OLDID=SCHARGPS(K)(1:4)
      ENDIF

 125  FORMAT(A4,4(' ',F9.2))

 300  CONTINUE

      ENDIF

      STOP
      END
       SUBROUTINE INDEXF (N,ARRIN,INDX)
C
C      INDEXS AN ARRAY ARRIN(1...N)
C      INPUT:           N SPAN OF SORT
C                     ARRIN - ARRAY TO BE SORTED - NOT
C      OUTPUT: INDX - ARRAY OF INDEXES SUCH THAT ARRAY(INDX(I)) IS
C                     IN ASCENDING ORDER FOR J = 1,N
C
       INTEGER INDX(99999)
C      INTEGER ARRIN(*),Q
       CHARACTER*12 ARRIN(99999),Q

       DO 10 J = 1,N
           INDX(J) = J
10     CONTINUE

       L = N/2 + 1

       IR = N
33     CONTINUE
       IF (L.GT.1) THEN
           L = L - 1
           INDXT=INDX(L)
           Q = ARRIN(INDXT)
       ELSE
           INDXT = INDX(IR)
           Q = ARRIN(INDXT)
           INDX(IR) = INDX(1)
           IR = IR - 1
           IF ( IR.EQ. 1) THEN
               INDX(1) = INDXT
               RETURN
           ENDIF
       ENDIF
       I = L
       J = L*2

30     CONTINUE
           IF ( J.LE.IR) THEN
               IF (J.LT.IR.AND.ARRIN(INDX(J)).LT.ARRIN(INDX(J+1))) THEN
                       J = J +1
               ENDIF
               IF ( Q.LT.ARRIN(INDX(J)) ) THEN
                   INDX(I) = INDX(J)
                   I = J
                   J = J + I
               ELSE
                   J = IR + 1
               ENDIF
           ENDIF
       IF ( J.LE.IR) GOTO 30
       INDX(I) = INDXT
       GOTO 33
       END
