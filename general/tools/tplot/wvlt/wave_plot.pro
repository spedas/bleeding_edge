pro wave_plot,t

magname='wi_B3'
densname='Np'
velname='Vp'

if keyword_set(t) then begin
timespan,t
load_3dp_data
get_pmom2 
load_wi_swe,/pol
load_wi_sp_mfi,/pol
load_wi_or,/var
get_sospec  
get_sfspec  
load_wi_elpd2
normpad
alfven_corr,magname,densname,velname,/rota
get_bsn2,bname='B_sm',pname='wi_pos',vname=velname

deriv_data,magname,newna='dB/dt
tsmooth2,magname,65
nam=rotate_data('dB/dt',magname+'_sm',name='^')
;del_data,'dB/dt_^'
;store_data,nam,newname="dB/dt_^"
crosscor_data,"dB/dt_^",dimen1=0,"dB/dt_^",dimen2=1,j=64
crosscor_data,"dB/dt_^",dimen1=2,j=64

endif

store_data,'V',data='wi_swe_Vp_mag wi_swe_VTHp Valfven Vp_mag VTHp'
ylim,'V',0,1000,0
store_data,'N',data='wi_swe_Np Np ph_mom.DENSITY'
ylim,'N',.1,100,1
store_data,'B',data='wi_B3_mag'
ylim,'B',1,50,1
store_data,'NB',data='Np wi_B3_mag' & ylim,'NB',0,0,0 & options,'NB',ynozero=1

options,'*swe*',colors='y'
options,'V',panel_size=1.5
options,'Valfven',colors='g'
ylim,'Vp_mag',300,800,0
ylim,'sfspec*',1e-6,1
ylim,'sospec*',1e-8,1
ylim,'Np',.5,50,1
zlim,'pow(*,*)',.005,.5,1
zlim,'pow(*(2))',.005,.5,1
zlim,'pol(*,*)',-.1,.1,0

tn='sfspec_34 plspec Vp_mag B N wi_B3 wi_B3_phi dB sospec_34 dBx_B dBy_B dBz_B slope2 bsn.TH_BN elpd-1-5:5 elpd-1-5:5_norm
tn='sfspec_34 plspec Vp_mag B N wi_B3 wi_B3_phi sospec_34 slope2 bsn.TH_BN pow(*,*) pol(*,*) elpd-1-5:5 elpd-1-5:5_norm
tplot,tn

end

