;+
;Function:  mav_apid_mag_handler
;Purpose: 
; Author: Davin Larson
; $LastChangedBy: davin-mac $
; $LastChangedDate: 2013-03-07 12:55:04 -0800 (Thu, 07 Mar 2013) $
; $LastChangedRevision: 11745 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/mag/mav_apid_mag_handler.pro $
; 
;-


function mav_mag_hkp_decom,ccsds
data = ccsds.data
data2 = uint(data,0,n_elements(data)/2)  & byteorder,data2,/swap_if_little_endian

hkp = { time: ccsds.time, $
message_id: data2[0], $
sync_1: data2[1], $
sync_2: data2[2], $
cmd_ctr: data2[3], $
frm_ctr: data2[4], $
time_f0: data2[5], $
time_mag: data2[6] * 2d^16 + data2[7] + data2[8]/2d^16, $
status_flag: data2[9], $
xtest: data2[10] * 0.016115, $
ytest: data2[11] * 0.016115, $
ztest: data2[12] * 0.016115, $
RTEST: data2[13] * 0.016115, $
VCALMON: data2[14] * 0.000392, $
P82VMON: data2[15] * 0.000392, $
M82VMON: data2[16] * 0.000392, $
SNSRTEMP: data2[17], $
PCBTEMP: data2[18], $
P13VMON: data2[19] * 0.000531, $
M13VMON: data2[20] * 0.000531, $
P114VREF: data2[21]* 0.000392, $
P25VDIG: data2[22] * 0.000256, $
P35VDIG: data2[23] * 0.000256, $
P5VADC: data2[24] * 0.000256, $
M5VADC: data2[25] * 0.000256, $
DIG_HK_00: data2[26], $
DIG_HK_01: data2[27], $
DIG_HK_02: data2[28], $
DIG_HK_03: data2[29], $
DIG_HK_04: data2[30], $
DIG_HK_05: data2[31], $
DIG_HK_06: data2[32], $
DIG_HK_07: data2[33], $
BSCI_X0: data2[34], $
BSCI_Y0: data2[35], $
BSCI_Z0: data2[36], $
CHECKSUM: data2[37], $
OPT: data2[38], $
RSTLMT: byte(ishft(data2[39],-8)), $
RSTSEC: byte(data2[40]), $
XOFF0: data2[40], $
YOFF0: data2[41], $
ZOFF0: data2[42], $
XOFF1: data2[43], $
YOFF1: data2[44], $
ZOFF1: data2[45], $
XOFF3: data2[46], $
YOFF3: data2[47], $
ZOFF3: data2[48], $
valid:1}
return,hkp
end

function mav_mag_svy_decom,ccsds
;printdat,ccsds,/hex
data = ccsds.data                                                                     ; data in bytes
data2 = uint(data,0,n_elements(data)/2)  & byteorder,data2,/swap_if_little_endian     ; data in words
subsec = data2[0]  ; (data[0]*256 + data[1])/(2.d^16)       ;  this needs verification
ccsds_time = ccsds.time + subsec/ (2d^16)
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
;epoch_mag = 946771200 - 12L*3600  ; time_double('2000-01-02')
mag_time =  mvn_spc_met_to_unixtime( time_f1 * 2L^16 + time_f2 + time_f3/2d^16 )
status_flags = data2[10]
scale = ([256.,2048.,8192.,65536.])[(status_flags and 3)]
;scale = ([256.*4,2048.*2,8192.,65536.])[(status_flags and 3)]
scale = scale / 2d^15
;scale = 1.
;dprint,dlevel=2,'scale=',scale
vec0 =  data2[11:13]
;time = ccsds_time
time = mag_time
if (decomid and 3) eq 2 then begin
  dprint,dlevel=3,time_string(ccsds.time),ccsds.apid,' Mag Sci 16 bit ',decomid,format='(a,z,a,z)'
endif
delt= (2 ^ avgper) / 32d
tshift = (2*(2 ^ avgper)-1)
time = mag_time - tshift + delt/2 - 1/64.
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
dat = { time: time ,  $
; subsec:subsec,  $
 seq_cntr:  ccsds.seq_cntr, $
 decomid_flag: decomid, $
; cmd_cntr:cmd_cntr, $
 frm_cntr:frm_cntr, $
; time_f0:time_f0, $
; time_f1:time_f1, $
; time_f2:time_f2, $
; time_f3:time_f3, $
; dtime_frm_f0: -frm_cntr + time_f0, $
; dtime_frm_f2: -frm_cntr + time_f2, $ 
; dtime_f0_f2: -time_f0 + time_f2, $ 
 DTIME_mag:  ccsds_time - mag_time, $
; avgper: avgper, $
 status_flag: status_flags, $
 delt: delt, $
; vec0: vec0, $
; Bvec:[0.,0.,0.] $
 vecs : scale * vecs  $
 }
 ;dprint,avgper,delt,dlevel=2
;mdat = replicate(  dat, ns)
;mdat.time = ccsds.time + dindgen(ns)* delt
;mdat.bx = reform(vecs[0,*]) 
;mdat.by = reform(vecs[1,*]) 
;mdat.bz = reform(vecs[2,*]) 
;mdat.bvec = vecs
;printdat,mdat.bvec[0,*]
;dprint,dlevel=3,ccsds.time
return,dat

end



pro mav_apid_mag_handler,ccsds,decom=decom,reset=reset
    common mav_apid_mag_handler_com,manage,realtime,a,b,c,d,e
 ;   dprint,dlevel=2,'Mag handler 1'
    if n_elements(reset) ne 0 then begin
        manage = reset
        realtime=1
        return
    endif
    if not keyword_set(manage) then return
    dprint,dlevel=4,'Mag handler'
    Case ccsds.apid of
      '26'x: mav_gse_structure_append  ,dummy_ptrs, realtime=realtime, tname='mag1_hkp',mav_mag_hkp_decom(ccsds)
      '27'x: mav_gse_structure_append  ,dummy_ptrs, realtime=realtime, tname='mag2_hkp',mav_mag_hkp_decom(ccsds)
      '40'x: begin
          tname = 'mag1_svy'
          mdat = mav_mag_svy_decom(ccsds)
          tags = tag_names(mdat)
          nt = n_elements(tags)
          vecs = mdat.vecs
          nd = size(/dimen,vecs)
          mav_gse_structure_append  ,dummy_ptrs, realtime=realtime, tname=tname,mdat,tags=tags[0:nt-2]
          time = mdat.time + dindgen(nd[1]) * mdat.delt
 ;         dprint,time_string(mdat.time)
          dlim = {ynozero: 1}
          store_data,tname+'_'+'Bvec', time, transpose(mdat.vecs), /append   ,dlim=dlim         
          store_data,tname+'_'+'Bx', time, transpose(mdat.vecs[0,*]), /append   ,dlim=dlim         
          store_data,tname+'_'+'By', time, transpose(mdat.vecs[1,*]), /append   ,dlim=dlim         
          store_data,tname+'_'+'Bz', time, transpose(mdat.vecs[2,*]), /append   ,dlim=dlim         
;          mav_gse_structure_append  ,dummy_ptrs, realtime=realtime, tname='mag1_svy',mdat,tags=tags[0:nt-2]
;          dprint,dlevel=3,ccsds.apid,'  ',time_string(time[0]),average(  mdat.vecs,2)      
        end    
;      '41'x: mav_gse_structure_append  ,dummy_ptrs, realtime=realtime, tname='mag2_svy',mav_mag_svy_decom(ccsds)
      '41'x: begin
          tname = 'mag2_svy'
          mdat = mav_mag_svy_decom(ccsds)
          tags = tag_names(mdat)
          nt = n_elements(tags)
          vecs = mdat.vecs
          nd = size(/dimen,vecs)
          mav_gse_structure_append  ,dummy_ptrs, realtime=realtime, tname=tname,mdat,tags=tags[0:nt-2]
          time = mdat.time + dindgen(nd[1]) * mdat.delt
 ;         dprint,time_string(mdat.time)
          dlim = {ynozero: 1}
          store_data,tname+'_'+'Bvec', time, transpose(mdat.vecs), /append   ,dlim=dlim         
          store_data,tname+'_'+'Bx', time, transpose(mdat.vecs[0,*]), /append   ,dlim=dlim         
          store_data,tname+'_'+'By', time, transpose(mdat.vecs[1,*]), /append   ,dlim=dlim         
          store_data,tname+'_'+'Bz', time, transpose(mdat.vecs[2,*]), /append   ,dlim=dlim 
;          dprint,dlevel=3,ccsds.apid,'  ',time_string(time[0]),average(  mdat.vecs,2)      
;          mav_gse_structure_append  ,dummy_ptrs, realtime=realtime, tname='mag1_svy',mdat,tags=tags[0:nt-2]
        end    
       else: return    ; Do nothing if not a MAG packet
    endcase 
    decom = 1
end
