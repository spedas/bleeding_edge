;+
;Procedure:
;  generate_maxwellian
;
;Purpose:
;
; Simple Maxwellian generator
; sigma2 = kT/m
; 
;
;Notes:
;  
;
;$LastChangedBy: adrozdov $
;$LastChangedDate: 2018-04-27 18:30:20 -0700 (Fri, 27 Apr 2018) $
;$LastChangedRevision: 25133 $
;$URL: 
;-



pro generate_maxwellian, vx=vx,vy=vy,vz=vz,num=num,sigma2=sigma2,print=print
V = sqrt(sigma2)*randomn(SYSTIME(/seconds)*10000000, num,3, /DOUBLE)
vx = REFORM(V[*,0])
vy = REFORM(V[*,1])
vz = REFORM(V[*,2])

if(KEYWORD_SET(print)) then begin
print, '               vx            vy           vz'
print, 'max: ',  [max(vx), max(vy), max(vz)] 
print, 'mean:',  [mean(vx), mean(vy), mean(vz)]
print, 'sigma:', [STDDEV(vx), STDDEV(vy), STDDEV(vz)]
endif

end 
