function mvn_sta_apid_0x2A_hkp_decom2,ccsds,lastpkt=lastpkt

; this function is obsolete, replaced by mvn_sta_hkp_decom.pro

;dprint,dlevel=2,'APID ',ccsds.apid,ccsds.seq_cntr,ccsds.size ,format='(a,z03," ",i,i)'
scale = replicate(1.,25)
data = FIX(ccsds.data,0,25) & byteorder,data,/swap_if_little_endian
;data = scale*data

if not keyword_set(lastpkt) then lastpkt = ccsds

i=0
str = {time:ccsds.time  ,$
       dtime:  ccsds.time - lastpkt.time ,$
       seq_cntr:  ccsds.seq_cntr   ,$
       seq_dcntr:  fix( ccsds.seq_cntr - lastpkt.seq_cntr )   ,$
CH0 : DATA[i++], $
CH1 : DATA[i++], $
CH2 : DATA[i++], $
CH3 : DATA[i++], $
CH4 : DATA[i++], $
CH5 : DATA[i++], $
CH6 : DATA[i++], $
CH7 : DATA[i++], $
CH8 : DATA[i++], $
CH9 : DATA[i++], $
CH10 : DATA[i++], $
CH11 : DATA[i++], $
CH12 : DATA[i++], $
CH13 : DATA[i++], $
CH14 : DATA[i++], $
CH15 : DATA[i++], $
CH16 : DATA[i++], $
CH17 : DATA[i++], $
CH18 : DATA[i++], $
CH19 : DATA[i++], $
CH20 : DATA[i++], $
CH21 : DATA[i++], $
CH22 : DATA[i++], $
CH23 : DATA[i++], $
;Spare: DATA[i++], $
       valid: 1 }

lastpkt=ccsds

return, str

end



function mvn_sta_apid_0xd7_fsthkp_decom2,ccsds,lastpkt=lastpkt

;dprint,dlevel=2,'APID ',ccsds.apid,ccsds.seq_cntr,ccsds.size ,format='(a,z03," ",i,i)'
;data = ccsds.data

data = mvn_pfdpu_part_decompress_data(ccsds)

data_hdr = data[0:5]

data_bdy = FIX(data[6:1029],0,512) & byteorder,data_bdy,/swap_if_little_endian

if not keyword_set(lastpkt) then lastpkt = ccsds

offset=16.d					; this is a guess based on data comparisons

str = {time:ccsds.time - offset  ,$
       dtime:  ccsds.time - lastpkt.time ,$
       seq_cntr:  ccsds.seq_cntr   ,$
       seq_dcntr:  fix( ccsds.seq_cntr - lastpkt.seq_cntr )   ,$
       mode: byte(data[2] and 127)  ,$
       mux: byte(data[3])  ,$
       test: byte(data[3] and 128)  ,$
       diag: byte(data[3] and 64)  ,$
       data : data_bdy ,$
       valid: 1 }
return, str
end



function mvn_sta_apid_xxxx_decom2,ccsds,lastpkt=lastpkt

;dprint,dlevel=2,'APID ',ccsds.apid,ccsds.seq_cntr,ccsds.size ,format='(a,z03," ",i,i)'
data = ccsds.data
if not keyword_set(lastpkt) then lastpkt = ccsds

str = {time:ccsds.time  ,$
;       dtime:  ccsds.time - lastpkt.time ,$
       seq_cntr:  ccsds.seq_cntr   ,$
;       seq_dcntr:  fix( ccsds.seq_cntr - lastpkt.seq_cntr )   ,$
       valid: 1 }
return, str
end






pro mvn_sta_apid_handler,ccsds,decom=decom,reset=reset,debug=debug
    common mvn_sta_apid_handler_com,manage,realtime,sta_hkp,sta_c0,sta_c2,sta_c4,sta_c6,sta_c8,sta_ca,$
	sta_cc,sta_cd,sta_ce,sta_cf,sta_d0,sta_d1,sta_d2,sta_d3,sta_d4,sta_d8,sta_d9,sta_da,sta_db,a,b,c,d,e
	
  if not keyword_set(ccsds) then begin
    if n_elements(reset) ne 0 then begin
        manage = reset
        sta_hkp = 0
        sta_c0=0 & sta_c2=0 & sta_c4=0 & sta_c6=0 & sta_c8=0 
	      sta_ca=0 & sta_cc=0 & sta_cd=0 & sta_ce=0 & sta_cf=0 
	      sta_d0=0 & sta_d1=0 & sta_d2=0 & sta_d3=0 & sta_d4=0 
	      sta_d8=0 & sta_d9=0 & sta_da=0 & sta_db=0 
        realtime=1
        return
    endif
    if keyword_set(debug) then begin
        dprint,phelp=2,reset,manage,realtime,sta_c0
    endif
    return
  endif
;printdat,ccsds
    if not keyword_set(manage) then return

    if ccsds.apid ne '2A'x && ((ccsds.apid and 'C0'x) ne 'C0'x) then return
    Case ccsds.apid of
;      '2A'x: mav_gse_structure_append  ,0, realtime=realtime, tname='mvn_STA_2A',(sta_hkp=mvn_sta_apid_0x2A_hkp_decom(ccsds,last=sta_hkp))
      '2A'x: mav_gse_structure_append  ,0, realtime=realtime, tname='mvn_STA_2A',mvn_sta_hkp_decom(ccsds,last=sta_hkp)
      'C0'x: mav_gse_structure_append  ,0, realtime=realtime, tname='mvn_STA_C0',mvn_sta_apid_decom(ccsds,last=sta_c0,apid='C0',pcyc= 128,len=1024)
      'C2'x: mav_gse_structure_append  ,0, realtime=realtime, tname='mvn_STA_C2',mvn_sta_apid_decom(ccsds,last=sta_c2,apid='C2',pcyc=1024,len=1024)
      'C4'x: mav_gse_structure_append  ,0, realtime=realtime, tname='mvn_STA_C4',mvn_sta_apid_decom(ccsds,last=sta_c4,apid='C4',pcyc= 256,len=1024)
      'C6'x: mav_gse_structure_append  ,0, realtime=realtime, tname='mvn_STA_C6',mvn_sta_apid_decom(ccsds,last=sta_c6,apid='C6',pcyc=1024,len=1024)
      'C8'x: mav_gse_structure_append  ,0, realtime=realtime, tname='mvn_STA_C8',mvn_sta_apid_decom(ccsds,last=sta_c8,apid='C8',pcyc= 512,len=1024)
      'CA'x: mav_gse_structure_append  ,0, realtime=realtime, tname='mvn_STA_CA',mvn_sta_apid_decom(ccsds,last=sta_ca,apid='CA',pcyc=1024,len=1024)
      'CC'x: mav_gse_structure_append  ,0, realtime=realtime, tname='mvn_STA_CC',mvn_sta_apid_decom(ccsds,last=sta_cc,apid='CC',pcyc=1024,len=1024)
      'CD'x: mav_gse_structure_append  ,0, realtime=realtime, tname='mvn_STA_CD',mvn_sta_apid_decom(ccsds,last=sta_cd,apid='CD',pcyc=1024,len=1024)
      'CE'x: mav_gse_structure_append  ,0, realtime=realtime, tname='mvn_STA_CE',mvn_sta_apid_decom(ccsds,last=sta_ce,apid='CE',pcyc=1024,len=1024)
      'CF'x: mav_gse_structure_append  ,0, realtime=realtime, tname='mvn_STA_CF',mvn_sta_apid_decom(ccsds,last=sta_cf,apid='CF',pcyc=1024,len=1024)
      'D0'x: mav_gse_structure_append  ,0, realtime=realtime, tname='mvn_STA_D0',mvn_sta_apid_decom(ccsds,last=sta_d0,apid='D0',pcyc=1024,len=1024)
      'D1'x: mav_gse_structure_append  ,0, realtime=realtime, tname='mvn_STA_D1',mvn_sta_apid_decom(ccsds,last=sta_d1,apid='D1',pcyc=1024,len=1024)
      'D2'x: mav_gse_structure_append  ,0, realtime=realtime, tname='mvn_STA_D2',mvn_sta_apid_decom(ccsds,last=sta_d2,apid='D2',pcyc=1024,len=1024)
      'D3'x: mav_gse_structure_append  ,0, realtime=realtime, tname='mvn_STA_D3',mvn_sta_apid_decom(ccsds,last=sta_d3,apid='D3',pcyc=1024,len=1024)
      'D4'x: mav_gse_structure_append  ,0, realtime=realtime, tname='mvn_STA_D4',mvn_sta_apid_decom(ccsds,last=sta_d4,apid='D4',pcyc= 128,len=1024)
      'D6'x: mav_gse_structure_append  ,0, realtime=realtime, tname='mvn_STA_D6',mvn_sta_apid_decom(ccsds,last=sta_d6,apid='D6',pcyc=1024,len=1024)
      'D7'x: mav_gse_structure_append  ,0, realtime=realtime, tname='mvn_STA_D7',mvn_sta_apid_0xd7_fsthkp_decom2(ccsds)
      'D8'x: mav_gse_structure_append  ,0, realtime=realtime, tname='mvn_STA_D8',mvn_sta_apid_decom(ccsds,last=sta_d8,apid='D8',pcyc=  12,len= 192)
      'D9'x: mav_gse_structure_append  ,0, realtime=realtime, tname='mvn_STA_D9',mvn_sta_apid_decom(ccsds,last=sta_d9,apid='D9',pcyc= 768,len= 768)
      'DA'x: mav_gse_structure_append  ,0, realtime=realtime, tname='mvn_STA_DA',mvn_sta_apid_decom(ccsds,last=sta_da,apid='DA',pcyc=1024,len=1024)
      'DB'x: mav_gse_structure_append  ,0, realtime=realtime, tname='mvn_STA_DB',mvn_sta_apid_decom(ccsds,last=sta_db,apid='DB',pcyc=1024,len=1024)
       else: return    ; Do nothing if not a STATIC packet
    endcase 
    decom = 1
end
