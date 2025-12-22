;	@(#)normn3.pro	1.4	07/27/01
;+
; Normalizes vectors, must be n by 3. 
;-
function normn3, x

sx = size(x)

ok = ((sx[0] eq 2) and (sx[2] eq 3)) or (sx[sx[0]+2] eq 3)

if not ok then begin
    message, 'not an N x 3 vector...',/continue
    return,!values.f_nan
endif

if  ((sx[0] eq 2) and (sx[2] eq 3)) then begin
    xmag = sqrt(total(x^2,2))
    vec = [[x(*,0) / xmag],[x(*,1) / xmag],[x(*,2) / xmag]]
endif else begin
    xmag = sqrt(total(x^2))
    vec = [[x(0) / xmag],[x(1) / xmag],[x(2) / xmag]]
endelse



return,vec
end

