;+
;
;PROCEDURE:   mvn_sta_mag_load
;
;PURPOSE:
;  Load Magnetometer data and insert values into STATIC
;  common block structures. Also creates tplot variables.
;
;USAGE:
;  mvn_sta_mag_load
;
;KEYWORDS:       
;  frame:       Mag data frame of reference (currently STATIC)
;  verbose:     Display information.
;
;LAST MODIFICATION:
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2019-09-16 12:19:40 -0700 (Mon, 16 Sep 2019) $
; $LastChangedRevision: 27759 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/sta/mvn_sta_programs/mvn_sta_mag_load.pro $
;
;-
pro mvn_sta_mag_load, frame=frame, verbose=verbose,  tplot=tplot

  IF keyword_set(verbose) THEN v = verbose ELSE v = 0
  dprint, 'Loading Magnetometer Data...', dlevel=1, verbose=v
  if ~keyword_set(frame) then frame='MAVEN_STATIC'


  ;-------------------------------------------------------------------------
  ;Declare all the common block arrays
  common mvn_2a,mvn_2a_ind,mvn_2a_dat 
  common mvn_c0,mvn_c0_ind,mvn_c0_dat
  common mvn_c2,mvn_c2_ind,mvn_c2_dat
  common mvn_c4,mvn_c4_ind,mvn_c4_dat
  common mvn_c6,mvn_c6_ind,mvn_c6_dat
  common mvn_c8,mvn_c8_ind,mvn_c8_dat
  common mvn_ca,mvn_ca_ind,mvn_ca_dat
  common mvn_cc,mvn_cc_ind,mvn_cc_dat
  common mvn_cd,mvn_cd_ind,mvn_cd_dat
  common mvn_ce,mvn_ce_ind,mvn_ce_dat
  common mvn_cf,mvn_cf_ind,mvn_cf_dat
  common mvn_d0,mvn_d0_ind,mvn_d0_dat
  common mvn_d1,mvn_d1_ind,mvn_d1_dat
  common mvn_d2,mvn_d2_ind,mvn_d2_dat
  common mvn_d3,mvn_d3_ind,mvn_d3_dat
  common mvn_d4,mvn_d4_ind,mvn_d4_dat
  common mvn_d6,mvn_d6_ind,mvn_d6_dat
  common mvn_d7,mvn_d7_ind,mvn_d7_dat
  common mvn_d8,mvn_d8_ind,mvn_d8_dat
  common mvn_d9,mvn_d9_ind,mvn_d9_dat
  common mvn_da,mvn_da_ind,mvn_da_dat
  common mvn_db,mvn_db_ind,mvn_db_dat

  apid=['2a','c0','c2','c4','c6','c8',$
        'ca','cc','cd','ce','cf','d0',$
        'd1','d2','d3','d4','d6','d7',$
        'd8','d9','da','db']
  nn_apid=n_elements(apid)


  ;-------------------------------------------------------------------------
  ;Load magnetometer data (mostly taken from Dave's mvn_mag_load_ql.pro)
  ;time -> unix time
  ;b[0] -> mag x in mag coordinates
  ;b[1] -> mag y in mag coordinates
  ;b[2] -> mag z in mag coordinates
  trange=timerange()
  if (size(trange,/type) eq 0) then begin
     print,"You must specify a file name or time range."
     return
  endif
  pathname = 'maven/data/sci/mag/l1/sav/1sec/YYYY/MM/mvn_mag_l1_pl_1sec_YYYYMMDD.sav'
  files = mvn_pfp_file_retrieve(pathname,/daily,trange=trange,source=source,verbose=verbose,/valid_only)
  nfiles = n_elements(files) * keyword_set(files)
  if nfiles eq 0 ||  keyword_set(download_only) then return;break
  str_all=0
  ind=0
  for i = 0, nfiles-1 do begin
     file = files[i]
     dprint,dlevel=2,verbose=verbose,'Restoring file: '+file
     restore,file,verbose= keyword_set(verbose) && verbose ge 3
     append_array,str_all,data,index=ind
  endfor
  append_array,str_all,index=ind
  time=str_all.time
  magf=transpose(str_all.vec)

  ;----------------------------------------------------------
  ;Trim data to requested time range
  if (size(tmin,/type) eq 5) then begin
    indx = where((time ge tmin) and (time le tmax), count)
    if (count gt 0L) then begin
      time = time[indx]
      magf = magf[indx,*]
   endif else begin
      print,"No MAG data within requested time range."
      return
   endelse
  endif


  ;-------------------------------------------------------------------------
  ;Smooth using a 4 second bin
  bb=magf*0.D
  bb[*,0]=smooth_in_time(magf[*,0],time,4)
  bb[*,1]=smooth_in_time(magf[*,1],time,4)
  bb[*,2]=smooth_in_time(magf[*,2],time,4)
  magf=bb

  ;-------------------------------------------------------------------------
  ;Davin's SPICE Routines to convert from mag to sta (frame of reference). 
  mk = mvn_spice_kernels(/all,/load,trange=trange,verbose=verbose)
  utc=time_string(time)
  for api=0, nn_apid-1 do begin
     temp=execute('nn1=size(mvn_'+apid[api]+'_dat,/type)')
     if nn1 ne 0 then begin
        temp=execute('tags=tag_names(mvn_'+apid[api]+'_dat)')
        pp=where(tags eq 'POS_SC_MSO' or $
                 tags eq 'MAGF',cc)
        if cc eq 2 then begin
           temp=execute('start_time=time_string(mvn_'+apid[api]+'_dat.time)')
           temp=execute('end_time=time_string(mvn_'+apid[api]+'_dat.end_time)')
           nn=n_elements(start_time)
           apid_time=(time_double(start_time) + time_double(end_time))/2D
           xx=interpol(magf[*,0],time,apid_time)
           yy=interpol(magf[*,1],time,apid_time)
           zz=interpol(magf[*,2],time,apid_time)
           vec=transpose([[xx],[yy],[zz]])
           newvec=spice_vector_rotate(vec,apid_time,$
                                      'MAVEN_SPACECRAFT',$
                                      'MAVEN_STATIC',$
                                      check_objects='MAVEN_SPACECRAFT', verbose=verbose)
           vec=transpose(newvec)
           temp=execute('mvn_'+apid[api]+'_dat.magf[*,0]=vec[*,0]')
           temp=execute('mvn_'+apid[api]+'_dat.magf[*,1]=vec[*,1]')
           temp=execute('mvn_'+apid[api]+'_dat.magf[*,2]=vec[*,2]')
           if apid[api] eq 'c6' then begin
              time_sta_c6=apid_time
              magf_sta_c6=vec
              cspice_recsph, transpose(magf_sta_c6), r, phi, theta
           endif
        endif
     endif
  endfor
  
  
  ;-------------------------------------------------------------------------
  ;Clear kernels
;  cspice_kclear
  mvn_spc_clear_spice_kernels   ;changed to allow correct clearing of SCLK kernel flag, jmm, 2015-03-16


  ;-------------------------------------------------------------------------
  ;Tplot  
  if keyword_set(tplot) then begin
     var = 'mvn_mag1_sta_phi'
     store_data,var,data={x:time_sta_c6, y:phi, labels:['phi'], $
                          labflag:1}, limits = {SPICE_FRAME:'MAVEN_STATIC', $
                                                SPICE_MASTER_FRAME:'MAVEN_SPACECRAFT'}
     
     var = 'mvn_mag1_sta_theta'
     store_data,var,data={x:time_sta_c6, y:theta, labels:['theta'], $
                          labflag:1}, limits = {SPICE_FRAME:'MAVEN_STATIC', $
                                                SPICE_MASTER_FRAME:'MAVEN_SPACECRAFT'}

     var = 'mvn_mag1_pl_full'
     store_data,var,data={x:time, y:magf, v:[0,1,2], labels:['X','Y','Z'], $
                          labflag:1}, limits = {SPICE_FRAME:'MAVEN_SPACECRAFT', $
                                                SPICE_MASTER_FRAME:'MAVEN_SPACECRAFT'}
     
     var = 'mvn_mag1_sta_ql'
     store_data,var,data={x:time_sta_c6, y:magf_sta_c6, v:[0,1,2], labels:['X','Y','Z'],$
                          labflag:1}, limits = {SPICE_FRAME:'MAVEN_STATIC', $
                                                SPICE_MASTER_FRAME:'MAVEN_SPACECRAFT'}
     
  endif
  


end


