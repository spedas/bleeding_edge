;+
; NAME:
;   rbsp_ac_highpass_response (function)
;
; PURPOSE:
;   Calculate the response of the one-pole 10 Hz high-pass analog filter applied
;   to RBSP AC channel field signals.
;
; CATEGORIES:
;
; CALLING SEQUENCE:
;   resp = rbsp_ac_highpass_response(f)
;
; ARGUMENTS:
;   f: (Input, required) A frequency array for which the response of the filter
;       is calcuated. The frequency should be in units of Hz.
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
;   2012-08-08: Created by Jianbao Tao, SSL, UC Berkeley.
; 
;
; Version:
;
; $LastChangedBy: jianbao_tao $
; $LastChangedDate: 2012-09-06 11:42:13 -0700 (Thu, 06 Sep 2012) $
; $LastChangedRevision: 10895 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/missions/rbsp/efw/rbsp_ac_highpass_response.pro $
;-

function rbsp_ac_highpass_response, f

compile_opt idl2

f0 = 10d ; in units of Hz, -3dB corner frequency
I = dcomplex(0, 1)
resp = I * f / f0 / (1d + I * f / f0)

return, resp

end

