;+
; NAME:
;    CORRECT_DELTA_PHI_VECTOR.PRO
;
; PURPOSE:  
;
; CATEGORY: 
;   TDAS
;
; CALLING SEQUENCE:
;   correct_delta_phi_vector,tvar=thb_fgs_dsl,delta_phi=delta_phi
;
;  INPUTS:
;
;  OUTPUTS:
;
;  KEYWORDS:
;     tvar: name of an input tplot variable containing 3-d vectors in DSL.
;        The data will be altered in place.
;     x_in, y_in: Input data with X and Y in separate arrays. Output
;        goes to variables specified with the x_out and y_out keywords.
;     xyz_in: Input data with x,y,z in a single array. Data will be
;        altered in place.
;     delta_phi: Array of delta_phi values, in degrees.  The sample
;        count must match the sample count of the data being transformed.
;    
;  PROCEDURE:
;
; Given a tplot variable name or array(s) of data values (in DSL coordinates),
; and an array of delta_phi values, apply a counter-clockwise rotation of 
; delta_phi degrees.  This is used to apply the eclipse delta_phi corrections 
; obtained from the spin model, and is intended for correcting spin fits (efs 
; and fgs), and (3-vector) particle moments.  Waveform data
; does not require this correction.  Some of the quantities
; from L1 MOM are tensors, and should not be corrected with this
; routine -- see correct_delta_phi_tensor.
;
;-

pro correct_delta_phi_vector,x_in=x,y_in=y,xyz_in=xyz_in,delta_phi=delta_phi,tvar=tvar, x_out=xp, y_out=yp
  if keyword_set(tvar) then begin
     get_data,tvar,data=d
     x=d.y[*,0]
     y=d.y[*,1]
  end else if keyword_set(xyz_in) then begin
     x=xyz_in[*,0]
     y=xyz_in[*,1]
  end
  
  cs = cos(delta_phi*!DPI/180.D)
  sn = sin(delta_phi*!DPI/180.D)
  my_xp = x*cs - y*sn
  my_yp = x*sn + y*cs

  if keyword_set(tvar) then begin
     d.y[*,0] = my_xp
     d.y[*,1] = my_yp
     store_data,tvar,data=d
  end else if keyword_set(xyz_in) then begin
     xyz_in[*,0] = my_xp
     xyz_in[*,1] = my_yp
  end else begin
     xp=my_xp 
     yp=my_yp
  endelse
end
