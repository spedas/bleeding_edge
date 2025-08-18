
pro mav_sep_misg_decom,cmnpkt,time=time  ,completed=completed

    common MISG_SEP_PROCESS_COM2,  $
    last_dbuffer,  $
    last_cmnpkt,  $
    status, status_ptrs,  $
    sephkp, sephkp_ptrs,  $
    sepscience, sepscience_ptrs, $
    sepnoise,   sepnoise_ptrs, $
    sepmemdump, sepmemdump_ptrs,  $
    sepcommand, sepcommands_ptrs, $
    memstate, memstate_ptrs

    realtime=1

    if keyword_set(completed) then begin
        mav_gse_structure_append  ,status_ptrs,     realtime=realtime, tname = 'MISG_2_STATUS'
        mav_gse_structure_append  ,sephkp_ptrs,     realtime=realtime, tname = 'SEP_2_HKP'
        mav_gse_structure_append  ,sepnoise_ptrs,   realtime=realtime, tname = 'SEP_2_NOISE'
        mav_gse_structure_append  ,sepscience_ptrs, realtime=realtime, tname = 'SEP_2_SCIENCE'
        mav_gse_structure_append  ,sepmemdump_ptrs, realtime=realtime, tname = 'SEP_2_MEMDUMP'
        mav_gse_structure_append  ,memstate_ptrs,   realtime=realtime, tname = 'SEP_2_MEMSTATE'
        return
    endif


    if ~keyword_set(cmnpkt) then begin  ; || (keyword_set(last_cmnpkt) && (cmnpkt.time lt last_cmnpkt.time) )  then begin
        dprint, 'Clearing common block data'
        last_cmnpkt = 0
        last_dbuffer =0
        status=0      &  status_ptrs=0
        sephkp=0      &  sephkp_ptrs=0
        sepscience=0  &  sepscience_ptrs=0
        sepnoise=0    &  sepnoise_ptrs = 0
        sepmemdump=0  &  sepmemdump_ptrs = 0
        memstate=0    &  memstate_ptrs = 0
        membuff =0
        store_data,'MISG_* SEP?_*',/clear    ; zero out contents
 ;       return
    endif

    if ~keyword_set(cmnpkt) then return

    last_cmnpkt = cmnpkt

    if cmnpkt.mid4 eq 1 then begin   ; decommutate commands sent TO MISG
        mav_gse_command_decom,cmnpkt,memstate,hkp=sephkp,membuff=membuff
        mav_gse_structure_append  ,memstate_ptrs, memstate, realtime=realtime
        return
    endif


;    tstr = time_string(cmnpkt.time)
    if not keyword_set(time) then time = cmnpkt.time
    if keyword_set(status)   then time = status.time

    dbuffer = uint(cmnpkt.buffer,0,cmnpkt.data_size/2)
    byteorder,dbuffer,/swap_if_little_endian

    if size(/n_dimen, last_dbuffer) eq 1 then begin
        dbuffer = [last_dbuffer,dbuffer]
    endif

    last_dbuffer=0

    while size(/n_dimen,dbuffer) ne 0 do begin

        misgpkt = mav_misg_packet_read_buffer(dbuffer,time=time)
        if not keyword_set(misgpkt) then begin
            dprint,'MISG packet error',dlevel=2
            last_dbuffer = dbuffer
            store_data,'CMNBLK_ERROR',cmnpkt.time,1,/append,dlim={psym:1}
            break
        endif

        case misgpkt.ctype of
        0:  begin
            tstr = '0 SYNC ERR '+time_string(systime(1),tformat='hh:mm:ss.fff')
            dprint,unit=u, dlevel=1, c,tstr,misgpkt.sync, format='(i6," ",a-24," | ",2Z6,260Z5)'
        end
        'C1'x:  begin
            status = mav_misg_status_decom(misgpkt,rec_time=cmnpkt.time,last_status=status)
            mav_gse_structure_append  ,status_ptrs, status  , realtime=realtime, tname='MISG_STATUS'
            time = status.time
;            tstr = time_string(status.time,prec=3)
;            dprint,unit=u, dlevel=4,tstr,misgpkt.sync,misgpkt.ctype,misgpkt.length,misgpkt.buffer, format='(a-24," | ",2Z6,260Z5)'
        end
        'C2'x:  begin
            dprint,unit=u, dlevel=1,tstr,misgpkt.sync,misgpkt.ctype,misgpkt.length,misgpkt.buffer, format='(a-24," | ",2Z6,260Z5)'
        end
        'C3'x:  begin
            msg = mav_misg_message(misgpkt)
            if (msg.valid eq 0) then begin
                tstr='Invalid MISG Message'
                dprint,dlevel=1,tstr
                store_data,'CMNBLK_ERROR',cmnpkt.time,tstr,/append,dlim={tplot_routine:'strplot'}
            endif else tstr = ''
            id0 = msg.id   and '111011'b            ; make all packets look like SEP1
            sepn = (msg.id and '000100'b) ne 0      ; determine SEPN
            SEPname = (['SEP1','SEP2'])[sepn]
            case id0 of
                '08'x:  dprint,dlevel=0,msg.length,' Event'
                '09'x:  dprint,dlevel=0,msg.length,' Unused'
                '18'x: begin    ;SEP Science
                    sepscience = mav_sep_science_decom(msg,hkp=sephkp ,last=sepscience, memdump=sepmemdump)  ;,last=lastscience)
                    mav_gse_structure_append,  sepscience_ptrs, sepscience , realtime=realtime, tname= SEPname+'_SCIENCE'
                    end
                '19'x: begin     ;SEP HKP
                    sephkp = mav_sep_hkp_decom(msg,last=sephkp,memstate=memstate)
                    mav_gse_structure_append  ,sephkp_ptrs, sephkp , realtime=realtime, tname=SEPname+'_HKP'
                    end
                '1a'x: begin ;SEP Noise
                    sepnoise = mav_sep_noise_decom(msg,hkp=sephkp,last=sepnoise)
                    mav_gse_structure_append, sepnoise_ptrs, sepnoise, realtime=realtime,tname=SEPname+'_NOISE'
                    end
                '1b'x: begin ; SEP MEMDUMP
                    sepmemdump = mav_sep_memdump_decom(msg,hkp=sephkp,last=sepmemdump)
                    mav_gse_structure_append, sepmemdump_ptrs, sepmemdump,  realtime=realtime,tname= SEPname+'_MEMDUMP'
                    dprint,unit=u,dlevel=4,msg.length,' MemDump' ;,string(msg.data[0:5],format=
                    end
                else:   begin
                    dprint,dlevel=0,msg.length, ' Unknown Packet'
                endelse

            endcase
            end
        endcase
    endwhile

end



