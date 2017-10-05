pro fa_orbitrange,orbitrange


if NOT keyword_set(orbitrange) then begin
	print,'Error @ fa_orbitrange.pro: No Orbit Range Set'
	return
endif

orbitrange_tmp=orbitrange

if n_elements(orbitrange_tmp) EQ 2 then begin
	if orbitrange_tmp[0] GT orbitrange_tmp[1] then begin
		orbitrange_tmp=[orbitrange_tmp[1],orbitrange_tmp[0]]
	endif
	if (orbitrange_tmp[0] LT 1) OR (orbitrange_tmp[0] GT 51315) then begin
		print,'Error: Invalid Lower Orbit'
		return
	endif
	if (orbitrange_tmp[1] LT 1) OR (orbitrange_tmp[1] GT 51315) then begin
		print,'Error: Invalid Upper Orbit'
		return
	endif
endif
if n_elements(orbitrange_tmp) EQ 1 then begin
	if (orbitrange_tmp LT 1) OR (orbitrange_tmp GT 51315) then begin
		print,'Error: Invalid Orbit'
		return
	endif
	orbitrange_tmp=[orbitrange_tmp,orbitrange_tmp]
endif

orbits_time=fa_orbit_to_time(orbitrange_tmp)
trange=[orbits_time[1,0],orbits_time[2,1]]
dt=trange[1]-trange[0]-20
timespan,trange[0],dt,/seconds

return

end