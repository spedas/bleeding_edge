;This file is largely obsolete retain.


pro set_pfdpu_tplot_options   ; retain this for realtime stuff
   tplot_options,'no_interp',1
   store_data,'mav_apid_all',data=tnames('MAV_APIDS MAV_APID_SKIPPED') ;,dlimit=tplot_routine='bitplot'
   tplot_options,'ynozero',1
   options,'sep?_noise_DATA sep?_svy_DATA',spec=1
   zlim,'sep?_svy_DATA',.9,100,1
   options,'sep?_svy_DATA',panel_size=2
   ylim,'sep?_hkp_RATE_CNTR',.5,1e5,1
   ylim,'sep?_hkp_RATE_CNTR',0,0,0
   ylim,'sep?_svy_COUNTS_TOTAL',1,1,1  ;,0,0,0
   store_data,'sep1_COUNTS',data='sep1_svy_RATE sep1_hkp_RATE_CNTR sep1_hkp_EVENT_CNTR'
   store_data,'sep2_COUNTS',data='sep2_svy_RATE sep2_hkp_RATE_CNTR sep2_hkp_EVENT_CNTR'
   store_data,'APIDS',data='MAV_APIDS MAV_APID_SKIPPED'
   
   options,'sep?_hkp_RATE_CNTR',psym=-1
   options,'PFDPU_SHKP_ACT_PWRCNTRL_FLAG',colors='BGR',labels=strsplit('Mag1 Mag2 SWEA SWIA LPW STA SEP',/extract)
   options,'PFDPU_OPER_ACT_REQUEST_FLAG',colors = 'GR',labels=strsplit('S1o S1s S2o S2s SWIA SWIA STATIC STATIC . . EUVEo EUVEs',/extract)
   options,'PFDPU_OPER_ACT_STATUS_FLAG',colors = 'GR',labels=strsplit('S1o S1s S2o S2s SWIAo SWIAs STATICo STATICs . . EUVEo EUVEs',/extract)
   options,'sep?_hkp_MODE_FLAGS',colors='BGRBGRYYBGRBGRMD',labels=strsplit(/extract,'D1 D2 D3 D4 D5 D6 BLR1 BLR2 TP_AO TP_AT TP_AF TP_BO TP_BT TP_BF TP_ENA Spare')
   options,'sep?_hkp_NOISE_FLAGS',labels=strsplit(/extract,'. . . . . . . . R R R Ena D1 D2 D3 D4'),colors='GGGGGGGGRRRBGRGR'
   store_data,'DPU_TEMP',data='sep1_hkp_AMON_TEMP_DAP sep2_hkp_AMON_TEMP_DAP PFDPU_HKP_REG_TEMP PFDPU_HKP_DCB_TEMP PFDPU_HKP_FPGA_TEMP'
   store_data,'SEPS_TEMP',data='sep?_hkp_AMON_TEMP_S?'
   options,'sep1_hkp_* sep1_svy_ATT sep1_svy_COUNTS_TOTAL',colors='b',ystyle=2
   options,'sep2_hkp_* sep2_svy_ATT sep2_svy_COUNTS_TOTAL',colors='r',ystyle=2
   options,'sep?_*DACS sep?_hkp_*RATE_CNTR','colors'
;   tnames = 'sep1_hkp_AMON_*'
   store_data,'SEPS_hkp_VCMD_CNTR',data='sep?_hkp_VCMD_CNTR'
   store_data,'SEPS_hkp_MEM_CHECKSUM',data='sep?_hkp_MEM_CHECKSUM'
   store_data,'SEPS_svy_ATT',data='sep?_svy_ATT'
   store_data,'SEPS_svy_COUNTS_TOTAL',data='sep?_svy_COUNTS_TOTAL'
   
   
   temps = tnames('SEPS_TEMP DPU_TEMP HTR_TEMP HTR_DC')
   
   if keyword_set(tnames(/tplot)) eq 0 then $
      tplot,'SEPS_hkp_VCMD_CNTR sep?_svy_DATA sep?_noise_SIGMA sep?_hkp_RATE_CNTR'
   
  if 0 then begin
     tplot,'SEPS_hkp_VCMD_CNTR sep1_svy_DATA sep1_svy_COUNTS_TOTAL sep1_hkp_RATE_CNTR P*ACT_*T*_FLAG'
     tplot,'SEPS_hkp_VCMD_CNTR sep2_svy_DATA sep2_svy_COUNTS_TOTAL sep2_noise_SIGMA sep2_hkp_RATE_CNTR P*ACT_*T*_FLAG'
     tplot,'SEPS_hkp_VCMD_CNTR sep?_svy_DATA sep?_noise_SIGMA sep?_hkp_RATE_CNTR'
     tplot,'SEPS_hkp_VCMD_CNTR sep1_svy_DATA sep1_noise_SIGMA sep1_hkp_RATE_CNTR SEPS_svy_COUNTS_TOTAL SEPS_svy_ATT SEPS_TEMP'  ; P*ACT_*T*_FLAG'
     tplot,'SEPS_hkp_VCMD_CNTR sep2_svy_DATA sep2_noise_SIGMA sep2_hkp_RATE_CNTR SEPS_svy_COUNTS_TOTAL SEPS_svy_ATT SEPS_TEMP'  ;P*ACT_*T*_FLAG'
     tplot,/add,'IG_* Beam_Current'
     tplot,/add,'sep1_hkp_DACS'
     tplot,'sep1_hkp_AMON_*'
     tplot,'sep2_hkp_AMON_*'
     tplot,'sep?_svy_DATA sep?_noise_DATA
     tplot,'sep1_hkp_MEM_ADDR sep1_svy_DATA sep1_noise_DATA sep1_hkp_RATE_CNTR'
     tplot,'sep2_hkp_MEM_ADDR sep2_svy_DATA sep2_noise_DATA sep2_hkp_RATE_CNTR'
     tplot,'SEPS_hkp_VCMD_CNTR sep?_svy_DATA sep?_noise_DATA sep?_hkp_RATE_CNTR'
     tplot,'SEPS_hkp_VCMD_CNTR sep?_svy_DATA sep?_noise_SIGMA sep?_hkp_RATE_CNTR'
     tplot,'SEPS_TEMP DPU_TEMP HTR_TEMP HTR_DC'
     tplot,'sep1'+strsplit('_hkp_VCMD_CNTR _svy_DATA _noise_DATA _hkp_RATE_CNTR',/extract)
     tplot,'sep?_hkp_RATE_CNTR'
     tplot,'sep?_hkp_VCMD_CNTR'
     tplot, 'mav_apid_all'
     tplot,'*FLAGS'
     tplot,'C*'
     tplot,'PFDPU_HKP_PFP28* PFDPU_HKP_SEP* PFDPU_*_TEMP sep?_hkp_AMON_*5* 
endif

end

function energy2adc,energy,parameter=par
if not keyword_set(par) then begin
    par = {func:'energy2adc',Edead:14.d,Escale:1.5d}
endif
if n_params() eq 0 then return,par

return, (energy-par.Edead)/par.Escale
end


pro sep_ical_plot,trange,param=par,ienergy=ienergy,name=name,png=png,xrange=xrange,xshift=xshift,xwidth=xwidth
if n_elements(trange) ne 2 then ctime,trange,npoints=2
if not keyword_set(xrange) then xrange=[0,60] ;+120
if not keyword_set(xshift) then xshift=0
if not keyword_set(xwidth) then xwidth=3. 
sep = 'sep2_'
sep_svy_data = sep+'svy_DATA'
ds = tsample(sep_svy_data,trange,values=v,/average)
v+=.5
printdat,v,ds
mm = minmax(ds)
ytitle='Counts  (average)'
xtitle='ADC bin'
title = trange_str(trange)
if keyword_set(name) then title += '  '+name
if keyword_set( ienergy) then title +=  ' Ion Energy= '+ string(ienergy)
plot,v,ds,xtitle=xtitle,ytitle=ytitle,title=title,xrange=xrange,psym=10;,yrange=[.1,10000],/ylog

par = mgauss()
vr = v ge xrange[0] and v le xrange[1]
mx = max(ds * vr,bmx)
w = where(abs(v -v[bmx]-xshift) le xwidth)
par.binsize=1
par.shift=1
par.g.x0=bmx
par.g.s = 1.5
par.g.a = mx * par.g.s * 2
fit,v[w],ds[w],param=par,names='G'
oplot,v[w],ds[w],psym=4
;printdat,par
pf,par,color=6

printdat,par,out=strs

if keyword_set(ienergy) then begin
names = 'IG_'+ ['STEER','EXB','LENS','HDEF']
for i=0,n_elements(names)-1 do begin
   s = tsample(/average,names[i],trange)
   printdat,s,varname=names[i],out=str,/value
   append_array,strs,str
endfor
print,transpose(strs)
endif

lf = ''
for i=0,n_elements(strs)-1 do begin
    strs[i] = lf + strs[i]
    lf += '!c'
endfor

xyouts,.5,.9,strs,/normal

if keyword_set(png) then begin
    fname = name
    if keyword_set(ienergy) then fname  += '_'+strtrim(round(ienergy),2)+'keV_spec'
    makepng,fname,time=average(trange)
endif


end



pro set_tplot_options
store_data,'SEPx_SCIENCE',data = 'SEP?_SCIENCE_DATA SEP?_MEMDUMP_RANGE *NOTE',dlim={panel_size:5,yrange:[0,260]}
;store_data,'SEP_SCIENCE',data = 'SEP_SCIENCE_DATA SEP_SCIENCE_LABELS *NOTE',dlim={panel_size:5,yrange:[0,260]}
STORE_data,'SEPx_RATES',data='SEP?_HKP_NOPEAK_RATE SEP?_HKP_EVENT_CNTR SEP?_HKP_RATE_CNTR SEP?_SCIENCE_A',dlim={panel_size:2}
options,'SEP?_SCIENCE_DATA',spec=1,PANEL_SIZE=3,ZRANGE=[.8,500],ZLOG=1,yrange=[0,260.],ystyle=3
options,'SEP?_NOISE_DDATA',spec=1,PANEL_SIZE=1.5,ZRANGE=[.8,100],ZLOG=1,yrange=[0,60.],ystyle=2
options,'SEP?_NOISE_BASELINE SEP?_NOISE_SIGMA',colors='MBCGDR'
options,'SEP?_HKP_RATE_CNTR','linestyle';,1
;STORE_data,'sep_RATES',data='sep_HKP_NOPEAK_RATE sep_HKP_EVENT_CNTR sep_HKP_RATE_CNTR',dlim={panel_size:2}
options,'SEP?_HKP_NOPEAK_RATE',psym=-3 ;,colors='b'
options,'SEP?_HKP_?CMD_RATE',psym=-1,ystyle=3,psym_lim=300
ylim,'SEP?_RATES',.8,1e5,1
tplot_options,'no_interp',1
options,'SEP?_NOISE_BASELINE',constant=0.
options,'SEP?_SCIENCE_PSUM',panel_size=2
options,'SEP?_HKP_AMON_*',/ynozero
options,'GPIB_?',colors='rrggbb'


;colors='BBBBGGGGMMMMRRRRCCCCYYYY'
;store_data,'SEP2_MEMDUMP_RANGE',dlim=struct(constant=brr,labels=labels,labflag=2,psym=-1,linestyle=1,colors=colors)

sconst = findgen(26) * 10
slabs = strsplit('O T F OT FT FTO',' ',/extract)
slabs = ['   0-'+ slabs,'   1-'+slabs]
slabs = [replicate(' ',13),slabs,' ']
scolors = 'ddddddddddddd' + 'BGRMCYBGRMCY' +'d'
store_data,'SEPx_SCIENCE_LABELS',systime(1),transpose(sconst),dlim=struct(constant=sconst,labels=slabs,labpos=sconst,labflag=3)
options,'SEP?_SCIENCE_LABELS SEP?_SCIENCE_PSUM',colors =scolors
;options,'SEP_SCIENCE',constant = sconst
;ylim,'???_NOISE_BASELINE',-5,5
;ylim,'???_NOISE_SIGMA',0,6
options,'MISG_STATUS_ACT_FLAGS*',symsize=.4,psyms=4,psym_lim=400,colors='MBRRGMRBDMGRGRYY'

;store_data,'SEP_SCIENCE',data = 'SEP_SCIENCE_DATA SEP_SCIENCE_X *NOTE',dlim={panel_size:5,yrange:[0,260]}

case 1 of
1: tplot,'SEP?_HKP_VCMD_RATE SEP?_NOISE_BASELINE SEP?_NOISE_SIGMA SEP?_SCIENCE SEP?_RATES'
2: tplot,'SEP?_SCIENCE SEP?_SCIENCE_PSUM'
endcase
end


function get_samples,var,t,delta=delta
    if not keyword_set(delta) then delta=5.
    array = data_cut(var,t)
    for i=0,n_elements(t)-1 do begin
        array[i,*] = tsample(var,t[i]+[-delta,delta]/2. ,/average)
    endfor
return,array
end





pro mav_sep_record_baseline
tr = 0
    baseline = tsample('SEP?_NOISE_BASELINE',tr,/average,stdev=sig_baseline,/silent)
    sigma    = tsample('SEP?_NOISE_SIGMA',tr,/average,stdev=sig_sigma,/silent)
    res     = tsample('SEP?_NOISE_RES',average(tr))
u=-1
data = [[baseline],[sigma],[sig_baseline],[sig_sigma]]
sig  = [[baseline],[sigma],[sig_baseline],[sig_sigma]]
t = tr[0]
tstr = time_string(t)
file_open,'u','baselines.txt',unit=u
printf,u,tstr,data,res,format='(a20, 4("  ",6(" ",f7.4))," ",i2)'
free_lun,u
end


pro read_file,pathname=pathname,recbase=recbase,source=source,trange=trange,file=file
  starttime = systime(1)
  if keyword_set(recbase) then begin
;      if not keyword_set(pathname) then begin
 
 ;     endif
      recorder,recbase,get_procbutton=proc_on,set_procbutton=0,get_filename=rtfile
      if not keyword_set(pathname) then begin
         file = rtfile
         printdat,file
      endif else pathname= ''
  endif
  store_data,'sep* pfdpu*',/clear
  mav_apid_sep_handler,reset=1
  mav_apid_mag_handler,reset=0
  mav_apid_swea_handler,reset=0
  mav_apid_swia_handler,reset=0
  mav_apid_lpw_handler,reset=0
  mav_apid_sta_handler,reset=0
  if keyword_set(file) then rtfile = file
  mav_gse_cmnblk_file_read,pathname=pathname ,file=file,source=source,trange=trange
  if keyword_set(recbase) then  recorder,recbase,set_procbutton=proc_on
  ;set_pfdpu_tplot_options
  ;tplot,'sep?_svy_COUNTS_TOTAL sep?_svy_DATA sep?_noise_SIGMA sep?_hkp_RATE_CNTR CMNBLK_USER_NOTE'
  dprint,'Done in ',systime(1)-starttime,' seconds'
end


function time_debug,t
common time_debug_com,time0
if keyword_set(t) then time0 = time_double(t)
return,time0
end



;pro mav_sep_crib


if 0 and ~keyword_set(recbase) then begin
    recorder,recbase,host='128.32.13.158',port=2025,exec_proc='gseos_cmnblk_bhandler',destination='~/RealTime/CMNBLK_YYYYMMDD_hhmmss.dat'
;    mav_apid_sep_handler,/reset
;    mav_apid_mag_handler,/reset
    mvn_sep_handler,/reset,/set_realtime
    mvn_mag_handler,/reset,/set_realtime
;    mvn_apid_mag_handler,/reset
    exec,tplotbase,  exec_text=["tplot,verbose=0,wshow=0,trange=systime(1)+[-.95,.05]*60* 20",'timebar,systime(1)']
;    exec,tekbase,  exec_text="tek_screen_shot,prefix='tek/',window=8"
    dprint,recbase,tekbase,tplotbase,/phelp
endif


;if size(/type,realtime) eq 0 then realtime=1

if 0 then begin
pathname=0
;pathname = 'maven/sep/prelaunch_tests/EM2/20120131_222340_preamp_flt_g1/gseos_common_msg.dat'
;pathname = 'maven/sep/prelaunch_tests/EM2/20120131_231216_preamp_flt_g2/gseos_common_msg.dat'
;pathname = 'maven/sep/prelaunch_tests/EM2/20120201_004351_preamp_flt_g3/gseos_common_msg.dat'
;pathname = 'maven/sep/prelaunch_tests/realtime/CMNBLK_20120211_015211_g4.dat'
;append_array,pathname,'maven/sep/prelaunch_tests/realtime/CMNBLK_20120212_050247_g4.dat'
;pathname = 'maven/sep/prelaunch_tests/realtime/CMNBLK_20120215_005308_g6.dat'
;pathname = 'maven/sep/prelaunch_tests/realtime/CMNBLK_20120215_014650_g7.dat'
;pathname = 'maven/sep/prelaunch_tests/EM2/20120215_023302_etu/gseos_common_msg.dat'
;pathname = 'maven/sep/prelaunch_tests/EM2/20120219_073140_exttp/gseos_common_msg.dat'
;pathname = 'maven/sep/prelaunch_tests/FM1/20120315_215726_/gseos_common_msg.dat'         ; actuator test (anomaly)
;pathname = 'maven/sep/prelaunch_tests/FM1/20120317_*/gseos_common_msg.dat'
;append_array,pathname, 'maven/sep/prelaunch_tests/FM1/20120316_012812_idle/gseos_common_msg.dat'   ; nothing
;append_array,pathname, 'maven/sep/prelaunch_tests/FM1/20120316_013917_fltspare2_attentest/gseos_common_msg.dat
;append_array,pathname, 'maven/sep/prelaunch_tests/FM1/20120316_015150_fltspare2_attentest/gseos_common_msg.dat'  ; actuator test
;append_array,pathname, 'maven/sep/prelaunch_tests/FM1/20120316_225529_fltspare2_attentest/gseos_common_msg.dat'
;append_array,pathname, 'maven/sep/prelaunch_tests/FM1/20120317_003542_fltspare1_attentest/gseos_common_msg.dat'  ; voltage test
;pathname = 'maven/sep/prelaunch_tests/bench2/20120416_182221_ATT_tests/gseos_common_msg.dat
;pathname = 'maven/sep/prelaunch_tests/bench1/2012*/gseos_common_msg.dat'   ; most recent
pathname =0
;pathname = 'maven/sep/prelaunch_tests/bench1/20120405_190838_DAP007_DFE05_DFE07/gseos_common_msg.dat'  ;  this file seems to have lots of memory errors
append_array,pathname,'maven/sep/prelaunch_tests/bench1/20120405_225152_DAP007_DFE05_DFE07/gseos_common_msg.dat
;pathname =0
;append_array,pathname,'maven/sep/prelaunch_tests/bench1/20120427_164952_DAP008_D1_D4_radsample/gseos_common_msg.dat' ;very long
;pathname = 'maven/sep/prelaunch_tests/bench2/20120418_171611_sens4_atttest/gseos_common_msg.dat
;pathname = 'maven/sep/prelaunch_tests/bench3_dpu/20120510_094634_sepflight_test1/commonBlock_20120510_094634_sepflight_test1_initialpoweron.dat'  ; nothing
;append_array,pathname, 'maven/sep/prelaunch_tests/bench3_dpu/20120510_094634_sepflight_test1/commonBlock_20120510_094634_sepflight_test1_firsttests.dat' ;  has SEP PFDPU packets and apid30
pathname =0
append_array,pathname, 'maven/sep/prelaunch_tests/bench3_dpu/20120510_102809_sepflight_test2/commonBlock_20120510_102809_sepflight_test2_long.dat' ; has beginning of CPT
;append_array,pathname, 'maven/sep/prelaunch_tests/bench3_dpu/20120510_102809_sepflight_test2/commonBlock_20120510_102809_sepflight_test2.dat'  ; short snippet with nothing interesting
;append_array,pathname, 'maven/sep/prelaunch_tests/bench3_dpu/20120510_160417_SEP_idle/commonBlock_20120510_160417_SEP_idle.dat';  nothing useful
;pathname = 'maven/sep/prelaunch_tests/bench3_dpu/20120510_161751_sepcheck/commonBlock_20120510_161751_sepcheck.dat'  ; apid 30 only (not reg packets)
;pathname = 'maven/sep/prelaunch_tests/bench3_dpu/20120510_165457_SEP_check/commonBlock_20120510_165457_SEP_check.dat'  ; apid 30 only

pathname = 'maven/sep/prelaunch_tests/bench4_Addition125/20120613_004442_FM1_SEP_CPT/commonBlock_20120613_004442_FM1_SEP_CPT.dat'   ; FM test without sensors
pathname = 'maven/sep/prelaunch_tests/bench4_Addition125/20120619_001229_FM_SEP1_TEST/commonBlock_20120619_001229_FM_SEP1_TEST.dat' ; first test with sensors ; lots of noise counts presumably from act polling
pathname = 'maven/sep/prelaunch_tests/bench4_Addition125/20120621_090402_SEP2_FM_CPT/commonBlock_20120621_090402_SEP2_FM_CPT.dat' ;  SEP2 only

;pathname = 0
;append_array,pathname,'maven/dpu/prelaunch/FM/20120621_200843_FLIGHT_SEPACT/commonBlock_20120621_200843_FLIGHT_SEPACT.dat
;append_array,pathname,'maven/dpu/prelaunch/FM/20120622_220341_FM_compat/commonBlock_20120622_220341_FM_compat.dat
;append_array,pathname,'maven/dpu/prelaunch/FM/20120622_230023_FM_COMPAT_TEST/commonBlock_20120622_230023_FM_COMPAT_TEST.dat'  ; compat test
;append_array,pathname,'maven/dpu/prelaunch/FM/20120623_015738_sep_script_test/commonBlock_20120623_015738_sep_script_test.dat' ; First Dual CPT
;pathname=0

;;;;;append_array,pathname,'maven/dpu/prelaunch/FM/20120623_015738_sep_script_test/20120623_015738_log.log
;append_array,pathname,'maven/dpu/prelaunch/FM/20120623_015738_sep_script_test/engNsciPkts_20120623_015738_sep_script_test.dat
;;;;;append_array,pathname,'maven/dpu/prelaunch/FM/20120622_230023_FM_COMPAT_TEST/engNsciPkts_20120622_230023_FM_COMPAT_TEST.dat
;pathname = 'maven/dpu/prelaunch/FM/2012062[67]*/common*.dat'
;pathname = 0
;append_array,pathname,'maven/dpu/prelaunch/FM/20120626_202024_FM1_PFDPUSELFCOMP/commonBlock_20120626_202024_FM1_PFDPUSELFCOMP.dat'
;append_array,pathname,'maven/dpu/prelaunch/FM/20120626_213655_FM1_PFDPUSELFCOMP/commonBlock_20120626_213655_FM1_PFDPUSELFCOMP.dat'
;append_array,pathname,'maven/dpu/prelaunch/FM/20120626_235552_PFDPUSELFCOMP/commonBlock_20120626_235552_PFDPUSELFCOMP.dat'
;append_array,pathname,'maven/dpu/prelaunch/FM/20120627_020559_FM1_PFDPUSELFCOMP/commonBlock_20120627_020559_FM1_PFDPUSELFCOMP.dat'; 10 minute compat test.
;pathname = 'maven/dpu/prelaunch/FM/20120711_203848_FM_PFDPU_Recheck_REG2/commonBlock_20120711_203848_FM_PFDPU_Recheck_REG2.dat' ; First actuator test
;pathname = 'maven/dpu/prelaunch/FM/20120717*/commonBlock_20120717*.dat'   ;Actuator tests
;pathname = 'maven/dpu/prelaunch/FM/20120717_233006_FM_SEP_TEST/commonBlock_20120717_233006_FM_SEP_TEST.dat' ; actuator tests (left closed)
;append_array,pathname , 'maven/dpu/prelaunch/FM/20120718_024727_FM1_STASTM/commonBlock_20120718_024727_FM1_STASTM.dat'   ; STA tests (SEP1 open)
;pathname = 'maven/dpu/prelaunch/FM/20120718*/commonBlock_20120718*.dat'   ; static testing
;pathname = 'maven/dpu/prelaunch/FM/20120719_010021_FM_SEP_CPT/commonBlock_20120719_010021_FM_SEP_CPT.dat'  ; Last CPT befor inspections, has wrong MAP 

;pathname = 'maven/dpu/prelaunch/FM/2012071*/commonBlock_2012071*.dat'
;pathname =  'maven/dpu/prelaunch/live/flight/emc-2012-08-01/initial/common_block.dat'  &  last_version = 1
pathname =  'maven/dpu/prelaunch/live/flight/emc-2012-08-12/initial/common_block.dat'  &  last_version = 1
pathname = 'maven/dpu/prelaunch/EM/commonBlock_DayInLife_Decomped.dat'
;pathname = 'maven/dpu/prelaunch/EM/commonBlock_DayInLife_Comped.dat'
pathname = 'maven/dpu/prelaunch/FM/20121118_045846_FM_DayInLife5/commonBlock_20121118_045846_FM_DayInLife5.dat'
pathname = 'maven/dpu/prelaunch/live/flight/DIL6-2012-11-20/initial/common_block.dat'
pathname = 'maven/dpu/prelaunch/live/flight/COMPAT_CPT_2012-11-21/initial/common_block.dat
pathname = 'maven/dpu/prelaunch/FM/20121128_150106_FM1-SEP_CPT_LM1/commonBlock_20121128_150106_FM1-SEP_CPT_LM1.dat'  ; First CPT at LM (bench test)
;pathname = 'maven/dpu/prelaunch/live/flight/DecompSplit_At_20121206_2041/initial/common_block.dat'
;append_array,pathname, 'maven/dpu/prelaunch/live/flight/DecompSplit_At_20121206_231620/initial/common_block.dat'
;
;rjBKh6H1
pathname = 'maven/dpu/prelaunch/live/flight/Split_At_20121207_234554/initial/common_block.dat'  ; Data on 9th no testing just collection

pathname = 'maven/dpu/prelaunch/live/flight/Split_At_20121216_235045/initial/common_block.dat'  ; day in life test?  (2015 aug 3)
pathname = 'maven/dpu/prelaunch/live/flight/Split_At_20130118_201204/initial/common_block.dat'
pathname = 'maven/dpu/prelaunch/live/flight/Split_At_20130226_160002/initial/common_block.dat
pathname = 'maven/dpu/prelaunch/live/flight/Split_At_20130301_152726/initial/common_block.dat
pathname = ['maven/dpu/prelaunch/live/flight/Split_At_20130312_224737/initial/common_block.dat','maven/dpu/prelaunch/live/flight/Split_At_20130313_181414/initial/common_block.dat']
pathname = 'maven/dpu/prelaunch/live/flight/Split_At_20130320_151843/initial/common_block.dat'
pathname = 'maven/dpu/prelaunch/live/flight/Split_At_20130327_152615/initial/common_block.dat' ; SEP/APP boom test
pathname = 'maven/dpu/prelaunch/live/flight/Split_At_20130327_171142/initial/common_block.dat'
pathname = 'maven/dpu/prelaunch/live/flight/Split_At_20130328_143200/initial/common_block.dat'
pathname = 'maven/dpu/prelaunch/live/flight/Split_At_20130404_205221/initial/common_block.dat'

pathname = 'maven/data/sci/pfp/ATLO/mvn_ATLO_pfp_all_l0_20130502_v1.dat'  ; Self tests (after EMC tests?)  Room Lights on for part of test.

pathname = 'maven/data/sci/pfp/ATLO/mvn_ATLO_pfp_all_l0_20130508_v1.dat'  ; Deep dip TEST data  simulated date is 2014/12/29

pathname = 'maven/dpu/prelaunch/live/flight/Split_At_20130520_145437/initial/common_block.dat'
pathname = 'maven/dpu/prelaunch/ATLO/20130521_153825_atlo_l0.dat'
pathname = 'maven/dpu/prelaunch/live/flight/Split_At_20130529_194036/initial/common_block.dat'  ; start of ATLO themal vac 
pathname = 'maven/ITF/ATLOData/ATLO/OnPadFunctional/OnPadFunctional_ATLO_20130918_SideA_pfp_all_l0_v1.dat
pathname = 'maven/ITF/FlatSat/20131106_195401_cmnToSplit/common_block.dat'

pathname = 'maven/dpu/prelaunch/live/flight/Split_At_20131109_010021/initial/common_block.dat

if 0 then begin
last_version=0
source = mav_file_source()
stop
file = file_retrieve(pathname,last_version=last_version,_extra=source)
stop
endif

endif

;file=0

;pathname=0

;printdat,pathname
; file = dialog_pickfile(/multiple)




; .edit mav_sep_dap_calibrate



if 0 then begin


orbdata = mvn_orbit_num()
store_data,'orbnum',orbdata.peri_time,orbdata.num,dlimit={ytitle:'Orbit'}
tplot,var_label='orbnum'


mk = mvn_spice_kernels(/all,/load,verbose=1,trange=tr)
frame='MSO'
scale = 3390.   ; mars radius in km
dprint,'Create some TPLOT variables with position data and then plot it.'
spice_position_to_tplot,'MAVEN','Mars',frame='MSO',res=300d,scale=1000.,name=n1  ,trange=[time_double('2014-9-22'),systime(1)+1e5]
xyz_to_polar,n1
;spice_position_to_tplot,'Earth','SUN',frame=frame,res=3600d*24,scale=scale,name=n2
;spice_position_to_tplot,'MARS','SUN',frame=frame,res=3600d*24,scale=scale,name=n3
;store_data,'POS',data=[n1,n2,n3]


maven_orbit_tplot

maven_orbit_snap, /prec

MAG1_offset_hg   = [0.451950, 0.258110, -1.01687]
MAG1_offset_lg   = [0.462475, 0.542162, -0.956552]


mag1_offset_xx  = [-0.47123703, 1.3987961, 1.3944077]

spice_qrot_to_tplot,'MAVEN_SPACECRAFT','MSO',get_omega=3,res=30d,names=tn,check_obj='MAVEN_SPACECRAFT' ,error=  .5 *!pi/180  ; .5 degree error
spice_qrot_to_tplot,'MAVEN_SPACECRAFT','MAVEN_APP',get_omega=3,res=30d,names=tn,check_obj='MAVEN_SPACECRAFT' ,error=  .5 *!pi/180  ; .5 degree error

mvn_mag_handler,offset1=1 ;  = mag1_offset_xx
SPICE_VECTOR_ROTATE_TPLOT,'mvn_mag1_svy_Bcor','MSO',check_objects='maven_spacecraft'

options,'mvn_mag1_svy_BAVG',spice_frame='MAVEN_MAG1'
SPICE_VECTOR_ROTATE_TPLOT,'mvn_mag1_svy_BAVG','MSO',check_objects='maven_spacecraft'



options,'MAG_STS',spice_frame='MAVEN_SPACECRAFT'


SPICE_VECTOR_ROTATE_TPLOT,'MAG_STS','MAVEN_MAG1',check_objects='maven_spacecraft'
SPICE_VECTOR_ROTATE_TPLOT,'MAG_STS','MAVEN_MSO',check_objects='maven_spacecraft'

t='2014-9-23'
q_msc_to_mag1 =spice_body_att('maven_spacecraft','maven_mag1',t,/quat) 
q_mag1_to_MSC =spice_body_att('maven_mag1','maven_spacecraft',t,/quat) 
q_mag2_to_MSC =spice_body_att('maven_mag2','maven_spacecraft',t,/quat) 

;spice_vector_rotate,

spice_vector_rotate_tplot,'mvn_mag?_svy_BRAW',def_frame,verbose=3,trange=tr
endif



timespan,'14 11 10',15

mvn_sep_load,/ancil

end


