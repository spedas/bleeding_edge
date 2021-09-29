; $LastChangedBy: ali $
; $LastChangedDate: 2021-06-14 10:41:21 -0700 (Mon, 14 Jun 2021) $
; $LastChangedRevision: 30043 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/sweap/SWEM/spp_swp_log_msg_apdat__define.pro $

function spp_swp_log_msg_apdat::decom,ccsds, source_dict=source_dict     ; ptp_header=ptp_header   ;, apdat=apdat,dlevel=dlevel

  ;printdat,ccsds
  ;time=ccsds.time
  ;printdat,ptp_header
  ;hexprint,ccsds.data

  ;  dprint,ptp_header.ptp_time - ccsds.time,'  '+time_string(ptp_header.ptp_time),dlevel=4
  if source_dict.haskey('ptp_header') then ptp_header = source_dict.ptp_header
  if keyword_set(ptp_header) then ccsds.time = ptp_header.ptp_time   ; Correct the time

  ; time = ptp_header.ptp_time   ;  log message packets have a bug - the MET is off by ten years
  ; ccsds.time= ccsds.time - 315619200 + 12*3600L ;log message packets produced by GSEOS have a bug - the MET is off by ten years -12 hours
  ; Bug corrected around June 2018

  ; printdat,ptp_header
  ;printdat,ccsds
  time = ccsds.time
  ccsds_data = spp_swp_ccsds_data(ccsds)
  ; printdat,self
  if debug(self.dlevel+4) then begin
    printdat,ccsds
    hexprint,ccsds_data
  endif
  bstr = ccsds_data[10:*]
  if 1 then begin
    w = where(bstr gt  16,/null)
    bstr = bstr[w]
  endif
  msg = string(bstr)
  tmsg = time_string(time)+  ' "'+msg+'"'
  dprint,dlevel=self.dlevel+2,tmsg
  if self.output_lun ne 0 then begin
    printf,self.output_lun,tmsg
    flush,self.output_lun
  endif
  str = { $
    time:         ccsds.time, $
    MET:          ccsds.met,  $
    apid:         ccsds.apid, $
    seqn:         ccsds.seqn,  $
    seqn_delta:   ccsds.seqn_delta,  $
    seqn_group:   ccsds.seqn_group,  $
    pkt_size:     ccsds.pkt_size,  $
    source_apid:  ccsds.source_apid,  $
    source_hash:  ccsds.source_hash,  $
    compr_ratio:  ccsds.compr_ratio,  $
    msg:          msg, $
    gap:          ccsds.gap $
  }
  ;str={time:time,seqn:ccsds.seqn,size:ccsds.pkt_size,msg:msg}
  return,str

end


PRO spp_swp_log_msg_apdat__define

  void = {spp_swp_log_msg_apdat, $
    inherits spp_gen_apdat, $    ; superclass
    filename : '', $
    fileunit : 0,   $
    flag: 0 $
  }
END

