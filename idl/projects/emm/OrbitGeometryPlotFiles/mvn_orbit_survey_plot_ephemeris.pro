;+
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; mvn_orbit_survey_plot_ephemeris
;
; Routine to create an ephemeris survey plot with 6 different panels,
;  given a single timestamp. The plot is for the entire orbit
;  containing that timestamp
;
; Syntax: mvn_orbit_survey_plot_ephemeris, time, fileroot, screen=screen
;
; Inputs:
;      time              - any UTC timestamp, as string or double precision
;
;      fileroot          - the name of the file, without extension
;                          (i.e. no '.jpg' at the end)
;
;      screen            - boolean keyword to send the output to the
;                          screen; used for testing. Default = 0
;
;      overlay           - Structure describing the image/data to be
;                          overlaid on the sphere of Mars. Contains
;                          the following tags:
;
;                           LAT: N-element array of latitudes of each
;                           point to be painted on the sphere.
;
;                           ELON: N-element array of East longitudes
;                           of each point to be painted on the sphere
;
;                           DATA: N-element array of values
;                           (e.g. brightnesses etc.) to be painted on
;                           the sphere
;
;                           COLOR_TABLE: which color table is wanted
;                           for the overlay
;
;                           LOG: 0 or 1 for whether the data should be
;                           plotted with a logarithmic color scale
;
;                           RANGE: the color scale range for the data
;
;                           OBSPOS: in the case of images of Mars
;                           captured by orbital assets, this is the
;                           position of the "camera", in Cartesian
;                           coordinates. 
;
;                           DESCRIPTION: a string, briefly describing
;                           what is being overlaid on the
;                           sphere. Ideally this should be less than
;                           20 characters
;
;                           FILENAME: if the image comes from a
;                           particular file

; obspos: pos, description:disk [0, 0].bands[band_index], $
;          Filename:file, time: time}
;
;
; Dependencies:
;      There are many code dependencies here, not including the
;      obvious dependency on Berkeley's MAVEN software. I haven't had
;      time to compile a complete list, but here's a partial
;      list of code by Dave Brain that is needed to run this routine:
;      mvn_get_orbit_times_brain.pro - gets start/stop times for orbit
;      mvn_load_eph_brain.pro - loads ephemeris info into tplot vars
;      mvn_orbproj_panel_brain.pro - makes a projection plot
;      mvn_cylplot_panel_brain.pro - makes a cylindrical coords plot
;      mvn_groundtrack_panel_brain.pro - makes a groundtrack
;      mvn_threed_projection_panel_brain.pro - makes a 3D projection
;      ps_set.pro - establishes a postscript plot
;      plotposn.pro - positions a plot
;      cleanup.pro - resets plotting system variables
;      colorscale.pro - Dave Brain version of bytscl.pro
;      ctload.pro - Dave Fanning (coyote) version of loadct, with
;                   brewer color mode enabled.
;
; Caution:
;   1. VERY IMPORTANT! Three of the routines contain a hard link to a
;      file containing crustal field information. This link needs to be
;      edited for the location of the file on your machine.
;      Please check header comments for:
;         mvn_orbproj_panel_brain.pro
;         mvn_groundtrack_panel_brain.pro
;         mvn_threed_projection_panel_brain.pro
;   2. This routine make use of the ImageMagick "convert" utility,
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
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;-
pro mvn_orbit_survey_plot_ephemeris, time, fileroot, screen=screen, $
                                     overlay = overlay, crustalfields = crustalfields, $
                                     tbuffer = tbuffer


;;; Parameters
  if n_elements(screen) eq 0 then screen = 0
  ;time = '2014-10-30/23:22:21'
  ;fileroot = 'test'

  
  
;;; Find the start and stop time of the orbit
  t0 = time_double( time )
  trange = mvn_get_orbit_times_brain( t0 )

  
  
;;; Establish the output device
  loadct, 0
  !p.background = 255
  !P.color = 0
  if keyword_set(screen) eq 1 then begin
     window, 0, xs=1400, ys=700
  endif
  if keyword_set(screen) eq 0 then begin
; this makes the plot 45 cm wide and 18 cm high
     ps_set, 50, file=fileroot+'.eps'
  endif
  
  
  
;;; Get time of periapsis
  mvn_load_eph_brain, trange, 1d0
  get_data, 'mvn_alt', t, alt
  ans = min(alt, ind)
  peri_time = t[ind]



;;; Create the projection centered on periapsis
  ;; Set some plot parameters
 

;;; Create the three projection plots
  panelsize = [10,10]
  xrange = [-3,3]
  yrange = xrange
  ss = .8
  cs = .75

  ans = plotposn( size=panelsize, cen=[ 5, 12.75 ], /region )
  mvn_orbproj_panel_brain, $
     /xy, trange=trange, res=60d0, /solidMars,$
     crustalfields = crustalfields, $
     xrange = xrange, yrange = yrange, $
     symsize = ss, charsize = cs, $
     /showperiapsis, /showticks, /noerase, overlay = overlay

  ans = plotposn( size=panelsize, cen=[ 15, 12.75 ], /region )
  mvn_orbproj_panel_brain, /solidMars,$
     /xz, trange=trange, res=60d0, $
     crustalfields = crustalfields, $
     xrange = xrange, yrange = yrange, $
     symsize = ss, charsize = cs, $
     /showperiapsis, /showticks, /noerase, overlay = overlay

; make the YZ plot from the backside
  ans = plotposn( size=panelsize, cen=[ 25, 12.75 ], /region )
  mvn_orbproj_panel_brain, /night,/solidMars,$
     /yz, trange=trange, res=60d0, $
     crustalfields = crustalfields, $
     xrange = xrange, yrange = yrange, $
     symsize = ss, charsize = cs, $
     /showperiapsis, /showticks, /noerase, overlay = overlay

;;; Create the cylindrical coordinates plot
  ;; Set some plot parameters
  panelsize = [ 15, 7.5 ]
  xrange = [-3,3]
  yrange = [0,3]
  ss = .8
  cs = .75

  ;; Make the plot
  ans = plotposn( size=panelsize, cen=[ 7.5, 3.75 ], /region )
  mvn_cylplot_panel_brain, $
     trange = trange, res = 60d0, $
     xrange = xrange, yrange= yrange, $
     /showperiapsis, /showticks, /noerase, $
     symsize = ss, charsize = cs

;;; Create the groundtrack plot
  ;; Set some plot parameters
  panelsize = [ 15, 7.5 ]
  ss = .8
  cs = .75

  ;; Make the plot
  ans = plotposn( size=panelsize, cen=[ 22.5, 3.75 ], /region )
  mvn_groundtrack_panel_brain, $
     trange = trange, res = 60d0, $
     /terminator, /noerase, $
     /showperiapsis, /showticks, crustalfields = crustalfields,$
     symsize = ss, charsize = cs, overlay = overlay



  

;;; Create the projection centered on periapsis
  ;; Set some plot parameters
  panelsize = [ 13, 13 ]
  xrange = [-1,1]*1.2
  yrange = xrange
  ss = 1

  ;; Make the plot
  ans = plotposn( size=panelsize, cen=[ 38, 10.5 ], /region )
  mvn_threed_projection_panel_brain, $
     trange=trange, res=10d0,$
     /noerase, /Crustalfields,$
     xrange = xrange, yrange = yrange,$
     /showperiapsis, /showticks, $
     symsize = ss
  

  
;;; Create the timebar
  color = colorscale( t, mindat=min(trange), maxdat=max(trange), $
                      mincol=20, maxcol=250 )
  store_data, $
     'mavenbar', $
     data={ x:t, $
            y:[[color],[color]], $
            v:[0,1] }
  
  options, 'mavenbar', 'ytitle', 'MAVEN'
  options, 'mavenbar', 'yticks', 1
  options, 'mavenbar', 'yminor', 1
  options, 'mavenbar', 'ytickname', [' ',' ']
  options, 'mavenbar', 'spec', 1
  options, 'mavenbar', 'no_color_scale', 1
  
  time_stamp, /off
  tplot_options, 'xmargin', [10,3]
  tplot_options, 'ymargin', [1,1]
  tplot_options, 'noerase', 1
  tplot_options, 'charsize', .7
  tplot_options, 'region', [0.675,0.08,0.975,0.23]
  ctload, 63, rgb=rgb
  rgb[255,*] = 255
  rgb[0,*] = 0
  tvlct, rgb[*,0], rgb[*,1], rgb[*,2]


; Make a copy of the O 1304 tplot variable
  Get_data, 'emus_O_1304', data=dd, dlimit=dl, limit=ll
  Store_data, 'emus_O_1304_copy', data=dd, dlimit=dl, limit=ll

  options, 'emus_O_1304_copy',  'ytitle', 'Pixel'
  Options, 'emus_O_1304_copy', 'no_color_scale', 1
  tplot, ['mavenbar', 'emus_O_1304'], trange = trange

;;; create the EMUS time bar


;;; Create the image brightness bar
  If keyword_set (overlay) then begin
     loadct2, overlay.color_table
     draw_color_scale,range=overlay.range,brange=[7, 254],log=overlay.log,yticks=6,$
         position=[0.658, 0.3, 0.675,0.85],charsize = 1.1,title=$
                      overlay.description + ' brightness, R'
     
  endif

;;; Create the image time bar

;;; Make title
  xyouts, /normal, 0.5, 0.95, charsize=1.5, al=0.5, $
          time_string (overlay.time) +'.  Emission: '+overlay.description + '.   File: '+overlay.filename+ ' '

; add labels to orient viewer
  ylabel = 0.892
  xyouts, /normal,5.5/45.0,ylabel, 'View from above', align = 0.5, charsize = 1.3
  xyouts, /normal,15.5/45.0,ylabel, 'View from dawn', align = 0.5, charsize = 1.3
  xyouts, /normal,25.5/45.0,ylabel, 'View toward sun', align = 0.5, charsize = 1.3
  
  xyouts, /normal,38/45.0,0.24, 'View from Hope', align = 0.5, charsize = 1.3
;;; Clean up
  if keyword_set(screen) eq 0 then begin
     ps_set, -1
     spawn, 'convert -density 300 ' + fileroot + '.eps ' + $
            fileroot + '.jpg'
     spawn, 'rm ' + fileroot + '.eps'
  endif
  
  cleanup

end
