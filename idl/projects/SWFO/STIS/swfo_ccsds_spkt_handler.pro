;+
; Purpose: Decomutate a single CCSDS data packet and uses the apid to retrieve an object that can process the specific APID
; Input:  byte array that containing a single CCSDS data packet
; 
; Written by Davin Larson
;
; $LastChangedBy: davin-mac $
; $LastChangedDate: 2024-11-01 10:08:56 -0700 (Fri, 01 Nov 2024) $
; $LastChangedRevision: 32915 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SWFO/STIS/swfo_ccsds_spkt_handler.pro $
;
;-

pro swfo_ccsds_spkt_handler,dbuffer, source_dict = source_dict , wrap_ccsds=wrap_ccsds

  ccsds = swfo_ccsds_decom(dbuffer,source_dict=source_dict,wrap_ccsds=wrap_ccsds,dlevel=2)
  if ~keyword_set(ccsds) then begin
    if debug(2) then begin
      dprint,dlevel=3,'Invalid CCSDS'
    endif
    return
  endif
  
  playback = 0
  if isa(source_dict,'dictionary')  then begin
    if source_dict.haskey('headerstr') && source_dict.headerstr.replay then begin
      playback = 0x400      
    endif
;    if source_dict.headerstr.replay then begin
;      playback = 0x400
;    endif
    source_dict.pkt_time = ccsds.time
  endif

  ;printdat,ccsds
;  get object handler for the given apid:
  apdat = swfo_apdat(ccsds.apid  or playback)
  
  if keyword_set( *apdat.ccsds_last) then begin
    ccsds_last = *apdat.ccsds_last
    dseq = (( ccsds.seqn - ccsds_last.seqn ) and '3fff'xu)
    ccsds.seqn_delta = dseq
    ccsds.time_delta = (ccsds.met - ccsds_last.met)
;    ccsds.gap = (dseq gt ccsds_last.seqn_delta)
    ccsds.gap = dseq ne 1
  endif

  ;if apdat.test then printdat,ccsds,time_string(ccsds.time)

  if  debug(3) && ccsds.seqn_delta gt 1 then begin
    dprint,dlevel=2,format='("Lost ",i5," ",a," (0x", Z03,") packets ",i5," ",a)',  ccsds.seqn_delta-1,apdat.name,apdat.apid,ccsds.seqn,time_string(ccsds.time,prec=3)
  endif

  apdat.handler, ccsds , source_dict=source_dict    ;.source_info, header
  ;    dummy = spp_rt(ccsds.time)     ; This line helps keep track of the current real time

  ;;  Save statistics - get APID_ALL and APID_GAP
  apdat.increment_counters, ccsds
  
  ;Update the overall packet counter:
  stats = swfo_apdat(0)    ; Handler object for all packets
  stats.increment_counters, ccsds, source_dict = source_dict

end
