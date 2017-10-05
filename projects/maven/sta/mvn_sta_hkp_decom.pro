function mvn_sta_hkp_decom,ccsds,lastpkt=lastpkt

;dprint,dlevel=2,'APID ',ccsds.apid,ccsds.seq_cntr,ccsds.size ,format='(a,z03," ",i,i)'
scale = replicate(1.,25)
data = FIX(ccsds.data,0,73) & byteorder,data,/swap_if_little_endian
;data = scale*data

if not keyword_set(lastpkt) then lastpkt = ccsds

i=0
str = {time:ccsds.time  ,$
	met:ccsds.met  ,$  
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
;switch to single bytes for next 38, $
CH24 : ccsds.data[48], $
CH25 : ccsds.data[49], $
CH26 : ccsds.data[50], $
CH27 : ccsds.data[51], $
CH28 : ccsds.data[52], $
CH29 : ccsds.data[53], $
CH30 : ccsds.data[54], $
CH31 : ccsds.data[55], $
CH32 : ccsds.data[56], $
CH33 : ccsds.data[57], $
CH34 : ccsds.data[58], $
CH35 : ccsds.data[59], $
CH36 : ccsds.data[60], $
CH37 : ccsds.data[61], $
CH38 : ccsds.data[62], $
CH39 : ccsds.data[63], $
CH40 : ccsds.data[64], $
CH41 : ccsds.data[65], $
CH42 : ccsds.data[66], $
CH43 : ccsds.data[67], $
CH44 : ccsds.data[68], $
CH45 : ccsds.data[69], $
CH46 : ccsds.data[70], $
CH47 : ccsds.data[71], $
CH48 : ccsds.data[72], $
CH49 : ccsds.data[73], $
CH50 : ccsds.data[74], $
CH51 : ccsds.data[75], $
CH52 : ccsds.data[76], $
CH53 : ccsds.data[77], $
CH54 : ccsds.data[78], $
CH55 : ccsds.data[79], $
CH56 : ccsds.data[80], $
CH57 : ccsds.data[81], $
CH58 : ccsds.data[82], $
CH59 : ccsds.data[83], $
CH60 : ccsds.data[84], $
CH61 : ccsds.data[85], $
CH62 : DATA[43], $
CH63 : ccsds.data[88], $
CH64 : ccsds.data[89], $
CH65 : DATA[45], $
CH66 : DATA[46], $
CH67 : DATA[47], $
CH68 : DATA[48], $
CH69 : DATA[49], $
CH70 : DATA[50], $
CH71 : DATA[51], $
CH72 : DATA[52], $
CH73 : DATA[53], $
CH74 : DATA[54], $
CH75 : DATA[55], $
CH76 : DATA[56], $
CH77 : DATA[57], $
CH78 : DATA[58], $
CH79 : DATA[59], $
CH80 : DATA[60], $
CH81 : DATA[61], $
CH82 : ccsds.data[124], $
CH83 : ccsds.data[125], $
CH84 : ccsds.data[126], $
CH85 : ccsds.data[127], $
CH86 : ccsds.data[128], $
CH87 : ccsds.data[129], $
CH88 : ccsds.data[130], $
CH89 : ccsds.data[131], $
CH90 : ccsds.data[132], $
CH91 : ccsds.data[133], $
CH92 : ccsds.data[134], $
CH93 : ccsds.data[135], $
CH94 : DATA[68], $
CH95 : DATA[69], $
CH96 : DATA[70], $
CH97 : DATA[71], $
CH98 : DATA[72], $
      valid: 1 }


lastpkt=ccsds

return, str

end
