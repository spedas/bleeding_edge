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
; $LastChangedBy: jianbao_tao $
; $LastChangedDate: 2012-09-06 11:42:13 -0700 (Thu, 06 Sep 2012) $
; $LastChangedRevision: 10895 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/missions/rbsp/efw/rbsp_anti_aliasing_response.pro $
;-

function rbsp_anti_aliasing_response, f

compile_opt idl2

; fc = 8192d
fc = 6500d

s = dcomplex( 0.0, 1.0)*(2.42741070215263d*f/fc)
return,945.0d/(s^5+15*s^4 + 105*s^3 + 420*s^2 + 945*s + 945.0d)

end

