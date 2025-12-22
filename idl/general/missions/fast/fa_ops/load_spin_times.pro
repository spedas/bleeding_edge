;	@(#)load_spin_times.pro	1.35	
;
;  stores a time column and de-jittered sun phase, for fields summary
;  plots. 
;
function load_spin_times, spin = spin, times = times, test=test,  $
                          orbit_env = orbit_env

catch,err_stat
if (err_stat ne 0) then begin
    message,!err_string,/continue
    catch,/cancel
    return,0
endif

twopi = 2.d*!dpi
status = 0
spin_per0 = 5.07                ; nominal spin period in seconds

get_data,'spin_times',index=index
if index ne 0 then store_data,'spin_times',/delete
;
;-----removed big chunk
;
phase = fa_fields_phase(/precise)
tphi = phase.time
phi =  phase.comp2
bphi = phase.comp1

if defined(spin) then begin
    spin = spin * twopi/360.d
endif else begin
    spin = 0.d
endelse

tspan = max(tphi) - min(tphi)
nspins = long(tspan/spin_per0)
phi = phi - double(long(phi(0)/twopi))*twopi
twonpi = twopi*dindgen(nspins)+spin

spin_times = ff_interp(twonpi,phi,tphi,delt=100.) ; use sun phase for spin times
spin_times = spin_times(where(finite(spin_times)))

tstart = min(spin_times)
tstop = max(spin_times)

if keyword_set(orbit_env) then begin
    idlorb = getenv('IDLORBIT')
    if idlorb eq '' then begin
        message,'IDLORBIT is not set!',/continue
        idlorb = what_orbit_is(median(spin_times))
    endif
    idlorb = long(idlorb)
    if not get_fa_orbit_times(idlorb,tstart,tstop) then  $
      message,'problem loading orbit times for orbit '+string(orbit)
endif 

spick = select_range(phase.time,tstart,tstop,nsp)
if nsp eq 0 then begin
    message,'Spin phase headers are loaded in SDT for orbit ' + $
      ''+strcompress(string(what_orbit_is(median(tphi))))+' but orbit ' + $
      ''+strcompress(string(idlorb))+' was requested through the environment ' + $
      'variable IDLORBIT...',/continue
    return,status
endif

tphi = tphi(spick)
phi = phi(spick)
bphi = bphi(spick)

if find_handle('B_model') eq 0 then begin
    get_fa_orbit,min(tphi),max(tphi),/all
endif

if not keyword_set(test) then begin
    store_data,'spin_times',data={x:spin_times,tphi:tphi,phi:phi,bphi:bphi}
endif else begin
    store_data,'spin_times',data={x:tspin(0:10)}
endelse
status = 1

catch,/cancel
return,status

end
