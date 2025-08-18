;+
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; mvn_orbql_multiplot
;
; Routine to create an ephemeris survey plot with 6 different panels,
;  given a single timestamp. The plot is for the entire orbit
;  containing that timestamp
;
; Syntax: mvn_orbql_multiplot, time, fileroot, screen=screen
;
; Inputs:
;      time              - any UTC timestamp, as string or double precision
;
;      fileroot          - the name of the file, without extension
;                          (i.e. no '.jpg' at the end)
;
; Dependencies:
;     - mvn_orbql_geo2mso_crustal_field_map.pro - loads Br map
;     - mvn_orbql_barebones_eph.pro - loads ephemeris info into tplot vars
;     - mvn_orbql_scposition.pro - calculates to-be-plotted parameters from eph
;     - mvn_orbql_orbproj_panel.pro - makes a projection plot
;     - mvn_orbql_cylplot_panel.pro - makes a cylindrical coords plot
;     - mvn_orbql_groundtrack_panel.pro - makes a groundtrack
;     - mvn_orbql_3d_projection_panel.pro - makes a 3D projection
;    - mvn_orbql_plotposn.pro - positions a plot
;    - mvn_orbql_colorscale.pro - scales a color map (Dave Brain version of bytscl.pro)
;    - mvn_orbql_overlay_map.pro - plots a 2d map
;    - mvn_orbql_symcat.pro - gives special plotting symbols
;
; Caution:
;   2. This routine makes use of the ImageMagick "convert" utility,
;      installed on Dave's machine. This step is used when
;      converting the .eps file producded by the program into a .jpg
;      file. If you don't have "convert", simply comment out
;      the lines below that create the .jpg and remove the .eps
;      files. (lines ~219-223, right under ;;;Cleanup)
;   3. This is optimized to work on Dave's machine. No
;      guarantees about your machine!
;
; Dave Brain
; 18 Jan, 2017 - Original version
; 24 Jan, 2024 - (RD Jolitz) cleaned routine
;   
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;-
pro mvn_orbql_multiplot, trange, fileroot, res=res, tickinterval=tickinterval,$
    showcrustal=showcrustal, showperiapsis=showperiapsis, showbehind=showbehind,$
    showorbit=showorbit, showapoapsis=showapoapsis, crustal_field_file=crustal_field_file,$
    title_string=title_string, saveplot=saveplot, interest_time=interest_time

  ;;Setting numbers
  ; print, showperiapsis


  ; Make XY/YZ/XZ projection plots
  ; from -3 Rm to 3 Rm
  projection_panel_xrange = [-3,3]
  projection_panel_yrange = [-3,3]

  ; Make cyl projection plot fro
  ; -3 Rm to 3 Rm in x and 0 to 3Rm
  ; on y
  cylindrical_xrange = [-3,3]
  cylindrical_yrange = [0,3]

  ; 3D projection dimensions at 1.2 Rm
  threed_xrange = [-1,1]*1.2
  threed_yrange = [-1,1]*1.2

  if !d.name eq 'Z' then begin

    ; symbol / chracter size
    symbol_size = 1.0*2
    character_size = 1.5*2
    title_char_size = 2.5*2
    colorbar_char_size = 1.1*2
    charthick = 4

    ; Size of the panel
    projection_panel_size = [20,20]*2
    cylindrical_panel_size = [ 30, 15 ]*2
    ground_track_panel_size = [ 30, 15 ]*2
    threed_panel_size = [ 26, 26 ]*2

    ; Center of plots
    xy_center = [ 10, 25.5 ]*2
    xz_center = [ 30, 25.5 ]*2
    yz_center = [ 50, 25.5 ]*2
    cyl_center = [ 15, 7.5 ]*2
    groundtrack_center = [ 45 , 7.5 ]*2
    proj_3d_center = [ 76, 21 ]*2

    colorbar_location = [0.675,0.1,0.975,0.18]
    colorbar_xmargin = [10, 1]
    colorbar_ymargin = [1, 1]

  endif else if !d.name eq 'X' then begin

    symbol_size = .8
    character_size = 1.3 ;   .75   ; 1.3
    title_char_size = 1.25
    colorbar_char_size = 1
    charthick = 1

    projection_panel_rel_size = [0.45, 0.45]
    cylindrical_panel_rel_size = [0.8, 0.4]
    ground_track_panel_rel_size = [0.8, 0.4]
    threed_panel_rel_size = [0.6, 0.6]

    ; Center of plots

    top_plots_offset_x = 0.215
    top_plots_ctr_y = 0.7
    xy_rel_center = [top_plots_offset_x, top_plots_ctr_y]
    xz_rel_center = [top_plots_offset_x + projection_panel_rel_size[0]/2, top_plots_ctr_y]
    yz_rel_center = [top_plots_offset_x + projection_panel_rel_size[0], top_plots_ctr_y]

    cyl_rel_center = [0.39, 0.25]
    groundtrack_rel_center = [0.39 + 0.33, 0.25]
    proj_3d_rel_center = [1, 0.6]

    colorbar_location = [0.71, 0.2, 0.975, 0.28]
    colorbar_xmargin = [10, 1]
    colorbar_ymargin = [1, 1]

  endif

  if not keyword_set(orbitcolortable) then orbitcolortable = 63
  if not keyword_set(overlaycolortable) then overlaycolortable = 70
  if not keyword_set(reverseoverlaycolortable) then reverseoverlaycolortable = 1

; Calculate the rotated crustal field at the time
  if keyword_set(showcrustal) then mvn_orbql_geo2mso_crustal_field_map,$
      crustal_field_file, trange, mso_crustal_fields
  
  ; Build the barebones ephemeris used
  ; (just MSO, GEO, lat, lon, and alt)
  mvn_orbql_barebones_eph, trange, res

  ; Get time of periapse
  mvn_orbql_scposition, trange, ticks, periapsis, apoapsis, interest_point,$
       showapoapsis=showapoapsis, showperiapsis=showperiapsis,$
       interest_time=interest_time, tickinterval=tickinterval


  if not keyword_set(title_string) then title_string = time_string(periapsis.t)
  ; stop
  ; print, time_string(t[-1])
  ; print, time_string(trange[-1])

;;; Create the three Cartesian projection plots: XY, then XZ, then YZ
  ans = mvn_orbql_plotposn(size=projection_panel_size,$
                           relsize=projection_panel_rel_size,$
                           cen=xy_center, relcen=xy_rel_center,$
                            /region)
  mvn_orbql_cart_panel, /xy,$
     trange=trange, res=res, $
     msofields=mso_crustal_fields,$
     apoapsis=apoapsis, periapsis=periapsis, interest_point=interest_point, ticks=ticks,$
     xrange = projection_panel_xrange, yrange = projection_panel_yrange, $
     symsize = symbol_size, charsize = character_size, $
     orbitcolortable=orbitcolortable, overlaycolortable=overlaycolortable,$
     reverseoverlaycolortable=reverseoverlaycolortable,$
     /noerase, showbehind=showbehind

  ans = mvn_orbql_plotposn(size=projection_panel_size,$
                           relsize=projection_panel_rel_size,$
                           cen=xz_center, relcen=xz_rel_center,$
                            /region)
  mvn_orbql_cart_panel, /xz,$
     trange=trange, res=res, $
     msofields=mso_crustal_fields,$
     apoapsis=apoapsis, periapsis=periapsis, interest_point=interest_point, ticks=ticks,$
     xrange = projection_panel_xrange, yrange = projection_panel_yrange, $
     symsize = symbol_size, charsize = character_size, $
     orbitcolortable=orbitcolortable, overlaycolortable=overlaycolortable,$
     reverseoverlaycolortable=reverseoverlaycolortable,$
     /noerase, showbehind=showbehind

  ans = mvn_orbql_plotposn(size=projection_panel_size,$
                           relsize=projection_panel_rel_size,$
                           cen=yz_center, relcen=yz_rel_center,$
                            /region)
  mvn_orbql_cart_panel, /yz,$
     trange=trange, res=res, $
     msofields=mso_crustal_fields,$
     apoapsis=apoapsis, periapsis=periapsis, interest_point=interest_point, ticks=ticks,$
     xrange = projection_panel_xrange, yrange = projection_panel_yrange, $
     symsize = symbol_size, charsize = character_size, $
     orbitcolortable=orbitcolortable, overlaycolortable=overlaycolortable,$
     reverseoverlaycolortable=reverseoverlaycolortable,$
     /noerase, showbehind=showbehind

   ; stop

;;; Create the cylindrical coordinates plot
  ; ans = mvn_orbql_plotposn( size=cylindrical_panel_size, cen=cyl_center, /region )
  ans = mvn_orbql_plotposn(size=cylindrical_panel_size,$
                           relsize=cylindrical_panel_rel_size,$
                           cen=cyl_center, relcen=cyl_rel_center,$
                            /region)
  mvn_orbql_cylplot_panel, $
     trange = trange, res = res, $
     xrange = cylindrical_xrange, yrange= cylindrical_yrange, $
     apoapsis=apoapsis, periapsis=periapsis, interest_point=interest_point, ticks=ticks,$
     orbitcolortable=orbitcolortable,$
     symsize = symbol_size, charsize = character_size, /noerase

   ; stop

;;; Create the groundtrack plot
  ; ans = mvn_orbql_plotposn( size=ground_track_panel_size, cen=groundtrack_center, /region )
  ans = mvn_orbql_plotposn(size=ground_track_panel_size,$
                           relsize=ground_track_panel_rel_size,$
                           cen=groundtrack_center, relcen=groundtrack_rel_center,$
                            /region)

  mvn_orbql_groundtrack_panel, $
     trange = trange, res = res, $
     periapsis=periapsis, interest_point=interest_point, ticks=ticks,$
     msofields=mso_crustal_fields,$
     /terminator, $
     orbitcolortable=orbitcolortable, overlaycolortable=overlaycolortable,$
     reverseoverlaycolortable=reverseoverlaycolortable,$
     symsize = symbol_size, charsize = character_size, /noerase

   ; stop


;;; Create the projection centered on periapsis
  ; ans = mvn_orbql_plotposn( size=threed_panel_size, cen=proj_3d_center, /region )
  ans = mvn_orbql_plotposn(size=threed_panel_size,$
                           relsize=threed_panel_rel_size,$
                           cen=proj_3d_center, relcen=proj_3d_rel_center,$
                            /region)

  mvn_orbql_3d_projection_panel, $
     trange=trange, res=res, $
     periapsis=periapsis, interest_point=interest_point, ticks=ticks,$
     msofields = mso_crustal_fields,$
     xrange = threed_xrange, yrange = threed_yrange, $
     orbitcolortable=orbitcolortable, overlaycolortable=overlaycolortable,$
     reverseoverlaycolortable=reverseoverlaycolortable,$
     symsize = symbol_size*1.2, /noerase


; stop

;;; Create the timebar
  ; color = mvn_orbql_colorscale($
  ;     t, mindat=min(trange), maxdat=max(trange), $
  ;     mincol=20, maxcol=250 )

  get_data, 'mvn_eph_mso', t, mso
  color = mvn_orbql_colorscale($
      t, mindat=min(trange), maxdat=max(trange), $
      mincol=1, maxcol=250 )

  store_data, 'colorbar', data={ x:t, y:[[color],[color]], v:[0,1] }
  
  if keyword_set(showorbit) then tplot_options,'var_label','orbnum'

  options, 'colorbar', 'ytitle', ' '
  options, 'colorbar', 'yticks', 1
  options, 'colorbar', 'yminor', 1
  options, 'colorbar', 'ytickname', [' ',' ']
  options, 'colorbar', 'spec', 1
  options, 'colorbar', 'no_color_scale', 1
  
  time_stamp, /off
  tplot_options, 'xmargin', colorbar_xmargin
  tplot_options, 'ymargin', colorbar_ymargin
  tplot_options, 'noerase', 1
  tplot_options, 'charsize', colorbar_char_size
  tplot_options, 'region', colorbar_location
  ; ctload, 63, rgb=rgb
  ; rgb = transpose(rgb)


  loadct2, orbitcolortable, rgb=rgb

  rgb[255,*] = 255
  rgb[0,*] = 0
  tvlct, rgb[*,0], rgb[*,1], rgb[*,2]
  ; stop
  tplot, 'colorbar', trange = trange
  ; stop

;;; Make title
  xyouts, /normal, 0.5, 0.93, charsize=title_char_size, charthick=charthick, al=0.5, title_string

  if keyword_set(saveplot) then begin
    image24 = TVRD(TRUE=1)
    image24 = rebin(image24, 3, 2340, 936)
    Write_JPEG, fileroot+ '.jpg', image24, True=1, Quality=100
  endif

end
