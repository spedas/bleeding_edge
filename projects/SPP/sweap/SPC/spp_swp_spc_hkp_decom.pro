; $LastChangedBy: davin-mac $
; $LastChangedDate: 2016-02-15 15:33:11 -0800 (Mon, 15 Feb 2016) $
; $LastChangedRevision: 20002 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu:36867/repos/spdsoft/trunk/projects/SPP/sweap/SWEM/spp_swp_swem_unwrapper.pro $




function spp_swp_spc_data_select,bytearray,startbit,nbits

  startbyte = startbit / 8
  startshft = startbit mod 8
  endbyte   = (startbit+nbits-1) / 8
  endshft  = (startbit+nbits) mod 8
  nbytes = endbyte - startbyte +1
  v=0UL
  mask = 2u ^ (8-startshft) - 1
;  dprint,startbyte,startshft,endbyte,endshft,nbytes,mask
  for i = 0,nbytes-1 do begin
    v = ishft(v,8) + bytearray[startbyte+i]
    if mask ne 0 then v = v and mask
    mask = 0
  endfor
  if endshft ne 0 then v = ishft(v,-endshft)
  case (nbits-1) / 8 + 1 of
    1:    v = byte(v)
    2:    v = uint(v)
    3:    v = ulong(v)
    4:    v = ulong(v)
    6:    v = ulong64(v)   ;   v = (swap_endian( uint(bytearray,startbyte,1) ,/swap_if_little_endian ))[0]
    8 :   v = ulong64(v)   ; (swap_endian(ulong(bytearray,startbyte,1) ,/swap_if_little_endian ))[0]
    else:  dprint,'error',nbytes
  endcase
  return,v
end


function spp_swp_spc_hkp_decom,ccsds,ptp_header=ptp_header,apdat=apdat
  ccsds_data = spp_swp_ccsds_data(ccsds)

  if debug(4) then begin
    dprint,dlevel=4,'SPC',ccsds.pkt_size, n_elements(ccsds_data), ccsds.apid
    hexprint,ccsds_data[0:31]
    hexprint,spp_swp_spc_data_select(ccsds_data,80,8)
  endif
  
  dprint,'spc',dlevel=4
  
  flt=1.
  str = {time:ccsds.time,  $
         seqn:    ccsds.seqn,$
         cmd_ctr:      spp_swp_spc_data_select(ccsds_data, 96 ,8  ) , $
         err_ctr:      spp_swp_spc_data_select(ccsds_data, 104 ,8  ) , $
         lastcmd:      spp_swp_spc_data_select(ccsds_data, 112 ,8  ) , $
         lastval:      spp_swp_spc_data_select(ccsds_data, 120 ,16) , $
         status_flag:  spp_swp_spc_data_select(ccsds_data, 136 ,8) , $
         adc_hvdac_in: spp_swp_spc_data_select(ccsds_data, 144 ,12) * 5./4095*(-6.25)/3.125 , $
         adc_3p3_V:    spp_swp_spc_data_select(ccsds_data,156 , 12) * 5./4095*3.3/3.3 , $
         adc_p12_V:    spp_swp_spc_data_select(ccsds_data,168 , 12) * 5./4095*12/3 , $
         adc_n12_V:    spp_swp_spc_data_select(ccsds_data,180 , 12) * 5./4095*(-12)/1.92 , $
         adc_HVOUT:    spp_swp_spc_data_select(ccsds_data,192 , 12) * 5./4095*(-10)/5 , $
         adc_railctl:  spp_swp_spc_data_select(ccsds_data,204 , 12) * 5./4095*5/5 , $
         adc_P5_V:     spp_swp_spc_data_select(ccsds_data,216 , 12) * 5./4095*5/2.5 , $
         adc_N5_V:     spp_swp_spc_data_select(ccsds_data,228 , 12) * 5./4095*(-5)/1.67 , $
         rio_LV_TEMP:  spp_swp_spc_data_select(ccsds_data,240 , 10) * flt , $
         rio_3p3_V:    spp_swp_spc_data_select(ccsds_data,250 , 10) * 0.00363147605083089 , $
         rio_1p5_v:    spp_swp_spc_data_select(ccsds_data,260 , 10) * 0.00239607843137255 , $
         rio_22_v:     spp_swp_spc_data_select(ccsds_data,270 , 10) * 0.02619320388349510 , $ 
         rio_p12v_v:   spp_swp_spc_data_select(ccsds_data,280 , 10) * 0.01552071005917160 , $
         rio_p5_v:     spp_swp_spc_data_select(ccsds_data,290 , 10) * 0.00617156862745098 , $
         rio_n12v_v:   spp_swp_spc_data_select(ccsds_data,300 , 10) * (-0.01538476562500000) , $
         rio_n5_v:     spp_swp_spc_data_select(ccsds_data,310 , 10) * (-0.00620886699507389) , $
         rio_3p3_i:    spp_swp_spc_data_select(ccsds_data,320 , 10) * 0.19476285714285700 , $
         rio_1p5_i:    spp_swp_spc_data_select(ccsds_data,330 , 10) * 1.39921700000000000 , $
         rio_p5_i:     spp_swp_spc_data_select(ccsds_data,340 , 10) * 0.97751700000000000 , $
         rio_p12_i:    spp_swp_spc_data_select(ccsds_data,350 , 10) * 2.51937422680412000 , $
         rio_n12_I:    spp_swp_spc_data_select(ccsds_data,360 , 10) * 2.44379300000000000 , $
         rio_n55_v:    spp_swp_spc_data_select(ccsds_data,370 , 10) * (-0.05872646784715750) , $
         rio_8k_v:     spp_swp_spc_data_select(ccsds_data,380 , 10) * 8000./2.5*2.5/(2.^10) , $  
         rio_8k_i:     spp_swp_spc_data_select(ccsds_data,390 , 10) * 2.5/0.1*25/(2^10) , $
         gap:0b }
         str.gap = ccsds.gap
  return,str

end


