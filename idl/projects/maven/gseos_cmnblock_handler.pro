
function gseos_cmnblock_pkt,dbuff

    clk_sec = dbuff[6]*2ul^16+dbuff[7]
    clk_sub = dbuff[8]
    t_offset =  978307200d   ; long(time_double('2001-1-1'))
    time = clk_sec + clk_sub/2d^16 + t_offset
    data_byteorder = byte(ishft(dbuff[13],-8))
    data_type = byte(dbuff[13])
    data_size = dbuff[14]
    if data_size eq 0 then data = 0 else begin
        if data_type eq 2 then begin
            message,'Not implemented'
            data = dbuff[15:15+data_size/2-1]
        endif else begin
            data = byte(dbuff[15:15+data_size/2-1],0,data_size)
        endelse
    endelse


    pkt = { time:time, $
            valid   :  1,   $
            sync:     dbuff[0],  $
            length  : dbuff[1]/2,  $
            seq_cntr: dbuff[2],  $
            cc1     : dbuff[3],  $
            cc2     : dbuff[4],  $
            cc3     : dbuff[5],  $
            clk_sec : clk_sec,   $
            clk_sub : clk_sub,   $
            mid1    : byte(ishft(dbuff[9],-8)) , $
            mid2    : byte(dbuff[9]), $
            mid3    : byte(ishft(dbuff[10],-8)), $
            mid4    : byte(dbuff[10]), $
            user1   : dbuff[11], $
            user2   : dbuff[12], $
            data_byteorder: data_byteorder, $
            data_type: data_type , $
            data_size: data_size, $
            buffer:data }

dprint,dlevel=3,pkt.time-time
return,pkt
end






pro gseos_cmnblock_handler,buffer,time=time

common cmnblock_com, lastbuff, nn , c1,c2,c3

dbuff = uint(buffer,0,n_elements(buffer)/2)
byteorder,dbuff,/swap_if_little_endian

;wait,1.5
;dprint,dlevel=4,dbuff,format= '(30(" ",Z04))'

nb = n_elements(dbuff)
i=0
j=0
while (i lt nb-1) do begin
    if dbuff[i] eq 'EB90'x then begin
        len = dbuff[i+1] /2
        if i+len le nb then begin
            dprint,dlevel=3,j++,dbuff[i:i+len-1],format='(i2,":",100(" ",Z04))'
            i = i+len
        endif else begin
            dprint,'Incomplete packet'
            return
;            message,'code needs fixing
        endelse
    endif else begin
        dprint,dlevel=1,'Lost Sync'
    endelse
endwhile
return
end

