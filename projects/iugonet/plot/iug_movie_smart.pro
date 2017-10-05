;+
; :PROCEDURE:
;    iug_movie_smart
;
; :PURPOSE:
;    Show movie of the solar images obtained by the SMART telescope 
;      at the Hida Observatory, Kyoto Univ.
;
; :KEYWOARDS:
;    valuename : tplot variables for image data
;
; :EXAMPLES:
;    iug_movie_smart, 'smart_t1_p00'
;
; :Author:
;    Satoru UeNo (E-mail: ueno@kwasan.kyoto-u.ac.jp)
;-

pro iug_movie_smart,valuename

;Check arguments
npar = n_params()
if npar lt 1 then return
if strlen(tnames(valuename)) eq 0 then return

;Window size
window,0,xs=512,ys=512
loadct,0

get_data,valuename,data=d
Nt=n_elements(d.y[*,0,0])
print,'The number of total frames: ',Nt
tmp=dblarr(512,512,Nt)
for t=0,Nt-1 do begin
 tmp[*,*,t]=d.y[t,*,*]
endfor
movie,bytscl(tmp),order=0

end

