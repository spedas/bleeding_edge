;+
; e_var. The tplot var saves 3D E field in certain coord.
; b_var. The tplot var saves 3D B field in the same coord.
; newname=. Set this to saves the new 3D E field to newname, otherwise will overwrite e_var.
; anglemin=. The min angle for E dot B = 0. 15 deg by default.
; no_preprocess=. A boolean, set to skip the interpolation and smoothing on b_var.
;-

pro rbsp_efw_calc_edotb_to_zero, e_var, b_var, $
    anglemin=anglemin, $
    newname=new_var, errmsg=errmsg, no_preprocess=no_preprocess

    errmsg = ''

    if tnames(e_var) eq '' then begin
        errmsg = 'No input e_var ...'
        return
    endif

    if tnames(b_var) eq '' then begin
        errmsg = 'No input b_var ...'
        return
    endif


    get_data, e_var, times, e_vec, limits=limits, dlimits=dlimits
    if keyword_set(no_preprocess) then begin
        bmag_smoothed = get_var_data(b_var)
    endif else begin
        tmp_b_var = b_var+'tmp'
        interp_time, tmp_b_var, times
        copy_data, b_var, tmp_b_var
        rbsp_detrend, tmp_b_var, 1800.
        bmag_smoothed = get_var_data(tmp_b_vec)
    endelse

    ; Calc Ex MGSE.
    e_vec[*,0] = -(e_vec[*,1]*bmag_smoothed[*,1] + e_vec[*,2]*bmag_smoothed[*,2]) / bmag_smoothed[*,0]


    ; Find bad E*B=0 data.
    if n_elements(anglemin) eq 0 then anglemin = 15.    ; deg.
    rad = !dtor
    limiting_ratio = cos(anglemin*rad)/cos((90-anglemin)*rad)

    ; Find bad E*B=0 data (where the angle b/t spinplane MGSE and Bo is
    ; less than 15 deg)
    ; Good data has By/Bx < 3.732   and  Bz/Bx < 3.732
    ntime = n_elements(times)
    bad_flag = intarr(ntime)

    
;    By2Bx = abs(bmag_smoothed[*,1]/bmag_smoothed[*,0])
;    Bz2Bx = abs(bmag_smoothed[*,2]/bmag_smoothed[*,0])
;    store_data, 'B2Bx_ratio', times, [[By2Bx],[Bz2Bx]]
;    ylim,'B2Bx_ratio',0,40
;    options,'B2Bx_ratio','ytitle','By/Bx (black)!CBz/Bx (red)'
;    badyx = where(By2Bx gt limiting_ratio)
;    badzx = where(Bz2Bx gt limiting_ratio)
    byz2bx = abs(bmag_smoothed[*,1:2]/bmag_smoothed[*,[0,0]])
    bad_index = where(total(byz2bx gt limiting_ratio, 2) ne 0, count)
    if count ne 0 then bad_flag[bad_index] = 1
    e_vec[bad_index,0] = !values.f_nan

;    ; Calculate specific limiting angles
;    angle_bybx = atan(1/By2Bx)/!dtor
;    angle_bzbx = atan(1/Bz2Bx)/!dtor
;    store_data,'angle_B2Bx',edata.x,[[angle_bzbx],[angle_bybx]]
;    options,'angle_B2Bx','ytitle','Limiting angles!CAngle Bz/Bx(black)!CAngle ByBx(red)'
;    options,'angle_B2Bx','colors',[0,250]
;    options,'angle_B2Bx','constant',anglemin
;    ylim,'angle_B2Bx',0.1,100,1


;    ; Calculate angles b/t despun spinplane antennas and Bo.
;    ; NOTE: Don't do this calculation for esvy-despun. Takes too long
;    ntime = n_elements(times)
;    ang_ey = fltarr(ntime)
;    ang_ez = fltarr(ntime)
;    if ntime le 86400. then begin
;      for i=0L,ntime-1 do ang_ey[i] = acos(total([0,1,0]*magmgse_smoothed.y[i,*])/(bmag_smoothed[i]))/!dtor
;      for i=0L,ntime-1 do ang_ez[i] = acos(total([0,0,1]*magmgse_smoothed.y[i,*])/(bmag_smoothed[i]))/!dtor
;      store_data,'rbsp'+probe+'_angles',data={x:edata.x,y:[[ang_ey],[ang_ez]]}
;    endif


;    ;Calculate ratio b/t spinaxis and spinplane components
;    e_sp = sqrt(edata.y[*,1]^2 + edata.y[*,2]^2)
;    rat = abs(edata.y[*,0])/e_sp
;    store_data,'rat',data={x:edata.x,y:rat}
;    store_data,'e_sp',data={x:edata.x,y:e_sp}
;    store_data,'e_sa',data={x:edata.x,y:abs(edata.y[*,0])}
;    options,'rat','constant',1


    ; Save to tplot.
    if n_elements(new_var) eq 0 then new_var = e_var
    store_data, new_var, times, e_vec, limits=limits, dlimits=dlimits


end
