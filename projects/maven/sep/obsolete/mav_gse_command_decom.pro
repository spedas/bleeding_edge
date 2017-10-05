pro mav_gse_command_decom,cmnpkt,memstate,hkp = last_hkp,membuff=membuff

dat = uint(cmnpkt.buffer,0,cmnpkt.data_size/2)
byteorder,dat,/swap_if_little_endian
;printdat,out=out,dat,/hex
dprint,dlevel=3,dat,format='(5(" ",Z04))'

if not keyword_set(membuff) then membuff = replicate(0b,2L^17)

if not keyword_set(memstate) then memstate = {time:0d, $
        ncmds: 0UL, $
        dcntr: 0b, $
        lastaddr:-1L, $
;        mem : ptr_new( replicate(0b,2L^17) ) , $
        DACs : replicate(0U,12), $
        map  : 0u , $
        tplsr: 0u , $
        fto:   0u , $
        enable: 0u, $
        noise:  0u, $
        blr:    0u, $
        mdmp:   0u, $
        lastcmd: 0b, $
        lastval: 0u, $
        tlast:0d }

;hexprint,dat
if n_elements(dat) eq 5  && array_equal( dat[0:2],['d8c1'x , 'a01b'x , 2u] ) then begin
    memstate.time = cmnpkt.time
    memstate.lastcmd = (cmd = dat[3])
    memstate.lastval = (val = dat[4])

    memstate.ncmds += 1
    if keyword_set(last_hkp) then  memstate.dcntr = (memstate.ncmds mod 256) - last_hkp.vcmd_cntr
    SEPN = (cmd and '40'x) ne 0
    cmd = cmd and (not '40'xu)
    case cmd of
        '12'x:   memstate.lastaddr = val
        '13'x:   memstate.lastaddr = val + 2L^16
        '14'x:   dprint,'Unused command:', dat,format='(a,5(" ",Z04))'
        '15'x:   begin
            v = val and 'FF'x
            n = ishft(val,-8)
            if n eq 0 then dprint,"Warning, using zero size fill!'
            if memstate.lastaddr lt 0 then dprint,dlevel=0,'Warning: address was not defined prior to mem fill'  $
            else if n ne 0 then   begin
;              (*memstate.mem)[memstate.lastaddr:memstate.lastaddr+n-1] = v
                append_array,membuff,replicate(v,n),index=memstate.lastaddr
;                membuff[memstate.lastaddr:memstate.lastaddr+n-1] = v
                memstate.lastaddr += n
            endif
            end
        '1a'x:   memstate.mdmp = val
        '1b'x:   memstate.mdmp = val + 2L^16
        '25'x:   memstate.fto = val
        '2a'x:   memstate.enable = val
        '2b'x:   memstate.noise  = val
        '2c'x:   memstate.blr  = val
        '2D'x:   memstate.map = val
        '23'x:   memstate.tplsr = val
        else: begin
            dac = cmd - '30'x
            if dac ge 0 and dac lt 12 then begin
                lastdacs = memstate.dacs
                memstate.dacs[dac] = val
                store_data,'SEP_MEMSTATE_DACS',cmnpkt.time+[-0.01,0],[transpose(lastdacs),transpose(memstate.dacs)],/append
            endif   else dprint,dlevel=0,cmd,val,format='(Z02,Z04,"x")'
        end
    endcase
    store_data,'SEP_MISG_COMMANDS',cmnpkt.time,string(dat,format='(6(" ",Z04))'),dlim={tplot_routine:'strplot'},/append
endif else begin
    dprint,dlevel=3,time_string(cmnpkt.time),'unknown commands:',dat,format='(a," ",a,6(" ",Z04))'
    store_data,'SEP_MISG_COMMANDS',cmnpkt.time,string(dat,format='(6(" ",Z04))'),dlim={tplot_routine:'strplot'},/append
endelse

return
end
