;+
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; mvn_orbql_barebones_eph.pro
;
; A heavily reduced version of Dave Brain's original ephemeris retrieval function
; to be compatible with making the mvn_orb_ql plots. Retrieves
; MSO, GEO, altitude, latitude, longitude, and orbit number for a given time range.
;
; Syntax:
;      mvn_orbql_barebones_eph, trange, 30d0
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
; 30 June, 2017 - Update to include plasma regions
; 9 Feb 2023 - Reduced to only necessary
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;-
pro mvn_orbql_barebones_eph, trange, res
  
;;; Figure out time resolution
  if n_params() lt 2 then res = 60d0

  ; print, trange
  ; stop
  
;;; Make time array based on trange
   dur = time_double(trange[1]) - time_double(trange[0])
   num = floor(dur/double(res)) + 1
   time = dindgen(num)*res + time_double(trange[0])

;;; Retrieve MVN position in Geographic coordinates
   geo_cart = spice_body_pos( 'MAVEN', 'MARS', frame='IAU_MARS', utc=time )

;;; Find altitude
   ; RDJ: changed from ancient code (mav_get_altitude)
   ; to modern mvn_altitude, borrowed code from maven_orbit_tplot:
   ; mav_get_altitude, lon, lat, rad, alt, /areoid
   ; print, time

   datum = 'areoid'
   print,"Reference surface for calculating altitude: ",strlowcase(datum)
   mvn_altitude, cart=geo_cart, datum=datum, result=dat
   alt = dat.alt
   lon = dat.lon
   lat = dat.lat
   undefine, dat


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
   store_data, 'mvn_alt', data={ x:time, y:alt }
   options, 'mvn_alt', 'ylog', 1
   options, 'mvn_alt', 'ytitle', 'Alt!C!C(km)'

;;; Retrieve MVN position in MSO coordinates
   mso_cart = spice_body_pos( 'MAVEN', 'MARS', frame='MAVEN_MSO', utc=time )

;;; Store MSO in tplot
   store_data, 'mvn_eph_mso', data={ x:time, y:mso_cart }

   orbnum = mvn_orbit_num(time=time)
   store_data,'orbnum',data={x:time, y:orbnum}

      
end
