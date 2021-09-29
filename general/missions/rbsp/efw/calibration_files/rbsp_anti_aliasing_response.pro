;+
; NAME:
;   rbsp_anti_aliasing_response (function)
;
; PURPOSE:
;   Calculate the frequency responses of the anti-aliasing filters for RBSP
;   field signals.
;
; CATEGORIES:
;
; CALLING SEQUENCE:
;   response = rbsp_anti_aliasing_response(f)
;
; ARGUMENTS:
;   f: (Input, required) A floating array of frequencies at which the responses
;           are calculated.
;
; KEYWORDS:
;   None.
;
; COMMON BLOCKS:
;
; EXAMPLES:
;
; SEE ALSO:
;
; HISTORY:
;   2012-08-10: Created by Jianbao Tao (JBT), SSL, UC Berkley.
;
;
; Version:
;
; $LastChangedBy: aaronbreneman $
; $LastChangedDate: 2020-04-29 11:11:13 -0700 (Wed, 29 Apr 2020) $
; $LastChangedRevision: 28640 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/missions/rbsp/efw/calibration_files/rbsp_anti_aliasing_response.pro $
;-

function rbsp_anti_aliasing_response, f

compile_opt idl2

; fc = 8192d
fc = 6500d

s = dcomplex( 0.0, 1.0)*(2.42741070215263d*f/fc)
return,945.0d/(s^5+15*s^4 + 105*s^3 + 420*s^2 + 945*s + 945.0d)

end

