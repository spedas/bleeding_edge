;20170111 Ali
;calculates Mars heliocentric distance (AU) and solar longitude (Ls)

pro mvn_pui_au_ls,times=times,trange=trange,mars_au=mars_au,mars_ls=mars_ls,res=res,spice=spice

au=149597870. ;astronomical unit (km)

if keyword_set(spice) then kernels=mvn_spice_kernels(['lsk','spk','std','sck','frm'],/load,trange=trange)
if ~keyword_set(res) then res=3600. ;3600 seconds (1 hour) default time resolution
if keyword_set(times) then times=time_double(times)
if keyword_set(trange) then times=dgen(range=timerange(trange),res=res)

if ~keyword_set(times) then begin
  get_timespan,trange
  times=dgen(range=timerange(trange),res=res)   
endif

inn=n_elements(times)

marspos=transpose(spice_body_pos('MARS','SUN',utc=times,check_objects='MARS'))/au ;Mars position (AU)
mars_au=sqrt(total(marspos^2,2)) ;Mars heliocentric distance (AU)

et=time_ephemeris(times,/ut2et) ;J2000 time
mars_ls=replicate(0.,inn)
for i=0,inn-1 do begin
  mars_ls[i]=!radeg*cspice_lspcn('MARS',et[i],'NONE') ;Mars solar longitude (Ls)
endfor

store_data,'Mars_(AU)',times,mars_au
store_data,'Mars_(Ls)',times,mars_ls
options,'Mars_(AU)','ystyle',1
options,'Mars_(Ls)','ystyle',1

end


