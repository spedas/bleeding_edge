;+
; PROCEDURE/FUNCTION sd_map_set
;
; :DESCRIPTION:
;		A wrapper routine for the IDL original "map_set" enabling some
;		annotations regarding the visualization of SD data.
;
;	:PARAMS:
;    time:   time (in double Unix time) for which the magnetic local time for the
;            world map is calculated. In AACGM plots, the magnetic local noon comes
;            on top in plot.
;
;	:KEYWORDS:
;    erase:   set to erase pre-existing graphics on the plot window.
;    clip:    set to zoom in roughly to a region encompassing a field of view of one radar.
;             Actually 30e+6 (clip is on) or 50e+6 (off) is put is "scale" keyword of map_set.
;    position:  gives the position of a plot panel on the plot window as the normal coordinates.
;    center_glat: geographical latitude at which a plot region is centered.
;    center_glon: geographical longitude at which a plot region is centered.
;                 (both center_glat and center_glon should be given, otherwise ignored)
;    mltlabel:    set to draw the MLT labels every 2 hour.
;    lonlab:      a latitude from which (toward the poles) the MLT labels are drawn.
;    force_scale:   Forcibly put a given value in "scale" of map_set.
;    stereo: Use the stereographic projection, instead of satellite projection (default)
;    nogrid: Set to prevent from drawing the lat-lon mesh
;    twohourmltgrid: Set to draw the MLT lines for every other hour, instead of every hour (default)
;
; :EXAMPLES:
;    sd_map_set
;    sd_map_set, /clip, center_glat=70., center_glon=180., /mltlabel, lonlab=74.
;
; :AUTHOR:
; 	Tomo Hori (E-mail: horit@isee.nagoya-u.ac.jp)
;
; :HISTORY:
; 	2011/01/11: Created
;
; $LastChangedDate: 2019-03-17 21:51:57 -0700 (Sun, 17 Mar 2019) $
; $LastChangedRevision: 26838 $
;-
PRO sd_map_set, time, erase=erase, clip=clip, position=position, $
    center_glat=glatc, center_glon=glonc, $
    mltlabel=mltlabel, lonlab=lonlab, $
    force_scale=force_scale, $
    geo_plot=geo_plot, coord=coord, $
    stereo=stereo, $
    charscale=charscale, $
    nogrid=nogrid, twohourmltgrid=twohourmltgrid, $
    dlat_grid=dlat_grid, dlon_grid=dlon_grid, color_grid=color_grid, $
    linethick_grid=linethick_grid
    
  ;Initialize the SD plot environment
  sd_init  ;Currently including map2d_init 
  
  ;Preserve the original position array 
  pre_pos = !p.position 
  
  ; Set the time for which the AACGM LAT-MLT coord is set. 
  npar = N_PARAMS()
  IF npar LT 1 THEN time = !map2d.time
  
  ;For coordinates 
  if size(coord, /type) ne 0 then begin
    map2d_coord, coord 
  endif
  if keyword_set(geo_plot) then !map2d.coord = 0 
  
  ; Set the scale for roughly clipping a field of view for one radar 
  IF KEYWORD_SET(clip) THEN scale=30e+6 ELSE scale=50e+6
  IF KEYWORD_SET(force_scale) THEN scale = force_scale 
  
  ; Set charscale 
  if ~keyword_set(charscale) then charscale = 1.0 
  charsize = !sdarn.sd_polar.charsize * charscale 
  
  ;Longitudinal grid interval
  if keyword_set(twohourmltgrid) then dlon_grid = 30. 
  
  ;Set the map2d mapping  
  map2d_set, $
    glatc=glatc, glonc=glonc, $
    erase=erase, scale=scale, position=position, $
    stereo=stereo, charsize=charsize, $
    set_time=time, $
    mltlabel=0, lonlab=lonlab, $
    nogrid=nogrid, $
    dlat_grid=dlat_grid, dlon_grid=dlon_grid, color_grid=color_grid, $
    linethick_grid=linethick_grid 
  
  
  IF ((size(glatc, /type) gt 0) AND (size(glatc, /type) lt 6)) AND $
      ((size(glonc, /type) gt 0) AND (size(glonc, /type) lt 6)) THEN BEGIN
    glonc = (glonc+360.) MOD 360.
    IF glonc GT 180. THEN glonc -= 360.
  ENDIF ELSE BEGIN
    glatc = !map2d.glatc & glonc = !map2d.glonc
  ENDELSE
  
  ;Hemisphere flag
  IF glatc GT 0 THEN hemis = 1 ELSE hemis = -1
  
  
  
  ;Resize the canvas size for the position values
  scl = (!x.window[1]-!x.window[0]) < (!y.window[1]-!y.window[0])
  scale /= scl
  ;Set charsize used for MLT labels and so on
  charsz = 1.4 * (KEYWORD_SET(clip) ? 50./30. : 1. ) * scl
  !sdarn.sd_polar.charsize = charsz
  
  ;Scale for characters applied only in sd_map_set
  IF ~KEYWORD_SET(charscale) THEN charscale=1.0
  
  IF KEYWORD_SET(mltlabel) THEN BEGIN
    ;Write the MLT labels
    mlts = 15.*FINDGEN(24) ;[deg]
    lonnames=['00hMLT','','02hMLT','','04hMLT','','06hMLT','','08hMLT','','10hMLT','','12hMLT','', $
      '14hMLT','','16hMLT','','18hMLT','','20hMLT','','22hMLT','']
    IF ~KEYWORD_SET(lonlab) THEN lonlab = 77.
    
    ;Calculate the orientation of the MTL labels
    lonlabs0 = replicate(lonlab,n_elements(mlts))
    if hemis eq 1 then lonlabs1 = replicate( (lonlab+10.) < 89.5,n_elements(mlts)) $
    else lonlabs1 = replicate( (lonlab-10.) > (-89.5),n_elements(mlts))
    nrmcord0 = CONVERT_COORD(mlts,lonlabs0,/data,/to_device)
    nrmcord1 = CONVERT_COORD(mlts,lonlabs1,/data,/to_device)
    ori = transpose( atan( nrmcord1[1,*]-nrmcord0[1,*], nrmcord1[0,*]-nrmcord0[0,*] )*!radeg )
    ori = ( ori + 360. ) mod 360. 
    
    ;ori = lons + 90 & ori[WHERE(ori GT 180)] -= 360.
    
    ;idx=WHERE(lons GT 180. ) & lons[idx] -= 360.
    
    nrmcord0 = CONVERT_COORD(mlts,lonlabs0,/data,/to_normal)
    FOR i=0,N_ELEMENTS(mlts)-1 DO BEGIN
      
      nrmcord = reform(nrmcord0[*,i])
      pos = [!x.window[0],!y.window[0],!x.window[1],!y.window[1]]
      IF nrmcord[0] LE pos[0] OR nrmcord[0] GE pos[2] OR $
        nrmcord[1] LE pos[1] OR nrmcord[1] GE pos[3] THEN CONTINUE
      XYOUTS, mlts[i], lonlab, lonnames[i], orientation=ori[i], $
        font=1, charsize=charsz*charscale
        
    ENDFOR
    
  ENDIF
  
  ;Restore the original position setting
  !p.position = pre_pos
  
  RETURN
END
