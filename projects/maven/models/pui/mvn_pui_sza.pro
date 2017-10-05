;20170413 Ali
;calculates the solar zenith angle in radians, given x,y,z
;
function mvn_pui_sza,x,y,z

r=sqrt(y^2+z^2)
sza=atan(r,x)

return,reform(sza)

end