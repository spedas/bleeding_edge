;+
; NAME:
;       test_leap_yr
; CALLING SEQUENCE:
;       lyr=test_leap_yr(iyr,modays=modays)
; PURPOSE:
;       Determines whether a given year is a leap year, and
;       returns the number of days in every month
; INPUT:
;       iyr = The year, as an integer
; OUTPUT:
;       lyr= 1 if iyr is a leap year and 0 if not
; KEYWORDS:
;       modays= the number of days in each month
;       modays= [31, 29, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31] for
;       a leap yr, [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31] otherwise
; HISTORY:
;       Written 19-OCt-93 by JM
;       Rewritten, 9-jul-2007, jmm
;-
FUNCTION Test_leap_yr, iyr, modays = modays
   iyr1 = fix(iyr)
   lyr = iyr1 & lyr[*] = 0
   cent = fix(float(iyr1)/100.0)
;   print, iyr1, cent
   ssc1 = where(cent GT 0)
;first be sure that the numbers in iyr1 are less than 100
   IF(ssc1[0] NE -1) THEN iyr1[ssc1] = iyr1[ssc1]-100*cent[ssc1]
;Ok, now do the leap year determination
   test = iyr1 MOD 4
;do the zeros correctly, leap year divisible by 100.0 are not,
;but years divisible by 400.0 are
   test_100 = cent MOD 1
   test_400 = cent MOD 4
   sslyr = where(test EQ 0)
   IF(sslyr[0] NE -1) THEN lyr[sslyr] = 1
   ss_100 = where((iyr1 EQ 0) AND (test_100 EQ 0))
   ss_400 = where((iyr1 EQ 0) AND (test_400 EQ 0))
   IF(ss_100[0] NE -1) THEN lyr[ss_100] = 0
   IF(ss_400[0] NE -1) THEN lyr[ss_400] = 1
;finally
   ssm1 = where(cent LT 0)
   IF(ssm1[0] NE -1) THEN BEGIN
      print, ' NO NEGATIVE CENTURIES'
      lyr[ssm1] = -1
   ENDIF
   modays = intarr(12, 2)
   modays[*, 1] = [31, 29, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
   modays[*, 0] = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
   RETURN, lyr   
END

;+
;NAME:
; spd_ui_timefix
;PURPOSE:
; Will fix an input time string of yyyy-mm-dd hh:mm:ss.xxxx if there
; is only 1 digit in the day or hour or second, etc.
; Will also return an error message, if the months, days, hours,
; seconds are not valid.
; 2011-07-20, added comment to test post-commit emails, jmm
; 2011-11-04, added comment to test post-commit emails, jmm
;$LastChangedBy: egrimes $
;$LastChangedDate: 2015-03-12 11:46:50 -0700 (Thu, 12 Mar 2015) $
;$LastChangedRevision: 17121 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas_gui/utilities/spd_ui_timefix.pro $
Function spd_ui_timefix, time_in, progobj = progobj, _extra = _extra
;-
  
  otp = -1
  t = strtrim(time_in, 2)
;  t = time_string(t)
  pxp1 = strpos(t, '-')         ;You gotta have dashes
  If(pxp1[0] Eq -1) Then Begin
    If(obj_valid(progobj)) Then progobj -> update, 0.0, $
      text = 'Bad time string input, no selection'
    Return, otp
  Endif
  ggg = strsplit(t, '-', /extract)
  ;Require year-month-day, yy-mm-dd or yyyy-mm-dd
  ;  changed logic to ensure ggg contains exactly 3 elements to avoid
  ;  crashes when the user inputs clearly invalid inputs, like: 'yyyy-mm-dd-/', 'yyyy-mm-dd-o', etc. 
  ; - egrimes 5/29/14
  If(n_elements(ggg) ne 3) Then Begin
  ;If(n_elements(ggg) Lt 3) Then Begin
    If(obj_valid(progobj)) Then progobj -> update, 0.0, $
      text = 'Bad time string input, no selection'
    Return, otp
  Endif
;test the year value
  If(is_numeric(ggg[0]) Eq 0) Then Begin
    If(obj_valid(progobj)) Then progobj -> update, 0.0, $
      text = 'Non-numerical year input, no selection'
    Return, otp
  Endif
  yr = fix(ggg[0])
  If(yr Lt 0) Then Begin
    If(obj_valid(progobj)) Then progobj -> update, 0.0, $
      text = 'Negative year input, no selection'
    Return, otp
  Endif
  if (yr GT 2100) Then Begin
    If(obj_valid(progobj)) Then progobj -> update, 0.0, $
      text = 'Year > 2100, no selection'
    Return, otp
  Endif
;this handles two-digit years, if less than 90, add 2000, otherwise
;add 1900
  If(yr Lt 100) Then Begin
    If(yr ge 90) Then yr = yr+1900 $
    Else yr = yr+2000
  Endif                           ;Else nothing, keep the year
;test the month value
  If(is_numeric(ggg[1]) Eq 0) Then Return, otp      
  mo = fix(ggg[1])
  If(mo Lt 1 Or mo Gt 12) Then Begin
    If(obj_valid(progobj)) Then progobj -> update, 0.0, $
      text = 'Month out of range, no selection'
    Return, otp
  Endif
;now, you don't necessarily need hours, minutes, seconds
;first check for a '/', if it's there use it as the time delimiter,
;otherwise use ' ', added support for T, 22-apr-2011, jmm
  pxp2 = strpos(t, '/') & pxp3 = strpos(t, 'T') 
  If(pxp2[0] Ne -1) Then hhh = strsplit(ggg[2], '/', /extract) $
  Else If(pxp3[0] Ne -1) Then hhh = strsplit(ggg[2], 'T', /extract) $
  Else hhh = strsplit(ggg[2], ' ', /extract)
  If(is_numeric(hhh[0]) Eq 0) Then Return, otp      
  dd = long(hhh[0])
;Need leap_yr information
  lyr = test_leap_yr(yr, modays = modays)
  dtest = [1, modays[mo-1, lyr]]
  If(dd Lt dtest[0] Or dd Gt dtest[1]) Then Begin
    If(obj_valid(progobj)) Then progobj -> update, 0.0, $
      text = 'Day out of range, no selection'
    Return, otp
  Endif
  If(dd Lt 10) Then dy = '0'+strcompress(string(dd), /remove_all) $
  Else dy = strcompress(string(dd), /remove_all)
  If(mo Lt 10) Then mon = '0'+strcompress(string(mo), /remove_all) $
  Else mon = strcompress(string(mo), /remove_all)
  yr = strcompress(string(yr), /remove_all)
;the time isn't necessarily passed in
  If(n_elements(hhh) Gt 1) Then Begin
    ttt = strsplit(hhh[1], ':', /extract)
    If(is_numeric(ttt[0]) Eq 0) Then Return, otp      
    hh = long(ttt[0])
    If(hh Lt 0 Or hh Gt 24) Then Begin
      If(obj_valid(progobj)) Then progobj -> update, 0.0, $
        text = 'Hour out of range, no selection'
      Return, otp
    Endif
    If(hh Lt 10) Then hr = '0'+strcompress(string(hh), /remove_all) $
    Else hr = strcompress(string(hh), /remove_all)
    If(n_elements(ttt) Gt 1) Then Begin
      If(is_numeric(ttt[1]) Eq 0) Then Return, otp      
      mm = long(ttt[1])
      If(mm Lt 0 Or mm Gt 59) or (hh eq 24 and mm ne 0) Then Begin  ;also dump if time > '24:00:00'
        If(obj_valid(progobj)) Then progobj -> update, 0.0, $
          text = 'Minute out of range, no selection'
        Return, otp
      Endif
      If(mm Lt 10) Then mn = '0'+strcompress(string(mm), /remove_all) $
      Else mn = strcompress(string(mm), /remove_all)
    Endif Else mn = '00'
    If(n_elements(ttt) Gt 2) Then Begin
      If(is_numeric(ttt[2]) Eq 0) Then Return, otp
      ss = long(ttt[2]) 
      msec = ''
;check for a decimal
      dpos = strpos(ttt[2], '.')
      If(dpos[0] Ne -1) Then Begin
        ttt2_tmp = strsplit(ttt[2], '.', /extract)
        If(n_elements(ttt2_tmp) Eq 2) Then Begin
          msec = '.'+ttt2_tmp[1]
        Endif
      Endif
      If(ss Lt 0 Or ss Ge 60) or (hh eq 24 and ss ne 0) Then Begin
        If(obj_valid(progobj)) Then progobj -> update, 0.0, $
          text = 'Second out of range, no selection'
        Return, otp
      Endif
      If(ss Lt 10) Then sc = '0'+strcompress(string(ss), /remove_all) $
      Else sc = strcompress(string(ss), /remove_all)
      sc = sc+msec
    Endif Else Begin
      sc = '00'
    Endelse
  Endif Else Begin
    hr = '00' & mn = '00' & sc = '00'
  Endelse
  otp = yr+'-'+mon+'-'+dy+' '+hr+':'+mn+':'+sc

  Return, otp
End

  

  
