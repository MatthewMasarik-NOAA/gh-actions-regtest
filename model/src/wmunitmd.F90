!> @file
!> @brief Contains module WMUNITMD.
!>
!> @author H. L. Tolman @date 29-May-2009
!>

#include "w3macros.h"
!/ ------------------------------------------------------------------- /

!>
!> @brief Dynamic assignement of unit numbers for the multi-grid wave
!>  model.
!>
!> @details Allowed range of unit numbers is set in parameter statements.
!>
!> @author H. L. Tolman  @date 29-May-2009
!>
MODULE WMUNITMD
  !/
  !/                  +-----------------------------------+
  !/                  | WAVEWATCH III           NOAA/NCEP |
  !/                  |           H. L. Tolman            |
  !/                  |                        FORTRAN 90 |
  !/                  | Last update :         29-May-2009 |
  !/                  +-----------------------------------+
  !/
  !/    29-Mar-2005 : Origination.                        ( version 3.07 )
  !/    29-May-2009 : Preparing distribution version.     ( version 3.14 )
  !/
  !/    Copyright 2009 National Weather Service (NWS),
  !/       National Oceanic and Atmospheric Administration.  All rights
  !/       reserved.  WAVEWATCH III is a trademark of the NWS.
  !/       No unauthorized use without permission.
  !/
  !  1. Purpose :
  !
  !     Dynamic assignement of unit numbers for the multi-grid wave
  !     model.
  !
  !     Allowed range of unit numbers is set in parameter statements.
  !
  !  2. Variables and types :
  !
  !      Name      Type  Scope    Description
  !     ----------------------------------------------------------------
  !      UNITLW    I.P.  Private  Lowest unit number.
  !      UNITHG    I.P.  Private  Highest unit number.
  !      INPLOW, INPHGH, OUTLOW, OUTHGH, SCRLOW, SCRHGH
  !                I.P.  Private  Low and high for input, output and
  !                               scratch files.
  !      FLINIT    Log.  Private  Flag for intialization.
  !
  !      U_USED    L.A.  Private  Flag for use/assignement.
  !      U_TYPE    C.A.  Private  Type of unit.
  !                                'RES' : Reserved.
  !                                'INP' : Input file.
  !                                'OUT' : Output file.
  !                                'SCR' : Scratch file.
  !      U_NAME    C.A.  Private  File name of unit.
  !      U_DESC    C.A.  Private  Decription of file.
  !     ----------------------------------------------------------------
  !
  !  3. Subroutines and functions :
  !
  !      Name      Type  Scope    Description
  !     ----------------------------------------------------------------
  !      WMUINI    Subr. Public   Initialize data structures.
  !      WMUDMP    Subr. Public   Dump contents of data structures.
  !      WMUSET    Subr. Public   Put data directly in structure.
  !      WMUGET    Subr. Public   Get a unit number.
  !      WMUINQ    Subr. Public   Update ansilary info automatically.
  !     ----------------------------------------------------------------
  !
  !  4. Subroutines and functions used :
  !
  !      Name      Type  Module   Description
  !     ----------------------------------------------------------------
  !      STRACE    Subr. W3SERVMD Subroutine tracing.
  !      EXTCDE    Subr.   Id.    Program abort.
  !     ----------------------------------------------------------------
  !
  !  5. Remarks :
  !
  !     - All parameters are private. Dump data using WMUDMP routine.
  !
  !  6. Switches :
  !
  !     !/S    Enable subroutine tracing.
  !     !/T    Enable test output
  !
  !  7. Source code :
  !
  !/ ------------------------------------------------------------------- /
  PUBLIC
  !/
  !/ Define acceptable ranges of unit numbers
  !/
  INTEGER, PARAMETER, PRIVATE   :: UNITLW =   1          !< UNITLW
  INTEGER, PARAMETER, PRIVATE   :: UNITHG = 120          !< UNITHG
  INTEGER, PARAMETER, PRIVATE   :: INPLOW =  10          !< INPLOW
  INTEGER, PARAMETER, PRIVATE   :: INPHGH =  49          !< INPHGH
  INTEGER, PARAMETER, PRIVATE   :: OUTLOW =  50          !< OUTLOW
  INTEGER, PARAMETER, PRIVATE   :: OUTHGH =  98          !< OUTHGH
  INTEGER, PARAMETER, PRIVATE   :: SCRLOW =  99          !< SCRLOW
  INTEGER, PARAMETER, PRIVATE   :: SCRHGH = 100          !< SCRHGH
  !
  LOGICAL,            PRIVATE   :: FLINIT = .FALSE.      !< FLINIT

  LOGICAL,            PRIVATE, ALLOCATABLE :: U_USED(:)  !< U_USED
  CHARACTER(LEN= 3),  PRIVATE, ALLOCATABLE :: U_TYPE(:)  !< U_TYPE
  CHARACTER(LEN=30),  PRIVATE, ALLOCATABLE :: U_NAME(:)  !< U_NAME
  CHARACTER(LEN=30),  PRIVATE, ALLOCATABLE :: U_DESC(:)  !< U_DESC
  !/
CONTAINS
  !/ ------------------------------------------------------------------- /
  !>
  !> @brief Allocate and initialize arrays of module.
  !>
  !> @details Allocate and test parameter setting.
  !>
  !> @param[in] NDSE Unit number for error output.
  !> @param[in] NDST Unit number for test output.
  !> @author H. L. Tolman @date 25-Mar-2005
  !>
  SUBROUTINE WMUINI ( NDSE, NDST )
    !/
    !/                  +-----------------------------------+
    !/                  | WAVEWATCH III           NOAA/NCEP |
    !/                  |           H. L. Tolman            |
    !/                  |                        FORTRAN 90 |
    !/                  | Last update :         25-Mar-2005 !
    !/                  +-----------------------------------+
    !/
    !/    25-Mar-2005 : Origination.                        ( version 3.07 )
    !/
    !  1. Purpose :
    !
    !     Allocate and initialize arrays of module.
    !
    !  2. Method :
    !
    !     Allocate and test parameter setting.
    !
    !  3. Parameters :
    !
    !     Parameter list
    !     ----------------------------------------------------------------
    !       NDSE    Int.   I   Unit number for error output.
    !       NDST    Int.   I   Unit number for test output.
    !     ----------------------------------------------------------------
    !
    !  4. Subroutines used :
    !
    !      Name      Type  Module   Description
    !     ----------------------------------------------------------------
    !      STRACE    Subr. W3SERVMD Subroutine tracing.
    !      EXTCDE    Subr.   Id.    Program abort.
    !     ----------------------------------------------------------------
    !
    !  5. Called by :
    !
    !  6. Error messages :
    !
    !     See source code.
    !
    !  7. Remarks :
    !
    !  8. Structure :
    !
    !     See source code.
    !
    !  9. Switches :
    !
    !     !/S    Enable subroutine tracing.
    !     !/T    Enable test output
    !
    ! 10. Source code :
    !
    !/ ------------------------------------------------------------------- /
    USE W3SERVMD, ONLY: EXTCDE
#ifdef W3_S
    USE W3SERVMD, ONLY: STRACE
#endif
    !
    IMPLICIT NONE
    !/
    !/ ------------------------------------------------------------------- /
    !/ Parameter list
    !/
    INTEGER, INTENT(IN)     :: NDSE, NDST
    !/
    !/ ------------------------------------------------------------------- /
    !/ Local parameters
    !/
    INTEGER                 :: J, I1, IN, I
#ifdef W3_S
    INTEGER, SAVE           :: IENT = 0
#endif
    CHARACTER(LEN=3)        :: STRING
    !/
#ifdef W3_S
    CALL STRACE (IENT, 'WMUINI')
#endif
    !
    ! -------------------------------------------------------------------- /
    ! 1.  Test parameter settings
    !
#ifdef W3_T
    WRITE (NDST,9000)
#endif
    !
    IF ( UNITLW .GE. UNITHG ) THEN
      WRITE (NDSE,1000) UNITLW, UNITHG
      CALL EXTCDE ( 1000 )
    END IF
    !
    IF ( UNITLW .GT. INPLOW .OR.                                    &
         UNITLW .GT. OUTLOW .OR.                                    &
         UNITLW .GT. SCRLOW ) THEN
      WRITE (NDSE,1001) UNITLW, INPLOW, OUTLOW, SCRLOW
      CALL EXTCDE ( 1001 )
    END IF
    !
    IF ( UNITHG .LT. INPHGH .OR.                                    &
         UNITHG .LT. OUTHGH .OR.                                    &
         UNITHG .LT. SCRHGH ) THEN
      WRITE (NDSE,1002) UNITHG, INPHGH, OUTHGH, SCRHGH
      CALL EXTCDE ( 1002 )
    END IF
    !
    IF ( FLINIT ) THEN
      WRITE (NDSE,1003)
      CALL EXTCDE ( 1003 )
    END IF
    !
    ! -------------------------------------------------------------------- /
    ! 1.  Allocate and initialize arrays
    !
#ifdef W3_T
    WRITE (NDST,9010) UNITLW, UNITHG
#endif
    !
    ALLOCATE ( U_USED(UNITLW:UNITHG) , U_TYPE(UNITLW:UNITHG) ,      &
         U_NAME(UNITLW:UNITHG) , U_DESC(UNITLW:UNITHG) )
    !
    U_USED = .FALSE.
    U_TYPE = 'RES'
    U_NAME = 'unknown'
    U_DESC = 'unknown'
    !
    ! -------------------------------------------------------------------- /
    ! 2.  Designate file types
    !
#ifdef W3_T
    WRITE (NDST,9020)
#endif
    !
    DO J=1, 3
      !
      SELECT CASE(J)
      CASE(1)
        STRING = 'INP'
        I1     = INPLOW
        IN     = INPHGH
      CASE(2)
        STRING = 'OUT'
        I1     = OUTLOW
        IN     = OUTHGH
      CASE DEFAULT
        STRING = 'SCR'
        I1     = SCRLOW
        IN     = SCRHGH
      END SELECT
      !
      DO I=I1, IN
        IF ( U_TYPE(I) .NE. 'RES' ) THEN
          WRITE (NDSE,1020) I, U_TYPE(I)
        END IF
        U_TYPE(I) = STRING
      END DO
    END DO
    !
    ! -------------------------------------------------------------------- /
    ! 3.  Set flags
    !
#ifdef W3_T
    WRITE (NDST,9030)
#endif
    !
    FLINIT = .TRUE.
    !
    ! -------------------------------------------------------------------- /
    ! 4.  Test output
    !
#ifdef W3_T
    WRITE (NDST,9040)
    DO I=UNITLW, UNITHG
      WRITE (NDST,9041) I,U_USED(I),U_TYPE(I),U_NAME(I),U_DESC(I)
    END DO
#endif
    !
    RETURN
    !
    ! Formats
    !
1000 FORMAT (/' *** ERROR WMUINI: ILLEGAL UNIT RANGE ***'/           &
         '                   LOW - HIGH : ',2I10/)
1001 FORMAT (/' *** ERROR WMUINI: ILLEGAL LOWER LIMITS ***'/         &
         '                   ',4I10/)
1002 FORMAT (/' *** ERROR WMUINI: ILLEGAL HIGHER LIMITS ***'/        &
         '                   ',4I10/)
1003 FORMAT (/' *** ERROR WMUINI: DATA ALREADY INITIALIZED ***'/)
1020 FORMAT (/' *** WARNING WMUINI: UNIT',I4,' ALREADY ASSIGNED [',  &
         A,'] ***')
    !
#ifdef W3_T
9000 FORMAT ( ' TEST WMUNINI: STARTING ROUTINE')
9010 FORMAT ( ' TEST WMUNINI: ALLOCATING ARRAYS ',2I6)
9020 FORMAT ( ' TEST WMUNINI: INITALIZING ARRAYS')
9030 FORMAT ( ' TEST WMUNINI: SETTING FLAGS')
9040 FORMAT ( ' TEST WMUNINI: DATA STRUCTURE AFTER INITIALIZATION')
9041 FORMAT ( 5X,I4,L4,3(2X,A))
#endif
    !/
    !/ End of WMUINI ----------------------------------------------------- /
    !/
  END SUBROUTINE WMUINI
  !/ ------------------------------------------------------------------- /
  !>
  !> @brief Display assigned unit number information from private data base.
  !>
  !> @param[in] NDS Unit number for output.
  !> @param[in] IREQ Request identifier.
  !>
  !> @author H. L. Tolman @date 25-Mar-2005
  !>

  SUBROUTINE WMUDMP ( NDS, IREQ )
    !/
    !/                  +-----------------------------------+
    !/                  | WAVEWATCH III           NOAA/NCEP |
    !/                  |           H. L. Tolman            |
    !/                  |                        FORTRAN 90 |
    !/                  | Last update :         25-Mar-2005 !
    !/                  +-----------------------------------+
    !/
    !/    25-Mar-2005 : Origination.                        ( version 3.07 )
    !/
    !  1. Purpose :
    !
    !     Display assigned unit number information from private data base.
    !
    !  2. Method :
    !
    !  3. Parameters :
    !
    !     Parameter list
    !     ----------------------------------------------------------------
    !       NDS     Int.   I   Unit number for output.
    !       IREQ    Int.   I   Request identifier.
    !                           < 0 : Dump all data.
    !                            0  : Dump assigned units only.
    !                           > 0 : Dump this unit only.
    !     ----------------------------------------------------------------
    !
    !  4. Subroutines used :
    !
    !      Name      Type  Module   Description
    !     ----------------------------------------------------------------
    !      STRACE    Subr. W3SERVMD Subroutine tracing.
    !      EXTCDE    Subr.   Id.    Program abort.
    !     ----------------------------------------------------------------
    !
    !  5. Called by :
    !
    !  6. Error messages :
    !
    !  7. Remarks :
    !
    !  8. Structure :
    !
    !  9. Switches :
    !
    !     !/S    Enable subroutine tracing.
    !     !/T    Enable test output
    !
    ! 10. Source code :
    !
    !/ ------------------------------------------------------------------- /
    USE W3SERVMD, ONLY: EXTCDE
#ifdef W3_S
    USE W3SERVMD, ONLY: STRACE
#endif
    !
    IMPLICIT NONE
    !/
    !/ ------------------------------------------------------------------- /
    !/ Parameter list
    !/
    INTEGER, INTENT(IN)     :: NDS, IREQ
    !/
    !/ ------------------------------------------------------------------- /
    !/ Local parameters
    !/
    INTEGER                 :: I
#ifdef W3_S
    INTEGER, SAVE           :: IENT = 0
#endif
    !/
#ifdef W3_S
    CALL STRACE (IENT, 'WMUDMP')
#endif
    !
    ! -------------------------------------------------------------------- /
    ! 1.  Test request and intialization
    !
    IF ( .NOT. FLINIT ) THEN
      WRITE (NDS,1000)
      CALL EXTCDE ( 1000 )
    END IF
    !
    IF ( IREQ.GT.0 .AND. ( IREQ.LT.UNITLW .OR. IREQ.GT.UNITHG) ) THEN
      WRITE (NDS,1001) IREQ, UNITLW, UNITHG
      CALL EXTCDE ( 1001 )
    END IF
    !
    ! -------------------------------------------------------------------- /
    ! 2.  Single unit request
    !
    IF ( IREQ .GT. 0 ) THEN
      WRITE (NDS,920) IREQ, U_USED(IREQ), U_TYPE(IREQ),           &
           U_NAME(IREQ), U_DESC(IREQ)
      !
      ! -------------------------------------------------------------------- /
      ! 3.  Multiple unit request
      !
    ELSE
      !
      IF ( IREQ .LT. 0 ) THEN
        WRITE (NDS,930)
      ELSE
        WRITE (NDS,931)
      END IF
      !
      DO I=UNITLW, UNITHG
        IF ( IREQ.LT.0 .OR. U_USED(I) )                           &
             WRITE (NDS,932) I, U_USED(I), U_TYPE(I),         &
             U_NAME(I), U_DESC(I)
      END DO
      WRITE (NDS,*)
      !
    END IF
    !
    RETURN
    !
    ! Formats
    !
920 FORMAT (/' WMUDMP: Unit number : ',I6/                          &
         '         Assigned    : ',L6/                          &
         '         Type        : ',A/                           &
         '         Name        : ',A/                           &
         '         Description : ',A/)
    !
930 FORMAT (/' WMUDMP: Unit information '//                         &
         '    Nr Flg Type  Name                  Description '/ &
         '  -------------------------------------------------', &
         '---------------------')
931 FORMAT (/' WMUDMP: Unit information (assigned only)'//          &
         '    Nr Flg Type  Name                  Description '/ &
         '  -------------------------------------------------', &
         '---------------------')
932 FORMAT ( 2X,I4,L4,2X,A3,2X,A20,2X,A)
    !
1000 FORMAT (/' *** ERROR WMUDMP: DATA STRUCTURE READY ***'/         &
         /'                   RUN WMUINI FIRST '/)
1001 FORMAT (/' *** ERROR WMUDMP: UNIT NUMBER OUT OF RANGE ***'      &
         /'                   REQ/RANG :',3I6/)
    !/
    !/ End of WMUDMP ----------------------------------------------------- /
    !/
  END SUBROUTINE WMUDMP
  !/ ------------------------------------------------------------------- /
  !>
  !> @brief Directly set information for a unit number in the data structure.
  !>
  !> @param[in] NDSE Unit number for error output.
  !> @param[in] NDST Unit number for test output.
  !> @param[in] NDS Unit number to be assigned.
  !> @param[in] FLAG Flag for assigning unit.
  !> @param[in] TYPE Type identifier to be used.
  !> @param[in] NAME Name of file.
  !> @param[in] DESC Description of file.
  !>
  !> @author H. L. Tolman @date 25-Mar-2005
  !>
  SUBROUTINE WMUSET ( NDSE, NDST, NDS, FLAG, TYPE, NAME, DESC )
    !/
    !/                  +-----------------------------------+
    !/                  | WAVEWATCH III           NOAA/NCEP |
    !/                  |           H. L. Tolman            |
    !/                  |                        FORTRAN 90 |
    !/                  | Last update :         25-Mar-2005 !
    !/                  +-----------------------------------+
    !/
    !/    25-Mar-2005 : Origination.                        ( version 3.07 )
    !/
    !  1. Purpose :
    !
    !     Directly set information for a unit number in the data structure.
    !
    !  2. Method :
    !
    !  3. Parameters :
    !
    !     Parameter list
    !     ----------------------------------------------------------------
    !       NDSE    Int.   I   Unit number for error output.
    !       NDST    Int.   I   Unit number for test output.
    !       NDS     Int.   I   Unit number to be assigned.
    !       FLAG    Log.   I   Flag for assigning unit.
    !       TYPE    C*3    I   Type identifier to be used.
    !       NAME    C*     I   Name of file.
    !       DESC    C*     I   Description of file.
    !     ----------------------------------------------------------------
    !
    !  4. Subroutines used :
    !
    !      Name      Type  Module   Description
    !     ----------------------------------------------------------------
    !      STRACE    Sur.  W3SERVMD Subroutine tracing.
    !      EXCTDE    Sur.    Id.    Program abort.
    !     ----------------------------------------------------------------
    !
    !  5. Called by :
    !
    !  6. Error messages :
    !
    !  7. Remarks :
    !
    !  8. Structure :
    !
    !  9. Switches :
    !
    !     !/S    Enable subroutine tracing.
    !     !/T    Enable test output
    !
    ! 10. Source code :
    !
    !/ ------------------------------------------------------------------- /
    USE W3SERVMD, ONLY: EXTCDE
#ifdef W3_S
    USE W3SERVMD, ONLY: STRACE
#endif
    !
    IMPLICIT NONE
    !/
    !/ ------------------------------------------------------------------- /
    !/ Parameter list
    !/
    INTEGER, INTENT(IN)     :: NDSE, NDST, NDS
    LOGICAL, INTENT(IN)     :: FLAG
    CHARACTER(LEN=3), INTENT(IN), OPTIONAL ::                       &
         TYPE
    CHARACTER*(*), INTENT(IN), OPTIONAL ::                          &
         NAME, DESC
    !/
    !/ ------------------------------------------------------------------- /
    !/ Local parameters
    !/
#ifdef W3_S
    INTEGER, SAVE           :: IENT = 0
#endif
    !/
#ifdef W3_S
    CALL STRACE (IENT, 'WMUSET')
#endif
    !
    ! -------------------------------------------------------------------- /
    ! 1.  Test input
    !
    IF ( .NOT. FLINIT ) THEN
      WRITE (NDSE,1000)
      CALL EXTCDE ( 1000 )
    END IF
    !
    IF ( NDS.LT.UNITLW .OR. NDS.GT.UNITHG ) THEN
      WRITE (NDSE,1001) NDS, UNITLW, UNITHG
      CALL EXTCDE ( 1001 )
    END IF
    !
#ifdef W3_T
    WRITE (NDST,9000) NDS, U_USED(NDS), U_TYPE(NDS),             &
         U_NAME(NDS), U_DESC(NDS)
#endif
    !
    ! -------------------------------------------------------------------- /
    ! 2.  Set data
    ! 2.a Flag
    !
    U_USED(NDS) = FLAG
    !
    ! 2.b Type
    !
    IF ( PRESENT(TYPE) ) U_TYPE(NDS) = TYPE
    !
    ! 2.c Name
    !
    IF ( PRESENT(NAME) ) THEN
      U_NAME(NDS) = NAME
    ELSE IF ( .NOT. FLAG ) THEN
      U_NAME(NDS) = 'unknown'
    END IF
    !
    ! 2.d Description
    !
    IF ( PRESENT(DESC) ) THEN
      U_DESC(NDS) = DESC
    ELSE IF ( .NOT. FLAG ) THEN
      U_DESC(NDS) = 'unknown'
    END IF
    !
#ifdef W3_T
    WRITE (NDST,9001) NDS, U_USED(NDS), U_TYPE(NDS),             &
         U_NAME(NDS), U_DESC(NDS)
#endif
    !
    RETURN
    !
    ! Formats
    !
1000 FORMAT (/' *** ERROR WMUSET: INITIALIZE FIRST !!! ***')
1001 FORMAT (/' *** ERROR WMUSET: UNIT NUMBER OUT OF RANGE ***'      &
         /'                   REQ/RANG :',3I6/)
    !
#ifdef W3_T
9000 FORMAT ( ' TEST WMUSET: UNIT ',I4', ON SUBROUTINE ENTRY :'/  &
         '              FLAG : ',L4/                         &
         '              TYPE : ',A/                          &
         '              NAME : ',A/                          &
         '              DESC : ' A)
9001 FORMAT ( ' TEST WMUSET: UNIT ',I4', ON SUBROUTINE EXIT :'/   &
         '              FLAG : ',L4/                         &
         '              TYPE : ',A/                          &
         '              NAME : ',A/                          &
         '              DESC : ' A)
#endif
    !/
    !/ End of WMUSET ----------------------------------------------------- /
    !/
  END SUBROUTINE WMUSET
  !/ ------------------------------------------------------------------- /
  !>
  !> @brief Find a free unit number for a given file type.
  !>
  !> @details Search the data base.
  !>
  !> @param[in] NDSE Unit number for error output.
  !> @param[in] NDST Unit number for test output.
  !> @param[out] NDS Unit number to be assigned.
  !> @param[in] TYPE Type identifier to be used.
  !> @param[in] NR Number of consecutive units needed for output
  !>               bounday data files.
  !>
  !> @author H. L. Tolman @date 20-Jan-2017
  !>
  SUBROUTINE WMUGET ( NDSE, NDST, NDS, TYPE, NR )
    !/
    !/                  +-----------------------------------+
    !/                  | WAVEWATCH III           NOAA/NCEP |
    !/                  |           H. L. Tolman            |
    !/                  |                        FORTRAN 90 |
    !/                  | Last update :         20-Jan-2017 !
    !/                  +-----------------------------------+
    !/
    !/    28-Mar-2005 : Origination.                        ( version 3.07 )
    !/    20-Jan-2017 : Add INQUIRE OPENED check.           ( version 6.02 )
    !/                  (T. J. Campbell, NRL)
    !/
    !  1. Purpose :
    !
    !     Find a free unit number for a given file type.
    !
    !  2. Method :
    !
    !     Search the data base.
    !
    !  3. Parameters :
    !
    !     Parameter list
    !     ----------------------------------------------------------------
    !       NDSE    Int.   I   Unit number for error output.
    !       NDST    Int.   I   Unit number for test output.
    !       NDS     Int.   O   Unit number to be assigned.
    !       TYPE    C*3    I   Type identifier to be used.
    !       NR      Int.   I   Number of consecutive units needed.
    !                          Needed for output bounday data files.
    !     ----------------------------------------------------------------
    !
    !  4. Subroutines used :
    !
    !      Name      Type  Module   Description
    !     ----------------------------------------------------------------
    !      STRACE    Sur.  W3SERVMD Subroutine tracing.
    !      EXCTDE    Sur.    Id.    Program abort.
    !     ----------------------------------------------------------------
    !
    !  5. Called by :
    !
    !  6. Error messages :
    !
    !  7. Remarks :
    !
    !  8. Structure :
    !
    !  9. Switches :
    !
    !     !/S    Enable subroutine tracing.
    !     !/T    Enable test output
    !
    ! 10. Source code :
    !
    !/ ------------------------------------------------------------------- /
    USE W3SERVMD, ONLY: EXTCDE
#ifdef W3_S
    USE W3SERVMD, ONLY: STRACE
#endif
    !
    IMPLICIT NONE
    !/
    !/ ------------------------------------------------------------------- /
    !/ Parameter list
    !/
    INTEGER, INTENT(IN)           :: NDSE, NDST
    INTEGER, INTENT(OUT)          :: NDS
    CHARACTER(LEN=3), INTENT(IN)  :: TYPE
    INTEGER, INTENT(IN), OPTIONAL :: NR
    !/
    !/ ------------------------------------------------------------------- /
    !/ Local parameters
    !/
    INTEGER                 :: NRC, I, J
#ifdef W3_S
    INTEGER, SAVE           :: IENT = 0
#endif
    LOGICAL                 :: OK
    LOGICAL                 :: OPND
    !/
#ifdef W3_S
    CALL STRACE (IENT, 'WMUGET')
#endif
    !
    ! -------------------------------------------------------------------- /
    ! 1.  Test input / output
    !
    IF ( .NOT. FLINIT ) THEN
      WRITE (NDSE,1010)
      CALL EXTCDE ( 1010 )
    END IF
    !
    IF ( PRESENT(NR) ) THEN
      NRC    = MAX ( 1 , NR )
    ELSE
      NRC    = 1
    END IF
    !
#ifdef W3_T
    WRITE (NDST,9010) TYPE, NRC
#endif
    !
    ! -------------------------------------------------------------------- /
    ! 2.  Find first free unit number and reset flag
    !
    NDS    = -1
    !
    DO I=UNITLW, UNITHG - NRC + 1
      ! new: We do not allow I=NDST (unit number for test output).
      !      NDST (aka MDST or IDST) is set to 10 in call to WMINIT
      !      (4th argument)
      OK     = .NOT.U_USED(I) .AND. U_TYPE(I).EQ.TYPE  &
           .AND. I.NE.NDST
      INQUIRE ( I, OPENED=OPND )
      OK     = OK .AND. .NOT.OPND
      IF ( OK ) THEN
        DO J=1, NRC-1
          OK     = OK .AND. (.NOT.U_USED(I+J) .AND.               &
               U_TYPE(I+J).EQ.TYPE )
          INQUIRE ( I+J, OPENED=OPND )
          OK     = OK .AND. .NOT.OPND
        END DO
      END IF
      IF ( OK ) THEN
        NDS       = I
        DO J=0, NRC-1
          U_USED(I+J) = .TRUE.
        END DO
        EXIT
      END IF
    END DO
    !
    IF ( NDS .EQ. -1 ) THEN
      WRITE (NDSE,1020) TYPE
      CALL EXTCDE ( 1020 )
    END IF
    !
#ifdef W3_T
    WRITE (NDST,9020) NDS
#endif
    !
    RETURN
    !
    ! Formats
    !
1010 FORMAT (/' *** ERROR WMUGET: INITIALIZE FIRST !!! ***')
1020 FORMAT (/' *** ERROR WMUGET: CANNOT FIND FREE UNIT FOR TYPE ',  &
         A,' ***'/)
    !
#ifdef W3_T
9010 FORMAT ( ' TEST WMUGET: LOOKING FOR UNIT FOR TYPE ',A,' [',  &
         I2,']')
9020 FORMAT ( ' TEST WMUGET: UNIT NUMBER SET TO',I4)
#endif
    !/
    !/ End of WMUGET ----------------------------------------------------- /
    !/
  END SUBROUTINE WMUGET
  !/ ------------------------------------------------------------------- /
  !>
  !> @brief Update data base information for a given unit number.
  !>
  !> @details FORTRAN INQUIRE statement.
  !>
  !> @param[in] NDSE Unit number for error output.
  !> @param[in] NDST Unit number for test output.
  !> @param[in] NDS  Unit number to be assigned.
  !>
  !> @author H. L. Tolman  @date 29-Mar-2005
  !>
  SUBROUTINE WMUINQ ( NDSE, NDST, NDS )
    !/
    !/                  +-----------------------------------+
    !/                  | WAVEWATCH III           NOAA/NCEP |
    !/                  |           H. L. Tolman            |
    !/                  |                        FORTRAN 90 |
    !/                  | Last update :         29-Mar-2005 !
    !/                  +-----------------------------------+
    !/
    !/    29-Mar-2005 : Origination.                        ( version 3.07 )
    !/
    !  1. Purpose :
    !
    !     Update data base information for a given unit number.
    !
    !  2. Method :
    !
    !     FORTRAN INQUIRE statement.
    !
    !  3. Parameters :
    !
    !     Parameter list
    !     ----------------------------------------------------------------
    !       NDSE    Int.   I   Unit number for error output.
    !       NDST    Int.   I   Unit number for test output.
    !       NDS     Int.   I   Unit number to be assigned.
    !     ----------------------------------------------------------------
    !
    !  4. Subroutines used :
    !
    !      Name      Type  Module   Description
    !     ----------------------------------------------------------------
    !      STRACE    Sur.  W3SERVMD Subroutine tracing.
    !      EXCTDE    Sur.    Id.    Program abort.
    !     ----------------------------------------------------------------
    !
    !  5. Called by :
    !
    !  6. Error messages :
    !
    !  7. Remarks :
    !
    !  8. Structure :
    !
    !  9. Switches :
    !
    !     !/S    Enable subroutine tracing.
    !     !/T    Enable test output
    !
    ! 10. Source code :
    !
    !/ ------------------------------------------------------------------- /
    USE W3SERVMD, ONLY: EXTCDE
#ifdef W3_S
    USE W3SERVMD, ONLY: STRACE
#endif
    !
    IMPLICIT NONE
    !/
    !/ ------------------------------------------------------------------- /
    !/ Parameter list
    !/
    INTEGER, INTENT(IN)           :: NDSE, NDST, NDS
    !/
    !/ ------------------------------------------------------------------- /
    !/ Local parameters
    !/
#ifdef W3_S
    INTEGER, SAVE           :: IENT = 0
#endif
    LOGICAL                 :: CHECK
    !/
#ifdef W3_S
    CALL STRACE (IENT, 'WMUINQ')
#endif
    !
    ! -------------------------------------------------------------------- /
    ! 1.  Test input / output
    !
    IF ( .NOT. FLINIT ) THEN
      WRITE (NDSE,1010)
      CALL EXTCDE ( 1010 )
    END IF
    !
    IF ( NDS.LT.UNITLW .OR. NDS.GT.UNITHG ) THEN
      WRITE (NDSE,1011) NDS, UNITLW, UNITHG
      CALL EXTCDE ( 1011 )
    END IF
    !
#ifdef W3_T
    WRITE (NDST,9010) NDS
#endif
    !
    ! -------------------------------------------------------------------- /
    ! 2.  Check out file
    ! 2.a Check if opened :
    !
    INQUIRE (NDS,OPENED=CHECK)
    !
#ifdef W3_T
    WRITE (NDST,9020) CHECK
#endif
    !
    ! 2.b File not opened, release to pool
    !
    IF ( .NOT. CHECK ) THEN
      CALL WMUSET ( NDSE, NDST, NDS, .FALSE. )
    ELSE
      !
      ! 2.c File is opened, get the name
      !
      INQUIRE (NDS,NAME=U_NAME(NDS))
      !
#ifdef W3_T
      WRITE (NDST,9021) U_NAME(NDS)
#endif
      !
    END IF
    !
    RETURN
    !
    ! Escape locations read errors --------------------------------------- *
    !
    !
    ! Formats
    !
1010 FORMAT (/' *** ERROR WMUINQ: INITIALIZE FIRST !!! ***')
1011 FORMAT (/' *** ERROR WMUINQ: UNIT NUMBER OUT OF RANGE ***'      &
         /'                   REQ/RANG :',3I6/)
    !
#ifdef W3_T
9010 FORMAT ( ' TEST WMUINQ: TESTING UNIT NUMBER',I4)
9020 FORMAT ( '              INQUIRE ON OPENED : ',L2)
9021 FORMAT ( '              NAME OF FILE      : ',A)
#endif
    !/
    !/ End of WMUINQ ----------------------------------------------------- /
    !/
  END SUBROUTINE WMUINQ
  !/
  !/ End of module WMUNITMD -------------------------------------------- /
  !/
END MODULE WMUNITMD
