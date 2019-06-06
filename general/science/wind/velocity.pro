;+
;FUNCTION:   velocity(energy,mass)
;PURPOSE:
;  Returns the relativistic momentum over mass given the energy and mass
;
;-
function velocity,nrg,mass,true_veloc=tv,momen_on_mass=mom, $
electron=el,proton=proton,alpha=alpha,inverse=inverse

c2 = 2.99792d5^2
c  = 2.99792d5     ; velocity of light in km/s

if keyword_set(el) then mass= 511000.d/c2
if keyword_set(proton) then mass= 511000.d/c2*1836.
if keyword_set(alpha) then mass= 511000.d/c2*1836. * 2

E0 = mass*c2

if keyword_set(tv) then begin
   gamma = (nrg+e0)/e0   
   vmag  = sqrt((1.-1./gamma^2)*c2)
   if keyword_set(inverse) then message,'not working!'
   return,vmag
endif
if 1 then begin    ;  momentum over mass
   if keyword_set(inverse) then begin
      vel= nrg
      return, e0 * (sqrt(1+((vel/c)^2))-1)
   endif
   vmag = sqrt(2.*nrg/mass * (1 +nrg/e0/2))
   return ,vmag
endif
end




  
