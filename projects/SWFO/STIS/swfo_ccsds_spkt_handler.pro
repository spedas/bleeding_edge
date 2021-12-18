;+
; Purpose: Handle buffer that should contain a single ccsds packet
; Written by Davin Larson
;
; $LastChangedBy: davin-mac $
; $LastChangedDate: 2021-12-17 09:47:01 -0800 (Fri, 17 Dec 2021) $
; $LastChangedRevision: 30471 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SWFO/STIS/swfo_ccsds_spkt_handler.pro $
;-

pro swfo_ccsds_spkt_handler,dbuffer, source_dict = source_dict , wrap_ccsds=wrap_ccsds

  ccsds = swfo_ccsds_decom(dbuffer,source_dict=source_dict,wrap_ccsds=wrap_ccsds,dlevel=2)
  if ~keyword_set(ccsds) then begin
    if debug(2) then begin
      dprint,dlevel=3,'Invalid CCSDS'
    endif
    return
  endif

;  get object handler for the given apid:
  apdat = swfo_apdat(ccsds.apid)
  
  if keyword_set( apdat.ccsds_last) then begin
    ccsds_last = apdat.ccsds_last
    dseq = (( ccsds.seqn - ccsds_last.seqn ) and '3fff'xu)
    ccsds.seqn_delta = dseq
    ccsds.time_delta = (ccsds.met - ccsds_last.met)
;    ccsds.gap = (dseq gt ccsds_last.seqn_delta)
    ccsds.gap = dseq ne 1
  endif

  ;if apdat.test then printdat,ccsds,time_string(ccsds.time)

  if  debug(5) && ccsds.seqn_delta gt 1 then begin
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
