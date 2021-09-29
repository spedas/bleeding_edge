;+
;NAME: PSP_FLD_EXTEND_EPOCH
;
;DESCRIPTION:
;  Helper to psp_load_fields routine.  Extends the quality_flag variable to
;  match the time resolution target.  Results valid only if the source epochs
;  and target epochs cover the same time period.
;  
;  Points in the target epoch falling before the source epoch start time will 
;  contain the quality flag of the earliest entry in the quality flag variable.
;  
;  Points in the target epoch falling after the source epoch end time will 
;  contain the quality flag of the last entry in the quality flag variable.
;
;INPUT:
;  DQF: Tplot variable name string or number of the quality flag variable
;       that will be matched to a new time resolution
;  EPOCH_TARGET: (DOUBLE) 1D array holding target epoch times as found
;                 from a tplot variable data.x field.
;  TAG: (STRING) Tplot variable name suffix for new quality flag variable
;  
;KEYWORD OUTPUT:
;  ERROR: Optional named variable to hold error status.  
;         0 for nominal execution
;         1 if the source and target epoch ranges are completely disjoint
;           or do not overlap by at least 90% of the target time range.
;           No new tplot variables are created in this instance.
;
;EXAMPLE:
;  fname = 'psp_fld_l2_mag_rtn_4_sa_per_cyc_20181111_v01.cdf'
;  cdf2tplot,files=fname,varformat="*"
;  get_data, 'psp_fld_l2_mag_RTN_4_Sa_per_Cyc', data=d
;  psp_fld_extend_epoch, 'psp_fld_l2_quality_flags', d.x, "_4per"
;  
;
;CREATED BY: Ayris Narock (ADNET/GSFC) 2020
;
; $LastChangedBy: anarock $
; $LastChangedDate: 2021-01-29 10:50:47 -0800 (Fri, 29 Jan 2021) $
; $LastChangedRevision: 29634 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/fields/util/misc/psp_fld_extend_epoch.pro $
;-

pro psp_fld_extend_epoch, dqf, epoch_target, tag, ERROR=err
  compile_opt idl2

  err = 0
  
  if n_params() ne 3 then begin
    dprint,dlevel=2,"PSP_FLD_EXTEND_EPOCH: Incorrect number of arguments"
    err = 1
    return
  endif
  
  ; Retrieve quality flag starting epochs and extend to target epoch
  get_data,dqf,data=dq,dlimit=dl
  
  if (epoch_target[-1] le dq.x[0]) || (epoch_target[0] ge dq.x[-1]) then begin
    err = 1
    dprint,dlevel=2,"Bad epoch ranges"
    return
  endif else begin
    target_len = epoch_target[-1] - epoch_target[0]
    r = where((dq.x ge epoch_target[0]) and (dq.x le epoch_target[-1]),/NULL)
    overlap_len = dq.x[r[-1]] - dq.x[r[0]]
    if overlap_len / target_len lt 0.9 then begin
      err = 1
      dprint,dlevel=2,"Bad epoch ranges"
      return      
    endif
  endelse
  
  newdq = dq
  newY  = replicate(dq.y[0],n_elements(epoch_target))
  
  for i=0,n_elements(dq.x)-2 do begin
    r = where((epoch_target ge dq.x[i]) and (epoch_target lt dq.x[i+1]), /NULL)
    newY[r] = dq.y[i]
  endfor
  r = where(epoch_target ge dq.x[-1], /NULL)
  newY[r] = dq.y[i]

  str_element,newdq,'x',epoch_target,/add_rep
  str_element,newdq,'y',newY,/add_rep  
  
  store_data,tnames(dqf)+tag,data=newdq,dlimit=dl
end
