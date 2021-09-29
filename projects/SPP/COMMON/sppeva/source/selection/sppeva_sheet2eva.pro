;+
;
;FUNCTION: SPPEVA_SHEET2EVA
;PURPOSE:  To add block info into the csv file downloaded from the Google Sheet.
;
;INPUT:
;  file_in : The name of the input file.
;  file_out: (Optional) The name of the output file. If omitted, a suffix "_converted"
;                       will be added.
;  mode    :  (Optional) Set 'FLD' or 'SWP'
;
;CREATED BY:	 Mitsuo Oka
;
; $LastChangedBy: moka $
; $LastChangedDate: 2020-11-19 13:07:06 -0800 (Thu, 19 Nov 2020) $
; $LastChangedRevision: 29364 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/COMMON/sppeva/source/selection/sppeva_sheet2eva.pro $
;
;-

PRO sppeva_sheet2eva, file_in, file_out, mode=mode
  compile_opt idl2

  ;---------------------
  ; INIT
  ;---------------------
  sppeva_init

  if undefined(mode) then mode = 'FLD'
  var = 'spp_'+mode+'_fomstr'

  ; Prep file_in WITHOUT .csv extension
  if undefined(file_in) then begin
    file_in = var
  endif else begin
    if strmatch(file_in,'*.csv') then begin; If .csv extension does exist
      file_in = strmid(file_in,0,max(strsplit(file_in,'.')-1)); then remove it.
    endif
  endelse

  ; Prep file_out WITH .csv extension
  if undefined(file_out) then begin
    file_out = file_in+'_converted.csv'
  endif else begin
    if not strmatch(file_out,'*.csv') then begin
      file_out += '.csv'
    endif
  endelse

  ; Add .csv to file_in  
  file_in += '.csv'
  
  ;---------------------
  ; LOAD CSV
  ;---------------------
  sppeva_sitl_csv2tplot, file_in, var=var

  ;---------------------
  ; GET BLOCK DATA
  ;---------------------
  get_data,var,data=D,dl=dl,lim=lim
  tstart = min(dl.FOMSTR.START)-86400.d0
  tstop  = max(dl.FOMSTR.STOP)+86400.d0
  sppeva_get_fld,'f1_100bps',trange=[tstart,tstop]

  ;---------------------
  ; WRITE CSV
  ;---------------------
  sppeva_sitl_tplot2csv, var, filename=file_out, msg=msg, error=error, auto=auto

END