;+
;Function:  mav_mag_handler
;Purpose: 
; Author: Davin Larson
; $LastChangedBy: davin-mac $
; $LastChangedDate: 2015-11-06 14:02:07 -0800 (Fri, 06 Nov 2015) $
; $LastChangedRevision: 19296 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/mag/mvn_mag_handler.pro $
; 
;-

function mvn_mag_analog_conversion,x, coeff=coeff
    temp = 0.d
    for i = 0,n_elements(coeff)-1 do  temp = temp * x + coeff[i]
    return,temp
end




function mvn_mag_hkp_decom,ccsds
data = ccsds.data
data2 = uint(data,0,n_elements(data)/2)  & byteorder,data2,/swap_if_little_endian

mag_temp_coeff = [2.81E-39,  8.23E-34,  -4.58E-30, -6.02E-25, 3.16E-21,  1.81E-16,  -2.94E-13, -1.45E-08, 1.30E-03,  8.87E+00]


hkp = { time: ccsds.time, $
MET: ccsds.met, $
message_id: data2[0], $
sync_1: data2[1], $
sync_2: data2[2], $
cmd_ctr: data2[3], $
frm_ctr: data2[4], $
f0:  ulong(data2[5]), $
time_f1: data2[6], $
time_f2: data2[7], $
time_f3: data2[8], $
F_MET: data2[6] * 2d^16 + data2[7] + data2[8]/2d^16, $
status_flag: data2[9], $
xtest: fix(data2[10]) * 0.016115, $
ytest: fix(data2[11]) * 0.016115, $
ztest: fix(data2[12]) * 0.016115, $
RTEST: fix(data2[13]) * 0.016115, $
VCALMON: data2[14] * 0.000392, $
P82VMON: data2[15] * 0.000392, $
M82VMON: data2[16] * 0.000392, $
SNSRTEMPRAW: fix(data2[17])* 2.5/ 2L^15, $
PCBTEMPRAW:  fix(data2[18])* 2.5/ 2L^15, $
SNSR_TEMP:mvn_mag_analog_conversion( fix(data2[17])* 1.,coeff=mag_temp_coeff), $
PCB_TEMP: mvn_mag_analog_conversion( fix(data2[18])* 1.,coeff=mag_temp_coeff), $
P13VMON: fix(data2[19]) * 0.000531, $
M13VMON: fix(data2[20]) * 0.000531, $
P114VREF: fix(data2[21])* 0.000392, $
P25VDIG: fix(data2[22]) * 0.000256, $
P35VDIG: fix(data2[23]) * 0.000256, $
P5VADC: fix(data2[24]) * 0.000256, $
M5VADC: fix(data2[25]) * 0.000256, $
DIG_HK_00: data2[26], $
DIG_HK_01: data2[27], $
DIG_HK_02: data2[28], $
DIG_HK_03: data2[29], $
DIG_HK_04: data2[30], $
DIG_HK_05: data2[31], $
DIG_HK_06: data2[32], $
DIG_HK_07: data2[33], $
BSCI: fix(data2[[34,35,36]]), $
;BSCI_X0: data2[34], $
;BSCI_Y0: data2[35], $
;BSCI_Z0: data2[36], $
CHECKSUM: data2[37], $
OPT: data2[38], $
RSTLMT: byte(ishft(data2[39],-8)), $
RSTSEC: byte(data2[40]), $
OFF0: fix(data2[[40,41,42]]), $
;XOFF0: data2[40], $
;YOFF0: data2[41], $
;ZOFF0: data2[42], $
OFF1: fix(data2[[43,44,45]]), $
;XOFF1: data2[43], $
;YOFF1: data2[44], $
;ZOFF1: data2[45], $
OFF3: fix(data2[[46,47,48]]), $
;XOFF3: data2[46], $
;YOFF3: data2[47], $
;ZOFF3: data2[48], $
valid:1}
return,hkp
end

;+
;FUNCTION:  mvn_mag_svy_decom
;PURPOSE: Decomutates a ccsds structure and returns a the RAW decomutated data.  (either 32 or 64 vectors depending upon compression)
;Known Bugs:
;   When the averaging period changes there can be a timing error for that packet (or a neighbor packet ?) Only occurs rarely
;   When the scale changes there can be a scaling error in that packet.  Only occurs rarely
;-
function mvn_mag_svy_decom,ccsds
;printdat,ccsds,/hex
data = ccsds.data                                                                     ; data in bytes
data2 = uint(data,0,n_elements(data)/2)  & byteorder,data2,/swap_if_little_endian     ; data in words
subsec = data2[0]  ; (data[0]*256 + data[1])/(2.d^16)       ;  this needs verification
ccsds_time = ccsds.time + subsec/ (2d^16)
ccsds_MET  = ccsds.MET  + subsec/ (2d^16)
msg_ID= data2[1]
sync1 = data2[2]
sync2 = data2[3]
decomid = data[8]
avgper = ishft(decomid,-3) and 7
cmd_cntr = data[9]
frm_cntr = data2[5]
time_f0 = data2[6]
time_f1 = data2[7]
time_f2 = data2[8]
time_f3 = data2[9]
mag_MET = time_f1 * 2L^16 + time_f2 + time_f3/2d^16 
mag_time =  mvn_spc_met_to_unixtime(mag_MET )
status_flags = data2[10]
scale_code = status_flags and 3
scale = ([256.*2,2048.,8192.,65536.])[scale_code]
;scale = ([256.*4,2048.*2,8192.,65536.])[scale_code]
scale = scale / 2d^15
;scale = 1.
;dprint,dlevel=2,'scale=',scale
vec0 =  fix(data2[11:13])
;time = ccsds_time
time = mag_time
met = mag_met
if (decomid and 3) eq 2 then begin
  dprint,dlevel=3,time_string(ccsds.time),ccsds.apid,' Mag Sci 16 bit ',decomid,format='(a,z,a,z)'
endif
delt= (2 ^ avgper) / 32d
tshift = (2*(2 ^ avgper)-1)
time = mag_time - tshift + delt/2 - 1/64.
met  = mag_met  - tshift + delt/2 - 1/64.
if (decomid and 3) eq 3 then begin  ; compressed packet
  ns = 64    ; number of samples
  vecs =  data[28:28+192-1]   ; bytes  (not yet signed)
  vecs =  reform(vecs,3,ns)
  dvecs = (vecs+128b)-128  ;  make signed values (integers)
  vecs = fix(vecs)
  vecs[*,0] = vec0
  for i=1,ns-1 do begin   ;        differences
     vecs[*,i] = vecs[*,i-1] + dvecs[*,i]
  endfor
;  time= time - ns * delt + delt/2
endif else begin                  ; Not compressed packet
  ns=32
  vecs =  fix( data[28:28+192-1] , 0 , 192/2)  &  byteorder,vecs,/swap_if_little_endian
  vecs = reform(vecs,3,ns) 
;  time = time - ns * delt + delt/2 -   ns*delt  ; kludge
endelse

chksum = (data[220]*256 + data[221])
dat = { $ 
 time: time ,  $
; subsec:subsec,  $
 met: met, $
 seq_cntr:  ccsds.seq_cntr, $
 decomid_flag: decomid, $
; cmd_cntr:cmd_cntr, $
 frm_cntr:frm_cntr, $
 f0:time_f0, $
 f_MET: mag_MET, $
 ccsds_MET: ccsds_MET, $
; time_f1:time_f1, $
; time_f2:time_f2, $
; time_f3:time_f3, $
; dtime_frm_f0: -frm_cntr + time_f0, $
; dtime_frm_f2: -frm_cntr + time_f2, $ 
; dtime_f0_f2: -time_f0 + time_f2, $ 
 DTIME_mag:  ccsds_time - mag_time, $
 AVGPER: avgper, $
 status_flag: status_flags, $
 scode: scale_code, $
 delt: delt, $
 vec0: vec0, $
; Bvec:[0.,0.,0.] $
 vecs : scale * vecs  $
 }
return,dat
end






pro  mvn_mag_apid_struct_append,mag_misc,mag_dat,mdat,tname=tname,realtime=realtime
          vecs = mdat.vecs
          nd = size(/dimen,vecs)
          dat = replicate({time:0d,Braw:[0.,0.,0.]},nd[1])
          dat.braw = vecs
          bavg = average(vecs,2)
          dat.time = mdat.time + dindgen(nd[1]) * mdat.delt
          misc = {time:mdat.time,met:mdat.met,f0:ulong(mdat.f0),f_met:mdat.f_met,ccsds_met:mdat.ccsds_met, avgper:mdat.avgper, $
              decomid_flag:mdat.decomid_flag,scode:mdat.scode,status_flag:mdat.status_flag,bavg:bavg}
          mav_gse_structure_append  ,mag_dat , realtime=realtime, tname=tname,dat
          mav_gse_structure_append  ,mag_misc, realtime=realtime, tname=tname,misc
end




pro mvn_mag_extract_data,dataname,data  ;,trange=trange,tnames=tnames,tags=tags,num=num
    common mav_apid_mag_handler_com,manage,realtime,mag1_hkp,mag2_hkp,mag1_svy,mag2_svy,mag1_svy_misc,mag2_svy_misc,mag1_arc,mag2_arc,mag1_arc_misc,mag2_arc_misc

case dataname of
'mag1_svy_misc': data=*(mag1_svy_misc.x)
'mag1_hkp': data=*(mag1_hkp.x)
'mag2_svy_misc': data=*(mag2_svy_misc.x)
'mag2_hkp': data=*(mag2_hkp.x)
else:            undefine,data
endcase

end




pro mvn_mag_var_save,filename,pathname=pathname,trange=trange,prereq_info=prereq_info
common mav_apid_mag_handler_com,manage,realtime,mag1_hkp,mag2_hkp,mag1_svy,mag2_svy,mag1_svy_misc,mag2_svy_misc,mag1_arc,mag2_arc,mag1_arc_misc,mag2_arc_misc

if not keyword_set(filename) then begin
  if ~keyword_set(mag1_svy) || ~keyword_set(*mag1_svy.x)  then begin
    dprint,'Improper data.  Returning'
    return
  endif
  if not keyword_set(trange) then trange = minmax((*(mag1_svy.x)).time)
  res = 86400.d
  days =  round( time_double(trange )/res)
  ndays = days[1]-days[0] > 1
  tr = days * res
  if not keyword_set(pathname) then pathname =  'maven/pfp/mag/l1/raw/sav/YYYY/MM/mvn_mag_l1_raw_$NDAY_YYYYMMDD.sav' 
  pn = str_sub(pathname, '$NDAY', strtrim(ndays,2)+'day')
  filename = mvn_pfp_file_retrieve(pn,/daily,trange=tr[0],source=source,verbose=verbose,/create_dir)
endif

spice_kernels = spice_test('*')
dependents = file_checksum(/add_mtime,spice_kernels)

if keyword_set(mag1_hkp) then m1_hkp = *mag1_hkp.x
if keyword_set(mag1_svy) then m1_svy = *mag1_svy.x
if keyword_set(mag1_arc) then m1_arc = *mag1_arc.x
if keyword_set(mag2_hkp) then m2_hkp = *mag2_hkp.x
if keyword_set(mag2_svy) then m2_svy = *mag2_svy.x
if keyword_set(mag2_arc) then m2_arc = *mag2_arc.x

if keyword_set(mag1_svy_misc) then m1_svy_misc = *mag1_svy_misc.x
if keyword_set(mag1_arc_misc) then m1_arc_misc = *mag1_arc_misc.x
if keyword_set(mag2_svy_misc) then m2_svy_misc = *mag2_svy_misc.x
if keyword_set(mag2_arc_misc) then m2_arc_misc = *mag2_arc_misc.x
;file_mkdir2,file_dirname(filename)  
save,filename=filename,verbose=verbose,dependents,m1_hkp,m1_svy,m1_svy_misc,m1_arc,m1_arc_misc,m2_hkp,m2_svy,m2_arc,m2_svy_misc,m2_arc_misc,description=description
end






pro mvn_mag_handler,ccsds,decom=decom,reset=reset,debug=debug,set_realtime=set_realtime,set_manage=set_manage,clear=clear,$
       offset1=offset1,hkp_tags=hkp_tags,svy_tags=svy_tags,arc_tags=arc_tags,magnum=magnum,finish=finish,  $
       mag1_svy=m1_svy

    common mav_apid_mag_handler_com,manage,realtime,mag1_hkp,mag2_hkp,mag1_svy,mag2_svy,mag1_svy_misc,mag2_svy_misc,mag1_arc,mag2_arc,mag1_arc_misc,mag2_arc_misc
    
    if n_elements(magnum) eq 0 then magnum=3
    if not keyword_set(ccsds) then begin
        if n_elements(reset) ne 0 then begin
           manage = reset
           clear = keyword_set(reset)
        endif
        if n_elements(set_realtime) ne 0 then realtime=set_realtime
        if n_elements(set_manage) ne 0 then manage=set_manage
        if arg_present(m1_svy) then m1_svy=*(mag1_svy.x)
        if arg_present(m2_svy) then m2_svy=*(mag2_svy.x)
        if arg_present(m1_hkp) then m1_hkp=*(mag1_hkp.x)
        if arg_present(m2_hkp) then m2_hkp=*(mag2_hkp.x)
        if keyword_set(debug) then begin
           dprint,phelp=debug,manage,realtime,mag1_svy,mag1_hkp,mag1_svy_misc
           return
        endif
        dprint,dlevel=3,verbose=verbose,'MAG handler: ', keyword_set(clear) ? 'Clearing' : 'Finalizing'
        if keyword_set(finish) then begin
 ;         if ~keyword_set(hkp_tags) then hkp_tags='None'
          if ~keyword_set(svy_tags) then svy_tags='BAVG'
;          if ~keyword_set(arc_tags) then arc_tags='BRAW'
        endif 
        if (magnum and 1) ne 0 then   mav_gse_structure_append, clear=clear,  mag1_hkp   ,    tname= 'mvn_mag1_hkp' , tags = hkp_tags
        if (magnum and 2) ne 0 then   mav_gse_structure_append, clear=clear,  mag2_hkp   ,    tname= 'mvn_mag2_hkp' , tags = hkp_tags
        if (magnum and 1) ne 0 then   mav_gse_structure_append, clear=clear,  mag1_svy,        tname='mvn_mag1_svy' , tags = svy_tags
        if (magnum and 1) ne 0 then   mav_gse_structure_append, clear=clear,  mag1_svy_misc,   tname='mvn_mag1_svy' , tags = svy_tags
        if (magnum and 2) ne 0 then   mav_gse_structure_append, clear=clear,  mag2_svy,        tname='mvn_mag2_svy' , tags = svy_tags
        if (magnum and 2) ne 0 then   mav_gse_structure_append, clear=clear,  mag2_svy_misc,   tname='mvn_mag2_svy' , tags = svy_tags
        if (magnum and 1) ne 0 then   mav_gse_structure_append, clear=clear,  mag1_arc,        tname='mvn_mag1_arc' , tags = arc_tags
        if (magnum and 1) ne 0 then   mav_gse_structure_append, clear=clear,  mag1_arc_misc,   tname='mvn_mag1_arc' , tags = arc_tags
        if (magnum and 2) ne 0 then   mav_gse_structure_append, clear=clear,  mag2_arc,        tname='mvn_mag2_arc' , tags = arc_tags
        if (magnum and 2) ne 0 then   mav_gse_structure_append, clear=clear,  mag2_arc_misc,   tname='mvn_mag2_arc' , tags = arc_tags
        if keyword_set(clear) then return
        if keyword_set(finish) then begin
           dprint,dlevel=3,verbose=verbose,'Finish mag stuff here'
       ;   do other stuff here        
        endif
        if keyword_set(offset1) then begin   ;  must be in highest gain setting
           if n_elements(offset1) ne 3 then offset1 =[-0.47123703, 1.3987961, 1.3944077]                      ; oldvalue = -[29, 17, -65] * 256.*2 / 2d^15  
           if keyword_set(mag1_svy) && ptr_valid(mag1_svy.x) && keyword_set( *(mag1_svy.x)) then begin
             p = mag1_svy.x
             store_data,'mvn_mag1_svy_Bcor',(*p).time, transpose((*P).braw + (offset1 # replicate(1,n_elements((*p).time) ) )) ,dlim={spice_frame:'MAVEN_MAG1'}
           endif
           if keyword_set(mag1_arc) && ptr_valid(mag1_arc.x) && keyword_set( *(mag1_arc.x)) then begin
             p = mag1_arc.x
             store_data,'mvn_mag1_arc_Bcor',(*p).time, transpose((*P).braw + (offset1 # replicate(1,n_elements((*p).time) ) )) ,dlim={spice_frame:'MAVEN_MAG1'}
           endif             
        endif
        return
    endif
    if not keyword_set(manage) then return
    dprint,dlevel=3,'Mag handler',ccsds.apid    ;  Append new packets here.
    Case ccsds.apid of
      '26'x: mav_gse_structure_append  ,mag1_hkp, realtime=realtime, tname='mag1_hkp',mvn_mag_hkp_decom(ccsds)
      '27'x: mav_gse_structure_append  ,mag2_hkp, realtime=realtime, tname='mag2_hkp',mvn_mag_hkp_decom(ccsds)
      '40'x: mvn_mag_apid_struct_append,mag1_svy_misc,mag1_svy,mvn_mag_svy_decom(ccsds),tname='mag1_svy',realtime=realtime
      '41'x: mvn_mag_apid_struct_append,mag2_svy_misc,mag2_svy,mvn_mag_svy_decom(ccsds),tname='mag2_svy',realtime=realtime
      '42'x: mvn_mag_apid_struct_append,mag1_arc_misc,mag1_arc,mvn_mag_svy_decom(ccsds),tname='mag1_arc',realtime=realtime
      '43'x: mvn_mag_apid_struct_append,mag2_arc_misc,mag2_arc,mvn_mag_svy_decom(ccsds),tname='mag2_arc',realtime=realtime
       else: return    ; Do nothing if not a MAG packet
    endcase 
    decom = 1
end
