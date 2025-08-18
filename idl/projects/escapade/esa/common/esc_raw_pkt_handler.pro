;+
; Purpose: Handle buffer that should contain a single bytes from a ccsds packet
; Written by Davin Larson
;
; $LastChangedBy: rlivi04 $
; $LastChangedDate: 2023-06-10 00:23:31 -0700 (Sat, 10 Jun 2023) $
; $LastChangedRevision: 31893 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/escapade/esa/common/esc_raw_pkt_handler.pro $
;-

PRO esc_raw_pkt_handler, raw_buf

   ;; Common Block
   COMMON esc_raw_pkt, initialized, raw_data, source_dict

   ;; Initialize if this is the first time being called
   IF ~keyword_set(initialized) THEN BEGIN
      initialized = 1
      raw_data = obj_new('esc_raw_pkt', source_dict=source_dict)
   ENDIF

   raw_data.handler, raw_buf

   
END








   ;; old code - may delete in future
   ;;GOTO, skip
   ;;
   ;; Create fake CCSDS header for the buffer
   ;;tt = systime(1)
   ;;apid = '360'x
   ;;fake_ccsds = bytarr(12)
   ;;fake_ccsds[0]  = ('00001'b * '1000'b) + (apid / 2UL^8)
   ;;fake_ccsds[1]  = apid AND 'ff'x
   ;;fake_ccsds[2]  = '00000000'b
   ;;fake_ccsds[3]  = '00000000'b
   ;;fake_ccsds[4]  = '00000000'b
   ;;fake_ccsds[5]  = '00000000'b
   ;;fake_ccsds[6]  =  ulong(tt) / 2UL^24 AND 'ff'x
   ;;fake_ccsds[7]  =  ulong(tt) / 2UL^16 AND 'ff'x
   ;;fake_ccsds[8]  =  ulong(tt) / 2UL^8  AND 'ff'x
   ;;fake_ccsds[9]  =  ulong(tt)          AND 'ff'x
   ;;fake_ccsds[10] =  ulong(tt * 2UL^8)  AND 'ff'x
   ;;fake_ccsds[11] = (ulong(tt * 2UL^14) AND '3f'x) * '40'x

   ;; Insert Fake CCSDS Header to data
   ;;dbuffer = [fake_ccsds, dbuffer]
   
   ;;ccsds = esc_ccsds_decom(dbuffer, source_dict=source_dict, wrap_ccsds=wrap_ccsds, dlevel=2)

   ;; 
   ;;IF ~keyword_set(ccsds) THEN BEGIN
   ;;   IF debug(2) THEN BEGIN
   ;;      dprint,dlevel=2,'Invalid CCSDS'
   ;;   ENDIF
   ;;   return
   ;;ENDIF

   ;;if  debug(5) then begin
   ;;   ccsds_data = esc_swp_ccsds_data(ccsds)
   ;;   n = ccsds.pkt_size
   ;;   if n gt 12 then ind = indgen(n-12)+12 else ind = !null
   ;;   dprint,dlevel=4,format='(i3,i6," APID: ", Z03,"  SeqGrp:",i1, " Seqn: ",i5,"  Size: ",i5,"   ",8(" ",Z02))',$
   ;;   npackets,offset,ccsds.apid,ccsds.seqn_group,ccsds.seqn,ccsds.pkt_size,ccsds_data[ind]
   ;;   dprint,dlevel=4,format='(i3,i6," APID: ", Z03,"  SeqGrp:",i1, " Seqn: ",i5,"  Size: ",i5,"   ")',$
   ;;          npackets,offset,ccsds.apid,ccsds.seqn_group,ccsds.seqn,ccsds.pkt_size ;,ccsds_data[ind]
   ;;endif

   ;;apdat = esc_apdat(ccsds.apid)

   ;;IF keyword_set( *apdat.ccsds_last) THEN BEGIN
   ;;   ccsds_last = *apdat.ccsds_last
   ;;   dseq = (( ccsds.seqn - ccsds_last.seqn ) AND '3fff'xu)
   ;;   ccsds.seqn_delta = dseq
   ;;   ccsds.time_delta = (ccsds.met - ccsds_last.met)
   ;;   ccsds.gap = (dseq GT ccsds_last.seqn_delta)
   ;;ENDIF

   ;;IF debug(5) && ccsds.seqn_delta GT 1 THEN BEGIN
   ;;   dprint,dlevel=5,format='("Lost ",i5," ",a," (0x", Z03,") packets ",i5," ",a)', $
   ;;          ccsds.seqn_delta-1,apdat.name,apdat.apid,ccsds.seqn,time_string(ccsds.time,prec=3)
   ;;ENDIF

   ;;apdat.handler, ccsds , source_dict=source_dict ;; .source_info, header
   ;;;; dummy = esc_rt(ccsds.time)     ; This line helps keep track of the current real time

   ;;;; Save statistics - get APID_ALL and APID_GAP
   ;;apdat.increment_counters, ccsds
   ;;stats = esc_apdat(0)
   ;;stats.handler, ccsds, source_dict = source_dict

   ;;skip:

