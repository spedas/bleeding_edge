function fa_orbit_to_time,orbits,string=string

fa_init
common fa_information,info_struct
timesarray=info_struct.timesarray

;This line isn't redundant. It allows string inputs.
orbits=long(orbits)

norbits=n_elements(orbits)
orbitsarray=strarr(3,norbits)
orbitsarray[0,*]=strcompress(string(orbits),/remove_all)

for i=0,norbits-1 do begin
	if (orbits[i] LE 0) then begin
		print,'Error: Orbit Less than 1'
		return,0
	endif
	if (orbits[i] GE 51315) then begin
		print,'Error: Orbit Greater than 51314'
		return,0
	endif
endfor

for i=0,norbits-1 do begin

  orbitline1=timesarray[orbits[i],*]
  orbitline2=timesarray[orbits[i]+1,*]
  
  date=strcompress(string(orbitline1[1]),/remove_all)
  hms=strcompress(string(orbitline1[2],format='(i06)'),/remove_all)
  milliseconds=strcompress(string(orbitline1[3],format='(i03)'),/remove_all)
  orbitsarray[1,i]=strmid(date,0,4)+'-'+strmid(date,4,2)+'-'+strmid(date,6)+'/'+strmid(hms,0,2)+':'+strmid(hms,2,2)+':'+strmid(hms,4)+'.'+milliseconds
  
  date=strcompress(string(orbitline2[1]),/remove_all)
  hms=strcompress(string(orbitline2[2],format='(i06)'),/remove_all)
  milliseconds=strcompress(string(orbitline2[3],format='(i03)'),/remove_all)
  orbitsarray[2,i]=strmid(date,0,4)+'-'+strmid(date,4,2)+'-'+strmid(date,6)+'/'+strmid(hms,0,2)+':'+strmid(hms,2,2)+':'+strmid(hms,4)+'.'+milliseconds
  
endfor

if keyword_set(string) then return,orbitsarray

oarray=dblarr(3,norbits)
oarray[0,*]=orbits
oarray[1:2,*]=time_double(orbitsarray[1:2,*])

return,oarray

end