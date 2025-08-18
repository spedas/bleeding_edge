;
;  $LastChangedBy: pulupalap $
;  $LastChangedDate: 2020-10-22 17:05:28 -0700 (Thu, 22 Oct 2020) $
;  $LastChangedRevision: 29280 $
;  $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/fields/l1/l1_dfb_hk/spp_fld_dfb_hk_load_l1.pro $
;

pro spp_fld_dfb_hk_load_l1, file, prefix = prefix, varformat = varformat

  if not keyword_set(prefix) then prefix = 'spp_fld_dfb_hk_'

  cdf2tplot, /get_support_data, file, prefix = prefix, varformat = varformat

  options, prefix + 'edc_gain', 'yrange', [-0.25, 1.25]
  options, prefix + 'edc_gain', 'yticks', 1
  options, prefix + 'edc_gain', 'ytickv', [0,1]
  options, prefix + 'edc_gain', 'yminor', 1
  options, prefix + 'edc_gain', 'ytickname', ['Lo','Hi']
  options, prefix + 'edc_gain', 'ystyle', 1
  options, prefix + 'edc_gain', 'colors', [6]
  ;options, prefix + 'edc_gain', 'psym_lim', 200
  options, prefix + 'edc_gain', 'psym', 7
  options, prefix + 'edc_gain', 'symsize', 0.75
  options, prefix + 'edc_gain', 'panel_size', 0.35
  options, prefix + 'edc_gain', 'ytitle', 'DFB!CEDC!CGain'
  options, prefix + 'edc_gain', 'ysubtitle', ''
  options, prefix + 'edc_gain', 'datagap', 120

  options, prefix + 'orbital_mode', 'colors', [6]
  ;options, prefix + 'orbital_mode', 'psym_lim', 200
  options, prefix + 'orbital_mode', 'psym', 7
  options, prefix + 'orbital_mode', 'symsize', 0.75
  options, prefix + 'orbital_mode', 'panel_size', 1.5
  options, prefix + 'orbital_mode', 'ytitle', 'DFB Mode'
  options, prefix + 'orbital_mode', 'ysubtitle', ''
  options, prefix + 'orbital_mode', 'datagap', 120
  options, prefix + 'orbital_mode', 'yticklen', 1
  options, prefix + 'orbital_mode', 'ygridstyle', 1
  options, prefix + 'orbital_mode', 'ystyle', 1
  options, prefix + 'orbital_mode', 'yrange', [-0.5,15.5]
  options, prefix + 'orbital_mode', 'yticks', 15
  options, prefix + 'orbital_mode', 'ytickv', indgen(16)


end