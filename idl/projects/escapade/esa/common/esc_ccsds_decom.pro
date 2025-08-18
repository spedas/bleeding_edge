; buffer should contain bytes for a single ccsds packet, header is
; contained in first 3 words (6 bytes)
; $LastChangedBy: rlivi04 $
; $LastChangedDate: 2023-01-31 17:23:26 -0800 (Tue, 31 Jan 2023) $
; $LastChangedRevision: 31453 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/escapade/esa/common/esc_ccsds_decom.pro $


FUNCTION esc_ccsds_decom_mettime,header,spc=spc,span=span,subsec=subsec

   ;; Convert to uints
   IF size(header,/type) EQ 1 THEN BEGIN 
      n = n_elements(header)
      header2 = swap_endian(uint(header,0,6 < n/2) ,/swap_if_little_endian )
      dprint,dlevel=1,'old code!'
      return, esc_ccsds_decom_mettime(header2,subsec=subsec,spc=spc,span=span)
   ENDIF

   ;; Header assumed to be uints at this point
   n = n_elements(header)
   IF n LT 5 THEN return, !values.d_nan
   IF keyword_set(span) THEN BEGIN
      ;; SPANS
      MET = (header[3]*2UL^16 + header[4] + (header[5] and 'fffc'x)  / 2d^16) + ( (header[5] ) mod 4) * 2d^15/150000
   ENDIF ELSE IF keyword_set(spc) THEN BEGIN
      ;; SPC
      MET = (header[3]*2UL^16 + header[4] + (header[5] and 'ffff'x)  / 2d^16)
   ENDIF ELSE BEGIN
      ;; Normal 1 sec resolution
      MET = double( header[3]*2UL^16 + header[4] ) 
   ENDELSE
   return,met
END



FUNCTION esc_ccsds_decom,buffer, source_dict=source_dict, wrap_ccsds=wrap_ccsds,$
                         offset,buffer_length,remainder=remainder , error=error,verbose=verbose,dlevel=dlevel

   error = 0b
   IF NOT keyword_set(offset) THEN offset = 0
   IF NOT keyword_set(buffer_length) THEN buffer_length = n_elements(buffer)
   remainder = !null

   d_nan = !values.d_nan
   f_nan = !values.f_nan

   ccsds = { ccsds_format, $
             time:         d_nan,  $ ; unixtime
             MET:          d_nan,  $
             apid:         0u, $
             seqn:         0u, $
             seqn_delta:   0u, $
             seqn_group:   0b, $
             pkt_size:     0ul,$

             ;; An indicator of where this packet came from:
             ;; 0: unknown, apid of wrapper_packet: 0x348 - 0x34f
             source_apid:  0u, $

             ;; hashcode() of source_name
             source_hash:  0UL, $
             compr_ratio:  0. , $

             ;; Number of data samples aggregated - determined from outer wrapper header
             aggregate:  0u,   $ 
             time_delta: f_nan,$

             ;; Unixtime from ptp packet
             ptp_time:     d_nan,  $
             error:        0b, $

             ;; This could be eliminated since it is useless
             version:      0b , $

             ;; Pointer to full packet data including header
             pdata:        ptr_new(),  $
             ;;ontent_compressed:   0b, $

             ;; packet counter as received - future use
             ;;counter:      0ul,    $

             ;; Unixtime when it was processed
             ;;proc_time:    d_nan,  $
             
             ;; File name of source
             ;;source_name:  ''   ,  $

             ;; Used by wrapper packets to define the apid of the inner packet
             ;;content_id:   0u   ,  $
             
             ;;content_nsamples:     0u   ,  $
             gap :         1b  }

   IF buffer_length-offset LT 12 THEN BEGIN
      IF debug(2) THEN BEGIN
         dprint,'CCSDS Buffer length too short to include full header: ',$
                buffer_length-offset,dlevel=2,offset,dwait=20
         hexprint,buffer
      ENDIF
      error = 1b
      return, !null
   ENDIF

   ;; ??? error here  % Illegal subscript range: BUFFER.
   header = swap_endian(uint(buffer[offset+0:offset+11],0,6) ,/swap_if_little_endian ) 

   ;; Corrected - but includes 2 extra bits   

   ;;ccsds.version = byte(ishft(header[0],-11) )
   ccsds.version = 1
   
   ;;ccsds.apid = header[0] and '7FF'x
   ccsds.apid = '360'x

   if n_elements(subsec) eq 0 then subsec= ccsds.apid ge '350'x
   apid = ccsds.apid
   MET = esc_ccsds_decom_mettime(header)

   ;; The following MET computation code belongs in the apdat object handler routines
   ;; This is a temporaty cluge that may disappear
   if apid ge '3c0'x then begin
      ;; GSE data
      MET = esc_ccsds_decom_mettime(header)
   endif else if apid ge '360'x then begin
      ;; SPANS
      MET = esc_ccsds_decom_mettime(header,/span)
   endif else if apid ge '350'x then begin
      ;; SPC
      MET = esc_ccsds_decom_mettime(header,/spc)
   endif else begin
      ;; SWEM Data
      MET = esc_ccsds_decom_mettime(header)
   endelse

   ccsds.met = met
   ccsds.time = spp_spc_met_to_unixtime(ccsds.MET)

   ccsds.pkt_size = header[2] + 7

   IF buffer_length-offset LT ccsds.pkt_size THEN BEGIN
      error=2b
      remainder = buffer[offset:*]
      IF debug(dlevel,verbose) THEN BEGIN
         dprint,'Not enough bytes: pkt_size, buffer_length= ',$
                ccsds.pkt_size,buffer_length-offset,dlevel=dlevel,verbose=verbose
         ;;hexprint,buffer
         ;;pktbuffer = 0
      ENDIF
      return ,0
   ENDIF ELSE BEGIN
      IF ccsds.pkt_size LT 10 THEN BEGIN
         dprint,ccsds.apid,ccsds.seqn,' Invalid Packet size:' , ccsds.pkt_size,dlevel=3
         return,0
      ENDIF
      IF ccsds.pkt_size ne buffer_length-offset then begin
         dprint,'buffer and CCSDS size mismatch',dlevel=3
      ENDIF
      pktbuffer = buffer[offset+0:offset+ccsds.pkt_size-1]
      ccsds.pdata = ptr_new(pktbuffer,/no_copy)
   ENDELSE

   ccsds.seqn_group =  ishft(header[1] ,-14)
   ccsds.seqn       =  header[1] and '3FFF'x

   IF (ccsds.MET lt 1e5) && (ccsds.apid NE '734'x) THEN BEGIN
      ;; 0x734 is the ground SWEAP ApID (MET=0) tells us when we send command files to the MOC
      dprint,dlevel=dlevel,verbose=verbose,'Invalid MET: ',MET,' For packet type: ',ccsds.apid
      ccsds.time = d_nan
   ENDIF

   IF ccsds.MET GT  'FFFFFFF0'x THEN BEGIN
      dprint,dlevel=dlevel,verbose=verbose,'MAX MET: ',MET,' For packet type: ',ccsds.apid
      ccsds.time = d_nan
   ENDIF

   IF isa(wrap_ccsds) THEN BEGIN
      ccsds.source_apid = wrap_ccsds.apid
      ccsds.aggregate   = wrap_ccsds.content_aggregate
      ccsds.compr_ratio = wrap_ccsds.compr_ratio
   ENDIF
   
   IF isa(source_dict) THEN BEGIN
      IF source_dict.haskey('source_info') THEN ccsds.source_hash = source_dict.source_info.input_sourcehash
      IF source_dict.haskey('ptp_header') && isa(source_dict.ptp_header) THEN BEGIN
         ptp_header = source_dict.ptp_header
         IF isa(ptp_header) && ptp_header.ptp_size NE ccsds.pkt_size + 17 THEN BEGIN
            dprint,dlevel=2,format='("APID: ",Z03," ccsds PKT size: ",i5," does not match ptp size:",i5,a)',$
                   ccsds.apid,ccsds.pkt_size+17, ptp_header.ptp_size,' '+time_string(ccsds.time)
         ENDIF
         IF isa(source_dict.ptp_header) THEN ccsds.ptp_time = ptp_header.ptp_time
      ENDIF ELSE BEGIN
         source_dict.ptp_header2 ={ ptp_time:systime(1), ptp_scid: 0, ptp_source:0, $
                                    ptp_spare:0, ptp_path:0, ptp_size: 17 + ccsds.pkt_size }
      ENDELSE

   ENDIF

   return,ccsds

END















;;############### BACKUP ######################

;;FUNCTION esc_ccsds_data,ccsds
;;   IF typename(ccsds) EQ 'CCSDS_FORMAT' THEN data = *ccsds.pdata ELSE data=ccsds.data
;;   return,data
;;END



   ;;  if apid ge '360'x then begin
   ;;    MET = (header[3]*2UL^16 + header[4] + (header[5] and 'fffc'x)  / 2d^16) +   ( (header[5] ) mod 4) * 2d^15/150000              ; SPANS
   ;;  endif else if apid ge '350'x then begin
   ;;    MET = (header[3]*2UL^16 + header[4] + (header[5] and 'ffff'x)  / 2d^16)             ; SPC
   ;;  endif else begin
   ;;    MET = double( header[3]*2UL^16 + header[4] )
   ;;  endelse
