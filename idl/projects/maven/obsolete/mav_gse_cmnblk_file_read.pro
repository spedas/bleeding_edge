; Opens and decommutates generic common block files
; if a filename or pathname is not provided it will look for the latest default realtime file

pro mav_gse_cmnblk_file_read,realtime=realtime ,pathname=pathname, source=source, files=files, rtdir=rtdir,last_version=last_version,trange=trange


if n_elements(realtime) ne 1 then realtime = keyword_set(pathname) ? 0 : 1

if not keyword_set(files) then begin

    if keyword_set(pathname) and ~keyword_set(realtime) then begin   ; get common block file from either local cache or the WEB
        if not keyword_set(source) then source = mav_file_source()
        files = file_retrieve(pathname,last_version=last_version,_extra=source)
    endif

    if keyword_set(realtime) then  begin                   ; get most recent realtime common block file(s)
        if not keyword_set(rtdir) then rtdir = ''
        rtfiles = file_search( rtdir+'CMNBLK_*.dat' )
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
    dprint,dlevel=2,'Processing: '+file
;    dprint,unit=u,dlevel=0,'File: ',file
    fi= file_info(file)
    if fi.exists then   file_open,'r',file,unit=fp,dlevel=5 else continue

    if 1 then begin

        mav_cmnblk_readu,fp,count=count,eofile=eofile,decom=1,trange=trange

    endif else begin

        brk = 0
        lastbuff=0

        while  not eof(fp) and not brk do begin
    ;        if 0 then   cmnpkt = mav_gse_cmnblk_pkt(fp)  else begin
               fst = fstat(fp)
               bsize = 2^10  < (fst.size-fst.cur_ptr)
               buffer0 = bytarr(bsize)
               readu,fp,buffer0
               append_array,lastbuff,buffer0
               gseos_cmnblk_bhandler,lastbuff,remainder=lastbuff
    ;        endelse
    ;        if keyword_set(cmnpkt) eq 0 then begin
    ;            dprint,dlevel=0,'Bad common pkt'
    ;            break
    ;        endif
    ;        tstr = ''
            fs = fstat(fp)
            buffsize = -1
            dprint,dlevel=1,dwait=5.,fs.cur_ptr,fs.size,100.*fs.cur_ptr/fs.size,buffsize,format='(i8," of ",i8, " bytes (",f3.0,"%),   buffsize=",i6)',break_requested=brk
            if keyword_set(brk) then stop
    ;        dprint,dlevel=4,time_string(cmnpkt.time,prec=3),' ',cmnpkt.sync,cmnpkt.mid1,cmnpkt.mid2,cmnpkt.mid3,cmnpkt.data_size
    ;        mav_gse_cmnblk_pkt_handler,cmnpkt
        endwhile


        if bad_message_cntr ne 0 then dprint,'Warning!',bad_message_cntr,' Bad Messages'
    endelse
    free_lun,fp
endfor


end
