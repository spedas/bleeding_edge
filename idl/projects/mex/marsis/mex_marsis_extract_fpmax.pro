;+
; PROCEDURE:
;       mex_marsis_extract_fpmax
; PURPOSE:
;       Extracts f_p(max) from ionospheric echoes and generates a csv file containing:
;        YYYYMMDD, hhmmss.fff, unix_time, f_p(max) [MHz], TD_(max) [ms], H'_(max) [km]
; CALLING SEQUENCE:
;       mex_marsis_extract_fpmax
; CREATED BY:
;       Yuki Harada on 2024-01-25
;
; $LastChangedBy: $
; $LastChangedDate: $
; $LastChangedRevision: $
; $URL: $
;-

pro mex_marsis_extract_fpmax, wfilename=wfilename,psym_thld=psym_thld, frange=frange

dprint,'============= Select a time range ============='
ctime,tr,np=2

if size(psym_thld,/type) eq 0 then psym_thld = 1

@mex_marsis_com
times = marsis_ionograms.time

wt = where( times gt tr[0] and times lt tr[1] , nwt )
if nwt eq 0 then return

if ~keyword_set(wfilename) then wfilename = 'fpmax_'+time_string(times[wt[0]],tf='YYYYMMDDhhmmss')+'-'+time_string(times[wt[nwt-1]],tf='YYYYMMDDhhmmss')+'.csv'

;;; set up a window
dsize = get_screen_size()
window, /free, xsize=dsize[0]/2., ysize=dsize[1]*2./3.,xpos=0., ypos=dsize[1]/3.
Iwin = !d.window

openw,unit,wfilename,/get_lun
for it=0,nwt-1 do begin
   dprint,'============= Move the cursor and left-click if the cursor overlaps the top of an ionospheric echo ============='

   ok = 0
   while ~ok do begin
      mex_marsis_snap,time=time_string(times[wt[it]]),win=Iwin,/keep,psym_thld=psym_thld, $
                      aalt_return=aalt,td_return=td,freq_return=freq,sdens_return=sdens,xrange=frange
      x = !values.f_nan & y = !values.f_nan & fpmax = !values.f_nan & td_max = !values.f_nan & aalt_max = !values.f_nan
      mex_marsis_crosshairs,x,y,/oneclick
      if finite(x[-1]) and finite(y[-1]) then begin
         tmp = min(abs(x[-1]-freq),ifreq)
         tmp = min(abs(y[-1]-td),itd)
         fpmax = freq[ifreq]
         td_max = td[itd]
         aalt_max = aalt[itd]
         plots,fpmax,td_max,color=1,psym=4,symsize=2,thick=2
      endif
      flag = ''
      read, flag, prompt='Enter 1 if okay: '
      if flag eq '1' then ok = 1 ;- finish
   endwhile
   
   printf,unit,time_string(times[wt[it]],tf='YYYYMMDD')+', '+time_string(times[wt[it]],tf='hhmmss.fff')+', ' $
          +string(times[wt[it]],f='(f24.4)')+', '+string(fpmax,format='(f7.4)')+', '+string(td_max,format='(f7.4)')+', '+string(aalt_max,format='(f13.4)')
   wait,.5
endfor
free_lun,unit


end
