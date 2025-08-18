;+
; PROCEDURE plot_map_sdfit
;
; PURPOSE:
;		Draw a fan plot of SD data on the world map
;
;	:Params:
;    var:   tplot variable to be plotted
;
;	:Keywords:
;    noerase:     Set to plot data without erasing the screen 
;    clip:        Set to scale in to get a magnified map
;    position:    Set the location of the plot frame in the plot window
;    center_glat: geographical latitude at which a plot region is centered
;    center_glon: geographical longitude at which a plot region is centered
;    mltlabel:    Set to draw the MLT labels every 2 hour
;    lonlab:      a latitude from which (toward the poles) the MLT labels are drawn
;    force_scale: Forcibly put a given value in "scale" of map_set
;    geo_plot:    Set to plot in the geographical coordinates
;    coast:      Set to superpose the world map on the plot
;    nocolorscale: Set to surpress drawing the color scale 
;    colorscalepos: Set the position of the color scale in the noraml 
;                   coordinates. Default: [0.85, 0.1, 0.87, 0.45] 
;    pixel_scale: Set a values of range 0.0-1.0 to scale pixels drawn on a 2D map plot
;
; :EXAMPLES:
;   plot_map_sdfit, 'sd_hok_vlos_bothscat'
;   plot_map_sdfit, 'sd_hok_vlos_bothscat', center_glat=70., center_glon=180. 
;   
; :Author:
; 	Tomo Hori (E-mail: horit at isee.nagoya-u.ac.jp)
;
; :HISTORY:
; 	2011/03/11: Created
; 	2011/06/15: Renamed to plot_map_sdfit
;
;-
PRO plot_map_sdfit, var $
    , noerase=noerase $
    , clip=clip $
    , position=position $
    , center_glat=glatc $
    , center_glon=glonc $
    , mltlabel=mltlabel $
    , lonlab=lonlab $
    , force_scale=force_scale $
    , geo_plot=geo_plot $
    , coord=coord $
    , coast=coast $
    , gscatmaskoff=gscatmaskoff $
    , nocolorscale=nocolorscale $
    , colorscalepos=colorscalepos $
    , force_nhemis=force_nhemis $
    , pixel_scale=pixel_scale
    
    
  ;the tplot var exists?
  IF TOTAL(tnames(var) eq '') GT 0 THEN BEGIN
    PRINT, 'Not find the tplot variable: '+var
    RETURN
  ENDIF
  
  ;Initialize the 2D plot environment
  sd_init
  
  ;For coordinates 
  if size(coord, /type) ne 0 then begin
    map2d_coord, coord 
  endif
  if keyword_set(geo_plot) then !map2d.coord = 0 
  
  ;Set map_set if any map projection is not defined
  sd_map_set, erase=(~KEYWORD_SET(noerase)), clip=clip, position=position, $
    center_glat=glatc, center_glon=glonc, $
    mltlabel=mltlabel, lonlab=lonlab, $
    force_scale=force_scale, $
    geo_plot=geo_plot, coord=coord 
    
    
  ;Draw a fan plot on map
  overlay_map_sdfit, var, $
    position=position, $
    geo_plot=geo_plot, $
    nogscat=nogscat, gscatmaskoff=gscatmaskoff, $
    nocolorscale=nocolorscale, colorscalepos=colorscalepos, $
    force_nhemis=force_nhemis, pixel_scale=pixel_scale
    
  ;Draw the world map
  IF KEYWORD_SET(coast) THEN BEGIN
    overlay_map_coast, geo_plot=geo_plot, position=position
  ENDIF
  
  ;Draw the color scale on the right in screen
  ;overlay_color_scale     ;to be developed soon
  
  
  
  RETURN
END

