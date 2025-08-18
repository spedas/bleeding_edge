;+
; PROCEDURE plot_map_asi_nipr
;
; :PURPOSE:
;    Draw NIPR all-sky imager data on the world map
;
; :Params:
;    asi_vns:   tplot variable to be plotted
;
; :Keywords:
;    set_time: time to plot all-sky imager data
;              (ex., '2012-01-12/21:30:00' or Unix time)
;    coord: the name of the coordinate system.
;           'geo' or 0 for geographic coordinate
;           'aacgm' or 1 for AACGM coordinate
;    glatc: geographical latitude at which a plot region is centered
;    glonc: geographical longitude at which a plot region is centered
;    scale: same as the keyword "scale" of map_set
;    altitude: altitude on which the image data will be mapped.
;              The default value is 110 (km). Available values are 90, 110, 150, 250.
;    colorrange: range of values of colorscale (this can be an array)
;    erase: set to erase pre-existing graphics on the plot window.
;    position:  position of the plot frame in the plot window
;    label: set to label the latitudes and longitudes.
;    stereo: use the stereographic mapping, instead of satellite mapping (default)
;    coast: set to draw coast
;    mapcharsize: size of the characters used for the labels.
;    mltlabel: set to draw the MLT labels every 2 hour
;    lonlab: a latitude from which (toward the poles) the MLT labels are drawn
;    nogrid: set to suppress drawing the lat-lon mesh
;    notimelabel: set to surpress drawing the time label
;    timelabelpos: position of the color scale in the noraml coordinates
;    tlcharsize: size of the characters used for the time label
;    nocolorscale: set to surpress drawing the color scale
;    colorscalepos: position of the color scale in the noraml coordinates.
;                   Default: [0.85, 0.1, 0.87, 0.45]
;    cscharsize: size of the characters used for the colorscale
;
; :EXAMPLES:
;   plot_map_asi_nipr, 'nipr_asi_hus_0000'
;   plot_map_asi_nipr, 'nipr_asi_hus_0000', glatc=65., glonc=-15. 
;   
; :AUTHOR:
;    Yoshimasa Tanaka (E-mail: ytanaka@nipr.ac.jp)
;
; :HISTORY:
;    2014/08/03: Created
;
;-
pro plot_map_asi_nipr, asi_vns, set_time=set_time, $
    coord=coord, glatc=glatc, glonc=glonc, scale=scale, $
    altitude=altitude, colorrange=colorrange, $
    erase=erase, position=position, $
    label=label, stereo=stereo, coast=coast, $
    mapcharsize=mapcharsize, $
    mltlabel=mltlabel, lonlab=lonlab, $
    nogrid=nogrid, dlat_grid=dlat_grid, dlon_grid=dlon_grid, $
    color_grid=color_grid, linethick_grid=linethick_grid, $
    notimelabel=notimelabel, timelabelpos=timelabelpos, $
    tlcharsize=tlcharsize, $
    nocolorscale=nocolorscale, colorscalepos=colorscalepos, $
    cscharsize=cscharsize
    
;the tplot var exists?
if total(tnames(asi_vn) eq '') gt 0 then begin
    print, 'not find the tplot variable: '+var
    return
endif
  
;Initialize the 2D plot environment
map2d_init
  
;Set map_set if any map projection is not defined
map2d_set, glatc=glatc, glonc=glonc, $
    scale=scale, erase=erase, position=position, label=label, $
    stereo=stereo, charsize=mapcharsize, $
    coord=coord, set_time=set_time, mltlabel=mltlabel, lonlab=lonlab, $
    nogrid=nogrid, $
    dlat_grid=dlat_grid, dlon_grid=dlon_grid, color_grid=color_grid, $
    linethick_grid=linethick_grid

;Draw a fan plot on map
overlay_map_asi_nipr, asi_vns, set_time=set_time, $
    altitude=altitude, coord=coord, position=position, $
    colorrange=colorrange, $
    notimelabel=notimelabel, timelabelpos=timelabelpos, $
	tlcharsize=tlcharsize, $
    nocolorscale=nocolorscale, colorscalepos=colorscalepos, $
    cscharsize=cscharsize

;Draw the world map
if keyword_set(coast) then begin
    overlay_map_coast, coord=coord, position=position
endif
  
;Draw the color scale on the right in screen
;overlay_color_scale     ;to be developed soon
  
return

end

