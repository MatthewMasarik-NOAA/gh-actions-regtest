!> @file
!> @brief Contains program for tide prediction, W3PRTIDE.
!>
!> @author F. Ardhuin @date 21-Apr-2020
!
#include "w3macros.h"
!/ ------------------------------------------------------------------- /
!> @brief Predicts tides (current or water level) to be used during
!>  run by ww3_shel or ww3_multi  (this takes much less memory).
!>
!> @author F. Ardhuin @date 21-Apr-2020
PROGRAM W3PRTIDE
  !/
  !/                  +-----------------------------------+
  !/                  | WAVEWATCH III           NOAA/NCEP |
  !/                  |           F. Ardhuin              |
  !/                  |                        FORTRAN 90 |
  !/                  | Last update :         21-Apr-2020 |
  !/                  +-----------------------------------+
  !/
  !/    29-Mar-2013 : Creation                            ( version 4.11 )
  !/    17-Oct-2013 : Manages missing data for UNST grids ( version 4.12 )
  !/    06-Jun-2018 : COMPUTE VNEIGH: calculate the number of connected
  !/                  triangles for a given point         ( version 6.04 )
  !/    21-Apr-2020 : MPI implementation                  ( version 7.13 )
  !/    21-Apr-2020 : bug fix for rectilinear grid        ( version 7.13 )
  !/     1-Feb-2020 : Improve indexing, A.Roland	        ( version 7.14 )

  !/
  !/    Copyright 2013 National Weather Service (NWS),
  !/       National Oceanic and Atmospheric Administration.  All rights
  !/       reserved.  WAVEWATCH III is a trademark of the NWS.
  !/       No unauthorized use without permission.
  !/
  !  1. Purpose :
  !
  !     Predicts tides (current or water level) to be used during
  !     run by ww3_shel or ww3_multi  (this takes much less memory).
  !
  !  2. Method :
  !
  !     See documented input file.
  !
  !  3. Parameters :
  !
  !     Local parameters.
  !     ----------------------------------------------------------------
  !       NDSI    Int.  Input unit number ("ww3_prtide.inp").
  !       NDSLL   Int.  Unit number(s) of long-lat file(s)
  !       NDSF    I.A.  Unit number(s) of input file(s).
  !       NDSDAT  Int.  Unit number for output data file.
  !       FLTIME  Log.  Time flag for input fields, if false, single
  !                     field, time read from NDSI.
  !       IDLALL  Int.  Layout indicator used by INA2R. +
  !       IDFMLL  Int.  Id. FORMAT indicator.           |
  !       FORMLL  C*16  Id. FORMAT.                     | Long-lat
  !       FROMLL  C*4   'UNIT' / 'NAME' indicator       |    file(s)
  !       NAMELL  C*40  Name of long-lat file(s)        +
  !       IDLAF   I.A.   +
  !       IDFMF   I.A.   |
  !       FORMF   C.A.   | Idem. fields file(s)
  !       FROMF   C*4    |
  !       NAMEF   C*50   +
  !       FORMT   C.A.  Format or time in field.
  !       XC      R.A.  Components of input vector field or first
  !                     input scalar field
  !       YC      R.A.  Components of input vector field or second
  !                     input scalar field
  !     ----------------------------------------------------------------
  !
  !  4. Subroutines used :
  !
  !      Name      Type  Module   Description
  !     ----------------------------------------------------------------
  !      W3NMOD    Subr. W3GDATMD Set number of model.
  !      W3SETG    Subr.   Id.    Point to selected model.
  !      W3NOUT    Subr. W3ODATMD Set number of model for output.
  !      W3SETO    Subr.   Id.    Point to selected model for output.
  !      ITRACE    Subr. W3SERVMD Subroutine tracing initialization.
  !      STRACE    Subr.   Id.    Subroutine tracing.
  !      NEXTLN    Subr.   Id.    Get next line from input filw
  !      EXTCDE    Subr.   Id.    Abort program as graceful as possible.
  !      STME21    Subr. W3TIMEMD Convert time to string.
  !      W3IOGR    Subr. W3IOGRMD Reading/writing model definition file.
  !      W3FLDO    Subr. W3FLDSMD Opening of WAVEWATCH III generic shell
  !                               data file.
  !      W3FLDG    Subr.   Id.    Reading/writing shell input data.
  !     ----------------------------------------------------------------
  !
  !  5. Called by :
  !
  !     None, stand-alone program.
  !
  !  6. Error messages :
  !
  !     - Checks on files and reading from file.
  !     - Checks on validity of input parameters.
  !
  !  7. Remarks :
  !
  !     - Input fields need to be continuous in longitude and latitude.
  !
  !  8. Structure :
  !
  !     ----------------------------------------------------
  !        To be updated ...
  !     ----------------------------------------------------
  !
  !  9. Switches :
  !
  !     !/S     Enable subroutine tracing.
  !     !/T     Enable test output,
  !
  !     !/NCO   NCEP NCO modifications for operational implementation.
  !
  ! 10. Source code :
  !
  !/ ------------------------------------------------------------------- /
  USE CONSTANTS
  !/
  !     USE W3GDATMD, ONLY: W3NMOD, W3SETG
#ifdef W3_NL1
  USE W3ADATMD,ONLY: W3NAUX, W3SETA
#endif
  USE W3ODATMD, ONLY: IAPROC, NAPROC, NAPERR, NAPOUT
  USE W3ODATMD, ONLY: W3NOUT, W3SETO
  USE W3SERVMD, ONLY : ITRACE, NEXTLN, EXTCDE, STRSPLIT
#ifdef W3_S
  USE W3SERVMD, ONLY : STRACE
#endif
  USE W3TIMEMD
  USE W3ARRYMD, ONLY : INA2R, INA2I
  USE W3IOGRMD, ONLY: W3IOGR
  USE W3FLDSMD, ONLY: W3FLDO, W3FLDG, W3FLDD, W3FLDTIDE1, W3FLDTIDE2
  !/
  USE W3GDATMD
  USE W3GSRUMD
  USE W3ODATMD, ONLY: NDSE, NDST, NDSO, FNMPRE
  USE W3TIDEMD
  USE W3IDATMD
  !
  IMPLICIT NONE
  !
#ifdef W3_MPI
  INCLUDE "mpif.h"
#endif
  !/
  !/ ------------------------------------------------------------------- /
  !/ Local parameters
  !/
  INTEGER                 :: NDSI, NDSF, NDSM, NDSDAT, NDSTRC, NTRACE
  INTEGER                 :: IERR, IFLD, I, JJ, J, IX, IY
  INTEGER                 :: DTTST, NDSEN, PRTIDE_DT
  INTEGER                 :: TIDE_PRMF, FLAGTIDE, TINDEX
  INTEGER                 :: TIDEOK, TIDE_MAX, TIDE_MAXI
  INTEGER                 :: K, ICON, IX2, SUMOK, NBAD, ITER
  INTEGER                 :: IE, IP, IP2, II, IFOUND, ALREADYFOUND
  INTEGER                 :: TIDE_KD0, INT24, INTDYS       ! "Gregorian day constant"
#ifdef W3_MPI
  INTEGER                 :: IERR_MPI, IND, REST, SLICE
#endif
  INTEGER                 :: TIME(2), TIDE_START(2), TIDE_END(2)
  INTEGER                 :: INDMAX(70), PR_INDS(70)
  !
  INTEGER, ALLOCATABLE    :: BADPOINTS(:,:), VNEIGH(:,:), CONN(:)
#ifdef W3_MPI
  INTEGER, ALLOCATABLE    :: NELEM(:), CUMUL(:)
#endif
  !
  REAL                    :: WCURTIDEX, WCURTIDEY, TIDE_ARGX, TIDE_ARGY
  REAL                    :: AMPCOS, AMPSIN
  !
  REAL                    :: TIDE_FX(44),UX(44),VX(44), MAXVALCON(70)
  !
  REAL, ALLOCATABLE       :: FX(:,:), FY(:,:), FA(:,:)
#ifdef W3_MPI
  REAL, ALLOCATABLE       :: FX1D(:), FY1D(:), FA1D(:)
  REAL, ALLOCATABLE       :: FX1DL(:), FY1DL(:), FA1DL(:)
#endif
  !
  DOUBLE PRECISION        :: d1,h,TIDE_HOUR,HH,pp,s,p,enp,dh,dpp,ds,dp,dnp,tau
  !
  CHARACTER*256           :: FILENAMEXT
  CHARACTER               :: TIDECONSTNAMES*1024
  CHARACTER*23            :: IDTIME
  CHARACTER               :: COMSTR*1, IDFLD*3
  !
  CHARACTER(LEN=100)      :: TIDECON_PRNAMES(70), TIDECON_MAXNAMES(70)
  CHARACTER(LEN=100)      :: TIDECON_MAXVALS(70)
  !
  LOGICAL                 :: TIDEFILL
  !
  !/
  !/ ------------------------------------------------------------------- /
  !/

  !==========================================================
  !
  ! Initialization
  !
  !==========================================================

  !
  ! 1.a  Set number of models
  !
  CALL W3NMOD ( 1, 6, 6 )
  CALL W3SETG ( 1, 6, 6 )
#ifdef W3_NL1
  CALL W3NAUX (    6, 6 )
  CALL W3SETA ( 1, 6, 6 )
#endif
  CALL W3NOUT (    6, 6 )
  CALL W3SETO ( 1, 6, 6 )
  !
  ! 1.b  IO set-up.
  !
  NDSI   = 10
  NDSO   =  6
  NDSE   =  6
  NDST   =  6
  NDSM   = 11
  NDSDAT = 12
  NDSF   = 13
  !
  NDSTRC =  6
  NTRACE = 10
  TIDEFILL =.TRUE.
  CALL ITRACE ( NDSTRC, NTRACE )
  !
#ifdef W3_NCO
  !
  ! Redo according to NCO
  !
  NDSI   = 11
  NDSO   =  6
  NDSE   = NDSO
  NDST   = NDSO
  NDSM   = 12
  NDSDAT = 51
  NDSTRC = NDSO
#endif

#ifdef W3_S
  CALL STRACE (IENT, 'W3PRTIDE')
#endif

  !
  ! 1.c MPP initializations
  !
#ifdef W3_SHRD
  NAPROC = 1
  IAPROC = 1
#endif
  !
#ifdef W3_MPI
  CALL MPI_INIT      ( IERR_MPI )
  CALL MPI_COMM_SIZE ( MPI_COMM_WORLD, NAPROC, IERR_MPI )
  CALL MPI_COMM_RANK ( MPI_COMM_WORLD, IAPROC, IERR_MPI )
  IAPROC = IAPROC + 1  ! this is to have IAPROC between 1 and NAPROC
#endif
  !
  IF ( IAPROC .EQ. NAPERR ) THEN
    NDSEN  = NDSE
  ELSE
    NDSEN  = -1
  END IF
  !
  IF ( IAPROC .EQ. NAPOUT ) WRITE (NDSO,900)
  !
  OPEN (NDSI,FILE=TRIM(FNMPRE)//'ww3_prtide.inp',STATUS='OLD',        &
       ERR=800,IOSTAT=IERR)
  REWIND (NDSI)
  READ (NDSI,'(A)',END=801,ERR=802,IOSTAT=IERR) COMSTR
  IF (COMSTR.EQ.' ') COMSTR = '$'
  IF ( IAPROC .EQ. NAPOUT ) WRITE (NDSO,901) COMSTR

  !==========================================================
  !
  ! Read model definition file.
  !
  !==========================================================

  CALL W3IOGR ( 'READ', NDSM )
  IF ( IAPROC .EQ. NAPOUT ) WRITE (NDSO,902) GNAME
  ALLOCATE ( FX(NX,NY), FY(NX,NY), FA(NX,NY),  BADPOINTS(NX,NY) )

  !==========================================================
  !
  ! Read types from input file.
  !
  !==========================================================

  CALL NEXTLN ( COMSTR , NDSI , NDSEN )
  READ (NDSI,*,END=801,ERR=802,IOSTAT=IERR) IDFLD
  !
  IF ( IDFLD.EQ.'LEV' ) THEN
    IFLD    = 2
  ELSE IF ( IDFLD.EQ.'CUR' ) THEN
    IFLD    = 4
  ELSE
    WRITE (NDSE,1030) IDFLD
    CALL EXTCDE ( 1 )
  END IF
  !
  CALL NEXTLN ( COMSTR , NDSI , NDSEN )
  READ (NDSI,'(A)',END=801,ERR=802,IOSTAT=IERR) TIDECONSTNAMES
  CALL NEXTLN ( COMSTR , NDSI , NDSE )
  TIDECON_PRNAMES(:)=''
  CALL STRSPLIT(TIDECONSTNAMES,TIDECON_PRNAMES)
  !
  CALL NEXTLN ( COMSTR , NDSI , NDSEN )
  READ (NDSI,'(A)',END=801,ERR=802,IOSTAT=IERR) TIDECONSTNAMES
  TIDECON_MAXNAMES(:)=''
  CALL STRSPLIT(TIDECONSTNAMES,TIDECON_MAXNAMES)
  !
  CALL NEXTLN ( COMSTR , NDSI , NDSEN )
  TIDECON_MAXVALS(:)=''
  READ (NDSI,'(A)',END=801,ERR=802,IOSTAT=IERR) TIDECONSTNAMES
  CALL STRSPLIT(TIDECONSTNAMES,TIDECON_MAXVALS)
  !
  CALL NEXTLN ( COMSTR , NDSI , NDSEN )
  READ (NDSI,*,END=801,ERR=802,IOSTAT=IERR) TIDE_START,PRTIDE_DT,TIDE_END
  CALL NEXTLN ( COMSTR , NDSI , NDSEN )
  READ (NDSI,*,END=801,ERR=802,IOSTAT=IERR) FILENAMEXT
  !
  CALL W3FLDO ('READ', IDFLD, NDSF, NDST,     &
       NDSE, NX, NY, GTYPE,               &
       IERR, FILENAMEXT, '', TIDEFLAGIN=FLAGTIDE )
  !
  IF (FLAGTIDE.NE.1) GOTO 803
  !
  CALL VUF_SET_PARAMETERS

  !==========================================================
  !
  ! Read tidal amplitudes and phases
  !
  !==========================================================

  CALL W3FLDTIDE1 ( 'READ',  NDSF, NDST, NDSE, NX, NY, IDFLD, IERR )
  CALL W3FLDTIDE2 ( 'READ',  NDSF, NDST, NDSE, NX, NY, IDFLD, 0, IERR )
  CLOSE(NDSF)

  !

  IF (GTYPE.EQ.UNGTYPE) THEN

    COUNTRI = MAXVAL(CCON)
    ALLOCATE(VNEIGH(NX,2*COUNTRI))
    ALLOCATE(CONN(NX))
    VNEIGH(:,:) = 0
    CONN(:) = 0
    !
    J = 0
    DO IP = 1, NX
      IFOUND = 0
      DO II = 1, CCON(IP)
        J = J + 1
        IE = IE_CELL(J)
        IF (IP == TRIGP(1,IE)) THEN
          DO IP2=2,3
            ALREADYFOUND = 0
            DO I=1,IFOUND
              IF (VNEIGH(IP,I).EQ.TRIGP(IP2,IE)) ALREADYFOUND=ALREADYFOUND+1
            END DO
            IF (ALREADYFOUND.EQ.0) THEN
              IFOUND=IFOUND+1
              VNEIGH(IP,IFOUND)=TRIGP(IP2,IE)
            END IF
          END DO
        END IF

        IF (IP == TRIGP(2,IE)) THEN
          DO IP2=3,4
            ALREADYFOUND = 0
            DO I=1,IFOUND
              IF (VNEIGH(IP,I).EQ.TRIGP(MOD(IP2-1,3)+1,IE)) ALREADYFOUND=ALREADYFOUND+1
            END DO
            IF (ALREADYFOUND.EQ.0) THEN
              IFOUND=IFOUND+1
              VNEIGH(IP,IFOUND)=TRIGP(MOD(IP2-1,3)+1,IE)
            END IF
          END DO
        END IF

        IF (IP == TRIGP(3,IE)) THEN
          DO IP2=1,2
            ALREADYFOUND = 0
            DO I=1,IFOUND
              IF (VNEIGH(IP,I).EQ.TRIGP(IP2,IE)) ALREADYFOUND=ALREADYFOUND+1
            END DO
            IF (ALREADYFOUND.EQ.0) THEN
              IFOUND=IFOUND+1
              VNEIGH(IP,IFOUND)=TRIGP(IP2,IE)
            END IF
          END DO
        END IF
      END DO ! CCON
      ! CONN is a counter on connected points. In comparison with the number of connected triangle
      ! CCON, it will enable to spot whether a point belong to the contour
      !
      CONN(IP)=IFOUND
      DO I=2,IFOUND
        DO JJ=1,i-1
          IF (VNEIGH(IP,JJ).EQ. VNEIGH(IP,I)) THEN
            COUNTCON(IP)=COUNTCON(IP)-1
            VNEIGH(IP,I:IFOUND)=VNEIGH(IP,I+1:IFOUND+1)  ! removes the double point
          END IF
        END DO
      END DO
    END DO !NX

  END IF ! UNGTYPE

  !==========================================================
  !
  ! Apply the maximum threshold value to tidal constituents
  !
  !==========================================================

  CALL TIDE_FIND_INDICES_PREDICTION(TIDECON_PRNAMES,PR_INDS,TIDE_PRMF)
  TIDE_MAX=0
  TIDE_MAXI=0
  DO WHILE (len_trim(TIDECON_MAXNAMES(TIDE_MAXI+1)).NE.0)
    TIDE_MAXI=TIDE_MAXI+1
    DO J=1,TIDE_MF
      IF (TRIM(TIDECON_NAME(J)).EQ.TRIM(TIDECON_MAXNAMES(TIDE_MAXI))) THEN
        TIDE_MAX=TIDE_MAX+1
        INDMAX(TIDE_MAX)=J
        READ(TIDECON_MAXVALS(TIDE_MAXI),*) MAXVALCON(TIDE_MAX)
        IF (IAPROC.EQ.NAPOUT) THEN
          WRITE(NDSO,'(A,I8,A,F10.2)') &
               'Maximum allowed value for amplitude:',&
               J,TRIM(TIDECON_NAME(J)),MAXVALCON(TIDE_MAX)
        END IF
      END IF
    END DO
  END DO

  !==========================================================
  !
  ! Create the binary output file
  !
  !==========================================================

  FLAGTIDE = 0
  IF (IAPROC .EQ. NAPOUT) THEN
    CALL W3FLDO ('WRITE', IDFLD, NDSDAT, NDST, NDSE, NX, NY,      &
         GTYPE, IERR, 'ww3', TIDEFLAGIN=FLAGTIDE)
  END IF

  !==========================================================
  !
  ! Set arrays for MPI exchanges
  !
  !==========================================================

#ifdef W3_MPI
  SLICE=NX/NAPROC
  REST=MOD(NX,NAPROC)
  IF(REST.GE.IAPROC) SLICE=SLICE+1
#endif

#ifdef W3_MPI
  ! set total 1D array (nx)
  ALLOCATE ( FX1D(NX), FY1D(NX), FA1D(NX))
  FX1D(:)=0.
  FY1D(:)=0.
  FA1D(:)=0.
#endif

#ifdef W3_MPI
  ! set local 1D array (slice)
  ALLOCATE(FX1DL(SLICE))
  ALLOCATE(FY1DL(SLICE))
  ALLOCATE(FA1DL(SLICE))
  FX1DL(:)=0.
  FY1DL(:)=0.
  FA1DL(:)=0.
#endif


#ifdef W3_MPI
  ! set arrays for number of elements per MPI proc
  ALLOCATE(NELEM(NAPROC))
  ALLOCATE(CUMUL(NAPROC))
  NELEM(1) = NX / NAPROC
  IF (REST .GT. 0) NELEM(1) = NELEM(1) + 1
  CUMUL(1) = 0
  DO I=2,NAPROC
    CUMUL(I)=CUMUL(I-1)+NELEM(I-1)
    NELEM(I) = NX / NAPROC
    IF (REST .GT. I-1) NELEM(I) = NELEM(I) + 1
  END DO
#endif

#ifdef W3_MPIT
  WRITE(100+IAPROC,*) "Number of points for this processor ", IAPROC, " : ", NELEM(IAPROC), ' / ', NX
  WRITE(100+IAPROC,*) "Cumul of points for this processor ", IAPROC, " : ", CUMUL(IAPROC), ' / ', NX
#endif

  !==========================================================
  !
  ! Loop on time steps
  !
  !==========================================================

  DTTST  = DSEC21 ( TIDE_START , TIDE_END )
  IF ( DTTST .LE. 0. .OR. PRTIDE_DT .LT. 1 ) GOTO 888
  TIME = TIDE_START
  TIDE_KD0= 2415020
  !
  TINDEX = 1
  !
  DO
    DTTST  = DSEC21 ( TIME, TIDE_END )
    IF ( DTTST .LT. 0. ) GOTO 888
    !
    CALL STME21 ( TIME , IDTIME )
    IF ( IAPROC .EQ. NAPOUT ) WRITE (NDSO,973) IDTIME

    TIDE_HOUR = TIME2HOURS(TIME)
    !
    !*  THE ASTRONOMICAL ARGUMENTS ARE CALCULATED
    !
    d1=TIDE_HOUR/24.d0
    d1=d1-dfloat(TIDE_kd0)-0.5d0
    CALL ASTR(d1,h,pp,s,p,enp,dh,dpp,ds,dp,dnp)
    INT24=24
    INTDYS=int((TIDE_HOUR+0.00001)/INT24)
    HH=TIDE_HOUR-dfloat(INTDYS*INT24)
    TAU=HH/24.D0+H-S

    !==========================================================
    !
    ! Treatment of 'bad points' at first time step
    !
    !==========================================================

    BADPOINTS(:,:)=0
    NBAD =0

    IF (TINDEX.EQ.1) THEN
      DO IY = 1, NY
        DO IX=1, NX
          TIDEOK=1
          DO I=1,TIDE_MAX
            IF (ABS(TIDAL_CONST(IX,IY,INDMAX(I),1,1)) .GT.MAXVALCON(I) .OR. &
                 ABS(TIDAL_CONST(IX,IY,INDMAX(I),2,1)) .GT.MAXVALCON(I)) THEN
              TIDEOK = 0
              WRITE(NDSO,'(A,I8,F10.2,A,2F10.2)') &
                   '[BAD POINT] GREATER THAN THRESHOLD ', MAXVALCON(I), &
                   ' AT INDEX ', INDMAX(I),                             &
                   ' WITH X-Y COMPONENTS : ', ABS(TIDAL_CONST(IX,IY,INDMAX(I),1:2,1))
            END IF
            BADPOINTS(IX,IY) = BADPOINTS(IX,IY) + (1-TIDEOK)
          END DO

          IF (BADPOINTS(IX,IY).GT.0) THEN
            NBAD = NBAD +1
            WRITE(NDSE,*) 'BAD POINT:',IX,IY,NBAD, &
                 TIDAL_CONST(IX,IY,:,1,1),'##',TIDAL_CONST(IX,IY,:,2,1)
          END IF
        END DO
      END DO
      !
      DO ITER=1,2
        DO IY = 1, NY
          DO IX= 1, NX
            IF (BADPOINTS(IX,IY).GT.0) THEN
              TIDAL_CONST(IX,IY,:,1,1)=0
              TIDAL_CONST(IX,IY,:,2,1)=0


              IF (TIDEFILL.AND.(GTYPE.EQ.UNGTYPE)) THEN

                !
                ! Performs a vector sum of tidal constituents over neighbor nodes
                !
                DO J=1, TIDE_MF
                  DO K=1, 2
                    AMPCOS = 0
                    AMPSIN = 0
                    SUMOK = 0
                    DO ICON=1,COUNTCON(IX)
                      IX2=VNEIGH(IX,ICON)
                      IF (BADPOINTS(IX2,IY).EQ.0) THEN
                        SUMOK = SUMOK + 1
                        AMPCOS = AMPCOS+TIDAL_CONST(IX2,IY,J,K,1)*COS(TIDAL_CONST(IX2,IY,J,K,2)*DERA)
                        AMPSIN = AMPSIN+TIDAL_CONST(IX2,IY,J,K,1)*SIN(TIDAL_CONST(IX2,IY,J,K,2)*DERA)
                      END IF
                    END DO
                    IF (SUMOK.GT.1) THEN
                      !
                      ! Finalizes the amplitude and phase calculation from COS and SIN. Special case for mean value Z0.
                      !
                      IF (TIDECON_NAME(J).NE.'Z0   ') THEN
                        TIDAL_CONST(IX,IY,J,K,1) = SQRT(AMPCOS**2+AMPSIN**2)/SUMOK
                        TIDAL_CONST(IX,IY,J,K,2) = ATAN2(AMPSIN,AMPCOS)/DERA
                      ELSE
                        TIDAL_CONST(IX,IY,J,K,1) = AMPCOS/SUMOK
                        TIDAL_CONST(IX,IY,J,K,2) = 0.
                      END IF
                      IF(K.EQ.2.AND.J.EQ.TIDE_MF) THEN
                        NBAD=NBAD-1
                        BADPOINTS(IX,IY) = 0
                      END IF
                    ENDIF
                  END DO
                END DO
              END IF
            END IF
          END DO
        END DO
      END DO
      IF ( IAPROC .EQ. NAPOUT ) WRITE(NDSE,*) 'Number of remaining bad points:',NBAD
    END IF

    !==========================================================
    !
    ! For currents: 2 components
    !
    !==========================================================

    IF (IFLD.EQ.4) THEN
      DO IY = 1, NY
#ifdef W3_MPI
        IND=0
        DO IX=CUMUL(IAPROC)+1,CUMUL(IAPROC)+NELEM(IAPROC)
#endif
#ifdef W3_SHRD
          DO IX=1,NX
#endif
            CALL SETVUF_FAST(h,pp,s,p,enp,dh,dpp,ds,dp,dnp,tau,REAL(YGRD(IY,IX)),TIDE_FX,UX,VX)
            WCURTIDEX = 0.
            WCURTIDEY = 0.
            DO I=1,TIDE_PRMF
              J=PR_INDS(I)
              IF (TRIM(TIDECON_NAME(J)).EQ.'Z0') THEN
                WCURTIDEX = WCURTIDEX+TIDAL_CONST(IX,IY,J,1,1)
                WCURTIDEY = WCURTIDEY+TIDAL_CONST(IX,IY,J,2,1)
              ELSE
                TIDE_ARGX=(VX(J)+UX(J))*twpi-TIDAL_CONST(IX,IY,J,1,2)*DERA
                TIDE_ARGY=(VX(J)+UX(J))*twpi-TIDAL_CONST(IX,IY,J,2,2)*DERA
                WCURTIDEX = WCURTIDEX+TIDE_FX(J)*TIDAL_CONST(IX,IY,J,1,1)*COS(TIDE_ARGX)
                WCURTIDEY = WCURTIDEY+TIDE_FX(J)*TIDAL_CONST(IX,IY,J,2,1)*COS(TIDE_ARGY)
              END IF
            END DO
            IF (ABS(WCURTIDEX).GT.10..OR.ABS(WCURTIDEY).GT.10.)  THEN
              WRITE(NDSE,*) &
                   'WARNING: VERY STRONG CURRENT... BAD CONSTITUENTS?', &
                   IX, WCURTIDEX, WCURTIDEY ,  TIDAL_CONST(IX,IY,:,1,1),'##',TIDAL_CONST(IX,IY,:,2,1)
              STOP
            END IF
#ifdef W3_MPI
            IND=IND+1
            FX1DL(IND) = WCURTIDEX
            FY1DL(IND) = WCURTIDEY
            FA1DL(IND) = 0.
          END DO ! NX
#endif
#ifdef W3_SHRD
          FX(IX,IY) = WCURTIDEX
          FY(IX,IY) = WCURTIDEY
          FA(IX,IY) = 0.
        END DO ! NX
#endif

        !
        ! Gather from other MPI tasks
        !

#ifdef W3_MPI
        IF (NAPROC.GT.1) THEN
          CALL MPI_GATHERV(FX1DL, SLICE, MPI_REAL, FX1D, NELEM, &
               CUMUL, MPI_REAL, NAPOUT-1, MPI_COMM_WORLD, IERR_MPI)
          CALL MPI_GATHERV(FY1DL, SLICE, MPI_REAL, FY1D, NELEM, &
               CUMUL, MPI_REAL, NAPOUT-1, MPI_COMM_WORLD, IERR_MPI)
          CALL MPI_GATHERV(FA1DL, SLICE, MPI_REAL, FA1D, NELEM, &
               CUMUL, MPI_REAL, NAPOUT-1, MPI_COMM_WORLD, IERR_MPI)
        ELSE
          FX1D = FX1DL
          FY1D = FY1DL
          FA1D = FA1DL
        END IF
#endif

        !
        ! Convert from 1D to 2D array
        !
#ifdef W3_MPI
        IF (IAPROC .EQ. NAPOUT) THEN
          IND=0
          DO IX=1,NX
            IND=IND+1
            FX(IX,IY)=FX1D(IND)
            FY(IX,IY)=FY1D(IND)
            FA(IX,IY)=FA1D(IND)
          END DO
        END IF
#endif

      END DO ! NY
    END IF ! IFLD.EQ.4


    !==========================================================
    !
    ! For water levels: only 1 component
    !
    !==========================================================

    IF (IFLD.EQ.2) THEN
      DO IY = 1, NY
#ifdef W3_MPI
        IND=0
        DO IX=CUMUL(IAPROC)+1,CUMUL(IAPROC)+NELEM(IAPROC)
#endif
#ifdef W3_SHRD
          DO IX=1,NX
#endif
            CALL SETVUF_FAST(h,pp,s,p,enp,dh,dpp,ds,dp,dnp,tau,REAL(YGRD(IY,IX)),TIDE_FX,UX,VX)
            !
            ! Removes unlikely values ...
            !
            IF (TINDEX.EQ.1) THEN
              TIDEOK=1
              DO I=1,TIDE_MAX
                IF (ABS(TIDAL_CONST(IX,IY,INDMAX(I),1,1)) .GT.MAXVALCON(I)) &
                     TIDEOK = 0
              END DO
              IF (TIDEOK.EQ.0) THEN
                WRITE(NDSE,*) 'BAD POINT:',IX,IY, TIDAL_CONST(IX,IY,:,1,1)
                TIDAL_CONST(IX,IY,:,1,1)=0
              END IF
            END IF

            WCURTIDEX = 0.
            DO I=1,TIDE_PRMF
              J=PR_INDS(I)
              IF (TRIM(TIDECON_NAME(J)).EQ.'Z0') THEN
                WCURTIDEX = WCURTIDEX+TIDAL_CONST(IX,IY,J,1,1)
              ELSE
                TIDE_ARGX=(VX(J)+UX(J))*twpi-TIDAL_CONST(IX,IY,J,1,2)*DERA
                WCURTIDEX = WCURTIDEX+TIDE_FX(J)*TIDAL_CONST(IX,IY,J,1,1)*COS(TIDE_ARGX)
              END IF
            END DO
#ifdef W3_MPI
            IND=IND+1
            FX1DL(IND) = 0.
            FY1DL(IND) = 0.
            FA1DL(IND) = WCURTIDEX
          END DO ! NX
#endif
#ifdef W3_SHRD
          FX(IX,IY) = 0.
          FY(IX,IY) = 0.
          FA(IX,IY) = WCURTIDEX
        END DO ! NX
#endif



        !
        ! Gather from other MPI tasks
        !

#ifdef W3_MPI
        IF (NAPROC.GT.1) THEN
          CALL MPI_GATHERV(FX1DL, SLICE, MPI_REAL, FX1D, NELEM,&
               CUMUL, MPI_REAL, NAPOUT-1, MPI_COMM_WORLD, IERR_MPI)
          CALL MPI_GATHERV(FY1DL, SLICE, MPI_REAL, FY1D, NELEM,&
               CUMUL, MPI_REAL, NAPOUT-1, MPI_COMM_WORLD, IERR_MPI)
          CALL MPI_GATHERV(FA1DL, SLICE, MPI_REAL, FA1D, NELEM,&
               CUMUL, MPI_REAL, NAPOUT-1, MPI_COMM_WORLD, IERR_MPI)
        ELSE
          FX1D = FX1DL
          FY1D = FY1DL
          FA1D = FA1DL
        END IF
#endif

        !
        ! Convert from 1D to 2D array
        !
#ifdef W3_MPI
        IF (IAPROC .EQ. NAPOUT) THEN
          IND=0
          DO IX=1,NX
            IND=IND+1
            FX(IX,IY)=FX1D(IND)
            FY(IX,IY)=FY1D(IND)
            FA(IX,IY)=FA1D(IND)
          END DO
        END IF
#endif

      END DO ! NY
    END IF ! IFLD.EQ.2


    !==========================================================
    !
    ! Write into binary output file
    !
    !==========================================================

    IF (IAPROC .EQ. NAPOUT) THEN

      !        WHERE(FX.NE.FX) FX = 0.
      !        WHERE(FY.NE.FY) FY = 0.
      !        WHERE(FA.NE.FA) FA = 0.

      CALL W3FLDG ('WRITE', IDFLD, NDSDAT, NDST, NDSE, NX, NY,  &
           NX, NY, TIME, TIME, TIME, FX, FY, FA, TIME,  &
           FX, FY, FA, IERR)
    END IF

    !==========================================================
    !
    ! Increment the clock
    !
    !==========================================================

    CALL TICK21 ( TIME, FLOAT(PRTIDE_DT) )
    TINDEX = TINDEX +1

  END DO
  !
  GOTO 888
  !
  ! Error escape locations
  !
800 CONTINUE
  WRITE (NDSE,1000) IERR
  CALL EXTCDE ( 40 )
  !
801 CONTINUE
  WRITE (NDSE,1001)
  CALL EXTCDE ( 41 )
  !
802 CONTINUE
  WRITE (NDSE,1002) IERR
  CALL EXTCDE ( 42 )
  !
803 CONTINUE
  WRITE (NDSE,1003)
  CALL EXTCDE ( 43 )
  !
888 CONTINUE
  IF ( IAPROC .EQ. NAPOUT ) WRITE (NDSO,999)
#ifdef W3_MPI
  CALL MPI_FINALIZE  ( IERR_MPI )
#endif

  !
  ! Formats
  !
900 FORMAT (/15X,'  *** WAVEWATCH III  tide prediction ***  '/       &
       15X,'==============================================='/)
901 FORMAT ( '  Comment character is ''',A,''''/)
902 FORMAT ( '  Grid name : ',A/)
973 FORMAT ( '           Time : ',A)
  !
999 FORMAT(/'  End of program '/                                     &
       ' ========================================='/           &
       '         WAVEWATCH III Input preprocessing '/)
  !
1000 FORMAT (/' *** WAVEWATCH III ERROR IN W3PRTIDE : '/              &
       '     ERROR IN OPENING INPUT FILE'/                     &
       '     IOSTAT =',I5/)
  !
1001 FORMAT (/' *** WAVEWATCH III ERROR IN W3PRTIDE : '/              &
       '     PREMATURE END OF INPUT FILE'/)
  !
1002 FORMAT (/' *** WAVEWATCH III ERROR IN W3PRTIDE : '/              &
       '     ERROR IN READING FROM INPUT FILE'/                &
       '     IOSTAT =',I5/)
  !
1003 FORMAT (/' *** WAVEWATCH III ERROR IN W3PRTIDE : '/              &
       '     THE INPUT FILE DOES NOT CONTAIN TIDAL DATA'/)
  !
1030 FORMAT (/' *** WAVEWATCH III ERROR IN W3PRTIDE : '/              &
       '     ILLEGAL FIELD ID -->',A,'<--'/)
  !
  !/
  !/ End of W3PRTIDE ----------------------------------------------------- /
  !/
END PROGRAM W3PRTIDE
