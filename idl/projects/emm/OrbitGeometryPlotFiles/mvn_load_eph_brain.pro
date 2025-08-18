;+
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; mvn_load_eph_brain.pro
;
; Procedure to create tplot variables containing ephemeris information
; at a given time resolution over a given range. I realize
; there's a routine for this in the Berkeley distribution. I
; wanted things organized my own way, and had already started creating
; something when I found it.
;
; Syntax:
;      mvn_load_eph_brain, trange, 30d0
;
; Inputs:
;      trange            - timerange over which to load ephemeris
;
;      res               - time resolution, in seconds. Default = 60
;
; Dependencies:
;      none outside of Berkeley MAVEN software (I think)
;
; Dave Brain
; 19 February, 2015 - Initial version (approximate date). Not the
;                     prettiest code ever.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;-
pro mvn_load_eph_brain, trange, res

;;; Figure out time resolution
  if n_params() lt 2 then res = 60d0
  
;;; Make time array based on trange
   dur = time_double(trange[1]) - time_double(trange[0])
   num = floor(dur/double(res)) + 1
   time = dindgen(num)*res + time_double(trange[0])

;;; Retrieve MVN position in Geographic coordinates
   Kernels =mvn_spice_kernels(['STD', 'LSK','SPK', 'FRM'],trange=trange,/load)

   geo_cart = spice_body_pos( 'MAVEN', 'MARS', frame='IAU_MARS', utc=time )

;;; Find lon/lat/rad
   geo_sph = cv_coord( from_rect=geo_cart, /to_sphere, /double )
   lon = ( reform( geo_sph[0,*] ) * !radeg + 360. ) mod 360.
   lat = reform( geo_sph[1,*] ) * !radeg
   rad = reform( geo_sph[2,*] )

;;; Find altitude
   mav_get_altitude, lon, lat, rad, alt, /areoid

;;; Store geographic info in tplot
   store_data, 'mvn_eph_geo', data={ x:time, y:geo_cart }
   store_data, 'mvn_lon', data={ x:time, y:lon }
   ylim, 'mvn_lon', 0, 360, 0
   options, 'mvn_lon', 'yticks', 4
   options, 'mvn_lon', 'ytitle', 'E Lon'
   store_data, 'mvn_lat', data={ x:time, y:lat }
   ylim, 'mvn_lat', -90, 90, 0
   options, 'mvn_lat', 'yticks', 4
   options, 'mvn_lat', 'ytitle', 'Lat'
   store_data, 'mvn_rad', data={ x:time, y:rad }
   options, 'mvn_rad', 'ytitle', 'Rad!C!C(km)'
   store_data, 'mvn_alt', data={ x:time, y:alt }
   options, 'mvn_alt', 'ylog', 1
   options, 'mvn_alt', 'ytitle', 'Alt!C!C(km)'

;;; Retrieve MVN position in MSO coordinates
   mso_cart = spice_body_pos( 'MAVEN', 'MARS', frame='MAVEN_MSO', utc=time )

;;; Find SZA, LST, SOLLAT
   mso_sph = cv_coord( from_rect=mso_cart, /to_sphere, /double )
   lst = ( ( reform( mso_sph[0,*] ) * !radeg + 540. ) mod 360. ) * 24./360.
   sollat = reform( mso_sph[1,*] ) * !radeg
   sza = reform( atan( sqrt( total( mso_cart[1:2,*]^2, 1) ), $
                       mso_cart[0,*] ) ) * !radeg

;;; Store MSO in tplot
   store_data, 'mvn_eph_mso', data={ x:time, y:mso_cart }
   store_data, 'mvn_lst', data={ x:time, y:lst }
   ylim, 'mvn_lst', 0, 24, 0
   options, 'mvn_lst', 'yticks', 4
   options, 'mvn_lst', 'ytitle', 'LT'
   store_data, 'mvn_sollat', data={ x:time, y:sollat }
   ylim, 'mvn_sollat', -90, 90, 0
   options, 'mvn_sollat', 'yticks', 4
   options, 'mvn_sollat', 'ytitle', 'Solar Latitude'
   store_data, 'mvn_sza', data={ x:time, y:sza }
   ylim, 'mvn_sza', 0, 180, 0
   options, 'mvn_sza', 'yticks', 4
   options, 'mvn_sza', 'ytitle', 'SZA'

;;; Make Sun bar
   sun = fix(time*0)
   tmp = where( mso_cart[0,*] ge 0 or $
                sqrt( mso_cart[1,*]^2 + mso_cart[2,*]^2 ) ge 3397., tmpnum )
   if tmpnum gt 0 then sun[tmp] = 1
   store_data, $
      'mvn_sun', $
      data={ x:time, $
	     y:[[sun],[sun]]*60 + 40, $
             v:[0,1] }		
   options, 'mvn_sun', 'panel_size', .15
   options, 'mvn_sun', 'spec', 1
   ylim, 'mvn_sun', 0, 1, 0
   zlim, 'mvn_sun', 0, 250, 0
   options, 'mvn_sun', 'ytitle', ' '
   options, 'mvn_sun', 'yticks', 1
   options, 'mvn_sun', 'yminor', 1
   options, 'mvn_sun', 'no_color_scale', 1
   options, 'mvn_sun', 'x_no_interp', 1
   options, 'mvn_sun', 'y_no_interp', 1
   options, 'mvn_sun', 'xstyle', 4
   options, 'mvn_sun', 'ystyle', 4

   
end
