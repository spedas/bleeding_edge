; $LastChangedBy: ali $
; $LastChangedDate: 2025-11-22 20:05:31 -0800 (Sat, 22 Nov 2025) $
; $LastChangedRevision: 33866 $
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
  n = dsize / 6
 ; rawdat =   swfo_data_select(ccsds_data, 20*8+indgen(64*2*3)*16, 16 ,/signed)
 
  rawdat =   swfo_data_select(ccsds_data,  20*8 +indgen(n * 6)*16, 16 ,signed=1)

  case ccsds.apid of
    1254: mdsize = 728 - 20      ; max size of data for 64 samples/sec
    1253: mdsize  = 88 - 20      ; max size of data for 8 samples/sec
    else: mdsize  = ccsds.pkt_size - 20
  endcase


  datastr = {$
    time:ccsds.time,  $
    time_delta:ccsds.time_delta, $
    met:ccsds.met,   $
    grtime: ccsds.grtime,  $
    delaytime: ccsds.delaytime, $
    apid:ccsds.apid,  $
    seqn:ccsds.seqn,$
    seqn_delta:ccsds.seqn_delta,$
    packet_size:ccsds.pkt_size,$
    vcid: ccsds.vcid, $
    vcid_seqn: ccsds.vcid_seqn, $
    file_hash: ccsds.file_hash, $
    replay:    ccsds.replay , $
    station:    ccsds.station  , $
    tod_day:      ccsds.day,  $   ;                    swfo_data_select(ccsds_data,  6*8,16),$
    tod_millisec: ccsds.millisec,  $   ;                    swfo_data_select(ccsds_data,  8*8,32),$
    tod_microsec:  ccsds.microsec,  $   ;                   swfo_data_select(ccsds_data, 12*8,16),$
    mag_data:  fltarr(6)  , $
    extra: fltarr(2)  , $
    raw_data:  bytarr(mdsize) , $
    gap:ccsds.gap }
    
    
    
    if 1 then begin
      dprint,dlevel=3,time_string(datastr.time),' ',datastr.seqn, ' ',ccsds.pkt_size
    endif
    
    if 1 then begin
      ndat = (datastr.pkt_size - 20)  < mdsize
      datastr.raw_data[0:ndat-1] = ccsds.data[20:ndat+20-1]
      return,datastr      
    endif else begin
      datastrs = replicate(datastr,n)
      datastrs.time += dindgen(n)/n
      datastrs.mag_data = float( reform( rawdat, 6, n) )
      return,datastrs
      
    endelse
    

end


pro swfo_mag_sci_apdat__define
  void = {swfo_mag_sci_apdat, $
    inherits swfo_gen_apdat $    ; superclass
  }
end

