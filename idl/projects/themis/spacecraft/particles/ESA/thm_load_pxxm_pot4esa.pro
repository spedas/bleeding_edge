;+
;NAME:
; thm_load_pxxm_pot4esa
;PURPOSE:
; loads the pxxm_pot variable for ESA processing, performs a time
; offset, and also loads the efs_Potl variable fro FIT files, if it
; exists.
;CALLING SEQUENCE:
; thm_load_esa_pxx_pot4esa, probe=probe, trange=trange,suffix=suffix
;INPUT;
; All via keyword
;OUTPUT:
; For each probe, a tplot variable 'thx_pxxm_pot', which is the SC
; potential that comes directly from the MOM L1 files, a variable,
; 'thm_pxxm_pot_0', that includes a time correction, 
;KEYWORDS:
; probe - ['a','b','c','d','e']
; trange -  the time range, otherwise just use whatever's there
;HISTORY:
; 11-May-2010, jmm, jimm@ssl.berkeley.edu
;$LastChangedBy: aaflores $
;$LastChangedDate: 2012-01-10 10:56:14 -0800 (Tue, 10 Jan 2012) $
;$LastChangedRevision: 9526 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/spacecraft/particles/ESA/thm_load_pxxm_pot4esa.pro $
;-
Pro thm_load_pxxm_pot4esa, probe = probe, trange = trange, $
                           _extra = _extra

  tshft_mom = [1.6028, 0.625]
  mom_tim_adjust = time_double(['07-11-29/20:51:26', '07-12-03/18:43:24', $
                                '07-12-03/18:23:03', '07-11-27/18:34:23', $
                                '07-11-29/17:49:10'])
; sc default
  if keyword_set(probe) then sc = probe
  if not keyword_set(sc) then begin
    dprint,  'S/C not set, default = all probes'
    sc = ['a', 'b', 'c', 'd', 'e']
  endif
  sc = strlowcase(sc)
  If(n_elements(sc) Eq 1) Then Begin
    sc = strsplit(sc,' ', /extract)
  Endif
  nsc = n_elements(sc)
  For j = 0, nsc-1 Do Begin
;get EFS potential, 
    If(keyword_set(trange)) Then Begin
      thm_load_fit, probe = sc[j], trange = trange, datatype = 'efs_potl'
    Endif Else thm_load_fit, probe = sc[j], datatype = 'efs_potl' 
    potl = 'th'+sc[j]+'_efs_potl'
;Get MOM potential
    If(keyword_set(trange)) Then Begin
      thm_load_mom, probe = sc[j], trange = trange, datatype = 'pxxm_pot'
    Endif Else thm_load_mom, probe = sc[j], datatype = 'pxxm_pot' 
    pxxm = 'th'+sc[j]+'_pxxm_pot'
    get_data, pxxm, data = dpxxm, dlimits = dlpxxm
;Correct potential variable with time shift
    If(is_struct(dpxxm)) Then Begin
      model = spinmodel_get_ptr(sc[j])
      npts = n_elements(dpxxm.x)
      If(obj_valid(model)) Then Begin                          
        spinmodel_interp_t, model = model, time = dpxxm.x, spinper = spin_period, $
          /use_spinphase_correction
      Endif Else spin_period = replicate(3.0, npts)
;Subtract the time shift
      pjno = where(['a', 'b', 'c', 'd', 'e'] Eq sc[j])
      If(dpxxm.x[0] Ge mom_tim_adjust[pjno]) Then Begin
        dpxxm.x = dpxxm.x-tshft_mom[1]*spin_period
      Endif Else If(dpxxm.x[npts-1] Lt mom_tim_adjust[pjno]) Then Begin
        dpxxm.x = dpxxm.x-tshft_mom[0]*spin_period
      Endif Else Begin
        aft = where(dpxxm.x Ge mom_tim_adjust[pjno])
        If(aft[0] Ne -1) Then dpxxm.x[aft] = dpxxm.x[aft]-tshft_mom[1]*spin_period[aft]
        bef = where(dpxxm.x Lt mom_tim_adjust[pjno])
        If(bef[0] Ne -1) Then dpxxm.x[bef] = dpxxm.x[bef]-tshft_mom[1]*spin_period[bef]
      Endelse
;done with time shifting
      store_data, pxxm+'_0', data = dpxxm, dlimits = dlpxxm
    Endif                ;nothing happens if there is no pxxm_pot data
  Endfor                        ;sc loop
  Return
End
