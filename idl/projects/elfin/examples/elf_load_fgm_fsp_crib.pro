pro elf_load_fgm_fsp_crib
;
  ;;    ============================
  ;;   Select date and time interval
  ;;    ============================
  elf_init
  tplot_options, 'xmargin', [18,8]
  tplot_options, 'ymargin', [5,8]
  ;cwdirname='C:\My Documents\ucla\Elfin\MAG\CAL_12_params\FSP_Science_Product\second_data_set_released' ; your directory here, if other than default IDL dir 
  ;cwd,cwdirname
  my101=[1,0,1]
  ;
  tstart='2022-01-12/15:45:51'
  tend='2022-01-12/15:52:04'

  ;tstart='2022-01-14/17:17:52'
  ;tend='2022-01-14/17:24:03'
  
  ;tstart='2022-01-14/17:30:15'
  ;tend='2022-01-14/17:36:28'
  
  ;tstart='2022-01-14/18:49:45'
  ;tend='2022-01-14/18:55:58'
  
  ;tstart='2022-01-15/21:07:50'
  ;tend='2022-01-15/21:14:01'
  
  time2plot=[tstart,tend]
  timeduration=time_double(tend)-time_double(tstart)
  timespan,tstart,timeduration,/seconds ; set the analysis time interval
  sclet='a'
  ;;    ============================
  ;;     read calibrated fgm data (this part will be replaced by elf_load_fgm.pro)
  ;;    ============================
  ; read elx_fgs_fsp_dmxl 
  ;filename=strmid(tstart,0,4)+strmid(tstart,5,2)+strmid(tstart,8,2)+'_'+strmid(tstart,11,2)+strmid(tstart,14,2)+'_'+strmid(tend,11,2)+strmid(tend,14,2)
  ;ascii2tplot, files=filename+'_ela_fgs_fsp_dmxl.txt', format_type=0, $
  ;  tformat='YYYY-MM-DD/hh:mm:ss', tvar_column=[0,1,2],$
  ;  tvarnames='elx_fgs_fsp_dmxl', delimiter=' '
  elf_load_fgm, probe='a', trange=['2022-01-12','2022-01-13'], datatype='fgs', /get_support_data
stop
  copy_data, 'ela_fgs_fsp_res_dmxl', 'elx_fgs_fsp_res_dmxl'
  copy_data, 'ela_fgs_fsp_res_gei', 'elx_fgs_fsp_res_gei'
  copy_data, 'ela_fgs_fsp_igrf_dmxl', 'elx_fgs_fsp_igrf_dmxl'
  copy_data, 'ela_fgs_fsp_igrf_gei', 'elx_fgs_fsp_igrf_gei'
  options,'elx_fgs_fsp_res_dmxl',spec=0, colors=['b','g','r'],labels=['x','y','z'],labflag=1
  options,'elx_fgs_fsp_igrf_dmxl',spec=0, colors=['b','g','r'],labels=['x','y','z'],labflag=1
  options,'elx_fgs_fsp_res_gei',spec=0, colors=['b','g','r'],labels=['x','y','z'],labflag=1
  options,'elx_fgs_fsp_igrf_gei',spec=0, colors=['b','g','r'],labels=['x','y','z'],labflag=1

  ;;    ============================
  ;;     calculated residual field
  ;;    ============================
  ;calc," 'elx_fgs_res_dmxl' ='elx_fgs_fsp_dmxl' - 'elx_fgs_fsp_igrf_dmxl' "
  tplot,'elx_fgs_fsp_igrf_dmxl elx_fgs_fsp_res_dmxl'
  pngfile=!elf.local_data_dir+'el'+sclet+'/tplot_1'
  makepng, pngfile
  stop
  
;  calc," 'elx_fgs_res_gei' ='elx_fgs_fsp_gei' - 'elx_fgs_fsp_igrf_gei' "
  tplot, 'elx_fgs_fsp_igrf_gei elx_fgs_fsp_res_gei'
  stop
  
;  tplot,'elx_fgs_fsp_res_gei elx_fgs_fsp_igrf_gei' 
;  stop
  ;
  ; here transform B (both FSP and IGRF) from gei into SM, then take difference
  ; to get residual, then plot it in NDW which is (-Bph, -Br, Bth) in the satellite-centered SM system.
  ; 
  ; first load position (and attitude, though attitude is not needed)
  elf_load_state,probe=sclet ; get position (and attitude) info
  tinterpol_mxn,'el'+sclet+'_pos_gei','elx_fgs_fsp_res_dmxl',newname='elx_pos_gei' ; get same times as for actual data
  tinterpol_mxn,'el'+sclet+'_att_gei','elx_fgs_fsp_res_dmxl',newname='elx_att_gei' ; get same times as for actual data
  tnormalize,'elx_att_gei',newname='elx_att_gei_norm'
  copy_data,'elx_att_gei_norm','elx_att_gei'
  cotrans,'elx_pos_gei','elx_pos_gse',/GEI2GSE
  cotrans,'elx_pos_gse','elx_pos_gsm',/GSE2GSM
  cotrans,'elx_pos_gsm','elx_pos_sm',/GSM2SM ; in SM now! Phew!
  ;
  ; ensure coords='gei' else bombs
  get_data,'elx_fgs_fsp_res_gei',data=my_elx_fgs_fsp_gei,dl=my_dl_elx_fgs_fsp_gei,lim=my_lim_elx_fgs_fsp_gei 
  my_dl_elx_fgs_fsp_gei.data_att.coord_sys = 'gei'
;  my_dl_elx_fgs_fsp_gei.data_att.units = 'nT'
  store_data,'elx_fgs_fsp_res_gei',data=my_elx_fgs_fsp_gei,dl=my_dl_elx_fgs_fsp_gei,lim=my_lim_elx_fgs_fsp_gei
  ;
  ; cotrans fgs_fsp into SM now
  cotrans,'elx_fgs_fsp_res_gei','elx_fgs_fsp_res_gse',/GEI2GSE
  cotrans,'elx_fgs_fsp_res_gse','elx_fgs_fsp_res_gsm',/GSE2GSM
  cotrans,'elx_fgs_fsp_res_gsm','elx_fgs_fsp_res_sm',/GSM2SM ; in SM now! Phew!
  ;
  ; ensure coords='gei' else bombs
  get_data,'elx_fgs_fsp_igrf_gei',data=my_elx_fgs_fsp_igrf_gei,dl=my_dl_elx_fgs_fsp_igrf_gei,lim=my_lim_elx_fgs_fsp_igrf_gei 
  my_dl_elx_fgs_fsp_igrf_gei.data_att.coord_sys = 'gei'
;  my_dl_elx_fgs_fsp_igrf_gei.data_att.units = 'nT'
  store_data,'elx_fgs_fsp_igrf_gei',data=my_elx_fgs_fsp_igrf_gei,dl=my_dl_elx_fgs_fsp_igrf_gei,lim=my_lim_elx_fgs_fsp_igrf_gei
  ;
  ; cotrans fgs_fsp into SM now
  cotrans,'elx_fgs_fsp_igrf_gei','elx_fgs_fsp_igrf_gse',/GEI2GSE
  cotrans,'elx_fgs_fsp_igrf_gse','elx_fgs_fsp_igrf_gsm',/GSE2GSM
  cotrans,'elx_fgs_fsp_igrf_gsm','elx_fgs_fsp_igrf_sm',/GSM2SM ; in SM now! Phew!
  ;
  ; take the difference to find residual
  ;calc," 'elx_fgs_fsp_res_sm'='elx_fgs_fsp_sm'-'elx_fgs_fsp_igrf_sm' "
  tplot,'elx_fgs_fsp_res_gei elx_fgs_fsp_igrf_gei'
  pngfile=!elf.local_data_dir+'el'+sclet+'/tplot_2'
  makepng, pngfile
  stop
  ;
  ;
  xyz_to_polar,'elx_pos_sm',/co_latitude
  calc," 'elx_pos_sm_mlat' = 90.-'elx_pos_sm_th' "
  get_data,'elx_pos_sm_th',data=elx_pos_sm_th,dlim=myposdlim,lim=myposlim
  get_data,'elx_pos_sm_phi',data=elx_pos_sm_phi
  calc," 'elx_pos_sm_mlt' = ('elx_pos_sm_phi' + 180. mod 360. ) / 15. "
  csth=cos(!PI*elx_pos_sm_th.y/180.)
  csph=cos(!PI*elx_pos_sm_phi.y/180.)
  snth=sin(!PI*elx_pos_sm_th.y/180.)
  snph=sin(!PI*elx_pos_sm_phi.y/180.)
  rot2rthph=[[[snth*csph],[csth*csph],[-snph]],[[snth*snph],[csth*snph],[csph]],[[csth],[-snth],[0.*csth]]]
  store_data,'rot2rthph',data={x:elx_pos_sm_th.x,y:rot2rthph},dlim=myposdlim,lim=myposlim
  tvector_rotate,'rot2rthph','elx_fgs_fsp_res_sm',newname='elx_fgs_fsp_res_sm_sph'
  ;tvector_rotate,'rot2rthph','elx_fgs_fsp_sm',newname='elx_fgs_fsp_sm_sph'
  tvector_rotate,'rot2rthph','elx_fgs_fsp_igrf_sm',newname='elx_fgs_fsp_igrf_sm_sph'
  ;rotSMSPH2NED=[[[snth*0.],[snth*0.],[snth*0.-1.]],[[snth*0.-1.],[snth*0.],[snth*0.]],[[snth*0.],[snth*0.+1.],[snth*0.]]]
  ; here use a new system, spherical coord's satellite centered, NDW: N= north (spherical -theta, positive north), D=radial down (spherical -r), W=west (spherical -phi)
  rotSMSPH2NDW=[[[snth*0.],[snth*0.-1],[snth*0.]],[[snth*0.-1.],[snth*0.],[snth*0.]],[[snth*0.],[snth*0.],[snth*0.-1]]]
  ;
  store_data,'rotSMSPH2NDW',data={x:elx_pos_sm_th.x,y:rotSMSPH2NDW},dlim=myposdlim,lim=myposlim
  ;
  tvector_rotate,'rotSMSPH2NDW','elx_fgs_fsp_res_sm_sph',newname='elx_fgs_fsp_res_ndw' ; N= north (spherical -theta, positive north), D=radial down (spherical -r), W=west (spherical -phi)
  ;tvector_rotate,'rotSMSPH2NDW','elx_fgs_fsp_sm_sph',newname='elx_fgs_fsp_ndw' ; N= north (spherical -theta, positive north), D=radial down (spherical -r), W=west (spherical -phi)
  ;tvector_rotate,'rotSMSPH2NDW','elx_fgs_fsp_igrf_sm_sph',newname='elx_fgs_fsp_igrf_ndw' ; N= north (spherical -theta, positive north), D=radial down (spherical -r), W=west (spherical -phi)
  ;
  options,'elx_fgs_fsp_res_ndw',spec=0, colors=['b','g','r'],labels=['N','D','W'],labflag=1, ytitle='elx_fgs_fsp_res_sm_NDW'
  options,'elx_fgs_*','databar',0.
  options,'elx_fgs_*',colors=['b','g','r']
  ;
  tplot,'elx_fgs_fsp_res_dmxl elx_fgs_fsp_res_sm elx_fgs_fsp_res_ndw'
  tplot_apply_databar
  pngfile=!elf.local_data_dir+'el'+sclet+'/tplot_3'
  makepng, pngfile
  stop
  ;
  ; Here rotate to FAC (obw) system, where b is along model field,
  ;                                        o is normal to b but outwards from Earth
  ;                                        w is normal to b but westward: w = (rxb)/|rxb|, where r is satellite position
  ; Procedure: get b first by normalizing the model field (IGRF)
  ;            then get w = (rxb)/|rxb|
  ;            then get o = bxw
  ;
  tnormalize,'elx_fgs_fsp_igrf_gei',newname='elx_fgs_fsp_igrf_gei_norm'
  tnormalize,'elx_pos_gei',newname='elx_pos_gei_norm'
  tcrossp,'elx_pos_gei_norm','elx_fgs_fsp_igrf_gei_norm',newname='BperpWest'
  tnormalize,'BperpWest',newname='BperpWest_norm'
  tcrossp,'elx_fgs_fsp_igrf_gei_norm','BperpWest_norm',newname='BperpOut'
  tnormalize,'BperpOut',newname='BperpOut_norm'
  ;
  get_data,'elx_fgs_fsp_igrf_gei_norm',data=elx_fgs_fsp_igrf_gei_norm,dlim=my_dl_elx_fgs_fsp_igrf_gei_norm,lim=my_lim_elx_fgs_fsp_igrf_gei_norm
  get_data,'BperpOut_norm',data=BperpOut_norm
  get_data,'BperpWest_norm',data=BperpWest_norm
  gei2obw=[[[BperpOut_norm.y[*,0]],[elx_fgs_fsp_igrf_gei_norm.y[*,0]],[BperpWest_norm.y[*,0]]],$
           [[BperpOut_norm.y[*,1]],[elx_fgs_fsp_igrf_gei_norm.y[*,1]],[BperpWest_norm.y[*,1]]],$
           [[BperpOut_norm.y[*,2]],[elx_fgs_fsp_igrf_gei_norm.y[*,2]],[BperpWest_norm.y[*,2]]]]
  store_data,'rotgei2obw',data={x:elx_fgs_fsp_igrf_gei_norm.x,y:gei2obw},dlim=my_dl_elx_fgs_fsp_igrf_gei_norm,lim=my_lim_elx_fgs_fsp_igrf_gei_norm
  ;
  tvector_rotate,'rotgei2obw','elx_fgs_fsp_igrf_gei',newname='elx_fgs_fsp_igrf_obw' 
  tvector_rotate,'rotgei2obw','elx_fgs_fsp_res_gei',newname='elx_fgs_fsp_res_obw'
  ;calc," 'elx_fgs_fsp_res_obw' = 'elx_fgs_fsp_obw'-'elx_fgs_fsp_igrf_obw' "
  options,'elx_fgs_fsp_res_obw',spec=0, colors=['b','g','r'],labels=['o','b','w'],labflag=1, ytitle='elx_fgs_fsp_res_obw'
  ;options,'elx_fgs_fsp_res_obw',spec=0, colors=['b','g','r'],labels=['o','b','w'],labflag=1, ytitle='elx_fgs_fsp_obw'
  options,'elx_fgs_fsp_igrf_obw',spec=0, colors=['b','g','r'],labels=['o','b','w'],labflag=1, ytitle='elx_fgs_fsp_igrf_obw'
  options,'elx_fgs_*','databar',0.
  ;
  tplot,'elx_fgs_fsp_res_dmxl elx_fgs_fsp_res_ndw elx_fgs_fsp_res_obw'
  tplot_apply_databar
  ; 
  ; plot again but zero-out the DMXL-Y, NDW-D and obw-b components
  ;
  ;calc, " 'elx_fgs_res_dmxly0' = ((total('elx_fgs_res_dmxl'^2,2)*0.+1.)#my101)*'elx_fgs_res_dmxl' "
  ;options,'elx_fgs_res_dmxly0',spec=0, colors=['b','g','r'],labels=['x','y=0','z'],labflag=1, ytitle='elx_fgs_res_dmxly0'
  ;options,'elx_fgs_res_dmxly0','databar',0.
  ;
  ;calc, " 'elx_fgs_fsp_res_ob0w' = ((total('elx_fgs_fsp_res_obw'^2,2)*0.+1.)#my101)*'elx_fgs_fsp_res_obw' "
  ;options,'elx_fgs_fsp_res_ob0w',spec=0, colors=['b','g','r'],labels=['o','b=0','w'],labflag=1, ytitle='elx_fgs_fsp_res_ob0w'
  ;options,'elx_fgs_fsp_res_ob0w','databar',0.
  ;
  ;calc, " 'elx_fgs_fsp_res_sm_ND0W' = ((total('elx_fgs_fsp_res_sm_NDW'^2,2)*0.+1.)#my101)*'elx_fgs_fsp_res_sm_NDW' "
  ;options,'elx_fgs_fsp_res_sm_ND0W',spec=0, colors=['b','g','r'],labels=['N','D=0','W'],labflag=1, ytitle='elx_fgs_fsp_res_sm_ND0W'
  ;options,'elx_fgs_fsp_res_sm_ND0W','databar',0.
  ;
  ;tplot,'elx_fgs_res_dmxly0 elx_fgs_fsp_res_sm_ND0W elx_fgs_fsp_res_ob0w'
  ;tplot_apply_databar
  ;

  print, 'Done'
  
end
