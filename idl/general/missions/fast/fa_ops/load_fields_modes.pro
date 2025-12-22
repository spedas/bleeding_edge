function load_fields_modes,spin = spin

status = 0
hdr = get_fa_fields('DataHdr_1032',/all)

if not hdr.valid then begin
    message,'Need to load DataHdr_1032 into SDT...',/continue
    return,status
endif

modes = reform(hdr.comp1(13,*))
ord = sort(hdr.time)
tmode = hdr.time(ord)
modes = modes(ord)

nt = n_elements(tmode)

done = 0
istart=0
tstart = tmode(istart)
startmode = modes(istart)
repeat begin 
    istop = min(where(modes(istart:nt-1l) ne modes(istart)))+istart
    if ((istop gt istart) and istop lt (nt-1l)) then begin
        istart = istop + 1l
        tstart = [tstart,tmode(istart)]
        startmode = [startmode,modes(istart)]
    endif else begin
        done = 1
    endelse
endrep until done
status = 1

store_data,'Fmode',data={x:tmode,y:modes,tstart:[tstart],mode:[startmode]}

return,status
end

