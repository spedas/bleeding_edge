pro mvn_sep_crib,trange=trange

;load spice data
;

mvn_spice_load,trange=trange

mvn_sep_load,trange=trange

store_data,'sep1',data=mvn_sep_get_anc_data(1,trange=trange,dlimit=dl,res=20),dlimit=dl
store_data,'sep2',data=mvn_sep_get_anc_data(2,trange=trange,dlimit=dl,res=20),dlimit=dl
store_data,'SEP_sun_angle',data= 'sep*_SUN_ANGLE'
store_data,'SEP_mars_angle',data='sep?.?_MARS_ANGLE',dlim={yrange:[0.,180],ystyle:1}

mvn_mag_load,trange=trange

mvn_swia_load_l2_data,/loadmom,/loadspec,/tplot,/eflux, trange=trange
xyz_to_polar,'mvn_swim_velocity_mso',/ph_0_360

mvn_sta_tplot_restore,trange=trange

end
