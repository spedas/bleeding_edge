;+
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; mvn_orbql_scposition.pro
;
; A centralization of all calculated parameters that are plotted
; in each panel of mvn_orb_ql by mvn_orbql_cart_panel, mvn_orbql_cylplot_panel,
; mvn_orbql_groundtrack_panel, and mvn_orbql_3d_projection_panel.
;
; For a given time range, returns structures containing
; - tick locations (ticks)
; - periapse location (periapse)
; - apoapse information (apoapse)
; - any additional location on MAVEN's path (interest_point)
;
; Syntax:
;      mvn_orbql_scposition, trange, ticks, /showperiapsis
;
; Inputs:
;      trange            - timerange over which to load ephemeris
;
; Dependencies:
;      uses structures created by mvn_orbql_barebones_eph
;
; 9 Feb 2023 - Created by Rebecca Jolitz, originally written in
;              the plotting routines
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;-


pro mvn_orbql_scposition, trange, ticks, periapse, apoapse, interest_point,$
     interest_time=interest_time, tickinterval=tickinterval,$
     showperiapsis=showperiapsis, showapoapsis=showapoapsis

     if n_elements(tickinterval) eq 0 then tickinterval = 600d0

     ; print, showperiapsis, showapoapsis

     get_data, 'mvn_eph_mso', time, mso
     get_data, 'mvn_eph_geo', time, geo

     Rm = 3390.
     mso /= Rm
     geo /= Rm

     times_hires = dindgen( trange[1] - trange[0] + 1 ) + trange[0]
     x_mso_hires = spline( time, mso[0,*], times_hires )
     y_mso_hires = spline( time, mso[1,*], times_hires )
     z_mso_hires = spline( time, mso[2,*], times_hires )

     ; observer info for 3d projection plot
     obstime = mean(trange)

     obsx = spline( time, mso[0,*], obstime )
     obsy = spline( time, mso[1,*], obstime )
     obsz = spline( time, mso[2,*], obstime )

     obssph = cv_coord( from_rect=[obsx, obsy, obsz], /to_sphere, /double )
     obslon = double( reform( obssph[0] ) )
     obslat = double( reform( obssph[1] ) )
     obslon = obslon[0]
     obslat = obslat[0]

     x_geo_hires = spline( time, geo[0,*], times_hires )
     y_geo_hires = spline( time, geo[1,*], times_hires )
     z_geo_hires = spline( time, geo[2,*], times_hires )

     r_hires = sqrt( x_mso_hires^2 + y_mso_hires^2 + z_mso_hires^2 )

     ; periapsis retrieval
     minrad = min(r_hires, periind)
     peri_t = times_hires[periind]

     ; Mso coordinates
     peri_mso_x = x_mso_hires[periind]
     peri_mso_y = y_mso_hires[periind]
     peri_mso_z = z_mso_hires[periind]

     ; projection of xyz in obs time FOV
     mvn_orbql_obsview, $
        peri_mso_x, peri_mso_y, peri_mso_z, $
        proj_3d_perix, proj_3d_periy, proj_3d_periz, $
        lon = obslon, lat = obslat

     ; Geo coordinates
     peri_geo_x = x_geo_hires[periind]
     peri_geo_y = y_geo_hires[periind]
     peri_geo_z = z_geo_hires[periind]

     ; Lat/lon info
     peri_geo_xyz = [peri_geo_x, peri_geo_y, peri_geo_z]
     peri_geo_sph = cv_coord( from_rect=peri_geo_xyz, $
                         /to_sphere, /double )
     peri_lon = ( reform( peri_geo_sph[0,*] ) * !radeg + 360. ) mod 360.
     peri_lat = reform( peri_geo_sph[1,*] ) * !radeg

     ; Show periapsis as black cross
     ; peri_marker = mvn_orbql_symcat(34)
     peri_marker = 34

     if keyword_set(showperiapsis) then begin
          periapse = {t: peri_t, x: peri_mso_x, y: peri_mso_y, z: peri_mso_z,$
                      lon: peri_lon, lat: peri_lat,$
                      m: peri_marker, ss: 1.5,$
                      proj_x: proj_3d_perix, proj_y: proj_3d_periy,$
                      proj_z: proj_3d_periz}
     endif

     ; Apoapsis retrieval
     aporad = max(r_hires, apoind)
     apo_mso_x = x_mso_hires[apoind]
     apo_mso_y = y_mso_hires[apoind]
     apo_mso_z = z_mso_hires[apoind]
     apo_t = times_hires[apoind]

     ; projection of xyz in obs time FOV
     mvn_orbql_obsview, $
        apo_mso_x, apo_mso_y, apo_mso_z, $
        proj_3d_apox, proj_3d_apoy, proj_3d_apoz, $
        lon = obslon, lat = obslat

     ; Show apoapse as Filled square.
     ; apo_marker = mvn_orbql_symcat(15)
     apo_marker = 15

     if keyword_set(showapoapsis) then begin
          apoapse = {t: apo_t, x: apo_mso_x, y: apo_mso_y, z: apo_mso_z,$
                     m :apo_marker, ss: 1.5,$
                     proj_x: proj_3d_apox, proj_y: proj_3d_apoy,$
                     proj_z: proj_3d_apoz}
     endif

     if keyword_set(interest_time) then begin

          t_i = time_double(interest_time)
          x_i = spline( time, mso[0,*], t_i )
          y_i = spline( time, mso[1,*], t_i )
          z_i = spline( time, mso[2,*], t_i )

          x_geo_i = spline( time, geo[0,*], t_i )
          y_geo_i = spline( time, geo[1,*], t_i )
          z_geo_i = spline( time, geo[2,*], t_i )

          geo_sph_i = cv_coord( from_rect=[x_geo_i, y_geo_i, z_geo_i], $
                         /to_sphere, /double )
          lon_i = ( reform( geo_sph_i[0,*] ) * !radeg + 360. ) mod 360.
          lat_i = reform( geo_sph_i[1,*] ) * !radeg

          ; projection of xyz in obs time FOV
          mvn_orbql_obsview, $
             x_i, y_i, z_i, $
             proj_3d_x_i, proj_3d_y_i, proj_3d_z_i, $
             lon = obslon, lat = obslat

          ; interest_marker = mvn_orbql_symcat(36)
          interest_marker = 36
          interest_point = {t: t_i, x: x_i, y: y_i, z: z_i,$
                            lat: lat_i, lon: lon_i, m: interest_marker, ss: 2.0,$
                            proj_x: proj_3d_x_i, proj_y: proj_3d_y_i,$
                            proj_z: proj_3d_z_i}

     endif


     ;; Make ticks structure
     timeinterval = trange[1]-trange[0]
     ticktimes = [peri_t]
     ; ticktimes = [apot]

     curtime = peri_t - tickinterval
     while curtime gt trange[0] do begin
        ticktimes = [ curtime, ticktimes ]
        curtime -= tickinterval
     endwhile
     curtime = peri_t + tickinterval
     while curtime lt trange[1] do begin
        ticktimes = [ ticktimes, curtime ]
        curtime += tickinterval
     endwhile
     tickxdat = spline( time, mso[0,*], ticktimes )
     tickydat = spline( time, mso[1,*], ticktimes )
     tickzdat = spline( time, mso[2,*], ticktimes )

     ; projection in 3d plane

     mvn_orbql_obsview, $
        reform( tickxdat), reform( tickydat ), reform( tickzdat ), $
        proj_tickx, proj_ticky, proj_tickz, $
        lon = obslon, lat = obslat

     ;; Get times to show
     tickxgeo = spline( time, geo[0,*], ticktimes )
     tickygeo = spline( time, geo[1,*], ticktimes )
     tickzgeo = spline( time, geo[2,*], ticktimes )
     geo_sph = cv_coord( from_rect=transpose( [ [tickxgeo], $
                                                [tickygeo], $
                                                [tickzgeo] ] ), $
                         /to_sphere, /double )
     ticklon = ( reform( geo_sph[0,*] ) * !radeg + 360. ) mod 360.
     ticklat = reform( geo_sph[1,*] ) * !radeg

     ; tickm = mvn_orbql_symcat(14)
     tickm = 14

     ticks = {t: ticktimes, x: tickxdat, y: tickydat, z: tickzdat, m: tickm, ss: 0.5,$
              lon:ticklon, lat: ticklat,$
              proj_x: proj_tickx, proj_y: proj_ticky,$
              proj_z: proj_tickz}

  ; return

end