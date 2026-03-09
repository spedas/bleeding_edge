;+
;
;FUNCTION:        ESC_EESA_STRUCT
;
;PURPOSE:         Defines the ESCAPADE EESA-e data structure. 
;
;INPUTS:          Abbreviation of the EESA-e data product.
;
;KEYWORDS:
;
;     PROBE:      Specifies 'BLUE' or 'GOLD'. Default is 'BLUE'.
;
;   NENERGY:      Specifies the number of energy bins.
;
;       NPA:      Specifies the number of mass bins.
;
;    NANODE:      Specifies the number of azimuth anode bins.
;
;      NDEF:      Specifies the number of deflector bins.
;
;CREATED BY:      Takuya Hara on 2022-08-29 (dummy version) -> 2026-03-04.
;
;LAST MODIFICATION:
; $LastChangedBy: hara $
; $LastChangedDate: 2026-03-04 15:34:52 -0800 (Wed, 04 Mar 2026) $
; $LastChangedRevision: 34230 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/escapade/esa/electron/esc_eesa_struct.pro $
;
;-
FUNCTION esc_eesa_struct, abbreviation, probe=probe, nenergy=nengy, npad=npad, nanode=nanode, ndef=ndef, verbose=verbose
  nan  = !values.f_nan
  dnan = !values.d_nan

  IF undefined(abbreviation) THEN BEGIN
     dprint, dlevel=2, verbose=verbose, "Data product name is not specified. Default is 'spec'."
     abbreviation = 'spec'
  ENDIF
  
  abb = abbreviation.tolower()
  dname = 'EESA-e ' + abb.toupper()
  CASE abb OF
     'pad': BEGIN
        sname = 'esc_eesai_pad' 
        nbins = [4, 16, 1, 1]   
     END 
     'pot': BEGIN
        sname = 'esc_eesae_pot'
        nbins = [18, 1, 1, 1]
     END 
     'spec': BEGIN
        sname = 'esc_eesae_spec'
        nbins = [32, 3, 1, 1]
     END 
     'f3d': BEGIN               ; Full 3D
        sname = 'esc_eesae_f3d'
        nbins = [64, 1, 8, 16]
     END 
  ENDCASE

  ; Energies,       Pitch Angles,     Deflectors,       Azimuth Anodes
  en = nbins[0]  &  pn = nbins[1]  &  dn = nbins[2]  &  an = nbins[3]

  IF  undefined(probe)  THEN probe = 'BLUE'
  IF ~undefined(nengy)  THEN en = nengy
  IF ~undefined(npad)  THEN  pn = npad
  IF ~undefined(nanode) THEN an = nanode
  IF ~undefined(ndef)   THEN dn = ndef
  IF abb EQ 'f3d' THEN bn = dn * an ELSE bn = pn ; nbins = number of total angular bins
  
  format = {project_name: 'ESCAPADE', spacecraft: probe, data_name: dname, apid: '0x140', $
            units_name: 'counts', units_procedure: 'esc_eesae_convert_units', time: dnan, end_time: dnan, delta_t: dnan, integ_t: dnan, $
            spoiler_state: 0B, padding: 0B, sweep_table: 0B, pad_code: 0B, num_accum: 0B, $
            mode: 0, nenergy: en, energy: REFORM(FLTARR(en, bn)), denergy: REFORM(FLTARR(en, bn)), $
            nbins: bn, bins: REFORM(INTARR(en, bn))}

  IF (abb EQ 'pad') OR (abb EQ 'spec') THEN $
     extract_tags, format, {pa: REFORM(FLTARR(en, bn)), dpa: REFORM(FLTARR(en, bn)), $
                            pa_min: REFORM(FLTARR(en, bn)), pa_max: REFORM(FLTARR(en, bn))}
  IF (abb EQ 'pad') OR (abb EQ 'f3d')  THEN $
     extract_tags, format, {ndef: dn, theta: REFORM(FLTARR(en, bn)), dtheta: REFORM(FLTARR(en, bn)), $
                            nanode: an, phi: REFORM(FLTARR(en, bn)), dphi: REFORM(FLTARR(en, bn)), domega: REFORM(FLTARR(en, bn))}

  extract_tags, format, {gf: REFORM(FLTARR(en, bn)), eff: REFORM(FLTARR(en, bn)), $
                         mass: 5.6856297d-06, charge: -1., sc_pot: 0., magf: FLTARR(3), $
                         bkg: REFORM(FLTARR(en, bn)), dead: REFORM(FLTARR(en, bn)), data: REFORM(FLTARR(en, bn)), cnts: REFORM(FLTARR(en, bn))}

  IF (abb EQ 'pad') THEN $
     extract_tags, format, {baz: nan, bel: nan, iaz: INTARR(bn), jel: INTARR(bn), k3d: INTARR(bn)}
  
  str = CREATE_STRUCT(name=sname, format)
  RETURN, str
END
