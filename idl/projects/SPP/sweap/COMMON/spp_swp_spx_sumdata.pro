
;FUNCTION:
;   sumdata
;PURPOSE:
;   Returns the summed value of an array/structure of data.
;   The input array can be an array of structures fpr PSP sweap
;INPUT:
;   dats    - Set of data structures
;OUTPUT:
;   sumdat  - Summed Structure
; KEYWORDS:
;
;NOTE:
;
;EXAMPLES:
;   using get_dat, select sum keyword
;
;CREATED BY: Orlando Romeo, 07/20/2022
;-
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
function spp_swp_spx_sumdata,dats,trange=tr
  ; Check data type
  if ~isa(dats,'struct') then return,!null
  ; Check size of data structure
  dnum = n_elements(dats)
  if dnum le 1 then return, dats
  ; Find middle structure
  midnum = dnum/2 
  ; Initialize summed data structure
  sumdat = dats[midnum]
  ; Perform sum/average if all data structures agree
  ; First need to check quality flag
  dats_qf = find_bits(dats.quality_flag)
  sums_qf = find_bits(sumdat.quality_flag)
  
  struct_check = {APID:all_true(sumdat.apid eq dats.apid) , $
                  NDAT:all_true(sumdat.ndat eq dats.ndat) , $
                  MODE2:all_true(sumdat.mode2 eq dats.mode2) , $
                  STATUS_BITS:all_true(sumdat.status_bits eq dats.status_bits) , $
                  LTCSNNNN_BITS:all_true(sumdat.LTCSNNNN_BITS eq dats.LTCSNNNN_BITS) , $
                  PRODUCT_BITS:all_true(sumdat.product_bits eq dats.product_bits) , $
                  
                  QUALITY_FLAG_ALT_ENERGY_TABLE:all_true(sums_qf[*,2] eq dats_qf[*,2]) , $
                  QUALITY_FLAG_SPOILER_TEST:all_true(sums_qf[*,3] eq dats_qf[*,3]) , $
                  QUALITY_FLAG_ATT_ENGAGED:all_true(sums_qf[*,4] eq dats_qf[*,4]) , $
                  QUALITY_FLAG_NEW_MASS:all_true(sums_qf[*,7] eq dats_qf[*,7]) , $
                  QUALITY_FLAG_OVER_DEF:all_true(sums_qf[*,8] eq dats_qf[*,8]) , $
                  QUALITY_FLAG_BAD_ENERGY:all_true(sums_qf[*,10] eq dats_qf[*,10]) , $
                  QUALITY_FLAG_MCP_TEST:all_true(sums_qf[*,11] eq dats_qf[*,11]) , $
                  QUALITY_FLAG_THRESHOLD_TEST:all_true(sums_qf[*,14] eq dats_qf[*,14])}
  
  ; Check each tag in structure that is important for summing multiple times of data
  flag_check = 1
  tags = tag_names(struct_check)
  for i=0,n_tags(struct_check)-1 do begin
    flag_check = flag_check and struct_check.(i)
    if flag_check ne 1 then message,tags[i]+' VALUE in structures for summing do not agree!',/cont
  endfor 
  
  ; Sum data
  if flag_check then begin
    ; Perform time averages
    sumdat.epoch     = mean(dats.epoch,/nan)
    if keyword_set(tr) then str_element,/add,sumdat,'time',tr else str_element,/add,sumdat,'time',[dats[0].time,dats[-1].time]
    ;sumdat.time      = [dats.time[0],dats.time[-1]]
    sumdat.met       = mean(dats.met,/nan)
    sumdat.magf_sc   = mean(dats.magf_sc,/nan,dim=2)
    sumdat.magf_inst   = mean(dats.magf_inst,/nan,dim=2)
    if tag_exist(dats,'magf_inst') then sumdat.magf_inst = mean(dats.magf_inst,/nan,dim=2)
    ; Perform sums
    sumdat.num_total = total(dats.num_total,/nan)
    sumdat.num_accum = total(dats.num_accum,/nan)
    sumdat.time_total = total(dats.time_total,/nan)
    sumdat.time_accum = total(dats.time_accum,/nan)
    sumdat.cnts = total(dats.cnts,/nan)
    if tag_exist(dats,'data') then sumdat.data = total(dats.data,2,/nan)
    ; Number of Samples Added
    str_element,/add,sumdat,'nsamples',dnum
    return, sumdat
  endif else begin
    return,!null
  endelse  
end