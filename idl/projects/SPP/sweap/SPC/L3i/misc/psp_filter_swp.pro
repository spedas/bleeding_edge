;+
;NAME: PSP_FILTER_SWP
;
;DESCRIPTION:
; Removed flagged values from PSP SWEAP SPC tplot variables based on selected
; quality flags.  See usage notes and available flag definitions by calling
; with the /HELP keyword.
;
; For each TVAR passed in a new tplot variable is created with the filtered 
; data.  The new name is of the form:  <tvarname>_{1,2,3}_XXXXXX 
; where each 'XX' is a 0 padded flag indicator sorted from lowest to highest.
; 
; So, psp_filter_swp,'np_fit',[3,4] results in tvar named "np_fit_3_0304"
; Or, psp_filter_swp,'np_fit',0,status=2 results in tvar named "np_fit_2_00"
; 
;  
;INPUT:
; TVARS:    (string/strarr) Elements are data handle names
;             OR (int/intarr) tplot variable reference numbers
; DQFLAG:   (int/intarr) Elements indicate which of the data quality flags
;             to filter on. Values from the set of integers 0 - 31           
;
;KEYWORDS:
; HELP:   If set, print a listing of the available data quality flags and 
;         their meaning.
; STATUS:  (int) From the set {1, 2, 3}. Indicates which flag statuses will be
;             removed.  (default = 3)
;             1: Remove only where the flag is explicitly marked as having 
;                 bad/problematic/condition present/etc
;             2: Remove (1) AND where status not determined ("don't know")
;             3: Remove all EXCEPT where explictly marked as 
;                 good/nominal/condition not present/etc for all selected flags
;             
;             TODO: (what to do about the "don't care" encoding status?)
;
;OUTPUTS:
; NAMES_OUT:  Named variable holding the tplot variable names created 
;             from this filter. Order corresponds to the input array of tvar
;             names, so that tvar[i] filtered is in names_out[i]
;
;EXAMPLE:
;  Keep only values explictly marked as good in the general flag
;  for the 'psp_spc_np_fit' variable
;  IDL> psp_filter_swp,'psp_spc_np_fit',0,status=3
;  
;  Remove all values where flags 11 or 12 are explictly marked as bad
;  for the 'psp_spc_np_fit' variable
;  IDL> psp_filter_swp,'psp_spc_np_fit',[11,12],status=1
;
;CREATED BY: Ayris Narock (ADNET/GSFC) 2020
;
; $LastChangedBy: anarock $
; $LastChangedDate: 2021-01-04 11:00:24 -0800 (Mon, 04 Jan 2021) $
; $LastChangedRevision: 29570 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/sweap/SPC/L3i/misc/psp_filter_swp.pro $
;-

pro psp_filter_swp, tvars, dqflag, STATUS=status, HELP=help, NAMES_OUT=names_out
  compile_opt idl2

  ; Handle HELP option
  @psp_common_spc_flaginfo
  if keyword_set(help) then begin
    print,spc_dqf_infostring,format='(A)'
    return
  endif
  
  names_out = []
  
  if ~isa(dqflag, /INT) then begin
    dprint, dlevel=1, verbose=!psp_sweap.verbose, "DQFLAG must be INT or INT ARRAY"
    return
  endif
  if ~keyword_set(status) $
    || ((status ne 1) and (status ne 2) and (status ne 3)) then begin
      status = 3
  endif
  
  ; Retrieve DQF array
  get_data,'psp_spc_DQF',data=d
  dqf = d.y
  
  
  ; Find index of elements to remove based on DQFLAGS and STATUS
  ; From cdf.vatt.var_notes for SPC L3I 
  ;  All flags are encoded as follows:
  ;  --------------------------
  ;  = 0,   good/nominal/condition not present/etc
  ;  > 0,  bad/problematic/condition present/etc
  ;  = -1,  status not determined ("don't know")
  ;  < -1,  status does not matter ("don't care")
  ;
  ;  -1 ("don't know") is the default value for all flags.
  ;
  ;  The 0th flag array element is the [standardized] global quality flag, 
  ;  signifying whether the data are suitable for use without caveate. 
  ;  It is repeated in the "general_flag" variable.
  
  rem_mask = replicate(0, n_elements(d.x))
  foreach flg,dqflag do begin
    case (status) of
      1: begin
        r = where(dqf[*,flg] gt 0, /NULL)
      end
      2: begin
       r = where((dqf[*,flg] gt 0) or (dqf[*,flg] eq -1), /NULL)
      end
      3: begin
        rgood = where(dqf[*,flg] eq 0, /NULL, COMPLEMENT=r)
      end
    endcase
    rem_mask[r] = 1
  endforeach
  rem_idx = where(rem_mask eq 1, /NULL)
  
  ; Remove data from tplot vars and store in "meaningful" tplot names
  foreach tname,tvars do begin
    suffix = '_'+status.ToString('(I02)')+'_'
    foreach flg,dqflag do suffix+= flg.ToString('(I02)')
    get_data,tname,data=d, dl=dl
    d.y[rem_idx,*] = !values.f_NAN
    if tag_exist(d,'dy') then d.dy[rem_idx,*] = !values.f_NAN
    if tag_exist(d,'dyL') then d.dyL[rem_idx,*] = !values.f_NAN
    if tag_exist(d,'dyH') then d.dyH[rem_idx,*] = !values.f_NAN
   
    store_data,tnames(tname)+suffix,data=d,dl=dl
    names_out = [names_out, tnames(name)+suffix]
  endforeach
end
