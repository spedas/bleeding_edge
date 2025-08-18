;+
;PROCEDURE:   mvn_altitude
;PURPOSE:
;  Determines the altitude of MAVEN.  Altitude is defined as the distance
;  from a point (e.g., MAVEN) to a reference surface along a line normal
;  to the reference surface.  The reference surface is sometimes called the
;  "datum".  This routine recognizes four definitions of altitude:
;
;    areocentric:  The datum is a sphere with Mars' volumetric mean radius
;                  of 3389.50 km.
;
;    areodetic:    The datum is the IAU Mars ellipsoid:
;                  R_equator = 3396.19 km ; R_pole = 3376.20 km
;
;    areoid:       The datum is the Mars areoid, which is a gravitational
;                  equipotential ("sea level").  This surface is irregular
;                  but within ~2 km of the IAU Mars ellipsoid.
;
;    topographic:  The datum is the solid surface, based on laser altimeter
;                  data (MGS-MOLA).
;
;  Areocentric and areodetic longitudes are identical, while the latitudes
;  differ by less than 0.3 deg.  The altitudes can differ by more than 10 km,
;  (about an atmospheric scale height), so this is the main reason for 
;  choosing the ellipsoid (or the areoid) for the region around periapsis.
;
;  The areoid and solid surface are irregular, so areocentric longitude and 
;  latitude are used for those reference surfaces.  This is consistent with
;  usage in the literature.
;
;  The results are stored in TPLOT variables.
;
;  You must have SPICE installed for this routine to work.
;
;USAGE:
;  mvn_altitude, trange
;
;INPUTS:
;       trange:   Optional.  Time range for calculating altitude.  If not 
;                 specified, then use the current range set by timespan.
;
;KEYWORDS:
;       DT:       Time resolution (sec).  Default is to use the time resolution
;                 of maven_orbit_tplot (usually 10 sec).
;
;       CART:     A 3 x N array of cartesian coordinates in the IAU_MARS frame.
;                 If specified, then trange and DT are ignored and the result
;                 is returned via keyword RESULT.  If not specified, then try 
;                 to get this information from maven_orbit_tplot, and the result
;                 is stored in tplot variables as well as in RESULT.
;
;       DATUM:    String for specifying the datum.  Can be one of "sphere", 
;                 "ellipsoid", "areoid", or "surface".  Default = 'ellipsoid'.
;                 Minimum matching is used for this keyword.
;
;       LATLON:   Create tplot variables for latitude and longitude.  If
;                 DATUM = 'ellipsoid', then you get areodetic latitude and
;                 longitude.
;
;       RESULT:   Returns a structure containing the altitude, latitude and 
;                 longitude.  If CART is set, then each of these will have N
;                 values.  If CART is not set, then the structure will be
;                 compatible with tplot (x = time, y = altitude).
;
;       PANS:     Named variable to hold the tplot variables created.  Variable
;                 names are in the form: mvn_<par>_<dat>, where <par> is the 
;                 parameter (alt, lon, lat) and <dat> is a three-letter code
;                 for the datum (sph, ell, are, sur).
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2021-04-07 16:16:41 -0700 (Wed, 07 Apr 2021) $
; $LastChangedRevision: 29857 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/general/mvn_altitude.pro $
;
;CREATED BY:    David L. Mitchell
;-
pro mvn_altitude, trange, dt=dt, cart=cart, datum=dtm, latlon=latlon, pans=pans, $
                  result=result

  @maven_orbit_common

  mk = spice_test()
  if (mk eq 0) then begin
    print,"Please install SPICE first."
    return
  endif

; Geodetic parameters for Mars (from the 2009 IAU Report)
;   Archinal et al., Celest Mech Dyn Astr 109, Issue 2, 101-135, 2011
;     DOI 10.1007/s10569-010-9320-4
;   These are the values used by SPICE (pck00010.tpc).
;   Last update: 2017-05-29.

  R_equ = 3396.19D  ; +/- 0.1
  R_pol = 3376.20D  ; N pole = 3373.19 +/- 0.1 ; S pole = 3379.21 +/- 0.1
  R_vol = 3389.50D  ; +/- 0.2
  flat = (R_equ - R_pol)/R_equ

; Make sure the datum is valid

  dlist = ['sphere','ellipsoid','areoid','surface']
  if (size(dtm,/type) ne 7) then dtm = dlist[1]
  i = strmatch(dlist, dtm+'*', /fold)
  case (total(i)) of
     0   : begin
             print, "Datum not recognized: ", dtm
             result = 0
             return
           end
     1   : datum = (dlist[where(i eq 1)])[0]
    else : begin
             print, "Datum is ambiguous: ", dlist[where(i eq 1)]
             result = 0
             return
           end
  endcase

; If CART is provided, then calculate ALT, LON and LAT from that

  if (size(cart,/type) ne 0) then begin
    dcart = size(cart)
    if ((dcart[0] gt 2) or (dcart[1] ne 3)) then begin
      print,'CART must be a 3 x N array.'
      result = 0
      return
    endif

    case strmid(strupcase(datum),0,3) of
      'SPH' : begin
                cspice_recgeo, cart, R_vol, 0D, phi, the, dr
                phi *= !radeg
                indx = where(phi lt 0., count)
                if (count gt 0) then phi[indx] += 360.
                the *= !radeg
              end
      'ELL' : begin
                cspice_recgeo, cart, R_equ, flat, phi, the, dr
                phi *= !radeg
                indx = where(phi lt 0., count)
                if (count gt 0) then phi[indx] += 360.
                the *= !radeg
              end
      'ARE' : begin
                x = reform(cart[0,*])
                y = reform(cart[1,*])
                z = reform(cart[2,*])
                cart_to_sphere, x, y, z, r, the, phi, /ph_0_360
                dr = mvn_get_altitude(x,y,z)
              end
      'SUR' : begin
                x = reform(cart[0,*])
                y = reform(cart[1,*])
                z = reform(cart[2,*])
                cart_to_sphere, x, y, z, r, the, phi, /ph_0_360
                dr = mvn_get_altitude(x,y,z,/topographic)
              end
    endcase
    result = {alt:dr, lon:phi, lat:the, datum:datum}
    return
  endif

; Get the time range

  if (size(trange,/type) eq 0) then begin
    tplot_options, get_opt=topt
    if (max(topt.trange_full) gt time_double('2013-11-18')) then trange = topt.trange_full
    if (size(trange,/type) eq 0) then begin
      print,"You must specify a time range."
      return
    endif
  endif
  tmin = min(time_double(trange), max=tmax)

; Get the cartesian coordinates of the spacecraft in the IAU_MARS frame

  if (size(state,/type) eq 0) then maven_orbit_tplot,/load

  if keyword_set(dt) then begin
    npts = ceil((tmax - tmin)/dt)
    t = tmin + dt*dindgen(npts)
    cart = fltarr(3,npts)
    cart[0,*] = spline(state.time, state.geo_x[*,0], t)
    cart[1,*] = spline(state.time, state.geo_x[*,1], t)
    cart[2,*] = spline(state.time, state.geo_x[*,2], t)
  endif else begin
    t = state.time
    cart = transpose(state.geo_x)
  endelse
  
  indx = where((t ge tmin) and (t le tmax), count)
  if (count eq 0) then begin
    print,'No ephemeris data within time range.'
    result = 0
    return
  endif
  
  t = t[indx]
  cart = cart[*,indx]

; Calculate ALT, LON, LAT with respect to the datum.  Store the result
; in a structure that is compatible with tplot.  Make tplot variables.

  case strmid(strupcase(datum),0,3) of
    'SPH' : begin
              cspice_recgeo, cart, R_vol, 0D, phi, the, dr
              phi *= !radeg
              indx = where(phi lt 0., count)
              if (count gt 0) then phi[indx] += 360.
              the *= !radeg
            end
    'ELL' : begin
              cspice_recgeo, cart, R_equ, flat, phi, the, dr
              phi *= !radeg
              indx = where(phi lt 0., count)
              if (count gt 0) then phi[indx] += 360.
              the *= !radeg
            end
    'ARE' : begin
              x = reform(cart[0,*])
              y = reform(cart[1,*])
              z = reform(cart[2,*])
              cart_to_sphere, x, y, z, r, the, phi, /ph_0_360
              dr = mvn_get_altitude(x,y,z)
            end
    'SUR' : begin
              x = reform(cart[0,*])
              y = reform(cart[1,*])
              z = reform(cart[2,*])
              cart_to_sphere, x, y, z, r, the, phi, /ph_0_360
              dr = mvn_get_altitude(x,y,z,/topographic)
            end
  endcase

  result = {x     : t     , $   ; time
            y     : dr    , $   ; altitude (km)
            lon   : phi   , $   ; longitude (deg)
            lat   : the   , $   ; latitude (deg)
            datum : datum    }  ; datum

; Store the results in tplot

  dtm = strmid(strlowcase(datum),0,3)
  pname = 'mvn_alt_' + dtm
  store_data, pname, data=result
  options, pname, 'ytitle', 'ALT!c' + datum
  pans = [pname]

  if keyword_set(latlon) then begin
    pname = 'mvn_lon_' + dtm
    store_data, pname, data={x:t, y:phi, datum:datum}
    options, pname, 'ytitle', 'LON!c' + datum
    pans = [pans, pname]
    pname = 'mvn_lat_' + dtm
    store_data, pname, data={x:t, y:the, datum:datum}
    options, pname, 'ytitle', 'LAT!c' + datum
    pans = [pans, pname]
  endif

  return

end
