pro store_orbit,tstart,tstop,status = status,orbit_number=orbit_number

labels = ['MLT','ALT','ILAT']
nlabs = n_elements(labels)

print,keyword_set(orbit_number)
    
orbit = get_fa_orbit(tstart,tstop,status=status)

if status eq 0 then begin
    tags = strupcase(tag_names(orbit))
    ntags = n_elements(tags)
    for i=0,nlabs-1 do begin
        lspots = where(tags eq labels(i),nl)
        if nl gt 0 then begin
            if defined(labspots) then begin
                labspots = [labspots,lspots]
            endif else begin
                labspots = lspots
            endelse
        endif else begin
            message,'OOPS! Orbit structure has no '+labels(i)+' ' + $
              'tag!',/continue
        endelse
    endfor
    
    nspots = n_elements(labspots)
    for i=0,nspots-1 do begin
        store_data,tags(labspots(i)),data = $
          {x:orbit.time,y:orbit.(labspots(i))}
    endfor
    if keyword_set(orbit_number) then begin
        orbit_number = orbit.orbit
    endif
    
endif else begin
    message,'bad status from GET_FA_ORBIT...',/continue
endelse


return
end

