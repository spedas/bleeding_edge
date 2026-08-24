;+
;FUNCTION:   mvn_sta_temp_struct
;
;PURPOSE:
;  Creates a temperature data structure.
;
;INPUTS:
;       NPTS:     Number of elements.  Default = 1.
;
;KEYWORDS:
;
;CREATED BY:      D. L. Mitchell as mvn_sta_cio_struct, edited by Gwen Hanley
;

;-
function mvn_sta_temp_struct, npts

  NaN = !values.f_nan
  NaN3 = replicate(NaN,3)
  NaN4 = replicate(NaN,4)
  NaN32 = replicate(NaN,32)
  dNaN = !values.d_nan
  dNaN3 = replicate(dNaN,3)

  if (size(npts,/type) eq 0) then npts = 1
  fstr = mvn_sta_tempflag_struct()

  temp_str = {time     : dNaN        , $   ; time
    temp     : NaN         , $   ; best estimate of core temperature
    dtemp    : NaN         , $   ; uncertainty of core temperature
    kintemp  : NaN4        , $   ; kinetic temperature
    prod     : NaN         , $   ; which temperature product is used; 0=c6;1=c8;2,3,4=d1/d0
    c6t      : NaN         , $   ; corrected c6 (energy) beamwidth temperature (eV)
    c6c      : NaN         , $   ; correction to c6 beamwidth temperature (eV)
    c6e      : NaN         , $   ; statistical error in c6 beamwidth temperature (eV)
    c8t      : NaN         , $   ; corrected c8 (angular) beamwidth temperature (eV)
    c8c      : NaN         , $   ; correction to c8 beamwidth temperature (eV)
    c8e      : NaN         , $   ; statistical error in c8 beamwidth temperature (eV)
;    dt10     : NaN4        , $   ; d1/d0 temperature moment restricted from 0 to 10 eV (eV)
;    dt20     : NaN4        , $   ; d1/d0 temperature moment restricted from 0 to 20 eV (eV)
    dt       : NaN4        , $   ; d1/d0 temperature moment including all energies (eV)
;    dt30r    : NaN4        , $   ; d1/d0 temperature moment restricted from 0 to 30 eV and to the ram direction (eV)
    dtc       : NaN         , $   ; correction to d0/d1 temperature (eV)
    dte       : NaN         , $   ; statistical error in d0/d1 temperature (eV)
;    modech   : NaN         , $   ; 1 if near mode/attenuator state change
    locnts   : NaN         , $   ; 1 it O2+ counts are low
    bigcorr  : NaN         , $   ; 1 if correction to provided temperature is >80%
    badscpot : NaN         , $   ; 1 if lpw data missing or scpot is too large
    vbulk    : NaN         , $   ; 1st moment of df used in tbc calculation
    vbulke   : NaN         , $   ; statistical error in the above 
    df_engy  : NaN32       , $   ; c6 energy table for the df
    df       : NaN32       , $   ; c6 df integrated over masses [24,40]
    core_A   : NaN         , $   ; amplitude of the Maxwellian fit to the core (c6 df units)
    core_T   : NaN         , $   ; temperature of the Maxwellian fit to the core (eV)
    core_v   : NaN         , $   ; bulk velocity of the Maxwellian fit to the core (km/s)
    eflux_ratio: NaN       , $   ; ratio of the eflux in the tail to the eflux in the core 
    ec_o2    : NaN         , $   ; characteristic energy of O2+ distribution (eV) 
    ec_o     : NaN         , $   ; characteristic energy of O+ distribution (eV) 
    att      : NaN         , $   ; STATIC attenuator state
    mode     : NaN         , $   ; STATIC mode
    tail     : NaN         , $   ; 1 if a significant fraction of the eflux comes from the tail
;    fovf     : NaN         , $   ; field-of-view flag from Fowler code checking STATIC FOV
    tpath    : NaN         , $   ; path taken through temp stitching code
    magf     : NaN3        , $   ; magnetic field in MSO frame (nT)
    sc_pot   : NaN         , $   ; spacecraft potential (V)
    lpw_scpot : NaN32       , $   ; offset in s/c pot calculated from lpw (V)
    mass     : NaN         , $   ; assumed ion mass (amu)
    mrange   : [NaN,NaN]   , $   ; mass range for N, V, and T moments (amu)
    erange   : [NaN,NaN]   , $   ; energy range for V and T moments (eV)
    frame    : ''          , $   ; reference frame for all vectors (except as noted)
    shape    : [NaN,NaN]   , $   ; e- shape parameter [away, toward]
    ratio    : NaN         , $   ; e- flux ratio (away/toward)
    flux40   : NaN         , $   ; e- energy flux at 40 eV
    topo     : 0           , $   ; magnetic topology index (Xu-Weber method)
    region   : 0           , $   ; plasma region index (Halekas method)
    imf_clk  : NaN         , $   ; clock angle of upstream IMF (0 = east, pi = west)
    sw_press : NaN         , $   ; dynamic pressure of upstream solar wind (nPa)
    mso      : NaN3        , $   ; MSO coordinates of spacecraft
    mse      : NaN3        , $   ; MSE coordinates of spacecraft
    geo      : NaN3        , $   ; GEO coordinates of spacecraft
    vsc_sta  : NaN3	   , $   ; STATIC frame velocity of spacecraft
    alt      : NaN         , $   ; spacecraft altitude (ellipsoid)
    slon     : NaN         , $   ; GEO longitude of sub-solar point
    slat     : NaN         , $   ; GEO latitude of sub-solar point
    Mdist    : NaN         , $   ; Mars-Sun distance (A.U.)
    L_s      : NaN         , $   ; Mars season (L_s)
    sza      : NaN         , $   ; solar zenith angle
    lst      : NaN         , $   ; local solar time
    sthe     : NaN         , $   ; elevation of Sun in s/c frame (SWEA twist)
    sthe_app : NaN         , $   ; elevation of Sun in APP frame (STA CIO config)
    rthe_app : NaN         , $   ; elevation of MSO RAM in APP frame (STA CIO config)
    inbound  : NaN         , $   ; 1 if inbound portion of orbit, 0 if outbound 
    valid    : 0              }

  if (npts gt 1) then return, replicate(temp_str, npts) $
  else return, temp_str

end
