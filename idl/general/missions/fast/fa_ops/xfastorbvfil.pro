;;  @(#)xfastorbvfil.pro	1.2 12/15/94   Fast orbit display program

pro xfastorbvfil,group=group

@fastorb.cmn

i=0l
print,'Current File:  '+satdesc(i).filename
print,'Satellite:  '+satdesc(i).sat
print,'First Orbit:  '+string(satdesc(i).orbit,form='(i5)')+ $
      '    Epoch:  '+string(satdesc(i).epochyr,satdesc(i).epochdoy, $
                            satdesc(i).epochhr,satdesc(i).epochmin, $
                            fix(satdesc(i).epochsec), $
                            fix(satdesc(i).epochsec mod 1.0), $
                      form='(i4," Day ",i3.3,1x,2i2.2,":",i2.2,".",i3.3)')+' UT'
i=n_elements(satdesc)-1
print,'Last Orbit:   '+string(satdesc(i).orbit,form='(i5)')+ $
      '    Epoch:  '+string(satdesc(i).epochyr,satdesc(i).epochdoy, $
                            satdesc(i).epochhr,satdesc(i).epochmin, $
                            fix(satdesc(i).epochsec), $
                            fix(satdesc(i).epochsec mod 1.0), $
                      form='(i4," Day ",i3.3,1x,2i2.2,":",i2.2,".",i3.3)')+' UT'
print,'Number of Orbits:  '+strtrim(string(i+1),2)
print,'Number of Orbital Vectors:  '+ $
      strtrim(string(round(total(satdesc.ndata))),2)
return
end
