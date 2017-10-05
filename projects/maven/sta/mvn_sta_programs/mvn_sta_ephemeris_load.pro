;+
;PROCEDURE:   mvn_sta_ephemeris_load
;
;PURPOSE:
;  Load ephemeris and insert values into STATIC
;  common block structures. 
;
;USAGE:
;  mvn_mag_load_ql
;
;KEYWORDS:
;  frame:       Mag data frame of reference (currently STATIC)
;  verbose:     Display information.




pro mvn_sta_ephemeris_load,frame=frame,verbose=verbose

  

  if keyword_set(verbose) then print, 'Loading STATIC Ephemeris...'
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
  ;Davin's SPICE routines                                                 
  trange=timerange()
  mk = mvn_spice_kernels(/all,/load,trange=trange)


  ;-------------------------------------------------------------------------
  ;Load ephemeris and create tplot structures
  for api=0, nn_apid-1 do begin
     temp=execute('nn1=size(mvn_'+apid[api]+'_dat,/type)')
     if nn1 eq 8 then begin        
        temp=execute('tt=tag_names(mvn_'+apid[api]+'_dat)')
        temp=where(tt eq 'POS_SC_MSO' or $
                   tt eq 'QUAT_SC' or $
                   tt eq 'QUAT_MSO',nn2)
        if nn2 eq 3 then begin
           temp=execute('utc=time_string(mvn_'+apid[api]+'_dat.time)')
           ;cspice_str2et, utc,et
           pos=spice_body_pos('MAVEN','MARS',frame='MSO',$
                              utc=utc,check_objects='MAVEN_SPACECRAFT') 
           quat_sc =spice_body_att('MAVEN_STATIC','MAVEN_SPACECRAFT',$
                                   utc,/quaternion,check_objects='MAVEN_SPACECRAFT') 
           quat_mso=spice_body_att('MAVEN_STATIC','MAVEN_MSO',$
                                   utc,/quaternion,check_objects='MAVEN_SPACECRAFT') 
           temp1=execute('mvn_'+apid[api]+'_dat.QUAT_SC    = transpose(quat_sc)')
           temp2=execute('mvn_'+apid[api]+'_dat.QUAT_MSO   = transpose(quat_mso)')
           temp3=execute('mvn_'+apid[api]+'_dat.POS_SC_MSO = transpose(pos)')
           if temp1 eq 0 or temp2 eq 0 or temp3 eq 0 then stop, 'Wrong array dimensions.'
        endif
     endif
  endfor


  ;-------------------------------------------------------------------------
  ;Clear kernels
;  cspice_kclear
  mvn_spc_clear_spice_kernels   ;changed to allow correct clearing of SCLK kernel flag, jmm, 2015-03-16

end


