;+
; mms_fpi_dist_slice_comparison_crib.pro
;
; This version is meant to work with v3.0.0+ of the FPI CDFs
;
;
; Suggestions for this crib sheet:
;     https://github.com/spedas/bleeding_edge/issues
;
;  changed ion burst mode time range   SAB
;  
; $LastChangedBy: egrimes $
; $LastChangedDate: 2023-08-14 12:51:35 -0700 (Mon, 14 Aug 2023) $
; $LastChangedRevision: 31999 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/examples/advanced/mms_fpi_dist_slice_comparison_crib.pro $
;-

start_time = systime(/sec)
;setup
;---------------------------------------------
read, 'for FPI data rate input 0 for brst, 1 for fast:', irate ;SAB
probe='1'
read,'input probe #:',probe
if probe lt 1 or probe gt 4 then probe=1
read,'input 0 for FPI electrons, 1 for FPI ions:',ispecies
if ispecies eq 0 then species='e' else species='i'

if irate eq 0 then begin ;SAB
	data_rate = 'brst'
	fgm_data_rate = 'brst'
	;trange = ['2015-10-16/13:06:00', '2015-10-16/13:06:00.02']
	trange = ['2015-10-16/13:07:02.220', '2015-10-16/13:07:02.250']
	if species eq 'i' then trange = ['2015-10-16/13:06:00', '2015-10-16/13:06:00.2']
endif else BEGIN ;SAB
	data_rate = 'fast'
	fgm_data_rate = 'srvy'
	trange = ['2015-10-16/13:06:00', '2015-10-16/13:06:5.00'] ;if trange lies within time interval FPI fast, no dist will be returned
endelse ;SAB
help, data_rate, fgm_data_rate

;probe='1' ;SAB
;read,'input probe #:',probe
;if probe lt 1 or probe gt 4 then probe=1
;read,'input 0 for FPI electrons, 1 for FPI ions:',ispecies
;if ispecies eq 0 then species='e' else species='i'
olines=20
geometric = 0
read,'input 1 for geometric scaling or 0:', geometric
resolution=500
read,'input integer resolution (defaults:  2D/3D interpolation: 150, geometric: 500)',resolution
if resolution eq 0 and geometric eq 1 then resolution=500
if resolution eq 0 and geometric eq 0 then resolution=150

;subfolder of current directory to place images
folder = 'slice_test/'

;trange = ['2015-09-1/12:20:09', '2015-09-1/12:20:09.05'] 

coord_sys = 'gse'

level = 'l2'

;load particle, field & support data
;---------------------------------------------
mms_load_fpi, data_rate=data_rate, level=level, datatype='d'+species+'s-dist', $
              probe=probe, trange=trange, min_version='2.2.0' ; don't allow this routine to run on v2.1 CDFs
mms_load_fgm, probe=probe, trange=trange, level='l2', data_rate=fgm_data_rate
mms_load_fpi, data_rate=data_rate, level=level, datatype='d'+species+'s-moms', $
              probe=probe, trange=trange, min_version='2.2.0' ; don't allow this routine to run on v2.1 CDFs


; b-field vector for data within the last 2 weeks (ql)
; bname = 'mms'+probe+'_dfg_srvy_gse_bvec'
; b-field vector for data older than 2 weeks ago (l2pre)
; bname = 'mms'+probe+'_dfg_srvy_l2pre_gse_bvec'
;  b-field vector for L2 data
bname = 'mms'+probe+'_fgm_b_gse_'+fgm_data_rate+'_l2_bvec'
vname = 'mms'+probe+'_d'+species+'s_bulkv_'+coord_sys+'_'+data_rate

;convert particle data to 3D structures
;     'BV':  The x axis is parallel to B field; the bulk velocity defines the x-y plane
;     'BE':  The x axis is parallel to B field; the B x V(bulk) vector defines the x-y plane
;     'xy':  (default) The x axis is along the data's x axis and y is along the data's y axis
;     'xz':  The x axis is along the data's x axis and y is along the data's z axis
;     'yz':  The x axis is along the data's y axis and y is along the data's z axis
;     'xvel':  The x axis is along the data's x axis; the x-y plane is defined by the bulk velocity
;     'perp':  The x axis is the bulk velocity projected onto the plane normal to the B field; y is B x V(bulk)

;---------------------------------------------
name =  'mms'+probe+'_d'+species+'s_dist_'+data_rate
dist = mms_get_fpi_dist(name, trange=time_double(trange), probe = probe, species = species)
errname =  'mms'+probe+'_d'+species+'s_disterr_'+data_rate
distErr = mms_get_fpi_dist(errname, trange=time_double(trange), probe = probe, species = species)


get_data, 'mms'+probe+'_d'+species+'s_numberdensity_'+data_rate, data=density_struct
get_data, 'mms'+probe+'_d'+species+'s_bulkv_'+coord_sys+'_'+data_rate, data=velocity_struct
get_data, 'mms'+probe+'_d'+species+'s_prestensor_'+coord_sys+'_'+data_rate, data=pressure_struct
get_data, 'mms'+probe+'_d'+species+'s_temptensor_'+coord_sys+'_'+data_rate, data=temp_struct

;set slice orientation
; (x parallel to B, y defined by vbulk)
rotation = 'bv'

;normal vectors of slices to be produced
; (xy plane, xz pane, yz plane)
norms = [ [0,0,1], [0,1,0], [1,0,0] ]

; make sure data was loaded
if ~ptr_valid(dist) then stop ; should have thrown an error specifying no data within the range

;initialize window and get plot positions, axis limits
;---------------------------------------------
energyr = minmax((*dist).energy)
vr = 13.8*sqrt(energyr)
if species eq 'e' then vr = vr*sqrt(1836.109)
vmax = max(vr)
vmin = min(vr)
print,'velocity range in km/s:',vr
read,'input max |velocity| in km/s to plot, input 0. for autoscaling:',vmax
if vmax le min(vr) then vr=[-1.,1.]*max(vr) else vr = [-1,1]*vmax
if species eq 'e' then zrange = [1.0e-29, 1.0e-25]  ;tmp guess for electrons
if species eq 'i' then zrange = [1.0e-25, 1.0e-21]  ;tmp guess for ions
   


win = 9
WINDOW,/free, XSIZE=1400, YSIZE=800, TITLE='MMS FPI Distributions'  
;nx = dimen2(norms)
nx = 4
ny = 3
spd_arrange_plots,x0,y0,x1,y1,nx=nx,ny=ny,ygap=0.056,x1margin=0.1,$
  x0margin=0.1,y1margin=0.02,xgap=0.1,y0margin=0.08
              
;loop over time samples and slice orientations to create a set of plots at each sample
;used short window to ensure only a single sample is used
;OPTION: change to 2D interpolation for speed (uses data within 20 deg of plane)
;geometric interpolation is slow but shows bin boundaries

;---------------------------------------------
for i=0, n_elements(*dist)-1 do begin
  ipos=-1
  time = (*dist)[i].time
  end_time = (*dist)[i].end_time
  
  for j=0, 2 do begin
    ipos=ipos+1
    if j eq 2 then nocolorbar=0 else nocolorbar=1
    if j eq 0 then slice = spd_slice2d(dist, time=time, window=end_time-time, rotation='xy', geometric=geometric, mag_data=bname, resolution=resolution)
    if j eq 1 then slice = spd_slice2d(dist, time=time, window=end_time-time, rotation='xz', geometric=geometric, mag_data=bname, resolution=resolution)
    if j eq 2 then slice = spd_slice2d(dist, time=time, window=end_time-time, rotation='yz', geometric=geometric, mag_data=bname, resolution=resolution)
    spd_slice2d_plot, slice, window=win, xrange = vr, yrange = vr, zrange = zrange,$
      /custom, title='',charsize=1.15, pos = [x0[ipos],y0[ipos],x1[ipos],y1[ipos]],$
      noerase = ipos gt 0, nocolorbar = nocolorbar,olines=olines ;, /PLOTBFIELD
    xyouts,/norm, align=1.0,x1[ipos]-(x1[ipos]-x0[ipos])/2.,y1[ipos]-0.05,'dist_PSD'
    mms_draw_circle,0.,0.,r=vmin,/fill  ;SAB, mask out interpolation below 10 eV
  endfor
  plot,[0,1],[0,1],/nodata,/noerase,pos = [x0[ipos],y0[ipos],x1[ipos],y1[ipos]],xstyle=5,ystyle=5
  ipos=ipos+1

  for j=0, 2 do begin
    ipos=ipos+1
    if j eq 2 then nocolorbar=0 else nocolorbar=1
    if j eq 0 then slice = spd_slice2d(distErr, time=time, window=end_time-time, rotation='xy', geometric=geometric, mag_data=bname, resolution=resolution)
    if j eq 1 then slice = spd_slice2d(distErr, time=time, window=end_time-time, rotation='xz', geometric=geometric, mag_data=bname, resolution=resolution)
    if j eq 2 then slice = spd_slice2d(distErr, time=time, window=end_time-time, rotation='yz', geometric=geometric, mag_data=bname, resolution=resolution)
    spd_slice2d_plot, slice, window=win, xrange = vr, yrange = vr, zrange = zrange,$
      /custom, title='',charsize=1.15, pos = [x0[ipos],y0[ipos],x1[ipos],y1[ipos]],$
      noerase = ipos gt 0, nocolorbar = nocolorbar,olines=olines ;, /PLOTBFIELD
    xyouts,/norm, align=1.0,x1[ipos]-(x1[ipos]-x0[ipos])/2.,y1[ipos]-0.05,'dist_Err'
    mms_draw_circle,0.,0.,r=vmin,/fill  ;SAB, mask out interpolation below 10 eV
  endfor
  plot,[0,1],[0,1],/nodata,/noerase,pos = [x0[ipos],y0[ipos],x1[ipos],y1[ipos]],xstyle=5,ystyle=5  
  ipos=ipos+1
 
  
;  for j=0, dimen2(norms)-1 do begin
;    ipos=ipos+1
;    if j eq dimen2(norms)-1 then nocolorbar=0 else nocolorbar=1
;    slice = spd_slice2d(dist, time=time, window=end_time-time, $
;      rotation=rotation, slice_norm=norms[*,j],  geometric=geometric, $
;      resolution=1000,$
;      mag_data=bname, vel_data=vname)
;    spd_slice2d_plot, slice, window=win, xrange = vr, yrange = vr, zrange = zrange,$
;      /custom, title='',charsize=1.15, pos = [ x0[ipos], y0[ipos], x1[ipos], y1[ipos] ],$
;      noerase = ipos gt 0, nocolorbar=nocolorbar
;    mms_draw_circle,0.,0.,r=vmin,/fill  ;SAB, mask out interpolation below 10 eV 
;  endfor
;  plot,[0,1],[0,1],/nodata,/noerase,pos = [x0[ipos],y0[ipos],x1[ipos],y1[ipos]],xstyle=5,ystyle=5
;  ipos=ipos+1

  for j=0, 3 do begin
    ipos=ipos+1
    if j eq 3 then nocolorbar=0 else nocolorbar=1
    if j eq 0 then slice = spd_slice2d(dist, time=time, window=end_time-time, rotation='BV', geometric=geometric, mag_data=bname, vel_data=vname, resolution=resolution) ;geometric interpolation
    if j eq 1 then slice = spd_slice2d(dist, time=time, window=end_time-time, rotation='BE', geometric=geometric, mag_data=bname, vel_data=vname, resolution=resolution) ;geometric interpolation
    if j eq 2 then slice = spd_slice2d(dist, time=time, window=end_time-time, rotation='perp', geometric=geometric, mag_data=bname, vel_data=vname, resolution=resolution) ;geometric interpolation
    if j eq 3 then slice = spd_slice2d(dist, time=time, window=end_time-time, rotation='xvel', geometric=geometric, mag_data=bname, vel_data=vname, resolution=resolution) ;geometric interpolation

    spd_slice2d_plot, slice, window=win, xrange = vr, yrange = vr, zrange = zrange,$
      /custom, title='',charsize=1.15, pos = [x0[ipos],y0[ipos],x1[ipos],y1[ipos]],$
      noerase = ipos gt 0, nocolorbar = nocolorbar,olines=olines ;, /PLOTBFIELD
    xyouts,/norm, align=1.0,x1[ipos]-(x1[ipos]-x0[ipos])/2.,y1[ipos]-0.05,'dist_PSD'
    mms_draw_circle,0.,0.,r=vmin,/fill  ;SAB, mask out interpolation below 10 eV
  endfor

  plot,[0,1],[0,1],/nodata,/noerase,pos = [min(x0),min(y0[0]),max(x1),max(y1)],xstyle=5,ystyle=5    
  plot,[0,1],[0,1],/nodata,/noerase,pos = [0., 0.,1.,1.],xstyle=5,ystyle=5
  xyouts,/norm,0.02,0.01,'created by mms_slice_comparison_crib.pro data_rate='+data_rate

  ;place title
  xyouts, x0[0],y1[0]+0.025, align=0.0, charsize=1.5, /normal, $
    slice.project_name+slice.spacecraft+' '+slice.data_name+' '+ $
    time_string(time, tformat='YYYYMMDD hh:mm:ss.fff')+' -> '+ $
    time_string(end_time, tformat='hh:mm:ss.fff')

  ; moments closest to this time
  closest_time = find_nearest_neighbor(density_struct.X, time)
  closest_idx = where(density_struct.X eq closest_time)
  density_at_this_time = density_struct.Y[closest_idx]
  
  ; bulk velocity closest to this time
  closest_time = find_nearest_neighbor(velocity_struct.X, time)
  closest_idx_vel = where(velocity_struct.X eq closest_time)
  velocity_at_this_time = velocity_struct.Y[closest_idx_vel, *]
  
  ; pressure/temperature closest to this time
  temp_at_this_time = reform(temp_struct.Y[closest_idx_vel, *, *])
  pres_at_this_time = reform(pressure_struct.Y[closest_idx_vel, *, *])

  ; plot density
  xyouts, 0.85, 0.9, align=0.5, charsize=1.5, /normal, 'Density: '+$
    strcompress(string(density_at_this_time),/rem) + ' [cm^-3]'
  
  ; plot temperature tensor
  xyouts, 0.85, 0.85, align=0.5, charsize=1.5, /normal, 'Txx: '+strcompress(string(temp_at_this_time[0, 0]),/rem)+'  Tyy: '+strcompress(string(temp_at_this_time[1, 1]),/rem)
  xyouts, 0.85, 0.80, align=0.5, charsize=1.5, /normal, 'Txy: '+strcompress(string(temp_at_this_time[0, 1]),/rem)+'  Tyz: '+strcompress(string(temp_at_this_time[1, 2]),/rem)
  xyouts, 0.85, 0.75, align=0.5, charsize=1.5, /normal, 'Txz: '+strcompress(string(temp_at_this_time[0, 2]),/rem)+'  Tzz: '+strcompress(string(temp_at_this_time[2, 2]),/rem)
  
  ; plot pressure tensor
  xyouts, 0.85, 0.7, align=0.5, charsize=1.5, /normal, 'Pxx: '+strcompress(string(pres_at_this_time[0, 0]),/rem)+'  Pyy: '+strcompress(string(pres_at_this_time[1, 1]),/rem)
  xyouts, 0.85, 0.65, align=0.5, charsize=1.5, /normal, 'Pxy: '+strcompress(string(pres_at_this_time[0, 1]),/rem)+'  Pyz: '+strcompress(string(pres_at_this_time[1, 2]),/rem)
  xyouts, 0.85, 0.6, align=0.5, charsize=1.5, /normal, 'Pxz: '+strcompress(string(pres_at_this_time[0, 2]),/rem)+'  Pzz: '+strcompress(string(pres_at_this_time[2, 2]),/rem)
  
    
  ; plot components of bulk velocity   
  xyouts, 0.85, 0.55, align=0.5, charsize=1.5, /normal, slice.data_name + ' bulk velocity'
  xyouts, 0.85, 0.50, align=0.5, charsize=1.5, /normal, 'Vx: '+$
    strcompress(string(velocity_at_this_time[0]),/rem) + ' [km/s]'
  xyouts, 0.85, 0.45, align=0.5, charsize=1.5, /normal, 'Vy: '+$
    strcompress(string(velocity_at_this_time[1]),/rem) + ' [km/s]'
  xyouts, 0.85, 0.40, align=0.5, charsize=1.5, /normal, 'Vz: '+$
    strcompress(string(velocity_at_this_time[2]),/rem) + ' [km/s]'

  ;write png
  makepng, folder+'mms'+probe+'_'+species+'_'+data_rate+'_'+rotation+'_'+ $
           time_string(time, tformat='YYYYMMDD_hhmmss.fff'), $
           /mkdir

endfor
print, 'took: ' + string(systime(/seconds)-start_time) + ' seconds to run'
end