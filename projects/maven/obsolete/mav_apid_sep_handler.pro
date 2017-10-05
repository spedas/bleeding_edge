function mav_apid_sep_noise_decom,ccsds

data = mav_pfdpu_part_decompress_data(ccsds)
;data = ccsds.data
dprint,ccsds.apid,n_elements(ccsds.data),n_elements(data),format='(z02,i5,i5)',dlevel=3

if n_elements(data) ge 66 then begin
    ddata = data[6:65]   
endif else begin
    printdat,data,/hex,out=outs
    dprint,outs,dlevel=2
    ddata = bytarr(60)
endelse

subsec = data[0]*256 + data[1] 
ccode = data[2]
mapid = data[3]

;printdat,ccode,hex=1
ddata = mvn_pfp_log_decomp(ddata,ccode)

p= replicate(find_peak(),6)

noise_res = 3  ; temporary fix - needs to be obtained from hkp packets    

x = (dindgen(10)-4.5) * ( 2d ^ (noise_res-3))
d = reform(ddata,10,6)
for j=0,5 do begin
;     p[j] = find_peak(d[*,j],x)
    p[j] = find_peak(d[0:8,j],x[0:8])   ; ignore end channel
endfor

dprint,dlevel=4,p.s

noise = {  $
    time: ccsds.time, $
    tdiff: ccsds.time_diff, $
    ccode:ccode,  $
    mapid:mapid,  $
    tot:p.a  ,  $
    baseline:p.x0  ,  $
    sigma:p.s,  $
    data:ddata, $          ; no decompression yet
    valid:1   }            


return,noise
end




function mav_apid_sep_memdump_decom,ccsds,lastmem=lastmem
;dprint,dlevel=2,'APID ',ccsds.apid,ccsds.seq_cntr,ccsds.size ,format='(a,z03," ",i,i)'
;data = ccsds.data
data = mav_pfdpu_part_decompress_data(ccsds)
;data = data[0:2047]
dprint,ccsds.apid,n_elements(ccsds.data),n_elements(data),format='(z02,i5,i5)',dlevel=2
subsec = data[0]*256 + data[1]
addr1 = data[4]*256u+data[5]
addr2 = data[8]*256u+data[9]
map = data[10:*]
memdump = {  $
    time: ccsds.time, $
    ccode:data[2],  $
;    addr1:addr1, $
    addr2:addr2, $
    map:map, $         
    valid:1   }        
if not keyword_set(lastmem) then    lastmem = {time:0d, map:intarr(2UL ^16)-1}
if data[7] ne 1 then message,'error'

lastmem.time = memdump.time
mn = addr2
mx = (addr2 + 2048ul-4) < (2UL^16)
lastmem.map[mn:mx-1] = map[0:mx-mn-1]
if ccsds.apid and 0 then begin
   dprint,addr2,mn,mx
   hexprint,data
   if addr2 ge 'ffff'x - 256 then begin
      hexprint,lastmem.map
   endif
endif

return,memdump
end


pro mav_sep_plot_spectra,data,avg_data=avg_data,window=wnd,color=color
   plt = get_plot_state()
 ;  dprint,'hello'
   if keyword_set(wnd) then  wi,wnd
   if n_elements(avg_data) le 1 then avg_data = data*1.
   n=10.
   avg_data = (avg_data*n + data) / (n+1) 
   yrange = minmax(avg_data > 5) * [0,2]
   plot,avg_data,xrange=[-5,260],/xstyle,yrange= yrange  ;, psym=10
   oplot,data,color=color,psym=10
   restore_plot_state,plt

end


function mav_apid_sep_science_decom,ccsds          

data = mav_pfdpu_part_decompress_data(ccsds)
;dprint,n_elements(ccsds.data),n_elements(data),dlevel=3
;if n_elements(data) lt 518 then data = [data,bytarr(518-n_elements(data))]  ; Pad if needed

len = (n_elements(data)-6)/2
;dprint,len,dlevel=3
len = 256
subsec = data[0]*256L+data[1]
seqcntr = ccsds.seq_cntr
ccode = data[2]
mapid = data[3]
attdur1 = data[4]
attdur2 = data[5]
att1 = ishft(attdur1, -6)
att2 = ishft(attdur2 ,-6)
;if ccsds.apid eq '0870'x and ccsds.time ge time_debug() and ccsds.time lt time_debug()+120 then begin
;   hexprint,ccsds.data[0:8]
;   stop
;endif
dat = { time:0d,subsec:subsec,ccode:ccode,$ 
        seq_cntr:seqcntr,  $
        mapid:mapid,att:att1, duration:0u,counts_total:0.,rate:0., data:fltarr(256) }

time = ccsds.time + (subsec / 2d^16)

dat1=dat
duration1 =(attdur1 and '111111'b)+1
dat1.time = time + duration1 /2.
;printdat,time
dat1.duration = duration1
dat1.att = att1
;ccode = ccode and 0  ; uncomment this line to look at calibration data  should use a time range to set.
dat1.data = mvn_pfp_log_decomp(data[6:len+6-1],ccode)   
dat1.counts_total = total(dat1.data)
dat1.rate = float(dat1.counts_total)/dat1.duration
;dprint,dat1.rate

delt = duration1  ; needs fixing!!
dat2=dat
duration2 =(attdur2 and '111111'b)+1
dat2.duration = duration2 
dat2.time = time + duration2/2.  + delt
dat2.att = att2
dat2.data = mvn_pfp_log_decomp(data[len+6:2*len+6-1],ccode)
dat2.counts_total = total(dat2.data)
dat2.rate = float(dat2.counts_total)/dat2.duration

;dprint,delt
return,   [dat1,dat2]
end

pro mav_sep_mapbins1
    det_names = ['X','O','T','OT','F','X','FT','FTO']
    side_names = ['A','B']
    mav_apid_sep_handler,mem1=mem1
    mapstat = {bin:0,chan:0b,side:'',det:'',width:0u,emm:[0u,0u]}
    mapstats = replicate(mapstat,256)
    map = reform(mem1.map,4096,2,8)
    map[*,*,0] = -2
    map[*,*,5] = -2   ; not possible
    for b =0,255 do begin
        w = where(map eq b,nw)
        if nw ne 0 then begin
            addr = minmax(w)
            channel = addr/4096
            if channel[0] eq channel[1] then begin
                ms = mapstat
                ms.bin = b
                chan = channel[0]
                ms.chan = chan
                ms.det = chan/2
                ms.side = chan mod 2
                ms.emm = addr mod 4096
                ms.width = nw
                nemm = ms.emm[1] - ms.emm[0] + 1
                mapstats[b] = ms
                lab = side_names[ms.side]+'-'+det_names[ms.det]
                if nemm ne nw then lab+=' Not contiguous'
                dprint,ms,lab,format='(i5,i5,i3,i3,i7, 2i7,"  ",a-10)'
            endif else dprint,b,'    Multiple mapping',i
        endif else dprint,b,'No mapping'
    endfor
 ;   for c=0,15 do begin
 ;       w = where(mapstats.chan eq c,nw)
 ;       if nw ne 0 then begin
 ;           
 ;       endif
 ;   endfor
 ;   channels = mapstats.chan
end


function mav_sep_mapbins2
    mav_apid_sep_handler,mem1=mem1
    det_names = ['X','O','T','OT','F','X','FT','FTO']
    side_names = ['A','B']
    det_pattern = [1,2,4,3,6,7]
    mapstat = {bin:0,chan:0b,side:'',det:'',width:0u,emm:[0u,0u]}
    mapstats = replicate(mapstat,256)
    map = reform(mem1.map,4096,2,8)
    ms_struct = {time:0d}
    for s=0,1 do begin
        for d=0,5 do begin         
            dp = det_pattern[d]
            m = map[*,s,dp]
            ms = m[sort(m)]
            bs = ms[uniq(ms)]
 ;           printdat,bs
            ms_array= replicate(mapstat,n_elements(bs) )
            for i =0,n_elements(bs)-1 do begin
                w = where(m eq bs[i],nw)
                if nw ne 0 then begin
            ;        print,bs[i]                    
                    ms = mapstat
                    ms.bin = bs[i]
                    ms.side = s
                    ms.det = dp
                    ms.emm = minmax(w)
                    ms.width = nw
                    nemm = ms.emm[1] - ms.emm[0] + 1
                    mapstats[i] = ms
                    lab = side_names[ms.side]+'-'+det_names[ms.det]
      ;;          if nemm ne nw then lab+=' Not contiguous'
                    dprint,ms,lab,format='(i5,i5,i3,i3,i7, 2i7,"  ",a-10)'
                    ms_array[i] = ms
                endif else dprint,b,'No mapping'
            endfor
            lab = side_names[ms.side]+'_'+det_names[ms.det]
            ;printdat,lab,ms_array
            ms_struct = create_struct(ms_struct,LAB,ms_array)
        endfor
    endfor
    return,ms_struct
end






pro mav_apid_sep_handler,ccsds,decom=decom,reset=reset,mem1=mem1,mem2=mem2 ;,realtime=realtime
    common mav_apid_sep_handler_com,manage,realtime,sep1_hkp,sep2_hkp,sep1_svy,sep2_svy,sep1_arc,sep2_arc,sep1_noise,sep2_noise   $
      ,sep1_memdump,sep2_memdump, sep1_avg,sep2_avg,lastmem1,lastmem2,sep1_last_hkp,sep2_last_hkp
;    dprint,'test 0'
    if n_elements(reset) ne 0 then begin
        manage = reset
        sep1_last_hkp =0
        sep2_last_hkp = 0
        sep1_avg = 0
        sep2_avg = 0
        lastmem1=0
        lastmem2=0
        sep1_hkp = 0
        sep2_hkp = 0
        sep1_svy = 0
        sep2_svy = 0
        sep1_arc = 0
        sep2_arc = 0
        sep1_noise = 0
        sep2_noise = 0
        sep1_memdump = 0
        sep2_memdump = 0
        realtime=1
        return
    endif
    if not keyword_set(manage) then return
    if not keyword_set(ccsds) then return
    mem1=lastmem1
    mem2=lastmem2
 ;   if (ccsds.apid and 'f0'x) eq '70'x then ccsds = mav_pfdpu_part_decompress_packet(ccsds)
 ;   dprint,'test'
    Case ccsds.apid of
      '2b'x: begin
          mav_gse_structure_append  ,sep1_hkp, realtime=realtime, tname='sep1_hkp',(sep1_last_hkp=mav_sep_hkp_pfdpu_decom(ccsds,last_hkp=sep1_last_hkp))
          ;dprint,sep1_hkp.pps_cntr,dlevel=2
          ;printdat,/value,sep1_hkp,out=sss
          ;display_text,44,exec_text=sss
          dprint,dlevel=4,sep1_last_hkp.rate_cntr
          end
      '2c'x: begin
          mav_gse_structure_append  ,sep2_hkp, realtime=realtime, tname='sep2_hkp',(sep2_last_hkp=mav_sep_hkp_pfdpu_decom(ccsds,last_hkp=sep2_last_hkp))
          dprint,dlevel=3,sep2_last_hkp.rate_cntr
          end
      '70'x: begin
          mav_gse_structure_append  ,sep1_svy, realtime=realtime, tname='sep1_svy',(sep1_spec=mav_apid_sep_science_decom(ccsds))
           ;         dprint,'Delay=',ccsds.time-systime(1)
          if abs(ccsds.time-systime(1)) lt 90 then mav_sep_plot_spectra,total(sep1_spec.data,2),avg_data=sep1_avg,window=1,color=2  ;          mav_sep_plot_spectra,spec.data
          end
      '71'x: begin
          mav_gse_structure_append  ,sep2_svy, realtime=realtime, tname='sep2_svy',(sep2_spec=mav_apid_sep_science_decom(ccsds))          
          if abs(ccsds.time-systime(1)) lt 90 then mav_sep_plot_spectra,total(sep2_spec.data,2),avg_data=sep2_avg,window=2,color=6  ;          mav_sep_plot_spectra,spec.data
          end
      '72'x: mav_gse_structure_append  ,sep1_arc, realtime=realtime, tname='sep1_arc',mav_apid_sep_science_decom(ccsds)
      '73'x: mav_gse_structure_append  ,sep2_arc, realtime=realtime, tname='sep2_arc',mav_apid_sep_science_decom(ccsds)
      '78'x: mav_gse_structure_append  ,sep1_noise, realtime=realtime, tname='sep1_noise',mav_apid_sep_noise_decom(ccsds)
      '79'x: mav_gse_structure_append  ,sep2_noise, realtime=realtime, tname='sep2_noise',mav_apid_sep_noise_decom(ccsds)
      '7c'x: mav_gse_structure_append  ,sep1_memdump, realtime=realtime, tname='sep1_memdump',mav_apid_sep_memdump_decom(ccsds,lastmem=lastmem1)
      '7d'x: mav_gse_structure_append  ,sep2_memdump, realtime=realtime, tname='sep2_memdump',mav_apid_sep_memdump_decom(ccsds,lastmem=lastmem2)
       else: return    ; Do nothing if not a SEP packet
    endcase 
    decom = 1
end
