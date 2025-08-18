;+
; TYPE:
;   function.
;
; NAME:
;   rbsp_mgse2gse.
;
; PURPOSE:
;   Convert vector in mGSE coord to GSE. (Also see rbsp_gse2mgse.pro)
;
; PARAMETERS:
;   tname, in, type = string or int, required.
;       tplot variable name or number, data must be in [n,3].
;
;   wgse, in/out, type = [3] or [n,3], optional.
;       The w-antenna direction in GSE.
;       By default, we load wgse automatically. It is saved for backward compatibility.
;       If set, then keywords probe and no_spice_load has no effect.
;       If omitted, then use spice to get wgse.
;
; KEYWORDS:
;   newname = newname, in, string, optional.
;       name of output tplot variable. If not set, newname = oldname+'_mgse'.
;
;   inverse = inverse, in, boolean, optional.
;       If set do gse->mgse, otherwise do mgse->gse.
;
;   probe = probe, in, string, optional.
;       probe can be 'a' or 'b'. Default is 'a'.
;       Used only when wgse is not set.
;
;   no_spice_load = no_spice_load, in, boolean, optional.
;       Set when spice kernel is loaded already. Set to 0, to use spice kernel.
;
; RETURN:
;   none.
;
; EXAMPLE:
;   rbsp_mgse2gse, 'rbspa_pos_mgse', wgse, newname = 'rbspa_pos_gse'
;
;   rbsp_mgse2gse, 'rbspa_pos_gse', wgse, newname = 'rbspa_pos_mgse', /inverse
;
;   rbsp_mgse2gse, 'rbspa_pos_mgse', newname = 'rbspa_pos_gse', $
;       probe = 'a', /no_spice_load
;
;   rbsp_mgse2gse, 'rbspa_pos_gse', newname = 'rbspa_pos_mgse', /inverse, $
;       probe = 'a', /no_spice_load
;
; DEPENDENCE:
;   idl_icy module, see icy_test.pro in tdas.
;
; NOTES:
;   * wgse and x_mgse are the same, x_mgse = {sint*cosp, sint*sinp, cost}.
;   * v_gse = {vx_gse, vy_gse, vz_gse},
;     v_mgse = {vx_mgse, vy_mgse, vz_mgse},
;     gse->mgse, M1 = | sint*cosp, sint*sinp, cost |
;                     | -sinp    , cosp     , 0    |
;                     |-cost*cosp,-cost*sinp, sint |
;     mgse->gse, M2 = transpose(M1), v_gse = M2*v_mgse.
;
; HISTORY:
;   Sheng Tian, UMN 2013-09-18 (created)
;   Sheng Tian, 2022-07-08, load wsc_gse from spice_var.
;
; VERSION:
;   $LastChangedBy: jimm $
;   $LastChangedDate: 2024-07-10 12:50:20 -0700 (Wed, 10 Jul 2024) $
;   $LastChangedRevision: 32732 $
;   $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/missions/rbsp/efw/rbsp_mgse2gse.pro $
;-



pro rbsp_mgse2gse, tname, wgse, probe=probe, $
    newname=newname, inverse=inverse, $
    no_spice_load=no_spice_load, $
    _extra=extra

    compile_opt idl2
    on_error, 0

    get_data, tname, data = dat
    vec0 = dat.y            ; old vec.
    vec1 = double(vec0)     ; new vec.
    vx0 = vec0[*,0] & vy0 = vec0[*,1] & vz0 = vec0[*,2]


    ; This block prepares wx,wy,wz.
    ; get x_mgse, which is also w_sc in gse.
    if n_elements(wgse) ne 0 then begin
        if n_elements(wgse) eq 3 then begin     ; wgse in [3].
            wx = wgse[0] & wy = wgse[1] & wz = wgse[2]
        endif else begin                        ; wgse in [n,3].
            wx = wgse[*,0] & wy = wgse[*,1] & wz = wgse[*,2]
        endelse
    endif else begin
        ; We need probe here, assume tname is rbspx_xxx.
        if n_elements(probe) eq 0 then probe = strlowcase(strmid(tname,4,1))
        prob = probe[0]
        prefix = 'rbsp'+prob+'_'

        ; Use spice_var by default. If no_spice_load = 0 means to load use spice kernel.
        if n_elements(no_spice_load) eq 0 then no_spice_load = 1
        if keyword_set(no_spice_load) then begin
            ; Load w_sc from spice_vars.
            tr = minmax(dat.x)
            rbsp_efw_read_spice_var, tr, probe=prob
            var = prefix+'wsc_gse'
            get_data, var, data=dat2
            wgse = dat2.y
            wx = interpol(wgse[*,0], dat2.x, dat.x)
            wy = interpol(wgse[*,1], dat2.x, dat.x)
            wz = interpol(wgse[*,2], dat2.x, dat.x)
            wgse = [[wx],[wy],[wz]]
        endif else begin
            ; Load w_sc from spice kernel.

            ; load spice kernel and get wgse.
            ; interpolation because spice runs slow and wgse varies slow.
            rbsp_efw_init,_extra=extra
            rbsp_load_spice_kernels,_extra=extra

            t0 = dat.x
            nrec = n_elements(t0)
            tt0 = [t0[0],t0[nrec-1]]
            wgse = dblarr(2,3)
            for i = 0, 1 do begin
                tstr = time_string(tt0[i], tformat = 'YYYY-MM-DDThh:mm:ss.ffffff')
                cspice_str2et, tstr, et
                cspice_pxform, 'RBSP'+prob+'_SCIENCE', 'GSE', et, pxform
                wgse[i,*] = pxform[2,*]
            endfor
            wx = interpol(wgse[*,0], tt0, t0)
            wy = interpol(wgse[*,1], tt0, t0)
            wz = interpol(wgse[*,2], tt0, t0)
            wgse = [[wx],[wy],[wz]]
        endelse
    endelse

    ; prepare angle.
    p = atan(double(wy),wx)     ; this way p (phi) in [0,2pi].
    cosp = cos(p)
    sint = wx/cosp
    sinp = wy/sint
    cost = double(wz)

    ; rotation. break the matrix to do vectorized calc, fast.
    if ~keyword_set(inverse) then begin     ; M2, mgse->gse.
        vx1 = sint*vx0 - cost*vz0
        vz1 = cost*vx0 + sint*vz0
        vy1 = vy0
        vx2 = cosp*vx1 - sinp*vy1
        vy2 = sinp*vx1 + cosp*vy1
        vz2 = vz1
    endif else begin                        ; M1, gse->mgse.
        vx1 =  cosp*vx0 + sinp*vy0
        vy1 = -sinp*vx0 + cosp*vy0
        vz1 =  vz0
        vx2 =  sint*vx1 + cost*vz1
        vy2 =  vy1
        vz2 = -cost*vx1 + sint*vz1
    endelse

    if keyword_set(newname) then name = newname else name = tname+'_gse'
    store_data, name, data = {x:dat.x, y:[[vx2],[vy2],[vz2]]}

end




;rbsp_efw_init,_extra=extra
;
;;tr = time_double(['2013-03-14/07:00','2013-03-14/10:00'])
;tr = timerange()
;timespan, tr[0], tr[1]-tr[0], /second
;
;
;if ~tdexists('rbsp'+sc+'_q_uvw2gse',tr[0],tr[1]) then rbsp_load_spice_cdf_file,probe
;
;;rbsp_load_spice_kernels,_extra=extra
;;rbsp_load_spice_state, probe = probe, coord = 'gse', _extra=extra;
;
;
;rbsp_mgse2gse, 'rbsp'+sc+'_state_pos_gse', wgse, $
;  newname = 'rbsp'+sc+'_state_pos_mgse', $
;  /inverse,probe=probe,_extra=extra
;
;rbsp_gse2mgse, 'rbsp'+sc+'_state_pos_gse', wgse, $
;  newname = 'rbsp'+sc+'_state_pos_mgse2'

;rbsp_mgse2gse, 'rbsp'+sc+'_state_pos_mgse', wgse, $
;  newname = 'rbsp'+sc+'_state_pos_gse2', $
;  probe = probe,_extra=extra
;
;
;vars = ['rbsp'+sc+'_state_pos_*']
;tplot, vars
;
;get_data, 'rbsp'+sc+'_state_pos_mgse', data = mgse1
;get_data, 'rbsp'+sc+'_state_pos_mgse2', data = mgse2
;print, max(mgse1.y-mgse2.y)
;
;get_data, 'rbsp'+sc+'_state_pos_gse', data = gse1
;get_data, 'rbsp'+sc+'_state_pos_gse2', data = gse2
;print, max(gse1.y-gse2.y)
;end
