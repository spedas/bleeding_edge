pro thm_cotrans_validate
    start_time = time_double('2007-03-23')
    times = start_time + 60.0D * indgen(1440)
    timestruct=time_struct(times)
    time_count=n_elements(times)
    basis_x = dblarr(time_count,3)
    basis_y = dblarr(time_count,3)
    basis_z = dblarr(time_count,3)
    basis_x[*,0] = 1.0D
    basis_y[*,1] = 1.0D
    basis_z[*,2] = 1.0D
    store_data,'basis_x',data={x:times,y:basis_x}
    store_data,'basis_y',data={x:times,y:basis_y}
    store_data,'basis_z',data={x:times,y:basis_z}
    cotrans_lib
    subGEI2GSE,timestruct,basis_x,basis_x_gei2gse
    subGEI2GSE,timestruct,basis_y,basis_y_gei2gse
    subGEI2GSE,timestruct,basis_z,basis_z_gei2gse
    store_data,'basis_x_gei2gse',data={x:times,y:basis_x_gei2gse}
    store_data,'basis_y_gei2gse',data={x:times,y:basis_y_gei2gse}
    store_data,'basis_z_gei2gse',data={x:times,y:basis_z_gei2gse}
    
    subGSE2GEI,timestruct,basis_x,basis_x_gse2gei
    subGSE2GEI,timestruct,basis_y,basis_y_gse2gei
    subGSE2GEI,timestruct,basis_z,basis_z_gse2gei
    store_data,'basis_x_gse2gei',data={x:times,y:basis_x_gse2gei}
    store_data,'basis_y_gse2gei',data={x:times,y:basis_y_gse2gei}
    store_data,'basis_z_gse2gei',data={x:times,y:basis_z_gse2gei}
    
    thm_autoload_support,probe='a',trange=['2007-03-20','2007-03-30'],/spinaxis,/spinmodel
    smp=spinmodel_get_ptr('a',use_eclipse_corrections=1)
    dsl2gse,'basis_x','tha_state_spinras_corrected','tha_state_spindec_corrected','basis_x_dsl2gse',/ignore_dlimits
    dsl2gse,'basis_y','tha_state_spinras_corrected','tha_state_spindec_corrected','basis_y_dsl2gse',/ignore_dlimits
    dsl2gse,'basis_z','tha_state_spinras_corrected','tha_state_spindec_corrected','basis_z_dsl2gse',/ignore_dlimits

    dsl2gse,'basis_x','tha_state_spinras_corrected','tha_state_spindec_corrected','basis_x_gse2dsl',/gse2dsl,/ignore_dlimits
    dsl2gse,'basis_y','tha_state_spinras_corrected','tha_state_spindec_corrected','basis_y_gse2dsl',/gse2dsl,/ignore_dlimits
    dsl2gse,'basis_z','tha_state_spinras_corrected','tha_state_spindec_corrected','basis_z_gse2dsl',/gse2dsl,/ignore_dlimits
    
    ssl2dsl,name_in='basis_x',name_out='basis_x_ssl2dsl',spinmodel_ptr=smp,use_spinphase_correction=1,/ignore_dlimits
    ssl2dsl,name_in='basis_y',name_out='basis_y_ssl2dsl',spinmodel_ptr=smp,use_spinphase_correction=1,/ignore_dlimits
    ssl2dsl,name_in='basis_z',name_out='basis_z_ssl2dsl',spinmodel_ptr=smp,use_spinphase_correction=1,/ignore_dlimits
 
    ssl2dsl,name_in='basis_x',name_out='basis_x_dsl2ssl',spinmodel_ptr=smp,use_spinphase_correction=1,/ignore_dlimits,/dsl2ssl
    ssl2dsl,name_in='basis_y',name_out='basis_y_dsl2ssl',spinmodel_ptr=smp,use_spinphase_correction=1,/ignore_dlimits,/dsl2ssl
    ssl2dsl,name_in='basis_z',name_out='basis_z_dsl2ssl',spinmodel_ptr=smp,use_spinphase_correction=1,/ignore_dlimits,/dsl2ssl
    
    ; Test lunar transforms.  We'll use probe positions and velocities as input variables.
    
    timespan,'2007-03-23',7,/days
    thm_load_state,probe='a',datatype='pos_gse vel_gse'
    thm_autoload_support,vname='tha_state_pos_gse',/slp
    thm_load_fit,probe='a',level=2,coord='gse'
    
    ; Sun and moon positions are in GEI, get converted to GSE inside gse2sse
    gse2sse,'tha_state_pos_gse','slp_sun_pos','slp_lun_pos','tha_state_pos_sse'
    gse2sse,'tha_state_vel_gse','slp_sun_pos','slp_lun_pos','tha_state_vel_sse'
    gse2sse,'tha_state_pos_gse','slp_sun_pos','slp_lun_pos','tha_state_pos_sse_rotate_only',/rotation_only
    gse2sse,'tha_state_vel_gse','slp_sun_pos','slp_lun_pos','tha_state_vel_sse_rotate_only',/rotation_only
    gse2sse,'tha_fgs_gse','slp_sun_pos','slp_lun_pos','tha_fgs_sse'
    
    sse2sel,'tha_state_pos_sse','slp_sun_pos','slp_lun_pos','slp_lun_att_x','slp_lun_att_z','tha_state_pos_sel'
    sse2sel,'tha_state_vel_sse','slp_sun_pos','slp_lun_pos','slp_lun_att_x','slp_lun_att_z','tha_state_vel_sel'
    sse2sel,'tha_fgs_sse','slp_sun_pos','slp_lun_pos','slp_lun_att_x','slp_lun_att_z','tha_fgs_sel'
    
    ; Inverse transformations
    gse2sse,'tha_state_pos_sse','slp_sun_pos','slp_lun_pos','tha_state_pos_gse_sse_gse',/sse2gse
    gse2sse,'tha_state_vel_sse','slp_sun_pos','slp_lun_pos','tha_state_vel_gse_sse_gse',/sse2gse
    gse2sse,'tha_state_pos_sse_rotate_only','slp_sun_pos','slp_lun_pos','tha_state_pos_gse_sse_gse_rotate_only',/sse2gse,/rotation_only
    gse2sse,'tha_state_vel_sse_rotate_only','slp_sun_pos','slp_lun_pos','tha_state_vel_gse_sse_gse_rotate_only',/sse2gse,/rotation_only
    gse2sse,'tha_fgs_sse','slp_sun_pos','slp_lun_pos','tha_fgs_gse_sse_gse',/sse2gse
    
    sse2sel,'tha_state_pos_sel','slp_sun_pos','slp_lun_pos','slp_lun_att_x','slp_lun_att_z','tha_state_pos_gse_sel_sse',/sel2sse
    sse2sel,'tha_state_vel_sel','slp_sun_pos','slp_lun_pos','slp_lun_att_x','slp_lun_att_z','tha_state_vel_gse_sel_sse',/sel2sse

    tpfile='thm_cotrans_validate.cdf'
    tvars=['basis_x','basis_y','basis_z','basis_x_gei2gse','basis_y_gei2gse','basis_z_gei2gse',$
      'basis_x_gse2gei','basis_y_gse2gei','basis_z_gse2gei','basis_x_dsl2gse','basis_y_dsl2gse','basis_z_dsl2gse',$
      'basis_x_gse2dsl','basis_y_gse2dsl','basis_z_gse2dsl','basis_x_ssl2dsl','basis_y_ssl2dsl','basis_z_ssl2dsl',$
      'basis_x_dsl2ssl','basis_y_dsl2ssl','basis_z_dsl2ssl',$
      'tha_state_pos_gse','tha_state_vel_gse','tha_state_pos_sse','tha_state_vel_sse',$
      'tha_state_pos_gse_sse_gse','tha_state_vel_gse_sse_gse',$
      'tha_state_pos_sel','tha_state_pos_gse_sel_sse',$
      'sse_mat_cotrans','sel_mat_cotrans','sel_x_gei','sel_x_gse','sel_x_sse','sel_y_sse','sel_z_sse','tha_fgs_gse','tha_fgs_sse','tha_fgs_sel','tha_fgs_gse_sse_gse','tha_state_pos_sse_rotate_only',$
      'tha_state_vel_sse_rotate_only','tha_state_pos_gse_sse_gse_rotate_only','tha_state_vel_gse_sse_gse_rotate_only']
     ;tplot_save,filename='group1',['basis_x','basis_y','basis_z','basis_x_gei2gse','basis_y_gei2gse','basis_z_gei2gse']
     ;tplot_save,filename='group2',['basis_x_gse2gei','basis_y_gse2gei','basis_z_gse2gei','basis_x_dsl2gse','basis_y_dsl2gse','basis_z_dsl2gse']
     ;tplot_save,filename='group3',['basis_x_gse2dsl','basis_y_gse2dsl','basis_z_gse2dsl','basis_x_ssl2dsl','basis_y_ssl2dsl','basis_z_ssl2dsl']
     ;tplot_save,filename='group4',['basis_x_dsl2ssl','basis_y_dsl2ssl','basis_z_dsl2ssl']
     tplot2cdf,filename=tpfile,tvars=tvars,/default_cdf_structure
     ;tplot_save,filename='thm_cotrans_validate',tvars
end