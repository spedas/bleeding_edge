;+
;
; $LastChangedBy: pulupalap $
; $LastChangedDate: 2024-01-23 13:45:46 -0800 (Tue, 23 Jan 2024) $
; $LastChangedRevision: 32397 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/fields/l1/l1_rfs_waveform/spp_fld_rfs_waveform_load_l1.pro $
;
;-

pro spp_fld_rfs_waveform_load_l1, file, prefix = prefix, varformat = varformat
  compile_opt idl2

  if not keyword_set(prefix) then prefix = 'spp_fld_rfs_waveform_'

  if typename(file) eq 'UNDEFINED' then begin
    DPRINT, 'No file provided to spp_fld_rfs_rawspectra_load_l1', dlevel = 2

    return
  endif

  cdf2tplot, /get_support_data, file, prefix = prefix, varformat = varformat

  hfr_wf_t = dindgen(2l ^ 15) / 38.4d6

  foreach wf, 'spp_fld_rfs_waveform_waveform_' + ['0', '1'] do begin
    if tnames(wf) ne '' then begin
      get_data, wf, data = d_wf

      v_wf = rebin(reform(hfr_wf_t, 1, 2l ^ 15), n_elements(d_wf.x), 2l ^ 15)

      get_data, 'spp_fld_rfs_waveform_algorithm', data = d_algorithm

      hfr_ind = where(d_algorithm.y mod 2 eq 0, n_hfr, $
        complement = lfr_ind, ncomplement = n_lfr)

      if n_lfr gt 0 then v_wf[lfr_ind, *] *= 8d

      store_data, wf, data = {x: d_wf.x, y: d_wf.y, v: v_wf}
    endif
  endforeach
end