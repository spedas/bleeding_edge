;+
;
; The following unit names are acceptable for units:
;   'flux' 'eflux' 'df' 'df_cm'
;
;   'df_km' and 'psd' are referred to as 'df'.
;
; CAUTION!!!
; "relativistic" keyword is valid only for electron currently.
; Using it for ions just messes up the conversion. 
;
;Author:
;  Tomo Hori, ERG Science Center, Nagoya Univ.
;  (E-mail tomo.hori _at_ nagoya-u.jp)
;
;History:
;  ver.0.0: The 1st experimental release 
;  
;$LastChangedBy: jwl $
;$LastChangedDate: 2026-02-13 11:08:26 -0800 (Fri, 13 Feb 2026) $
;$LastChangedRevision: 34145 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/erg/satellite/erg/particle/erg_convert_flux_units.pro $
;
;-
pro erg_convert_flux_units $
   , dist, units=units, output=output $
   , relativistic=relativistic $
   , debug=debug

  compile_opt idl2, hidden

  output = dist

  species_lc = strlowcase(dist.species)
  units_in = strlowcase(dist.units_name)

  if undefined(units) then begin
    units = 'flux'
  endif
  units_out = strlowcase(units)
  if units_in eq units_out then return ;; No need to convert!

  ;; Unify some unit notations
  if units_in eq 'df_km' or units_in eq 'psd' then units_in = 'df'
  if units_out eq 'df_km' or units_out eq 'psd' then units_out = 'df'

  ;; Get the mass of species (unit: proton mass)
  case species_lc of
    'e': A = 1d/1836            ;e-
    'hplus':  A = 1  ;H+
    'proton': A = 1 ;H+
    'he2plus':  A = 4 ;He2+
    'alpha':  A = 4 ;He2+
    'heplus':  A = 4 ;He+
    'oplusplus':  A = 16 ;O++
    'oplus':  A = 16 ;O+
    'o2plus':  A = 32 ;(O2)+
    else: message, 'Unknown species: '+species_lc
  endcase

  ;; Scaling factor between df (s^3/km^6) and flux (#/eV/s/str/cm2).
  ;; Note that the notation is in such a way that the conversion is
  ;; done below as:
  ;; f [s3/km6] = j [#/eV/s/str/cm2] / K [eV] * flux_to_df
  ;;                                 for non-relativistic cases
  ;;
  ;; f [(c/MeV/cm)^3] = j [#/eV/s/str/cm2] * flux_to_df / K [eV]
  ;;                 for relativisitc electron cases with keyword relativistic on
  ;; 
  ;; !!CAUTION!! MEPs data should be converted to (#/eV/s/str/cm2) 
  ;; when one uses the mep_part_products libraries.
  ;;
  ;; !!CAUTION2!!
  ;; Keyword "relativistic" is valid for only electrons.
  ;; DO NOT USE it for ions. 
  flux_to_df = A^2 * 0.5447d * 1d6
  if keyword_set(relativistic) then begin
    ;; Conversion here is based on those adopted by Hilmer+JGR,2000.
    
    mc2 = 5.10999D-1 ;; Electron rest energy [MeV]
    ene = double(dist.energy) ;; [eV]
    MeV_ene = double(dist.energy) * 1d-6  ;; [MeV]
    p2c2 = MeV_ene*(MeV_ene+2*mc2)     ;; [MeV^2]

    ;; f [(c/MeV/cm)^3]
    ;;     = j [#/eV/s/str/cm2] * 1d+3 / p2c2 * 1.66d-10 * 200.3 
    ;; 1d+3 is to convert input flux values to [#/keV/s/sr/cm2]. 
    ;; The multiplication of energy [eV] is to be consistent
    ;; with the conversion below. 
    flux_to_df = 1d+3 / p2c2 * 1.66d-10 * 200.3 * ene
    
  endif

  ;; factor between km^6 and cm^6 for df
  cm_to_km = 1d30

  ;; Calculation will be kept simple and stable as possible by 
  ;; pre-determining the final exponent of each scaling factor 
  ;; rather than multiplying by all applicable in/out factors
  ;; these exponents should always be integers!
  ;;    [energy, flux_to_df, cm_to_km]
  in = [0, 0, 0]
  out = [0, 0, 0]

  ;; get input/output scaling exponents  
  ;; All conversions are done via energy flux (eflux).  
  case units_in of 
    'flux': in = [1, 0, 0]
    'eflux': 
    'df': in = [2, -1, 0]
    'df_cm': in = [2, -1, 1]
    else: message, 'Unknown input units: '+units_in
  endcase
  
  case units_out of 
    'flux':out = -[1, 0, 0]
    'eflux': 
    'df': out = -[2, -1, 0]
    'df_cm': out = -[2, -1, -1]
    else: message, 'Unknown output units: '+units_out
  endcase

  exp = in + out

  ;; Ensure everything is double prec first for numerical stability
  ;;  -target field won't be mutated since it's part of a structure
  output.data = double(dist.data) $
                * double(dist.energy)^exp[0] $
                * (flux_to_df^exp[1] * cm_to_km^exp[2])
  
  output.units_name = strlowcase(units)


  return
end

