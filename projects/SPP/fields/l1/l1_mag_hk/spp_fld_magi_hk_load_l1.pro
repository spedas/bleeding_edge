;
;  $LastChangedBy: pulupalap $
;  $LastChangedDate: 2019-07-11 16:06:40 -0700 (Thu, 11 Jul 2019) $
;  $LastChangedRevision: 27437 $
;  $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/fields/l1/l1_mag_hk/spp_fld_magi_hk_load_l1.pro $
;

pro spp_fld_magi_hk_load_l1, file, prefix = prefix, varformat = varformat

  prefix = 'spp_fld_magi_hk_'

  spp_fld_mag_hk_load_l1, file, prefix = prefix, color = 6, varformat = varformat

end