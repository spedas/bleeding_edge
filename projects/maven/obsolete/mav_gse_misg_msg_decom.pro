; Dummy placeholder routines
pro mav_lpw_misg_decom,pkt
     dprint,dlevel=1,'Dummy LPW decommutater'
end

pro mav_mag_misg_decom,pkt
     dprint,dlevel=1,'Dummy MAG decommutater'
end

pro mav_swea_misg_decom,pkt
     dprint,dlevel=1,'Dummy SWEA decommutater'
end

pro mav_swia_misg_decom,pkt
     dprint,dlevel=1,'Dummy SWIA decommutater'
end





; Decommutates data coming from the MISG  (and commands sent to MISG)
; splits packet to appropriate instrument decommutator


pro mav_gse_misg_msg_decom,pkt

    if pkt.mid2 ne 4 then return   ;  safety
    case pkt.mid3 of
;    '00'x: mav_misg_decom,pkt ;  error
    '01'x: mav_lpw_misg_decom,pkt   ; LPW
    '02'x: mav_mag_misg_decom,pkt   ;,'MAG'
    '03'x: mav_sep_misg_decom,pkt   ; 'SEP'     Use this routine as a model
    '04'x: mav_sta_misg_decom,pkt   ;,'STATIC'
    '05'x: mav_swea_misg_decom,pkt  ;,'SWEA'
    '06'x: mav_swia_misg_decom,pkt  ;,'SWIA'
    else:  dprint,dlevel=0,'Unknown Instrument'
    endcase

end
