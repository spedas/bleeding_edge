;
;  $LastChangedBy: pulupalap $
;  $LastChangedDate: 2018-01-29 13:27:43 -0800 (Mon, 29 Jan 2018) $
;  $LastChangedRevision: 24602 $
;  $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/fields/l1/l1_mag_hk/spp_fld_mago_hk_load_l1.pro $
;

pro spp_fld_mago_hk_load_l1, file, prefix = prefix

  prefix = 'spp_fld_mago_hk_'

  spp_fld_mag_hk_load_l1, file, prefix = prefix, color = 6

end