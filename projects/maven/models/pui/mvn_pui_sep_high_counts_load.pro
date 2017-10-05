;20161114
;loads the necessary data for use by mvn_pui_sep_high_counts_stat

pro mvn_pui_sep_high_counts_load

common mvn_swia_data,info_str, swihsk, swics, swica, swifs, swifa, swim, swis

;kernels=mvn_spice_kernels(/all,/clear,/load,trange=trange,verbose=2)

secinday=86400L ;number of seconds in a day
timespan,['14-12-1','16-11-11']
get_timespan,trange
ndays=round((trange[1]-trange[0])/secinday) ;number of days
res=64. ;time averaging (resolution is secs)
inn=floor(secinday/res) ;number of time steps in a day

data=replicate({sephc:byte(0),vsw:fltarr(3),nsw:0.,mag:fltarr(3),pos:fltarr(3),time:double(0)},inn,ndays) ;structure of data

for j=0,ndays-1 do begin ;loop over days

tr=trange[0]+[j,j+1]*secinday ;one day
timespan,tr

file=mvn_pfp_file_retrieve('maven/data/sci/sep/l1/sav/YYYY/MM/mvn_sep_l1_YYYYMMDD_1day.sav',/daily) ;SEP L1 data
if ~file_test(file) then continue
restore,file
if ~keyword_set(s1_svy) then continue

mvn_swia_load_l2_data,/loadmom,qlevel=0.1 ;load SWIA data
if ~keyword_set(swim) then continue
swim2=average_hist(swim,swim.time_unix+2.,binsize=res,range=tr,xbins=centertime); swia moments
data[*,j].vsw=swim2.velocity_mso ;solar wind velocity (km/s)
data[*,j].nsw=swim2.density ;solar wind density (cm-3)

mvn_mag_load,'L2_1sec' ;load MAG data
get_data,'mvn_B_1sec',data=magdata; magnetic field vector, payload coordinates (nT)
magpayload=average_hist2(magdata.y,magdata.x,binsize=res,trange=tr,centertime=centertime); magnetic field vector payload (nT)
data[*,j].mag=spice_vector_rotate(transpose(magpayload),centertime,'MAVEN_SPACECRAFT','MAVEN_MSO',check_objects='MAVEN_SPACECRAFT') ;mag (MSO)

data[*,j].pos=spice_body_pos('MAVEN','MARS',frame='MSO',utc=centertime) ;MAVEN position MSO (km)
data[*,j].time=centertime

cdf2tplot,mvn_pfp_file_retrieve('maven/data/sci/sep/anc/cdf/YYYY/MM/mvn_sep_l2_anc_YYYYMMDD_v??_r??.cdf',/daily),prefix='SepAnc_',verbose=0
get_data,'SepAnc_sep_1f_fov_sun_angle',data=sun1fdata; %sep1f fov
get_data,'SepAnc_sep_2f_fov_sun_angle',data=sun2fdata;
get_data,'SepAnc_sep_1r_fov_sun_angle',data=sun1rdata;
get_data,'SepAnc_sep_2r_fov_sun_angle',data=sun2rdata;
get_data,'SepAnc_sep_1f_frac_fov_ill',data=ill1fdata;
get_data,'SepAnc_sep_2f_frac_fov_ill',data=ill2fdata;
get_data,'SepAnc_sep_1r_frac_fov_ill',data=ill1rdata; 
get_data,'SepAnc_sep_2r_frac_fov_ill',data=ill2rdata; 

sun1f=average_hist2(sun1fdata.y,sun1fdata.x,binsize=res,trange=tr,centertime=centertime)
sun2f=average_hist2(sun2fdata.y,sun2fdata.x,binsize=res,trange=tr,centertime=centertime)
sun1r=average_hist2(sun1rdata.y,sun1rdata.x,binsize=res,trange=tr,centertime=centertime)
sun2r=average_hist2(sun2rdata.y,sun2rdata.x,binsize=res,trange=tr,centertime=centertime)
ill1f=average_hist2(ill1fdata.y,ill1fdata.x,binsize=res,trange=tr,centertime=centertime)
ill2f=average_hist2(ill2fdata.y,ill2fdata.x,binsize=res,trange=tr,centertime=centertime)
ill1r=average_hist2(ill1rdata.y,ill1rdata.x,binsize=res,trange=tr,centertime=centertime)
ill2r=average_hist2(ill2rdata.y,ill2rdata.x,binsize=res,trange=tr,centertime=centertime)

sep1=average_hist(s1_svy,s1_svy.time,binsize=res,range=tr,xbins=centertime) ;SEP data
sep2=average_hist(s2_svy,s2_svy.time,binsize=res,range=tr,xbins=centertime)
nse1=average_hist(s1_nse,s1_nse.time,binsize=res,range=tr,xbins=centertime) ;SEP noise
nse2=average_hist(s2_nse,s2_nse.time,binsize=res,range=tr,xbins=centertime)

s1ao_cps_lo=total(sep1.data[0:12,*],1)/sep1.delta_time
s2ao_cps_lo=total(sep2.data[0:12,*],1)/sep2.delta_time
s1bo_cps_lo=total(sep1.data[128:140,*],1)/sep1.delta_time
s2bo_cps_lo=total(sep2.data[128:140,*],1)/sep2.delta_time
s1ao_cps_hi=total(sep1.data[13:23,*],1)/sep1.delta_time
s2ao_cps_hi=total(sep2.data[13:23,*],1)/sep2.delta_time
s1bo_cps_hi=total(sep1.data[141:151,*],1)/sep1.delta_time
s2bo_cps_hi=total(sep2.data[141:151,*],1)/sep2.delta_time
s1cps=sep1.data/(replicate(1.,256)#sep1.delta_time)
s2cps=sep2.data/(replicate(1.,256)#sep2.delta_time)

s1ao_sig=nse1.sigma[0]
s2ao_sig=nse2.sigma[0]
s1bo_sig=nse1.sigma[3]
s2bo_sig=nse2.sigma[3]

s1ao_bln=nse1.baseline[0]
s2ao_bln=nse2.baseline[0]
s1bo_bln=nse1.baseline[3]
s2bo_bln=nse2.baseline[3]

limsig=1.3 ;if sigma greater than this, then count as noise
limcps=3e3 ;cps lower threshold
limcme=2e3 ;CME threshold
limbln=-.3 ;baseline threshold
limill=.1 ;illumination (mars shine) threshold

index1=where((s1ao_sig gt limsig) and (s1ao_cps_lo gt limcps) and (s1ao_cps_hi lt limcme) and (s1ao_bln lt limbln) and (ill1r lt limill),count1)
index2=where((s2ao_sig gt limsig) and (s2ao_cps_lo gt limcps) and (s2ao_cps_hi lt limcme) and (s2ao_bln lt limbln) and (ill2r lt limill),count2)
index4=where((s1bo_sig gt limsig) and (s1bo_cps_lo gt limcps) and (s1bo_cps_hi lt limcme) and (s1bo_bln lt limbln) and (ill1f lt limill),count4)
index8=where((s2bo_sig gt limsig) and (s2bo_cps_lo gt limcps) and (s2bo_cps_hi lt limcme) and (s2bo_bln lt limbln) and (ill2f lt limill),count8)
;index16=where(edotp gt 0,count16) ;where E.P is positive

if count1 ne 0 then data[index1,j].sephc+=1
if count2 ne 0 then data[index2,j].sephc+=2
if count4 ne 0 then data[index4,j].sephc+=4
if count8 ne 0 then data[index8,j].sephc+=8
;if count16 ne 0 then data[index16,j].sephc+=16

;store_data,'SEP_High',centertime,transpose(data[*,j].sephc)
;ylim,'SEP_High',0,32
;options,'SEP_High','panel_size',.5
;
;store_data,'SEP1_ATT',s1_svy.time,s1_svy.att
;store_data,'SEP2_ATT',s2_svy.time,s2_svy.att
;ylim,'SEP?_ATT',0,3,0
;options,'SEP?_ATT','ystyle',0
;options,'SEP1_ATT','colors','b'
;options,'SEP2_ATT','colors','r'
;options,'SEP?_ATT','panel_size',.1
;
;store_data,'SEP1_CPS',centertime,transpose(s1cps)
;store_data,'SEP2_CPS',centertime,transpose(s2cps)
;ylim,'SEP?_CPS',0,256
;zlim,'SEP?_CPS',1e-1,1e4,1
;options,'SEP?_CPS','spec',1
;
;store_data,'SEP_TOTAL_CPS',centertime,[[sep1.rate],[sep2.rate]]
;ylim,'SEP_TOTAL_CPS',1,1e5,1
;options,'SEP_TOTAL_CPS','colors','br'
;options,'SEP_TOTAL_CPS','labels',['SEP1','SEP2']
;options,'SEP_TOTAL_CPS','labflag',-1
;options,'SEP_TOTAL_CPS','panel_size',.5
;
;store_data,'SEP_O_CPS_LOW',centertime,[[s1ao_cps_lo],[s2ao_cps_lo],[s1bo_cps_lo],[s2bo_cps_lo]]
;ylim,'SEP_O_CPS_LOW',.1,1e5,1
;options,'SEP_O_CPS_LOW','colors','cmbr'
;options,'SEP_O_CPS_LOW','labels',['SEP1AO','SEP2AO','SEP1BO','SEP2BO']
;options,'SEP_O_CPS_LOW','labflag',-1
;
;store_data,'SEP_O_CPS_HI',centertime,[[s1ao_cps_hi],[s2ao_cps_hi],[s1bo_cps_hi],[s2bo_cps_hi]]
;ylim,'SEP_O_CPS_HI',.1,1e5,1
;options,'SEP_O_CPS_HI','colors','cmbr'
;options,'SEP_O_CPS_HI','labels',['SEP1AO','SEP2AO','SEP1BO','SEP2BO']
;options,'SEP_O_CPS_HI','labflag',-1
;
;store_data,'SEP_O_SIGMA',centertime,[[s1ao_sig],[s2ao_sig],[s1bo_sig],[s2bo_sig]]
;ylim,'SEP_O_SIGMA',1,3
;options,'SEP_O_SIGMA','colors','cmbr'
;options,'SEP_O_SIGMA','labels',['SEP1AO','SEP2AO','SEP1BO','SEP2BO']
;options,'SEP_O_SIGMA','labflag',-1
;
;store_data,'SEP_O_BASELINE',centertime,[[s1ao_bln],[s2ao_bln],[s1bo_bln],[s2bo_bln]]
;ylim,'SEP_O_BASELINE',-4,.5
;options,'SEP_O_BASELINE','colors','cmbr'
;options,'SEP_O_BASELINE','labels',['SEP1AO','SEP2AO','SEP1BO','SEP2BO']
;options,'SEP_O_BASELINE','labflag',-1
;
;tplot,'SEP_TOTAL_CPS SEP1_ATT SEP1_CPS SEP2_ATT SEP2_CPS SEP_O_CPS_LOW SEP_O_CPS_HI SEP_O_SIGMA SEP_O_BASELINE SEP_High'

;makepng,'sep_high_counts_'+strmid(time_string(tr[0]),0,10)

;p=plot(centertime,s1cps_data,/ylog,c='b')
;p=plot(centertime,s2cps_data,c='r',/o)
;
;p=plot(centertime,s1ao_sig,c='c')
;p=plot(centertime,s2ao_sig,c='m',/o)
;p=plot(centertime,s1bo_sig,c='b',/o)
;p=plot(centertime,s2bo_sig,c='r',/o)

;ind1att=where(sep1.att eq 1)
;p=plot(ill1r[ind1att],s1ao_sig[ind1att],'o')
;p=scatterplot(ill1r[ind1att],s1ao_sig[ind1att],magnitude=ind1att)

endfor
save,data

stop
end