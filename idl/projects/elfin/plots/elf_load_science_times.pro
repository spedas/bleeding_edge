;+
; PROCEDURE:
;         elf_load_science_times
;
; PURPOSE:
;         Get science data for FGM and EPD and load into tplot vars
;         Return science collection times structure (for elfin a and b)
;         This routine is used by elf_map_state_t96_intervals.
;
; KEYWORDS:
;         tdate:   time of interest (start time) with the format
;                  'YYYY-MM-DD'
;         dur:     duration of time frame in factional days. default value is 1
;         pred:     use this flag if you want to check predicted data
;-
function elf_load_science_times, pred=pred, tdate=tdate, dur=dur

  if keyword_set(dur) then dur = dur else dur=1
  if keyword_set(tdate) then timespan, tdate, dur
  tr=timerange()
   
  ; load science data (only if not predicted orbit plots)
  if ~keyword_set(pred) then elf_load_epd, type='nflux'
  if ~keyword_set(pred) then elf_load_fgm

  ; get all science data collected and append times
  ; ELFIN A
  get_data, 'ela_pef_nflux', data=pefa
  if size(pefa, /type) EQ 8 then append_array, sci_timea, pefa.x
  get_data, 'ela_pif_nflux', data=pifa
  if size(pifa, /type) EQ 8 then append_array, sci_timea, pifa.x
  get_data, 'ela_fgf', data=fgfa
  if size(fgfa, /type) EQ 8 then append_array, sci_timea, fgfa.x
  get_data, 'ela_fgs', data=fgsa
  if size(fgsa, /type) EQ 8 then append_array, sci_timea, fgsa.x
  if undefined(sci_timea) then sci_timesa=-1. else $
    sci_timesa=sci_timea[UNIQ(sci_timea), SORT(sci_timea)]

  ; ELFIN B
  get_data, 'elb_pef_nflux', data=pefb
  if size(pefb, /type) EQ 8 then append_array, sci_timeb, pefb.x
  get_data, 'elb_pif_nflux', data=pifb
  if size(pifb, /type) EQ 8 then append_array, sci_timeb, pifb.x
  get_data, 'elb_fgf', data=fgfb
  if size(fgfb, /type) EQ 8 then append_array, sci_timeb, fgfb.x
  get_data, 'elb_fgs', data=fgsb
  if size(fgsb, /type) EQ 8 then append_array, sci_timeb, fgsb.x
  if undefined(sci_timeb) then sci_timesb=-1. else $
    sci_timesb=sci_timeb[UNIQ(sci_timeb), SORT(sci_timeb)]

  sci_times={a:sci_timesa, b:sci_timesb}
  
  return, sci_times
  
end