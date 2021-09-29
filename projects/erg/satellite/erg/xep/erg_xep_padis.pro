;Procedure:
;erg_xep_padis, tname_flux, tname_mag_dsi $
;    , dpa=dpa, no_pa=no_pa, no_energy=no_energy,pa_offset=pa_offset, count=count

;Description:
; --- Calculate pitch angle distributions (no angle weighting) of electrons
;     observed by XEP onboard the ERG spacecraft.
;Input:
; --- tname_flux    :[string or integer]
;                    A tplot name or tplot number of electron flux.
;                    flux[nt x nsv x nsp]
; --- tname_mag_dsi :[string or integer]
;                    A tplot name or tplot number of the magnetic field in DSI
;                    coordiantes.
;                    mag[nt x xyz]
;Keyowrd:
; --- dpa           :[float]
;                    Width of pitch angle bin [deg]. Default is 20 [deg].
; --- no_pa         :If set, no return tplot variables *_pad_sv??
; --- no_energy     :If set, no return tplot variables *_pad_pabin??
; --- count         :If set, return number of data in each bin.
;                    (tplot variables, '*_dcount_*')
;
;Output:
; --- tname_flux+'_pa'       :[tplot variable]
;                             3D array of pitch angle [deg].
; --- tname_flux+'_pad'      :[tplot variable]
;                             3D array (time-energy-pa) of flux sorted by pitch angle.
; --- tname_flux+'_pad_sv??' :[tplot variable]
;                                2D array (time-pa) of flux sorted by pitch angle
;                                for each energy step (sv??).
; --- tname_flux+'_pad_pabin??' :[tplot variable]
;                                  2D array (time-energy) of flux
;                                 sorted by pitch angle for each pitch angle bin (pabin??).
;
;Exmaple usage:
; IDL> erg_xep_padis, 'erg_xep_l2_FEDU_SSD', 'erg_mgf_l2_mag_8sec_dsi'
;
;Author:
; Shun Imajo, ERG Science Center, Nagoya University
;
;History:
;created by S. Imajo 2021-01-28

pro erg_xep_padis, tname_flux, tname_mag_dsi $
    , dpa=dpa, no_pa=no_pa, no_energy=no_energy, count=count


    ;Setting
    if not keyword_set(dpa) then dpa = 20. ;[deg.]
    if (180./dpa) mod 1 ne 0. then begin
        print,'dpa should be an angle 180 divided by an integer (e.g.,10,15,20)'
        return
    endif

    if not KEYWORD_SET(pa_offset) then pa_offset=0
    ;------------------------------------------------------------------------------
    ;Calculation
    ;get idl variable
    get_data, tname_flux   , data=d1,dlimit=dl1 ;[nt x nsv x nsp]

    get_data, tname_mag_dsi, data=d2,dlimit=dl2

    ;parameters
    nt  = n_elements(d1.y[*,0,0])
    nsv = n_elements(d1.y[0,*,0])
    nsp = n_elements(d1.y[0,0,*])
    ;spin phase level time
    time_sp = dblarr(ulong(nt)*nsp)
    ang_sp = dblarr(ulong(nt)*nsp)
    dph=360./16.
    for i = 0, nt-2 do begin & $
        dt  = (d1.x[i+1] - d1.x[i]) / nsp & $
        time_sp[i*nsp:(i+1)*nsp-1] = d1.x[i] + dindgen(nsp)*dt + dt/2. & $
        ang_sp [i*nsp:(i+1)*nsp-1] = dindgen(nsp)*dph + dph/2. ;spin phase angle
    endfor

    ;last elements
    time_sp[(nt-1)*nsp:nt*nsp-1] = d1.x[nt-1] + dindgen(nsp)*dt + dt/2.
    ang_sp[(nt-1)*nsp:nt*nsp-1] = dindgen(nsp)*dph + dph/2.
    store_data, 'erg_xep_time_sp', data={x:time_sp, y:time_sp}
    store_data, 'erg_xep_ang_sp', data={x:time_sp, y:ang_sp}
    options, 'erg_xep_time_sp', ystyle=1
    options, 'erg_xep_ang_sp', ystyle=1
    ;interpolation
    tinterpol_mxn, tname_mag_dsi, 'erg_xep_time_sp',/nan_extrapolate
    ;no interpolation
;    get_data,tname_mag_dsi,data=d
;    no_in_mag= dblarr(ulong(nt)*nsp,3)
;    for i = 0, nt-2 do begin & $
;        no_in_mag[i*nsp:(i+1)*nsp-1,*]=transpose(replicate_array(d.y[i,*],16))
    ;endfor
    ;store_data,tname_mag_dsi+'_interp',data={x:time_sp,y:no_in_mag}

    ;normal vector of the magnetic field
    get_data,tname_mag_dsi+'_interp',data=d
    v_len = sqrt(d.y[*,0]^2+d.y[*,1]^2+d.y[*,2]^2)
    e_mag = [[d.y[*,0]/v_len],[d.y[*,1]/v_len],[d.y[*,2]/v_len]] ;[nt*nsp x xyz]

    ;--------P.A. in dsi coordinate----------
    ntsp=n_elements(time_sp)
    cdffpath = dl1.cdf.filename
    cdfi=cdf_load_vars(cdffpath,varformat='FEDU_Angle_sga')
    id = where( strcmp( cdfi.vars.name, 'FEDU_Angle_sga' ))
    angarr = *( cdfi.vars[id].dataptr )  ;lower limit, center, and upper limit of the elevation and athimuthal angles of detector look directions in satellite coordinates
    ele = replicate(reform(angarr[0,1]),ntsp);ang_sp;ang_sp
    azi =replicate(reform(angarr[1,1]),ntsp);replicate(reform(angarr[1,1]),ntsp);

    sphere_to_cart, 1, ele, azi, ex, ey, ez
    theta= (ang_sp-(90+21.6))*!dtor
    rotate_z,theta,ex, ey, ez,ex1, ey1, ez1
    store_data,'erg_xep_lookdir_dsi',data={x:time_sp,y:[[ex1],[ey1],[ez1]]}
    get_data,'erg_xep_lookdir_dsi',data=e_ch1
    e_ch2 = transpose(reform(e_ch1.y,[nsp,nt,3]),[1,0,2]) ;[nt x nsp x xyz]
    e_mag2 = transpose(reform(e_mag,[nsp,nt,3]),[1,0,2]) ;[nt x nsp x xyz]
    ;pitch angle
    pa = 180 - acos(total(e_ch2*e_mag2,3))*!radeg ;,/nan[nt x nsp] in deg.
    ;------------------------------------------------------------------------------
    ;binning
    ;define pitch angle bins
    ;parameters
    pa_llim = dpa*indgen(180/dpa)
    pa_ulim = dpa*(indgen(180/dpa)+1)
    pa_bin  = (pa_llim + pa_ulim) / 2.
    npa     = n_elements(pa_bin)
    ;output array
    padist = fltarr(nt,nsv,npa) ;[nt x nsv x npa]
    dcount = fltarr(nt,nsv,npa) ;[nt x nsv x npa]
    print, '< erg_cal_xep_padis > P.A. sorting ...'
    for i = 0UL, nt-1 do begin
        for j = 0, nsv-1 do begin
            for k = 0, npa-1 do begin
                ;tmp_flux[nsp x nch] at specified time and sv step
                tmp_flux = d1.y[i,j,*]
                tmp_pa   = pa[i,*] ;[nt x nsp]
                sub = where(tmp_pa gt pa_llim[k] and $
                tmp_pa le pa_ulim[k]     $
                , cnt)
                dcount[i,j,k]=cnt
                if cnt gt 0 then begin
                    sub2 = where(tmp_flux[sub] gt 0, cnt2)
                    if cnt2 gt 0 then begin
                        padist[i,j,k] = mean(tmp_flux[sub[sub2]],/nan)
                    endif else begin
                        padist[i,j,k] = 0
                    endelse
                endif else begin
                    padist[i,j,k] = !values.f_nan
                endelse
            endfor
        endfor
    endfor
    ;------------------------------------------------------------------------------
    ;Output

    ;pitch angle
    store_data, tname_flux+'_pa' $
    , data={x:d1.x,y:pa,v:indgen(nsp)}

    ; count of data in each bin
    if KEYWORD_SET(count) then store_data, tname_flux+'_dcount' $
    , data={x:dcount,y:pa,v:indgen(nsp)}

    ;3d (time-energy-pa) flux
    store_data, tname_flux+'_pad' $
    , data={x:d1.x,y:padist,v1:d1.v,v2:pa_bin} $
    , dlim={ytitle:'Energy',ysubtitle:'[keV]' $
    ,ztickformat:'pwr10tick',zlog:1 $
    ,ztitle:'[1/s/cm!U2!N/keV/sr]',minzlog:1e-10}

    if not KEYWORD_SET(no_pa) then begin
        ;P.A. dist.
        for i = 0, nsv-1 do begin
            flux = reform(padist[*,i,*])
            dlim = { ytitle:string(d1.v[i],format='(f0.1)')+' keV' $
            , ysubtitle:'P.A.!C[deg.]', ytickv:[0,45,90,135,180] $
            , yticks:4, yminor:3, ylog:0, zlog:1, ztickformat:'pwr10tick' $
            , spec:1, no_interp:1, yticklen:-0.03, zticklen:-0.3 $
            , ztitle:'[1/s/cm!U2!N/keV/sr]',extend_y_edges:1, zrange:[1e-1,1e4],constant:[45,90,135],minzlog:1e-10}
            data = { x:d1.x,y:flux,v:pa_bin}
            store_data, tname_flux+'_pad_sv' + string(format='(i2.2)',i) $
            , data=data, dlim=dlim

            if KEYWORD_SET(count) then begin
                dcnt= reform(dcount[*,i,*])
                dlim = { ytitle:string(d1.v[i],format='(f0.1)')+' keV' $
                , ysubtitle:'P.A.!C[deg.]', ytickv:[0,45,90,135,180] $
                , yticks:4, yminor:3, ylog:0, zlog:0 $
                , spec:1, no_interp:1, yticklen:-0.03, zticklen:-0.3 $
                , ztitle:'number of data',extend_y_edges:1,constant:[45,90,135],minzlog:1e-10}
                data = { x:d1.x,y:dcnt,v:pa_bin}
                store_data, tname_flux+'_dcount_sv' + string(format='(i2.2)',i) $
                , data=data, dlim=dlim
            endif

        endfor
    endif
    if not KEYWORD_SET(no_energy) then begin
        ;energy dist.
        for i = 0, npa-1 do begin
            flux = reform(padist[*,*,i])
            dlim = { ytitle:'C.P.A.=!C'+string(pa_bin[i],format='(5f0.1)')+'!9'+string(176b)+'!x' $
            , ytickformat:'pwr10tick', ylog:1 ,ysubtitle:'Energy!C[keV]',yrange:[500,3300] $
            ,ystyle:1, zlog:1, ztickformat:'pwr10tick' $
            , spec:1, no_interp:1, yticklen:-0.03, zticklen:-0.3 $
            , ztitle:'[1/s/cm!U2!N/keV/sr]',zrange:[1e-1,1e4],minzlog:1e-10}
            data = { x:d1.x,y:flux,v:d1.v}
            store_data, tname_flux+'_pad_pabin' + string(format='(i2.2)',i) $
            , data=data, dlim=dlim

            if KEYWORD_SET(count) then begin
                dcnt= reform(dcount[*,*,i])
                dlim = { ytitle:'C.P.A.=!C'+string(pa_bin[i],format='(5f0.1)')+'!9'+string(176b)+'!x' $
                , ytickformat:'pwr10tick', ylog:1 ,ysubtitle:'Energy!C[keV]',yrange:[500,3300] $
                ,ystyle:1, zlog:0 $
                , spec:1, no_interp:1, yticklen:-0.03, zticklen:-0.3 $
                , ztitle:'number of data',minzlog:1e-10}
                data = { x:d1.x,y:dcnt,v:d1.v}
                store_data, tname_flux+'_dcount_pabin' + string(format='(i2.2)',i) $
                , data=data, dlim=dlim
            endif
        endfor
    endif
end
