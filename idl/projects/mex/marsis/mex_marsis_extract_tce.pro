;+
; PROCEDURE:
;       mex_marsis_extract_tce
; PURPOSE:
;       Extracts Tce from electron cyclotron echoes and generates a csv file containing:
;        YYYYMMDD, hhmmss.fff, unix_time, Tce [ms]
; CALLING SEQUENCE:
;       mex_marsis_extract_tce
; CREATED BY:
;       Yuki Harada on 2024-01-19
;
; $LastChangedBy: $
; $LastChangedDate: $
; $LastChangedRevision: $
; $URL: $
;-

pro mex_marsis_extract_tce, wfilename=wfilename,_extra=_ex

dprint,'============= Select a time range ============='
ctime,tr,np=2


@mex_marsis_com
times = marsis_ionograms.time

wt = where( times gt tr[0] and times lt tr[1] , nwt )
if nwt eq 0 then return

if ~keyword_set(wfilename) then wfilename = 'tce_'+time_string(times[wt[0]],tf='YYYYMMDDhhmmss')+'-'+time_string(times[wt[nwt-1]],tf='YYYYMMDDhhmmss')+'.csv'

;;; set up a window
dsize = get_screen_size()
window, /free, xsize=dsize[0]/2., ysize=dsize[1]*2./3.,xpos=0., ypos=dsize[1]/3.
Iwin = !d.window

openw,unit,wfilename,/get_lun
for it=0,nwt-1 do begin
   dprint,'============= (1) Move the cursor and left-click if the horizontal lines match the electron cyclotron echoes ============='
   dprint,'============= (2) You can do the procedure (1) many times ============='
   dprint,'============= (3) Right-click once (1)-(2) is done ============='
   dprint,'============= (4) Repeat (1)-(3) for the next ionogram ============='
   mex_marsis_snap,time=time_string(times[wt[it]]),win=Iwin,/keep,_extra=_ex
   y = !values.f_nan
   mex_marsis_crosshairs2,x,y
   printf,unit,time_string(times[wt[it]],tf='YYYYMMDD')+', '+time_string(times[wt[it]],tf='hhmmss.fff')+', ' $
          +string(times[wt[it]],f='(f24.4)')+', '+string(y[-1],format='(f7.4)')
   wait,.5
endfor
free_lun,unit


end
