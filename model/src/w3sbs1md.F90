!> @file
!> @brief Computes scattering term.
!>
!> @author F. Ardhuin
!> @date   14-Nov-2010
!>

#include "w3macros.h"
!>
!> @brief This module computes a scattering term
!>  based on the theory by Ardhuin and Magne (JFM 2007).
!>
!> @author F. Ardhuin
!> @date   14-Nov-2010
!>
!> @copyright Copyright 2009-2022 National Weather Service (NWS),
!>       National Oceanic and Atmospheric Administration.  All rights
!>       reserved.  WAVEWATCH III is a trademark of the NWS.
!>       No unauthorized use without permission.
!>
!/ ------------------------------------------------------------------- /
MODULE W3SBS1MD
  !/
  !/                  +-----------------------------------+
  !/                  | WAVEWATCH III                SHOM |
  !/                  |            F. Ardhuin             |
  !/                  |                        FORTRAN 90 |
  !/                  | Last update :         14-Nov-2010 |
  !/                  +-----------------------------------+
  !/
  !/    15-Jul-2005 : Origination.                        ( version 3.07 )
  !/    23-Jun-2006 : Formatted for submitting code for   ( version 3.09 )
  !/                  inclusion in WAVEWATCH III.
  !/    10-May-2007 : adapt from version 2.22.SHOM        ( version 3.10.SHOM )
  !/    14-Nov-2010 : include scaling factor and clean up ( version 3.14 )
  !/
  !  1. Purpose :
  !
  !     This module computes a scattering term
  !     based on the theory by Ardhuin and Magne (JFM 2007)
  !
  !  2. Variables and types :
  !
  !      Name      Type  Scope    Description
  !     ----------------------------------------------------------------
  !     ----------------------------------------------------------------
  !
  !  3. Subroutines and functions :
  !
  !      Name      Type  Scope    Description
  !     ----------------------------------------------------------------
  !      W3SBS1    Subr. Public   bottom scattering
  !      INSBS1    Subr. Public   Corresponding initialization routine.
  !     ----------------------------------------------------------------
  !
  !  4. Subroutines and functions used :
  !
  !      Name      Type  Module   Description
  !     ----------------------------------------------------------------
  !      STRACE    Subr. W3SERVMD Subroutine tracing.
  !     ----------------------------------------------------------------
  !
  !  5. Remarks :
  !
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
  !/ Public variables
  !/
  REAL, DIMENSION(:,:), ALLOCATABLE   :: BOTSPEC
  INTEGER, PARAMETER :: NKSCAT = 30                 !number of wavenumbers
  DOUBLE PRECISION  ,DIMENSION(:,:,:) ,  ALLOCATABLE :: SCATMATV !scattering matrices
  DOUBLE PRECISION  ,DIMENSION(:,:,:) ,  ALLOCATABLE :: SCATMATA !original matrix
  DOUBLE PRECISION  ,DIMENSION(:,:)   ,  ALLOCATABLE :: SCATMATD
  CHARACTER(len=10)                   :: botspec_indicator
  INTEGER            :: nkbx, nkby
  REAL               :: dkbx, dkby, kwmin, kwmax
  REAL, PARAMETER    :: scattcutoff=0.
  REAL               :: CURTX, CURTY
  !/
CONTAINS
  !>
  !> @brief Bottom scattering source term.
  !>
  !> @details Without current, goes through a diagonalization of the matrix
  !>  problem  S(f,:) = M(f,:,:)**E(f,:).
  !>  With current, integrates the source term along the resonant locus.

  !> @param[in] A         Action density spectrum (1-D)
  !> @param[in] CG        Group velocities
  !> @param[in] WN        Wavenumbers
  !> @param[in] DEPTH     Mean water depth
  !> @param[in] CX1       Current components at ISEA
  !> @param[in] CY1       Current components at ISEA
  !> @param[out] TAUSCX   Change of wave momentum due to scattering
  !> @param[out] TAUSCY   Change of wave momentum due to scattering
  !> @param[out] S        Source term (1-D version)
  !> @param[out] D        Diagonal term of derivative (1-D version)
  !>
  !> @author F. Ardhuin
  !> @date   23-Jun-2006
  !>
  SUBROUTINE W3SBS1(A, CG, WN, DEPTH, CX1, CY1,      &
       TAUSCX, TAUSCY, S, D)
    !/
    !/                  +-----------------------------------+
    !/                  | WAVEWATCH III           NOAA/NCEP |
    !/                  |            F. Ardhuin             |
    !/                  |                        FORTRAN 90 |
    !/                  | Last update :         23-Jun-2006 |
    !/                  +-----------------------------------+
    !/
    !/    15-Jul-2005 : Origination.                        ( version 3.07 )
    !/    23-Jun-2006 : Formatted for submitting code for   ( version 3.09 )
    !/                  inclusion in WAVEWATCH III.
    !/
    !  1. Purpose :
    !
    !     Bottom scattering source term
    !
    !  2. Method :
    !
    !     Without current, goes through a diagonalization of the matrix
    !     problem  S(f,:) = M(f,:,:)**E(f,:)
    !     With current, integrates the source term along the resonant locus
    !
    !  3. Parameters :
    !
    !     Parameter list
    !     ----------------------------------------------------------------
    !  A         R.A.  I   Action density spectrum (1-D)
    !       CG        R.A.  I   Group velocities.
    !       WN        R.A.  I   Wavenumbers.
    !       DEPTH     Real  I   Mean water depth.
    !       S         R.A.  O   Source term (1-D version).
    !       D         R.A.  O   Diagonal term of derivative (1-D version).
    !       CX1-Y1    R.A.  I   Current components at ISEA.
    !       TAUSCX-Y  R.A.  I   Change of wave momentum due to scattering
    !     ----------------------------------------------------------------
    !
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
    !      W3SRCE    Subr. W3SRCEMD Source term integration.
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
    USE CONSTANTS
    USE W3GDATMD, ONLY: NK, NTH, NSPEC, SIG, DTH, DDEN, &
         ECOS, ESIN, EC2, MAPTH, MAPWN, &
         SIG2, DSII
#ifdef W3_S
    USE W3SERVMD, ONLY: STRACE
#endif
    !/
    !
    IMPLICIT NONE
    !/
    !/ ------------------------------------------------------------------- /
    !/ Parameter list
    !/
    REAL, INTENT(IN)        :: CG(NK), WN(NK), DEPTH
    REAL, INTENT(IN)        :: A(NTH,NK)
    REAL, INTENT(IN)        :: CX1, CY1
    REAL, INTENT(OUT)       :: TAUSCX, TAUSCY
    REAL, INTENT(OUT)       :: S(NSPEC), D(NSPEC)
    !/
    !/ ------------------------------------------------------------------- /
    !/ Local parameters
    !/
    INTEGER         :: ISPEC, IK, NSCUT, ITH, ITH2, i, j,iajust,iajust2
#ifdef W3_S
    INTEGER, SAVE           :: IENT = 0
#endif
    LOGICAL, SAVE   :: FIRST = .TRUE.
    INTEGER         :: MATRICES = 0

    REAL            :: R1, R2, R3

    REAL            :: WN2(NSPEC, NTH), Ka(NSPEC),        &
         Kb(NSPEC, NTH), WNBOT(NSPEC, NTH), &
         B(NSPEC, NTH)
    REAL            :: kbotxi, kbotyi, xbk,   &
         ybk,integral, kbotx, kboty, count,count2

    INTEGER         :: ibk, jbk, ik2
    REAL            ::  SIGP,KU, KPU, CGK, CGPK, WN2i, xk2, Ap, kcutoff, ECC2, &
         variance , integral1,integral1b,integral2, SB(NK,NTH), integral3,&
         ajust,absajust,aa,bb,LNORM,UdotL,KdotKP,MBANDC
    REAL            :: KD, Kfactor, kscaled, kmod , CHECKSUM, ETOT
    REAL            :: SMATRIX(NTH,NTH),SMATRIX2(NTH,NTH)
    DOUBLE PRECISION :: AVECT(NTH)

    CURTX=CX1
    CURTY=CY1

    count=0
    !/
    !/ ------------------------------------------------------------------- /
    !/
#ifdef W3_S
    CALL STRACE (IENT, 'W3SBS1')
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
      CALL INSBS1( 1 )
      FIRST  = .FALSE.
    END IF
    IF (( (ABS(CX1)+ABS(CY1)).EQ.0.).AND.(MATRICES.EQ.0) ) THEN
      kwmin=MAX(MAX(dkbx,dkby),SIG(1)**2/GRAV)
      kwmax=MIN(nkbx*dkbx,nkby*dkby)*0.25
      WRITE(*,*) 'k range:',kwmin,kwmax,SIG(1)**2/GRAV
      CALL INSBS1( 2 )
      MATRICES  = 1
    END IF
    !
    ! 1.  Sets scattering term to zero
    !
    D = 0.
    S = 0.
    TAUSCX=0.
    TAUSCY=0.
    !
    ! 3.  Bottom scattering ================================================== *
    !
    IF ( DEPTH*WN(1) .LE. 6 ) THEN
      !
      ! 3.a Ardhuin and Herbers JFM 2000: no current
      !
      IF ((ABS(CX1)+ABS(CY1).EQ.0.).AND.(MATRICES.EQ.1)) THEN
        DO IK=1,NK
          KD=WN(IK)*DEPTH
          IF ( KD .LE. 6 .AND.WN(IK).LT.kwmax ) THEN
            ! Test on kwmax means that scattering is not computed if interaction goes beyond the shortest resolved
            ! bottom component. This should probably be replaced by a warning...
            Kfactor=(WN(IK)**4)*SIG(IK)*pi*4.             &
                 /(SINH(2*KD)*(2*KD+SINH(2*KD)))
            kscaled=(nkscat-2)*(WN(IK)-kwmin)/(kwmax-kwmin)
            AVECT=DBLE(A(:,IK))
            IF (kscaled.LT.0) THEN
              ibk=0
              kmod=0.
            ELSE
              ibk=INT(kscaled)
              kmod=mod(kscaled,1.0)
            END IF
            S((IK-1)*NTH+1:IK*NTH)                              &
                 =REAL(MATMUL(SCATMATV(IBK,:,:),Kfactor*SCATMATD(IBK,:) &
                 *MATMUL(TRANSPOSE(SCATMATV(IBK,:,:)),AVECT))*(1.-kmod))
            S((IK-1)*NTH+1:IK*NTH)                              &
                 =S((IK-1)*NTH+1:IK*NTH)                           &
                 +REAL(MATMUL(SCATMATV(IBK+1,:,:),Kfactor*SCATMATD(IBK+1,:) &
                 *MATMUL(TRANSPOSE(SCATMATV(IBK+1,:,:)),AVECT))*kmod)
            CHECKSUM=ABS(SUM(S((IK-1)*NTH+1:IK*NTH) ))
            ETOT=SUM(A(:,IK))
            IF (CHECKSUM.GT.0.01*ETOT) WRITE(*,*)         &
                 'Energy not conserved:',IK,DEPTH,CHECKSUM,ETOT
          ELSE
            S((IK-1)*NTH+1:IK*NTH)=0.
          END IF
        END DO
      ELSE
        ! 3.b
        !  Case with current (Ardhuin and Magne JFM 2007)
        ! Compute k' (WN2) from k (WN) and U (CX1, CY1)
        ! using : k'=(Cg+k.U/k)/(Cg+k'.U/k')
        !
        DO ITH2=1, NTH

          DO ISPEC=1, NSPEC

            KU=CX1 * ECOS(MAPTH(ISPEC))+CY1 * ESIN(MAPTH(ISPEC))
            KPU=CX1 * ECOS(ITH2)+  CY1 * ESIN(ITH2)
            CGK=CG(MAPWN(ISPEC))
            IF ((CGK+KPU).LT.0.1*CGK) KPU=-0.9*CGK
            IF ((CGK+KU).LT.0.1*CGK)  KU=-0.9*CG(MAPWN(ISPEC))
            WN2(ISPEC,ITH2)= WN(MAPWN(ISPEC))*(CGK+KU)/(CGK+KPU)
          END DO

        END DO
        !
        ! 3.c Compute the coupling coefficient as a product of two terms
        !
        !   K=0.5*pi k'^2 * M(k,k')^2 / [sig*sig' *(k'*Cg'+k'.U)]
        !                                      (Magne and Ardhuin JFM 2007)
        !
        !   K=Ka(k)*Kb(k,k',theta')
        !
        !   Ka = ...
        !   here Mc is neglected
        !
        DO ISPEC=1, NSPEC
          Ka(ISPEC)= 4*PI*SIG2(ISPEC) * WN(MAPWN(ISPEC))  /    &
               SINH(MIN(2*WN(MAPWN(ISPEC))*DEPTH,20.))

          DO ITH2=1, NTH
            KU=CX1 * ECOS(MAPTH(ISPEC))+CY1 * ESIN(MAPTH(ISPEC))
            KPU=CX1 * ECOS(ITH2)+  CY1 * ESIN(ITH2)
            SIGP=SQRT(GRAV*WN2(ISPEC,ITH2)*TANH(WN2(ISPEC,ITH2)*DEPTH))
            CGPK=SIGP*(0.5+WN2(ISPEC,ITH2)*DEPTH &
                 /SINH(MIN(2*WN2(ISPEC,ITH2)*DEPTH,20.)))/WN2(ISPEC, ITH2)

            Kb(ISPEC, ITH2)= WN2(ISPEC, ITH2)**3      &
                 *EC2(1+ABS(MAPTH(ISPEC)-ITH2)) /        &
                 (                                      &
                 2*WN2(ISPEC, ITH2)*DEPTH +             &
                 SINH(MIN(2*WN2(ISPEC,ITH2)*DEPTH,20.)) &
                 *(1+WN2(ISPEC,ITH2)*KPU*2/SIGP)  &
                 )

            !
            !  Other option for computing also Mc
            !
            !  UdotL=WN(MAPWN(ISPEC))*KU-KPU*WN2(ISPEC,ITH2)
            !  KdotKP=EC(1+ABS(MAPTH(ISPEC)-ITH2))*WN2(ISPEC,ITH2)*WN(MAPWN(ISPEC))
            !  LNORM=sqrt(WN(MAPWN(ISPEC))**2+WN2(ISPEC, ITH2)**2-2*KdotKP)
            !  MBANDC=grav*KdotKP &
            !        /(COSH(MIN(WN2(ISPEC,ITH2)*DEPTH,20.))*COSH(MIN(WN(MAPWN(ISPEC))*DEPTH,20.)
            !        +(UdotL*(SIGP*(WN(MAPWN(ISPEC))**2-KdotKP)+SIG2(ISPEC)*(KdotKP-WN2(ISPEC, ITH2)**2)) &
            !           - UdotL**2*(KdotKP-SIGP*SIG2(ISPEC)*(SIGP*SIG2(ISPEC)+UdotL**2)/GRAV**2)) &
            !           /(LNORM*(UdotL**2/(GRAV*LNORM)-TANH(MIN(LNORM*DEPTH,20.)))*COSH(MIN(LNORM*DEPTH,20.)))
            !  Kb(ISPEC,ITH2)= WN2(ISPEC, ITH2)**2
            !                   /((SIG2(ISPEC)*SIGP*WN2(ISPEC, ITH2)*(CGPK+KPU)) &
            !                  *MBANDC**2
            !
          END DO
        END DO
        !
        ! 3.a Bilinear interpolation of the bottom spectrum BOTSPEC
        !     along the locus -> B(ISPEC,ITH2)
        !
        B(:,:)=0
        DO ISPEC=1, NSPEC
          kcutoff=scattcutoff*WN(MAPWN(ISPEC))
          DO ITH2=1,NTH
            kbotx=WN(MAPWN(ISPEC))*ECOS(MAPTH(ISPEC)) - &
                 WN2(ISPEC, ITH2) * ECOS(ITH2)
            kboty=WN(MAPWN(ISPEC))*ESIN(MAPTH(ISPEC)) - &
                 WN2(ISPEC, ITH2) * ESIN(ITH2)
            !
            ! 3.a.1 test if the bottom wavenumber is larger than the cutoff
            !        otherwise the interaction is set to zero

            IF ((kbotx**2+kboty**2)>(kcutoff**2)) THEN

              kbotxi=REAL(nkbx-MOD(nkbx,2))/2.+1.+kbotx/dkbx   ! The MOD(nkbx,2) is either 1 or 0
              kbotyi=REAL(nkby-MOD(nkby,2))/2.+1.+kboty/dkby   ! k=0 is at ik=(nkbx-1)/2+1 if kkbx is odd

              ibk=MAX(MIN(INT(kbotxi),nkbx-1),1)
              xbk=mod(kbotxi,1.0)
              jbk=MAX(MIN(INT(kbotyi),nkby-1),1)
              ybk=mod(kbotyi,1.0)

              B(ISPEC,ITH2)=(                &
                   (BOTSPEC(ibk,jbk)*(1-ybk)+      &
                   BOTSPEC(ibk,jbk+1)*ybk)*(1-xbk) &
                   +               &
                   (BOTSPEC(ibk+1,jbk)*(1-ybk)+    &
                   BOTSPEC(ibk+1,jbk+1)*ybk)*xbk   &
                   )
            END IF
          END DO
        END DO
        !
        ! 4. compute Sbscat
        ! 4.a linear interpolation of A(k', theta') -> Ap
        !

        !  4.b computation of the source term
        integral2=0.
        integral3=0.
        SMATRIX(:,:)=0.
        DO ISPEC=1, NSPEC
          integral=0
          DO ITH2=1, NTH
            iajust=1
            DO I=2,NK
              if(WN2(ISPEC,ITH2).GE.WN(I)) iajust=I
            END DO
            iajust=MAX(iajust,1)
            iajust2=MIN(iajust+1,NK)
            IF (iajust.EQ.iajust2) THEN
              Ap=A(ITH2,iajust)
            ELSE
              bb=(WN2(ISPEC,ITH2)-WN(iajust))/(WN(iajust2)-WN(iajust))
              aa=(WN(iajust2)-WN2(ISPEC,ITH2))/(WN(iajust2)-WN(iajust))
              Ap=(A(ITH2,iajust)*aa+A(ITH2,iajust2)*bb)
            END IF

            integral=integral + Ka(ISPEC)*Kb(ISPEC, ITH2)*B(ISPEC,ITH2)*               &
                 ( Ap*WN(MAPWN(ISPEC))/WN2(ISPEC,ITH2)- A(MAPTH(ISPEC),MAPWN(ISPEC))) *DTH
            ! the factor WN/WN2 accounts for the fact that N(K) and N(K')
            ! have different Jacobian transforms from kx,ky to k,theta

            integral1=integral1+Kb(ISPEC, ITH2)*B(ISPEC,ITH2)*Ap*WN(MAPWN(ISPEC))/WN2(ISPEC,ITH2)*DTH &
                 *DTH*DSII(MAPWN(ISPEC))/CG(MAPWN(ISPEC))
            integral1b=integral1b+Kb(ISPEC, ITH2)*B(ISPEC,ITH2)*A(MAPTH(ISPEC),MAPWN(ISPEC))*DTH  &
                 *DTH*DSII(MAPWN(ISPEC))/CG(MAPWN(ISPEC))
          END DO
          S(ISPEC)=S(ISPEC)+integral

          integral2=integral2+S(ISPEC)*DTH*DSII(MAPWN(ISPEC))/CG(MAPWN(ISPEC))
          integral3=integral3+ABS(S(ISPEC))*DTH*DSII(MAPWN(ISPEC))/CG(MAPWN(ISPEC))
        END DO
      END IF
#ifdef W3_T
      print*,'BOTTOM SCAT CHECKSUM:',integral2,integral3,integral1,integral1b
#endif

#ifdef W3_T
      DO ITH=1,120
        WRITE(6,'(120G15.7)') SMATRIX(ITH,:)
      END DO
#endif
    END IF

    !/
    !/ End of W3SBS1 ----------------------------------------------------- /
    !/
  END SUBROUTINE W3SBS1
  !/ ------------------------------------------------------------------- /
  !>
  !> @brief Initialization for bottom scattering source term routine.
  !>
  !> @param[in] inistep
  !>
  !> @author F. Ardhuin
  !> @date   23-Jun-2006
  !>

  SUBROUTINE INSBS1( inistep )
    !/
    !/                  +-----------------------------------+
    !/                  | WAVEWATCH III           NOAA/NCEP |
    !/                  |            F. Ardhuin             |
    !/                  |                        FORTRAN 90 |
    !/                  | Last update :         23-Jun-2006 |
    !/                  +-----------------------------------+
    !/
    !/    23-Jun-2006 : Origination.                        ( version 3.09 )
    !/
    !  1. Purpose :
    !
    !     Initialization for bottom scattering source term routine.
    !
    !  2. Method :
    !
    !  3. Parameters :
    !
    !     Parameter list
    !     ----------------------------------------------------------------
    !     ----------------------------------------------------------------
    !
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
    !      W3SBS1    Subr. W3SBS1MD Corresponding source term.
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
    USE W3GDATMD, ONLY: NK, NTH, NSPEC, SIG, DTH, DDEN, ECOS, ESIN
    USE W3SERVMD, ONLY: DIAGONALIZE
#ifdef W3_S
    USE W3SERVMD, ONLY: STRACE
#endif
    !/
    IMPLICIT NONE
    !/
    !/ ------------------------------------------------------------------- /
    !/ Parameter list
    !/
    INTEGER, INTENT(IN)        :: inistep
    !/
    !/ ------------------------------------------------------------------- /
    !/ Local parameters
    !/
#ifdef W3_S
    INTEGER, SAVE           :: IENT = 0
#endif
    INTEGER         :: I, J, K1, K2, IK, JK, NROT
    REAL            :: kbotx, kboty, kcurr, kcutoff, variance
    REAL            :: kbotxi, kbotyi, xk, yk
    DOUBLE PRECISION, ALLOCATABLE,DIMENSION(:,:) :: AMAT, V
    DOUBLE PRECISION, ALLOCATABLE,DIMENSION(:)   :: D
    !/
    !/ ------------------------------------------------------------------- /
    !/
#ifdef W3_S
    CALL STRACE (IENT, 'INSBS1')
#endif
    !
    IF (inistep.EQ.1) THEN
      !
      ! 1.  Reads bottom spectrum
      !
      OPEN(183,FILE= 'bottomspectrum.inp', status='old')
      READ(183,*) nkbx, nkby
      READ(183,*) dkbx, dkby
      WRITE(*,*) 'Bottom spec. dim.:', nkbx, nkby, dkbx, dkby
      ALLOCATE(BOTSPEC(nkbx, nkby))
      DO I=1, nkbx
        READ(183,*) BOTSPEC(I,:)
      END DO
      CLOSE(183)
      variance=0
      DO i=1,nkbx
        DO j=1,nkby
          variance=variance+BOTSPEC(i,j)*dkbx*dkby
        END DO
      END DO
      WRITE(*,*) 'Bottom variance:', variance
      !
    ELSE
      !
      ! 2.  Precomputed the scatering matrices for zero current
      !
      ! The Scattering source term is expressed as a matrix problem for
      ! a list of wavenumbers k0
      ! in the range of wavenumbers used in the model.
      ! i.e. S(k0,theta)=Kfactor*SCATMATA ** TRANSPOSE (E(k0,theta))
      !
      ! in which
      !
      ! Kfactor is a scalar computed in CALCSOURCE as
      !        Kfactor=tailfactor*(Kp(I,J)**4)*2.*pi*FREQ(J)*pi*4./(SINH(HND)*(HND+SINH(HND)))
      !
      ! SCATMATA is a square matrix of size NTH*NTH
      !
      ! S(k0,theta) and E(k0,theta) are the vectors giving the directional source term
      !   and spectrum at a fixed wavenumber
      !
      ALLOCATE(SCATMATA(0:nkscat-1,1:NTH,1:NTH))
      ALLOCATE(AMAT(NTH,NTH))
      DO I=0,nkscat-1
        ! kcurr is the current surface wavenumber for which
        ! the scattering matrices are evaluated
        kcurr=kwmin+I*(kwmax-kwmin)/(nkscat-2)
        kcutoff=scattcutoff*kcurr
        DO K1=1,NTH
          DO K2=1,NTH
            kbotx=-kcurr*(ECOS(K2)-ECOS(K1))
            kboty=-kcurr*(ESIN(K2)-ESIN(K1))
            AMAT(K1,K2)=0.
            ! Tests if the bottom wavenumber is larger than the cutoff
            ! Otherwise the interaction is set to zero
            IF ((kbotx**2+kboty**2) > (kcutoff**2)) THEN
              !WARNING : THERE MAY BE A BUG : spectrum not symmetric when
              ! nkbx is odd !!

              kbotxi=REAL(nkbx)/2.+1.+kbotx/dkbx
              kbotyi=REAL(nkby)/2.+1.+kboty/dkby
              !WRITE(6,*) 'Bottom wavenumber i:',kbotxi,kbotyi
              ik=INT(kbotxi)
              xk=mod(kbotxi,1.0)
              jk=INT(kbotyi)
              yk=mod(kbotyi,1.0)
              IF (ik.GE.nkbx) ik=nkbx-1
              IF (jk.GE.nkby) jk=nkby-1
              IF (ik.LT.1) ik=1
              IF (jk.LT.1) jk=1
              ! Bilinear interpolation of the bottom spectrum
              AMAT(K1,K2)=((BOTSPEC(ik,jk  )  *(1-yk)           &
                   +BOTSPEC(ik,jk+1)  *yk    )*(1-xk)   &
                   +(BOTSPEC(ik+1,jk)  *(1-yk)           &
                   +BOTSPEC(ik+1,jk+1)*yk)    *xk)      &
                   *(ECOS(K1)*ECOS(K2)+ESIN(K1)*ESIN(K2))**2
            END IF
          END DO
          AMAT(K1,K1)=AMAT(K1,K1)-SUM(AMAT(K1,:))
        END DO
        AMAT(:,:)=DTH*(AMAT(:,:)+TRANSPOSE(AMAT(:,:)))*0.5
        !makes sure the matrix is exactly symmetric
        !which should already be the case if the bottom
        ! spectrum is really symmetric
        SCATMATA(I,:,:)=AMAT(:,:)
      END DO
      ALLOCATE(SCATMATD(0:nkscat-1,NTH))
      ALLOCATE(SCATMATV(0:nkscat-1,NTH,NTH))
      ALLOCATE(V(NTH,NTH))
      ALLOCATE(D(NTH))
      DO I=0,nkscat-1
        AMAT(:,:)=SCATMATA(I,:,:)
        !
        !diagonalizes the matrix A
        !D is a vector with the eigenvalues, V is the matrix made of the
        !eigenvectors so that VD2Vt=A  with D2(i,j)=delta(i,j)D(i)
        !and VVt=Id, so that exp(A)=Vexp(D2)Vt
        !
        CALL DIAGONALIZE(AMAT,D,V,nrot)
        SCATMATD(I,:)=D(:)    !eigen values
        SCATMATV(I,:,:)=V(:,:) !eigen vectors
        kcurr=kwmin+I*(kwmax-kwmin)/(nkscat-2)
        WRITE(*,*) 'Scattering matrix diagonalized for k=  ',kcurr,',',I+1,'out of ',nkscat
      END DO
    END IF

    !/
    !/ End of INSBS1 ----------------------------------------------------- /
    !/
  END SUBROUTINE INSBS1
  !/
  !/ End of module INSBS1MD -------------------------------------------- /
  !/
END MODULE W3SBS1MD
