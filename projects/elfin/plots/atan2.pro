;+
; FUNCTION:
;         atan2
;
; PURPOSE:
;         Utility routine to calculate the arc tangent. This routine is currently
;         used by the ELFIN orbit plots
;
; KEYWORDS:
;         yin: y variable
;         xin: x variable
;         degrees: set this flag to output results in degrees. if not set the 
;                  result will be in radians 
;         full_circle: if set, output is 0-360 degs, if not it is +-180 degs
;
; OUTPUT:
;         arc tangent
;
; AUTHOR: Jiang Liu
;-
function atan2, yin, xin, degrees = degrees, full_circle = full_circle
  dimx = size(xin, /dimensions)
  dimy = size(yin, /dimensions)
  if dimx(0) ne dimy(0) then begin
    print, 'ATAN2: the dimension of y and x do not agree!'
    return, !values.f_nan
  endif
  
  if dimx(0) eq 0 then begin
  	case 1 of
  	xin gt 0: result=atan(yin/xin)
  	xin lt 0: if yin ge 0 then result=!pi+atan(yin/xin) else result=-!pi+atan(yin/xin)
  	else: begin ;; x==0
  		case 1 of
  		yin gt 0: result = !pi/2
  		yin lt 0: result = -!pi/2
  		else: result = !values.f_nan ;; y==0 too
  		endcase
  		end
  	endcase
  	if keyword_set(full_circle) then begin
  		if result lt 0. then result = result+2*!pi
  	endif
  endif else begin
  	result = dblarr(dimx)
  	for i = 0, n_elements(xin)-1 do begin
  		x = xin[i]
  		y = yin[i]
  
  		case 1 of
  		x gt 0: result[i]=atan(y/x)
  		x lt 0: if y ge 0 then result[i]=!pi+atan(y/x) else result[i]=-!pi+atan(y/x)
  		else: begin ;; x==0
  			case 1 of
  			y gt 0: result[i] = !pi/2
  			y lt 0: result[i] = -!pi/2
  			else: result[i] = !values.f_nan ;; y==0 too
  			endcase
  			end
  		endcase
  
  		if keyword_set(full_circle) then begin
  			if result[i] lt 0. then result[i] = result[i]+2*!pi
  		endif
  	endfor
  endelse
  
  if keyword_set(degrees) then result = result/!pi*180.

  return, result
end
