;
;  $LastChangedBy: pulupa $
;  $LastChangedDate: 2017-07-12 15:38:14 -0700 (Wed, 12 Jul 2017) $
;  $LastChangedRevision: 23594 $
;  $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/fields/l1/l1_aeb1_hk/spp_fld_aeb1_hk_load_l1.pro $
;

pro spp_fld_aeb1_hk_load_l1, file, prefix = prefix

  if not keyword_set(prefix) then prefix = 'spp_fld_aeb1_hk_'

  cdf2tplot, file, prefix = prefix

  aeb_hk_names = tnames(prefix + '*')

  if aeb_hk_names[0] NE '' then begin

    foreach name, aeb_hk_names do begin

      options, name, 'ynozero', 1
      options, name, 'horizontal_ytitle', 1
      options, name, 'colors', [2]
      options, name, 'ytitle', name.Remove(0, prefix.Strlen()-1)

      options, name, 'psym', 4
      options, name, 'symsize', 0.5

    endforeach

  endif

end