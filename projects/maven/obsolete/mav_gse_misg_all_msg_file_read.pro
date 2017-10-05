; Opens and decommutates generic common block files
; if a filename or pathname is not provided it will look for the latest default realtime file

pro mav_gse_misg_all_msg_file_read,realtime=realtime ,pathname=pathname, source=source, files=files, rtdir=rtdir


if n_elements(realtime) ne 1 then realtime = keyword_set(pathname) ? 0 : 1

if not keyword_set(files) then begin

    if keyword_set(pathname) and ~keyword_set(realtime) then begin   ; get common block file from either local cache or the WEB
        if not keyword_set(source) then source = mav_file_source()
        files = file_retrieve(pathname,/last_version,_extra=source)
    endif

    if keyword_set(realtime) then  begin                   ; get most recent realtime common block file(s)
        if not keyword_set(rtdir) then rtdir = ''
        rtfiles = file_search( rtdir+'STREAM_*.dat' )
        nf = n_elements(rtfiles)
        rtfiles = rtfiles[sort(rtfiles)]
        rtfiles = rtfiles[nf-abs(realtime):*]
        append_array,files,rtfiles
    endif
endif

;file_open,'w','common_out.txt',unit=u,dlevel=2

time=0d

nf = n_elements(files) * keyword_set(files)


for fn = 0,nf-1 do begin
    bad_message_cntr=0

    file = files[fn]
    dprint,dlevel=0,'Processing: ',file
    rawtcp = strmatch(file,'*STREAM_*',/fold_case)

;    dprint,unit=u,dlevel=0,'File: ',file
    fi= file_info(file)
    if fi.exists then   file_open,'r',file,unit=fp,dlevel=3 else continue
    brk = 0

    while  not eof(fp) and not brk do begin
        if keyword_set(rawtcp) then begin
            buffsize = 0
            dummy = 0
            readu,fp,dummy,buffsize & byteorder,dummy,buffsize , /swap_if_little_endian
            buffsize = buffsize/2   ; (number of words)
;            dprint,buffsize,/phelp, dlevel=2, dwait=5.
        endif else buffsize = 2048L
        fs = fstat(fp)
        buffsize = (fs.size - fs.cur_ptr)/2 < buffsize
        buffer0 = uintarr(buffsize)
        readu,fp,buffer0   &  byteorder,buffer0,  /swap_if_little_endian
        if keyword_set(buffer) then buffer = [buffer,buffer0] else buffer=buffer0
        dprint,dlevel=1,dwait=5.,fs.cur_ptr,fs.size,100.*fs.cur_ptr/fs.size,buffsize,format='(i8," of ",i8, " bytes (",f3.0,"%),   buffsize=",i6)',break_requested=brk

        if keyword_set(brk) then stop
;        dprint,dlevel=3 ,time_string(cmnpkt.time,prec=3),' ',cmnpkt.sync,cmnpkt.mid1,cmnpkt.mid2,cmnpkt.mid3,cmnpkt.data_size
;        printdat,buffer,output=str   &     dprint,dlevel=3,str
        mav_sta_misg_decom,buffer = buffer
    endwhile
    if bad_message_cntr ne 0 then dprint,'Warning!',bad_message_cntr,' Bad Messages' else dprint,'Done'
    free_lun,fp
endfor
;free_lun,u


end
