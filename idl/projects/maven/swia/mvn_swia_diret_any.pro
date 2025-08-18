;+
; PROCEDURE:
;       mvn_swia_dirEt
; PURPOSE:
;       Makes directional E-t spectrograms in the specified frame from SWIA Coarse data.
;       a tplot variable will be generated for only the specified phi
;       and theta bounds in the chosen coordinate frame.
; CALLING SEQUENCE:
;       mvn_swia_diret_any
; INPUTS:
;       None (SWIA data and SPICE kernels need to have been loaded)
; KEYWORDS:
;       all optional
;       FRAME: specifies the frame (Def: 'MSO')
;       UNITS: specifies the units ('eflux', 'counts', etc.) (Def: 'eflux')
;       ARCHIVE: uses archive data instead of survey
;       ATTVEC: generates tplot variables showing SWIA XYZ vectors in the specified frame
;       TRANGE: time range to compute directional spectra (Def: all)
;       THETA_bounds: polar angle range in degrees [MAX: 0 TO 180] over which data is wanted
;       (Def: 45 to 135)
;       PHI_bounds: azimuth angle range in degrees [MAX: 0 to 360] over which data is wanted
;       (Def: 315 to 45)
; CREATED BY:
;       Rob Lillis on 2016-06-22, modified from Yuki Harada's mvn_swia_dirEt
;
; $LastChangedBy: rlillis3 $
; $LastChangedDate: 2016-06-23 18:15:58 -0700 (Thu, 23 Jun 2016) $
; $LastChangedRevision: 21359 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swia/mvn_swia_diret_any.pro $
;-

pro mvn_swia_diret_any, frame=frame, units=units, archive=archive, attvec=attvec, trange=trange, verbose=verbose, theta_bounds = theta_bounds,phi_bounds = phi_bounds

  common mvn_swia_data

  if not keyword_set(frame) then frame='MSO'
  if not keyword_set(units) then units='eflux'
  if not keyword_set (theta_bounds) then theta_bounds = [45.0, 135.0]
  if not keyword_set (phi_bounds) then phi_bounds = [315,45.0]
  
; very important, change the bounds to the same coordinate system used
; by Yuki, i.e. latitude instead of co-latitude and longitude from
; -180 to 180
  theta_bounds_new = reverse (90.0 - theta_bounds)
  phi_bounds_new = convert_azimuth (phi_bounds)
  
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

  eflux = fltarr(n_elements(time),48)
 
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

; now find the indices where the angles are within the ranges we want
     if phi_bounds_new [0] gt phi_bounds_new [1] then idx = $
        where( (thetanew) ge theta_bounds_new[0] and $ 
               (thetanew) le theta_bounds_new[1] and $
               ((phinew) ge phi_bounds_new [0] or $
                (phinew) le phi_bounds_new [1]) , idx_cnt ) else idx = $
     where( (thetanew) ge theta_bounds_new[0] and $ 
               (thetanew) le theta_bounds_new[1] and $
               (phinew) ge phi_bounds_new [0] and $
                (phinew) le phi_bounds_new [1] , idx_cnt )
     
     if idx_cnt gt 0 then begin
        w = d.data * 0.
        w[idx] = 1.
        if strlowcase(units) ne 'counts' then $
           eflux[i,*] = total(d.data*d.domega*w,2)/total(d.domega*w,2) $
        else $
           eflux[i,j] = total(d.data*w,2)
     endif else eflux[i,*] = !values.f_nan

  endfor                        ;- time loop end


  if keyword_set(archive) then type = 'swica' else type = 'swics'

  store_data,'mvn_'+type+'_en_'+units+'_'+frame+'_theta'+roundst(theta_bounds[0]) +'_' + $
             roundst(theta_bounds[1])+'_phi'+roundst(phi_bounds[0]) +'_' + $
             roundst(phi_bounds[1]),$
             data={x:center_time,y:eflux,v:energy}, $
             dlim={spec:1,zlog:1,ylog:1,yrange:minmax(energy),ystyle:1, $
                   ytitle:type+'!c'+frame+'theta'+roundst(theta_bounds[0]) +'_' + $
             roundst(theta_bounds[1])+'!cphi'+roundst(phi_bounds[0]) +'_' + $
             roundst(phi_bounds[1])+'!cEnergy [eV]', $
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
