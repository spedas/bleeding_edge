;+
;*****************************************************************************************
;
;  FUNCTION :   test_spd_date_format.pro
;  PURPOSE  :   This routine tests whether an input is consistent with the expected
;                 format for a date used by several software routines within the
;                 TPLOT libraries.  The expected format is 'YYYY-MM-DD', where
;                 YYYY=year, MM=month, and DD=day.
;
;  CALLED BY:   
;               NA
;
;  INCLUDES:
;               NA
;
;  CALLS:
;               NA
;
;  REQUIRES:    
;               NA
;
;  INPUT:
;               TDATE    :  Scalar (or array) [string] defining the date of interest of
;                             the form:  'YYYY-MM-DD' [MM=month, DD=day, YYYY=year]
;
;  EXAMPLES:    
;               [calling sequence]
;               test = test_tdate_format(tdate [,NOMSSG=nomssg])
;
;  KEYWORDS:    
;               NOMSSG   :  If set, routine will not print out warning/informational
;                             messages
;                             [Default = FALSE]
;
;   CHANGED:  1)  Added keyword:  NOMSSG
;                                                                   [11/02/2015   v1.1.0]
;             2)  Changed name from test_tdate_format.pro to test_spd_date_format.pro
;                   for migration of version to SPEDAS libraries
;                                                                   [09/08/2016   v1.2.0]
;
;   NOTES:      
;               1)  The format expected by this routine is commonly used in the
;                     SPEDAS/TDAS libraries
;               2)  This is a direct adaptation of the routine test_tdate_format.pro from
;                     L.B. Wilson's UMN Modified Wind/3DP IDL Libraries
;
;  REFERENCES:  
;               NA
;
;   CREATED:  09/22/2015
;   CREATED BY:  Lynn B. Wilson III
;    LAST MODIFIED:  09/08/2016   v1.2.0
;    MODIFIED BY: Lynn B. Wilson III
;
; $LastChangedBy: lbwilsoniii_desk $
; $LastChangedDate: 2016-09-08 13:15:03 -0700 (Thu, 08 Sep 2016) $
; $LastChangedRevision: 21805 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/missions/wind/waves/test_spd_date_format.pro $
;
;*****************************************************************************************
;-

FUNCTION test_spd_date_format,tdate,NOMSSG=nomssg

;;----------------------------------------------------------------------------------------
;;  Constants/Defaults
;;----------------------------------------------------------------------------------------
f              = !VALUES.F_NAN
d              = !VALUES.D_NAN
s              = ''
with_rex       = '[0-9]'
;;  Error messages
noinput_mssg   = 'No or incorrect input was supplied...'
bad_intype_msg = 'Incorrect input type:  TDATE must be of string type...'
bad_in_for_msg = "Incorrect input format:  TDATE must have the following format 'YYYY-MM-DD'"
;;----------------------------------------------------------------------------------------
;;  Check input
;;----------------------------------------------------------------------------------------
test           = (N_PARAMS() LT 1)
IF (test[0]) THEN BEGIN
  IF ~KEYWORD_SET(nomssg) THEN MESSAGE,noinput_mssg[0],/INFORMATIONAL,/CONTINUE
  RETURN,0b
ENDIF
test           = (SIZE(tdate,/TYPE) NE 7)
IF (test[0]) THEN BEGIN
  IF ~KEYWORD_SET(nomssg) THEN MESSAGE,bad_intype_msg[0],/INFORMATIONAL,/CONTINUE
  RETURN,0b
ENDIF
slens          = STRLEN(tdate)
test           = (TOTAL(slens LT 10) GT 0)
IF (test[0]) THEN BEGIN
  IF ~KEYWORD_SET(nomssg) THEN MESSAGE,'0: '+bad_in_for_msg[0],/INFORMATIONAL,/CONTINUE
  RETURN,0b
ENDIF
;;----------------------------------------------------------------------------------------
;;  Test input
;;----------------------------------------------------------------------------------------
yy             = STRMID(tdate,0L,4L)      ;;  should be 'YYYY'
mm             = STRMID(tdate,5L,2L)      ;;  should be 'MM'
dd             = STRMID(tdate,8L,2L)      ;;  should be 'DD'
nd             = N_ELEMENTS(tdate)
test_yy        = STREGEX(yy,with_rex[0]+'{4}',/BOOLEAN)     ;;  Make sure year is a 4 digit number
test_mm        = STREGEX(mm,with_rex[0]+'{2}',/BOOLEAN)     ;;  Make sure month is a 2 digit number
test_dd        = STREGEX(dd,with_rex[0]+'{2}',/BOOLEAN)     ;;  Make sure day is a 2 digit number
test           = (TOTAL(test_yy) NE nd[0]) OR (TOTAL(test_mm) NE nd[0]) OR $
                 (TOTAL(test_dd) NE nd[0])
IF (test[0]) THEN BEGIN
  IF ~KEYWORD_SET(nomssg) THEN MESSAGE,'1: '+bad_in_for_msg[0],/INFORMATIONAL,/CONTINUE
  RETURN,0b
ENDIF
;;----------------------------------------------------------------------------------------
;;  Passed test --> Return to user
;;----------------------------------------------------------------------------------------

RETURN,1b
END



