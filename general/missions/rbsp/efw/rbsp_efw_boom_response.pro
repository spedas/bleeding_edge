;+
; NAME:
;   rbsp_efw_boom_response (function)
;
; PURPOSE:
;
; CATEGORIES:
;
; CALLING SEQUENCE:
;   resp = rbsp_efw_boom_response(f, boom_type, rsheath = rsheath, $
;   H_before = H_before, H_after = H_after)
;
; ARGUMENTS:
;
; KEYWORDS:
;
; COMMON BLOCKS:
;
; EXAMPLES:
;
; SEE ALSO:
;
; HISTORY:
;   2012-08-12: Created by Jianbao Tao (JBT), SSL, UC Berkley.
;
; VERSION:
; $LastChangedBy: jianbao_tao $
; $LastChangedDate: 2012-08-14 18:00:24 -0700 (Tue, 14 Aug 2012) $
; $LastChangedRevision: 10823 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/missions/rbsp/efw/rbsp_efw_boom_response.pro $
;
;-

function rbsp_efw_boom_response, f, boom_type, rsheath = rsheath, $
  H_before = H_before, H_after = H_after

compile_opt idl2

if ~keyword_set(rsheath) then $
  rsheath = 50d6          ; Default sheath resistance, 10 MOhm

case strupcase(boom_type) of
  'SPB': begin
      R_sh = rsheath
      C_sh = 14d-12  ; Sheath capacitance [F]
      R_esd = 100d3   ; ESD resistance [Ohm]
      R_stray = 1d12  ; Preamp stray (op-amp input) resistance  [Ohm]
      C_stray = 7.5d-12 ; Preamp stray (op-amp input) capacitance [F]
      R_out = 25d    ; Op-amp output resistance [Ohm]
      R_cable = 75d   ; Boom cable resistance [Ohm]
      C_cable = 9.6d-9 ; Boom cable capacitance [F]
      R_load = 100d3  ; Load resistance [Ohm]
    end
  'AXB': begin
      R_sh = rsheath
      C_sh = 4d-12  ; Sheath capacitance [F]
      R_esd = 100d3   ; ESD resistance [Ohm]
      R_stray = 1d12  ; Preamp stray (op-amp input) resistance  [Ohm]
      C_stray = 7.5d-12 ; Preamp stray (op-amp input) capacitance [F]
      R_out = 25d    ; Op-amp output resistance [Ohm]
      R_cable = 75d   ; Boom cable resistance [Ohm]
      C_cable = 1.4d-9 ; Boom cable capacitance [F]
      R_load = 100d3  ; Load resistance [Ohm]
    end
  else: begin
      dprint, 'Invalid boom type. A NaN is returned.'
      return, !values.f_nan
    end
endcase

j = dcomplex(0, 1)  ; Imaginary unit
ww = 2 * !dpi * f	; omega, rad/s.
ss = j * ww	; j*omega, rad/s.

; Sheath impedance
Z_sh = R_sh / (1d + ss * C_sh * R_sh)

; Preamp stray impedance
Z_stray = R_stray / (1d + ss * C_stray * R_stray)

; Transfer function before the voltage-follower
H_before = Z_stray / (Z_sh + R_esd + Z_stray)

; Effective load impedance
Z_load = (R_cable + R_load) / (1d + ss * C_cable * (R_cable + R_load))

; Transfer function after the voltage-follower
H_after = Z_load / (R_out + Z_load)

; Overall response
resp = H_before * H_after

return, resp

end

