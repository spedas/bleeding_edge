; $LastChangedBy: davin-mac $
; $LastChangedDate: 2025-02-21 16:59:13 -0800 (Fri, 21 Feb 2025) $
; $LastChangedRevision: 33145 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SWFO/STIS/ccsds_reader__define.pro $



;+
;  PROCEDURE ccsds_reader
;  This object is a collecton of routines to process socket stream and files that have CCSDS packets
;  is only specific to SWFO in the default decom_procedure on initialization.
;  When a complete ccsds packet is read in  it will execute the routine "swfo_ccsds_spkt_handler"
;-






function ccsds_reader::header_struct,header

  nsync = self.sync_size
  if nsync ne 0 then  sync = self.sync_pattern[0:nsync-1] else sync = !null

  
  if n_elements(header) lt self.header_size then return, !null                    ; Not enough bytes in packet header
  if  (isa(sync) && (array_equal(sync,header[0:nsync-1] and self.sync_mask) eq 0)) then return,!null   ; Not a valid packet
  

  strct = { $
    time:!values.d_nan, $
    apid:0u, $
    seqn:0u, $
    psize: 0u , $
    frm_seqn:0ul ,$
    frm_seqid: 0 , $
    replay: 0b, $
    valid:0b, $
    gap:0b ,  $
 ;   sync:0b, $
    quality_bits:0UL}
  
  
  strct.apid  = (header[nsync+0] * 256U + header[nsync+1]) and 0x7FF 
  strct.seqn  = (header[nsync+2] * 256u + header[nsync+3]) and 0x3FFF
  strct.psize = header[nsync+4] * 256u + header[nsync+5] + 1   ; size of payload  (6 bytes less than size of ccsds packet)
  
  strct.frm_seqn = self.last_frm_seqn
  strct.frm_seqid = self.frm_seqid
  strct.replay   = self.replay

  if nsync eq 4 &&  header[0] eq 0x3b then begin
    strct.replay = 1
  endif


 ; if isa(sync) && header[0] eq 0x3b then begin    ; special case for SWFO
 ;   strct.apid = strct.apid or 0x8000         ; turn on highest order bit to segregate different apid
 ; endif


  return,strct

end







pro ccsds_reader::handle,buffer

  if debug(4,self.verbose) then begin
    dprint,self.name
    hexprint,buffer
    dprint
  endif
  
  if self.run_proc then begin
    swfo_ccsds_spkt_handler,buffer[self.sync_size:*],source_dict=self.source_dict         ; Process the complete packet
  endif
  
  if self.ccsds_output_lun ne 0 then BEGIN
    dprint ,dlevel=2,'Writing output',dwait=10.
    writeu,self.ccsds_output_lun,buffer[self.sync_size:*]
  endif

  headerstr = self.source_dict.headerstr
  if self.save_data then begin
    self.dyndata.append, headerstr
  endif

end





function ccsds_reader::init,sync_pattern=sync_pattern,sync_mask=sync_mask,decom_procedure = decom_procedure,mission=mission,_extra=ex
  ret=self.socket_reader::init(_extra=ex)
  if ret eq 0 then return,0

  if isa(mission,'string') && mission eq 'SWFO' then begin
    if ~isa(sync_pattern) && ~isa(sync_pattern,/null) then sync_pattern = ['1a'xb,  'cf'xb ,'fc'xb, '1d'xb ]
    decom_procedure = 'swfo_ccsds_spkt_handler'
  endif
  self.sync_size = n_elements(sync_pattern)
  self.maxsize = 4100
  self.minsize = 10
  if self.sync_size gt 4 then begin
    dprint,'Number of sync bytes must be <= 4'
    return, 0
  endif
  if self.sync_size ne 0 then begin
    self.sync_pattern = sync_pattern
    self.sync_mask = ['ff'xb,  'ff'xb ,'ff'xb, 'ff'xb ]
  endif
  if isa(sync_mask) then self.sync_mask = sync_mask
  self.header_size = self.sync_size + 6

  return,1
end





PRO ccsds_reader__define
  void = {ccsds_reader, $
    inherits socket_reader, $    ; superclass
    last_frm_seqn: 0ul,  $            ; if the parent ccsds frame exists then this will contain the last frame seq number
    frm_seqid:  0b,  $                ; indicates which VC contained the data
    replay:     0b,  $                ; byte indicates this was a replay packet
    decom_procedure: '',  $
    minsize: 0UL , $
    maxsize: 0UL , $
    ccsds_output_lun: 0  $ ; Use this to generate ccsds output
  }
END




