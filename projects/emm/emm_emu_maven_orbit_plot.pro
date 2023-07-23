;+
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; emm_emu_maven_orbit_plot
;
; Routine to create a 6-panel plot with the orbits of MAVEN (and
; potentially other spacecraft in future)  plotted with respect to a
; gridded lat-long data image. 
;
; Syntax: mvn_orbit_survey_plot_ephemeris, time, fileroot, screen=screen
;
; Inputs:
;      time              - any UTC timestamp, typically the start or
;                          central time  the image was taken
;
;      fileroot          - the name of the file, without extension
;                          (i.e. no '.jpg' at the end)
;
; KEYWORDS:
;      screen            - boolean keyword to send the output to the
;                          screen; used for testing. Default = 0
;
;      tbuffer           - The number of seconds before and after the
;                          central time where the trajectory  should
;                          be plotted
;
;      sun_view          - Controls the viewpoint in the YZ-plane. If
;                          set to 'day', the view is of the dayside of
;                          Mars. If set to 'night', the view is of the
;                          nightside.
;
;      traj_ct           - Color table for the MAVEN trajectory
;
;      overlay           - Structure describing the image/data to be
;                          overlaid on the sphere of Mars. Contains
;                          the following tags:
;
;                           LAT: Nx-element array of latitudes of each
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
;                           particular file, it can be entered for
;                           printing on the final plot

;
; Dependencies:
;      Requires installation of the Berkeley SPEDAS software package.
; 
;
; Caution:
;   1. This routine make use of the ImageMagick "convert" utility. This step is used when
;      converting the .eps file producded by the program into a .jpg
;      file. If you don't have "convert", simply comment out
;      the lines below that create the .jpg and remove the .eps
;      files. 
;

; 18 Jan, 2017 - Original version by David brain
; 02 Nov, 2022 - update for EMM by Rob  Lillis
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;-
pro emm_emu_maven_orbit_plot, time, fileroot, screen=screen, $
                                     overlay = overlay, crustalfields = crustalfields, $
                                     tbuffer = tbuffer, sun_view = sun_view, $
                                     traj_CT = traj_CT

; Choose the trajectory color scheme
  If not keyword_set (traj_ct) then traj_ct = 63


;;; Parameters
  if n_elements(screen) eq 0 then screen = 0
  ;time = '2014-10-30/23:22:21'
  ;fileroot = 'test'

; define the time before and after for which we want the MAVEN orbit
  if not keyword_set (tbuffer) then tbuffer = 3600*1.5; 1.5 hours

; find the time range
  Trange = time + tbuffer*[-1, 1]
  
  
;;; Establish the output device
  loadct, 0
  !p.background = 255
  !P.color = 0
; this is for diagnosing issues
  if keyword_set(screen) eq 1 then window, 0, xs=1400, ys=700
  

; this is for making the finished product
  
  if keyword_set(screen) eq 0 then ps_set, 60, file=fileroot+'.eps'
     ; this makes the plot 45 cm wide and 18 cm high

  if not keyword_set (sun_view) then sun_view = 'night'
  
;;; Get time of periapsis
  mvn_load_eph_brain, trange, 1d0
  get_data, 'mvn_alt', t, alt
  ans = min(alt, ind)
  peri_time = t[ind]


;;; Create the three projection plots
  panelsize = [10,10]
  xrange = [-2.5,2.5]
  yrange = xrange
  ss = .8
  cs = .75
 ; stop
; make the XY plot (top view)
  ans = plotposn( size=panelsize, cen=[ 5, 12.75 ], /region )
  ;.r mvn_orbproj_panel
  mvn_orbproj_panel, /crustalfields,$
     /xy, trange=trange, res=60d0, /solidMars,$
     xrange = xrange, yrange = yrange, $
     symsize = ss, charsize = cs, $
     /showperiapsis, /showticks, /noerase, overlay = overlay, $
     orbitcolortable = traj_ct

; make the XZ plot (side view)
  ans = plotposn( size=panelsize, cen=[ 15, 12.75 ], /region )
  mvn_orbproj_panel, /solidMars,$
     /xz, trange=trange, res=60d0,/crustalfields, $
     xrange = xrange, yrange = yrange, $
     symsize = ss, charsize = cs, $
     /showperiapsis, /showticks, /noerase, overlay = overlay, $
     orbitcolortable = traj_ct

; make the YZ plot (view from or toward the sun)
  ans = plotposn( size=panelsize, cen=[ 25, 12.75 ], /region )

; NOTE:
  if sun_view eq 'day' then mvn_orbproj_panel,/solidMars,$
     /yz, trange=trange, res=60d0, $
     xrange = xrange, yrange = yrange, /crustalfields,$
     symsize = ss, charsize = cs, $
     /showperiapsis, /showticks, /noerase, overlay = overlay, $
     orbitcolortable = traj_ct
  if sun_view eq 'night' then mvn_orbproj_panel, /night,/solidMars,$
     /yz, trange=trange, res=60d0, /crustalfields,$
     xrange = xrange, yrange = yrange, $
     symsize = ss, charsize = cs, $
     /showperiapsis, /showticks, /noerase, overlay = overlay, $
     orbitcolortable = traj_ct

;;; Create the cylindrical coordinates plot
  ;; Set some plot parameters
  panelsize = [ 15, 7.5 ]
  xrange = [-3,3]
  yrange = [0,3]
  ss = .8
  cs = .75

  ;; Make the plot
  ans = plotposn( size=panelsize, cen=[ 7.5, 3.75 ], /region )
  mvn_cylplot_panel, $
     trange = trange, res = 60d0, $
     xrange = xrange, yrange= yrange, $
     /showperiapsis, /showticks, /noerase, $
     symsize = ss, charsize = cs, $
     orbitcolortable = traj_ct

;;; Create the groundtrack plot
  ;; Set some plot parameters
  panelsize = [ 15, 7.5 ]
  ss = .8
  cs = .75

  ;; Make the ground track plot
  ans = plotposn( size=panelsize, cen=[ 22.5, 3.75 ], /region )
  mvn_groundtrack_panel, $
     trange = trange, res = 60d0, $
     /terminator, /noerase, /crustalfields,$
     /showperiapsis, /showticks, $
     symsize = ss, charsize = cs, overlay = overlay, $
     orbitcolortable = traj_ct


  

;;; Create the projection from the viewpoint of EMM
  panelsize = [ 13, 16 ]
  xrange = [-1, 1]*1.3
  yrange = [-1, 1]*1.3*16.0/13
  ss = 1

  ;; Make the plot
  ans = plotposn( size=panelsize, cen=[ 38, 9.0 ], /region )
  mvn_threed_projection_panel, $
     trange=trange, res=10d0, overlay = overlay,$
     /noerase, obspos =overlay.obsPOS,$
     xrange = xrange, yrange = yrange, $
     /showperiapsis, /showticks, /crustalfields,$
     symsize = ss, orbitcolortable = traj_ct
  

  
;;; Create the MAVEN timebar
  color = colorscale( t, mindat=min(trange), maxdat=max(trange), $
                      mincol=20, maxcol=250 )
  store_data, $
     'mavenbar', $
     data={ x:t, $
            y:[[color],[color]], $
            v:[0,1] }
  
  options, 'mavenbar', 'ytitle', 'MAVEN!cORBIT'
  options, 'mavenbar', 'yticks', 1
  options, 'mavenbar', 'yminor', 1
  options, 'mavenbar', 'ytickname', [' ',' ']
  options, 'mavenbar', 'spec', 1
  options, 'mavenbar', 'no_color_scale', 1
  options, 'mavenbar', 'panel_size', 0.9
  
  time_stamp, /off
  tplot_options, 'xmargin', [10,3]
  tplot_options, 'ymargin', [1,1]
  tplot_options, 'noerase', 1
  tplot_options, 'charsize', .7
  tplot_options, 'region', [0.675*45.0/60,0.03,0.975*45.0/60,0.27]
  loadct, traj_ct, rgb=rgb
  rgb[255,*] = 255
  rgb[0,*] = 0
  tvlct, rgb[*,0], rgb[*,1], rgb[*,2]

; check to see if emus tplot variables already exist
  names = tnames()
  emus_present = where(names eq 'emus_O_1304')
  
  if emus_present lt 0 then message, 'Must run emm_emus_image_bar.pro first!!'

; Make a copy of the O 1304 tplot variable, so as not to mess with the
; original
  Get_data, 'emus_O_1304', data=dd, dlimit=dl, limit=ll
  Store_data, 'emus_O_1304_copy', data=dd, dlimit=dl, limit=ll

  options, 'emus_O_1304_copy',  'ytitle', 'Pixel'
  Options, 'emus_O_1304_copy', 'no_color_scale', 1
  Options, 'emus_O_1304_copy', 'color_table', overlay.color_table
  Options, 'emus_O_1304_copy', 'panel_size', 1.1
  options, 'mvn_alt', 'panel_size', 1.1
  options, 'mvn_alt', 'ytitle', 'MAVEN!cALT, km'
  options, 'mvn_alt', 'yticks', 2
  options, 'mvn_alt', 'ystyle', 1
  options, 'mvn_alt', 'yrange', [100,  10000]

  Options, 'mavenbar', 'color_table',traj_ct
  options,'mavenbar', 'panel_size', 0.5

  timespan, trange

  ;tplot, ['mvn_alt', 'mavenbar', 'emus_O_1304_copy'], trange = trange

;;; create the EMUS time bar
  ; emm_emus_maven_ql, time_range, disk = disk


;;; Create the image brightness bar
  If keyword_set (overlay) then begin
     loadct2, overlay.color_table
     draw_color_scale,range=overlay.range,brange=[7, 254],log=overlay.log,yticks=6,$
         position=[0.658*0.75, 0.3, 0.675*0.75,0.85],charsize = 1.1,title=$
                      overlay.description + ' brightness, R'
     
  endif

; assume that emm_emus_maven_ql has been run

;;; create lots of tplot variables
 tplot_options, 'xmargin', [10,3]
  tplot_options, 'ymargin', [1,1]
  tplot_options, 'noerase', 1
  tplot_options, 'charsize', .7
  tplot_options, 'region', [1.0*45.0/60,0.03, 0.97,0.95]
 
  loadct2, 39
Tplot, ['mvn_swis_en_eflux',  'mvn_sun','mvn_swe_etspec','mvn_sta_c0_e'    , $         
        'mvn_sta_c0_h_e', ' mvn_sta_c6_m',  'mvn_mag_bamp', $
          'mvn_mag_cone_clock', 'alt2', 'mavenbar', 'emus_O_1304_copy']

;;; Make title
  xyouts, /normal, 0.5, 0.95, charsize=1.5, al=0.5, $
          'Time: ' +time_string (overlay.time) +'   Emission: '+$
          overlay.description + '   File: '+overlay.filename+ ' '

; add labels to orient viewer
  ylabel = 0.892
  xyouts, /normal,5.5/60.0,ylabel, 'View from above', align = 0.5, charsize = 1.3
  xyouts, /normal,15.5/60.0,ylabel, 'View from dawn', align = 0.5, charsize = 1.3
  xyouts, /normal,25.5/60.0,ylabel, 'View toward sun', align = 0.5, charsize = 1.3
  
  xyouts, /normal,43.5/60.0,0.22, 'View from Hope', align = 1.0, charsize = 1.3
;;; Clean up
  if keyword_set(screen) eq 0 then begin
     ps_set, -1
     spawn, 'convert -density 300 ' + fileroot + '.eps ' + $
            fileroot + '.jpg'
     spawn, 'rm ' + fileroot + '.eps'
  endif
  
  cleanup

end
