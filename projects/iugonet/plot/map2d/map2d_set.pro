;+
; PROCEDURE map2d_set
;
; :DESCRIPTION:
;    A wrapper routine for the IDL original "map_set" enabling some
;    annotations regarding the visualization of 2D data.
;
; :KEYWORDS:
;    glatc: geographical latitude at which a plot region is centered.
;    glonc: geographical longitude at which a plot region is centered.
;           (both glatc and glonc should be given, otherwise ignored)
;    scale: same as the keyword "scale" of map_set
;    erase: aet to erase pre-existing graphics on the plot window.
;    position: gives the position of a plot panel on the plot window as the normal coordinates.
;    label: set to label the latitudes and longitudes.
;    stereo: use the stereographic mapping, instead of satellite mapping (default)
;    charsize: size of the characters used for the labels.
;    coord: name of the coordinate system.
;        'geo' or 0 for Geographic coordinate
;        'aacgm' or non-zero numbers for AACGM coordinate
;    set_time: this is used to calculate MLT when coord is 'aacgm'
;    mltlabel: set to draw the MLT labels every 2 hour.
;    lonlab: a latitude from which (toward the poles) the MLT labels are drawn.
;    nogrid: set to suppress drawing the lat-lon mesh
;
; :EXAMPLES:
;    map2d_set
;    map2d_set, glatc=70., glonc=180., /mltlabel, lonlab=74.
;
; :AUTHOR:
;    Yoshimasa Tanaka (E-mail: ytanaka@nipr.ac.jp)
;
; :HISTORY:
;    2014/07/07: Created
;-

PRO map2d_set, glatc=glatc, glonc=glonc, $
    scale=scale, erase=erase, position=position, label=label, $
    stereo=stereo, charsize=charsize, $
    coord=coord, set_time=set_time, mltlabel=mltlabel, lonlab=lonlab, $
    nogrid=nogrid, $
    dlat_grid=dlat_grid, dlon_grid=dlon_grid, color_grid=color_grid, $
    linethick_grid=linethick_grid 
    
;----- Initialize the map2d environment -----;
map2d_init, set_time=set_time, coord=coord, $
    glatc=glatc, glonc=glonc, scale=scale
    
;----- get !map2d -----;
time_tmp =!map2d.time
coord_tmp=!map2d.coord
glatc_tmp=!map2d.glatc
glonc_tmp=!map2d.glonc
scale_tmp=!map2d.scale

;----- stereo -----;
if keyword_set(stereo) then begin
    satellite=0
    stereo=1
endif else begin
    satellite=1
    stereo=0
endelse
  
;----- position -----;
pre_pos = !p.position
if keyword_set(position) then begin
    !p.position = position
endif else begin
    nopos = 1
    position = !p.position
endelse
if position[0] ge position[2] or position[1] ge position[3] then begin
    print, '!p.position is not set, temporally use [0,0,1,1]'
    position = [0.,0.,1.,1.]
    !p.position = position
endif

;----- character size -----;
if ~keyword_set(charsize) then charsize=!p.charsize

;----- Resize the canvas size for the position values -----;
if ~keyword_set(nopos) then begin
    scl = (position[2]-position[0]) < (position[3]-position[1])
endif else begin
    scl = 1.
    if !x.window[1]-!x.window[0] gt 0. then $
        scl = (!x.window[1]-!x.window[0]) < (!y.window[1]-!y.window[0])
endelse
scale_tmp /= scl

;----- Calculate the rotation angle regarding MLT -----;
;hemisphere flag
if glatc_tmp gt 0 then hemis = 1 else hemis = -1
if coord_tmp eq 1 then begin ; aacgm
    ts = time_struct(time_tmp) & yrsec = (ts.doy-1)*86400l + long(ts.sod)

    aacgmloadcoef, ts.year
    aacgmconvcoord, glatc_tmp, glonc_tmp, 0.1, mlatc, mlonc, err, /to_aacgm
    tmltc = aacgmmlt(ts.year, yrsec, mlonc)
    mltc = ( tmltc + 24. ) mod 24.
    mltc_lon = 360./24.* mltc
	if mltc_lon gt 180. then mltc_lon -= 360.
    rot_angle = (-mltc_lon*hemis +360.) mod 360.
    if rot_angle gt 180. then rot_angle -= 360.

    ;rotate oppositely for the s. hemis.
    if hemis lt 0 then begin 
        rot_angle = ( rot_angle + 180. ) mod 360.
        ;rot_angle *= (-1.)
        rot_angle = (rot_angle+360.) mod 360.
        if rot_angle gt 180. then rot_angle -= 360.
    endif
endif else rot_angle = 0.

;calculate the rotation angle of the north dir in a polar plot
;ts = time_struct(time)
;aacgm_conv_coord, 60., 0., 400., mlat,mlon,err, /to_aacgm
;mlt = aacgm_mlt( ts.year, long((ts.doy-1)*86400.+ts.sod), mlon)

;----- Set the lat-lon canvas and draw the continents -----;
if coord_tmp eq 0 then begin
    latc=glatc_tmp
    lonc=glonc_tmp
endif else begin
    latc=mlatc
    lonc=mltc_lon
endelse

map_set, latc, lonc, rot_angle, $
    satellite=satellite, stereo=stereo, sat_p=[6.6, 0., 0.], $
    scale=scale_tmp, /isotropic, /horizon, noerase=~keyword_set(erase), $
    label=label, charsize=charsize 

if ~keyword_set(nogrid) then $
  map2d_grid, dlat=dlat_grid, dlon=dlon_grid, color=color_grid, $
    linethick=linethick_grid 

;    ;Resize the canvas size for the position values
;    scl = (!x.window[1]-!x.window[0]) < (!y.window[1]-!y.window[0])
;    scale /= scl
;    ;Set charsize used for MLT labels and so on
;    charsz = 1.4 * (KEYWORD_SET(clip) ? 50./30. : 1. ) * scl
;    !sdarn.sd_polar.charsize = charsz

if (coord_tmp eq 1) and keyword_set(mltlabel) then begin
    ;write the mlt labels
    mlts = 15.*findgen(24) ;[deg]
    lonnames=['00hMLT','','02hMLT','','04hMLT','','06hMLT','','08hMLT','','10hMLT','','12hMLT','', $
      '14hMLT','','16hMLT','','18hMLT','','20hMLT','','22hMLT','']
    if ~keyword_set(lonlab) then lonlab = 77.

    ;calculate the orientation of the mtl labels
    lonlabs0 = replicate(lonlab,n_elements(mlts))
    if hemis eq 1 then lonlabs1 = replicate( (lonlab+10.) < 89.5,n_elements(mlts)) $
    else lonlabs1 = replicate( (lonlab-10.) > (-89.5),n_elements(mlts))
    nrmcord0 = convert_coord(mlts,lonlabs0,/data,/to_device)
    nrmcord1 = convert_coord(mlts,lonlabs1,/data,/to_device)
    ori = transpose( atan( nrmcord1[1,*]-nrmcord0[1,*], nrmcord1[0,*]-nrmcord0[0,*] )*!radeg )
    ori = ( ori + 360. ) mod 360. 

    ;ori = lons + 90 & ori[where(ori gt 180)] -= 360.
    ;idx=where(lons gt 180. ) & lons[idx] -= 360.

    nrmcord0 = convert_coord(mlts,lonlabs0,/data,/to_normal)
    for i=0,n_elements(mlts)-1 do begin
        nrmcord = reform(nrmcord0[*,i])
        pos = [!x.window[0],!y.window[0],!x.window[1],!y.window[1]]
        if nrmcord[0] le pos[0] or nrmcord[0] ge pos[2] or $
            nrmcord[1] le pos[1] or nrmcord[1] ge pos[3] then continue
        xyouts, mlts[i], lonlab, lonnames[i], orientation=ori[i], $
            font=1, charsize=charsize
    endfor

endif
  
;----- Restore the original position setting -----;
!p.position = pre_pos

return
end
