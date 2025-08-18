; $LastChangedBy: davin-mac $
; $LastChangedDate: 2023-12-02 00:05:21 -0800 (Sat, 02 Dec 2023) $
; $LastChangedRevision: 32261 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/swx/swx_swem_events_apdat__define.pro $

function swx_swem_events_apdat::display_string, strct  
  ev_strng = strarr(n_elements(strct))
  fmt = '(Z04," ",i2," ", i4, 4(" ",Z02)," ",a  )'
  for i=0,n_elements(strct)-1 do begin
    s  =strct[i]
    ev_strng[i] =  time_string(s.time)  + "  "+ string(format=fmt,s.seqn,s.num,s.code,s.id,s.str)
  endfor
  return,ev_strng
end
 
 
function swx_swem_events_apdat::decom,ccsds  ,source_dict = source_dict  ;,header

  common swx_swem_events_apdat_com, event_str
  if n_elements(event_str) eq 0 then event_str=strtrim(spp_swp_swem_events_strings(),2)

  ccsds_data = swx_ccsds_data(ccsds)

  strct = {  $
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
    num: 0, $
    subtime: 0ul, $
    code: 0u, $
    id:  bytarr(4), $
    str:  'Unknown Event', $
    brate: !values.f_nan , $
    gap: ccsds.gap  $
  }
  fmt = '(a,": ",f1,TL1,Z04,i,i4,i,4i3,a,i)'
  
  last_c = *self.ccsds_last
  if keyword_set(last_c) then   strct.brate=float(ccsds.pkt_size)/(ccsds.time - last_c.time)

;hexprint,ccsds_data,ncol=10
  bsize = ccsds.pkt_size
  strcts = !null
  if bsize mod 10 eq 0  then begin
    for i = 1 , bsize/10-1 do begin
      b = ccsds_data[i*10:i*10+9]
      strct.subtime = ((b[0]*256uL+b[1])*256Ul+b[2])*256Ul+b[3]
      strct.code = uint(b[4]*256u+b[5])
      strct.num = i
      strct.id = b[6:9]
      strct.str = event_str[strct.code < (n_elements(event_str)-1)]
      strcts = [strcts,strct]
    endfor
  endif else dprint,dlevel=self.dlevel,'Invalid EVENT packet length: ',ccsds.pkt_size
  ;  savetomain,strcts
  if 1 then begin
    for i = 0, n_elements(strcts)-1 do begin
      s = strcts[i]
      strng = string( format='(a,": ",f1,f1,TL2,Z04,i3,": ",z08,i,4(" ",Z02)," ",a,f6.2,i)',time_string(s.time),s )  ; this is poor coding!
      if self.output_lun ne 0 then begin
        printf,self.output_lun,strng
        flush,self.output_lun
      endif
    endfor    
  endif
  if 0 && debug(self.dlevel+2) then begin
    for i = 0, n_elements(strcts)-1 do begin
      s = strcts[i]
      strng = string( format='(a,": ",f1,f1,TL2,Z04,i3,": ",z08,i,4(" ",Z02)," ",a,f6.2,i)',time_string(s.time),s )
      if s.code ne 278 then $
        dprint,dlevel=self.dlevel+2,strng
    endfor
  endif
  return,strcts
end


PRO swx_swem_events_apdat__define
void = {swx_swem_events_apdat, $
  inherits swx_gen_apdat, $    ; superclass
  filename : '', $
  fileunit : 0,   $
  flag: 0 $
;  temp1 : 0u, $
;  buffer: ptr_new()   $
  }
END
