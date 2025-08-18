;+
; NAME:  mms_get_roi
;
; PURPOSE:
;   To return the SROI timerange closest to the specified time "t".
;   If "t" is a large enough time range, then all ROIs within the time range
;   will be returned.
;
; CALLING SEQUENCE: roi = mms_get_roi( t [, num] )
;
; INPUT:
;    t (optional) Can be either string or double.
;                 Can be either a scalar or a 2-element array.
;                 If omitted, current time (UTC) will be used as the input.
;
; OUTPUT:
;    (2 x N) array indicating matched ROI time ranges.
;    N is the number of matched ROIs.
;
; OTHER OUTPUT:
;    num : the number of matched ROIs
;
; KEYWORDS:
;    NEXT: Returns the next ROI (does not overlap with the input timerange)
;    PREVIOUS: Returns the previous ROI (does not overlap with the input timerange)
;
; EXAMPLES:
;
;   (1) Find all ROIs within a time range
;
;   MMS> print, time_string(mms_get_roi(['2015-12-01/00:00','2015-12-07/24:00']))
;
;   (2) Find the ROI closest to time 2015-12-02/06:00
;
;   MMS> print, time_string(mms_get_roi('2015-12-02/06:00'))
;
;   (3) Find the ROI just after 2015-12-02/06:00
;
;   MMS> print, time_string(mms_get_roi('2015-12-02/06:00',/next))
;
;
; CREATED BY: moka in Oct 2015
; UPDATED after introducing dynamic SITL window: May 2020
;
; $LastChangedBy: moka $
; $LastChangedDate: 2020-05-24 15:23:34 -0700 (Sun, 24 May 2020) $
; $LastChangedRevision: 28734 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/sitl/bss/mms_get_roi.pro $
;-
FUNCTION mms_get_roi_distance, roi_time, tc, distance=distance
  compile_opt idl2

  distance0 = min(roi_time[0,*]-tc,n0,/abs)
  distance1 = min(roi_time[1,*]-tc,n1,/abs)
  if abs(distance0) lt abs(distance1) then begin
    distance = abs(distance0)
    nc = n0
  endif else begin
    distance = abs(distance1)
    nc = n1
  endelse
  return, nc
END

FUNCTION mms_get_roi, t, num, next=next, previous=previous, login_info=login_info, sc_id=sc_id
  compile_opt idl2
  
  ;------------
  ; TRANGE
  ;------------
  if undefined(t) then t = systime(/utc,/seconds) else t = time_double(t)
  mode = n_elements(t)
  pad = 3.0d0*86400.d0; ROI can be up to 3.0(?) days away
  case mode of
    1: tr = [t-pad, t+pad]; force the timerange to be a 2-element array
    2: tr = t
    else: message, '"time" should be either a scalar or a 2-element array.'
  endcase
  tc = 0.5d0*total(tr); center time
  num = 1

  ;------------
  ; SC_ID
  ;------------
  if undefined(sc_id) then sc_id = 'mms1'
  
  ;------------
  ; LOAD
  ;------------
  start_time = time_string(tr[0])
  end_time = time_string(tr[1])
  srois = get_mms_srois(start_time=start_time,$
     end_time=end_time, sc_id=sc_id)
  
  ;----------
  ; ANALYZE
  ;----------
  nmax = n_elements(srois)
  roi_time = dblarr(2,nmax)
  roi_time[0,0:nmax-1] = time_double(srois.START_TIME)
  roi_time[1,0:nmax-1] = time_double(srois.END_TIME)
  
  case mode of
    1: begin
      nc = mms_get_roi_distance(roi_time, tc, distance=d)
      if keyword_set(next) then nc += 1
      if keyword_set(previous) then nc -= 1
      return, reform(roi_time[0:1, nc])
    end
    2: begin

      ; Check if overlapped
      ;-----------------------------
      idx = -1
      for n=0,nmax-1 do begin
        lensum = (tr[1]-tr[0]) + (roi_time[1,n]-roi_time[0,n])
        lenrng = max([tr[1],roi_time[1,n]]) - min([tr[0],roi_time[0,n]])
        if (lensum gt lenrng) then idx = [idx,n]; if overlap
        ;print, time_String(roi_time[0,n])+' - '+time_string(roi_time[1,n]),' overlap=',(lensum gt lenrng)
      endfor

      ; If not overlapped, find closest
      ;------------------------------------------
      if (n_elements(idx) eq 1) then begin
        nc0 = mms_get_roi_distance(roi_time, tr[0], distance=d0)
        nc1 = mms_get_roi_distance(roi_time, tr[1], distance=d1)
        nc = (d0 lt d1) ? nc0 : nc1
        idx = [idx,nc]
      endif

      ; Return
      ;---------------
      if n_elements(idx) gt 1 then begin
        idx = idx[1:*]
        num = n_elements(idx)
        return, roi_time[0:1,idx]
      endif else begin
        return, 0
      endelse
    end
  endcase

END  