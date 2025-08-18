;+
; NAME:
;       thm_gmag_stackplot_intervals.pro
;
; PURPOSE:
;       To create 3 PNG files displaying the H,D and Z components of the magnetic field
;	from multiple GBO stations out of GMAG data that is stored in CDF file.
;
; CALLING SEQUENCE:
;       thm_gmag_stackplot, date, duration, stack_shift=stack_shift, no_expose=no_expose, make_png=make_png
;
; INPUTS:
;       date: The start of the time interval to be plotted. (Format: 'YYYY-MM-DD/hh:mm:ss')
;	duration: The length of the interval being plotted. (Floating point number of days -> 12hr=0.5), default=1
;	stack_shift: Space between stations on the y-axis (units are nanotesla), default=50
;	no_expose: Set this keyword to prevent the plot from being printed to the screen.
;	make_png: Set this keyword to make the 3 PNG files.
;	max_deviation:  Large spikes in the data (probably gliches) can screw up the y-axis scales.  This keyword allows
;		you to set the maximum deviation the data can go from the median; points that exceed this value are omitted.
;		The default value is plus or minus 1500 nT
;	no_data_load:  This keyword prevents new data from being loaded; the routine will try to plot existing data if it exists.
;	hi_lat:  Set this keyword to plot high latitude stations (above 49 degrees)
;	lo_lat:  Set this keyword to plot low latitude stations (below 49 below)
;
; OUTPUTS:
;       None, but it creates 3 PNG files in the directory that IDL is being run.
;
; PROCEDURE:
;       Read in data from CDF files; plot the data using tplot.pro routines;
;       make PNG files with makegif.pro routine
;
; EXAMPLE:
;       thm_gmag_stackplot, '2006-11-11',1,/make_png, max_deviation=1500, stack_shift=200.
;
; MODIFICATION HISTORY:
;       Written by:       Matt Davis
;       October 23, 2006     Initial version
;       Added dydt_spike_test, 7-apr-2008, jmm, jimm@ssl.berkeley.edu
;
;NOTE: This program is still in development.  Features to be added:
;	-generalizing the routine
;
;-

pro thm_gmag_stackplot_intervals, date_in, duration, stack_shift=stack_shift, $
                                  make_png = make_png, max_deviation = max_deviation, $
                                  no_data_load = no_data_load, hi_lat = hi_lat, lo_lat = lo_lat, $
                                  plot_dir = plot_dir, _extra = _extra


compile_opt idl2
;________________________________________________________________________________________________
;find all gmag CDF files on given date and put data into tplot variables
;________________________________________________________________________________________________

if not keyword_set(date_in) then begin
   dprint,  'You must specify a date. (Format : YYYY-MM-DD/HH:MM:SS)'
   return
endif else date = time_string(date_in) ;allow for non-string date

if not keyword_set(duration) then duration=1.
if keyword_set(hi_lat) then a=0 else a=1      ; do high lat
if keyword_set(lo_lat) then b=1 else b=0      ; do low lat
if a gt b then begin            ; no keywords then do both
   a = 0
   b = 1
endif

if not keyword_set(stack_shift) then set_default_shift=1 else set_default_shift=0

start_time=time_double(date)
end_time=start_time+86400.*duration

timespan,date,duration
if not keyword_set(no_data_load) then begin
   ;delete all gmag data
   del_data, 'thg_mag_*'
   thm_load_gmag, /verbose, site='????'
   thm_load_gmag, site = ['fcc', 'cmo', 'naq', 'lrv']
   ;If NRSQ was loaded, take it out -- it's the same as NAQ
   del_data, '*nrsq*'
   del_data, '*pang*'
   del_data, '*iglo*'
endif
; add low lat stations
ll_sites=['dva', 'gua', 'hon', 'bsl', 'dtx', 'tuc', 'frn', 'frd', 'dmo', 'col', 'bou', $
  'dbo', 'doh', 'dct', 'dat', 'dme', 'dhe', 'nes', 'kapu', 'pina', 'sept', $
  'roth', 'atha', 'shu', 'gill', 'nain', 'sit']
thm_load_gmag, site=ll_sites  

tplot_names

;________________________________________________________________________________________________
;check that there is some valid data
;________________________________________________________________________________________________
tplotvars=tnames('thg_mag_???? thg_mag_???')
if tplotvars[0] eq '' then begin
  dprint,  'Appropriate tplot variables could not be found!'
  dprint,  'Searched for "thg_mag_????"'
  dprint,  'Stackplot program was aborted.'
  return
endif

;________________________________________________________________________________________________
;check for spikes in data then save this tplot var so they don't have to be reloaded
;________________________________________________________________________________________________
for i=0,n_elements(tplotvars)-1 do begin
  get_data, tplotvars[i],data=dd,dlimits=dl,limits=l
  store_data, tplotvars[i]+'_orig',data=dd,dlimits=dl,limits=l
endfor
tplotvars_orig=tnames('thg_mag_*_orig')
stations=['filler']

;________________________________________________________________________________________________
;set up for time intervals
;1 24 hour plot, 4 6 hr plots, 12 2 hr plots
;________________________________________________________________________________________________
start_time=time_double(date)
end_time=start_time + 86400.
hr_st = [0, 6*indgen(4), 2*indgen(12)]
dhr = [24, 6+intarr(4), 2+intarr(12)]
hr_en = hr_st+dhr
;strings for filenames
hr_ststr = string(hr_st, format='(i2.2)')
hr_enstr = string(hr_en, format='(i2.2)')
file_lbl = hr_ststr+hr_enstr
start_times=start_time+hr_st*3600.
end_times=start_times+dhr*3600.

;________________________________________________________________________________________________
;Now start the loop for the hour intervals
;________________________________________________________________________________________________

for k=0,n_elements(dhr)-1 do begin

  ;  timespan, date, duration
  timespan, start_times[k], dhr[k], /hour
  stations=['filler']

  ;________________________________________________________________________________________________
  ;this section is in place to make sure that we are only looking at data in the time range specified,
  ;previously loaded gmag data from different time range is ignored
  ;also use this loop to despike the data
  ;________________________________________________________________________________________________
  for i=0,n_elements(tplotvars_orig)-1 do begin
    	time_clip, tplotvars_orig[i], start_times[k], end_times[k], newname=tplotvars[i]
    	get_data,tplotvars[i],data=dd,dlimits=dl
    	tn=tag_names(dl.cdf.vatt)
    	tidx=where(strlowcase(tn) eq 'station_latitude' or strlowcase(tn) eq 'station_longitude', ncnt)
    	if ncnt eq 0 then continue
    	index_time=where(dd.x ge start_time and dd.x le end_time)
    	if index_time[0] ne -1 then begin
    	   dd.x=dd.x[index_time]
    	   dd.y=dd.y[index_time,*]
         stations_tmp = strsplit(tplotvars[i], '_', /extract)
         stations = [stations, stations_tmp[2]]
         if n_elements(dd.x) LT 5 then continue
         t = dd.x & dt = t[1:*]-t
         median_dt = median(dt)
         If(median_dt Gt 1.0) Then degap_dt = 10.0*median_dt Else degap_dt = 1.0
         bad_flag0 = dydt_spike_test(dd.x, dd.y[*, 0], dydt_lim = 100.0, $
                                    degap_dt = degap_dt, degap_margin = 1.0)
         bad_flag1 = dydt_spike_test(dd.x, dd.y[*, 1], dydt_lim = 100.0, $
                                    degap_dt = degap_dt, degap_margin = 1.0)
         bad_flag2 = dydt_spike_test(dd.x, dd.y[*, 2], dydt_lim = 100.0, $
                                     degap_dt = degap_dt, degap_margin = 1.0)
         bad = where(bad_flag0+bad_flag1+bad_flag2 Gt 0, nbad)         
         if (nbad gt 0) then begin
            dd.y[bad, *] = !values.f_nan
            store_data, tplotvars[i], data = dd
         endif
       endif
  endfor
    
  stations=stations[1:*]

  ;________________________________________________________________________________________________
  ;sort stations by longitude
  ;________________________________________________________________________________________________
  
  lats=fltarr(n_elements(stations))
  lons=fltarr(n_elements(stations))
  for i=0,n_elements(stations)-1. do begin
  	get_data,'thg_mag_'+stations[i],dlimits=dl
  	lats[i]=float(dl.cdf.vatt.station_latitude)
  	lons[i]=float(dl.cdf.vatt.station_longitude)
  endfor
  
  nidx=where(lons LT 0., ncnt)
  if ncnt gt 0 then lons[nidx]=lons[nidx]+360.
  
  hi_index=where(lats ge 49)
  lo_index=where(lats lt 49)
  If (hi_index[0] Ne -1) Then Begin ;jmm, 9-oct-2007, handle cases with no hi or lo latitudes correctly
     hi_stat = stations[hi_index]
     hi_lon = lons[hi_index]
     ;hi_lat_lon_index = reverse(sort(hi_lon))
     hi_lat_lon_index = sort(hi_lon)
     hi_stat = hi_stat[hi_lat_lon_index]
     skip_hi = 0  ; set a flag to be checked in the loop below
  Endif Else Begin
     hi_stat = -1
     hi_lon = -1
     hi_lat_lon_index = -1
     skip_hi = 1  ; set a flag to be checked in the loop below
  Endelse
  If (lo_index[0] Ne -1) Then Begin
     lo_stat = stations[lo_index]
     lo_lon = lons[lo_index]
     lo_lat_lon_index = sort(lo_lon)
     lo_stat = lo_stat[lo_lat_lon_index]
     skip_lo = 0  ; set a flag to be checked in the loop below
  Endif Else Begin
     lo_stat = -1
     lo_lon = -1
     lo_lat_lon_index = -1
     skip_lo = 1  ; set a flag to be checked in the loop below
  Endelse
  
  ;________________________________________________________________________________________________
  ;manipulate data into tplot variables for "relative" stack plots
  ;________________________________________________________________________________________________
  
  for w=a,b do begin
  
    ; Do we need to skip this latitude range?
    ; 
    ; The original code assigned hi_stat or lo_stat to the 'stations' variable.
    ; But 'stations' is used outside this loop, and we don't want to clobber it
    ; for the next iteration.  I changed this to a local variable loop_stations,
    ; which seems to work.
    ; JWL 12-30-2023
    
    if w eq 0 then begin
      loop_stations = hi_stat
      skip = skip_hi
    endif else begin
      loop_stations = lo_stat
      skip = skip_lo
    endelse
  
    if skip eq 1 then continue  ; skip processing if no stations available
    
    ;create tplot variables of components
    num_elements = n_elements(loop_stations)
    h_axis_range = dblarr(2)
    d_axis_range = dblarr(2)
    z_axis_range = dblarr(2)
    if set_default_shift eq 1 and w eq 0 then stack_shift = 500.
    if set_default_shift eq 1 and w eq 1 then stack_shift = 50.
    if keyword_set(max_deviation) then begin ;changed the clipping parameters, 9-oct-2007, jmm
      if (n_elements(max_deviation) Eq 1) then begin
        max_dev = [-max_deviation, max_deviation]
      endif else max_dev = max_deviation
    endif else max_dev = [-1500., 1500.]
    max_dev = [min(max_dev), max(max_dev)]
  
    for i = 0, num_elements-1 do begin
      get_data, 'thg_mag_'+loop_stations[i], data = dd
      index_time = where(dd.x ge start_time and dd.x le end_time)
      themedian = strcompress(string(median(dd.y[index_time, 0], /even), format = '(f10.1)'), /remove_all)
      hdata = dd.y[index_time, 0]-median(dd.y[index_time, 0], /even)
      xclip, max_dev[0], max_dev[1], hdata, /clip_adjacent
      hdata = hdata+stack_shift*i
      store_data, 'thg_mag_'+loop_stations[i]+'_h_rel', data = {x:dd.x[index_time], y:hdata}, $
        limits = {labels:[strupcase(loop_stations[i])+'='+string(themedian)]}
  
      themedian = strcompress(string(median(dd.y[index_time, 1], /even), format = '(f10.1)'), /remove_all)
      ddata = dd.y[index_time, 1]-median(dd.y[index_time, 1], /even)
      xclip, max_dev[0], max_dev[1], ddata, /clip_adjacent
      ddata = ddata+stack_shift*i
      store_data, 'thg_mag_'+loop_stations[i]+'_d_rel', data = {x:dd.x[index_time], y:ddata}, $
        limits = {labels:[strupcase(loop_stations[i])+'='+string(themedian)]}
  
      themedian = strcompress(string(median(dd.y[index_time, 2], /even), format = '(f10.1)'), /remove_all)
      zdata = dd.y[index_time, 2]-median(dd.y[index_time, 2], /even)
      xclip, max_dev[0], max_dev[1], zdata, /clip_adjacent
      zdata = zdata+stack_shift*i
      store_data, 'thg_mag_'+loop_stations[i]+'_z_rel', data = {x:dd.x[index_time], y:zdata}, $
        limits = {labels:[strupcase(loop_stations[i])+'='+string(themedian)]}
    
      if max(hdata) gt h_axis_range[1] then h_axis_range[1] = max(hdata)
      if max(ddata) gt d_axis_range[1] then d_axis_range[1] = max(ddata)
      if max(zdata) gt z_axis_range[1] then z_axis_range[1] = max(zdata)
      if min(hdata) lt h_axis_range[0] then h_axis_range[0] = min(hdata)
      if min(ddata) lt d_axis_range[0] then d_axis_range[0] = min(ddata)
      if min(zdata) lt z_axis_range[0] then z_axis_range[0] = min(zdata)
  	
    endfor

    ;________________________________________________________________________________________________
    ;create buffer tplot variables
    ;the purpose of these buffers is to 'trick' the plot routines into formatting the stackplots
    ;the way we want, it can be more reliable (as in doing what we want rather than what we tell it)
    ;than explicitly setting the plot format
    ;it also allows for the easy placement of the 'Median (nT)' label
    ;________________________________________________________________________________________________
  
    bth = dd.y[index_time, 0]
    bbh = dd.y[index_time, 0] 
    btd = dd.y[index_time, 1]
    bbd = dd.y[index_time, 1]
    btz = dd.y[index_time, 2]
    bbz = dd.y[index_time, 2]
  
    bth[*] = h_axis_range[1]+stack_shift
    bbh[*] = h_axis_range[0]-stack_shift
    btd[*] = d_axis_range[1]+stack_shift
    bbd[*] = d_axis_range[0]-stack_shift
    btz[*] = z_axis_range[1]+stack_shift
    bbz[*] = z_axis_range[0]-stack_shift

    store_data, 'BUFFER_TOP_H', data = {x:dd.x[index_time], y:bth}
    store_data, 'BUFFER_BOT_H', data = {x:dd.x[index_time], y:bbh}
    store_data, 'BUFFER_TOP_D', data = {x:dd.x[index_time], y:btd}
    store_data, 'BUFFER_BOT_D', data = {x:dd.x[index_time], y:bbd}
    store_data, 'BUFFER_TOP_Z', data = {x:dd.x[index_time], y:btz}
    store_data, 'BUFFER_BOT_Z', data = {x:dd.x[index_time], y:bbz}
  
    options, 'BUFFER_TOP_H', 'ytitle', ''
    options, 'BUFFER_BOT_H', 'ytitle', ''
    options, 'BUFFER_TOP_D', 'ytitle', ''
    options, 'BUFFER_BOT_D', 'ytitle', ''
    options, 'BUFFER_TOP_Z', 'ytitle', ''
    options, 'BUFFER_BOT_Z', 'ytitle', ''
  
    options, 'BUFFER_TOP_H', 'labels', ['Median (nT)']
    options, 'BUFFER_TOP_D', 'labels', ['Median (nT)']
    options, 'BUFFER_TOP_Z', 'labels', ['Median (nT)']

    ;________________________________________________________________________________________________
    ;Set various plotting options
    ;________________________________________________________________________________________________
  
    tplotvars_h = ['filler']
    tplotvars_d = ['filler']
    tplotvars_z = ['filler']

    for i = 0, n_elements(loop_stations)-1 do begin
      tplotvars_h = [tplotvars_h, tnames('thg_mag_'+loop_stations[i]+'_h_rel')]
      tplotvars_d = [tplotvars_d, tnames('thg_mag_'+loop_stations[i]+'_d_rel')]
      tplotvars_z = [tplotvars_z, tnames('thg_mag_'+loop_stations[i]+'_z_rel')]
    endfor
  
    store_data, 'BH', data = [tplotvars_h[1:*], 'BUFFER_TOP_H', 'BUFFER_BOT_H']
    store_data, 'BD', data = [tplotvars_d[1:*], 'BUFFER_TOP_D', 'BUFFER_BOT_D']
    store_data, 'BZ', data = [tplotvars_z[1:*], 'BUFFER_TOP_Z', 'BUFFER_BOT_Z']
  
    options, 'BH', 'ytickformat', '(a1)' ; this gets rid of the y-axis numbering
    options, 'BD', 'ytickformat', '(a1)' ; this gets rid of the y-axis numbering
    options, 'BZ', 'ytickformat', '(a1)' ; this gets rid of the y-axis numbering
    
    num_hticks = (h_axis_range[1]+stack_shift)/100. - (h_axis_range[0]-stack_shift)/100.
    h_factor = (byte(num_hticks/30.)+1)
    num_hticks = byte(num_hticks/h_factor)-1
    num_dticks = (d_axis_range[1]+stack_shift)/100. - (d_axis_range[0]-stack_shift)/100.
    d_factor = (byte(num_dticks/30.)+1)
    num_dticks = byte(num_dticks/d_factor)-1
    num_zticks = (z_axis_range[1]+stack_shift)/100. - (z_axis_range[0]-stack_shift)/100.
    z_factor = (byte(num_zticks/30.)+1)
    num_zticks = byte(num_zticks/z_factor)-1
  
    options, 'BH', 'yticks', num_hticks
    options, 'BD', 'yticks', num_dticks
    options, 'BZ', 'yticks', num_zticks
  
    hy_pos_ticks = findgen(byte( (h_axis_range[1]+stack_shift)/(100.*h_factor) +1.))*100.*h_factor
    dy_pos_ticks = findgen(byte( (d_axis_range[1]+stack_shift)/(100.*d_factor) +1.))*100.*d_factor
    zy_pos_ticks = findgen(byte( (z_axis_range[1]+stack_shift)/(100.*z_factor) +1.))*100.*z_factor
  
    hy_neg_ticks = -100.*h_factor*reverse(findgen(byte( abs(h_axis_range[0]-stack_shift)/(100.*h_factor) +1.)))
    dy_neg_ticks = -100.*d_factor*reverse(findgen(byte( abs(d_axis_range[0]-stack_shift)/(100.*d_factor) +1.)))
    zy_neg_ticks = -100.*z_factor*reverse(findgen(byte( abs(z_axis_range[0]-stack_shift)/(100.*z_factor) +1.)))
  
    if n_elements(hy_pos_ticks) gt 1 then hy_tickvalues = [hy_neg_ticks, hy_pos_ticks[1:*]] else hy_tickvalues = [hy_neg_ticks]
    if n_elements(dy_pos_ticks) gt 1 then dy_tickvalues = [dy_neg_ticks, dy_pos_ticks[1:*]] else dy_tickvalues = [dy_neg_ticks]
    if n_elements(zy_pos_ticks) gt 1 then zy_tickvalues = [zy_neg_ticks, zy_pos_ticks[1:*]] else zy_tickvalues = [zy_neg_ticks]

    options, 'BH', 'ytickv', hy_tickvalues
    options, 'BD', 'ytickv', dy_tickvalues
    options, 'BZ', 'ytickv', zy_tickvalues
  
    options, 'BH', 'yminor', 10
    options, 'BD', 'yminor', 10
    options, 'BZ', 'yminor', 10
  
    options, 'BH', 'ytitle', 'Scale='+strcompress(string(100*h_factor, format = '(f10.0)'))+'nT/major, '+strcompress(string(10*h_factor, format = '(f10.0)'))+'nT/minor tickmark'
    options, 'BD', 'ytitle', 'Scale='+strcompress(string(100*d_factor, format = '(f10.0)'))+'nT/major, '+strcompress(string(10*d_factor, format = '(f10.0)'))+'nT/minor tickmark'
    options, 'BZ', 'ytitle', 'Scale='+strcompress(string(100*z_factor, format = '(f10.0)'))+'nT/major, '+strcompress(string(10*z_factor, format = '(f10.0)'))+'nT/minor tickmark'

    ;________________________________________________________________________________________________
    ;make plots/PNG files
    ;________________________________________________________________________________________________
    original_device = !d.name     ;save to reset
    If keyword_set(make_png) Then Begin
      set_plot, 'z'
      device, set_resolution = [800, 800]
    Endif Else Begin
      osf = strupcase(!version.os_family)
      If(osf Eq 'WINDOWS') Then set_plot, 'win' Else set_plot, 'x'
    Endelse
  
    tplot_options, 'region', [0.00, 0.00, 0.95, 1.]
    !p.color = 0
    !p.background = 255
    !p.charsize = 1.2
    time_stamp, /off
  
    date_compress = strcompress(strmid(date, 0, 4)+strmid(date, 5, 2)+strmid(date, 8, 2), /remove_all)

    if(keyword_set(plot_dir)) then pdir = spd_addslash(plot_dir) else pdir = './'
    ;if k ne 0 then tlimit, start_times[k], end_times[k]
  
    if w eq 0 then begin
  
      thetitle = string('Ground Magnetometer Data : High Latitude : H Component')
      if keyword_set(make_png) then begin
        tplot, 'BH', title = thetitle
        makepng, pdir+'thg_l2_mag_hhla_'+string(date_compress)+'_'+file_lbl[k]+'_v01', /no_expose
        print, pdir+'thg_l2_mag_hhla_'+string(date_compress)+'_'+file_lbl[k]+'_v01.png'    
      endif else begin
        window, 3*w+0, xsize = 600, ysize = 600
        tplot, 'BH', title = thetitle, window = 3*w+0
      endelse      

      thetitle = string('Ground Magnetometer Data : High Latitude : D Component')
      if keyword_set(make_png) then begin
        tplot, 'BD', title = thetitle
        makepng, pdir+'thg_l2_mag_dhla_'+string(date_compress)+'_'+file_lbl[k]+'_v01', /no_expose
        print, pdir+'thg_l2_mag_dhla_'+string(date_compress)+'_'+file_lbl[k]+'_v01.png'
      endif else begin
        window, 3*w+1, xsize = 600, ysize = 600
        tplot, 'BD', title = thetitle, window = 3*w+1
      endelse

      thetitle = string('Ground Magnetometer Data : High Latitude : Z Component')
      if keyword_set(make_png) then begin
        tplot, 'BZ', title = thetitle
        makepng, pdir+'thg_l2_mag_zhla_'+string(date_compress)+'_'+file_lbl[k]+'_v01', /no_expose
        print, pdir+'thg_l2_mag_zhla_'+string(date_compress)+'_'+file_lbl[k]+'_v01.png'
      endif else begin
        window, 3*w+2, xsize = 600, ysize = 600
        tplot, 'BZ', title = thetitle, window = 3*w+2
      endelse
      
    endif else begin

      thetitle = string('Ground Magnetometer Data : Low Latitude : H Component')
      if keyword_set(make_png) then begin
        tplot, 'BH', title = thetitle
        makepng, pdir+'thg_l2_mag_hlla_'+string(date_compress)+'_'+file_lbl[k]+'_v01', /no_expose
        print, pdir+'thg_l2_mag_hlla_'+string(date_compress)+'_'+file_lbl[k]+'_v01.png'
      endif else begin
        window, 3*w+0, xsize = 600, ysize = 600
        tplot, 'BH', title = thetitle, window = 3*w+0
      endelse
  
      thetitle = string('Ground Magnetometer Data : Low Latitude : D Component')
      if keyword_set(make_png) then begin
        tplot, 'BD', title = thetitle
        makepng, pdir+'thg_l2_mag_dlla_'+string(date_compress)+'_'+file_lbl[k]+'_v01', /no_expose
        print, pdir+'thg_l2_mag_dlla_'+string(date_compress)+'_'+file_lbl[k]+'_v01.png'
      endif else begin
        window, 3*w+1, xsize = 600, ysize = 600
        tplot, 'BD', title = thetitle, window = 3*w+1
      endelse
  
      thetitle = string('Ground Magnetometer Data : Low Latitude : Z Component')
      if keyword_set(make_png) then begin
        tplot, 'BZ', title = thetitle
        makepng, pdir+'thg_l2_mag_zlla_'+string(date_compress)+'_'+file_lbl[k]+'_v01', /no_expose
        print, pdir+'thg_l2_mag_zlla_'+string(date_compress)+'_'+file_lbl[k]+'_v01.png'
      endif else begin
        window, 3*w+2, xsize = 600, ysize = 600
        tplot, 'BZ', title = thetitle, window = 3*w+2
      endelse      
    endelse

  endfor

endfor 

print, 'done'
;--------------------------                         
set_plot, original_device
close, /all

end

