;+
;NAME:
; mvn_qlook_mag_geom
;PURPOSE:
; Wrapper for MVN_MAG_GEOM that loads mag data, and Spice kernels 
;CALLING SEQUENCE:
; mvn_qlook_mag_gemp, trange=trange, alt=alt, var=var
;INPUT:
; None explicit
;OUTPUT:
; tplot variables for B field
;KEYWORDS: (passed into mvn_mag_geom)
; trange = If set, use this time range
; alt = Electron absorption altitude.  Default = 170 km.
; var = Tplot variable name that contains the magnetic field data
;       in payload coordinates.  Default = 'mvn_B_1sec'.  Variable
;       names for MAG data in other frames are derived from this.
;HISTORY:
; 6-oct-2015, jmm, jimm@ssl.berkeley.edu
; $LastChangedBy: jimm $
; $LastChangedDate: 2015-10-06 13:54:55 -0700 (Tue, 06 Oct 2015) $
; $LastChangedRevision: 19016 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/quicklook/mvn_qlook_mag_geom.pro $
;-
Pro mvn_qlook_mag_geom, trange=trange, alt=alt, var=var, _extra=_extra


;Handle trange here
  If(keyword_set(trange)) Then Begin
     tr0 = time_double(trange)
  Endif Else Begin
     tr0 = time_double(timerange())
  Endelse

;Timespan call is needed for mvn_mag_load
  day = (tr0[1]-tr0[0])/86400.0d0
  timespan, tr0[0], day

;Load mag data and SPICE kernels
  mvn_mag_load
;Load spice kernels
  mvn_spice_load
;Call mvn_mag_geom
  mvn_mag_geom, alt=alt, var=var
;Create tplot variables for amp, azimuth, elev, dist, lon, lat
  get_data, 'mvn_B_1sec_iau_mars', data = ppp
  If(is_struct(ppp)) Then Begin
     store_data, 'mvn_B_1sec_amp', data = {x:ppp.x, y:ppp.amp}
     store_data, 'mvn_B_1sec_azim', data = {x:ppp.x, y:ppp.azim}
     store_data, 'mvn_B_1sec_elev', data = {x:ppp.x, y:ppp.elev}
     store_data, 'mvn_B_1sec_clock', data = {x:ppp.x, y:ppp.clock}
     store_data, 'mvn_B_1sec_dist', data = {x:ppp.x, y:ppp.dist}
     store_data, 'mvn_B_1sec_lon', data = {x:ppp.x, y:ppp.lon}
     store_data, 'mvn_B_1sec_lat', data = {x:ppp.x, y:ppp.lat}
  Endif

;Done
  Return
End
