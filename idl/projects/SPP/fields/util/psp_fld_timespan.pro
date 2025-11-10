;+
;
; Wrapper for spp_fld_timespan.pro
;
; $LastChangedBy: pulupalap $
; $LastChangedDate: 2025-11-04 11:26:44 -0800 (Tue, 04 Nov 2025) $
; $LastChangedRevision: 33821 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/fields/util/psp_fld_timespan.pro $
;-

pro psp_fld_timespan, orbit, days = days, encounter = encounter, venus = venus, $
  peri = peri, timespan = timespan, no_set = no_set
  compile_opt idl2

  spp_fld_timespan, orbit, days = days, encounter = encounter, venus = venus, $
    peri = peri, timespan = timespan, no_set = no_set
end
