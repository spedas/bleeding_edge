;+
;
; Basic example file for loading PSP/FIELDS RFS data
;
; $LastChangedBy: pulupalap $
; $LastChangedDate: 2026-03-25 22:46:56 -0700 (Wed, 25 Mar 2026) $
; $LastChangedRevision: 34291 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/fields/crib/psp_fld_example_rfs.pro $
;
;-

pro psp_fld_example_rfs
  compile_opt idl2

  timespan, '2019-04-03'

  psp_fld_load, type = 'rfs_hfr'
  psp_fld_load, type = 'rfs_lfr'

  tplot, ['psp_fld_l2_rfs_hfr_auto_averages_ch0_V1V2', $
    'psp_fld_l2_rfs_lfr_auto_averages_ch0_V1V2']
end
