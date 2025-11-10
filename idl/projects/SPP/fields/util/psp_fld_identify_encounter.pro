;+
;
; Wrapper for spp_fld_identify_encounter.pro
;
; $LastChangedBy: pulupalap $
; $LastChangedDate: 2025-11-04 11:26:44 -0800 (Tue, 04 Nov 2025) $
; $LastChangedRevision: 33821 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/fields/util/psp_fld_identify_encounter.pro $
;-

function psp_fld_identify_encounter, t
  compile_opt idl2

  return, spp_fld_identify_encounter(t)
end
