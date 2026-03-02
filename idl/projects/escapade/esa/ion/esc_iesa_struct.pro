;+
;
;FUNCTION:        ESC_IESA_STRUCT
;
;PURPOSE:         Defines the ESCAPADE EESA-i data structure. 
;
;INPUTS:          Abbreviation of the EESA-i data product.
;
;KEYWORDS:
;
;      BLUE:      If set, specifies the BLUE spacecraft explicitly.
;
;      GOLD:      If set, specifies the GOLD spacecraft explicitly.
;
;     PROBE:      Specifies 'BLUE' or 'GOLD'. Default is 'BLUE'.
;
;   NENERGY:      Specifies the number of energy bins.
;
;     NMASS:      Specifies the number of mass bins.
;
;    NANODE:      Specifies the number of azimuth anode bins.
;
;      NDEF:      Specifies the number of deflector bins.
;
;CREATED BY:      Takuya Hara on 2026-02-07.
;
;LAST MODIFICATION:
; $LastChangedBy: hara $
; $LastChangedDate: 2026-02-23 10:10:11 -0800 (Mon, 23 Feb 2026) $
; $LastChangedRevision: 34179 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/escapade/esa/ion/esc_iesa_struct.pro $
;
;-
FUNCTION esc_iesa_struct, prod, probe=probe, blue=blue, gold=gold, verbose=verbose, $
                          nenergy=nengy, nmass=nmass, nanode=nanode, ndef=ndef
  nan  = !values.f_nan
  dnan = !values.d_nan

  IF undefined(prod) THEN BEGIN
     dprint, dlevel=2, verbose=verbose, "Data product name is not specified. Default is 'f4d', i.e., Fine 4D."
     abbreviation = 'f4d'
  ENDIF
  
  abb = prod.tolower()
  CASE abb OF
     'fe': BEGIN
        dname = 'Fine Energies'
        sname = 'esc_eesai_fe' 
        nbins = [64, 1, 1, 3]
        apid  = ''
     END 
     'fm': BEGIN
        dname = 'Fine Masses'
        sname = 'esc_eesai_fm'
        nbins = [1, 1, 1, 64]
        apid  = ''
     END 
     'f4d': BEGIN
        dname = 'Fine 4D'       ; or Distribution Function
        sname = 'esc_eesai_f4d'
        nbins = [32, 8, 11, 3]
        apid  = '0x125'
     END 
     'sw': BEGIN
        dname = 'Solar Wind'
        sname = 'esc_eesai_sw'
        nbins = [32, 8, 4, 2]
        apid  = '' 
     END 
     'fd': BEGIN
        ; Obsolete
        dname = 'Fine Deflectors'
        sname = 'esc_eesai_fd'
        nbins = [16, 8, 1, 2]
        apid  = ''
     END 
     'c4d': BEGIN
        ; Obsolete
        dname = 'Coarse 4D'
        sname = 'esc_eesai_cd'
        nbins = [16, 4, 11, 2]
        apid  = ''
     END 
  ENDCASE

  ; Energies,       Deflectors,       Azimuth Anodes,   Masses
  en = nbins[0]  &  dn = nbins[1]  &  an = nbins[2]  &  mn = nbins[3]

  IF KEYWORD_SET(blue) THEN probe = 'BLUE'
  IF KEYWORD_SET(gold) THEN probe = 'GOLD'
  
  IF  undefined(probe)  THEN probe = 'BLUE'
  IF ~undefined(nengy)  THEN en = nengy
  IF ~undefined(nmass)  THEN mn = nmass
  IF ~undefined(nanode) THEN an = nanode
  IF ~undefined(ndef)   THEN dn = ndef
  bn = dn * an                  ; nbins = number of total angular bins
  
  data_name = dname + ' ' + 'enedndanamnm'
  data_name = data_name.replace('en', roundst(en))
  data_name = data_name.replace('dn', roundst(dn))
  data_name = data_name.replace('an', roundst(an))
  data_name = data_name.replace('mn', roundst(mn))

  data_name = data_name.replace('1e', '')
  data_name = data_name.replace('1d', '')
  IF data_name.contains('11a') EQ 0 THEN data_name = data_name.replace('1a', '')
  data_name = data_name.replace('1m', '')
  
  format = {project_name: 'ESCAPADE', spacecraft: probe.toupper(), data_name: data_name, apid: apid, $
            units_name: 'counts', units_procedure: 'esc_iesa_convert_units', time: dnan, end_time: dnan, $
            delta_t: dnan, integ_t: dnan, quality_flag: 0B, att_state: 0B, spoiler_state: 0B, padding: 0B, $
            sweep_table: 0B, lut_id: 0B, dp_cadence: 0B, num_accum: 0B, att_ind: 0B, $
            nenergy: en, energy: REFORM(FLTARR(en, bn, mn)), denergy: REFORM(FLTARR(en, bn, mn)), $
            nbins: bn, bins: REFORM(FLTARR(en, bn, mn)), ndef: dn, nanode: an, theta: REFORM(FLTARR(en, bn, mn)), dtheta: REFORM(FLTARR(en, bn, mn)), $
            phi: REFORM(FLTARR(en, bn, mn)), dphi: REFORM(FLTARR(en, bn, mn)), domega: REFORM(FLTARR(en, bn, mn)), gf: REFORM(FLTARR(en, bn, mn)), eff: REFORM(FLTARR(en, bn, mn)), $
            geom_factor: 1., nmass: mn, mass: 0.0104389, mass_arr: REFORM(FLTARR(en, bn, mn)), charge: 1., sc_pot: nan, magf: FLTARR(3), $
            bkg: REFORM(FLTARR(en, bn, mn)), dead: REFORM(FLTARR(en, bn, mn)), cnts: REFORM(FLTARR(en, bn, mn)), data: REFORM(FLTARR(en, bn, mn))}  

  str = CREATE_STRUCT(name=sname, format)
  RETURN, str
END
