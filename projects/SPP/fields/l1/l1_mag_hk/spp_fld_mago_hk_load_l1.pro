;
;  $LastChangedBy: spfuser $
;  $LastChangedDate: 2017-05-10 14:36:10 -0700 (Wed, 10 May 2017) $
;  $LastChangedRevision: 23294 $
;  $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/fields/l1/l1_mag_hk/spp_fld_mago_hk_load_l1.pro $
;

pro spp_fld_mago_hk_load_l1, file

  prefix = 'spp_fld_mago_hk_'

  spp_fld_mag_hk_load_l1, file, prefix = prefix, color = 6

end