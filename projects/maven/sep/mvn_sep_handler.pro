; $LastChangedBy: ali $
; $LastChangedDate: 2020-01-31 14:37:52 -0800 (Fri, 31 Jan 2020) $
; $LastChangedRevision: 28266 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/sep/mvn_sep_handler.pro $

function  find_peak,d,cbins,window = wnd,threshold=threshold
nan = !values.d_nan
peak = {a:nan, x0:nan, s:nan}
if n_params() eq 0 then return,peak
if not keyword_set(cbins) then cbins = dindgen(n_elements(d))

if keyword_set(wnd) then begin
    mx = max(d,b)
    i1 = (b-wnd) > 0
    i2 = (b+wnd) < (n_elements(d)-1)
;    dprint,wnd
    pk = find_peak(d[i1:i2],cbins[i1:i2],threshold=threshold)
    return,pk
endif
if keyword_set(threshold) then begin
   dprint,'not functioning'
endif

t = total(d)
avg = total(d * cbins)/t
sdev = sqrt(total(d*(cbins-avg)^2)/t)
peak.a=t
peak.x0=avg
peak.s=sdev
return,peak
end



function mvn_apid_sep_noise_decom,ccsds

data = mvn_pfdpu_part_decompress_data(ccsds,cfactor=cfactor)
;data = ccsds.data
;dprint,ccsds.apid,n_elements(ccsds.data),n_elements(data),format='(z02,i5,i5)',dlevel=3

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

duration = 0u

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
    met: ccsds.met, $
    tdiff: ccsds.time_diff, $
    duration: duration, $
    ccode:ccode,  $
    mapid:mapid,  $
    noise_res:noise_res,  $
    tot:p.a  ,  $
    baseline:p.x0  ,  $
    sigma:p.s,  $
    data:ddata, $      
    cfactor:cfactor, $
    valid:1   }            


return,noise
end


function mvn_pfdpu_read_dpu_commands,trange,ncommands  ; reads commands within a time range and returns them
common mav_pfdpu_cmnblk_handler_com,command_ptrs,realtime
ncommands=0
if ~keyword_set(command_ptrs) then return,0
pkts = *command_ptrs.x
if n_elements(trange) ne 2 then begin
  ctime,trange,npoints=2,/silent
  printdat,/value,time_string(trange) ,varname='T_cmd'
endif
w = where(pkts.time ge trange[0] and pkts.time le trange[1],ncommands)
if ncommands eq 0 then return,0
return,pkts[w].buffer[14:17]
end

function mvn_sep_commands_to_lut,sepn,cmds=cmds,trange=trange,LUT1=LUT1,LUT2=LUT2  ; sepn is 0 or 1
 if ~keyword_set(cmds) then  cmds= mvn_pfdpu_read_dpu_commands(trange,ncommands)
; printdat,cmds,ncommands,/hex
nc= n_elements(cmds)/4
 w = where(cmds[0,*] ne 'fe'x  ,npfp)
 w = where(cmds[0,*] eq 'fe'x  ,nsep)
 scmds = cmds
 mask = '40'xb
 dprint,nc,' Total Commands',nsep, ' SEP Commands ',npfp,' PFP Commands'
 lut1 = replicate(-1,2L^17)
 ptr1 =0L                     ; comment out to get intentional fail
 lut2 = replicate(-1,2L^17)
 ptr2 =0L                     ; comment out to get intentional fail
 for i= 0L,nc-1 do begin
    c = scmds[*,i]
    if c[0] ne 'FE'x then begin
       dprint,c,'  non SEP',format='(4(Z02," "),a)' 
       continue
    endif
    case c[1] of
     '12'x: ptr1 = c[2] * 256L + c[3]
     '13'x: ptr1 = c[2] * 256L + c[3] +2L^16
     '15'x: for j=0,c[2]-1 do lut1[ptr1++] = c[3]   ; intentionally designed to fail here. 
     '52'x: ptr2 = c[2] * 256L + c[3]
     '53'x: ptr2 = c[2] * 256L + c[3] +2L^16
     '55'x: for j=0,c[2]-1 do lut2[ptr2++] = c[3]   ; intentionally designed to fail here. 
     else: dprint,c,format='(4(Z02," "))' 
    endcase
 ;   ptr = ptr mod 2L^16
endfor
LUT1 = LUT1[2L^16 : *]
LUT2 = LUT2[2L^16 : *]
w = where(lut1 eq -1,nw)
if nw ne 0 then dprint,'LUT1 not fully loaded!'
w = where(lut2 eq -1,nw)
if nw ne 0 then dprint,'LUT2 not fully loaded!'
lut1= byte(lut1)
lut2= byte(lut2)
return, sepn ? lut2 : lut1
end



function mvn_mag_hkp_decom_f0,ccsds
data = ccsds.data
data2 = uint(data,0,n_elements(data)/2)  & byteorder,data2,/swap_if_little_endian

;mag_temp_coeff = [2.81E-39,  8.23E-34,  -4.58E-30, -6.02E-25, 3.16E-21,  1.81E-16,  -2.94E-13, -1.45E-08, 1.30E-03,  8.87E+00]


hkp = { time: ccsds.time, $
MET: ccsds.met, $
;message_id: data2[0], $
;sync_1: data2[1], $
;sync_2: data2[2], $
;cmd_ctr: data2[3], $
frm_ctr: data2[4], $
f0:  ulong(data2[5]), $
time_f1: data2[6], $
time_f2: data2[7], $
time_f3: data2[8], $
F_MET: data2[6] * 2d^16 + data2[7] + data2[8]/2d^16, $
;status_flag: data2[9], $
;xtest: data2[10] * 0.016115, $
;ytest: data2[11] * 0.016115, $
;ztest: data2[12] * 0.016115, $
;RTEST: data2[13] * 0.016115, $
;VCALMON: data2[14] * 0.000392, $
;P82VMON: data2[15] * 0.000392, $
;M82VMON: data2[16] * 0.000392, $
;SNSRTEMPRAW: fix(data2[17])* 2.5/ 2L^15, $
;PCBTEMPRAW:  fix(data2[18])* 2.5/ 2L^15, $
;SNSR_TEMP:mvn_mag_analog_conversion( fix(data2[17])* 1.,coeff=mag_temp_coeff), $
;PCB_TEMP: mvn_mag_analog_conversion( fix(data2[18])* 1.,coeff=mag_temp_coeff), $
;P13VMON: fix(data2[19]) * 0.000531, $
;M13VMON: fix(data2[20]) * 0.000531, $
;P114VREF: fix(data2[21])* 0.000392, $
;P25VDIG: fix(data2[22]) * 0.000256, $
;P35VDIG: fix(data2[23]) * 0.000256, $
;P5VADC: fix(data2[24]) * 0.000256, $
;M5VADC: fix(data2[25]) * 0.000256, $
;DIG_HK_00: data2[26], $
;DIG_HK_01: data2[27], $
;DIG_HK_02: data2[28], $
;DIG_HK_03: data2[29], $
;DIG_HK_04: data2[30], $
;DIG_HK_05: data2[31], $
;DIG_HK_06: data2[32], $
;DIG_HK_07: data2[33], $
;BSCI: fix(data2[[34,35,36]]), $
;BSCI_X0: data2[34], $
;BSCI_Y0: data2[35], $
;BSCI_Z0: data2[36], $
;CHECKSUM: data2[37], $
;OPT: data2[38], $
;RSTLMT: byte(ishft(data2[39],-8)), $
;RSTSEC: byte(data2[40]), $
;OFF0: fix(data2[[40,41,42]]), $
;XOFF0: data2[40], $
;YOFF0: data2[41], $
;ZOFF0: data2[42], $
;OFF1: fix(data2[[43,44,45]]), $
;XOFF1: data2[43], $
;YOFF1: data2[44], $
;ZOFF1: data2[45], $
;OFF3: fix(data2[[46,47,48]]), $
;XOFF3: data2[46], $
;YOFF3: data2[47], $
;ZOFF3: data2[48], $
valid:1}
return,hkp
end




function mvn_apid_sep_memdump_decom,ccsds,lastmem=lastmem
;dprint,dlevel=2,'APID ',ccsds.apid,ccsds.seq_cntr,ccsds.size ,format='(a,z03," ",i,i)'
;data = ccsds.data
data = mvn_pfdpu_part_decompress_data(ccsds)
;data = data[0:2047]
dprint,ccsds.apid,n_elements(ccsds.data),n_elements(data),format='(z02,i5,i5)',dlevel=3
subsec = data[0]*256 + data[1]
addr1 = data[4]*256u+data[5]
addr2 = data[8]*256u+data[9]
map = data[10:*]
printdat,map
n = n_elements(map)
map = reform( reverse( reform(map,2,n/2),1),n)   ; Swap even and odd values... Not sure why it worked this way. 

memdump = {  $
    time: ccsds.time, $
    ccode:data[2],  $
;    addr1:addr1, $
    addr2:addr2, $
    map:map, $         
    valid:1   }        
if not keyword_set(lastmem) then    lastmem = {time:0d, map:intarr(2UL ^16)-1}
if data[7] ne 1 then begin
  dprint,'Memdump error'
  memdump.valid=0
endif
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


pro mvn_sep_plot_spectra,data,avg_data=avg_data,window=wnd,color=color
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


function mvn_apid_sep_science_decom,ccsds

data = mvn_pfdpu_part_decompress_data(ccsds,cfactor=cfactor)
if n_elements(data) ne 518 then begin
   dprint,'Bad decompression',n_elements(ccsds.data),n_elements(data),dlevel=2
;if n_elements(data) lt 518 then data = [data,bytarr(518-n_elements(data))]  ; Pad if needed
endif
;cfactor = float(n_elements(ccsds.data))/float(n_elements(data))

len = (n_elements(data)-6)/2
;dprint,len,dlevel=3
len = 256
subsec = data[0]*256L+data[1]
seqcntr = ccsds.seq_cntr

sensor= byte(ccsds.apid and 1) + 1b        ; this needs checking!
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
dat = { time:0d,  $      ; Unix time
        met: 0d,  $      ; Mission elapsed time
        et:  0d,  $      ; Ephemeris time
        subsec:subsec, $
        f0: 0UL, $   ; place holder for SC time counter.
        delta_time: 0d,  $
        trange:[0d,0d],  $
        seq_cntr:seqcntr,  $
        dseqcntr:0ul,  $
        sensor:sensor, $
        ccode:ccode,$ 
        mapid:mapid,att:att1,$
        duration:0u,$
        counts_total:0.,rate:0.,cfactor:cfactor, data:fltarr(256), $
        valid:0 }

time = ccsds.time + (subsec / 2d^16)
met  = ccsds.met + (subsec/2d^16)
dat1=dat
duration1 =(attdur1 and '111111'b)+1
dat1.time = time + duration1 /2.
dat1.met  = met + duration1/2.
dat1.trange = [time,time+duration1]
;printdat,time
dat1.delta_time = duration1
dat1.duration = duration1
dat1.att = att1
if met lt 1354320000 then ccode = ccode and 0  ; uncomment this line to look at calibration data  should use a time range to set.
dat1.data = mvn_pfp_log_decomp(data[6:len+6-1],ccode)   
dat1.counts_total = total(dat1.data)
dat1.rate = float(dat1.counts_total)/dat1.duration
;dprint,dat1.rate

delt = duration1  ; needs fixing!!
dat2=dat
duration2 =(attdur2 and '111111'b)+1
dat2.delta_time = duration2
dat2.duration = duration2 
dat2.time = time + duration2/2.  + delt
dat2.met  = met  + duration2/2.  + delt
dat2.trange = [time,time+duration2] + delt
dat2.att = att2
dat2.data = mvn_pfp_log_decomp(data[len+6:2*len+6-1],ccode)
dat2.counts_total = total(dat2.data)
dat2.rate = float(dat2.counts_total)/dat2.duration

;dprint,delt
return,   [dat1,dat2]
end

pro mvn_sep_mapbins1
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


function mvn_sep_mapbins2
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



pro mvn_sep_extract_data,dataname,data,trange=trange,tnames=tnames,tags=tags,num=num

@mvn_sep_handler_commonblock.pro

;    common mav_apid_sep_handler_com , sep_all_ptrs ,  sep1_hkp,sep2_hkp,sep1_svy,sep2_svy,sep1_arc,sep2_arc,sep1_noise,sep2_noise   $
;      ,sep1_memdump,sep2_memdump,mag1_hkp_f0,mag2_hkp_f0


count=0
data=0
if ~keyword_set(sep_all_ptrs) then begin
   dprint,'No data has been loaded!'
   return   ;,data
endif
w = where(dataname eq sep_all_ptrs.name,nw)
if nw ne 1 then begin
   if nw eq 0 then  dprint,'Data not found: '+dataname  else dprint,'Multiple names found: '+dataname
      dprint,sep_all_ptrs.name
   return   ;,data
endif
ptrs= sep_all_ptrs[w]
datap = ptrs.x
num = n_elements(*datap)
if keyword_set(trange) then begin
    trr = minmax( time_double( trange)) 
    tr = (*datap).trange
    w = where( (tr[0,*] le trr[1]) and (tr[1,*] gt trr[0] ) ,num)   
;    if tr[0] eq tr[1] then begin
;       test = t le tr[0] 
;       w = where(test,nw)
;       num = 1
;       if nw ne 0 then    w = w[nw-1]  else num = 0
;    endif else begin
;       test = t ge tr[0] and  t lt tr[1]
;       w = where( test ,num)
;    endelse
    if num eq 0 then begin
        dprint,'No ',dataname,' data found in time range: '+strjoin(time_string(trr),' - ')
    endif else begin
        data = (*datap)[w]       
    endelse
endif else data = *datap
if keyword_set(tags) then begin
;    printdat,ptrs,datap,data,sep1_svy
    if keyword_set(tnames) then prefix =tnames else prefix=ptrs.name
printdat,prefix
    mav_gse_structure_append,   ptrs,   tname=prefix, tags=tags
    
endif
return  ;,data
end





pro mvn_sep_var_save,filename,pathname=pathname,trange=trange,prereq_info=prereq_info,verbose=verbose,description=description

@mvn_sep_handler_commonblock.pro
@mvn_pfdpu_handler_commonblock.pro

if not keyword_set(filename) then begin
  if not keyword_set(trange) then trange = minmax((*(sep1_svy.x)).time)
  res = 86400.d
  days =  round( time_double(trange )/res )
  ndays = days[1]-days[0]
  tr = days * res
  if not keyword_set(pathname) then pathname =  'maven/pfp/sep/l1/sav/YYYY/MM/mvn_sep_l1_YYYYMMDD_$NDAY.sav' 
  pn = str_sub(pathname, '$NDAY', strtrim(ndays,2)+'day')
  filename = mvn_pfp_file_retrieve(pn,/daily,trange=tr[0],source=source,verbose=verbose,/create_dir)
  dprint,dlevel=2,verbose=verbose,'Creating: ',filename
endif

if 1 then begin
 ; undefine, s1_hkp,s1_svy,s1_arc,s1_nse   
 ; undefine, s2_hkp,s2_svy,s2_arc,s2_nse
  sw_version = mvn_sep_sw_version()
  spice_kernels = spice_test('*')
  spice_info = file_checksum(/add_mtime,spice_kernels)
  if keyword_set(sep1_hkp) then s1_hkp = *sep1_hkp.x
  if keyword_set(sep1_svy) then s1_svy = *sep1_svy.x
  if keyword_set(sep1_arc) then s1_arc = *sep1_arc.x
  if keyword_set(sep1_noise) then s1_nse = *sep1_noise.x 
  if keyword_set(sep2_hkp) then s2_hkp = *sep2_hkp.x
  if keyword_set(sep2_svy) then s2_svy = *sep2_svy.x
  if keyword_set(sep2_arc) then s2_arc = *sep2_arc.x
  if keyword_set(sep2_noise) then s2_nse = *sep2_noise.x
  if keyword_set(mag1_hkp_f0) then m1_hkp = *mag1_hkp_f0.x
  if keyword_set(mag2_hkp_f0) then m2_hkp = *mag2_hkp_f0.x
  
  if keyword_set(apid20x) then ap20 = *apid20x.x
  if keyword_set(apid21x) then ap21 = *apid21x.x
  if keyword_set(apid22x) then ap22 = *apid22x.x
  if keyword_set(apid23x) then ap23 = *apid23x.x
  if keyword_set(apid24x) then ap24 = *apid24x.x
  if keyword_set(apid25x) then ap25 = *apid25x.x
  
  if keyword_set(source_filenames) then source_filename = source_filenames

  file_mkdir2,file_dirname(filename)  
  save,filename=filename,verbose=verbose,s1_hkp,s1_svy,s1_arc,s1_nse,s2_hkp,s2_svy,s2_arc,s2_nse,m1_hkp,m2_hkp,sw_version,prereq_info,spice_info,ap20,ap21,ap22,ap23,ap24,ap25,source_filename,description=description
;  l1_filename = filename
endif else begin
  save,verbose=verbose,filename=filename,sep_all_ptrs,sep1_hkp,sep2_hkp,sep1_svy,sep2_svy,sep1_arc,sep2_arc,sep1_noise,sep2_noise,sep1_memdump,sep2_memdump
endelse
end







pro mvn_sep_handler,ccsds,decom=decom,reset=reset,debug=debug,finish=finish,set_realtime=set_realtime,record_filenames=record_filenames ,clear=clear,set_manage=set_manage $
 ,trange=trange,svy_tags=svy_tags,hkp_tags=hkp_tags,noise_tags=noise_tags,sepnum=sepnum,mag_tags=mag_tags,units_name=units_name,lowres=lowres,arc=arc

    common mav_apid_sep_handler_misc_com,manage,realtime,sep1_avg,sep2_avg,lastmem1,lastmem2,sep1_last_hkp,sep2_last_hkp ,sep1_spec,sep2_spec,sep1arc_spec,sep2arc_spec

;  All SEP data is stored in the common block variables
@mvn_sep_handler_commonblock.pro

    if n_elements(sepn) eq 0 then sepn=3
    if n_elements(magnum) eq 0 then magnum=3
    if not keyword_set(ccsds) then begin  
        if n_elements(reset) ne 0 then begin
           manage = reset
           realtime=0
           sep1_last_hkp =0
           sep2_last_hkp = 0
           sep1_avg = 0
           sep2_avg = 0
 ;          lastmem1=0
 ;          lastmem2=0
           clear = keyword_set(reset)
        endif
        if n_elements(set_manage) ne 0 then manage=set_manage
        if n_elements(set_realtime) ne 0 then realtime=set_realtime
        if keyword_set(debug) then begin
           dprint,phelp=debug,manage,realtime
           if (sepn and 1) ne 0 then dprint,phelp=debug,sep1_hkp,sep1_svy,sep1_arc,sep1_memdump,lastmem1
           if (sepn and 2) ne 0 then dprint,phelp=debug,sep2_hkp,sep2_svy,sep2_arc ,sep2_memdump,lastmem2
           dprint,/phelp,source_filenames
           return
        endif
        if keyword_set( record_filenames) then append_array,source_filenames,record_filenames       
        dprint,dlevel=2,'SEP handler: ' , keyword_set(clear) ? 'Clearing Data' : 'Finalizing'
        prefix = 'mvn_'
        if keyword_set(lowres) then begin
          prefix='mvn_5min_'
          if lowres eq 2 then prefix='mvn_01hr_'
        endif
        if ~keyword_set(hkp_tags) then hkp_tags = 'RATE_CNTR VCMD_CNTR AMON_* DACS'
        if ~keyword_set(svy_tags) then svy_tags = 'DATA ATT COUNTS_TOTAL DURATION'
        if ~keyword_set(noise_tags) then noise_tags = 'BASELINE SIGMA DATA TOT'
        if (sepn and 1) ne 0 then mav_gse_structure_append, clear=clear,  sep1_hkp,   tname=prefix+'sep1_hkp' , tags=hkp_tags 
        if (sepn and 2) ne 0 then mav_gse_structure_append, clear=clear,  sep2_hkp,   tname=prefix+'sep2_hkp' , tags=hkp_tags 
        if (sepn and 1) ne 0 then mav_gse_structure_append, clear=clear,  sep1_svy,   tname=prefix+'sep1_svy' , tags= svy_tags 
        if (sepn and 2) ne 0 then mav_gse_structure_append, clear=clear,  sep2_svy,   tname=prefix+'sep2_svy' , tags= svy_tags ; 'DATA ATT MAPID COUNTS_TOTAL'
        if (sepn and 1) ne 0 then mav_gse_structure_append, clear=clear,  sep1_arc,   tname=prefix+'sep1_arc' , tags= svy_tags ; 'DATA ATT MAPID COUNTS_TOTAL'
        if (sepn and 2) ne 0 then mav_gse_structure_append, clear=clear,  sep2_arc,   tname=prefix+'sep2_arc' , tags= svy_tags ; 'DATA ATT MAPID COUNTS_TOTAL'
        if (sepn and 1) ne 0 then mav_gse_structure_append, clear=clear,  sep1_noise, tname=prefix+'sep1_noise', tags= noise_tags ;'BASELINE SIGMA DATA TOT'
        if (sepn and 2) ne 0 then mav_gse_structure_append, clear=clear,  sep2_noise, tname=prefix+'sep2_noise', tags= noise_tags ;'BASELINE SIGMA DATA TOT'
        if (sepn and 1) ne 0 then mav_gse_structure_append, clear=clear,  sep1_memdump , tname = prefix+'sep1_mem'    ; don't create any tplot variables for this
        if (sepn and 2) ne 0 then mav_gse_structure_append, clear=clear,  sep2_memdump , tname = prefix+'sep2_mem' 
        if (magnum and 1) ne 0 then   mav_gse_structure_append, clear=clear,  mag1_hkp_f0   ,    tname= 'mvn_mag1_hkp' , tags = mag_tags
        if (magnum and 2) ne 0 then   mav_gse_structure_append, clear=clear,  mag2_hkp_f0   ,    tname= 'mvn_mag2_hkp' , tags = mag_tags
        if keyword_set(clear) then begin
          undefine,source_filenames
        endif
        sep_all_ptrs = 0
        append_array,sep_all_ptrs,sep1_hkp
        append_array,sep_all_ptrs,sep2_hkp
        append_array,sep_all_ptrs,sep1_svy
        append_array,sep_all_ptrs,sep2_svy
        append_array,sep_all_ptrs,sep1_arc
        append_array,sep_all_ptrs,sep2_arc
        append_array,sep_all_ptrs,sep1_noise
        append_array,sep_all_ptrs,sep2_noise
        append_array,sep_all_ptrs,sep1_memdump   ; ok to produce error message
        append_array,sep_all_ptrs,sep2_memdump
        append_array,sep_all_ptrs,mag1_hkp_f0
        append_array,sep_all_ptrs,mag2_hkp_f0
        
;        if not keyword_set(clear) then begin
;           if (sepn and 1) ne 0 then if keyword_set(sep1_svy)   then mvn_sep_create_subarrays,*sep1_svy.x,tname=prefix+'sep1' ;,mapname=mapname
;           if (sepn and 2) ne 0 then if keyword_set(sep2_svy)   then mvn_sep_create_subarrays,*sep2_svy.x,tname=prefix+'sep2' ;,mapname=mapname
        if keyword_set(finish) && (keyword_set(sep1_svy) || keyword_set(sep2_svy)) then begin
          data_str1='mvn_sep1_svy'
          data_str2='mvn_sep2_svy'
          if keyword_set(arc) then begin
            data_str1='mvn_sep1_arc'
            data_str2='mvn_sep2_arc'
          endif
          if (sepn and 1) ne 0 then mvn_sep_create_subarrays,data_str1,units_name=units_name,lowres=lowres,arc=arc
          if (sepn and 2) ne 0 then mvn_sep_create_subarrays,data_str2,units_name=units_name,lowres=lowres,arc=arc
          if (sepn and 1) ne 0 && keyword_set(sep1_noise) then mvn_sep_create_noise_arrays,*sep1_noise.x,tname=prefix+'sep1'
          if (sepn and 2) ne 0 && keyword_set(sep2_noise) then mvn_sep_create_noise_arrays,*sep2_noise.x,tname=prefix+'sep2'
          mvn_sep_pfdpu_tplot_options,lowres=lowres
        endif
        return
    endif
    if not keyword_set(manage) then return
    prefix = 'mvn_'
    Case ccsds.apid of
      '2b'x: begin
        ;  printdat,gap
          mav_gse_structure_append  ,sep1_hkp, realtime=realtime, tname=prefix+'sep1_hkp',(sep1_last_hkp=mvn_sep_hkp_pfdpu_decom(ccsds,last_hkp=sep1_last_hkp,gap=gap)),insert_gap=gap  ; to revert to gap remove 0
        ;  printdat,gap
          end
      '2c'x: begin
          mav_gse_structure_append  ,sep2_hkp, realtime=realtime, tname=prefix+'sep2_hkp',(sep2_last_hkp=mvn_sep_hkp_pfdpu_decom(ccsds,last_hkp=sep2_last_hkp,gap=gap)),insert_gap=gap
          end
      '70'x: begin
          last_seqcntr = keyword_set(sep1_spec) ? sep1_spec[0].seq_cntr : 0u
          mav_gse_structure_append  ,sep1_svy, realtime=realtime, tname=prefix+'sep1_svy',(sep1_spec=mvn_apid_sep_science_decom(ccsds)) ,insert_gap = (sep1_spec[0].seq_cntr-last_seqcntr) ne 1
 ;         if (sep1_spec[0].seq_cntr-last_seqcntr) ne 1 then dprint,'gap',dlevel=3
;          if abs(ccsds.time-systime(1)) lt 90 then mvn_sep_plot_spectra,total(sep1_spec.data,2),avg_data=sep1_avg,window=1,color=2  ;          mav_sep_plot_spectra,spec.data
          end
      '71'x: begin
          last_seqcntr = keyword_set(sep2_spec) ? sep2_spec[0].seq_cntr : 0u
          mav_gse_structure_append  ,sep2_svy, realtime=realtime, tname=prefix+'sep2_svy',(sep2_spec=mvn_apid_sep_science_decom(ccsds)) ,insert_gap = (sep2_spec[0].seq_cntr-last_seqcntr) ne 1
;          if abs(ccsds.time-systime(1)) lt 90 then mvn_sep_plot_spectra,total(sep2_spec.data,2),avg_data=sep2_avg,window=2,color=6  ;          mav_sep_plot_spectra,spec.data
          end
      '72'x: begin
          last_seqcntr = keyword_set(sep1arc_spec) ? sep1arc_spec[0].seq_cntr : 0u
          mav_gse_structure_append  ,sep1_arc, realtime=realtime, tname=prefix+'sep1_arc',(sep1arc_spec=mvn_apid_sep_science_decom(ccsds)) ,insert_gap = (sep1arc_spec[0].seq_cntr-last_seqcntr) ne 1
          end
      '73'x: begin
          last_seqcntr = keyword_set(sep2arc_spec) ? sep2arc_spec[0].seq_cntr : 0u
          mav_gse_structure_append  ,sep2_arc, realtime=realtime, tname=prefix+'sep2_arc',(sep2arc_spec=mvn_apid_sep_science_decom(ccsds)),insert_gap = (sep2arc_spec[0].seq_cntr-last_seqcntr) ne 1
          end
      '78'x: mav_gse_structure_append  ,sep1_noise, realtime=realtime, tname=prefix+'sep1_noise',mvn_apid_sep_noise_decom(ccsds)
      '79'x: mav_gse_structure_append  ,sep2_noise, realtime=realtime, tname=prefix+'sep2_noise',mvn_apid_sep_noise_decom(ccsds)
      '7c'x: mav_gse_structure_append  ,sep1_memdump, realtime=realtime, tname=prefix+'sep1_memdump',mvn_apid_sep_memdump_decom(ccsds,lastmem=lastmem1)
      '7d'x: mav_gse_structure_append  ,sep2_memdump, realtime=realtime, tname=prefix+'sep2_memdump',mvn_apid_sep_memdump_decom(ccsds,lastmem=lastmem2)
 ;     '7c'x: mav_gse_structure_append  ,sep1_memdump, realtime=realtime, tname=prefix+'sep1_memdump',mvn_apid_sep_memdump_decom(ccsds,lastmem=lastmem1)
 ;     '7d'x: mav_gse_structure_append  ,sep2_memdump, realtime=realtime, tname=prefix+'sep2_memdump',mvn_apid_sep_memdump_decom(ccsds,lastmem=lastmem2)
      '26'x: mav_gse_structure_append  ,mag1_hkp_f0, realtime=realtime, tname=prefix+'mag1_hkp',mvn_mag_hkp_decom_f0(ccsds)
      '27'x: mav_gse_structure_append  ,mag2_hkp_f0, realtime=realtime, tname=prefix+'mag2_hkp',mvn_mag_hkp_decom_f0(ccsds)
       else: return    ; Do nothing if not a SEP packet
    endcase 
    decom = 1
end



pro mvn_sep_verify_mem
;mem = 
mvn_sep_extract_data,'mvn_sep1_mem',data
printdat,data
lut = mvn_sep_create_lut(mapnum=9)
printdat,where( lut ne data.map) 
mvn_sep_extract_data,'mvn_sep2_mem',data
lut = mvn_sep_create_lut(mapnum=9)
printdat,where( lut ne data.map) 


end

