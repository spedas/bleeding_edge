; This routine looks for tplot variables corresponding to spin axis
; RA and Dec corrections, and applies them to thx_state_spinras
; and thx_state_spindec, creating new tplot variables for the
; corrected values.  If the variables for the spin axis corrections
; are not found, then the corrected tplot variables will be copied
; verbatim from the uncorrected variables.  If the uncorrected
; variables are not found, no action is taken.


; The correction algorithm is the same for RA and Dec.  This
; helper routine gets called once for RA and once for Dec.

pro apply_oneaxis_correction,rawvar=rawvar,deltavar=deltavar,corrvar=corrvar

   ; Get information from input tplot variables

   get_data,rawvar,data=raw_data,dl=raw_dl,index=raw_n
   get_data,deltavar,data=delta_data,dl=dl,index=delta_n

   if (raw_n NE 0) then begin
      if (delta_n NE 0) then begin
        ; tplot variables exist for the raw data & deltas.
        ;dprint,'Applying corrections'

        time = raw_data.x
        corr_times = delta_data.x
        corr_vals = delta_data.y
        corr_count = n_elements(corr_times)
        first_corr_time=corr_times[0]
        first_corr_val= corr_vals[0]
        last_corr_time=corr_times[corr_count-1]
        last_corr_val= corr_vals[corr_count-1]

        ; Interpolate corrections using input_times

        ; Special case: if only one correction is available, e.g. when only
        ; a single day is loaded in thm_load_state, then that value applies for
        ; all time. (interpol needs at least two points or it will bomb).

        if (corr_count LT 2) then begin
           interp_correction=replicate(first_corr_val,n_elements(time))
        endif else begin
           interp_correction=interpol(corr_vals,corr_times,time)
        endelse

        ; For times before & after correction time range, use nearest
        ; neighbor instead of extrapolation

        idx=where(time LT first_corr_time,count)
        if (count GT 0) then interp_correction[idx] = first_corr_val

        idx=where(time GE last_corr_time,count)
        if (count GT 0) then interp_correction[idx] = last_corr_val

        ; Apply corrections
        fix_raw = raw_data.y - interp_correction

        ; Make output tplot variable
        store_data,corrvar,data={x:time,y:fix_raw},dl=raw_dl

   endif else begin
     ; If the corrections aren't present, just copy the original data
     dprint,'Spin axis corrections variable '+deltavar+' not found, skipping '+corrvar
   endelse
endif else begin
   ; Raw variable doesn't exist, nothing to do here.
   ;dprint,'Spin axis variable '+rawvar+' not found, skipping '+corrvar
endelse

end

; Apply spin axis corrections to spinras and  spindec values,
; creating new tplot variables with corrected spinras and spindec
; This is the routine that gets called from thm_load_state.
; It takes 6 tplot variable names: 3 for spinras (original, delta,
; corrected), and 3 for spindec.

pro apply_spinaxis_corrections,spinras=spinras,spindec=spindec,$
  delta_spinras=delta_spinras, delta_spindec=delta_spindec, $
  corrected_spinras=corrected_spinras, corrected_spindec=corrected_spindec


  apply_oneaxis_correction,rawvar=spinras,deltavar=delta_spinras,corrvar=corrected_spinras
  apply_oneaxis_correction,rawvar=spindec,deltavar=delta_spindec,corrvar=corrected_spindec

end

