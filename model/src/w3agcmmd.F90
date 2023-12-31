!> @file
!> @brief Contains module used for coupling applications between atmospheric model
!>  and WW3 with OASIS3-MCT.
!>
!> @author J. Pianezze
!> @date   Mar-2021
!>

#include "w3macros.h"
!/ ------------------------------------------------------------------- /
!>
!> @brief Module used for coupling applications between atmospheric model
!>  and WW3 with OASIS3-MCT.
!>
!> @author J. Pianezze
!> @date   Mar-2021
!>
!> @copyright Copyright 2009-2022 National Weather Service (NWS),
!>       National Oceanic and Atmospheric Administration.  All rights
!>       reserved.  WAVEWATCH III is a trademark of the NWS.
!>       No unauthorized use without permission.
!>
MODULE W3AGCMMD
  !/
  !/                  +-----------------------------------+
  !/                  | WAVEWATCH III           NOAA/NCEP |
  !/                  |           J. Pianezze             |
  !/                  |                        FORTRAN 90 |
  !/                  | Last update :            Mar-2021 |
  !/                  +-----------------------------------+
  !/
  !/        Mar-2014 : Origination.                       ( version 4.18 )
  !/                   For upgrades see subroutines.
  !/        Apr-2016 : Add comments (J. Pianezze)         ( version 5.07 )
  !/        Mar-2021 : Add TAUA and RHOA coupling         ( version 7.13 )
  !/
  !/    Copyright 2009-2012 National Weather Service (NWS),
  !/       National Oceanic and Atmospheric Administration.  All rights
  !/       reserved.  WAVEWATCH III is a trademark of the NWS.
  !/       No unauthorized use without permission.
  !/
  !  1. Purpose :
  !
  !     Module used for coupling applications between atmospheric model and WW3 with OASIS3-MCT
  !
  !  2. Variables and types :
  !
  !  3. Subroutines and functions :
  !
  !      Name                   Type   Scope    Description
  !     ----------------------------------------------------------------
  !      SND_FIELDS_TO_ATMOS    Subr.  Public   Send fields to atmos model
  !      RCV_FIELDS_FROM_ATMOS  Subr.  Public   Receive fields from atmos model
  !     ----------------------------------------------------------------
  !
  !  4. Subroutines and functions used :
  !
  !      Name                 Type    Module     Description
  !     ----------------------------------------------------------------
  !      CPL_OASIS_SEND       Subr.   W3OACPMD   Send fields
  !      CPL_OASIS_RECV       Subr.   W3OACPMD   Receive fields
  !     ----------------------------------------------------------------
  !
  !  5. Remarks
  !  6. Switches :
  !  7. Source code :
  !
  !/ ------------------------------------------------------------------- /
  !
  IMPLICIT NONE
  !
  INCLUDE "mpif.h"
  !
  PRIVATE
  !
  ! * Accessibility
  PUBLIC SND_FIELDS_TO_ATMOS
  PUBLIC RCV_FIELDS_FROM_ATMOS
  !
CONTAINS
  !/ ------------------------------------------------------------------- /
  !>
  !> @brief Send coupling fields to atmospheric model.
  !>
  !> @author J. Pianezze
  !> @date   Apr-2016
  !>
  SUBROUTINE SND_FIELDS_TO_ATMOS()
    !/
    !/                  +-----------------------------------+
    !/                  | WAVEWATCH III           NOAA/NCEP |
    !/                  |           J. Pianezze             |
    !/                  |                        FORTRAN 90 |
    !/                  | Last update :            Apr-2016 |
    !/                  +-----------------------------------+
    !/
    !/    Mar-2014 : Origination.                  ( version 4.18 )
    !/    Apr-2016 : Add comments (J. Pianezze)    ( version 5.07 )
    !/
    !  1. Purpose :
    !
    !     Send coupling fields to atmospheric model
    !
    !  2. Method :
    !  3. Parameters :
    !  4. Subroutines used :
    !
    !     Name             Type    Module     Description
    !     -------------------------------------------------------------------
    !     CPL_OASIS_SND    Subr.   W3OACPMD   Send field to atmos/ocean model
    !     -------------------------------------------------------------------
    !
    !  5. Called by :
    !
    !     Name            Type    Module     Description
    !     ------------------------------------------------------------------
    !     W3WAVE          Subr.   W3WAVEMD   Wave model
    !     ------------------------------------------------------------------
    !
    !  6. Error messages :
    !  7. Remarks :
    !  8. Structure :
    !  9. Switches :
    ! 10. Source code :
    !
    !/ ------------------------------------------------------------------- /
    !
    USE W3OACPMD,  ONLY: ID_OASIS_TIME, IL_NB_SND, SND_FLD, CPL_OASIS_SND
    USE W3GDATMD,  ONLY: NSEAL, NSEA
    USE W3ADATMD,  ONLY: CX, CY, CHARN, HS, FP0, TWS
    USE W3ODATMD,  ONLY: UNDEF, NAPROC, IAPROC
    !
    !/ ------------------------------------------------------------------- /
    !/ Local parameters
    !/
    REAL(kind=8), DIMENSION(NSEAL,1) :: RLA_OASIS_SND
    INTEGER                          :: IB_DO
    LOGICAL                          :: LL_ACTION
    REAL(kind=8), DIMENSION(NSEAL)   :: TMP
    INTEGER                          :: JSEA, ISEA
    !
    !----------------------------------------------------------------------
    ! * Executable part
    !
    DO IB_DO = 1, IL_NB_SND
      !
      ! Ocean sea surface current (m.s-1) (u-component)
      ! ---------------------------------------------------------------------
      IF (SND_FLD(IB_DO)%CL_FIELD_NAME == 'WW3_WSSU') THEN
        TMP(1:NSEAL) = 0.0
        DO JSEA=1, NSEAL
          ISEA=IAPROC+(JSEA-1)*NAPROC
          IF(CX(ISEA) /= UNDEF) TMP(JSEA)=CX(ISEA)
        END DO
        RLA_OASIS_SND(:,1) = DBLE(TMP(1:NSEAL))
        CALL CPL_OASIS_SND(IB_DO, ID_OASIS_TIME, RLA_OASIS_SND, LL_ACTION)
      ENDIF
      !
      ! Ocean sea surface current (m.s-1) (v-component)
      ! ---------------------------------------------------------------------
      IF (SND_FLD(IB_DO)%CL_FIELD_NAME == 'WW3_WSSV') THEN
        TMP(1:NSEAL) = 0.0
        DO JSEA=1, NSEAL
          ISEA=IAPROC+(JSEA-1)*NAPROC
          IF(CY(ISEA) /= UNDEF) TMP(JSEA)=CY(ISEA)
        END DO
        RLA_OASIS_SND(:,1) = DBLE(TMP(1:NSEAL))
        CALL CPL_OASIS_SND(IB_DO, ID_OASIS_TIME, RLA_OASIS_SND, LL_ACTION)
      ENDIF
      !
      ! Charnock Coefficient (-)
      ! ---------------------------------------------------------------------
      IF (SND_FLD(IB_DO)%CL_FIELD_NAME == 'WW3_ACHA') THEN
        TMP(1:NSEAL) = 0.0
        WHERE(CHARN(1:NSEAL) /= UNDEF) TMP(1:NSEAL)=CHARN(1:NSEAL)
        RLA_OASIS_SND(:,1) = DBLE(TMP(1:NSEAL))
        CALL CPL_OASIS_SND(IB_DO, ID_OASIS_TIME, RLA_OASIS_SND, LL_ACTION)
      ENDIF
      !
      ! Significant wave height (m)
      ! ---------------------------------------------------------------------
      IF (SND_FLD(IB_DO)%CL_FIELD_NAME == 'WW3__AHS') THEN
        TMP(1:NSEAL) = 0.0
        WHERE(HS(1:NSEAL) /= UNDEF) TMP(1:NSEAL)=HS(1:NSEAL)
        RLA_OASIS_SND(:,1) = DBLE(TMP(1:NSEAL))
        CALL CPL_OASIS_SND(IB_DO, ID_OASIS_TIME, RLA_OASIS_SND, LL_ACTION)
      ENDIF
      !
      ! Peak frequency (s-1)
      ! ---------------------------------------------------------------------
      IF (SND_FLD(IB_DO)%CL_FIELD_NAME == 'WW3___FP') THEN
        TMP(1:NSEAL) = 0.0
        WHERE(FP0(1:NSEAL) /= UNDEF) TMP(1:NSEAL)=FP0(1:NSEAL)
        RLA_OASIS_SND(:,1) = DBLE(TMP(1:NSEAL))
        CALL CPL_OASIS_SND(IB_DO, ID_OASIS_TIME, RLA_OASIS_SND, LL_ACTION)
      ENDIF
      !
      ! Peak period (s)
      ! ---------------------------------------------------------------------
      IF (SND_FLD(IB_DO)%CL_FIELD_NAME == 'WW3___TP') THEN
        TMP(1:NSEAL) = 0.0
        WHERE(FP0(1:NSEAL) /= UNDEF) TMP(1:NSEAL)=1./FP0(1:NSEAL)
        RLA_OASIS_SND(:,1) = DBLE(TMP(1:NSEAL))
        CALL CPL_OASIS_SND(IB_DO, ID_OASIS_TIME, RLA_OASIS_SND, LL_ACTION)
      ENDIF
      !
      ! Wind sea Mean period (s)
      ! ---------------------------------------------------------------------
      IF (SND_FLD(IB_DO)%CL_FIELD_NAME == 'WW3__FWS') THEN
        TMP(1:NSEAL) = 0.0
        WHERE(TWS(1:NSEAL) /= UNDEF) TMP(1:NSEAL)=TWS(1:NSEAL)
        RLA_OASIS_SND(:,1) = DBLE(TMP(1:NSEAL))
        CALL CPL_OASIS_SND(IB_DO, ID_OASIS_TIME, RLA_OASIS_SND, LL_ACTION)
      ENDIF
      !

    ENDDO
    !
    !/ ------------------------------------------------------------------- /
  END SUBROUTINE SND_FIELDS_TO_ATMOS
  !>
  !> @brief Receive coupling fields from atmospheric model.
  !>
  !> @param[in]    ID_LCOMM MPI communicator.
  !> @param[in]    IDFLD    Name of the exchange fields.
  !> @param[inout] FXN      First exchange field.
  !> @param[inout] FYN      Second exchange field.
  !> @param[inout] FAN      Third exchange field.
  !>
  !> @author J. Pianezze
  !> @date   Mar-2021
  !>
  !/ ------------------------------------------------------------------- /
  SUBROUTINE RCV_FIELDS_FROM_ATMOS(ID_LCOMM, IDFLD, FXN, FYN, FAN)
    !/
    !/                  +-----------------------------------+
    !/                  | WAVEWATCH III           NOAA/NCEP |
    !/                  |           J. Pianezze             |
    !/                  |                        FORTRAN 90 |
    !/                  | Last update :            Mar-2021 |
    !/                  +-----------------------------------+
    !/
    !/    Mar-2014 : Origination.                ( version 4.18 )
    !/    Apr-2015 : Modification (M. Accensi)   ( version 5.07 )
    !/    Apr-2016 : Add comments (J. Pianezze)  ( version 5.07 )
    !/    Mar-2021 : Add TAUA and RHOA coupling  ( version 7.13 )
    !/
    !  1. Purpose :
    !
    !     Receive coupling fields from atmospheric model
    !
    !  2. Method :
    !  3. Parameters :
    !
    !     Parameter list
    !     ----------------------------------------------------------------
    !     ID_LCOMM          Char.     I     MPI communicator
    !     IDFLD             Int.      I     Name of the exchange fields
    !     FXN               Int.     I/O    First exchange field
    !     FYN               Int.     I/O    Second exchange field
    !     FAN               Int.     I/O    Third exchange field
    !     ----------------------------------------------------------------
    !
    !  4. Subroutines used :
    !
    !     Name             Type    Module     Description
    !     -------------------------------------------------------------------
    !     CPL_OASIS_RCV    Subr.   W3OACPMD   Receive fields from atmos/ocean model
    !     W3S2XY           Subr.   W3SERVMD   Convert from storage (NSEA) to spatial grid (NX, NY)
    !     -------------------------------------------------------------------
    !
    !  5. Called by :
    !
    !     Name            Type    Module     Description
    !     ------------------------------------------------------------------
    !     W3FLDG          Subr.   W3FLDSMD   Manage input fields of depth,
    !                                        current, wind and ice concentration
    !     ------------------------------------------------------------------
    !
    !  6. Error messages :
    !  7. Remarks :
    !  8. Structure :
    !  9. Switches :
    ! 10. Source code :
    !
    !/ ------------------------------------------------------------------- /
    !
    USE W3OACPMD, ONLY: ID_OASIS_TIME, IL_NB_RCV, RCV_FLD, CPL_OASIS_RCV
    USE W3GDATMD, ONLY: NX, NY, NSEAL, NSEA, MAPSF
    USE W3ODATMD, ONLY: NAPROC, IAPROC
    USE W3SERVMD, ONLY: W3S2XY
    !
    !/ ------------------------------------------------------------------- /
    !/ Parameter list
    !/
    INTEGER, INTENT(IN)              :: ID_LCOMM
    CHARACTER(LEN=3), INTENT(IN)     :: IDFLD
    REAL, INTENT(INOUT)              :: FXN(:,:), FYN(:,:), FAN(:,:)
    !
    !/ ------------------------------------------------------------------- /
    !/ Local parameters
    !/
    LOGICAL                          :: LL_ACTION
    INTEGER                          :: IB_DO, IB_I, IB_J, IL_ERR
    REAL(kind=8), DIMENSION(NSEAL,1) :: RLA_OASIS_RCV
    REAL(kind=8), DIMENSION(NSEAL)   :: TMP
    REAL, DIMENSION(1:NSEA)          :: SND_BUFF,RCV_BUFF
    !
    !----------------------------------------------------------------------
    ! * Executable part
    !
    RLA_OASIS_RCV(:,:) = 0.0
    !
    DO IB_DO = 1, IL_NB_RCV
      IF (IDFLD == 'WND') THEN
        !
        ! Wind speed at 10m (m.s-1) (u-component)
        ! ----------------------------------------------------------------------
        IF (RCV_FLD(IB_DO)%CL_FIELD_NAME == 'WW3__U10') THEN
          CALL CPL_OASIS_RCV(IB_DO, ID_OASIS_TIME, RLA_OASIS_RCV, LL_ACTION)
          IF (LL_ACTION) THEN
            TMP(1:NSEAL) = RLA_OASIS_RCV(1:NSEAL,1)
            SND_BUFF(1:NSEA) = 0.0
            DO IB_I = 1, NSEAL
              IB_J = IAPROC + (IB_I-1)*NAPROC
              SND_BUFF(IB_J) = TMP(IB_I)
            ENDDO
            !
            CALL MPI_ALLREDUCE(SND_BUFF(1:NSEA), &
                 RCV_BUFF(1:NSEA), &
                 NSEA,     &
                 MPI_REAL, &
                 MPI_SUM,  &
                 ID_LCOMM, &
                 IL_ERR)
            !
            ! Convert from storage (NSEA) to spatial grid (NX, NY)
            CALL W3S2XY(NSEA,NSEA,NX,NY,RCV_BUFF(1:NSEA),MAPSF,FXN)
            !
          ENDIF
        ENDIF
        !
        ! Wind speed at 10m (m.s-1) (v-component)
        ! ----------------------------------------------------------------------
        IF (RCV_FLD(IB_DO)%CL_FIELD_NAME == 'WW3__V10') THEN
          CALL CPL_OASIS_RCV(IB_DO, ID_OASIS_TIME, RLA_OASIS_RCV, LL_ACTION)
          IF (LL_ACTION) THEN
            TMP(1:NSEAL) = RLA_OASIS_RCV(1:NSEAL,1)
            SND_BUFF(1:NSEA) = 0.0
            DO IB_I = 1, NSEAL
              IB_J = IAPROC + (IB_I-1)*NAPROC
              SND_BUFF(IB_J) = TMP(IB_I)
            END DO
            !
            CALL MPI_ALLREDUCE(SND_BUFF(1:NSEA),       &
                 RCV_BUFF(1:NSEA),       &
                 NSEA,     &
                 MPI_REAL, &
                 MPI_SUM,  &
                 ID_LCOMM, &
                 IL_ERR)
            !
            ! Convert from storage (NSEA) to spatial grid (NX, NY)
            CALL W3S2XY(NSEA,NSEA,NX,NY,RCV_BUFF(1:NSEA),MAPSF,FYN)
            !
          ENDIF
        ENDIF
        !
      ENDIF
      IF (IDFLD == 'TAU') THEN
        !
        ! Atmospheric momentum (Pa) (u-component)
        ! ----------------------------------------------------------------------
        IF (RCV_FLD(IB_DO)%CL_FIELD_NAME == 'WW3_UTAU') THEN
          CALL CPL_OASIS_RCV(IB_DO, ID_OASIS_TIME, RLA_OASIS_RCV, LL_ACTION)
          IF (LL_ACTION) THEN
            TMP(1:NSEAL) = RLA_OASIS_RCV(1:NSEAL,1)
            SND_BUFF(1:NSEA) = 0.0
            DO IB_I = 1, NSEAL
              IB_J = IAPROC + (IB_I-1)*NAPROC
              SND_BUFF(IB_J) = TMP(IB_I)
            ENDDO
            !
            CALL MPI_ALLREDUCE(SND_BUFF(1:NSEA), &
                 RCV_BUFF(1:NSEA), &
                 NSEA,     &
                 MPI_REAL, &
                 MPI_SUM,  &
                 ID_LCOMM, &
                 IL_ERR)
            !
            ! Convert from storage (NSEA) to spatial grid (NX, NY)
            CALL W3S2XY(NSEA,NSEA,NX,NY,RCV_BUFF(1:NSEA),MAPSF,FXN)
            !
          ENDIF
        ENDIF
        !
        ! Atmospheric momentum (Pa) (v-component)
        ! ----------------------------------------------------------------------
        IF (RCV_FLD(IB_DO)%CL_FIELD_NAME == 'WW3_VTAU') THEN
          CALL CPL_OASIS_RCV(IB_DO, ID_OASIS_TIME, RLA_OASIS_RCV, LL_ACTION)
          IF (LL_ACTION) THEN
            TMP(1:NSEAL) = RLA_OASIS_RCV(1:NSEAL,1)
            SND_BUFF(1:NSEA) = 0.0
            DO IB_I = 1, NSEAL
              IB_J = IAPROC + (IB_I-1)*NAPROC
              SND_BUFF(IB_J) = TMP(IB_I)
            END DO
            !
            CALL MPI_ALLREDUCE(SND_BUFF(1:NSEA),       &
                 RCV_BUFF(1:NSEA),       &
                 NSEA,     &
                 MPI_REAL, &
                 MPI_SUM,  &
                 ID_LCOMM, &
                 IL_ERR)
            !
            ! Convert from storage (NSEA) to spatial grid (NX, NY)
            CALL W3S2XY(NSEA,NSEA,NX,NY,RCV_BUFF(1:NSEA),MAPSF,FYN)
            !
          ENDIF
        ENDIF
        !
      ENDIF
      IF (IDFLD == 'RHO') THEN
        !
        ! Air density (kg.m-3)
        ! ----------------------------------------------------------------------
        IF (RCV_FLD(IB_DO)%CL_FIELD_NAME == 'WW3_RHOA') THEN
          CALL CPL_OASIS_RCV(IB_DO, ID_OASIS_TIME, RLA_OASIS_RCV, LL_ACTION)
          IF (LL_ACTION) THEN
            TMP(1:NSEAL) = RLA_OASIS_RCV(1:NSEAL,1)
            SND_BUFF(1:NSEA) = 0.0
            DO IB_I = 1, NSEAL
              IB_J = IAPROC + (IB_I-1)*NAPROC
              SND_BUFF(IB_J) = TMP(IB_I)
            ENDDO
            !
            CALL MPI_ALLREDUCE(SND_BUFF(1:NSEA), &
                 RCV_BUFF(1:NSEA), &
                 NSEA,     &
                 MPI_REAL, &
                 MPI_SUM,  &
                 ID_LCOMM, &
                 IL_ERR)
            !
            ! Convert from storage (NSEA) to spatial grid (NX, NY)
            CALL W3S2XY(NSEA,NSEA,NX,NY,RCV_BUFF(1:NSEA),MAPSF,FAN)
            !
          ENDIF
        ENDIF
      ENDIF
    ENDDO
    !/ ------------------------------------------------------------------- /
  END SUBROUTINE RCV_FIELDS_FROM_ATMOS
  !/ ------------------------------------------------------------------- /
  !/
END MODULE W3AGCMMD
!/
!/ ------------------------------------------------------------------- /
