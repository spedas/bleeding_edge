;;  @(#)xfastorbvele.pro	1.2 12/15/94   Fast orbit display program

pro xfastorbvele,group=group

@fastorb.cmn

i=satdescindx
print,'Orbit:  '+string(satdesc(i).orbit,form='(i5)')+ $
      '    Epoch:  '+string(satdesc(i).epochyr,satdesc(i).epochdoy, $
                            satdesc(i).epochhr,satdesc(i).epochmin, $
                            fix(satdesc(i).epochsec), $
                            fix(satdesc(i).epochsec mod 1.0), $
                      form='(i4," Day ",i3.3,1x,2i2.2,":",i2.2,".",i3.3)')+' UT'
print,'Axis:      '+string(satdesc(i).axis)
print,'Ecc:       '+string(satdesc(i).ecc)
print,'Inc:       '+string(satdesc(i).inc)
print,'Node:      '+string(satdesc(i).node)
print,'Aperigee:  '+string(satdesc(i).aperigee)
print,'Manomaly:  '+string(satdesc(i).manomaly)

return
end
