pro thm_state_validate
    timespan,'2008-03-23',5,/days
    probe='a'
    thm_load_state,probe='a',/get_support
    tpsave='thm_state_validate'
    tplot_save,filename=tpsave,['tha_state_pos','tha_state_vel','tha_state_spinras','tha_state_spindec','tha_state_spinras_correction','tha_state_spindec_correction',$
        'tha_state_spinras_corrected','tha_state_spindec_corrected']
end