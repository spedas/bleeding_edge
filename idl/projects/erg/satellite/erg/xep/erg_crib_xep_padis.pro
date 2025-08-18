pro erg_crib_xep_padis


    ; initialize
    erg_init

    ;road_data
    timespan,'2017-03-24',1,/day
    erg_load_xep,datatype='2dflux'
    erg_load_mgf

    get_data,'erg_xep_l2_FEDU_SSD',data=d

    tname_flux='erg_xep_l2_FEDU_SSD'
    tname_mag_dsi='erg_mgf_l2_mag_8sec_dsi'
    erg_xep_padis, tname_flux, tname_mag_dsi, dpa=20.,/count
    tplot,'erg_xep_l2_FEDU_SSD_pad_sv0?'
    tplot,'erg_xep_l2_FEDU_SSD_pad_pabin0?'
    tplot,'erg_xep_l2_FEDU_SSD_dcount_sv0?'
    tplot,'erg_xep_l2_FEDU_SSD_dcount_pabin0?'
end
