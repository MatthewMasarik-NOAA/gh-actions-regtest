!> @file
!> @brief Diffusion source term.
!>
!> @author S. Zieger
!> @date   20-Dec-2013
!>

#include "w3macros.h"
!/ ------------------------------------------------------------------- /

!>
!> @brief Diffusion source term.
!>
!> @author S. Zieger
!> @date   20-Dec-2013
!>
!> @copyright Copyright 2009-2022 National Weather Service (NWS),
!>       National Oceanic and Atmospheric Administration.  All rights
!>       reserved.  WAVEWATCH III is a trademark of the NWS.
!>       No unauthorized use without permission.
!>
MODULE W3SIS1MD
  !/
  !/                  +-----------------------------------+
  !/                  | WAVEWATCH III           NOAA/NCEP |
  !/                  |           S. Zieger               |
  !/                  |                        FORTRAN 90 |
  !/                  | Last update :         20-Dec-2013 |
  !/                  +-----------------------------------+
  !/
  !/    For updates see W3SID1 documentation.
  !/
  !  1. Purpose :
  !
  !     Diffusion source term.
  !
  !  2. Variables and types :
  !
  !  3. Subroutines and functions :
  !
  !      Name      Type  Scope    Description
  !     ----------------------------------------------------------------
  !      W3SIS1    Subr. Public   Ice scattering term.
  !     ----------------------------------------------------------------
  !
  !  4. Subroutines and functions used :
  !
  !     See subroutine documentation.
  !
  !  5. Remarks :
  !
  !  6. Switches :
  !
  !     See subroutine documentation.
  !
  !  7. Source code :
  !/
  !/ ------------------------------------------------------------------- /
  !/
  PUBLIC :: W3SIS1
  !/
CONTAINS
  !/ ------------------------------------------------------------------- /
  !>
  !> @brief Spectral reflection due to ice.
  !>
  !> @param[in]  A    Action density spectrum (1-D).
  !> @param[in]  ICE  Sea ice concentration.
  !> @param[out] S    Source term (1-D version).
  !>
  !> @author S. Zieger
  !> @date
  !>
  SUBROUTINE W3SIS1 (A, ICE, S)
    !/
    !/                  +-----------------------------------+
    !/                  | WAVEWATCH III           NOAA/NCEP |
    !/                  |           S. Zieger               |
    !/                  |                        FORTRAN 90 |
    !/                  | Last update :         20-Dec-2013 |
    !/                  +-----------------------------------+
    !/
    !/    16-Nov-2012 : Origination.                        ( version 4.14 )
    !/                                                        (S. Zieger)
    !  1. Purpose :
    !     Spectral reflection due to ice.
    !
    !/ ------------------------------------------------------------------- /
    !
    !  2. Method :
    !
    !  3. Parameters :
    !
    !     Parameter list
    !     ----------------------------------------------------------------
    !       A       R.A.  I   Action density spectrum (1-D)
    !       ICE     Real  I   Sea ice concentration.
    !       S       R.A.  O   Source term (1-D version).
    !     ----------------------------------------------------------------
    !
    !  4. Subroutines used :
    !
    !      Name      Type  Module   Description
    !     ----------------------------------------------------------------
    !     ----------------------------------------------------------------
    !
    !  5. Called by :
    !
    !      Name      Type  Module   Description
    !     ----------------------------------------------------------------
    !      W3SRCE    Subr. W3SRCEMD Source term integration.
    !      W3EXPO    Subr.   N/A    ASCII Point output post-processor.
    !      W3EXNC    Subr.   N/A    NetCDF Point output post-processor.
    !      GXEXPO    Subr.   N/A    GrADS point output post-processor.
    !     ----------------------------------------------------------------
    !
    !  6. Error messages :
    !
    !     None.
    !
    !  7. Remarks :
    !
    !     If ice parameter 1 is zero, no calculations are made.
    !
    !  8. Structure :
    !
    !     See source code.
    !
    !  9. Switches :
    !
    !     !/S  Enable subroutine tracing.
    !     !/T   Enable general test output.
    !           2-D print plot of source term.
    !
    ! 10. Source code :
    !
    !/ ------------------------------------------------------------------- /
    USE W3ODATMD, ONLY: NDSE
    USE W3SERVMD, ONLY: EXTCDE
    USE W3GDATMD, ONLY: NK, NTH, NSPEC, SIG, SIG2, DDEN2
    USE W3GDATMD, ONLY: DTMIN, TH, DTH, ECOS, DTMIN
    USE W3GDATMD, ONLY: IS1C1, IS1C2
#ifdef W3_T
    USE W3ODATMD, ONLY: NDST
#endif
#ifdef W3_S
    USE W3SERVMD, ONLY: STRACE
#endif
#ifdef W3_T
    USE W3ARRYMD, ONLY: PRT2DS
#endif
    !
    IMPLICIT NONE
    !/
    !/ ------------------------------------------------------------------- /
    !/ Parameter list
    REAL, INTENT(IN)        :: A(NSPEC), ICE
    REAL, INTENT(OUT)       :: S(NSPEC)
    !/
    !/ ------------------------------------------------------------------- /
    !/ Local parameters
    !/
#ifdef W3_S
    INTEGER, SAVE           :: IENT = 0
#endif
    INTEGER                 :: IK, ITH, ITH2, IS, IS2
    REAL                    :: ALPHA
#ifdef W3_T
    REAL                    :: SOUT(NK,NTH)
#endif
    !/
    !/ ------------------------------------------------------------------- /
    !/
#ifdef W3_S
    CALL STRACE (IENT, 'W3SIS1')
#endif
    !
    ! 0.  Initializations ------------------------------------------------ *
    !
    S     = 0.
#ifdef W3_T
    SOUT  = 0.
#endif
    !
    !     Calculate scattering coefficient (linear transfer function) ---- *
    ALPHA = MAX(0., IS1C1 * ICE + IS1C2)
#ifdef W3_T
    WRITE(NDST,8000) ALPHA
#endif
    !
    IF (ALPHA.GT.0. .AND. ICE.GT.0.) THEN
      ! 1. Calculate the derivative ---------------------------------------- *
      DO IK = 1,NK
        DO ITH = 1,NTH
          IS  = ITH+(IK-1)*NTH
          IF (A(IS).GE.0.) THEN
            S(IS)   = S(IS)  -  ALPHA * A(IS)
            DO ITH2 = 1,NTH
              IS2 = ITH2+(IK-1)*NTH
              IF (IS2.NE.IS) THEN
                S(IS2) = S(IS2)  +  ALPHA * A(IS) / REAL(NTH-1)
              END IF
            END DO
          END IF
        END DO
      END DO
      !
      S = S / DTMIN
      !
#ifdef W3_T
      DO IK = 1, NK
        DO ITH = 1, NTH
          IS  = ITH+(IK-1)*NTH
          SOUT(IK,ITH) = S(IS)
        END DO
      END DO
      CALL PRT2DS (NDST, NK, NK, NTH, SOUT, SIG(1:NK), '  ', 1.,    &
           0.0, 0.001, 'Diag Sir1', ' ', 'NONAME')
#endif
      !
    END IF
    ! Formats
8000 FORMAT (' TEST W3SIS1 : ALPHA :',E10.3)
    !
    !/
    !/ End of W3SIS1 ----------------------------------------------------- /
    !/
  END SUBROUTINE W3SIS1
  !/
  !/ End of module W3SIS1MD -------------------------------------------- /
  !/
END MODULE W3SIS1MD
