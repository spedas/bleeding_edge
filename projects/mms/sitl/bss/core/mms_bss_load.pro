;+
; NAME: mms_bss_load
;
; PURPOSE: To return burst-segment status (aka 'back-structure') 
;          within a given time interval. Ask super-SITLs for the meaning of 
;          each tag in the returned structure.  
;          
; CALLING SEQUENCE: result = mms_bss_load(trange)
;
; INPUTS:  trange .... can be either string or double
;
; EXAMPLE:
;
;     MMS> tr = time_double('2015-11-04/'+['04:00','05:00'])
;     MMS> s = mms_bss_load(trange=tr)
;     MMS> help, s
;     
; NOTES: 
;     
;     1. If no burst-segment were found within the trange, then this function returns -1
;     
;     2. The timerange 'trange' should not be too big (like more than a month).
;        because LaTis (at SDC) will return an erratic result (as of 2016-09-02).
;     
;     3. The FIN keyword is obsolete and should not be used if the above issue (item 2) 
;        remains. 
;        
;   FIN: Set this keyword to find segments that 'finished' within trange
;        instead of querying segments that were defined within trange.
;        Because a segment can take many tens of days,
;        trange is expand to [tlaunch,tnow] when retrieving segment info.
;                
; CREATED BY: M. Oka   August 2015
;
; $LastChangedBy: moka $
; $LastChangedDate: 2017-02-02 21:31:34 -0800 (Thu, 02 Feb 2017) $
; $LastChangedRevision: 22722 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/sitl/bss/core/mms_bss_load.pro $
;-
FUNCTION mms_bss_load, trange=trange, fin=fin
  compile_opt idl2

  mms_init

  ;----------------
  ; TIME RANGE
  ;----------------
  tlaunch = time_double('2015-03-12/22:44')
  tnow = systime(/utc,/seconds)
  tr = (n_elements(trange) eq 2) ? timerange(trange) : [tlaunch,tnow]
  ts = tr[0]
  if keyword_set(fin) then begin
    ;tr[0] -= 30.d0*86400.d0; Extends the time range by one more month.
    tr[0] = tlaunch
  endif
  print,' Executing query: '
  print,' timerange = '+time_string(tr[0])+' - '+time_string(tr[1])


  ;------------------
  ; GET BACK-STRUCT
  ;------------------
  mms_get_back_structure, tr[0], tr[1], BAKStr, pw_flag, pw_message; START,STOP are ULONG
  if pw_flag then begin
    print,'pw_flag = 1'
    print, pw_message
    return, -1
  endif
  s = BAKStr
  str_element,/add,s,'START', mms_tai2unix(BAKStr.START); START,STOP are LONG
  str_element,/add,s,'STOP',  mms_tai2unix(BAKStr.STOP)

  ;-----------------------
  ; CREATE & FINISH TIME
  ;-----------------------
  ; If pending, FINISHTIME will be a null string and will cause some inconvenience later.
  ; Here, such null FINISHTIMEs are replaced with the current time.
  cretime = time_double(s.CREATETIME)
  fintime = time_double(s.FINISHTIME)
  idx = where(strlen(s.FINISHTIME) eq 0, ct)
  if ct gt 0 then begin
    fintime[idx] = tnow
  endif
  str_element,/add,s,'UNIX_FINISHTIME',fintime
  str_element,/add,s,'UNIX_CREATETIME',cretime

  snew = s  
  if keyword_set(fin) then begin
    idx = where((ts le s.UNIX_CREATETIME) and (s.UNIX_CREATETIME le tr[1]), ct)
    if ct gt 0 then begin
      snew = mms_bss_replace(s, idx)
    endif
  endif
  return, snew
END
