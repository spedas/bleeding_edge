; $LastChangedBy: davin-mac $
; $LastChangedDate: 2025-11-05 10:13:48 -0800 (Wed, 05 Nov 2025) $
; $LastChangedRevision: 33828 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SWFO/mag/swfo_mag_sci_apdat__define.pro $


function swfo_mag_sci_apdat::decom,ccsds,source_dict=source_dict

  ccsds_data = swfo_ccsds_data(ccsds)

;  if ccsds.pkt_size eq 768/8+20 then begin
;    rawdat =   swfo_data_select(ccsds_data, 20*8+indgen(8*2*3)*16, 16 ,/signed)
;    
;  endif else begin
;    rawdat =   swfo_data_select(ccsds_data, 20*8+indgen(64*2*3)*16, 16 ,/signed)
;    
;  endelse

  dsize = (ccsds.pkt_size - 20) /2
  n = dsize / 7
 ; rawdat =   swfo_data_select(ccsds_data, 20*8+indgen(64*2*3)*16, 16 ,/signed)
 
  rawdat =   swfo_data_select(ccsds_data,  20*8 +indgen(dsize)*16, 16 ,signed=1)


  datastr = {$
    time:ccsds.time,  $
    time_delta:ccsds.time_delta, $
 ;   met:ccsds.met,   $
 ;   grtime: ccsds.grtime,  $
 ;   delaytime: ccsds.delaytime, $
    apid:ccsds.apid,  $
    seqn:ccsds.seqn,$
    seqn_delta:ccsds.seqn_delta,$
    packet_size:ccsds.pkt_size,$
    vcid: ccsds.vcid, $
    vcid_seqn: ccsds.vcid_seqn, $
    file_hash: ccsds.file_hash, $
    replay:    ccsds.replay , $
    
;    tod_day:                          swfo_data_select(ccsds_data,  6*8,16),$
;    tod_millisec:                     swfo_data_select(ccsds_data,  8*8,32),$
;    tod_microsec:                     swfo_data_select(ccsds_data, 12*8,16),$
    mag_data:  fltarr(7)  , $
    gap:ccsds.gap }
    
    if 1 then begin
      dprint,dlevel=3,time_string(datastr.time),' ',datastr.seqn, ' ',ccsds.pkt_size
    endif
    
    datastrs = replicate(datastr,n)
    datastrs.time += dindgen(n)/n
    datastrs.mag_data = float( reform( rawdat, 7, n) )
    
  return,datastrs

end


pro swfo_mag_sci_apdat__define
  void = {swfo_mag_sci_apdat, $
    inherits swfo_gen_apdat $    ; superclass
  }
end

