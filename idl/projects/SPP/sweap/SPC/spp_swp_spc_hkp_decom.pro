; $LastChangedBy: ali $
; $LastChangedDate: 2021-06-14 10:41:21 -0700 (Mon, 14 Jun 2021) $
; $LastChangedRevision: 30043 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/sweap/SPC/spp_swp_spc_hkp_decom.pro $

function spp_swp_spc_hkp_decom,ccsds,ptp_header=ptp_header,apdat=apdat
  ccsds_data = spp_swp_ccsds_data(ccsds)

  if debug(5) then begin
    dprint,dlevel=4,'SPC',ccsds.pkt_size, n_elements(ccsds_data), ccsds.apid
    hexprint,ccsds_data[0:31]
    hexprint,spp_swp_data_select(ccsds_data,80,8)
  endif

  dprint,'spc',dlevel=5

  flt=1.
  str = { $
    time:         ccsds.time, $
    MET:          ccsds.met,  $
    apid:         ccsds.apid, $
    seqn:         ccsds.seqn,  $
    seqn_delta:   ccsds.seqn_delta,  $
    seq_group:    ccsds.seq_group,  $
    pkt_size:     ccsds.pkt_size,  $
    source:       ccsds.source,  $
    source_hash:  ccsds.source_hash,  $
    compr_ratio:  ccsds.compr_ratio,  $
    cmd_ctr:      spp_swp_data_select(ccsds_data, 96 ,8  ) , $
    err_ctr:      spp_swp_data_select(ccsds_data, 104 ,8  ) , $
    lastcmd:      spp_swp_data_select(ccsds_data, 112 ,8  ) , $
    lastval:      spp_swp_data_select(ccsds_data, 120 ,16) , $
    status_flag:  spp_swp_data_select(ccsds_data, 136 ,8) , $
    adc_hvdac_in: spp_swp_data_select(ccsds_data, 144 ,12) * 5./4095*(-6.25)/3.125 , $
    adc_3p3_V:    spp_swp_data_select(ccsds_data,156 , 12) * 5./4095*3.3/3.3 , $
    adc_p12_V:    spp_swp_data_select(ccsds_data,168 , 12) * 5./4095*12/3 , $
    adc_n12_V:    spp_swp_data_select(ccsds_data,180 , 12) * 5./4095*(-12)/1.92 , $
    adc_HVOUT:    spp_swp_data_select(ccsds_data,192 , 12) * 5./4095*(-10)/5 , $
    adc_railctl:  spp_swp_data_select(ccsds_data,204 , 12) * 5./4095*5/5 , $
    adc_P5_V:     spp_swp_data_select(ccsds_data,216 , 12) * 5./4095*5/2.5 , $
    adc_N5_V:     spp_swp_data_select(ccsds_data,228 , 12) * 5./4095*(-5)/1.67 , $
    rio_LV_TEMP:  spp_swp_data_select(ccsds_data,240 , 10) * flt , $
    rio_3p3_V:    spp_swp_data_select(ccsds_data,250 , 10) * 0.00363147605083089 , $
    rio_1p5_v:    spp_swp_data_select(ccsds_data,260 , 10) * 0.00239607843137255 , $
    rio_22_v:     spp_swp_data_select(ccsds_data,270 , 10) * 0.02619320388349510 , $
    rio_p12v_v:   spp_swp_data_select(ccsds_data,280 , 10) * 0.01552071005917160 , $
    rio_p5_v:     spp_swp_data_select(ccsds_data,290 , 10) * 0.00617156862745098 , $
    rio_n12v_v:   spp_swp_data_select(ccsds_data,300 , 10) * (-0.01538476562500000) , $
    rio_n5_v:     spp_swp_data_select(ccsds_data,310 , 10) * (-0.00620886699507389) , $
    rio_3p3_i:    spp_swp_data_select(ccsds_data,320 , 10) * 0.19476285714285700 , $
    rio_1p5_i:    spp_swp_data_select(ccsds_data,330 , 10) * 1.39921700000000000 , $
    rio_p5_i:     spp_swp_data_select(ccsds_data,340 , 10) * 0.97751700000000000 , $
    rio_p12_i:    spp_swp_data_select(ccsds_data,350 , 10) * 2.51937422680412000 , $
    rio_n12_I:    spp_swp_data_select(ccsds_data,360 , 10) * 2.44379300000000000 , $
    rio_n55_v:    spp_swp_data_select(ccsds_data,370 , 10) * (-0.05872646784715750) , $
    rio_8k_v:     spp_swp_data_select(ccsds_data,380 , 10) * 8000./2.5*2.5/(2.^10) , $
    rio_8k_i:     spp_swp_data_select(ccsds_data,390 , 10) * 2.5/0.1*25/(2^10) , $
    gap:0b }
  str.gap = ccsds.gap
  return,str

end


