;+
;PROCEDURE: 
;	mvn_scpot_defaults
;
;PURPOSE:
;	Sets defaults for mvn_scpot and related routines.  These are stored
;   in a common block (mvn_scpot_com).
; 
;AUTHOR: 
;	David L. Mitchell
;
;CALLING SEQUENCE: 
;	mvn_scpot_defaults
;
;INPUTS: 
;   none - simply sets defaults for the common block.
;
;KEYWORDS:
;   ERANGE:    Energy range over which to search for the potential in
;              the SWE+ method.  Default = [3.,30.]
;
;   THRESH:    Threshold for the minimum slope, d(logF)/d(logE), for 
;              the SWE+ method  Default = 0.05
;
;              A smaller value includes more data and extends the range 
;              over which you can estimate the potential, but at the 
;              expense of making more errors.
;
;   MINFLUX:   Minimum peak energy flux for the SWE+ method.
;              Default = 1e6
;
;   DEMAX:     The largest allowable energy width of the spacecraft 
;              potential feature for the SWE+ method.  This excludes 
;              features not related to the spacecraft potential at 
;              higher energies (often observed downstream of the shock).
;              Default = 6 eV
;
;   BIAS:      Voltage bias applied to the energy of the maximum slope in
;              the SWE+ method.  This corrects for the common situation
;              in which the maximum slope that is used to locate the
;              photoelectron line does not quite match the optimal value
;              of the potential.  Default = +0.5 energy bins.
;
;   ABINS:     When using 3D spectra, specify which anode bins to 
;              include in the analysis: 0 = no, 1 = yes.
;              Default = replicate(1,16)
;
;   DBINS:     When using 3D spectra, specify which deflection bins to
;              include in the analysis: 0 = no, 1 = yes.
;              Default = replicate(1,6)
;
;   OBINS:     When using 3D spectra, specify which solid angle bins to
;              include in the analysis: 0 = no, 1 = yes.
;              Default = reform(ABINS#DBINS,96).  Takes precedence over
;              ABINS and OBINS.
;
;   MASK_SC:   Mask the spacecraft blockage.  This is in addition to any
;              masking specified by the above three keywords.
;              Default = 1 (yes).
;
;   BADVAL:    If the algorithm cannot estimate the potential, then set it
;              to this value.  Units = volts.  Default = NaN.
;
;   MIN_LPW_POT : Minumum valid LPW potential.
;
;   MIN_STA_POT : Minumum valid STA potential.
;
;   MAX_STA_ALT : Maximum altitude for limiting range of STA potentials.
;
;   MIN_SWE_ALT : Minimum altitude for limiting range of SWE+ potentials.
;
;   MAXDT:     Maximum time gap to interpolate across.  Default = 64 sec.
;
;   LIST:      Take no action.  Just list the defaults.
;
;OUTPUTS:
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2024-07-25 14:47:01 -0700 (Thu, 25 Jul 2024) $
; $LastChangedRevision: 32760 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/general/mvn_scpot_defaults.pro $
;
;-

pro mvn_scpot_defaults, erange=erange2, thresh=thresh2, dEmax=dEmax2, $
               abins=abins, dbins=dbins, obins=obins2, mask_sc=mask_sc, $
               badval=badval2, minflux=minflux2, maxdt=maxdt2, $
               min_lpw_pot=min_lpw_pot2, list=list, bias=bias2, $
               min_sta_pot=min_sta_pot2, max_sta_alt=max_sta_alt2, $
               min_swe_alt=min_swe_alt2

  @mvn_swe_com
  @mvn_scpot_com

; List the defaults

  if keyword_set(list) then begin
    print, ""
    if (size(Espan,/type) ne 0) then begin
      print, "mvn_scpot_com"
      print, "  erange:       ", Espan
      print, "  thresh:       ", thresh
      print, "  dEmax:        ", dEmax
      print, "  bias:         ", bias
      print, "  minflux:      ", minflux
      print, "  badval:       ", badval
      print, "  min_lpw_pot:  ", min_lpw_pot
      print, "  min_sta_pot:  ", min_sta_pot
      print, "  max_sta_alt:  ", max_sta_alt
      print, "  min_swe_alt:  ", min_swe_alt
      print, "  maxdt:        ", maxdt
    endif else print, "mvn_scpot_com: defaults not set"
    print, ""

    return
  endif

; Define spacecraft potential data structure
;   There are 6 methods used to estimate the potential:
;     -1 : Invalid : No method works or has been attempted
;      0 : Manual  : No algorithm at all, set by a human
;      1 : LPW     : I/V curves calibrated by SWE+ and STA methods
;      2 : SWE+    : Sharp break in solar wind/sheath electron energy spectrum
;      3 : SWE-    : Position of He-II photoelectron feature in SPEC data*
;      4 : STA     : Low-energy cutoff of H+ distribution (away from periapsis)
;                  : or shift of O2+ and O+ energy w.r.t ram energy (near periapsis)**
;      5 : SWE/SHD : Position of He-II photoelectron feature in PAD data*
;
;  * Warning: The SWE- and SWE/SHD methods provide the sum of the spacecraft
;             and Mars potentials.  Ionospheric photoelectrons are always subject
;             to the ambipolar potential (~1 V) that forms at the electron exobase 
;             to maintain charge neutrality with the gravitationally bound ions.  
;             There are other Mars potentials that can sometimes play a role.  
;             Comparison with the STA method is necessary to separate the spacecraft
;             and Mars potentials.  Thus, the LPW, SWE+, and STA methods must take
;             precedence.
;
; ** Warning: O2+ dominates at periapsis.  Using shifts in the O2+ energy alone
;             assumes that thermospheric winds are negligible.

  mvn_pot_struct = {time           : 0D   , $  ; unix time
                    potential      : 0.   , $  ; spacecraft potential (V)
                    method         : -1      } ; method used (see above)

; Defaults for the SWE+ method

  if (n_elements(swe_sc_mask) ne 192) then mvn_swe_calib, tab=5

  Espan = [3.,30.]        ; energy search range
  thresh = 0.05           ; minimum value of d(logF)/d(logE)
  dEmax = 6.              ; maximum width of d(logF)/d(logE)
  bias = 0.5              ; bias from the energy of max slope (SWE+)
  minflux = 1.e6          ; minimum 40-eV energy flux
  obins = swe_sc_mask     ; FOV mask when 3D data are used

; Other defaults

  badval = !values.f_nan  ; fill value for potential when no method works
  min_lpw_pot = -14.      ; minimum valid LPW potential
  min_sta_pot = -20.      ; minimum valid STA potential near periapsis
  max_sta_alt = 200.      ; trust STA method in shadow above this altitude
  min_swe_alt = 400.      ; minimum altitude for SWE+ method
  maxdt = 64D             ; maximum time gap to interpolate across

; Override defaults by keyword.  Affects all routines that use mvn_scpot_com.

  if (n_elements(erange2)  gt 1) then Espan = float(minmax(erange2))
  if (size(thresh2,/type)  gt 0) then thresh = float(thresh2)
  if (size(dEmax2,/type)   gt 0) then dEmax = float(dEmax2)
  if (size(bias2,/type)    gt 0) then bias = float(bias2)
  if (size(minflux2,/type) gt 0) then minflux = float(minflux2)
  if (size(badval2,/type)  gt 0) then badval = float(badval2)
  if (size(maxdt2,/type)   gt 0) then maxdt = float(maxdt2)
  if (size(min_lpw_pot2,/type) gt 0) then min_lpw_pot = float(min_lpw_pot2)
  if (size(min_sta_pot2,/type) gt 0) then min_sta_pot = float(min_sta_pot2)
  if (size(max_sta_alt2,/type) gt 0) then max_sta_alt = float(max_sta_alt2)
  if (size(min_swe_alt2,/type) gt 0) then min_swe_alt = float(min_swe_alt2)

  if ((size(obins,/type) eq 0) or keyword_set(abins) or keyword_set(dbins) or $
      keyword_set(obins2) or (size(mask_sc,/type) ne 0)) then begin
    if (n_elements(abins)  ne 16) then abins = replicate(1B, 16)
    if (n_elements(dbins)  ne  6) then dbins = replicate(1B, 6)
    if (n_elements(obins2) ne 96) then begin
      obins = replicate(1B, 96, 2)
      obins[*,0] = reform(abins # dbins, 96)
      obins[*,1] = obins[*,0]
    endif else obins = byte(obins2 # [1B,1B])
    if (size(mask_sc,/type) eq 0) then mask_sc = 1
    if keyword_set(mask_sc) then obins = swe_sc_mask * obins
  endif

  return

end
