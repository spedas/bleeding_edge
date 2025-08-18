pro erg_crib_mgf_spintone_rm


timespan,'2017-11-16/09:00:00',12,/h
erg_load_mgf,datatype='64hz',coord='dsi'

tdeflag,'erg_mgf_l2_mag_64hz_dsi',"remove_nan",/overwrite;remove nan
tinterpol,'erg_mgf_l2_spin_phase_64hz','erg_mgf_l2_mag_64hz_dsi';adjust time index

mag_data='erg_mgf_l2_mag_64hz_dsi'
sp_data='erg_mgf_l2_spin_phase_64hz_interp'

;remove spin tone
erg_mgf_spintone_rm,mag_data,sp_data,dt=600,/extrapolate

;make tplots
split_vec,'erg_mgf_l2_mag_64hz_dsi_clean_spt'
split_vec,'erg_mgf_l2_mag_64hz_dsi_spt'
split_vec,'erg_mgf_l2_mag_64hz_dsi'
store_data,'erg_mgf_l2_mag_64hz_dsi_x_comp',data=['erg_mgf_l2_mag_64hz_dsi_x','erg_mgf_l2_mag_64hz_dsi_clean_spt_x']
store_data,'erg_mgf_l2_mag_64hz_dsi_y_comp',data=['erg_mgf_l2_mag_64hz_dsi_y','erg_mgf_l2_mag_64hz_dsi_clean_spt_y']
options,'erg_mgf_l2_mag_64hz_dsi_?_comp',labflag=1,ynozero=1,ystyle=0,labels=['original','rm spin tone'],colors=[0,6]
options,'erg_mgf_l2_mag_64hz_dsi_spt_?',panel_size=0.6

window,xsize=1200,ysize=800
;example 1
tplot,['erg_mgf_l2_mag_64hz_dsi_?_comp','erg_mgf_l2_mag_64hz_dsi_spt_x','erg_mgf_l2_mag_64hz_dsi_spt_y'],trange=['2017-11-16/10:00:00','2017-11-16/11:00:00']
stop
;example 2
options,'erg_mgf_l2_mag_64hz_dsi_x_comp',yrange=[95,110];,
tplot,['erg_mgf_l2_mag_64hz_dsi_?_comp','erg_mgf_l2_mag_64hz_dsi_spt_x','erg_mgf_l2_mag_64hz_dsi_spt_y'],trange=['2017-11-16/10:00:00','2017-11-16/10:04:00']

;example 3
options,'erg_mgf_l2_mag_64hz_dsi_x_comp',yrange=[104,108];,
tplot,['erg_mgf_l2_mag_64hz_dsi_?_comp','erg_mgf_l2_mag_64hz_dsi_spt_x','erg_mgf_l2_mag_64hz_dsi_spt_y'],trange=['2017-11-16/10:01:30','2017-11-16/10:03:00']

;example 4
options,'erg_mgf_l2_mag_64hz_dsi_x_comp',yrange=[150,300];,
options,'erg_mgf_l2_mag_64hz_dsi_y_comp',yrange=[50,450];,
tplot,['erg_mgf_l2_mag_64hz_dsi_?_comp','erg_mgf_l2_mag_64hz_dsi_spt_x','erg_mgf_l2_mag_64hz_dsi_spt_y'],trange=['2017-11-16/11:00:00','2017-11-16/12:00:00']

;example 5
options,'erg_mgf_l2_mag_64hz_dsi_x_comp',yrange=[250,270];,
options,'erg_mgf_l2_mag_64hz_dsi_y_comp',yrange=[280,330];,
tplot,['erg_mgf_l2_mag_64hz_dsi_?_comp','erg_mgf_l2_mag_64hz_dsi_spt_x','erg_mgf_l2_mag_64hz_dsi_spt_y'],trange=['2017-11-16/11:45:00','2017-11-16/11:50:00']

end
