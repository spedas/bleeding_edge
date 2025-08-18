;  Returns single common block packet given a file pointer


function mav_gse_cmnblk_pkt,fp,neof=neof  ;,time=time
        fst = fstat(fp)
        neof=0
        cur_ptr = fst.cur_ptr
        smallest_size = 10
        if fst.cur_ptr gt fst.size-smallest_size then return,0  ; don't read if the smallest possible packet isn't available
        swrd = 0u
        time = 0d
        valid = 0d
                seq_cntr=0u
                cc1 = 0u
                cc2 = 0u
                cc3 = 0u
                clk_sec = 0ul
                clk_sub = 0u
                mid1 = 0b
                mid2 = 0b
                mid3 = 0b
                mid4 = 0b
                user1 = 0u
                user2 = 0u
                data_byteorder = 0b
                data_type  = 0b
                data_size  = 0u
        readu,fp,swrd
        byteorder,swrd,  /swap_if_little_endian
        nbytes = 0u
        nwords = 0u
        if swrd eq 'EB90'x || swrd eq 'EB92'x then begin
            readu,fp,nwords
            byteorder,nwords,  /swap_if_little_endian
            if swrd eq 'EB90'x then nwords /=2                    ; Old format
            nbytes = nwords*2L
            if nbytes ne 0 then begin
                if fst.cur_ptr gt fst.size-nbytes then begin
                    dprint,'Incomplete packet ignored. found ',fst.size-fst.cur_ptr,' of ',nbytes,' bytes'
                    point_lun,fp,cur_ptr
     ;               return,0
                endif
                readu,fp,seq_cntr,cc1,cc2,cc3,clk_sec,clk_sub,mid1,mid2,mid3,mid4,user1,user2,data_byteorder,data_type,data_size
                byteorder,seq_cntr,cc1,cc2,cc3,clk_sub,user1,user2, /swap_if_little_endian
                byteorder,/swap_if_little_endian,/NTOHL, clk_sec   ;; this needs to be verified for all platforms
                byteorder,data_size, /swap_if_little_endian
                t_offset =  978307200d   ; long(time_double('2001-1-1'))
                time = clk_sec + clk_sub/2d^16 + t_offset
                if data_size eq 0 then data = 0 else begin
                    if data_type eq 2 then begin
                        message,'Not implemented'
                        data =  uintarr(data_size/2)
                        readu,fp,data
                    endif else begin
                        data =  bytarr(data_size)
                        readu,fp,data
                    endelse
                endelse
            endif else data = 0
            pkt = { time:time, valid:valid, sync: swrd,  length:nwords,  $
            seq_cntr:seq_cntr,  $
            cc1     : cc1,  $
            cc2     : cc2,  $
            cc3     : cc3,  $
            clk_sec : clk_sec, $
            clk_sub : clk_sub, $
            mid1    : mid1 , $
            mid2    : mid2, $
            mid3    : mid3, $
            mid4    : mid4, $
            user1   : user1, $
            user2   : user2, $
            data_byteorder: data_byteorder, $
            data_type: data_type, $
            data_size: data_size, $
            buffer:data }

        endif else begin
            pkt=0
        endelse
    return,pkt
end

