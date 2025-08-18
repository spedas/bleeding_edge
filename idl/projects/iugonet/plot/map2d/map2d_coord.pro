;+
; PROCEDURE map2d_coord
; 
; :DESCRIPTION:
;    Set the coordinate to the geographic or AACGM.
;
; :PARAMS:
;    coord: the name of the coordinate system.
;        'geo' or 0 for Geographic coordinate
;        'aacgm' or non-zero numbers for AACGM coordinate
;
; :AUTHOR: 
;   Yoshimasa Tanaka (E-mail: ytanaka@nipr.ac.jp)
;
; :HISTORY: 
;   2014/08/12: Created
; 
;-

pro map2d_coord, coord, guiet=quiet

;Initialize !map2d system variable
map2d_init

;----- set coord -----;
type_coord=size(coord,/type)
if type_coord ne 0 then begin
    if type_coord eq 7 then begin	;string
        case strlowcase(coord) of
            'geo': tcoord=0
            'aacgm': tcoord=1
            else: begin
                print, 'Not support such coordinate system!'
                return
            end
        endcase
    endif else begin
        if (type_coord gt 0) and (type_coord lt 6) then begin
            if coord eq 0 then begin
                tcoord=0
            endif else begin
                tcoord=1
            endelse
        endif else begin
            print, 'Not support such data type for coord!'
            return
        endelse
    endelse
    !map2d.coord = tcoord
endif

if ~keyword_set(quiet) then begin
    case !map2d.coord of
        0: print, 'Set to geographic coordinate'
        1: print, 'Set to AACGM coordinate'
    endcase
endif

return
end
