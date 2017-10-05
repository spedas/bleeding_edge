;+
; NAME:  mms_get_roi
;    
; PURPOSE:
;   To return the ROI timerange closest to the specified time "t".
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
;   MMS> print, time_string(mms_get_roi(['2015-10-01/00:00','2015-10-07/24:00']))
;
;   (2) Find the ROI closest to time 2015-10-02/06:00
;   
;   MMS> print, time_string(mms_get_roi('2015-10-02/06:00'))
;
;   (3) Find the ROI just after 2015-10-02/06:00
;
;   MMS> print, time_string(mms_get_roi('2015-10-02/06:00',/next))
;
;
; CREATED BY: moka in Oct 2015
;
; $LastChangedBy: moka $
; $LastChangedDate: 2016-01-11 11:40:15 -0800 (Mon, 11 Jan 2016) $
; $LastChangedRevision: 19706 $
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

FUNCTION mms_get_roi, t, num, next=next, previous=previous, login_info=login_info
  compile_opt idl2

  ;------------
  ; INITIALIZE
  ;------------
  
  mms_init
  if undefined(t) then t = systime(/utc,/seconds) else t = time_double(t)
  mode = n_elements(t)
  case mode of
    1: tr = [t, t]; force the timerange to be a 2-element array
    2: tr = t
    else: message, '"time" should be either a scalar or a 2-element array.'   
  endcase 
  pad = 3.d0*86400.d0; ROI can be up to 3(?) days away
  tc = 0.5d0*total(tr); center time
  trange = [tr[0]-pad, tr[1]+pad]
  num = 1
  
  ;----------
  ; LOAD
  ;----------
  status = mms_login_lasp(login_info = login_info)
  if status ne 1 then begin
    print, 'Log-in failed'
    return, 0
  endif
  mms_get_abs_fom_files, local_flist, pw_flag, pw_message, trange=trange
  
  if pw_flag ne 0 then return, 0
  nmax = n_elements(local_flist)
  roi_start = 0.d0
  roi_stop = 0.d0
  
  ;----------
  ; SCAN
  ;----------
  
  for n=0,nmax-1 do begin
    restore, local_flist[n]
    if n_tags(FOMstr) gt 3 then begin
      timestamps = mms_tai2unix(FOMstr.TIMESTAMPS)
      ts = timestamps[0]
      te = timestamps[FOMstr.NUMCYCLES-1]+10.d0; end of the last trigger cycle
      if (~keyword_set(next    ) and ~keyword_set(previous)) or $
         ( keyword_set(next    ) and (tr[1] lt ts   ) ) or      $
         ( keyword_set(previous) and (te    lt tr[0]) ) then begin
        roi_start = [roi_start, ts]
        roi_stop  = [roi_stop,  te]
      endif
    endif
  endfor
  
  nmax = n_elements(roi_start)
  if nmax gt 1 then begin
    roi_start = roi_start[1:*]
    roi_stop  = roi_stop[1:*]
    nmax -= 1
  endif else return, 0
  
  ;----------
  ; ANALYZE
  ;----------

  roi_time = dblarr(2,nmax)
  roi_time[0,0:nmax-1] = roi_start
  roi_time[1,0:nmax-1] = roi_stop

  case mode of
    1: begin
      nc = mms_get_roi_distance(roi_time, tc, distance=d)
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
