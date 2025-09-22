pro minvar_python_validate

  ; Single rotation matrix output example
  tstart='2013/07/09 20:32'
  tduration=15 ; minutes
  tend=time_string(time_double(tstart)+tduration*60.)
  timespan,tstart,tduration,/minutes

  pival=!PI
  ;
  ; load FGM data
  ;

  del_data  
  trange_shock=['2013/07/09 20:39:10','2013/07/09 20:39:50']  
  thm_load_fgm,probe='b',level='l2',data='fgs',coord='gsm',/get_support,/time_clip
  tvectot,'thb_fgs_gsm',newname='thb_fgs_gsmt'
  ;tplot,'thb_fgs_gsmt'; but use 3-vector from now on: thb_fgs_gsm

  time_clip,'thb_fgs_gsm',trange_shock[0],trange_shock[1],newname='thb_fgs_gsm_shockclipped'
  ;
  mymvatrange1=time_double('2013/07/09 20:39:29')+[-11.,+11.] ; 20s of data or ~4 points (4s spin per.)!
  time_clip,'thb_fgs_gsm',mymvatrange1[0],mymvatrange1[1],newname='thb_fgs_gsm_mvaclipped1'
  ;
  minvar_matrix_make,'thb_fgs_gsm_mvaclipped1',evname='mva_vals',tminname='mva_min',tmidname='mva_int',tmaxname='mva_max' ; [16s]
  tvector_rotate,'thb_fgs_gsm_mvaclipped1_mva_mat','thb_fgs_gsm_mvaclipped1'
  tvector_rotate,'thb_fgs_gsm_mvaclipped1_mva_mat','thb_fgs_gsm_shockclipped' ; this gets rotated data in MVA coords i,j,k. Bk is Bn (minvar)


  test1_vars=['thb_fgs_gsm_mvaclipped1','thb_fgs_gsm_mvaclipped1_mva_mat', 'mva_vals', 'mva_min', 'mva_int', 'mva_max',$
    'thb_fgs_gsm_mvaclipped1_rot', 'thb_fgs_gsm_shockclipped_rot']
   
  del_data    
  ;
  ; An example with multiple output matrices
  
  tstart='2015/12/14 13:00'
  tduration=1 ; hours
  tend=time_string(time_double(tstart)+tduration*3600.)
  timespan,tstart,tduration,/hours
  trange=['2015/12/14 13:27','2015/12/14 13:29']
  trange_long=['2015/12/14 13:26','2015/12/14 13:30']
  pival=!PI
  ;
  ; load FGM data
  ;
  mms_load_fgm,probes='1',level='l2',data_rate='srvy',/get_support,/time_clip
  ;
  tsmooth2,'mms1_fgm_b_gsm_srvy_l2_bvec',1+2^6 ; new name is _sm
  calc," 'mms1_fgm_b_gsm_srvy_l2_bvec_hp' = 'mms1_fgm_b_gsm_srvy_l2_bvec' - 'mms1_fgm_b_gsm_srvy_l2_bvec_sm'
  tsmooth2,'mms1_fgm_b_gsm_srvy_l2_bvec_hp',5,newname='mms1_fgm_b_gsm_srvy_l2_bvec_bp'; new name is _bp

  tsmooth2,'mms1_fgm_b_gsm_srvy_l2_bvec',newname='mms1_fgm_b_gsm_srvy_l2_bvec_sm4minvar',1+2^7 ; new name is _sm4minvar [16s]
  calc," 'mms1_fgm_b_gsm_srvy_l2_bvec_hp4minvar' = 'mms1_fgm_b_gsm_srvy_l2_bvec' - 'mms1_fgm_b_gsm_srvy_l2_bvec_sm4minvar'
  minvar_matrix_make,'mms1_fgm_b_gsm_srvy_l2_bvec_hp4minvar',twindow=16.,tslide=4., $
    evname='mva_vals2',tminname='mva_min2',tmidname='mva_int2',tmaxname='mva_max2' ; [16s]
  tvector_rotate,'mms1_fgm_b_gsm_srvy_l2_bvec_hp4minvar_mva_mat','mms1_fgm_b_gsm_srvy_l2_bvec_bp'

  test2_vars = ['mms1_fgm_b_gsm_srvy_l2_bvec_hp4minvar', 'mms1_fgm_b_gsm_srvy_l2_bvec_hp4minvar_mva_mat', 'mms1_fgm_b_gsm_srvy_l2_bvec_bp', 'mva_vals2', 'mva_min2', 'mva_int2', 'mva_max2', $
    'mms1_fgm_b_gsm_srvy_l2_bvec_bp_rot']
    
   tplot_save,[test1_vars, test2_vars],filename='mva_python_validate'
end