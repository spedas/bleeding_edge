;+
; PROCEDURE: IUG_CRIB_KYUSHUGCM
;    A sample crib sheet that explains how to use the "iug_load_kyushugcm" 
;    procedure. You can run this crib sheet by copying & pasting each 
;    command below (except for stop and end) into the IDL command line. 
;    Or alternatively compile and run using the command:
;        .run iug_crib_kyushugcm
;
; NOTE: See the rules of the road.
;       The simulation data are 3D and have a large file size (about 100MB).
;       The large file size may cause long download time and out of memory 
;       depending on the situation.
;
; Written by: Y.-M. Tanaka, August, 2013
;             National Institute of Polar Research, Japan.
;             ytanaka at nipr.ac.jp
;-

; Initialize
thm_init

; Set the date and duration (in days)
timespan, '2009-1-1'

; Load Kyushu GCM data
iug_load_kyushugcm, datatype='t'

; View the loaded data names
tplot_names
get_data, 'kyushugcm_T', data=d
help, d, /str

; Stop
print,'Enter ".c" to continue.'
stop


; Delete a IDL varibale, d.
undefine, d

; Pick up altitude profile at glat=35 and glon=135.
; You can choose glat or glon or alt profile by setting selparam_idx
; (=[glat, glon, alt]). For example, altitude profile is selected by 
; selparam_idx=[0,0,1].
conv3d, 'kyushugcm_T', selparam_idx=[0, 0, 1], selparam_dat=[35., 135., 0], $
	newname='kyushugcm_T_alt'

; Plot
ylim, 'kyushugcm_T_alt', [1000., 1.0e-9]
options, 'kyushugcm_T_alt', spec=1, ylog=1, ysubtitle='Pressure [hPa]'
tplot, 'kyushugcm_T_alt'

; Stop
print,'Enter ".c" to continue.'
stop


; Delete kyushugcm_T
store_data, 'kyushugcm_T', /delete
store_data, 'kyushugcm_T_alt', /delete

; Pick up altitude profile at glat=-69 and glon=39 at the same time $
; when loading data. Y axis is set to altitude (km).
iug_load_kyushugcm, datatype='t', selparam_idx=[0, 0, 1], $
	selparam_dat=[-69., 39., 0], newname='kyushugcm_T_alt', /altitude

; Plot
tplot, 'kyushugcm_T_alt'

; Stop
print,'Enter ".c" to continue.'
stop


; Delete kyushugcm_T_alt
store_data, 'kyushugcm_T_alt', /delete

; Load latitude profile at glon=135 and pressure=10hPa.
iug_load_kyushugcm, datatype='t', selparam_idx=[1, 0, 0], $
        selparam_dat=[0, 135., 10.], newname='kyushugcm_T_glat'

; Plot
tplot, 'kyushugcm_T_glat'

; Stop
print,'Enter ".c" to continue.'
stop


; Delete kyushugcm_T_alt
store_data, 'kyushugcm_T_glat', /delete

; Load 2D temperature data at alt=30km.
iug_load_kyushugcm, datatype='t', selparam_idx=[1, 1, 0], $
        selparam_dat=[0, 0, 30.], newname='kyushugcm_T_2D', /altitude

; Draw contour iamge of 2D temperature data at alt=30km at 10:00UT.
time='2009-1-1/10:00'
get_data, 'kyushugcm_T_2D', data=d, dl=dl, lim=lim
idx = nn( d.x, time_double(time) )
Tmap = transpose(reform(d.y[idx, *, *]))
lat = d.v1
lon = d.v2

contour, Tmap, lon, lat, /fill, nlevels=50
str_element, lim, 'ztitle', val=ztitle
draw_color_scale, pos=[0.9, 0.2, 0.91, 0.7], range=[min(Tmap), max(Tmap)], $
	title=ztitle

end
