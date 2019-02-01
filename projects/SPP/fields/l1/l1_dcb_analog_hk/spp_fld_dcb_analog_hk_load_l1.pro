;
;  $LastChangedBy: pulupalap $
;  $LastChangedDate: 2019-01-30 21:11:34 -0800 (Wed, 30 Jan 2019) $
;  $LastChangedRevision: 26522 $
;  $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/fields/l1/l1_dcb_analog_hk/spp_fld_dcb_analog_hk_load_l1.pro $

pro spp_fld_dcb_analog_hk_load_l1, file, prefix = prefix

  if not keyword_set(prefix) then prefix = 'spp_fld_dcb_analog_hk_'

  cdf2tplot, /get_support_data, file, prefix = prefix

  dcb_hk_names = tnames(prefix + '*')

  if dcb_hk_names[0] NE '' then begin

    for i = 0, n_elements(dcb_hk_names)-1 do begin

      name = dcb_hk_names[i]

      options, name, 'ynozero', 1
      options, name, 'horizontal_ytitle', 1
      options, name, 'colors', [2]
      options, name, 'ytitle', name.Remove(0, prefix.Strlen()-1)

      ;options, name, 'psym', 4
      options, name, 'psym_lim', 100
      options, name, 'symsize', 0.75

    endfor

  endif

end