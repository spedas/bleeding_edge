;+
;PROCEDURE:   mvn_sta_cio_convert
;PURPOSE:
;  Converts array-of-structures to structure-of-arrays.  Also performs
;  several calculations and adds structure elements.
;
;INPUTS:
;     data  : A named variable to hold the data.  Reformatted data are
;             returned in same variable.
;
;KEYWORDS:
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2020-05-01 12:26:38 -0700 (Fri, 01 May 2020) $
; $LastChangedRevision: 28659 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swea/mvn_sta_cio_convert.pro $
;
;CREATED BY:	David L. Mitchell
;FILE:  mvn_sta_cio_convert.pro
;-
pro mvn_sta_cio_convert, data

    npts = n_elements(data.time)
    tags = tag_names(data)

; Some filters to exclude unreliable results

  mintemp = 0.1  ; minimum ion temperature

; Geodetic parameters for Mars (from the 2009 IAU Report)
;   Archinal et al., Celest Mech Dyn Astr 109, Issue 2, 101-135, 2011
;     DOI 10.1007/s10569-010-9320-4
;   These are the values used by SPICE (pck00010.tpc).
;   Last update: 2017-05-29.

    R_equ = 3396.19D  ; +/- 0.1
    R_pol = 3376.20D  ; N pole = 3373.19 +/- 0.1 ; S pole = 3379.21 +/- 0.1
    R_vol = 3389.50D  ; +/- 0.2

    R_m = R_vol       ; use the mean radius for converting to Mars radii

    odata = mvn_sta_cio_struct()
    str_element, odata, 'v_sc_x', !values.f_nan, /add
    str_element, odata, 'v_sc_y', !values.f_nan, /add
    str_element, odata, 'v_sc_z', !values.f_nan, /add
    str_element, odata, 'vel_x', !values.f_nan, /add
    str_element, odata, 'vel_y', !values.f_nan, /add
    str_element, odata, 'vel_z', !values.f_nan, /add
    str_element, odata, 'vel_phi', !values.f_nan, /add
    str_element, odata, 'vel_the', !values.f_nan, /add
    str_element, odata, 'vratio', !values.f_nan, /add
    str_element, odata, 'fbulk', !values.f_nan, /add

    odata    = {time     : dblarr(npts)  , $   ; time
                den_i    : fltarr(npts)  , $   ; ion number density (1/cc)
                den_e    : fltarr(npts)  , $   ; electron number density (1/cc)
                temp     : fltarr(npts)  , $   ; ion temperature (eV)
                v_sc_x   : dblarr(npts)  , $   ; spacecraft X velocity (km/s)
                v_sc_y   : dblarr(npts)  , $   ; spacecraft Y velocity (km/s)
                v_sc_z   : dblarr(npts)  , $   ; spacecraft Z velocity (km/s)
                v_tot    : dblarr(npts)  , $   ; spacecraft speed (km/s)
                vel_x    : dblarr(npts)  , $   ; ion bulk X velocity in MSO frame (km/s)
                vel_y    : dblarr(npts)  , $   ; ion bulk Y velocity in MSO frame (km/s)
                vel_z    : dblarr(npts)  , $   ; ion bulk Z velocity in MSO frame (km/s)
                vel_s    : dblarr(npts)  , $   ; ion bulk S velocity in MSO frame (km/s)
                vel_r    : dblarr(npts)  , $   ; ion bulk radial velocity w.r.t. Mars (km/s)
                vel_xe   : dblarr(npts)  , $   ; ion bulk X velocity in MSE frame (km/s)
                vel_ye   : dblarr(npts)  , $   ; ion bulk Y velocity in MSE frame (km/s)
                vel_ze   : dblarr(npts)  , $   ; ion bulk Z velocity in MSE frame (km/s)
                vbulk    : dblarr(npts)  , $   ; ion bulk speed (km/s)
                vel_phi  : dblarr(npts)  , $   ; ion bulk speed phi in YZ plane (deg)
                vel_the  : dblarr(npts)  , $   ; ion bulk speed theta w.r.t. X (deg)
                v_esc    : dblarr(npts)  , $   ; escape velocity (km/s)
                vratio   : dblarr(npts)  , $   ; V_ion/V_esc
                fbulk    : dblarr(npts)  , $   ; vbulk * den_i (cm-2 s-1)
                fradial  : dblarr(npts)  , $   ; vel_r * den_i (cm-2 s-1)
                logfrad  : dblarr(npts)  , $   ; sign(fradial) * log(abs(fradial))
                v_app_x  : dblarr(npts)  , $   ; ion bulk X velocity in APP frame (km/s)
                v_app_y  : dblarr(npts)  , $   ; ion bulk Y velocity in APP frame (km/s)
                v_app_z  : dblarr(npts)  , $   ; ion bulk Z velocity in APP frame (km/s)
                Bmag     : fltarr(npts)  , $   ; magnetic field amplitude (nT)
                Bphi     : fltarr(npts)  , $   ; magnetic field MSO phi   (nT)
                Bthe     : fltarr(npts)  , $   ; magnetic field MSO theta (nT)
                Psw      : fltarr(npts)  , $   ; upstream solar wind dynamic pressure (nPa)
                Bclk     : fltarr(npts)  , $   ; upstream IMF clock angle (0 = east, pi = west)
                energy   : dblarr(npts)  , $   ; ion kinetic energy (eV)
                VB_phi   : dblarr(npts)  , $   ; angle between V and B (deg)
                VI_phi   : fltarr(npts)  , $   ; angle between V and APP-i (deg)
                VK_the   : fltarr(npts)  , $   ; angle between V and APP-ij plane (deg)
                sc_pot   : fltarr(npts)  , $   ; spacecraft potential (V)
                mass     : 0.            , $   ; assumed ion mass (amu)
                mrange   : [0.,0.]       , $   ; mass range for integration (amu)
                frame    : ''            , $   ; reference frame (for all vectors)
                shp_a    : fltarr(npts)  , $   ; e- shape parameter: away
                shp_t    : fltarr(npts)  , $   ; e- shape parameter: toward
                ratio    : fltarr(npts)  , $   ; e- flux ratio (away/toward)
                flux40   : fltarr(npts)  , $   ; e- energy flux at 40 eV
                topo     : intarr(npts)  , $   ; topology index (see below)
                region   : intarr(npts)  , $   ; plasma region index
                mso_x    : fltarr(npts)  , $   ; MSO X coordinate of spacecraft
                mso_y    : fltarr(npts)  , $   ; MSO Y coordinate of spacecraft
                mso_z    : fltarr(npts)  , $   ; MSO Z coordinate of spacecraft
                mso_s    : fltarr(npts)  , $   ; sqrt(mso_y^2. + mso_z^2.)
                mse_x    : fltarr(npts)  , $   ; MSE X coordinate of spacecraft
                mse_y    : fltarr(npts)  , $   ; MSE Y coordinate of spacecraft
                mse_z    : fltarr(npts)  , $   ; MSE Z coordinate of spacecraft
                sza      : fltarr(npts)  , $   ; solar zenith angle
                glon     : fltarr(npts)  , $   ; GEO longitude of spacecraft
                glat     : fltarr(npts)  , $   ; GEO latitude of spacecraft
                alt      : fltarr(npts)  , $   ; spacecraft altitude (ellipsoid)
                slon     : fltarr(npts)  , $   ; GEO longitude of sub-solar point
                slat     : fltarr(npts)  , $   ; GEO latitude of sub-solar point
                Mdist    : fltarr(npts)  , $   ; Mars-Sun distance (A.U.)
                L_s      : fltarr(npts)  , $   ; Mars season (L_s)
                sthe     : fltarr(npts)  , $   ; elevation of Sun in s/c frame
                sthe_app : fltarr(npts)  , $   ; elevation of Sun in APP frame
                rthe_app : fltarr(npts)  , $   ; elevation of MSO RAM in APP frame
                apid     : replicate('  ',npts) , $   ; STATIC APID used for calculation
                flag     : intarr(npts)  , $   ; CIO configuration flag
                valid    : intarr(npts)     }

    odata.time = data.time
    odata.den_i = data.den_i
    odata.den_e = data.den_e
    odata.temp = data.temp
    indx = where(odata.temp lt mintemp, count)
    if (count gt 0L) then odata.temp[indx] = !values.f_nan
    odata.v_sc_x = data.v_sc[0]
    odata.v_sc_y = data.v_sc[1]
    odata.v_sc_z = data.v_sc[2]
    odata.v_tot = data.v_tot
    odata.vel_x = data.v_mso[0]
    odata.vel_y = data.v_mso[1]
    odata.vel_z = data.v_mso[2]
    odata.vel_s = sqrt(odata.vel_y^2. + odata.vel_z^2.)

    sc = transpose(data.mso)
    sc /= (sqrt(total(sc*sc,2)) # replicate(1.,3))
    odata.vel_r = total(sc*transpose(data.v_mso),2)

    i = where(tags eq 'V_MSE')
    if (i ge 0) then begin
      odata.vel_xe = data.v_mse[0]
      odata.vel_ye = data.v_mse[1]
      odata.vel_ze = data.v_mse[2]
    endif
    odata.vbulk = data.vbulk
    odata.vel_phi = atan(odata.vel_z, odata.vel_y)*!radeg
    indx = where(odata.vel_phi lt 0., count)
    if (count gt 0L) then odata.vel_phi[indx] += 360.
    odata.vel_the = acos(odata.vel_x/odata.Vbulk)*!radeg
    odata.v_app_x = data.v_app[0]
    odata.v_app_y = data.v_app[1]
    odata.v_app_z = data.v_app[2]
    odata.v_esc = data.v_esc
    odata.vratio = data.vbulk/data.v_esc
    odata.fbulk = 1d5*data.vbulk*data.den_i
    odata.fradial = 1d5*odata.vel_r*odata.den_i
    indx = where(finite(odata.fradial),count)
    if (count gt 0L) then begin
      odata.logfrad[indx] = signum(odata.fradial[indx])*alog10(abs(odata.fradial[indx]) > 1.)
    endif
    Bx = data.magf[0]
    By = data.magf[1]
    Bz = data.magf[2]
    odata.Bmag = sqrt(Bx*Bx + By*By + Bz*Bz)
    odata.Bphi = atan(By, Bx)*!radeg
    indx = where(odata.Bphi lt 0., count)
    if (count gt 0L) then odata.Bphi[indx] += 360.
    odata.Bthe = asin(Bz/odata.Bmag)*!radeg
    i = where(tags eq 'SW_PRESS')
    if (i ge 0) then begin
      odata.Psw = data.sw_press
      odata.Bclk = data.imf_clk * !radeg
      indx = where(odata.Bclk lt 0., count)
      if (count gt 0L) then odata.Bclk[indx] += 360.
    endif
    odata.energy = data.energy
    odata.VB_phi = acos(abs(cos(data.VB_phi/!radeg)))*!radeg
    odata.VI_phi = data.VI_phi
    odata.VK_the = data.VK_the
    odata.sc_pot = data.sc_pot
    i = (where(finite(data.mass)))[0]
    odata.mass = data[i].mass
    odata.mrange = data[i].mrange
    odata.frame = data[i].frame
    odata.shp_a = data.shape[0]
    odata.shp_t = data.shape[1]
    odata.ratio = data.ratio
    odata.flux40 = data.flux40
    odata.mso_x = data.mso[0]/R_m
    odata.mso_y = data.mso[1]/R_m
    odata.mso_z = data.mso[2]/R_m
    i = where(tags eq 'MSE')
    if (i ge 0) then begin
      odata.mse_x = data.mse[0]/R_m
      odata.mse_y = data.mse[1]/R_m
      odata.mse_z = data.mse[2]/R_m
    endif
    odata.mso_s = sqrt(odata.mso_y^2. + odata.mso_z^2.)
    odata.sza = atan(odata.mso_s, odata.mso_x)*!radeg
    geo_r = sqrt(data.geo[0]^2. + data.geo[1]^2. + data.geo[2]^2.)
    odata.glon = atan(data.geo[1], data.geo[0])*!radeg
    indx = where(odata.glon lt 0., count)
    if (count gt 0L) then odata.glon[indx] += 360.
    odata.glat = asin(data.geo[2]/geo_r)*!radeg
    odata.alt = data.alt
    odata.slon = data.slon
    indx = where(odata.slon lt 0., count)
    if (count gt 0L) then odata.slon[indx] += 360.
    odata.slat = data.slat
    odata.Mdist = data.Mdist
    odata.L_s = data.L_s
    odata.sthe = data.sthe
    odata.sthe_app = data.sthe_app
    odata.rthe_app = data.rthe_app
    odata.apid = data.apid
    odata.valid = data.valid

; Fix MSO --> MSE transformation

    cosclk = cos(odata.Bclk * !dtor)
    sinclk = sin(odata.Bclk * !dtor)

    odata.vel_ye = (odata.vel_y * cosclk) + (odata.vel_z * sinclk)
    odata.vel_ze = (odata.vel_z * cosclk) - (odata.vel_y * sinclk)

    odata.mse_y  = (odata.mso_y * cosclk) + (odata.mso_z * sinclk)
    odata.mse_z  = (odata.mso_z * cosclk) - (odata.mso_y * sinclk)

; Magnetic Field Topology

    if (1) then begin

; Topology index array (Xu-Weber method)
;   0-?   unknown
;   1-CD  closed to day
;   2-CX  closed cross terminator
;   3-CT  closed trapped (closed to night)
;   4-CV  closed void (closed to night)
;   5-OD  open to day
;   6-ON  open to night
;   7-D   draped
;
;   All types of closed loops (1-4) are combined into one.
;   0 = unknown, 1 = closed, 2 = open to day, 3 = open to night, 4 = draped

      odata.topo = data.topo  ; Xu-Weber method

    endif else begin

; Topology index array (Xu method with voids & flux ratios)
;   0 = unknown (typically insufficient pitch angle coverage)
;   1 = closed (both footpoints on day side)
;   2 = closed (cross terminator)
;   3 = closed (both footpoints on night side)
;   4 = open (one footpoint on day side)
;   5 = open (one footpoint on night side)
;   6 = draped

      indx = where((odata.shp_a le 1.) and (odata.shp_t le 1.), count)
      if (count gt 0) then odata.topo[indx] = 1

      indx = where((odata.shp_a gt 1.) and (odata.shp_t le 1.) and (odata.sza gt 80.), count)
      if (count gt 0) then odata.topo[indx] = 2

      indx = where(odata.flux40 le 1., count)
      if (count gt 0) then odata.topo[indx] = 3

      indx = where(((odata.shp_a le 1.) and (odata.shp_t gt 1.)) or $
                   ((odata.shp_a gt 1.) and (odata.shp_t le 1.) and (odata.sza le 80.)), count)
      if (count gt 0) then odata.topo[indx] = 4

      other = where((odata.shp_a gt 1.) and (odata.shp_t gt 1.), count)
     if (count gt 0) then begin
        indx = where((odata.sza[other] ge 100.) and (odata.ratio[other] le 0.75), cnt1, $
                     comp=jndx, ncomp=cnt2)

        if (cnt1 gt 0) then odata.topo[other[indx]] = 5
        if (cnt2 gt 0) then odata.topo[other[jndx]] = 6
      endif
    endelse

; CIO configuration flag

    indx = where(abs(odata.sthe - 45.) lt 5., count)
    if (count gt 0) then odata.flag[indx] = 1  ; SWEA is optimized (twist)
    indx = where((abs(odata.sthe_app) le 5.) and $
                 (abs(odata.rthe_app) le 10.), count)
    if (count gt 0) then odata.flag[indx] = 2  ; STATIC is optimized (APP orientation)
    indx = where((abs(odata.sthe - 45.) lt 5.) and $
                 (abs(odata.sthe_app) le 5.) and $
                 (abs(odata.rthe_app) le 10.), count)
    if (count gt 0) then odata.flag[indx] = 3  ; both STATIC and SWEA are optimized

; Stuff the result back into data

    data = temporary(odata)

  return

end
