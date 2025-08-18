;+
; PROCEDURE map2d_init
; 
; :DESCRIPTION:
;    Initialize or modify the environment for drawing 2D data 
;
; :KEYWORDS:
;    reset: set to reset map2d system variables
;    set_time: the time for which 2D data is drawn on the world map.
;    coord: the name of the coordinate system.
;           'geo' or 0 for geographic coordinate
;           'aacgm' or 1 for AACGM coordinate
;    glatc, glonc: geographic latitude and longitude of the center 
;                  of the map.
;    scale: same as the keyword 'scale' of map_set procedure.
;
; :AUTHOR: 
;   Yoshimasa Tanaka (E-mail: ytanaka@nipr.ac.jp)
;
; :HISTORY: 
;   2014/07/07: Created
; 
;-

pro map2d_init, reset=reset, set_time=set_time, coord=coord, $
			glatc=glatc, glonc=glonc, scale=scale

;===== Initialize =====;
defsysv,'!map2d',exists=exists
if (exists eq 0) or (keyword_set(reset)) then begin
    defsysv,'!map2d', $
        { $
        init: 0, $
        aacgm_dlm_exists: 0, $
        time: 0.D, $
        coord: 0, $    ; 0: geographic, 1: aagcm
        glatc: 89., $
        glonc: 0., $
        scale: 50e+6 $
        }

    ;----- Check if AACGM DLM is usable? -----;
    help, /dlm, 'AACGM', out=out
    if strmid(out[0],0,8) eq '** AACGM' then begin
        !map2d.aacgm_dlm_exists = 1
        aacgm_load_coef, 2000      ;Load the S-H coefficients for Year 2000
    endif else begin
        aacgmidl
    endelse
endif

;----- set set_time -----;
if keyword_set(set_time) then begin
    map2d_time, set_time
endif

;----- set coord -----;
if size(coord,/type) ne 0 then begin
    map2d_coord, coord
endif

;----- set glatc, glonc, scale -----;
if size(glatc,/type) ne 0 then !map2d.glatc = glatc
if size(glonc,/type) ne 0 then !map2d.glonc = (glonc+360.) mod 360.
if !map2d.glonc gt 180. then !map2d.glonc -= 360.
if keyword_set(scale) then !map2d.scale = scale

; if keyword_set(reset) then !map2d.init=0
; if !map2d.init ne 0 then return

!map2d.init = 1

return
end
