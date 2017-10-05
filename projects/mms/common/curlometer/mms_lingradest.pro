;+
; PROCEDURE:
;       mms_lingradest
;       
; PURPOSE:
;       Calculations of Grad, Curl, Curv,..., for MMS using
;       the Linear Gradient/Curl Estimator technique
;       see Chanteur, ISSI, 1998, Ch. 11
;
; Based on Cluster routine (A. Runov, 2003) 
;
; Input: Bxyz from four points with the same time resolution
;        and same sampling intervals (joined time series)
;        Coordinates of the four points (R) with the same time
;        resolution and sampling as Bxyz
;        datArrLength := the length of B and R arrays (must be
;        the same for all vectors)
;        
; Output: bxbc, bybc, bzbc: B-field in the barycenter
;         LGBx, LGBy LGBz: B-gradient at the barycenter
;         LCxB, LCvB, LCzB: curl^B at the barycenter
;         curv_x_B, curv_y_B, curv_z_B: B-curvature at the
;         barycenter, RcurvB: the curvature radius
;         
; $LastChangedBy: egrimes $
; $LastChangedDate: 2017-04-24 12:31:29 -0700 (Mon, 24 Apr 2017) $
; $LastChangedRevision: 23222 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/common/curlometer/mms_lingradest.pro $
;-

pro mms_lingradest, fields=fields, positions=positions, suffix=suffix
   if undefined(suffix) then suffix = ''
  if undefined(fields) || undefined(positions) then begin
    dprint, dlevel = 0, 'B-field and spacecraft position keywords required.'
    return
  endif
  ;... interpolate the magnetic field data all onto the same timeline (MMS1):
  ;... should be in GSE coordinates
  tinterpol, fields[1], fields[0], newname=fields[1]+'_i', error=b_error_1
  tinterpol, fields[2], fields[0], newname=fields[2]+'_i', error=b_error_2
  tinterpol, fields[3], fields[0], newname=fields[3]+'_i', error=b_error_3
    
  if b_error_1 ne 1 or b_error_2 ne 1 or b_error_3 ne 1 then begin
    dprint, dlevel =0, 'Error interpolating magnetic field data all onto the same timeline (MMS1)'
    return
  endif
  
  ;... interpolate the definitive ephemeris onto the magnetic field timeseries
  ;... should be in GSE coordinates
  tinterpol, positions[0], fields[0], newname=positions[0]+'_i', error=p_error_1
  tinterpol, positions[1], fields[0], newname=positions[1]+'_i', error=p_error_2
  tinterpol, positions[2], fields[0], newname=positions[2]+'_i', error=p_error_3
  tinterpol, positions[3], fields[0], newname=positions[3]+'_i', error=p_error_4
  
  if p_error_1 ne 1 or p_error_2 ne 1 or p_error_3 ne 1 or p_error_4 ne 1 then begin
    dprint, dlevel =0, 'Error interpolating S/C position data onto the magnetic field timeseries'
    return
  endif
  
  ; ... get data
  get_data, fields[0], data=B1
  datarrLength = n_elements(B1.x)

  Bx1 = B1.y[*,0] & By1 = B1.y[*,1] & Bz1 = B1.y[*,2] & Bt1 = sqrt(B1.y[*,0]^2+B1.y[*,1]^2+B1.y[*,2]^2)
  get_data, positions[0]+'_i', data=R1
  R1=R1.y
  
  get_data, fields[1]+'_i', data=B2
  Bx2 = B2.y[*,0] & By2 = B2.y[*,1] & Bz2 = B2.y[*,2] & Bt2 = sqrt(B2.y[*,0]^2+B2.y[*,1]^2+B2.y[*,2]^2)
  get_data, positions[1]+'_i', data=R2
  R2=R2.y
  
  get_data, fields[2]+'_i', data=B3
  Bx3 = B3.y[*,0] & By3 = B3.y[*,1] & Bz3 = B3.y[*,2] & Bt3 = sqrt(B3.y[*,0]^2+B3.y[*,1]^2+B3.y[*,2]^2)
  get_data, positions[2]+'_i', data=R3
  R3=R3.y
  
  get_data, fields[3]+'_i', data=B4
  Bx4 = B4.y[*,0] & By4 = B4.y[*,1] & Bz4 = B4.y[*,2] & Bt4 = sqrt(B4.y[*,0]^2+B4.y[*,1]^2+B4.y[*,2]^2)
  get_data, positions[3]+'_i', data=R4
  R4=R4.y
  
  ; ... calculation starts
  
  lingradest,     Bx1, Bx2, Bx3, Bx4,                            $
                  By1, By2, By3, By4,                            $
                  Bz1, Bz2, Bz3, Bz4,                            $
                  R1,  R2,  R3,  R4,                             $
                  datarrLength,                                  $
                  bxbc, bybc, bzbc, bbc,                         $
                  LGBx, LGBy, LGBz,                              $
                  LCxB, LCyB, LCzB, LD,                          $
                  curv_x_B, curv_y_B, curv_z_B, RcurvB
                  
  ; ... calculation ends
   
  ; ... store the results:
  ;                  
  store_data, 'Bt'+suffix, data={x: B1.x,  y: Bbc[*]}
  store_data, 'Bx'+suffix, data={x: B1.x,  y: Bxbc[*]}
  options, 'Bx'+suffix, 'color', 2
  store_data, 'By'+suffix, data={x: B1.x, y: Bybc[*]}
  options, 'By'+suffix, 'color', 4
  store_data, 'Bz'+suffix, data={x: B1.x, y: Bzbc[*]}
  options, 'Bz'+suffix, 'color', 6
  
  store_data, 'Bbc'+suffix, data=['Bt','Bx','By','Bz']+suffix
  
  ; ... B-field gradients
  store_data, 'gradBx'+suffix, data={x: B1.x, y: LGBx[*,*]}
  store_data, 'gradBy'+suffix, data={x: B1.x, y: LGBy[*,*]}
  store_data, 'gradBz'+suffix, data={x: B1.x, y: LGBz[*,*]}
  
  CB =  sqrt(LCxB[*]^2 + LCyB[*]^2 +  LCzB[*]^2);
  store_data, 'absCB'+suffix, data={x: B1.x,  y: CB[*]} ; in nT/1000km
  store_data, 'CxB'+suffix, data={x: B1.x,  y: LCxB[*]} ; in nT/1000km
  options, 'CxB'+suffix, 'colors', 2
  store_data, 'CyB'+suffix, data={x: B1.x,  y: LCyB[*]} ; in nT/1000km
  options, 'CyB'+suffix, 'colors', 4
  store_data, 'CzB'+suffix, data={x: B1.x,  y: LCzB[*]} ; in nT/1000km
  options, 'CzB'+suffix, 'colors', 6
  
  store_data, 'divB_nT/1000km'+suffix, data={x: B1.x,  y: LD[*]} ; divB in nT/1000km
  
  store_data, 'curlB_nT/1000km'+suffix, data=['absCB', 'CxB','CyB','CzB']+suffix
  
  
  store_data, 'jx'+suffix, data={x: B1.x,  y: 0.8*LCxB[*]} ; jx in nA/m^2
  options, 'jx'+suffix, 'colors', 2
  options, 'jx'+suffix, 'ysubtitle', '[nA/m!U2!N]'
  options, 'jx'+suffix, 'labels', 'Jx'
  store_data, 'jy'+suffix, data={x: B1.x,  y: 0.8*LCyB[*]} ; jy in nA/m^2
  options, 'jy'+suffix, 'colors', 4
  options, 'jy'+suffix, 'ysubtitle', '[nA/m!U2!N]'
  options, 'jy'+suffix, 'labels', 'Jy'
  store_data, 'jz'+suffix, data={x: B1.x,  y: 0.8*LCzB[*]} ; jz in nA/m^2
  options, 'jz'+suffix, 'colors', 6
  options, 'jz'+suffix, 'ysubtitle', '[nA/m!U2!N]'
  options, 'jz'+suffix, 'labels', 'Jz'
  
  store_data, 'jtotal'+suffix, data=['jx', 'jy', 'jz']+suffix
  options, 'jtotal'+suffix, 'labflag', -1
  options, 'jtotal'+suffix, 'ytitle', 'J'
  
  store_data, 'curvx'+suffix, data={x: B1.x,  y: curv_x_B}
  options, 'curvx'+suffix, 'colors', 2
  store_data, 'curvy'+suffix, data={x: B1.x,  y: curv_y_B}
  options, 'curvy'+suffix, 'colors', 4
  store_data, 'curvz'+suffix, data={x: B1.x,  y: curv_z_B}
  options, 'curvz'+suffix, 'colors', 6
  
  store_data, 'curvB'+suffix, data=['curvx',  'curvy',  'curvz']+suffix
  
  store_data, 'Rc_1000km'+suffix, data={x: B1.x, y: RcurvB}

end
