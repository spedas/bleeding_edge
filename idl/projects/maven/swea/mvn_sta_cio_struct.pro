;+
;FUNCTION:   mvn_sta_cio_struct
;
;PURPOSE:
;  Creates a Cold Ion Outflow data structure.
;
;INPUTS:
;       NPTS:     Number of elements.  Default = 1.
;
;KEYWORDS: 
;
;CREATED BY:      D. L. Mitchell.
;
;LAST MODIFICATION:
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2018-09-09 18:05:59 -0700 (Sun, 09 Sep 2018) $
; $LastChangedRevision: 25764 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swea/mvn_sta_cio_struct.pro $
;
;-
function mvn_sta_cio_struct, npts

  NaN = !values.f_nan
  NaN3 = replicate(NaN,3)
  dNaN = !values.d_nan
  dNaN3 = replicate(dNaN,3)

  if (size(npts,/type) eq 0) then npts = 1

  cio_str = {time     : dNaN        , $   ; time
             den_i    : NaN         , $   ; ion number density (1/cc)
             den_e    : NaN         , $   ; electron number density (1/cc)
             temp     : NaN         , $   ; ion temperature (eV)
             v_sc     : dNaN3       , $   ; spacecraft velocity in MSO frame (km/s)
             v_tot    : dNaN        , $   ; spacecraft speed in MSO frame (km/s)
             v_mso    : dNaN3       , $   ; ion bulk velocity in MSO frame (km/s)
             v_mse    : dNaN3       , $   ; ion bulk velocity in MSE frame (km/s)
             vbulk    : dNaN        , $   ; ion bulk speed in MSO/MSE frame (km/s)
             v_app    : dNaN3       , $   ; ion bulk velocity in APP frame (km/s)
             v_esc    : dNaN        , $   ; local escape velocity (km/s)
             magf     : NaN3        , $   ; magnetic field in MSO frame (nT)
             energy   : dNaN        , $   ; ion kinetic energy (eV)
             VB_phi   : dNaN        , $   ; angle between V and B (deg)
             VI_phi   : NaN         , $   ; angle between V and APP-i (deg)
             VK_the   : NaN         , $   ; angle between V and APP-ij plane (deg)
             sc_pot   : NaN         , $   ; spacecraft potential (V)
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
             alt      : NaN         , $   ; spacecraft altitude (ellipsoid)
             slon     : NaN         , $   ; GEO longitude of sub-solar point
             slat     : NaN         , $   ; GEO latitude of sub-solar point
             Mdist    : NaN         , $   ; Mars-Sun distance (A.U.)
             L_s      : NaN         , $   ; Mars season (L_s)
             sthe     : NaN         , $   ; elevation of Sun in s/c frame (SWEA twist)
             sthe_app : NaN         , $   ; elevation of Sun in APP frame (STA CIO config)
             rthe_app : NaN         , $   ; elevation of MSO RAM in APP frame (STA CIO config)
             apid     : ''          , $   ; STATIC APID used for calculation
             valid    : 0              }

  if (npts gt 1) then return, replicate(cio_str, npts) $
                 else return, cio_str

end
