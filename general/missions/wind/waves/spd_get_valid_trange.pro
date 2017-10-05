;+
;*****************************************************************************************
;
;  FUNCTION :   spd_get_valid_trange.pro
;  PURPOSE  :   This routine determines a time range in several formats from inputs
;                 define by the optional keywords or prompts to the user.
;
;  CALLED BY:   
;               NA
;
;  INCLUDES:
;               NA
;
;  CALLS:
;               time_double.pro
;               test_spd_date_format.pro
;               is_num.pro
;               spd_gen_prompt_routine.pro
;               time_string.pro
;               time_struct.pro
;
;  REQUIRES:    
;               1)  SPEDAS IDL Libraries
;
;  INPUT:
;               NA
;
;  EXAMPLES:    
;               [calling sequence]
;               struc = spd_get_valid_trange([TDATE=tdate] [,TRANGE=trange] $
;                                            [,PRECISION=prec]              )
;
;  KEYWORDS:    
;               TDATE          :  Scalar [string] defining the date of interest of the form:
;                                   'YYYY-MM-DD' [MM=month, DD=day, YYYY=year]
;                                   [Default = {prompted input if TRANGE not set}]
;               TRANGE         :  [2]-Element [double] array specifying the Unix time
;                                   range for which to define/constrain data
;                                   [Default = {prompted input if TDATE not set}]
;               PRECISION      :  Scalar [long] defining precision of the string output:
;                                   = -5  :  Year only
;                                   = -4  :  Year, month
;                                   = -3  :  Year, month, date
;                                   = -2  :  Year, month, date, hour
;                                   = -1  :  Year, month, date, hour, minute
;                                   = 0   :  Year, month, date, hour, minute, sec
;                                   = >0  :  fractional seconds
;                                   [Default = 0]
;               MIN_TDATE      :  Scalar [string] defining the minimum allowable
;                                   date that user can specify [same format as TDATE]
;                                   [Default = '1957-10-04']
;               MAX_TDATE      :  Scalar [numeric] defining the maximum allowable
;                                   date that user can specify [same format as TDATE]
;                                   [Default = {today's date}]
;
;   CHANGED:  1)  Continued to write routine
;                                                                   [09/25/2015   v1.0.0]
;             2)  Fixed bug when both TDATE and TRANGE are set
;                                                                   [09/25/2015   v1.0.1]
;             3)  Changed a default output message, updated Man. page, and changed the
;                   minimum time range limit from 1 hour to 1 microsecond
;                                                                   [10/05/2015   v1.0.2]
;             4)  Added NOMSSG keyword to test_tdate_format.pro to reduce unnecessary
;                   and/or redundant output messages
;                                                                   [11/02/2015   v1.0.3]
;             5)  Fixed bug when NO_CLEAN keyword is set in call to time_struct.pro
;                   [bug only affected day of year output]
;                                                                   [09/08/2016   v1.1.0]
;             6)  Changed name from get_valid_trange.pro to
;                   spd_get_valid_trange.pro for migration of version
;                   to SPEDAS libraries --> now calls:
;                   test_spd_date_format.pro
;                   is_num.pro
;                   spd_gen_prompt_routine.pro
;                   and added keywords:  MAX_TDATE and MIN_TDATE
;                                                                   [09/08/2016   v1.2.0]
;
;   NOTES:      
;               1)  If no keywords are given, the routine will prompt the user for a
;                     single date and define the time range as that given date.
;               2)  See also:  time_struct.pro, time_string.pro, time_struct.pro
;               3)  Setting TDATE will result in a time range for the date defined from
;                     the start to the end of the day
;               3)  This is a direct adaptation of the routine get_valid_trange.pro
;                     from L.B. Wilson's UMN Modified Wind/3DP IDL Libraries
;
;  REFERENCES:  
;               NA
;
;   CREATED:  09/23/2015
;   CREATED BY:  Lynn B. Wilson III
;    LAST MODIFIED:  09/08/2016   v1.2.0
;    MODIFIED BY: Lynn B. Wilson III
;
; $LastChangedBy: lbwilsoniii_desk $
; $LastChangedDate: 2016-09-08 13:15:03 -0700 (Thu, 08 Sep 2016) $
; $LastChangedRevision: 21805 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/missions/wind/waves/spd_get_valid_trange.pro $
;
;*****************************************************************************************
;-

FUNCTION spd_get_valid_trange,TDATE=tdate,TRANGE=trange,PRECISION=prec,  $
                              MIN_TDATE=min_tdate,MAX_TDATE=max_tdate

;;----------------------------------------------------------------------------------------
;;  Define some defaults
;;----------------------------------------------------------------------------------------
;;  Default time-related values
start_of_day   = '00:00:00.000000'
end___of_day   = '23:59:59.999999'
;;  Define the DOY values at the start of each month for non-leap and leap years
mdt            = [[0, 31,  59,  90, 120, 151, 181, 212, 243, 273, 304, 334, 365], $
                  [0, 31,  60,  91, 121, 152, 182, 213, 244, 274, 305, 335, 366]]
;;  Define the # of days in each month for non-leap and leap years
nd_per_mon     = INTARR(13,2)
x              = LINDGEN(12)  & y = x + 1L
nd_per_mon[y,*] = mdt[y,*] - mdt[x,*]     ;;  # of days in each month
;;  Default prompting info
yearmin        = 1957L                   ;;  Year Sputnik 1 spacecraft was launched --> cannot start before this
tdate_min      = '1957-10-04'            ;;  Date Sputnik 1 spacecraft was launched
unix_min       = time_double(tdate_min[0]+'/'+end___of_day[0])
unix_max       = SYSTIME(1,/SECONDS)
current_time   = SYSTIME()               ;;  Current time
yearmax        = LONG(STRMID(current_time,STRLEN(current_time)-4,4))
prompt_yy      = "Please enter a year between "+STRING(yearmin[0],FORMAT='(I4.4)')+$
                 " and "+STRING(yearmax[0],FORMAT='(I4.4)')+":"
prompt_mm      = "Please enter a month between 1 and 12:"
prompt_dd      = "Please enter a day between 1 and 31:"     ;;  this will change below
;;----------------------------------------------------------------------------------------
;;  Check keywords
;;----------------------------------------------------------------------------------------
;;  Check TDATE
test           = (N_ELEMENTS(tdate) LT 1) OR (test_spd_date_format(tdate,/NOMSSG) EQ 0)
IF (test[0]) THEN tdate_on = 0b ELSE tdate_on = 1b
;;  Check TRANGE
test           = (N_ELEMENTS(trange) GE 2) AND is_num(trange)
IF (test[0]) THEN BEGIN
  test = ((TOTAL(trange GT unix_min[0]) EQ 2) OR (TOTAL(trange LT unix_max[0]) EQ 2)) AND $
          (trange[0] NE trange[1])
ENDIF
IF (test[0]) THEN tran__on = 1b ELSE tran__on = 0b
;;  Check PRECISION
test           = (N_ELEMENTS(prec) GE 1) AND is_num(prec)
IF (test[0]) THEN prec = (LONG(prec[0]))[0] < 15L ELSE prec = 0L
;;  Check MAX_TDATE and MIN_TDATE
test           = (N_ELEMENTS(min_tdate) LT 1) OR (test_spd_date_format(min_tdate,/NOMSSG) EQ 0)
IF (test[0]) THEN min_tdate_on = 0b ELSE min_tdate_on = 1b
test           = (N_ELEMENTS(max_tdate) LT 1) OR (test_spd_date_format(max_tdate,/NOMSSG) EQ 0)
IF (test[0]) THEN max_tdate_on = 0b ELSE max_tdate_on = 1b
;;  Check if time range limit and prompting strings require updating
test           = min_tdate_on[0] OR max_tdate_on[0]
IF (test[0]) THEN BEGIN
  IF (min_tdate_on[0]) THEN BEGIN
    unix_min       = time_double(min_tdate[0]+'/'+start_of_day[0])
    yearmin        = LONG(STRMID(min_tdate[0],0L,4))
  ENDIF
  IF (max_tdate_on[0]) THEN BEGIN
    unix_max       = time_double(max_tdate[0]+'/'+end___of_day[0])
    yearmax        = LONG(STRMID(max_tdate[0],0L,4))
  ENDIF
  ;;  Update year prompt
  prompt_yy      = "Please enter a year between "+STRING(yearmin[0],FORMAT='(I4.4)')+$
                   " and "+STRING(yearmax[0],FORMAT='(I4.4)')+":"
ENDIF
;;----------------------------------------------------------------------------------------
;;  Define Time Range
;;----------------------------------------------------------------------------------------
;;  Define Min/Max TDATES
tdate_min      = STRMID(time_string(unix_min[0],PREC=3),0L,10L)
tdate_max      = STRMID(time_string(unix_max[0],PREC=3),0L,10L)
month_min      = STRMID(tdate_min[0],5L,2L)
month_max      = STRMID(tdate_max[0],5L,2L)
daynm_min      = STRMID(tdate_min[0],8L,2L)
daynm_max      = STRMID(tdate_max[0],8L,2L)
test           = (tdate_on[0] EQ 0) AND (tran__on[0] EQ 0)
IF (test[0]) THEN BEGIN  ;;  Niether TDATE or TRANGE were set
  ;;--------------------------------------------------------------------------------------
  ;;    --> Prompt user for a year
  ;;--------------------------------------------------------------------------------------
  read_out       = 0L
  val__out       = 0L
  WHILE (val__out[0] LT yearmin[0] OR val__out[0] GT yearmax[0]) DO BEGIN
    val__out = spd_gen_prompt_routine(read_out,STR_OUT=prompt_yy[0])
    test     = (is_num(val__out) EQ 0)
    IF (test[0]) THEN val__out = 0L
  ENDWHILE
  ;;  Define year [force long integer format too]
  year           = (LONG(STRING(val__out[0],FORMAT='(I4.4)')))[0]
  leap           = ((year[0] MOD 4) EQ 0) - ((year[0] MOD 100) EQ 0) + ((year[0] MOD 400) EQ 0) $
                    - ((year[0] MOD 4000) EQ 0)
  ;;  Update Min/Max month range if necessary
  min_mon        = ([ 1L,(LONG(month_min[0]))[0]])[(year[0] EQ yearmin[0])]
  max_mon        = ([12L,(LONG(month_max[0]))[0]])[(year[0] EQ yearmax[0])]
  mnmx_mstr      = STRING([min_mon[0],max_mon[0]],FORMAT='(I2.2)')
  ;;  Re-define the month prompt
  prompt_mm      = "Please enter a month between "+mnmx_mstr[0]+" and "+mnmx_mstr[1]+":"
  ;;--------------------------------------------------------------------------------------
  ;;    --> Prompt user for a month
  ;;--------------------------------------------------------------------------------------
  read_out       = 0L
  val__out       = 0L
  WHILE (val__out[0] LT min_mon[0] OR val__out[0] GT max_mon[0]) DO BEGIN
    val__out = spd_gen_prompt_routine(read_out,STR_OUT=prompt_mm[0])
    test     = (is_num(val__out) EQ 0)
    IF (test[0]) THEN val__out = 0L
  ENDWHILE
  ;;  Define month [force long integer format too]
  month          = (LONG(STRING(val__out[0],FORMAT='(I2.2)')))[0]
  ;;  Define the max number of days in this month
  max_nd         = nd_per_mon[month[0],leap[0]]
  ;;  Update Min/Max month range if necessary
  test_min       = (year[0] EQ yearmin[0]) AND (month[0] EQ (LONG(month_min[0]))[0])
  test_max       = (year[0] EQ yearmax[0]) AND (month[0] EQ (LONG(month_max[0]))[0])
  min_day        = ([ 1L,(LONG(daynm_min[0]))[0]])[test_min[0]]
  max_day        = ([max_nd[0],(LONG(daynm_max[0]))[0]])[test_max[0]]
  mnmx_dstr      = STRING([min_day[0],max_day[0]],FORMAT='(I2.2)')
  ;;  Re-define the day prompt
  prompt_dd      = "Please enter a day between "+mnmx_dstr[0]+" and "+mnmx_dstr[1]+":"
  ;;--------------------------------------------------------------------------------------
  ;;    --> Prompt user for a day
  ;;--------------------------------------------------------------------------------------
  read_out       = 0L
  val__out       = 0L
  WHILE (val__out[0] LT min_day[0] OR val__out[0] GT max_day[0]) DO BEGIN
    val__out = spd_gen_prompt_routine(read_out,STR_OUT=prompt_dd[0])
    test     = (is_num(val__out) EQ 0)
    IF (test[0]) THEN val__out = 0L
  ENDWHILE
  ;;  Define day [force long integer format too]
  day            = (LONG(STRING(val__out[0],FORMAT='(I2.2)')))[0]
  ;;  Define TDATE [e.g., '2007-01-01']
  tdate          = STRING(year[0],FORMAT='(I4.4)')+'-'+STRING(month[0],FORMAT='(I2.2)')+$
                   '-'+STRING(day[0],FORMAT='(I2.2)')
  ;;  Define TRANGE
  tra_t          = tdate[0]+'/'+[start_of_day[0],end___of_day[0]]
  trange         = time_double(tra_t)
  ;;  Redefine string time range in case it changed
  tra_t          = time_string(trange,PREC=prec)
  ;;  Define TDATES in case it changed
  tdates         = STRMID(tra_t,0L,10L)
  ;;  Let user know the date they chose
  outmssg        = 'Defining time range for '+tdate[0]
  MESSAGE,outmssg[0],/INFORMATIONAL,/CONTINUE
ENDIF ELSE BEGIN
  ;;--------------------------------------------------------------------------------------
  ;;  Either TDATE and/or TRANGE was set
  ;;--------------------------------------------------------------------------------------
  test           = (TOTAL([(tdate_on[0] EQ 0),(tran__on[0] EQ 0)]) LT 2) AND $
                   (TOTAL([tdate_on[0],tran__on[0]]) NE 2)
  IF (test[0]) THEN BEGIN
    ;;  Only one is set
    CASE 1 OF
      (tdate_on[0] EQ 0)  :  BEGIN
        ;;  TRANGE was set
        ;;    --> Constrain to within valid time ranges [force min ∆t = 1 µs]
        trange         = trange[SORT(trange)]
        trange[0]      = trange[0] > unix_min[0]
        trange[1]      = (trange[1] < unix_max[0]) > (trange[0] + 1d-6)
        tra_t          = time_string(trange,PRECISION=prec)
        ;;  Define TDATES [e.g., '2007-01-01']
        tdates         = STRMID(tra_t,0L,10L)
      END
      (tran__on[0] EQ 0)  :  BEGIN
        ;;  TDATE was set --> Load one full day
        ;;    --> Check
        tra_t          = tdate[0]+'/'+[start_of_day[0],end___of_day[0]]
        ;;  Define TRANGE
        trange         = time_double(tra_t)
        ;;    --> Constrain to within valid time ranges [force min ∆t = 1 µs]
        trange[0]      = trange[0] > unix_min[0]
        trange[1]      = (trange[1] < unix_max[0]) > (trange[0] + 1d-6)
        ;;  Redefine string time range in case it changed
        tra_t          = time_string(trange,PRECISION=prec)
        ;;  Define TDATES in case it changed
        tdates         = STRMID(tra_t,0L,10L)
      END
      ELSE                :  STOP   ;;  This should not be able to happen... debug!
    ENDCASE
  ENDIF ELSE BEGIN
    ;;  Both are set --> Check [TRANGE has priority]
    ;;    --> Constrain to within valid time ranges [force min ∆t = 1 µs]
    trange         = trange[SORT(trange)]
    trange[0]      = trange[0] > unix_min[0]
    trange[1]      = (trange[1] < unix_max[0]) > (trange[0] + 1d-6)
    tra_t          = time_string(trange,PRECISION=prec)
    ;;  Define TDATES in case it changed
    tdates         = STRMID(tra_t,0L,10L)
  ENDELSE
ENDELSE
;;----------------------------------------------------------------------------------------
;;  Determine day of year (DOY) range
;;----------------------------------------------------------------------------------------
tstruc         = time_struct(tra_t)
test           = (SIZE(tstruc,/TYPE) EQ 8)
IF (test[0]) THEN doy_ra = tstruc.DOY ELSE doy_ra = REPLICATE(-1,2L)
;;----------------------------------------------------------------------------------------
;;  Define output structure
;;----------------------------------------------------------------------------------------
tags           = ['DATE','DOY','STRING','UNIX']+'_TRANGE'
struct         = CREATE_STRUCT(tags,tdates,doy_ra,tra_t,trange)
;;----------------------------------------------------------------------------------------
;;  Return to user
;;----------------------------------------------------------------------------------------

RETURN,struct
END














