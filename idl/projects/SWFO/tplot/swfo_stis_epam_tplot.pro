;+
;PROCEDURE:  swfo_stis_epam_tplot
; PURPOSE: Makes a plot comparing ACE EPAM RTSW
; and SWFO/SOLAR-1 STIS Level 2 fluxes.
; 
; If "overlay" keyword is active, STIS and EPAM
; fluxes will be drawn on the same plot.
; 
; $LastChangedBy: rjolitz $
; $LastChangedDate: 2026-10-28 15:39:41 -0700 (Wed, 28 Oct 2026) $
; $LastChangedRevision: 35018 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SWFO/tplot/swfo_stis_epam_tplot.pro $


pro swfo_stis_epam_tplot, stis_res_tplot_prefix=stis_res_tplot_prefix,$
    stis_res_name=stis_res_name,$
    stis_energy_labels=stis_energy_labels,$
    epam_elec_tname=epam_elec_tname, stis_elec_tname=stis_elec_tname,$
    epam_proton_tname=epam_proton_tname, stis_ion_tname=stis_ion_tname,$
    tplot_var_names=tplot_var_names,$
    overlay=overlay, window=window, verbose=verbose

  ; Default from swfo_load is 30 sec, so set that as our default
  if ~keyword_set(stis_res_tplot_prefix) then stis_res_tplot_prefix = '30s'
  stis_l2_tplot_prefix = 'swfo_stis_l2_'+stis_res_tplot_prefix

  if ~keyword_set(stis_res_name) then begin
    case stis_res_tplot_prefix of
      'fr': stis_res_name = ''
      '30s': stis_res_name = '30-sec '
      '300s': stis_res_name = '5-min '
      else: stis_res_name = ''
    endcase
  endif

  if ~keyword_set(tplot_var_names) then begin
    ; Check for ACE:
    epam_proton_tname = tnames('ace_rtsw_epam_proton_flux',nd_p,ind=ind,/all)
    epam_elec_tname = tnames('ace_rtsw_epam_elec_flux',nd_e,ind=ind,/all)
    if nd_p eq 0 or nd_e eq 0 then begin
       dprint,dlevel=0,verbose=verbose,$
         "No variable names matching 'ace_rtsw_epam*flux', run 'ace_load'."
       return
    endif

    ; Check for STIS:
    stis_l2_ion_tplot_name = stis_l2_tplot_prefix + '_ION_FLUX'
    stis_l2_elec_tplot_name = stis_l2_tplot_prefix +'_ELEC_FLUX'
    stis_elec_tname = tnames(stis_l2_elec_tplot_name, nd_e,ind=ind,/all)
    stis_ion_tname = tnames(stis_l2_ion_tplot_name, nd_i,ind=ind,/all)
    if nd_i eq 0 or nd_e eq 0 then begin
       dprint,dlevel=0,verbose=verbose,$
         "No variable names matching 'swfo_stis_l2*FLUX', run 'swfo_load'."
       return
    endif

    tplot_var_names = [epam_elec_tname, stis_elec_tname, epam_proton_tname, stis_ion_tname]

  endif

  ; Make the stis energy labels
  if ~keyword_set(stis_energy_labels) then begin
    ; Grab the first index, and extract the energy ranges
    ; for ion data:
    get_data, stis_l2_tplot_prefix + '_ION_ERANGE', data=d
    ion_erange = reform(d.y[0, *, *])
    n_ion_en = (ion_erange.dim)[0]
    ; Iterate through the energy bins to construct the labels:
    stis_ion_en_labels = strarr(n_ion_en)
    for i=0, n_ion_en-1 do begin
      ; round, turn into a string, remove white space, and join:
      ion_en_r_i = string(round(reform(ion_erange[i, *])))
      ion_en_label_i = (ion_en_r_i.compress()).join('-') + ' keV'
      stis_ion_en_labels[i] = ion_en_label_i
    endfor
    ; Now do the same for electrons
    get_data, stis_l2_tplot_prefix + '_ELEC_ERANGE', data=d
    elec_erange = reform(d.y[0, *, *])
    n_elec_en = (elec_erange.dim)[0]
    ; Iterate through the energy bins to construct the labels:
    stis_elec_en_labels = strarr(n_elec_en)
    for i=0, n_elec_en-1 do begin
      ; round, turn into a string, remove white space, and join:
      elec_en_r_i = string(round(reform(elec_erange[i, *])))
      elec_en_label_i = (elec_en_r_i.compress()).join('-') + ' keV'
      stis_elec_en_labels[i] = elec_en_label_i
    endfor

  endif
  ; stis_energy_labels = ['30-50 keV','50-100 keV', '100-200 keV', '200-400 keV', '400-800 keV', '800-1600 keV', '1.6-3 MeV']

  ; ; - ACE compare:
  ; ace_var = ['stis_l2_{}_ION_FLUX', 'stis_l2_{}_ELEC_FLUX',$
  ;            'ace_rtsw_epam_proton_flux', 'ace_rtsw_epam_elec_flux']
  ; ace_var_i = strarr_replace(ace_var, '{}', res_tplot_prefix)

  ; Enough room for the labels:
  tplot_options,'title', stis_res_name + 'SOLAR-1 STIS (color) versus ACE EPAM (gray, RTSW)'
  tplot_options,'xmargin',[10,15]

  options, 'ace_rtsw_epam_elec_flux', ytitle='5-min ACE Elec Flux', ysubtitle='[#/cm2-s-ster-keV]'
  options, 'ace_rtsw_epam_proton_flux', ytitle='5-min ACE Proton Flux', ysubtitle='[#/cm2-s-ster-keV]'

  options, stis_ion_tname,$
    ytitle= stis_res_name+'STIS Ion Flux', ysubtitle='[#/cm2-s-ster-keV]',$
    labels=stis_ion_en_labels, ylog=1, ystyle=1, labflag=-1
  options, stis_elec_tname,$
    ytitle=stis_res_name +'STIS Elec Flux', ysubtitle='[#/cm2-s-ster-keV]',$
    labels=stis_elec_en_labels, ylog=1, ystyle=1, labflag=-1

  ; make new plot:
  if keyword_set(overlay) then begin

    ; use B+W colortable for ACE EPAM to contrast
    ; shift to ensure visibility on white background
    bw_ct = 42
    options, 'ace_rtsw_epam_proton_flux', color_table=bw_ct, colors=55 + indgen(5)*(254-55)/4
    options, 'ace_rtsw_epam_elec_flux', color_table=bw_ct, colors=[55, 254]

    store_data, 'epam_stis_proton_flux',$
      data=[stis_l2_ion_tplot_name, epam_proton_tname]
    options, 'epam_stis_proton_flux',$
      labflag=-1, ytitle="Ion Flux", ysubtitle='[#/cm2-s-ster-keV]', yrange=[1e-6, 1e6]

    store_data, 'epam_stis_elec_flux',$
      data=[stis_l2_elec_tplot_name, epam_elec_tname]
    options, 'epam_stis_elec_flux',$
      labflag=-1, ytitle="Elec Flux", ysubtitle='[#/cm2-s-ster-keV]', yrange=[1e-6, 1e6]

    tplot_var_names = ['epam_stis_elec_flux', 'epam_stis_proton_flux']


  endif

  tplot, tplot_var_names, window=window


end
