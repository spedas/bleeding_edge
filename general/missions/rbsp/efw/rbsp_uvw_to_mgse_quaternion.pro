;pro rbsp_uvw_to_mgse_quaternion.pro 
;
;Use quaternion rotation along with Sheng's SPICE CDF files to
;rotate from UVW to MGSE (via GSE), or from MGSE to UVW. 
;This is MUCH faster than loading
;SPICE every time.
;
;Example
;timespan,'2014-01-01'
;tvar = 'rbspa_efw_esvy'    ;UVW 
;sc = 'a'
;
;rbsp_uvw_to_mgse_quaternion,tvar,sc
;
;
;Keywords:
;   inverse --> rotate from MGSE to UVW

pro rbsp_uvw_to_mgse_quaternion,tvar,sc,inverse=inv,newname=newname


    tr = timerange()
    get_data,tvar,data=d


    new_times = d.x





    ;Get the spinaxis direction for rotation to/from GSE/MGSE
    tinterpol_mxn,'rbsp'+sc+'_spinaxis_direction_gse',new_times,/quadratic
    get_data,'rbsp'+sc+'_spinaxis_direction_gse_interp',tt,wgse


    if ~keyword_set(newname) then begin 
        if keyword_set(inv) then newname = tvar + '_uvw' else newname = tvar + '_mgse'
    endif


    ;load quaternion, if not already loaded
    if ~tdexists('rbsp'+sc+'_q_uvw2gse',tr[0],tr[1]) then rbsp_load_spice_cdf_file,sc



    ;Interpolate to the wanted times:
    get_data,'rbsp'+sc+'_q_uvw2gse',times,q_uvw2gse


    q_uvw2gse_interp = qslerp(q_uvw2gse, times, new_times)




    ;Convert it to the rotation matrix:
    m = qtom(q_uvw2gse_interp)


    ;for inverse rotation (MGSE to UVW)


    ;Put data into GSE coord
    if keyword_set(inv) then begin 
        m_prime = m
        m_prime[*] = 0.
        for ii=0, n_elements(new_times)-1 do m_prime[ii,*,*] = transpose(m[ii,*,*])


        ;Since the quaternion rotates from GSE --> UVW, I need to rotate from MGSE to GSE
        tinterpol_mxn,'rbsp'+sc+'_spinaxis_direction_gse',new_times,/quadratic
        get_data,'rbsp'+sc+'_spinaxis_direction_gse_interp',ttmp,wgse
        rbsp_mgse2gse,tvar,wgse
        tvarnew = tvar + '_gse'
        get_data,tvarnew,data=d

        v = d.y
        w = v
        w[*] = 0.

        ;Rotation from GSE to UVW
        w[*,0] = v[*,0]*m_prime[*,0,0] + v[*,1]*m_prime[*,0,1] + v[*,2]*m_prime[*,0,2]
        w[*,1] = v[*,0]*m_prime[*,1,0] + v[*,1]*m_prime[*,1,1] + v[*,2]*m_prime[*,1,2]
        w[*,2] = v[*,0]*m_prime[*,2,0] + v[*,1]*m_prime[*,2,1] + v[*,2]*m_prime[*,2,2]

        store_data,newname,new_times,w

    endif else begin 

        tvarnew = tvar
        get_data,tvarnew,data=d

        v = d.y
        w = v
        w[*] = 0.

        ;Rotation from UVW to GSE
        w[*,0] = v[*,0]*m[*,0,0] + v[*,1]*m[*,0,1] + v[*,2]*m[*,0,2]
        w[*,1] = v[*,0]*m[*,1,0] + v[*,1]*m[*,1,1] + v[*,2]*m[*,1,2]
        w[*,2] = v[*,0]*m[*,2,0] + v[*,1]*m[*,2,1] + v[*,2]*m[*,2,2]
        store_data,'tmp_gse',new_times,w

        ;Rotation from GSE to MGSE
        rbsp_gse2mgse,'tmp_gse',wgse
        copy_data,'tmp_gse_mgse',newname

    endelse

end
