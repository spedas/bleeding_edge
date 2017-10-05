pro mav_user_note_handler,cmnblk

    dl = 3
    dprint,dlevel=dl,time_string(cmnblk.time)+' User note: "'+string(cmnblk.buffer)+'"'
    if cmnblk.mid4 eq 1 then begin
        dprint,dlevel=2,string(cmnblk.buffer)
        store_data,'CMNBLK_USER_NOTE',cmnblk.time,string(cmnblk.buffer),/append,dlim={tplot_routine:'strplot'}
    endif
    if cmnblk.mid4 eq 2 then begin   ;  cmnblk_store command
        str = string(cmnblk.buffer)
        pos = strpos(str,'=')
        varname = strmid(str,0,pos)
        value = strmid(str,pos+1)
        bmap = bytarr(256)
        bmap[byte('-0.123456789')] =1
        bstr = byte(value)
        if bmap[bstr[0]] then value = float(value)  ; convert to float if possible
;        printdat,str
        dprint,dlevel=2,varname,value
        store_data,varname,cmnblk.time,value,/append
    endif


end