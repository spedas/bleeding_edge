;+
; Make L2 vsvy-hires v02 data from v01.
;
; v01 CDFs are from rbsp_efw_make_l2_vsvy_hires.
; v01 CDFs have two formats. They are unified in v02.
; v02 CDFs have the same format (data, support_data, metadata).
;-

pro phasef_make_l2_vsvy_hires_v02_cdf

    the_usrhost = susrhost()
    default_usrhost = 'kersten@xwaves7.space.umn.edu'
    if the_usrhost ne default_usrhost then message, 'This routine only works on '+default_usrhost

    data_types = ['vsvy-hires']
    delete_unused_var = 1
    delete_unwanted_var = 1
    phasef_coerce_l2_labeling, probes, $
        data_types=data_types, $
        delete_unused_var=delete_unused_var, $
        delete_unwanted_var=delete_unwanted_var

end


phasef_make_l2_vsvy_hires_v02_cdf
end
