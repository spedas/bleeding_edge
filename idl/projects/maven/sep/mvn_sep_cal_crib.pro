
;pro mvn_sep_cal_crib,use_server=use_server

source = mvn_file_source()

if not keyword_set(tidname) then tidname = ''

localdir = source.local_data_dir
if keyword_set(use_server) then serverdir = source.remote_data_dir

pathname = 'maven/dpu/prelaunch/FM/20121128_150106_FM1-SEP_CPT_LM1/commonBlock_20121128_150106_FM1-SEP_CPT_LM1.dat'  ; First CPT at LM (not done through spacecraft)
pathname = 'maven/holding_pen/sep/prelaunch_tests/realtime/CMNBLK_20121210_180840.dat'         ; First SEP CPT through S/C
pathname = 'maven/dpu/prelaunch/live/flight/Split_At_20121210_161038/initial/common_block.dat' ; First SEP CPT through S/C


tf='2012-10-17/17'   & desc = 'SEP1A Electron Cal'
tf=['2012-10-17/18:04:0' ,'2012-10-17/22:26:30'] & mapname = 'SEP-A-O-alpha'  & desc = 'SEP1B ion cal'
tf='2012-11-28/16'   & desc = 'SEP Bench test CPT at LM'
tf='2012-12-10/19'   & desc = 'First S/C SEP CPT'
tf='2013-6-1'   & desc = 'S/C Thermal Vac Start First cold cycle'
tf='2013-6-2'   & desc = 'S/C Thermal Vac remainder of First cold cycle'
tf='2013-6-3'   & desc = 'S/C Thermal Vac warmup after First cold cycle'

pathname='maven/prelaunch/dpu/prelaunch/FM/20121011_172239_SEP1A_CAL/commonBlock_20121011_172239_SEP1A_CAL.dat' ; <1 minute of data (xray source)
pathname='maven/prelaunch/dpu/prelaunch/FM/20121011_211441_SEP1A_cal/commonBlock_20121011_211441_SEP1A_cal.dat' ; protons @ 30 kev and 35 kev
pathname='maven/prelaunch/dpu/prelaunch/FM/20121011_234813_idle/commonBlock_20121011_234813_idle.dat'           ;  9 hours of xray data on SEP1 
pathname='maven/prelaunch/dpu/prelaunch/FM/20121015_200525_SEP1A_cal/commonBlock_20121015_200525_SEP1A_cal.dat'  ; tiny file - nothing in it.
pathname='maven/prelaunch/dpu/prelaunch/FM/20121016_151433_SEP1A_cal_e/commonBlock_20121016_151433_SEP1A_cal_e.dat' ; Electron conditioning ~1hour of xray on sep1
pathname='maven/prelaunch/dpu/prelaunch/FM/20121016_163107_/commonBlock_20121016_163107_.dat'                        ;no data 
pathname='maven/prelaunch/dpu/prelaunch/FM/20121016_164819_SEP1A_CAL_E/commonBlock_20121016_164819_SEP1A_CAL_E.dat' ; no data
pathname='maven/prelaunch/dpu/prelaunch/FM/20121016_165223_SEP1A_CAL_E/commonBlock_20121016_165223_SEP1A_CAL_E.dat' ; fullstack0 Electron Cal
pathname='maven/prelaunch/dpu/prelaunch/FM/20121016_210224_SEP1A_cal/commonBlock_20121016_210224_SEP1A_cal.dat'  ;  fullstack0 Electron cal (long run with Am241)
pathname='maven/prelaunch/dpu/prelaunch/FM/20121017_150703_idle/commonBlock_20121017_150703_idle.dat'   ;  no data
pathname='maven/prelaunch/dpu/prelaunch/FM/20121017_153644_SEP1B_cal/commonBlock_20121017_153644_SEP1B_cal.dat' ; no data
pathname='maven/prelaunch/dpu/prelaunch/FM/20121017_164147_FMB_SEP1B_CAL/commonBlock_20121017_164147_FMB_SEP1B_CAL.dat'; no data
pathname='maven/prelaunch/dpu/prelaunch/FM/20121017_170252_FMB_SEP1B_CAL/commonBlock_20121017_170252_FMB_SEP1B_CAL.dat' ; SEP1B ion cal  35,40,45, kev
pathname='maven/prelaunch/dpu/prelaunch/FM/20121018_043857_idle/commonBlock_20121018_043857_idle.dat'                    ; SEP1B ion cal 35,30,25,20 kev
pathname='maven/prelaunch/dpu/prelaunch/FM/20121018_200915_FMB_SEP1B_CAL/commonBlock_20121018_200915_FMB_SEP1B_CAL.dat'  ; 1B Electron cal
pathname='maven/prelaunch/dpu/prelaunch/FM/20121019_163553_idle/commonBlock_20121019_163553_idle.dat'  ; 
pathname='maven/prelaunch/dpu/prelaunch/FM/20121019_205133_FMB_SEP2A_CAL/commonBlock_20121019_205133_FMB_SEP2A_CAL.dat'  ; 2A ion and electron
pathname='maven/prelaunch/dpu/prelaunch/FM/20121020_054626_idle/commonBlock_20121020_054626_idle.dat'  ;
pathname='maven/prelaunch/dpu/prelaunch/FM/20121022_171311_FMB_SEP2B_CAL/commonBlock_20121022_171311_FMB_SEP2B_CAL.dat'  ; no data
pathname='maven/prelaunch/dpu/prelaunch/FM/20121022_183727_FMB_SEP2B_CAL/commonBlock_20121022_183727_FMB_SEP2B_CAL.dat'  ; Only SEP2B cal data - has noise oddity
pathname='maven/prelaunch/dpu/prelaunch/FM/20121023_163520_FMB_SEP2B_cal_end/commonBlock_20121023_163520_FMB_SEP2B_cal_end.dat'  ; contains no SEP data
pathname='maven/prelaunch/dpu/prelaunch/FM/20121024_191646_FMS2_LPWCPT/commonBlock_20121024_191646_FMS2_LPWCPT.dat



; tvfiles = mvn_file_retrieve(trange=['2013-5-31','2013-6-4'],name='ATLO-L0',verbose=4)



mvn_pfp_l0_file_read,pathname=pathname,/sep



if tidname eq '1A' then begin
tidname='1A'

tf='2012-10-16/22'   ; electrons
tf='2012-10-12'      ; Idling  xrays for 9 hours
tf='2012-10-11/22'   ; protons  35 kev and 40 kev protons
tf=['2012-10-11/21:15:10', '2012-10-11/23:47:50']

files = mvn_file_retrieve(trange=tf[0],/no_server)
dprint,file_info(files),phelp=2

if not keyword_set(loaded) then mvn_sep_load,file=files,trange=tf;,  /sep  ;,/mag
loaded=1
wi,0,wsize=[700,800]

tplot,'*sep1_svy_DATA *sep1_noise_SIGMA *sep1_noise_BASELINE

tlimit,tf

desc = 'SEP1A_Proton_Response'

zlim,'mvn_sep1_A-O_bins',1,500,1
tplot, 'mvn_sep1_hkp_DACS mvn_sep1_A-O_bins mvn_sep1_A_CNTS mvn_sep1_A_sigma mvn_sep1_A_baseline mvn_sep1_A_total'
if keyword_set(png) then makepng,desc+'_tplot_summary',wind=0
wi,1

yrange=[1e-3,1e4]

t35=  ['2012-10-11/21:26:50', '2012-10-11/21:28:10']
sep_ical_plot3,t35,ienergy=35.,param=par35_1ao,det=[1,2,3],tid=0,seps=1,source=tidname+'_Protons' ,png=png,yrange=yrange

t40 = ['2012-10-11/23:00:10', '2012-10-11/23:01:20']
sep_ical_plot3,t40,ienergy=40.,param=par40_1ao,det=[1,2,3],tid=0,seps=1,source=tidname+'_Protons' ,png=png,yrange=yrange

pars_1ao = [par35_1ao[0],par40_1ao[0]]

plot,pars_1ao.energy,pars_1ao.g.x0,psym=-1,xtitle='Proton Energy',ytitle='ADC Value',Title=desc,xrange=[0,50],yrange=[0,30]
makepng,desc

T_xray =['2012-10-11/22:11:20', '2012-10-11/22:44:30']
sep_ical_plot3,t_xray_1a,ienergy=59.5,param=par_xray_1ao,det=[1,2,3],tid=0,seps=1,source=tidname+'_X-rays' ,png=png,yrange=yrange

if keyword_set(png) then makepng,desc+'_tplot_summary',wind=0
wi,1


save,pars_1ao,par_xray_1a,file=tidname+'_parameters.sav',/verbos

end










;tidname = '1B'
if tidname eq '1B' then begin
tidname='1B'

tf=['2012-10-17/18:04:0' ,'2012-10-17/22:26:30']
tf=['2012-10-17/17' ,'2012-10-18/21']

files = mvn_file_retrieve(trange=tf,/no_server)
dprint,files

if not keyword_set(loaded) then mvn_sep_load,file=files,trange=tf;,  /sep  ;,/mag
; loaded=1

tlimit,tf

tplot, 'mvn_sep1_hkp_DACS Energy mvn_sep1_B-O mvn_sep1_B mvn_sep1_B_sigma mvn_sep1_B_baseline mvn_sep1_B_total'
tplot,  'mvn_sep1_hkp_DACS mvn_sep1_B-O_bins mvn_sep1_B_CNTS mvn_sep1_B_sigma mvn_sep1_B_baseline'
mvn_sep_plot,tidname
tplot,'mvn_sep1_hkp_DACS mvn_sep1_svy_DATA mvn_sep1_A_sigma mvn_sep1_A_baseline'
;tplot,/add,[mvn+'hkp_MEM_ADDR','*NOTE','Energy',mvn+'hkp_DACS']

yrange=[1e-4,1e4]

t35=['2012-10-17/19:32:20', '2012-10-17/19:33:50']
sep_ical_plot3,t35,ienergy=35.,param=par35_1bo,det=1,tid=1,seps=1,source=tidname+'_Protons' ,png=png

t40= ['2012-10-17/21:21:45', '2012-10-17/21:23:05']
sep_ical_plot3,t40,ienergy=40.,param=par40_1bo,det=1,tid=1,seps=1,source=tidname+'_Protons' ,png=png

T45 = ['2012-10-17/22:02:20', '2012-10-17/22:04:00']
sep_ical_plot3,t45,ienergy=45.,param=par45_1bo,det=1,tid=1,seps=1,source=tidname+'_Protons' ,png=png

; Next day, next file

T35b =  ['2012-10-18/15:20:25', '2012-10-18/15:22:55']
sep_ical_plot3,t35b,ienergy=35.,param=par35b_1bo,det=1,tid=1,seps=1,source=tidname+'_Protons' ,png=png


T30 = ['2012-10-18/15:40:50', '2012-10-18/15:41:45']
sep_ical_plot3,t30,ienergy=30.,param=par30_1bo,det=1,tid=1,seps=1,source=tidname+'_Protons' ,png=png

T25 = ['2012-10-18/17:44:30', '2012-10-18/17:46:20']
sep_ical_plot3,t25,ienergy=25.,param=par25_1bo,det=1,tid=1,seps=1,source=tidname+'_Protons' ,png=png

T20 =  ['2012-10-18/18:13:50', '2012-10-18/18:15:00']
sep_ical_plot3,t20,ienergy=20.,param=par20_1bo,det=1,tid=1,seps=1,source=tidname+'_Protons' ,png=png

pars_1bo = [par20_1bo,par25_1bo,par30_1bo,par35b_1bo,par35_1bo,par40_1bo,par45_1bo]

title='SEP1B Proton Response'
plot,pars_1bo.energy,pars_1bo.g.x0,psym=-1,xtitle='Proton Energy',ytitle='ADC Value',Title=title,xrange=[0,50],yrange=[0,30]
if keyword_set(png) then makepng,'1B_Proton_Response'

T_alpha = ['2012-10-17/18:29:05', '2012-10-17/18:58:15']
xrange=[3000,4000]
xrange = [3600,4000]
sep_ical_plot3,t_alpha,ienergy=5500.,param=par_alpha_1bo,det=1,tid=1,seps=1,source=tidname+'_Alphas',xrange=xrange ,xwidth=20.,png=png


T_xray =['2012-10-17/18:00:00', '2012-10-17/18:24:30']
sep_ical_plot3,t_xray,ienergy=59.5,param=par_xray_1bo,det=1,tid=1,seps=1,source=tidname+'_X-rays',xmin=10 ,png=png


T_xray2 =['2012-10-18/19:03:00', '2012-10-18/19:26:30']
sep_ical_plot3,t_xray2,ienergy=59.5,param=par_xray_1b2,det=[1,2,3],tid=1,seps=1,source=tidname+'_X-rays',xmin=10 ,png=png


T_xray3 =['2012-10-19/00:50:00', '2012-10-19/04:35:00']
sep_ical_plot3,t_xray3,ienergy=59.5,param=par_xray_1b3,det=[1,2,3],tid=1,seps=1,source=tidname+'_X-rays',xmin=10 ,png=png

save, pars_1bo,par_xray_1bo,par_alpha_1bo,par_xray_1b2,par_xray_1b3,file='SEP1B_param.sav',/verbose


;electron stuff

tf='2012-10-18/21'
files = mvn_file_retrieve(trange=tf[0],/no_server)
dprint,files,/phelp

if not keyword_set(loaded) then mvn_sep_load,file=files,trange=tf;,  /sep  ;,/mag

tplot,'Egun_voltage mvn_sep1_hkp_DACS mvn_sep1_B-F_bins mvn_sep1_B_CNTS mvn_sep1_B_sigma mvn_sep1_B_baseline'
tlimit,['2012-10-18/20:56:45', '2012-10-18/22:00:10']
makepng,'SEP1B_35keV_electron_cal_summary',wind=0


tlimit

t35e = 0
tr =time_double(['2012-10-18/21:00:40', '2012-10-18/21:04:50'])
tt = tr[0] + dindgen(21)*(tr[1]-tr[0])/20
ttt = transpose([[tt],[tt+5]])
;timebar,tt
yrange=[1e-2,1000]
for i=0,20 do sep_ical_plot3,ttt[*,i],ienergy=15.+i,param=p,det=3,tid=1,seps=1,source=tidname+'_electrons',yrange=yrange ,png=png


end






if tidname eq '2A' then begin
tidname='2A'

pathname='maven/prelaunch/dpu/prelaunch/FM/20121019_205133_FMB_SEP2A_CAL/commonBlock_20121019_205133_FMB_SEP2A_CAL.dat'  ; 2A ion and electron


tf= ['2012-10-19/20:53:00', '2012-10-20/05:45:00']; & mapname = 'SEP-A-O-alpha_low'  & desc = 'SEP2A Ion Cal'

files = mvn_file_retrieve(trange=tf[0],/no_server)
dprint,files,/phelp

if not keyword_set(loaded) then mvn_sep_load,file=files,trange=tf;,  /sep  ;,/mag
loaded=1

;mvn_sep_handler,mapname=mapname
;map = mvn_sep_lut2map(mapname=mapname)

tlimit,tf

tplot,'mvn_sep2_hkp_DACS mvn_sep2_svy_DATA mvn_sep2_A_sigma mvn_sep2_A_baseline
;tplot, 'mvn_sep2_hkp_DACS Energy mvn_sep2_A-O mvn_sep2_A mvn_sep2_A_sigma mvn_sep2_A_baseline mvn_sep2_A_total'
;mvn_sep_plot,tidname
;tplot,/add,[mvn+'hkp_MEM_ADDR','*NOTE','Energy',mvn+'hkp_DACS']

;ctime,t & printdat,/valu,time_string(t)  ,varname='T'

;tname = 'mvn_sep2_A-O'

t25=['2012-10-20/02:42:40', '2012-10-20/02:44:00']
sep_ical_plot3,t25,ienergy=25.,param=par25_2ao,det=1,tid=0,seps=2,source=tidname+'_Protons' ,png=png

t30=['2012-10-20/02:16:50', '2012-10-20/02:17:40']
sep_ical_plot3,t30,ienergy=30.,param=par30_2ao,det=1,tid=0,seps=2,source=tidname+'_Protons' ,png=png

t35= ['2012-10-20/00:36:30', '2012-10-20/00:38:00']
sep_ical_plot3,t35,ienergy=35.,param=par35_2ao,det=1,tid=0,seps=2,source=tidname+'_Protons' ,png=png

T40 =   ['2012-10-20/01:08:00', '2012-10-20/01:08:36']
sep_ical_plot3,t40,ienergy=40.,param=par40_2ao,det=1,tid=0,seps=2,source=tidname+'_Protons' ,png=png

T42_5 =  ['2012-10-20/01:40:40', '2012-10-20/01:42:00']
sep_ical_plot3,t42_5,ienergy=42.5,param=par42_5_2ao,det=1,tid=0,seps=2,source=tidname+'_Protons' ,png=png

pars_2ao = [par25_2ao,par30_2ao,par35_2ao,par40_2ao,par42_5_2ao]

desc='SEP2A_Proton_Response'
plot,pars_2ao.energy,pars_2ao.g.x0,psym=-1,xtitle='Proton Energy',ytitle='ADC Value',Title=desc,xrange=[0,50],yrange=[0,30]
makepng,desc

T_alpha = ['2012-10-19/23:58:25', '2012-10-20/00:17:30']  ; alphas
sep_ical_plot3,t_alpha,ienergy=5500.,param=par_alpha_2ao,det=1,tid=0,seps=2,source=tidname+'_Alpha',xrange=[3000,4000],xwidth=20 ,png=png

;t_alpha3=0
;sep_ical_plot3,t_alpha3,ienergy=5500.,param=par_alpha3_2ao,det=1,tid=0,seps=2,source=tidname+'_Alpha',xrange=[3000,4000],xwidth=20 ,png=png

T_xray =  ['2012-10-20/03:10:30', '2012-10-20/03:24:30']
sep_ical_plot3,t_xray,ienergy=59.5,param=par_xray_2ao,det=[1],tid=0,seps=2,source=tidname+'_X-rays',xmin=10 ,png=png

T_xray2 = ['2012-10-19/23:27:00', '2012-10-19/23:38:00']
sep_ical_plot3,t_xray2,ienergy=59.5,param=par_xray_2a,det=[1,2,3],tid=0,seps=2,source=tidname+'_X-rays',xmin=10 ,png=png


;save,pars_2ao,par_alpha_2ao,par_xray_2a,par_xray_2ao,file=tname+'.sav',/verbos


t_el_alpha=['2012-10-19/21:10:00', '2012-10-19/21:31:00']
sep_ical_plot3,t_el_alpha,ienergy=5500.,param=par_alpha_2af,det=3,tid=0,seps=2,source=tidname+'_el_Alpha',xrange=[3000,4000],xwidth=20 ,png=png

t_el_alpha2=['2012-10-19/21:52:30', '2012-10-19/22:12:30']
sep_ical_plot3,t_el_alpha2,ienergy=5500.,param=par_alpha2_2af,det=3,tid=0,seps=2,source=tidname+'_el_Alpha',xrange=[3000,4000],xwidth=20 ,png=png


save,pars_2ao,par_alpha_2ao,par_xray_2a,par_xray_2ao,par_alpha2_2af,par_alpha2_2af,file='2B_Proton_response'+'.sav',/verbos

; examine 2A-T threshold adjustment
t_test = ['2012-10-19/23:12:00', '2012-10-19/23:46:20']
mvn_sep_extract_data,'mvn_sep2_svy',rawdat,trange=t_test,count=count
mvn_sep_create_subarrays,rawdat,tname='alpha_test'
tplot,'alpha_test_A* *2*DACS'



end


if tidname eq '2B' then begin
tidname='2B'
desc = 'SEP2B_Proton_Response'
pathname='maven/prelaunch/dpu/prelaunch/FM/20121022_183727_FMB_SEP2B_CAL/commonBlock_20121022_183727_FMB_SEP2B_CAL.dat


tf= ['2012-10-22/19', '2012-10-22/23']  ; & mapname = 'SEP-B-O-alpha_low'  & desc = 'SEP2B Ion Cal'

files = mvn_file_retrieve(trange=tf[0],/no_server)
dprint,files,/phelp

if not keyword_set(loaded) then mvn_sep_load,file=files,trange=tf;,  /sep  ;,/mag

loaded=1


;prefix = 'mvn_'
;    common mav_apid_sep_handler_com 
;mvn_sep_create_subarrays,*sep1_svy.x,tname=prefix+'sep1',mapname=mapname,yval='adc'
;mvn_sep_create_subarrays,*sep2_svy.x,tname=prefix+'sep2',mapname=mapname,yval='adc'
;mvn_sep_create_subarrays,*sep1_svy.x,tname=prefix+'sep1',mapname=mapname,yval='bins'
;mvn_sep_create_subarrays,*sep2_svy.x,tname=prefix+'sep2',mapname=mapname,yval='bins'
;mvn_sep_handler,mapname=mapname

;t_lut=0
;lut = mvn_sep_commands_to_lut(1,trange=t_lut)
;map = mvn_sep_lut2map(lut=lut)

;mapname = mvn_sep_mapnum_to_mapname()
;map = mvn_sep_lut2map(mapname=mapname)

tlimit,tf

tplot, 'mvn_sep2_hkp_DACS Energy mvn_sep2_svy_DATA mvn_sep2_B-O_bins mvn_sep2_B_CNTS mvn_sep2_svy_MAPID'
ylim,'mvn_sep2_B-O',0,50

;   ctime,t & printdat,/valu,time_string(t)  ,varname='T'

;sepname = 'mvn_sep2_svy'
;name = 'B-O'

yrange=[1e-4,1e4]
t25= ['2012-10-23/00:24:40', '2012-10-23/00:27:20']
sep_ical_plot3,t25,ienergy=25.,param=par25_2bo,det=1,tid=1,seps=2,source=tidname+'_Protons',yrange=yrange ,png=png

t30= ['2012-10-22/23:49:10', '2012-10-22/23:50:30']
sep_ical_plot3,t30,ienergy=30.,param=par30_2bo,det=1,tid=1,seps=2,source=tidname+'_Protons',yrange=yrange ,png=png

t35= ['2012-10-22/23:13:50', '2012-10-22/23:15:30']
sep_ical_plot3,t35,ienergy=35.,param=par35_2bo,det=1,tid=1,seps=2,source=tidname+'_Protons',yrange=yrange ,png=png

T40 =   ['2012-10-22/23:32:00', '2012-10-22/23:34:40']
sep_ical_plot3,t40,ienergy=40.,param=par40_2bo,det=1,tid=1,seps=2,source=tidname+'_Protons',yrange=yrange ,png=png

pars_2bo = [par25_2bo,par30_2bo,par35_2bo,par40_2bo]


plot,pars_2bo.energy,pars_2bo.g.x0,psym=-1,xtitle='Proton Energy',ytitle='ADC Value',Title=desc,xrange=[0,50],yrange=[0,30]
makepng,'SEP2B_Proton_Response'

mvn_sep_create_subarrays,'mvn_sep2_svy',mapid=152,tname='map152_sep2'
mvn_sep_create_subarrays,'mvn_sep2_svy',mapid=202,tname='map202_sep2' ,yval='energy'; electron run


T_alpha = ['2012-10-22/21:45:30', '2012-10-22/22:32:30'] ; alphas
sep_ical_plot3,t_alpha,ienergy=5500.,param=par_alpha_2bo,det=1,tid=1,seps=2,source=tidname+'_Alpha',xrange=[3000,4000],xwidth=20 ,png=png

; alphas were at the edge of high res map for this sample  (use spectra above)
;T_alpha_b = ['2012-10-22/21:45:30', '2012-10-22/22:32:30'] ; alphas
;sep_ical_plot2,T_alpha_b,ienergy=5500.,param=par_alpha,sepname=sepname,name=name,source='Alphas',png=png,labpos=[.3,.9],xrange=[2000,4000]


T_xray =  ['2012-10-22/20:14:00', '2012-10-22/20:47:30']
sep_ical_plot3,t_xray,ienergy=59.5,param=par_xray_2bo,det=[1],tid=1,seps=2,source=tidname+'_X-rays',xmin=10 ,png=png

T_xray2 = ['2012-10-23/04:31:20', '2012-10-23/04:46:20']
sep_ical_plot3,t_xray2,ienergy=59.5,param=par_xray2_2b,det=[1,2,3],tid=1,seps=2,source=tidname+'_X-rays',xmin=10 ,png=png,yrange=yrange


t_el_alpha=['2012-10-23/01:33:00', '2012-10-23/01:43:00']
sep_ical_plot3,t_el_alpha,ienergy=5500.,param=par_alpha_2bf,det=3,tid=1,seps=2,source=tidname+'_el_Alpha',xrange=[3000,4000],xwidth=20 ,png=png

t_el_alpha2= ['2012-10-23/01:53:20', '2012-10-23/02:06:40']
sep_ical_plot3,t_el_alpha2,ienergy=5500.,param=par_alpha2_2bf,det=3,tid=1,seps=2,source=tidname+'_el_Alpha',xrange=[3000,4000],xwidth=20 ,png=png


t_el_xalpha=['2012-10-23/01:33:00', '2012-10-23/01:43:00']
sep_ical_plot3,t_el_xalpha,ienergy=5500.,param=par_xalpha_2bf,det=3,tid=1,seps=2,source=tidname+'_el_X-Alpha' ,png=png

t_el_xalpha2= ['2012-10-23/01:53:20', '2012-10-23/02:06:40']
sep_ical_plot3,t_el_xalpha2,ienergy=5500.,param=par_xalpha2_2bf,det=3,tid=1,seps=2,source=tidname+'_el_X-Alpha' ,png=png

t_el35 =  ['2012-10-23/02:35:37', '2012-10-23/02:36:30']
sep_ical_plot3,ienergy=35.,seps=2,det=3,tid=1 ,t_el35,par=p1
t_el35_att =  ['2012-10-23/02:33:23', '2012-10-23/02:35:23']
sep_ical_plot3,ienergy=35.,seps=2,det=3,tid=1 ,t_el35_att,par=p2,/over

pars_2B = [pars_2bo,par_xray_2bo,par_xray_2b,par_alpha_2bo,par_alpha_2bf]

tname = 'SEP2B_par'
save,pars_2bo,par_xray_2bo,par_xray2_2b,par_alpha_2bo,par_alpha_2bf,file=tname+'.sav',/verbose

end

wi,1

;restore,

;deadlayer:
einc = [25,30,35,40]
elost = [10.2,10.7,11.6,12.2]
plot,einc,elost,psym=-1,xrange=[0,50]
par = polycurve()
fit,einc,elost,par=lostenergy,names='a0 a1',/over
;25 keV ions lose ~10.2 keV
;30 keV ions lose ~10.7 keV
;35 keV ions lose ~11.6 keV
;40 keV ions lose ~12.2 keV


scale=[1.,1,1,1]  & ytitle = 'ADC Value'  & yrange=[0,30]
scale= 59.5/ [43.77,41.97,40.25,43.2]  & ytitle='Energy Deposited (keV)' & yrange=[0,50]
keys = replicate({psym:0, color:0, label:''},4)
keys.psym = -[1,2,4,5]
keys.color = 0
keys.label = strsplit('1A-O 1B-O 2A-O 2B-O',/extract,' ')

title = 'SEP Open detectors - Response to Protons'
plot,/nodata,indgen(2),psym=-1,xtitle='Proton Energy (keV)',ytitle=ytitle,Title=title,xrange=[0,50],yrange=yrange
oplot,pars_1ao.energy,pars_1ao.g.x0*scale[0],_extra=keys[0]
oplot,pars_1bo.energy,pars_1bo.g.x0*scale[0],_extra=keys[1]
oplot,pars_2ao.energy,pars_2ao.g.x0*scale[0],_extra=keys[2]
oplot,pars_2bo.energy,pars_2bo.g.x0*scale[0],_extra=keys[3]
display_key,keys
xv = dgen()
oplot,xv,xv,linestyle=1
oplot,xv,xv-func(xv,par=lostenergy),linestyle=2
makepng,'SEP_proton_response_w_dead_layer_est

cbin59_5 =[[[ 1. , 43.77, 38.49, 41.13,  41.,41.,41. ] ,  $  ;1A
            [ 1. , 41.97, 40.29, 42.28,  41.,41.,41. ]] ,  $  ;1B
           [[ 1. , 40.25, 44.08, 43.90,  41.,41.,41. ] ,  $  ;2A
            [ 1. , 43.2 , 43.97, 41.96,  41.,41.,41. ]]]   ;  2B


; diff_e_flux =  energy[i] * rate / GF / delta_E[i] / eff[i]
; diff_flux = rate/ GF / delta_E[i] /eff[i]

; rate = diff_flux *GF * delta_E[i] * eff[i]
; rate[i] = diff_eflux *GF * delta_E[i] / energy[i] * eff[i]







end
