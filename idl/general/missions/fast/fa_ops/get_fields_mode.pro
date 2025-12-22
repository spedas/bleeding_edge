;	@(#)get_fields_mode.pro	1.4	
;+
;
;Takes all the same keywords as GET_FA_FIELDS, returns the mode as a
; function of time, in the requested format (fields structure or
; stored for TPLOT)
;
;-
function get_fields_mode,time1,time2, NPTS=npts, START=st, EN=en,      $
                         PANF=pf, PANB=pb, ALL = all, CALIBRATE = $
                         calibrate, STORE = store, STRUCTURE = struct, $
                         SPIN = spin, REPAIR = repair

mode_byte = 13
crap = {data_name:'fields mode',valid:0L}

hdr = get_fa_fields('DataHdr_1032',time1,time2, NPTS=npts, START=st, EN=en,      $
                    PANF=pf, PANB=pb, ALL = all, STRUCTURE = $
                    struct,REPAIR = repair)

if not hdr.valid then begin
    message,'Need to load FastFieldsMode_1032 into SDT...',/continue
    return,crap
endif

modes = reform(hdr.comp1(mode_byte,*))
ord = sort(hdr.time)
tmode = hdr.time(ord)
modes = modes(ord)
nmodes = n_elements(modes)
if nmodes eq 1 then goto,only_one
;
; pick off the times where a new mode begins (if any)
;
changes = where(modes(1l:nmodes-1l) ne modes(0l:nmodes-2l),nchanges)+1l

if nchanges eq 0 then begin
    only_one:return,{data_name:'fields ' + $
                     'mode',valid:1l,time:tmode(0),comp1:modes(0),npts:1}
endif
;
; the first time is always the start of a mode...
;
time = [tmode(0),tmode(changes)]
mode = [modes(0),modes(changes)]

if not keyword_set(store) then begin
return,{data_name:'fields mode', $
        valid:1, $
        project_name:'FAST', $
        start_time:min(tmode,max=end_time), $
        end_time:end_time, $
        npts:n_elements(mode), $
        ncomp:1, $
        depth:1, $
        time:time, $
        comp1:mode}
endif else begin
    name = 'fields mode'
    store_data,name,data={x:time,y:mode}
    return,name
endelse
        
end
