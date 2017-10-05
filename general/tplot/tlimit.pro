;+
;PROCEDURE:   tlimit,t1,t2
;PURPOSE:  defines time range for "tplot"
;	   (tplot must be called first)
;INPUTS:  Starting and Ending times.  These can be string, double (seconds
;   since 1970), or hours since refdate.  If no Input is given then the cursor
;   is used to select times from the most recent time plot.
;KEYWORD:
;	REFDATE:   new TPLOT reference data in seconds (double).
;	FULL:	   use full limits.
;	LAST:	   use the last plot's limits.
;	ZOOM:	   set to a value between 0 (no range in times) and 1 (full
;		   time range) to zoom in on the center of the time range.
;	WINDOW:    window in which to plot new time range.
;	OLD_TVARS: use this to pass an existing tplot_vars structure and
;		   override the one in the tplot_com common block.  This
;		   can be used to select which window and set of data to
;		   define a time range in.
;	NEW_TVARS: returns the tplot_vars structure created when plotting
;		   the newly defined time range.
;	DAYS, HOURS, MINUTES, SECONDS: passed to "ctime" for cursor input of
;		   time range.
;       SILENT     If true, don't print output with x/y values under cursor.
;                  Default value for Windows is silent=1, default for others is
;                  silent = 0.
;EXAMPLES:
;   tlimit                     ; Use the cursor
;   tlimit,'12:30','14:30'
;   tlimit, 12.5, 14.5
;   tlimit,t,t+3600            ; t must be set previously
;   tlimit,/FULL               ; full limits
;   tlimit,/LAST               ; previous limits
;
;CREATED BY:	Davin Larson
;FILE:  tlimit.pro
;VERSION:  1.26
;LAST MODIFICATION:  98/08/06
;-
pro tlimit,d1,d2,  $
days = days, $
Hours = hours, $
minutes = minutes, $
seconds = seconds, $
FULL = full,  $
LAST = last,  $
ZOOM = zoom,  $
REFDATE = refdate, $
OLD_TVARS = old_tvars, $
NEW_TVARS = new_tvars, $
WINDOW = window, $
SILENT = silent,$
current = current

@tplot_com.pro

if keyword_set(old_tvars) then tplot_vars = old_tvars
if size(/type,refdate) eq 7 then str_element,tplot_vars,'options.refdate',$
	refdate,/add_replace

; if silent keyword is not explicitly set or set to zero, default behavior
; is silent for windows, not silent for others.
if size(/type, silent) eq 0 then silent = !version.os_family eq 'Windows'

n = n_params()
str_element,tplot_vars,'options.trange',trange
str_element,tplot_vars,'options.trange_full',trange_full
str_element,tplot_vars,'settings.trange_old',trange_old
str_element,tplot_vars,'settings.time_scale',time_scale
str_element,tplot_vars,'settings.time_offset',time_offset

temp       = trange
tpv_set_tags = tag_names( tplot_vars.settings)
idx = where( tpv_set_tags eq 'X', icnt)
if icnt gt 0 then begin
	tr = tplot_vars.settings.x.crange * time_scale + time_offset
endif else begin
	return
endelse

;tr         = tplot_vars.settings.x.crange * time_scale + time_offset

if keyword_set(zoom) then begin
   tmid = (tr[0]+tr[1])/2
   tdif = (tr[1]-tr[0])/2
   trange = tmid+ zoom*[-tdif,tdif]
   n = -1
endif

if keyword_set(full) then begin
  trange = trange_full
  n = -1
endif

if keyword_set(last) then begin
  trange = trange_old
  n = -1
endif

if keyword_set(current) then begin
  trange = current * 60 * [-.95,.05] + systime(1)
  n=-1
endif

if n eq 0 then begin
  ctime,t,npoints=2,prompt="Use cursor to select a begin time and an end time",$
    hours=hours,minutes=minutes,seconds=seconds,days=days,silent=silent
  if n_elements(t) ne 2 then return
  t1 = t[0]
  t2 = t[1]
  delta = tr[1] - tr[0]
  case 1 of
    (t1 lt tr[0]) and (t2 gt tr[1]):  trange = trange_full      ; full range
    (t1 gt tr[1]) and (t2 gt tr[1]):  trange = tr + delta       ; pan right
    (t1 lt tr[0]) and (t2 lt tr[0]):  trange = tr - delta       ; pan left
    t2 lt t1:                         trange = trange_old       ; last limits
;    t2 gt tr(1):                      trange = tr + (t1-tr(0))  ; pan right
;    t1 lt tr(0):                      trange = tr + (tr(1)-t2)  ; pan left
    else:                             trange = [t1,t2]          ; new range
  endcase
endif
if n eq 1 then begin
    if n_elements(d1) eq 2 then trange = time_double(d1) $
    else trange = [time_double(d1),time_double(d1)+tr[1]-tr[0]]
endif
if n eq 2 then   trange = time_double([d1,d2])

str_element,tplot_vars,'options.trange',trange,/add_replace
str_element,tplot_vars,'options.trange_full',trange_full,/add_replace
str_element,tplot_vars,'settings.trange_old',trange_full,/add_replace
str_element,tplot_vars,'settings.window',old_window
if keyword_set(window) then wi, window
tplot,window=window
str_element,tplot_vars,'settings.trange_old',temp,/add_replace
new_tvars = tplot_vars

return
end

