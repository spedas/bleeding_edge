; $LastChangedBy: davin-mac $
; $LastChangedDate: 2018-12-04 12:32:15 -0800 (Tue, 04 Dec 2018) $
; $LastChangedRevision: 26232 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/sweap/SPC/spp_swp_spc_decom.pro $

function spp_swp_spc_rss_apdat_decom, bytarray
  if n_elements(bytarray) eq 0 then bytarray = bytarr(8)
  sci_strct = { $
    ;SW_SPC_SCI_DATA: spp_swp_data_select(data,   128 -128 ,  8 ), $   ;                                 Data bytes
    WINDOW: spp_swp_data_select(data,     128 -128 ,  8 ), $   ;                                 SPC Window
    AGAIN : spp_swp_data_select(data,   136 -128 ,  2 ), $   ;                                 SPC Gain A
    ARSS : spp_swp_data_select(data,    138 -128 ,  12 ), $   ;                                  SPC RSS A
    BGAIN: spp_swp_data_select(data,    150 -128 ,  2 ), $   ;                                 SPC Gain B
    BRSS : spp_swp_data_select(data,    152 -128 ,  12 ), $   ;                                  SPC RSS B
    CGAIN : spp_swp_data_select(data,   164 -128 ,  2 ), $   ;                                 SPC Gain C
    CRSS : spp_swp_data_select(data,    166 -128 ,  12  ), $   ;                                 SPC RSS C
    DGAIN: spp_swp_data_select(data,    178 -128 ,  2  ), $   ;                                SPC Gain D
    DRSS : spp_swp_data_select(data,    180 -128 ,  12 ), $   ;                                  SPC RSS D
    valid: 1b $
  }

end


function spp_swp_spc_rss_apdat::decom,ccsds,ptp_header=ptp_header
 ; if debug(3,msg='SPC') then begin
 ;   dprint,dlevel=4,'SPC',ccsds.pkt_size, n_elements(ccsds.pdata), ccsds.apid
 ;   hexprint,ccsds.data[0:31]
 ; endif

  data = spp_swp_ccsds_data(ccsds)
  
  sci_start_byte = 128/8
  sci_size  = 8
  nsci = (ccsds.pkt_size - sci_start_byte ) / sci_size          
  dprint,dlevel=self.dlevel+1,ccsds.pkt_size,nsci

  sci_strcts = replicate(spp_swp_spc_rss_apdat_decom(), nsci)

  for i = 0 , nsci-1 do begin
    bytelocation = sci_start_byte + i * sci_size
    buffer = data[bytelocation : bytelocation-1]
    sci_strcts[i] = spp_swp_spc_rss_apdat_decom(buffer)
  endfor
  
  strct ={  $
;    inherits ccsds_format, $
    time: ccsds.time, $
    seqn: ccsds.seqn, $
    SW_SPCSUBSEC: spp_swp_data_select(data, 80,   16), $   ;                                  MET Subseconds
    SW_SPCITST: spp_swp_data_select(data,    96  ,  16), $   ;                                   SPC Int Time and Serv Time
    SW_SPC_SERVTIME: spp_swp_data_select(data,    96  ,  6 ), $   ;                                 SPC Service Time mod 64
    SW_SPC_INTTIME: spp_swp_data_select(data,     102 ,  10 ), $   ;                                  SPC Integration Time
    SPC_SCICONFIG1_bits: spp_swp_data_select(data,    112 ,  8 ), $   ;                                 SPC Config 1
    SW_SPC_spare: spp_swp_data_select(data,    112 ,  2 ), $   ;                                 Spare bits
    SW_SPC_CALFLAG: spp_swp_data_select(data,     114 ,  1 ), $   ;                                 0 if CAL=0, 1 if CAL!=0
    SPC_ELECMODE: spp_swp_data_select(data,     115 ,  1 ), $   ;                                 SPC Electron Mode Flag
    SPC_ASAT: spp_swp_data_select(data,     116 ,  1 ), $   ;                                 Det. A. Saturated during this NYS
    SPC_BSAT: spp_swp_data_select(data,     117 ,  1), $   ;                                  Det. B. Saturated during this NYS
    SPC_CSAT: spp_swp_data_select(data,     118 ,  1 ), $   ;                                 Det. C. Saturated during this NYS
    SPC_DSAT: spp_swp_data_select(data,     119 ,  1 ), $   ;                                 Det. D. Saturated during this NYS
    SPC_SCICONFIG2: spp_swp_data_select(data,    120 ,  8 ), $   ;                                 SPC Config 2
    SPC_WINWIDTH: spp_swp_data_select(data,     120 ,  4 ), $   ;                                 Window Width
    SPC_FSW_spare : spp_swp_data_select(data,   124 ,  4 ), $   ;                                 Flight Software Bits
    rss_data: sci_strcts,  $  
    gap: ccsds.gap $
  }
  return,strct

end



PRO spp_swp_spc_rss_apdat__define
  void = {spp_swp_spc_rss_apdat, $
    inherits spp_gen_apdat, $    ; superclass
    flag: 0  $
  }
END



; Extracted from CTM:
;Mnemonic  Bytes Offset  Type  #bits Length  Gap A7  A6  A5  A4  A3  A2  A1  A0  Units -RL -YL YH  RH  Seq Description
;SW_SPCSUBSEC  2 80  UW  16                                  MET Subseconds
;(SW_SPCITST)  2 96  UW  16                                  SPC Int Time and Serv Time
;SW_SPC_SERVTIME   96  UB  6                                 SPC Service Time mod 64
;SW_SPC_INTTIME    102 UB  10                                  SPC Integration Time
;(SPC_SCICONFIG1)  1 112 UB  8                                 SPC Config 1
;SW_SPC_BITS   112 UB  2                                 Spare bits
;SW_SPC_CALFLAG    114 UB  1                                 0 if CAL=0, 1 if CAL!=0
;SPC_ELECMODE    115 UB  1                                 SPC Electron Mode Flag
;SPC_ASAT    116 UB  1                                 Det. A. Saturated during this NYS
;SPC_BSAT    117 UB  1                                 Det. B. Saturated during this NYS
;SPC_CSAT    118 UB  1                                 Det. C. Saturated during this NYS
;SPC_DSAT    119 UB  1                                 Det. D. Saturated during this NYS
;(SPC_SCICONFIG2)  1 120 UB  8                                 SPC Config 2
;SPC_WINWIDTH    120 UB  4                                 Window Width
;SPC_FSWBITS   124 UB  4                                 Flight Software Bits
;(SW_SPC_SCI_DATA) 65530 128 UB  8                                 Data bytes
;WINDOW    128 UB  8                                 SPC Window
;AGAIN   136 UB  2                                 SPC Gain A
;ARSS    138 UW  12                                  SPC RSS A
;BGAIN   150 UB  2                                 SPC Gain B
;BRSS    152 UW  12                                  SPC RSS B
;CGAIN   164 UB  2                                 SPC Gain C
;CRSS    166 UW  12                                  SPC RSS C
;DGAIN   178 UB  2                                 SPC Gain D
;DRSS    180 UW  12                                  SPC RSS D