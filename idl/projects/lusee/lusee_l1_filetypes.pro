;+
;
; NAME:
;   lusee_l1_filetypes
;
; $LastChangedBy: pulupalap $
; $LastChangedDate: 2022-08-31 22:07:53 -0700 (Wed, 31 Aug 2022) $
; $LastChangedRevision: 31065 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/lusee/lusee_l1_filetypes.pro $
;
;-

function lusee_l1_filetypes, match_string, tmlib = tmlib

  if n_elements(match_string) EQ 0 then match_string = '*'

  all_l1_filetypes = [ $
    'aeb1_hk', $
    'dcb_analog_hk', $
    'dcb_events', $
    'dcb_memory', $
    'dcb_ssr_telemetry', $
    'dfb_ac_bpf1', $
    'dfb_ac_bpf2', $
    'dfb_ac_spec1', $
    'dfb_ac_spec2', $
    'dfb_ac_spec3', $
    'dfb_ac_spec4', $
    'dfb_ac_xspec1', $
    'dfb_ac_xspec2', $
    'dfb_ac_xspec3', $
    'dfb_ac_xspec4', $
    'dfb_dbm1', $
    'dfb_dbm2', $
    'dfb_dbm3', $
    'dfb_dbm4', $
    'dfb_dbm5', $
    'dfb_dbm6', $
    'dfb_dc_bpf1', $
    'dfb_dc_bpf2', $
    'dfb_dc_spec1', $
    'dfb_dc_spec2', $
    'dfb_dc_spec3', $
    'dfb_dc_spec4', $
    'dfb_dc_xspec1', $
    'dfb_dc_xspec2', $
    'dfb_dc_xspec3', $
    'dfb_dc_xspec4', $
    'dfb_hk', $
    'dfb_wf01', $
    'dfb_wf02', $
    'dfb_wf03', $
    'dfb_wf04', $
    'dfb_wf05', $
    'dfb_wf06', $
    'dfb_wf07', $
    'dfb_wf08', $
    'dfb_wf09', $
    'dfb_wf10', $
    'dfb_wf11', $
    'dfb_wf12', $
    'f1_100bps', $
    'f2_100bps', $
    'mago_hk', $
    'mago_survey', $
    'rfs_burst', $
    'rfs_hfr_auto', $
    'rfs_hfr_cross', $
    'rfs_lfr_auto', $
    'rfs_lfr_hires', $
    'rfs_rawspectra', $
    'rfs_waveform']

  match_ind = $
    WHERE(STRMATCH(all_l1_filetypes, match_string, /FOLD) EQ 1, match_count)

  if match_count GT 0 then match_types = all_l1_filetypes[match_ind] $
  else return, []

  if keyword_set(tmlib) then begin

    match_tmlib_ind = stregex(match_types, '[0-9]+$')

    for i = 0, n_elements(match_tmlib_ind)-1 do begin

      if match_tmlib_ind[i] GT 0 then $
        match_types[i] = (match_types[i]).Insert('_', match_tmlib_ind[i])

    endfor

  endif

  return, match_types

end