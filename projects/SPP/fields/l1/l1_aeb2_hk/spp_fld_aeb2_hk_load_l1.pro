;
;  $LastChangedBy: spfuser $
;  $LastChangedDate: 2018-09-06 16:36:27 -0700 (Thu, 06 Sep 2018) $
;  $LastChangedRevision: 25742 $
;  $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/fields/l1/l1_aeb2_hk/spp_fld_aeb2_hk_load_l1.pro $
;

pro spp_fld_aeb2_hk_load_l1, file, prefix = prefix

  if not keyword_set(prefix) then prefix = 'spp_fld_aeb2_hk_'

  cdf2tplot, file, prefix = prefix

  aeb_hk_names = tnames(prefix + '*')

  if aeb_hk_names[0] NE '' then begin

    foreach name, aeb_hk_names do begin

      options, name, 'ynozero', 1
      options, name, 'horizontal_ytitle', 1
      options, name, 'colors', [6]
      options, name, 'ytitle', name.Remove(0, prefix.Strlen()-1)

      options, name, 'psym_lim', 100
      options, name, 'symsize', 0.75

    endforeach

  endif

end