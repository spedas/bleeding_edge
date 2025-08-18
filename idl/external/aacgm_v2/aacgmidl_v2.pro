; time.pro
; ========
; Author: R.J.Barnes
;
; $License$
;
; TimeYrsectoYMDHMS         Convert seconds of year to YMDHMS
; TimeYMDHMStoYrsec         Convert YMDHMS to seconds of year
; TimeEpochtoYMDHMS         Convert seconds of epoch to YMDHMS
; TimeYMDHMStoEpoch         Convert YMDHMS to seconds of epoch
; TimeJuliantoYMDHMS        Convert Julian time to YMDHMS
; TimeYMDHMStoJulian        Convert YMDHMS to Julian time
;
; ---------------------------------------------------------------



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;+
; NAME:
;       TimeYrsectoYMDHMS
;
; PURPOSE:
;       Convert seconds of year to YMDHMS.
;
;
; CALLING SEQUENCE:
;       status = TimeYrsecToYMDHMS(yr,mo,dy,hr,mt,sc,yrsec)
;
;       All the arguments must be given.
;
;       The returned value is zero for success, or -1 for failure
;
;-----------------------------------------------------------------
;


function TimeYrsecToYMDHMS,yr,mo,dy,hr,mt,sc,yrsec

  nday=[0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334, 365]
  lday=[0, 31, 60, 91, 121, 152, 182, 213, 244, 274, 305, 335, 366]

  if ((yr mod 4) eq 0) and (((yr mod 100) ne 0) or ((yr mod 400) eq 0)) then $
    jday=lday else jday=nday

  yd=fix(yrsec/(24L*60L*60L));

  n=0
  while ((n lt 12) and (yd ge jday[n])) do n=n+1

  mo=n
  if (n gt 0) then dy=1+yd-jday[n-1] else dy=yd+1

  dt=yrsec mod (24L*60L*60L)
  hr=fix(dt/(60L*60L))
  mt=fix((dt mod (60L*60L))/60L)
  ;sc=fix(dt mod 60L)
  sc=(dt mod 60L)

  return, 0
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;+
; NAME:
;       TimeYMDHMSToYrsec
;
; PURPOSE:
;       Convert YMDHMS to seconds of year.
;
;
; CALLING SEQUENCE:
;       yrsec = TimeYMDHMSToYrSec(yr,mo,dy,hr,mt,sc)
;
;       All the arguments must be given.
;
;       The returned value is the number of seconds past the
;       start of the year for success, or -1 for failure
;
;-----------------------------------------------------------------
;

function TimeYMDHMSToYrsec,yr,mo,dy,hr,mt,sc

  jday=[0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334]
  mday=[31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]

  if ( (mo lt 1) or (mo gt 12) or (hr lt 0) or (hr gt 23) or $
    (dy lt 1) or (mt lt 0) or (mt ge 60) or (sc lt 0) or $
    (sc ge 60) ) then return, -1

  if (dy gt mday[mo-1]) then begin
    if (mo ne 2) then return, -1 $
    else if (dy ne (mday[1] +1) or ((yr mod 4) ne 0)) then return, -1
  endif

  t = jday[mo-1] + dy - 1

  if ( (mo gt 2) and ((yr mod 4) eq 0) and $
    (((yr mod 100) ne 0) or ((yr mod 400) eq 0))) then t=t+1

  ;return, (((t*24L + hr)*60L + mt)*60L)+sc
  return, (((t*24D + hr)*60D + mt)*60D)+sc
end


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;+
; NAME:
;       TimeYMDHMSToEpoch
;
; PURPOSE:
;       Convert YMDHMS to seconds of epoch.
;
;
; CALLING SEQUENCE:
;       epoch = TimeYMDHMSToEpoch(yr,mo,dy,hr,mt,sc)
;
;       All the arguments must be given.
;
;       The returned value is the number of seconds since 0:00UT
;       January 1, 1970 for success, or -1 for failure
;
;-----------------------------------------------------------------
;

function TimeYMDHMSToEpoch,yr,mo,dy,hr,mt,sc

  YEAR_SEC=365.0D*24.0D*3600.0D
  LYEAR_SEC=366.0D*24.0D*3600.0D

  if (yr lt 1970) then return, -1

  yrsec=TimeYMDHMSToYrsec(yr,mo,dy,hr,mt,sc);
  if (yrsec eq -1) then return, -1
  ;tme=double(yrsec)
  tme=yrsec

  lpyear=(yr-1969)/4;
  ryear=(yr-1970)-lpyear;

  tme=tme+(lpyear*LYEAR_SEC)+(ryear*YEAR_SEC)

  return, tme
end


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;+
; NAME:
;       TimeEpochToYMDHMS
;
; PURPOSE:
;       Convert seconds of epoch to YMDHMS.
;
;
; CALLING SEQUENCE:
;       status = TimeEpochToYMDHMS(yr,mo,dy,hr,mt,sc,epoch)
;
;       All the arguments must be given.
;
;       The returned value is zero for success, or -1 for failure
;
;-----------------------------------------------------------------
;

function TimeEpochToYMDHMS,yr,mo,dy,hr,mt,sc,tme

  i=0
  yrsec=0.0D
  YEAR_SEC=365.0D*24.0D*3600.0D
  LYEAR_SEC=366.0D*24.0D*3600.0D


  while (yrsec le tme) and (i lt 10000) do begin
    if ((i mod 4) eq 2) then yrsec=yrsec+LYEAR_SEC $
    else yrsec=yrsec+YEAR_SEC
    i=i+1

  endwhile

  if (((i-1) mod 4) eq 2) then tmptme=tme-(yrsec-LYEAR_SEC) $
  else tmptme=tme-(yrsec-YEAR_SEC)
  yr=i+1969
  return, TimeYrsecToYMDHMS(yr,mo,dy,hr,mt,sc,tmptme)
end


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;+
; NAME:
;       TimeYMDHMSToJulian
;
; PURPOSE:
;       Convert YMDHMS to Julian date.
;
;
; CALLING SEQUENCE:
;       julian = TimeYMDHMStoJulian(yr,mo,dy,hr,mt,sc)
;
;       All the arguments must be given.
;
;       The returned value is the julian time for success,
;       or -1 for failure
;
;-----------------------------------------------------------------
;


function TimeYMDHMSToJulian,yr,mo,dy,hr,mt,sc

  DAY_SEC=24.0D*3600.0D

  yr=yr-1

  i=fix(yr/100)

  A=i

  i=fix(A/4)
  B=fix(2-A+i)

  i=floor(365.25*yr)

  i+=floor(30.6001*14)

  jdoy=i+B+1720994.5D

  dfrac=1.0+TimeYMDHMSToYrsec(yr+1,mo,dy,hr,mt,sc)/DAY_SEC;

  return,jdoy+dfrac
end


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;+
; NAME:
;       TimeJulianToYMDHMS
;
; PURPOSE:
;       Convert Julian date to YMDHMS.
;
;
; CALLING SEQUENCE:
;       status = TimeJulianToYMDHMS(yr,mo,dy,hr,mt,sc,epoch)
;
;       All the arguments must be given.
;
;       The returned value is zero for success, or -1 for failure
;
;-----------------------------------------------------------------
;

function TimeJulianToYMDHMS,yr,mo,dy,hr,mt,sc,jd

  DAY_SEC=24.0D*3600.0D

  factor=0.5/DAY_SEC/1000;

  F=(jd+0.5)-floor(jd+0.5)

  if ((F+factor) ge 1.0) then begin
    jd=jd+factor;
    F=0.0;
  endif

  Z=floor(jd+0.5);

  if (Z lt 2299161) then A=Z $
  else begin
    alpha=floor((Z-1867216.25)/36524.25)
    A=Z+1+alpha-floor(alpha/4)
  endelse

  B=A+1524;
  C=floor((B-122.1)/365.25)
  D=floor(365.25*C)
  E=floor((B-D)/30.6001)
  day=B-D-floor(30.6001*E)+F

  if (E lt 13.5) then month=floor(E-0.5) $
  else month=floor(E-12.5)
  if (month gt 2.5) then year=C-4716 $
  else year=C-4715


  yr=fix(floor(year))
  mo=fix(month)
  dy=fix(floor(day))

  A=(day-floor(day))*DAY_SEC;

  hr=fix(floor(A/3600.0))
  mt=fix(floor((A-hr*3600.0D)/60.0))

  sc=A-hr*3600.0-mt*60.0

end

;------------------------------------------------------------------------------
;
; NAME:
;       AACGM_v2_Dayno
;
; PURPOSE:
;       Determine the day number of the given date.
;
; CALLING SEQUENCE:
;       AACGM_v2_Dayno, yr,mo,dy, days=days
;
;     Input Arguments:
;       yr            - 4-digit year
;       mo            - Month: 1-January, 2-February, etc.
;       dy            - Day of month, starting at 1
;
;       date inputs can be an array, but must be the same size and it is
;       assumed that each day is from the same year.
;
;     Keywords:
;       days          - set to a variable that will contain the total number of
;                       days in the given year.
;
;     Return Value:
;       dayno         - day number of the current year.
;
; HISTORY:
;
; Revision 1.0  14/06/10 SGS initial version
;
;+-----------------------------------------------------------------------------
;

function AACGM_v2_Dayno, yr,mo,dy, days=days
  ; works on an array. assume that all from same day
  ; WHAT IS THE POINT OF AN ARRAY OF THE SAME DAY?!

  mdays=[0,31,28,31,30,31,30,31,31,30,31,30,31]

  nelem = n_elements(yr)
  if (yr[0] ne yr[nelem-1]) or $
    (mo[0] ne mo[nelem-1]) or $
    (dy[0] ne dy[nelem-1]) then begin
    print, ''
    print, 'Not same day in AACGM_v2_Dayno'
    print, ''
    exit
  endif

  tyr = yr[0]
  ; leap year calculation
  if tyr mod 4 ne 0 then inc=0 $
  else if tyr mod 400 eq 0 then inc=1 $
  else if tyr mod 100 eq 0 then inc=0 $
  else inc=1
  mdays[2]=mdays[2]+inc

  if keyword_set(days) then days = fix(total(mdays))

  if nelem eq 1 then $
    doy = total(mdays[0:mo[0]-1])+dy[0] $
  else $
    doy = intarr(nelem) + total(mdays[0:mo[0]-1])+dy[0]

  return, fix(doy)
end

;------------------------------------------------------------------------------
;
; NAME:
;       AACGM_v2_Date
;
; PURPOSE:
;       Determine the date from the given day number and year.
;
; CALLING SEQUENCE:
;       AACGM_v2_Dayno, yr, dayno, mo,dy
;
;     Input Arguments:
;       yr            - 4-digit year
;       dayno         - day number, starting at 1 for Jan 1
;
;     Output Arguments:
;       mo            - Month: 1-January, 2-February, etc.
;       dy            - Day of month, starting at 1
;
; HISTORY:
;
; Revision 1.0  14/06/10 SGS initial version
;
;+-----------------------------------------------------------------------------
;

pro AACGM_v2_Date, yr,dayno, mo,dy

  err = 0

  mdays=[0,31,28,31,30,31,30,31,31,30,31,30,31]

  ; leap year calculation
  if yr mod 4 ne 0 then inc=0 $
  else if yr mod 400 eq 0 then inc=1 $
  else if yr mod 100 eq 0 then inc=0 $
  else inc=1
  mdays[2]=mdays[2]+inc

  tots = intarr(13)
  for k=0,12 do tots[k] = total(mdays[0:k])

  q = where(tots ge dayno, nq)
  mo = q[0]
  dy = dayno - tots[q[0]-1]

end

;------------------------------------------------------
; AACGMIDL_V2
; This procedure initializes environmental variables
; and compiles routines used for AACGM
;------------------------------------------------------
pro aacgmidl_v2

  ; set up the environmental variables
  rt_info = routine_info('aacgmidl_v2',/source)
  basedir=file_dirname(rt_info.path)

  envstring1='AACGM_v2_DAT_PREFIX='+basedir+path_sep()+'coeffs'+path_sep()+'aacgm_coeffs-14-'
  envstring2='IGRF_COEFFS='+basedir+path_sep()+'magmodel_1590-2025.txt'
  setenv,envstring1
  setenv,envstring2
  ; compile and initialize all routines needed for aacgm-v2
  igrflib_v2
  aacgmlib_v2
  aacgm_v2
  astalg
  mlt_v2

end