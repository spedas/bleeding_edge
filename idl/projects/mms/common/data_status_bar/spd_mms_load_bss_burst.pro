; NAME: spd_mms_load_bss_burst
;
; PURPOSE: Displays horizontal color bars indicating burst data that has a status of
;      'COMPLETE&FINISHED'.
;
; KEYWORDS:
;  
;   trange:          time frame for bss
;   include_labels:  set this flag to have the horizontal bars labeled
;
;   See also "spd_mms_load_bss_crib" for examples and mms_load_bss.
;   
; $LastChangedBy: egrimes $
; $LastChangedDate: 2016-01-29 15:05:42 -0800 (Fri, 29 Jan 2016) $
; $LastChangedRevision: 19848 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/common/data_status_bar/spd_mms_load_bss_burst.pro $
;-


PRO spd_mms_load_bss_burst, trange=trange, include_labels=include_labels
  compile_opt idl2
  
  if ~undefined(trange) && n_elements(trange) eq 2 $
    then trange = timerange(trange) $
  else trange = timerange()
  mms_init
  
  ;-------------------
  ; DATA
  ;-------------------
  s = mms_bss_load(trange=trange)
  if n_tags(s) lt 10 then return

  ;-------------------
  ; FIRST POINT
  ;-------------------
  bar_x = trange[0]
  bar_y = !VALUES.F_NAN

  ;-------------------
  ; MAIN LOOP
  ;-------------------
  nan = !VALUES.F_NAN
  Nsegs = n_elements(s.FOM)
  
  for n=0,Nsegs-1 do begin; for each segment
    if s.status[N] EQ 'COMPLETE+FINISHED' then begin
       ss = double(s.start[N])
       se = double(s.stop[N]+10.d0)
       bar_x = [bar_x, ss, ss, se, se]
       bar_y = [bar_y, nan, 0.,0., nan]
    endif
  endfor

  if n_elements(bar_x) gt 1 then begin
    bar_x = bar_x[1:*]
    bar_y = bar_y[1:*]
  endif

  ;-------------------
  ; TPLOT VARIABLE
  ;-------------------
  store_data,'mms_bss_burst',data={x:bar_x, y:bar_y}

  if undefined(include_labels) then panel_size= 0.01 else panel_size=0.09
  if undefined(include_labels) then labels='' else labels=['Burst']
  options,'mms_bss_burst',thick=5,xstyle=4,ystyle=4,yrange=[-0.001,0.001],ytitle='',$
    ticklen=0,panel_size=panel_size,colors=4, labels=labels, charsize=2.

END



