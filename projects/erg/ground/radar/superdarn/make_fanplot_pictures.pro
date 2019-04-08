;+
; PROCEDURE make_fanplot_pictures
;
; :Description:
;		Generate a set of fan plots for specified time period
;
;	:Params:
;    varn:  a tplot variable for which fan plots are generated
;    shhmm: start time in HHMM format for fan plots
;    ehhmm: end time  for fan plots
;    center_glat: a geographic latitude in deg at which a fanplot is centered
;    center_glon: a geographic longitude in deg at which a fanplot is centered
;    gscatmaskoff: set to prevent ground scatter pixels from being filled with grey
;     
;	:Keywords:
;    prefix:  prefix string added to the file path of fan plots
;
; :EXAMPLES:
;   make_fanplot_pictures, 'sd_hok_vlos_bothscat_1', 0230, 0300, prefix='pngdir/sd_hok_'
;
; :Author:
; 	Tomo Hori (E-mail: horit@isee.nagoya-u.ac.jp)
;
; :HISTORY:
; 	2011/07/01: Created
;
; $LastChangedDate: 2019-03-17 21:51:57 -0700 (Sun, 17 Mar 2019) $
; $LastChangedRevision: 26838 $
;-
PRO make_fanplot_pictures, varn, shhmm, ehhmm, prefix=prefix, $
  center_glat=center_glat, center_glon=center_glon, gscatmaskoff=gscatmaskoff, $
  force_scale=force_scale, pixel_scale=pixel_scale, clip=clip, coast=coast 

  ;Check the arguments
  n_par = n_params()
  if n_par ne 3 then begin
    print, 'Usage: '
    print, "    make_fanplot_pictures, 'sd_hok_vlos_bothscat_1', HHMM1, HHMM2"
    print, '     HHMM1: start time, HHMM2: end time'
    return
  endif
  if max(strlen(tnames(varn))) lt 6 then begin
    print, 'Cannot find a tplot var: ', varn
    return
  endif
  if ~keyword_set(prefix) then prefix=''
  if strpos(prefix, '/') ne -1 or strpos(prefix,'\') $
    then mkdir=1 else mkdir=0
  
  get_timespan, tr & ts = tr[0]
  shh = shhmm / 100 & smm = shhmm mod 100 
  ehh = ehhmm / 100 & emm = ehhmm mod 100 
  stime = time_string(ts, tfor='YYYY-MM-DD')+'/'+string(shh,smm,'(I2.2,":",I2.2)')
  etime = time_string(ts, tfor='YYYY-MM-DD')+'/'+string(ehh,emm,'(I2.2,":",I2.2)')
  stime = time_double(stime) & etime = time_double(etime) 
  
  i = 0L
  for time=stime, etime, 60. do begin
    map2d_time, time
    plot_map_sdfit, varn, coast=coast,$
      clip=clip, center_glat=center_glat,center_glon=center_glon, $
      /mltlabel, $
      gscatmaskoff=gscatmaskoff, force_scale=force_scale,$
      pixel_scale=pixel_scale
    
    strhhmm = time_string(time, tfor='hhmm')
    filename = prefix+strhhmm
    ;filename = prefix+string(i,'(I03)')
    makepng, filename, mkdir=mkdir
    i ++
  endfor
  
  

  return
end
