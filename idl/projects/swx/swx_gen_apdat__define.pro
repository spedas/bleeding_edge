;+
;  SWX_GEN_APDAT
;  This basic object is the entry point for defining and obtaining all data for all apids
; $LastChangedBy: davin-mac $
; $LastChangedDate: 2024-11-03 23:43:14 -0800 (Sun, 03 Nov 2024) $
; $LastChangedRevision: 32928 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/swx/swx_gen_apdat__define.pro $
;-
;COMPILE_OPT IDL2




PRO swx_gen_apdat__define
  void = {swx_gen_apdat, $
    ; inherits spp_gen_apdat  $
    inherits generic_apdat  $    ; superclass
  }
END


