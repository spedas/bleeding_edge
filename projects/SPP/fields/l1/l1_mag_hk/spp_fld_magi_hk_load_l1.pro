;
;  $LastChangedBy: pulupa $
;  $LastChangedDate: 2018-02-05 11:21:46 -0800 (Mon, 05 Feb 2018) $
;  $LastChangedRevision: 24641 $
;  $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/fields/l1/l1_mag_hk/spp_fld_magi_hk_load_l1.pro $
;

pro spp_fld_magi_hk_load_l1, file, prefix = prefix

  prefix = 'spp_fld_magi_hk_'

  spp_fld_mag_hk_load_l1, file, prefix = prefix, color = 6

end