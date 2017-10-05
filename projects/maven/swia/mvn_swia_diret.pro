;+
; PROCEDURE:
;       mvn_swia_dirEt
; PURPOSE:
;       Makes directional E-t spectrograms in the specified frame from SWIA Coarse data.
;       6 tplot variables will be generated: +X, -X, +Y, -Y, +Z, and -Z.
; CALLING SEQUENCE:
;       mvn_swia_diret
; INPUTS:
;       None (SWIA data and SPICE kernels need to have been loaded)
; KEYWORDS:
;       all optional
;       FRAME: specifies the frame (Def: 'MSO')
;       UNITS: specifies the units ('eflux', 'counts', etc.) (Def: 'eflux')
;       ARCHIVE: uses archive data instead of survey
;       THLD_THETA: theta_v > thld_theta => +Z,
;                   theta_v < -thld_theta => -Z (Def: 45)
;       ATTVEC: generates tplot variables showing SWIA XYZ vectors in the specified frame
;       TRANGE: time range to compute directional spectra (Def: all)
; CREATED BY:
;       Yuki Harada on 2014-11-20
;
; $LastChangedBy: haraday $
; $LastChangedDate: 2015-01-16 12:50:20 -0800 (Fri, 16 Jan 2015) $
; $LastChangedRevision: 16664 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swia/mvn_swia_diret.pro $
;-

pro mvn_swia_diret, frame=frame, units=units, archive=archive, thld_theta=thld_theta, attvec=attvec, trange=trange, verbose=verbose

  common mvn_swia_data

  if not keyword_set(frame) then frame='MSO'
  if not keyword_set(units) then units='eflux'
  if keyword_set(archive) then time = swica.time_unix else time = swics.time_unix
  if keyword_set(thld_theta) then thld_theta = abs(thld_theta) else thld_theta = 45
  if keyword_set(trange) then begin
     idx = where(time ge trange[0] and time le trange[1], idx_cnt)
     if idx_cnt gt 0 then time = time[idx] else begin
        dprint,dlevel=1,verbose=verbose,'No data in the specified time range.'
        return
     endelse
  endif


  center_time = dblarr(n_elements(time))
  energy = fltarr(n_elements(time),48)

  eflux_pX = fltarr(n_elements(time),48)
  eflux_mX = fltarr(n_elements(time),48)
  eflux_pY = fltarr(n_elements(time),48)
  eflux_mY = fltarr(n_elements(time),48)
  eflux_pZ = fltarr(n_elements(time),48)
  eflux_mZ = fltarr(n_elements(time),48)

  pX_new = fltarr(n_elements(time),3)
  pY_new = fltarr(n_elements(time),3)
  pZ_new = fltarr(n_elements(time),3)

  for i=0ll,n_elements(time)-1 do begin ;- time loop
     if i mod 1000 eq 0 then dprint,dlevel=1,verbose=verbose,i,' /',n_elements(time)
     d = mvn_swia_get_3dc(time[i],archive=archive)
     d = conv_units(d,units)
     center_time[i] = (d.time+d.end_time)/2.d
     energy[i,*] = d.energy[*,0]
     sphere_to_cart,1.,d.theta,d.phi,vx,vy,vz

     q = spice_body_att('MAVEN_SWIA',frame,center_time[i], $ 
                        /quaternion,check_object='MAVEN_SPACECRAFT', $
                        verbose=-1)

     t2 =   q[0]*q[1]           ;- cf. quaternion_rotation.pro
     t3 =   q[0]*q[2]
     t4 =   q[0]*q[3]
     t5 =  -q[1]*q[1]
     t6 =   q[1]*q[2]
     t7 =   q[1]*q[3]
     t8 =  -q[2]*q[2]
     t9 =   q[2]*q[3]
     t10 = -q[3]*q[3]

     vxnew = 2*( (t8 + t10)*vx + (t6 -  t4)*vy + (t3 + t7)*vz ) + vx
     vynew = 2*( (t4 +  t6)*vx + (t5 + t10)*vy + (t9 - t2)*vz ) + vy
     vznew = 2*( (t7 -  t3)*vx + (t2 +  t9)*vy + (t5 + t8)*vz ) + vz

     thetanew = 90. - acos(vznew)*!radeg
     phinew = atan(vynew,vxnew)*!radeg

     if keyword_set(attvec) then begin
        pX_new[i,0] = 2*( (t8 + t10)*1. + (t6 -  t4)*0. + (t3 + t7)*0. ) + 1.
        pX_new[i,1] = 2*( (t4 +  t6)*1. + (t5 + t10)*0. + (t9 - t2)*0. ) + 0.
        pX_new[i,2] = 2*( (t7 -  t3)*1. + (t2 +  t9)*0. + (t5 + t8)*0. ) + 0.
        pY_new[i,0] = 2*( (t8 + t10)*0. + (t6 -  t4)*1. + (t3 + t7)*0. ) + 0.
        pY_new[i,1] = 2*( (t4 +  t6)*0. + (t5 + t10)*1. + (t9 - t2)*0. ) + 1.
        pY_new[i,2] = 2*( (t7 -  t3)*0. + (t2 +  t9)*1. + (t5 + t8)*0. ) + 0.
        pZ_new[i,0] = 2*( (t8 + t10)*0. + (t6 -  t4)*0. + (t3 + t7)*1. ) + 0.
        pZ_new[i,1] = 2*( (t4 +  t6)*0. + (t5 + t10)*0. + (t9 - t2)*1. ) + 0.
        pZ_new[i,2] = 2*( (t7 -  t3)*0. + (t2 +  t9)*0. + (t5 + t8)*1. ) + 1.
     endif


     idx = where( abs(thetanew) le thld_theta $ ;- +X
                  and abs(phinew) le 45, idx_cnt )
     if idx_cnt gt 0 then begin
        w = d.data * 0.
        w[idx] = 1.
        if strlowcase(units) ne 'counts' then $
           eflux_pX[i,*] = total(d.data*d.domega*w,2)/total(d.domega*w,2) $
        else $
           eflux_pX[i,j] = total(d.data*w,2)
     endif else eflux_pX[i,*] = !values.f_nan

     idx = where( abs(thetanew) le thld_theta $ ;- -X
                  and abs(phinew) ge 135, idx_cnt )
     if idx_cnt gt 0 then begin
        w = d.data * 0.
        w[idx] = 1.
        if strlowcase(units) ne 'counts' then $
           eflux_mX[i,*] = total(d.data*d.domega*w,2)/total(d.domega*w,2) $
        else $
           eflux_mX[i,*] = total(d.data*w,2)
     endif else eflux_mX[i,*] = !values.f_nan

     idx = where( abs(thetanew) le thld_theta $ ;- +Y
                  and phinew gt 45 and phinew lt 135, idx_cnt )
     if idx_cnt gt 0 then begin
        w = d.data * 0.
        w[idx] = 1.
        if strlowcase(units) ne 'counts' then $
           eflux_pY[i,*] = total(d.data*d.domega*w,2)/total(d.domega*w,2) $
        else $
           eflux_pY[i,*] = total(d.data*w,2)
     endif else eflux_pY[i,*] = !values.f_nan

     idx = where( abs(thetanew) le thld_theta $ ;- -Y
                  and phinew gt -135 and phinew lt -45, idx_cnt )
     if idx_cnt gt 0 then begin
        w = d.data * 0.
        w[idx] = 1.
        if strlowcase(units) ne 'counts' then $
           eflux_mY[i,*] = total(d.data*d.domega*w,2)/total(d.domega*w,2) $
        else $
           eflux_mY[i,*] = total(d.data*w,2)
     endif else eflux_mY[i,*] = !values.f_nan

     idx = where( thetanew gt thld_theta, idx_cnt ) ;- +Z
     if idx_cnt gt 0 then begin
        w = d.data * 0.
        w[idx] = 1.
        if strlowcase(units) ne 'counts' then $
           eflux_pZ[i,*] = total(d.data*d.domega*w,2)/total(d.domega*w,2) $
        else $
           eflux_pZ[i,*] = total(d.data*w,2)
     endif else eflux_pZ[i,*] = !values.f_nan

     idx = where( thetanew lt -thld_theta, idx_cnt ) ;- -Z
     if idx_cnt gt 0 then begin
        w = d.data * 0.
        w[idx] = 1.
        if strlowcase(units) ne 'counts' then $
           eflux_mZ[i,*] = total(d.data*d.domega*w,2)/total(d.domega*w,2) $
        else $
           eflux_mZ[i,*] = total(d.data*w,2)
     endif else eflux_mZ[i,*] = !values.f_nan

  endfor                        ;- time loop end


  if keyword_set(archive) then type = 'swica' else type = 'swics'

  store_data,'mvn_'+type+'_en_'+units+'_'+frame+'_pX', $
             data={x:center_time,y:eflux_pX,v:energy}, $
             dlim={spec:1,zlog:1,ylog:1,yrange:minmax(energy),ystyle:1, $
                   ytitle:type+'!c'+frame+' +X!cEnergy [eV]', $
                   ztitle:units,datagap:180},verbose=verbose
  store_data,'mvn_'+type+'_en_'+units+'_'+frame+'_mX', $
             data={x:center_time,y:eflux_mX,v:energy}, $
             dlim={spec:1,zlog:1,ylog:1,yrange:minmax(energy),ystyle:1, $
                   ytitle:type+'!c'+frame+' -X!cEnergy [eV]', $
                   ztitle:units,datagap:180},verbose=verbose
  store_data,'mvn_'+type+'_en_'+units+'_'+frame+'_pY', $
             data={x:center_time,y:eflux_pY,v:energy}, $
             dlim={spec:1,zlog:1,ylog:1,yrange:minmax(energy),ystyle:1, $
                   ytitle:type+'!c'+frame+' +Y!cEnergy [eV]', $
                   ztitle:units,datagap:180},verbose=verbose
  store_data,'mvn_'+type+'_en_'+units+'_'+frame+'_mY', $
             data={x:center_time,y:eflux_mY,v:energy}, $
             dlim={spec:1,zlog:1,ylog:1,yrange:minmax(energy),ystyle:1, $
                   ytitle:type+'!c'+frame+' -Y!cEnergy [eV]', $
                   ztitle:units,datagap:180},verbose=verbose
  store_data,'mvn_'+type+'_en_'+units+'_'+frame+'_pZ', $
             data={x:center_time,y:eflux_pZ,v:energy}, $
             dlim={spec:1,zlog:1,ylog:1,yrange:minmax(energy),ystyle:1, $
                   ytitle:type+'!c'+frame+' +Z!cEnergy [eV]', $
                   ztitle:units,datagap:180},verbose=verbose
  store_data,'mvn_'+type+'_en_'+units+'_'+frame+'_mZ', $
             data={x:center_time,y:eflux_mZ,v:energy}, $
             dlim={spec:1,zlog:1,ylog:1,yrange:minmax(energy),ystyle:1, $
                   ytitle:type+'!c'+frame+' -Z!cEnergy [eV]', $
                   ztitle:units,datagap:180},verbose=verbose

  if keyword_set(attvec) then begin
     store_data,'mvn_'+type+'_'+frame+'_Xvec', $
                data={x:center_time,y:pX_new}, $
                dlim={yrange:[-2,2],ystyle:1,labflag:1, $
                      ytitle:'Xswia!c'+frame, $
                      labels:['x','y','z'],colors:'bgr'},verbose=verbose
     store_data,'mvn_'+type+'_'+frame+'_Yvec', $
                data={x:center_time,y:pY_new}, $
                dlim={yrange:[-2,2],ystyle:1,labflag:1, $
                      ytitle:'Yswia!c'+frame, $
                      labels:['x','y','z'],colors:'bgr'},verbose=verbose
     store_data,'mvn_'+type+'_'+frame+'_Zvec', $
                data={x:center_time,y:pZ_new}, $
                dlim={yrange:[-2,2],ystyle:1,labflag:1, $
                      ytitle:'Zswia!c'+frame, $
                      labels:['x','y','z'],colors:'bgr'},verbose=verbose
  endif

end
