
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
  struct_check = all_true(sumdat.apid eq dats.apid) and $
                 all_true(sumdat.ndat eq dats.ndat) and $
                 all_true(sumdat.mode2 eq dats.mode2) and $
                 all_true(sumdat.status_bits eq dats.status_bits) and $
                 all_true(sumdat.LTCSNNNN_BITS eq dats.LTCSNNNN_BITS) and $
                 all_true(sumdat.product_bits eq dats.product_bits) and $
                 all_true(sumdat.quality_flag eq dats.quality_flag)
  if struct_check then begin
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
    print,'Structures do not agree!
    return,!null
  endelse  
end