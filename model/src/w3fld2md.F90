!/ ------------------------------------------------------------------- /
Module W3FLD2MD
  !/
  !/                  +-----------------------------------+
  !/                  | WAVEWATCH III      NOAA/NCEP/NOPP |
  !/                  |           B. G. Reichl            |
  !/                  |                        FORTRAN 90 |
  !/                  | Last update :         22-Mar-2021 |
  !/                  +-----------------------------------+
  !/
  !/    01-Jul-2013 : Origination                         (version 3.14)
  !/    16-May-2014 : Finalizing                          (version 4.18)
  !/    19-Mar-2015 : Extending for non-10 m winds        (version 5.12)
  !/    27-Jul-2016 : Added Charnock output (J.Meixner)   (version 5.12)
  !/    22-Jun-2018 : Minor modification for application in shallow water.
  !/                                        (X.Chen)      (version 6.06)
  !/    22-Mar-2021 : Consider DAIR a variable            ( version 7.13 )
  !/
  !/    Copyright 2009 National Weather Service (NWS),
  !/       National Oceanic and Atmospheric Administration.  All rights
  !/       reserved.  WAVEWATCH III is a trademark of the NWS.
  !/       No unauthorized use without permission.
  !/
  !  1. Purpose :
  !
  !     This section of code has been designed to compute the wind
  !     stress vector from the wave spectrum, the wind speed
  !     vector, and the lower atmosphere stability.
  !     This code is based on the 2012 JGR paper, "Modeling Waves
  !     and Wind Stress" by Donelan, Curcic, Chen, and Magnusson.
  !
  !  2. Variables and types :
  !
  !     Not applicable
  !
  !  3. Subroutines and functions :
  !
  !      Name      Type  Scope    Description
  !     ----------------------------------------------------------------
  !      W3FLD2    Subr. Public   Donelan et al. 2012 stress calculation
  !     ----------------------------------------------------------------
  !
  !  4. Subroutines and functions used :
  !
  !      Name       Type  Module    Description
  !     ----------------------------------------------------------------
  !      STRACE     Subr. W3SERVMD  Subroutine tracing.
  !     ----------------------------------------------------------------
  !
  !  5. Remarks :
  !
  !  6. Switches :
  !
  !     !/S  Enable subroutine tracing.
  !
  !  7. Source code :
  !/
  !/ ------------------------------------------------------------------- /
  !/
  !
  PUBLIC
  !/
CONTAINS
  !/ ------------------------------------------------------------------- /
  SUBROUTINE W3FLD2(  ASPC,FPI, WNDX,WNDY, ZWND,                 &
       DEPTH, RIB, DAIR, UST, USTD, Z0, TAUNUX,TAUNUY,CHARN)
    !/
    !/                  +-----------------------------------+
    !/                  | WAVEWATCH III      NOAA/NCEP/NOPP |
    !/                  |           B. G. Reichl            |
    !/                  |                        FORTRAN 90 |
    !/                  | Last update :         22-Mar-2021 |
    !/                  +-----------------------------------+
    !/
    !/    01-Jul-2013 : Origination                         (version 3.14)
    !/    19-Mar-2015 : Clean-up for submission             (version 5.12)
    !/    22-Mar-2021 : Consider DAIR a variable            ( version 7.13 )
    !/
    !  1. Purpose :
    !
    !     Wind stress vector calculation from wave spectrum and
    !        n-meter wind speed vector.
    !
    !  2. Method :
    !     See Donelan et al. (2012).
    !
    !  3. Parameters :
    !
    !     Parameter list
    !     ----------------------------------------------------------------
    !       ASPC    Real   I   1-D Wave action spectrum.
    !       FPI     Real   I   Peak input frequency.
    !       WNDX    Real   I   X-dir wind (assumed referenced to current)
    !       WNDY    Real   I   Y-dir wind (assumed referenced to current)
    !       ZWND    Real   I   Wind height.
    !       DEPTH   Real   I   Water depth.
    !       RIB     Real   I   Bulk Richardson number in lower atm
    !       DAIR    Real   I   Air density
    !       TAUNUX  Real   0   X-dir viscous stress (guessed from prev.)
    !       TAUNUY  Real   0   Y-dir viscous stress (guessed from prev.)
    !       UST     Real   O   Friction velocity.
    !       USTD    Real   O   Direction of friction velocity.
    !       Z0      Real   O   Surface roughness length
    !       CHARN   Real   O,optional   Charnock parameter
    !     ----------------------------------------------------------------
    !
    !  4. Subroutines used :
    !
    !      Name      Type  Module   Description
    !     ----------------------------------------------------------------
    !      STRACE    Subr. W3SERVMD Subroutine tracing.
    !      APPENDTAIL Subr. W3FLD1MD  Modification of tail for calculation
    !      SIG2WN     Subr. W3FLD1MD  Depth-dependent dispersion relation
    !      MFLUX      Subr. W3FLD1MD  MO stability correction
    !      WND2Z0M    Subr. W3FLD1MD  Bulk Z0 from wind
    !      CALC_FPI   Subr. W3FLD1MD  Calculate peak frequency
    !     ----------------------------------------------------------------
    !
    !  5. Called by :
    !
    !      Name      Type  Module   Description
    !     ----------------------------------------------------------------
    !      W3ASIM    Subr. W3ASIMMD Air-sea interface module.
    !      W3EXPO    Subr.   N/A    Point output post-processor.
    !      GXEXPO    Subr.   N/A    GrADS point output post-processor.
    !     ----------------------------------------------------------------
    !
    !  6. Error messages :
    !
    !       None.
    !
    !  7. Remarks :
    !
    !  8. Structure :
    !
    !     See source code.
    !
    !  9. Switches :
    !
    !     !/S  Enable subroutine tracing.
    !
    ! 10. Source code :
    !
    !/ ------------------------------------------------------------------- /
    USE CONSTANTS, ONLY: DWAT, GRAV, TPI, PI, KAPPA
    USE W3GDATMD,  ONLY: NK, NTH, NSPEC, SIG, DTH, XFR, TH
    USE W3ODATMD,  ONLY: NDSE
    USE W3SERVMD,  ONLY: EXTCDE
    USE W3FLD1MD,  ONLY: APPENDTAIL,sig2wn,wnd2z0m,infld,tail_choice,&
         tail_level, tail_transition_ratio1,         &
         tail_transition_ratio2
#ifdef W3_S
    USE W3SERVMD, ONLY: STRACE
#endif
    !/
    IMPLICIT NONE
    !/
    !/ ------------------------------------------------------------------- /
    !/ Parameter list
    !/
    REAL, INTENT(IN)        :: ASPC(NSPEC), WNDX, WNDY, &
         ZWND, DEPTH, RIB, DAIR, FPI
    REAL, INTENT(OUT)       :: UST, USTD, Z0
    REAL, INTENT(OUT),OPTIONAL :: CHARN
    REAL, INTENT(INOUT)     :: TAUNUX, TAUNUY
    !/
    !/ ------------------------------------------------------------------- /
    !/ Local parameters
    !/
    !-Parameters
    REAL, PARAMETER  :: NU=0.105/10000.0
    !-Commonly used values
    REAL :: UREF, UREFD
    !-Tail
    REAL :: SAT
    REAL :: KMAX, KTAILA, KTAILB, KTAILC
    INTEGER :: KA1, KA2, KA3, NKT
    !-Extended spectrum
    REAL, ALLOCATABLE, DIMENSION(:)   :: WN, DWN, CP, sig2,TAUINTX, TAUINTY
    REAL, ALLOCATABLE, DIMENSION(:,:) :: SPC2
    !-Stress Calculation
    INTEGER :: K, T, ITS
    REAL :: TAUXW, TAUYW, TAUX, TAUY
    REAL :: USTRA, USTRB, USTSM
    REAL :: A1, SCIN
    REAL :: CD, CDF, CDS
    real :: wnd_z, wnd_z_mag, wnd_z_proj, wnd_effect
    ! Stress iteration
    REAL :: B1, B2
    REAL :: USTRI1, USTRF1, USTRI2, USTRF2
    REAL :: USTGRA, SLO
    LOGICAL :: UST_IT_FLG(2)
    !-Z0 iteration
    REAL :: z01,z02
    !-Wind iteration
    real :: wnd_10_x, wnd_10_y, wnd_10_mag, wnd_10_dir
    real :: u35_1, v35_1, u35_2, v35_2, u35_3, v35_3
    REAL :: DIFU10xx, DIFU10yx, DIFU10xy, DIFU10yy
    REAL :: fd_a, fd_b, fd_c, fd_d
    REAL :: DU, DV, UITV, VITV, CH
    REAL :: APAR, DTX(3), DTY(3), DT
    LOGICAL :: WIFLG, WND_IT_FLG
    !-MO stability correction
    LOGICAL :: HEIGHTFLG
    integer :: wi_count, wi
    real :: wnd_ref_al,wnd_ref_ax
    real :: wndpa, wndpax, wndpay, wndpe,wndpex, wndpey
    LOGICAL :: NO_ERR
    LOGICAL :: ITERFLAG
    INTEGER :: ITTOT
    INTEGER :: COUNT
#ifdef W3_S
    INTEGER, SAVE           :: IENT = 0
#endif
    LOGICAL, SAVE           :: FIRST = .TRUE.
#ifdef W3_OMPG
    !$omp threadprivate( FIRST )
#endif
    !/
    !/ ------------------------------------------------------------------- /
    !/
#ifdef W3_S
    CALL STRACE (IENT, 'C3FLD2')
#endif
    !
    ! 0.  Initializations ------------------------------------------------ *
    !
    !     **********************************************************
    !     ***    The initialization routine should include all   ***
    !     *** initialization, including reading data from files. ***
    !     **********************************************************
    !
    IF ( FIRST ) THEN
      CALL INFLD
      FIRST  = .FALSE.
    END IF
    !----------------------------|
    ! Calculate Reference height |
    !  wind magnitude            |
    !----------------------------|
    UREF=SQRT(WNDX**2+WNDY**2)
    UREFD=ATAN2(WNDY,WNDX)
    !----------------------------------------------|
    ! Check if wind height not equal to 10 m       |
    !----------------------------------------------|
    !HeightFLG = (abs(zwnd-10.).GT.0.1) ! True if not 10m
    !----------------------------------------------|
    ! Assume bulk and calculate 10 m wind guess for|
    ! defining tail level                          |
    !----------------------------------------------|
    CALL wnd2z0m(uref,z01)  ! first guess at z0
    wnd_10_mag=uref
    ittot=1
    ! If input wind is not 10m, solve for approx 10 m
    !-------------------------------------------------|
    ! If height != 10 m, then iterate to get 10 m wind|
    ! (assuming neutral -- this is just a guess)      |
    !-------------------------------------------------|
    !IF (HeightFLG) THEN
    !   IterFLAG=.true.
    !   COUNT = 1 !COUNT is now counting iteration over z0
    !   do while(IterFLAG)
    !      wnd_10_mag=UREF*log(10./z01)/log(zwnd/z01)
    !      CALL wnd2z0m(wnd_10_mag,z02)
    !      if ( (abs(z01/z02-1.).GT.0.001) .AND. &
    !           (COUNT.LT.10))THEN
    !         z01 = z02
    !      else
    !         IterFLAG = .false.
    !      endif
    !      COUNT = COUNT + 1
    !   enddo
    !   ITTOT = 3 !extra iterations for 10m wind
    !ELSE
    !   wnd_10_mag = uref
    !   ITTOT = 1 !no iteration needed
    !ENDIF
    if (Tail_Choice.eq.0) then
      SAT=Tail_Level
    elseif (Tail_Choice.eq.1) then
      CALL WND2SAT(wnd_10_mag,SAT)
    endif
    ! now you have the guess at 10 m wind mag. and z01
    !/
    !--------------------------|
    ! Get first guess at ustar |
    !--------------------------|
    USTRA = UREF*kappa/log(zwnd/z01)
    USTD = UREFD
    wnd_10_dir = urefd
    wnd_10_x=wnd_10_mag*cos(wnd_10_dir)
    wnd_10_y=wnd_10_mag*sin(wnd_10_dir)
    !
    ! 1.  Attach Tail ---------------------------------------------------- *
    !
    call sig2wn ( sig(nk),depth,kmax)
    NKT = NK
    DO WHILE ( KMAX .LT. 366. )
      NKT = NKT + 1
      KMAX = ( KMAX * XFR**2 )
    ENDDO
    ALLOCATE( WN(NKT), DWN(NKT), CP(NKT),sig2(nkt), SPC2(NKT,NTH), &
         TAUINTX(NKT),TAUINTY(NKT))
    !|--------------------------------------------------------------------|
    !|----Build Discrete Wavenumbers for defining spectrum on-------------|
    !|--------------------------------------------------------------------|
    DO K = 1, NK
      call sig2wn(sig(k),depth,wn(k))
      CP(K) = sig(k) / WN(K)
      sig2(k) = sig(k)
    ENDDO
    DO K = ( NK + 1 ), ( NKT)
      sig2(k)=sig2(k-1)*XFR
      call sig2wn(sig2(k),depth,wn(k))
      cp(k)=sig2(k)/wn(k)
    ENDDO
    DO K = 2, NKT-1
      DWN(K) = (WN(K+1) - WN(K-1)) / 2.0
    ENDDO
    DWN(1) = ( WN(2)- ( WN(1) / (XFR **2.0) ) ) / 2.0
    DWN(NKT) = ( WN(NKT)*(XFR**2.0) -  WN(NKT-1)) / 2.0
    !|---------------------------------------------------------------------|
    !|---Attach initial tail-----------------------------------------------|
    !|---------------------------------------------------------------------|
    COUNT=0 !Count is now counting step through 1-d spectrum
    DO K=1, NK
      DO T=1, NTH
        COUNT = COUNT + 1
        SPC2(K,T) = ASPC(COUNT)  * SIG(K)
      ENDDO
    ENDDO
    DO K=NK+1, NKT
      DO T=1, NTH
        SPC2(K,T)=SPC2(NK,T)*WN(NK)**3.0/WN(K)**(3.0)
      ENDDO
    ENDDO
    !
    ! 1c. Calculate transitions for new (constant saturation ) tail ------ *
    !
    !-----Wavenumber for beginning of (spectrum level) transition to tail- *
    call sig2wn (FPI*TPI*tail_transition_ratio1,depth,ktaila )
    !-----Wavenumber for end of (spectrum level) transition to tail------- *
    call sig2wn (FPI*TPI*tail_transition_ratio2,depth,ktailb )
    !-----Wavenumber for end of (spectrum direction) transition to tail--- *
    KTAILC= KTAILB * 2.0
    KA1 = 2     ! Do not modify 1st wavenumber bin
    DO WHILE ( ( KTAILA .GE. WN(KA1) ) .AND. (KA1 .LT. NKT-6) )
      KA1 = KA1 + 1
    ENDDO
    KA2 = KA1+2
    DO WHILE ( ( KTAILB .GE. WN(KA2) ) .AND. (KA2 .LT. NKT-4) )
      KA2 = KA2 + 1
    ENDDO
    KA3 = KA2+2
    DO WHILE ( ( KTAILC .GE. WN(KA3)) .AND. (KA3 .LT. NKT-2) )
      KA3 = KA3 + 1
    ENDDO
    CALL APPENDTAIL(SPC2,WN,NKT,KA1,KA2,KA3,atan2(WNDY,WNDX),SAT)
    ! Now the spectrum is set w/ tail level SAT
    !
    ! 2. Enter iteration ------------------------------------------------- *
    !
    ! Add new iteration for wind
    !
    ! Wind perturbations for iteration
    !DT = 1.E-04
    !DTX = (/ 1. , -1. , 0. /)
    !DTY = (/ 0. , 1. , -1. /)
    !/
    HEIGHTFLG=.false.!Not set-up for non-10 m winds
    WIFLG = .TRUE.   !This kicks out when wind iteration complete
    NO_ERR = .TRUE.  !This kicks out when there is an error
    WI_COUNT = 1     !Count is now counting wind iterations
    ! - start of wind iteration (if applicable)
    DO WHILE ( WIFLG .AND. NO_ERR )  !Wind iteration
      !/
      DO WI = 1, ITTOT   !Newton-Raphson solve for derivatives if zwnd not 10 m.
        ! If iterating over 10 m wind need to adjust guesses to get slopes
        IF (HeightFLG) THEN
          WND_10_X = WND_10_X + DTX(WI)*DT
          WND_10_Y = WND_10_Y + DTY(WI)*DT
          wnd_10_mag = sqrt(wnd_10_x**2+wnd_10_y**2)
          wnd_10_dir = atan2(wnd_10_y,wnd_10_x)
        ENDIF
        !
        ! Stress iteration (inside wind iteration solve for stress)
        ITS = 1 !ITS is counting stress iteration
        UST_IT_FLG(1)=.TRUE.
        UST_IT_FLG(2)=.TRUE.
        DO WHILE ((UST_IT_FLG(1) .AND. UST_IT_FLG(2)) .AND. NO_ERR)
          !Get z0 from (guessed) stress and wind magnitude
          z0  = 10. / ( EXP( KAPPA * wnd_10_mag / USTRA ) )
          TAUINTX(1:NKT) = 0.0
          TAUINTY(1:NKT) = 0.0
          DO K = 1, NKT
            !Waves 'feel' wind at height related to wavelength
            wnd_z = MIN( PI / WN(K), 20.0 )
            wnd_z_mag = ( USTRA / KAPPA ) * (LOG(wnd_z/Z0))
            DO T = 1, NTH
              !projected component of wind in wave direction
              wnd_z_proj = wnd_z_mag * COS( wnd_10_dir-TH(T) )
              IF (wnd_z_proj .GT. CP(K)) THEN
                !Waves slower than wind
                A1 = 0.11
              ELSEIF (( wnd_z_proj .GE. 0 ) .AND. ( wnd_z_proj .LE. CP(K) )) THEN
                !Wave faster than wind
                A1 = 0.01
              ELSEIF (wnd_z_proj .LT. 0) THEN
                !Waves opposed to wind
                A1 = 0.1
              ENDIF
              wnd_effect = wnd_z_proj - CP(K)
              SCIN = A1 * wnd_effect * ABS( wnd_effect ) * DAIR / DWAT * &
                   WN(K) / CP(K)
              ! -- Original version assumed g/Cp = sig,(a.k.a in deep water.)
              !   TAUINTX(K) = TAUINTX(K) + SPC2(K,T) * SCIN &
              !        * COS( TH(T) ) / CP(K) * DTH
              !   TAUINTY(K) = TAUINTY(K) + SPC2(K,T) * SCIN &
              !        * SIN( TH(T) ) / CP(K) * DTH

              TAUINTX(K) = TAUINTX(K) + SPC2(K,T) * SCIN &
                   * COS( TH(T) ) *SIG2(K) * DTH
              TAUINTY(K) = TAUINTY(K) + SPC2(K,T) * SCIN &
                   * SIN( TH(T) ) *SIG2(K) * DTH
            ENDDO
          ENDDO
          TAUYW = 0.0
          TAUXW = 0.0
          DO K = 1, NKT
            !  TAUXW = TAUXW + DWAT * GRAV * DWN(K) * TAUINTX(K)
            !  TAUYW = TAUYW + DWAT * GRAV * DWN(K) * TAUINTY(K)
            TAUXW = TAUXW + DWAT * DWN(K) * TAUINTX(K)
            TAUYW = TAUYW + DWAT * DWN(K) * TAUINTY(K)
          ENDDO
          CDF = ( SQRT(TAUXW**2.0+TAUYW**2.0) / DAIR ) / wnd_10_mag**2.0
          !|---------------------------------------------------------------------|
          !|----Solve for the smooth drag coefficient to use as initial guess----|
          !|----for the viscous stress-------------------------------------------|
          !|---------------------------------------------------------------------|
          IF (UREF .LT. 0.01) THEN
            USTSM = 0.0
            IterFLAG = .false.
          ELSE
            Z02 = 0.001
            IterFLAG = .true.
          ENDIF
          COUNT = 1
          ! Finding smooth z0 to get smooth drag
          DO WHILE( (IterFLAG ) .AND. (COUNT .LT. 10) )
            Z01 = Z02
            USTSM = KAPPA * wnd_10_mag / ( LOG( 10. / Z01 ) )
            Z02 = 0.132 * NU / USTSM
            IF (ABS( Z02/Z01-1.0) .LT. 10.0**(-4)) THEN
              IterFLAG = .false.
            ELSE
              IterFLAG = .true.
            ENDIF
            COUNT = COUNT + 1
          ENDDO
          CDS = USTSM**2.0 / wnd_10_mag**2.0
          ! smooth drag adjustment based on full drag
          CDS = CDS / 3.0 * ( 1.0 + 2.0 * CDS / ( CDS + CDF ) )
          !-----Solve for viscous stress from smooth Cd
          TAUNUX = DAIR * CDS * wnd_10_mag**2.0 * COS( wnd_10_dir )
          TAUNUY = DAIR * CDS * wnd_10_mag**2.0 * SIN( wnd_10_dir )
          !-----Sum drag components
          TAUX = TAUNUX + TAUXW
          TAUY = TAUNUY + TAUYW
          !-----Calculate USTAR
          USTRB = SQRT( SQRT( TAUY**2.0 + TAUX**2.0) / DAIR )
          !-----Calculate stress direction
          ustd = atan2(tauy,taux)
          !Checking ustar. ustra=guess. ustrb=found.
          B1 = ( USTRA - USTRB )
          B2 = ( USTRA + USTRB ) / 2.0
          ITS = ITS + 1
          !Check for convergence
          UST_IT_FLG(1)=( ABS(B1*100.0/B2) .GE. 0.01)
          !If not converged after 20 iterations, quit.
          UST_IT_FLG(2)=( ITS .LT. 20 )
          IF ( UST_IT_FLG(1) .AND. UST_IT_FLG(2)) THEN
            ! Toyed with methods for improving iteration.
            ! ultimately this was sufficient.
            ! May be imporved upon in future...
            USTRA = USTRB*.5 + USTRB*.5
          ELSEIF (ABS(B1*100.0/B2) .GE. 5.) THEN
            !After 20 iterations, >5% from converged
            UST_IT_FLG(1) = .FALSE.
            UST_IT_FLG(2) = .FALSE.
            print*,'Attn: Stress not converged for windspeed: ',UREF
            UST = -999.
            NO_ERR = .false.
          ENDIF
        ENDDO
        !IF (HeightFLG) THEN
        !   ! Get along stress wind at top wave boundary layer (10m)
        !   WNDPA=WND_10_mag*COS(WND_10_dir-USTD)
        !   WNDPE=WND_10_mag*SIN(WND_10_dir-USTD)
        !   ! Calculate Cartesian of across wind
        !   WNDPEx=WNDPE*cos(ustd+pi/2.)! add pi/2 since referenced
        !   WNDPEy=WNDPE*sin(ustd+pi/2.)! to right of stress angle
        !   !Approx as neutral inside 10 m (WBL) calculate z0
        !   wnd_ref_al=uref*cos(urefd-ustd)
        !   z0=10. / exp( wnd_10_mag * KAPPA / ustra )
        !   ! Use that z0 to calculate stability
        !   ! Cd to ref height (based on input wind)
        ! Below is subroutine for computing stability effects
        !   call mflux(wnd_ref_al,zwnd,z0,rib,cd)
        ! 2. Get CD with stability
        ! 3. Get New 35-m wind based on calculated stress Cd from MO
        !   WNDPA=ustra/sqrt(cd)
        !   WNDPAX=WNDPA*cos(ustd)
        !   WNDPAY=WNDPA*sin(ustd)
        !   if (wi.eq.3) then
        !      u35_1=WNDPAX+WNDPEX
        !      v35_1=WNDPAY+WNDPEY
        !   elseif (wi.eq.2) then
        !      u35_2=WNDPAX+WNDPEX
        !      v35_2=WNDPAY+WNDPEY
        !   elseif (wi.eq.1) then
        !      u35_3=WNDPAX+WNDPEX
        !      v35_3=WNDPAY+WNDPEY
        !   endif
        !ENDIF
      ENDDO
      !IF (HeightFLG) THEN
      !   DIFU10xx= u35_3-u35_1
      !   DIFU10yx= v35_3-v35_1
      !   DIFU10xy= u35_2-u35_1
      !   DIFU10yy= v35_2-v35_1
      !   fd_a = difu10xx / DT
      !   fd_b = difu10xy / DT
      !   fd_c = difu10yx / DT
      !   fd_d = difu10yy / DT
      !   du = -wndx+u35_1
      !   dv = -wndy+v35_1
      !   uitv= abs(du)
      !   vitv=abs(dv)
      !   ch=sqrt(uitv*uitv+vitv*vitv)
      !   if (ch.gt.10) then
      !      apar=0.5/(fd_a*fd_d-fd_b*fd_c)
      !   else
      !      apar=1.0/(fd_a*fd_d-fd_b*fd_c)
      !   endif

      ! Check for wind convergence
      !   WND_IT_FLG = (((du**2+dv**2)/(wndx**2+wndy**2)).GT.0.001)
      !
      !   IF ( WND_IT_FLG .AND. WI_COUNT.LT.10 ) THEN
      !      ! New guesses
      !      wnd_10_x=wnd_10_x-apar*( FD_D * DU - FD_B * DV )
      !      wnd_10_y=wnd_10_y-apar*( -FD_C * DU +FD_A * DV )
      !   ELSE
      !      wiflg = .FALSE.
      !      IF (WI_COUNT .gt. 10 .AND. &
      !           ((du**2+dv**2)/(wndx**2+wndy**2)).GT.0.05 ) then
      !         print*,'Attn: W3FLD2 Wind error gt 5%'
      !         !print*,'  Wind y/error: ',wndy,dv
      !         !print*,'  Wind x/error: ',wndx,du
      !         NO_ERR = .false.
      !      endif
      !   ENDIF
      !   WI_COUNT = WI_COUNT + 1
      !ELSE
      wiflg=.false. ! If already 10 m wind then complete.
      !ENDIF
    enddo

    UST = USTRB
    USTD = ATAN2(TAUY, TAUX)
    CD = UST**2 / UREF**2
    IF (PRESENT(CHARN)) THEN
      CHARN = 0.01/SQRT(SQRT( TAUNUX**2 + TAUNUY**2 )/(UST**2))
    ENDIF
    IF (.not.((CD .LT. 0.01).AND.(CD .GT. 0.0005)).or. .not.(NO_ERR)) THEN
      !Fail safe to bulk
      print*,'Attn: W3FLD2 failed, using bulk stress'
      print*,'Calculated Wind/Cd: ',UREF,CD,UST
      call wnd2z0m(UREF,Z0)
      UST = UREF * kappa / log(zwnd/z0)
      CD = UST**2/UREF**2
      USTD = UREFD
    ENDIF
    DEALLOCATE( TAUINTY , TAUINTX , &
         SPC2, sig2, CP , DWN , WN )
    !STOP

    !/ End of W3FLD2 ----------------------------------------------------- /
    !/
    RETURN
    !
  END SUBROUTINE W3FLD2

  SUBROUTINE WND2SAT(WND10,SAT)
    !/                  +-----------------------------------+
    !/                  | WAVEWATCH III           NOAA/NCEP |
    !/                  |           B. G. Reichl            |
    !/                  |                        FORTRAN 90 |
    !/                  | Last update :         04-Aug-2016 |
    !/                  +-----------------------------------+
    !/
    !/    15-Jan-2016 : Origination.                        ( version 5.12 )
    !/    05-Aug-2016 : Updated for 2016 HWRF CD/U10 curve  ( J. Meixner   )
    !/
    !  1. Purpose :
    !
    !     Gives level of saturation spectrum to produce
    !         equivalent Cd as in wnd2z0m (for neutral 10m wind)
    !         tuned for method of Donelan et al. 2012
    !
    !  2. Method :
    !
    !  3. Parameters :
    !
    !     Parameter list
    !     ----------------------------------------------------------------
    !Input: WND10 - 10 m neutral wind [m/s]
    !Output: SAT  - Level 1-d saturation spectrum in tail [non-dim]
    !     ----------------------------------------------------------------
    !  4. Subroutines used :
    !
    !      Name      Type  Module   Description
    !     ----------------------------------------------------------------
    !      STRACE    Subr. W3SERVMD Subroutine tracing.
    !     ----------------------------------------------------------------
    !
    !  5. Called by :
    !
    !      Name      Type  Module   Description
    !     ----------------------------------------------------------------
    !      W3FLD2    Subr. W3FLD2MD Corresponding source term.
    !     ----------------------------------------------------------------
    !
    !  6. Error messages :
    !
    !       None.
    !
    !  7. Remarks :
    !
    !  8. Structure :
    !
    !     See source code.
    !
    !  9. Switches :
    !
    !     !/S  Enable subroutine tracing.
    !
    ! 10. Source code :
    !
    !/ ------------------------------------------------------------------- /
#ifdef W3_S
    USE W3SERVMD, ONLY: STRACE
#endif
    !
    IMPLICIT NONE
    REAL, INTENT(IN) :: WND10
    REAL, INTENT(OUT) :: SAT
#ifdef W3_S
    INTEGER, SAVE           :: IENT = 0
    CALL STRACE (IENT, 'WND2SAT')
#endif
    !
    ! ST2, previous HWRF relationship:
    !        SAT =0.000000000000349* WND10**6 +&
    !             -0.000000000250547* WND10**5 +&
    !             0.000000039543565* WND10**4 +&
    !             -0.000002229206185* WND10**3 +&
    !             0.000034922624204* WND10**2 +&
    !             0.000339117617027* WND10**1 +&
    !             0.003521314236550
    !     SAT values based on
    !     HWRF 2016 CD curve, created with  fetch limited cases ST4 physics
    IF (WND10<20) THEN
      SAT = -0.022919753482426e-3* WND10**2 &
           +0.960758623686446e-3* WND10    &
           -0.084461041915030e-3
    ELSEIF (WND10<45) THEN
      SAT = -0.000000006585745* WND10**4 &
           +0.000001058147954* WND10**3 &
           -0.000065829151883* WND10**2 &
           +0.001587028483595* WND10    &
           -0.002857112191889
    ELSE
      SAT = -0.000178498197241* WND10    &
           +0.012706067280674
    ENDIF
    SAT = min(max(SAT,0.002),0.014)

  END SUBROUTINE WND2SAT
  !/ ------------------------------------------------------------------- /
  !/
  !/ ------------------------------------------------------------------- /

  !/
  !/ End of module C3FLD2MD -------------------------------------------- /
  !/
END MODULE W3FLD2MD
