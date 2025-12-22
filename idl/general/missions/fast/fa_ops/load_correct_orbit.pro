pro load_correct_orbit,tstart,tstop,orbit0

two_hours = 7200.d              ; seconds
orbit_period = 8100.d           ; approximate

repeat begin
    get_fa_orbit,tstart,tstop,/no_store,struc=orb
    orbit = orb.orbit
    pick = where(orbit eq orbit0,npick)
    if npick eq 0 then begin
        if max(orbit) lt orbit0 then begin
            tstop = tstop + double(orbit0-max(orbit)+1L)*orbit_period
            tstart = tstart + double(orbit0-max(orbit))*orbit_period 
        endif else begin
            tstart = tstart - double(orbit0-max(orbit)+1L)*orbit_period
            tstop = tstop - double(orbit0-max(orbit))*orbit_period 
        endelse
    endif
endrep until(npick gt 0)
                    
tstart = min(onum.x(pick))-two_hours
tstop = max(onum.x(pick))+two_hours
get_fa_orbit,tstart,tstop,/all
pick = where(orbit eq orbit0,npick)
tstart = min(onum.x(pick))
tstop = max(onum.x(pick))
orbit = long(median(onum.y(pick)))
if orbit ne orbit0 then message,'WARNING: orbit ne orbit0!!!',/continue

return
end

