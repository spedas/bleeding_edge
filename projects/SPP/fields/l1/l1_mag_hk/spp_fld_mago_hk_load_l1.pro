;
; $LastChangedBy: pulupalap $
; $LastChangedDate: 2023-09-25 14:46:38 -0700 (Mon, 25 Sep 2023) $
; $LastChangedRevision: 32126 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/fields/l1/l1_mag_hk/spp_fld_mago_hk_load_l1.pro $
;

pro spp_fld_mago_hk_load_l1, file, prefix = prefix, varformat = varformat
  compile_opt idl2

  if not keyword_set(prefix) then prefix = 'spp_fld_mago_hk_'

  spp_fld_mag_hk_load_l1, file, prefix = prefix, color = 2, varformat = varformat
end