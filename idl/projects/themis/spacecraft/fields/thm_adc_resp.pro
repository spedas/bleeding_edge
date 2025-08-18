
function thm_adc_resp,quantity,f,backup_adc_mode=backup_adc_mode
  if keyword_set(backup_adc_mode) then begin
    case quantity of
      'SCMZ': slot=0
      'V1': slot=2
      'V2': slot=4
      'V3': slot=6
      'V4': slot=8
      'V5': slot=10
      'V6': slot=12
      'E12HF': slot=14
      'E12DC': slot=16
      'E34DC': slot=24
      'E56DC': slot=26
      'SCMX': slot=28
      'SCMY': slot=30
      'E12AC': slot=2
      'E34AC': slot=4
      'E56AC': slot=6
      else: begin
              print,'thm_adc_resp: quantity not recognized'
              return,!values.f_nan
            end
    endcase
  endif else begin
    case quantity of
      'SCMZ': slot=0
      'V1': slot=8
      'V2': slot=9
      'V3': slot=10
      'V4': slot=11
      'V5': slot=12
      'V6': slot=13
      'E12HF': slot=14
      'E12DC': slot=16
      'E34DC': slot=24
      'E56DC': slot=26
      'SCMX': slot=28
      'SCMY': slot=30
      'E12AC': slot=2
      'E34AC': slot=4
      'E56AC': slot=6
      else: begin
              print,'thm_adc_resp: quantity not recognized'
              return,!values.f_nan
            end
    endcase
  endelse

  if strmid(quantity,0,1) eq 'S' then print,'WARNING: SCM phase is corrected during loading.'
  if strmid(quantity,3,1) eq 'A' then slot+=32  $
  else slot-=4 ; Align to SCMX

  phase=f*(slot/262144.0)*2*!pi
return,dcomplex(cos(phase),-sin(phase))
end