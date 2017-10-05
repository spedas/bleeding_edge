;+
; NAME: rbsp_efw_make_l2_hsk.pro
; SYNTAX: 
; PURPOSE: creates a CDF file of RBSP housekeeping values 
; INPUT: sc = 'a' or 'b'
;		 date = 'yyyy-mm-dd'
; OUTPUT: 
; KEYWORDS: 
; requires the skeleton cdf file rbsp?_hsk_00000000.cdf
; HISTORY: Created by Aaron W Breneman  Nov 2014
; VERSION: 
;   $LastChangedBy: aaronbreneman $
;   $LastChangedDate: 2014-12-10 08:02:17 -0800 (Wed, 10 Dec 2014) $
;   $LastChangedRevision: 16442 $
;   $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/missions/rbsp/efw/l1_to_l2/rbsp_efw_make_l2_hsk.pro $
;-

pro rbsp_efw_make_l2_hsk,sc,date,folder=folder,version=version


	rbsp_efw_init
	rbspx = 'rbsp'+sc

	store_data,tnames(),/delete
	timespan,date


	skeleton = 'rbsp'+sc+'_hsk_00000000.cdf'
	source_file='~/Desktop/code/Aaron/RBSP/l2_processing_cribs/' + skeleton

	folder ='~/Desktop/code/Aaron/RBSP/l2_processing_cribs/'
;	; make sure we have the skeleton CDF
;	source_file=file_search(source_file,count=found) ; looking for single file, so count will return 0 or 1
;	if ~found then begin
;		dprint,'Could not find l2_combo v'+vskeleton+' skeleton CDF, returning.'
;		return
;	endif
	; fix single element source file array
	source_file=source_file[0]



	rbsp_load_efw_hsk,probe=probe,/get_support_data


;get times for flag variables
        get_data,rbspx+'_efw_hsk_idpu_analog_IMON_BEB',data=times
        times = times.x




;**************************************************
;Various flag values
;**************************************************

 ;--------------------------------------------------
  ;load eclipse times
  ;--------------------------------------------------



  rbsp_load_eclipse_predict,sc,date,$
                            local_data_dir='~/data/rbsp/',$
                            remote_data_dir='http://themis.ssl.berkeley.edu/data/rbsp/'

  get_data,'rbsp'+sc + '_umbra',data=eu
  get_data,'rbsp'+sc + '_penumbra',data=ep


  eclipse = replicate(0.,n_elements(times))


;set the eclipse flag in this program
  padec = 5.*60.  ;plus/minus value (sec) outside of the eclipse start and stop times for throwing the eclipse flag

;Umbra
  if is_struct(eu) then begin
     for bb=0,n_elements(eu.x)-1 do begin
        goo = where((times ge (eu.x[bb]-padec)) and (times le (eu.x[bb]+eu.y[bb]+padec)))
        if goo[0] ne -1 then eclipse[goo] = 1
     endfor
  endif
;Penumbra
  if is_struct(ep) then begin
     for bb=0,n_elements(ep.x)-1 do begin
        goo = where((times ge (ep.x[bb]-padec)) and (times le (ep.x[bb]+ep.y[bb]+padec)))
        if goo[0] ne -1 then eclipse[goo] = 1
     endfor
  endif




;--------------------------------------------------
;Determine times of antenna deployment
;--------------------------------------------------


  dep = rbsp_efw_boom_deploy_history(date,allvals=av)

  if sc eq 'a' then begin
     ds12 = strmid(av.deploystarta12,0,10)  
     ds34 = strmid(av.deploystarta34,0,10)  
     ds5 = strmid(av.deploystarta5,0,10)  
     ds6 = strmid(av.deploystarta6,0,10)  

     de12 = strmid(av.deployenda12,0,10)  
     de34 = strmid(av.deployenda34,0,10)  
     de5 = strmid(av.deployenda5,0,10)  
     de6 = strmid(av.deployenda6,0,10)  

     deps_alltimes = time_double([av.deploystarta12,av.deploystarta34,av.deploystarta5,av.deploystarta6])
     depe_alltimes = time_double([av.deployenda12,av.deployenda34,av.deployenda5,av.deployenda6])
  endif else begin
     ds12 = strmid(av.deploystartb12,0,10)  
     ds34 = strmid(av.deploystartb34,0,10)  
     ds5 = strmid(av.deploystartb5,0,10)  
     ds6 = strmid(av.deploystartb6,0,10)  

     de12 = strmid(av.deployendb12,0,10)  
     de34 = strmid(av.deployendb34,0,10)  
     de5 = strmid(av.deployendb5,0,10)  
     de6 = strmid(av.deployendb6,0,10)  

     deps_alltimes = time_double([av.deploystartb12,av.deploystartb34,av.deploystartb5,av.deploystartb6])
     depe_alltimes = time_double([av.deployendb12,av.deployendb34,av.deployendb5,av.deployendb6])
  endelse


;all the dates of deployment times (note: all deployments start and
;end on same date)
  dep_alldates = [ds12,ds34,ds5,ds6]

  ant_deploy = replicate(0,n_elements(times))


  goo = where(date eq dep_alldates)
  if goo[0] ne -1 then begin
     ;;for each deployment find timerange and flag
     for y=0,n_elements(goo)-1 do begin
        boo = where((times ge deps_alltimes[goo[y]]) and (times le depe_alltimes[goo[y]]))
        if boo[0] ne -1 then ant_deploy[boo] = 1
     endfor
  endif

;--------------------------------------------------
;Determine maneuver times
;--------------------------------------------------


  maneuver = replicate(0,n_elements(times))

  m = rbsp_load_maneuver_file(sc,date)
  if is_struct(m) then begin
     for bb=0,n_elements(m.m0)-1 do begin
        goo = where((times ge m.m0[bb]) and (times le m.m1[bb]))
        if goo[0] ne -1 then maneuver[goo] = 1
     endfor
  endif


;--------------------------------------------------
;Determine times of bias sweeps
;--------------------------------------------------

get_data, 'rbsp'+sc+'_efw_hsk_beb_analog_CONFIG0', data = BEB_config
if is_struct(BEB_config) then begin
	bias_sweep = intarr(n_elements(BEB_config.x))
	boo = where(BEB_config.y eq 64)
	if boo[0] ne -1 then bias_sweep[boo] = 1
	store_data,'bias_sweep',data={x:BEB_config.x,y:bias_sweep}
	tinterpol_mxn,'bias_sweep',times
	;; ylim,['bias_sweep','bias_sweep_interp'],0,1.5
	;; tplot,['bias_sweep','bias_sweep_interp']
	get_data,'bias_sweep_interp',data=bias_sweep
	bias_sweep = bias_sweep.y
endif 


;------------------------------------------------
;ADD AUTO BIAS TO FLAG VALUES
;------------------------------------------------
  
;; AutoBias starts actively controlling the bias currents at V12 = -1.0 V,
;; ramping down the magnitude of the bias current so that when V12 = 0.0 V,
;; the bias current is very near to zero after starting out around -20
;; nA/sensor.

;; For V12 > 0.0 V, the bias current continues to increase (become more
;; positive), although at a slower rate, 0.2 nA/V or something like that.


;Auto Bias flag values. From 'rbsp?_efw_hsk_idpu_fast_TBD'
;Bit	Value	Meaning
;3	8	Toggles off and on every other cycle when AutoBias is;
;		active.
;2	4	One when AutoBias is controlling the bias, Zero when
;		AutoBias is not controlling the bias.
;1	2	One when BIAS3 and BIAS4 can be controlled by AUtoBias,
;		zero otherwise.
;0	1	One when BIAS1 and BIAS2 can be controlled by AUtoBias,
;		zero otherwise.



  ;Find times when auto biasing is active
  get_data,'rbsp'+sc+'_efw_hsk_idpu_fast_TBD',data=tbd
  tbd.y = floor(tbd.y)
  auto_bias = intarr(n_elements(tbd.x))

  ;Possible flag values for on and off
  ab_off = [1,2,3,8,10,11]
  ab_on = [4,5,6,7,12,13,14,15]

  goo = where((tbd.y eq 4) or (tbd.y eq 5) or (tbd.y eq 6) or (tbd.y eq 7) or $
              (tbd.y eq 12) or (tbd.y eq 13) or (tbd.y eq 14) or (tbd.y eq 15))
  if goo[0] ne -1 then auto_bias[goo] = 1
  
  store_data,'auto_bias',data={x:tbd.x,y:auto_bias}
  ;; options,['rbsp'+sc+'_efw_hsk_idpu_fast_TBD','auto_bias'],'psym',4
  ;; tplot,['rbsp'+sc+'_efw_hsk_idpu_fast_TBD','auto_bias','rbsp'+sc+'_state_lshell']
  ;; timebar,eu.x
  ;; timebar,eu.x+eu.y


  tinterpol_mxn,'auto_bias',times
  ;; tplot,['*IBIAS*','auto_bias','auto_bias_interp']

  get_data,'auto_bias_interp',data=auto_bias
  auto_bias = auto_bias.y



;--------------------------------------------------
;ADD IN ACTUAL BIAS CURRENTS
;--------------------------------------------------

 tinterpol_mxn,rbspx+'_efw_hsk_beb_analog_IEFI_IBIAS1',times
 tinterpol_mxn,rbspx+'_efw_hsk_beb_analog_IEFI_IBIAS2',times
 tinterpol_mxn,rbspx+'_efw_hsk_beb_analog_IEFI_IBIAS3',times
 tinterpol_mxn,rbspx+'_efw_hsk_beb_analog_IEFI_IBIAS4',times
 tinterpol_mxn,rbspx+'_efw_hsk_beb_analog_IEFI_IBIAS5',times
 tinterpol_mxn,rbspx+'_efw_hsk_beb_analog_IEFI_IBIAS6',times
;tplot,['*IBIAS*','rbsp'+sc+'_efw_hsk_idpu_fast_TBD']

 get_data,rbspx+'_efw_hsk_beb_analog_IEFI_IBIAS1_interp',data=ib1
 get_data,rbspx+'_efw_hsk_beb_analog_IEFI_IBIAS2_interp',data=ib2
 get_data,rbspx+'_efw_hsk_beb_analog_IEFI_IBIAS3_interp',data=ib3
 get_data,rbspx+'_efw_hsk_beb_analog_IEFI_IBIAS4_interp',data=ib4
 get_data,rbspx+'_efw_hsk_beb_analog_IEFI_IBIAS5_interp',data=ib5
 get_data,rbspx+'_efw_hsk_beb_analog_IEFI_IBIAS6_interp',data=ib6


 ibias = [[ib1.y],[ib2.y],[ib3.y],[ib4.y],[ib5.y],[ib6.y]]



;get_data,rbspx+'_efw_hsk_idpu_analog_IMON_BEB',data=dat
	epoch = tplot_time_to_epoch(times,/epoch16)

	tinterpol_mxn,rbspx+'_'+'efw_hsk_idpu_eng_SC_EFW_SSR',times
	tinterpol_mxn,rbspx+'_'+'efw_hsk_idpu_fast_B1_EVALMAX',times
	tinterpol_mxn,rbspx+'_'+'efw_hsk_idpu_fast_B1_PLAYREQ',times
	tinterpol_mxn,rbspx+'_'+'efw_hsk_idpu_fast_B1_RECBBI',times
	tinterpol_mxn,rbspx+'_'+'efw_hsk_idpu_fast_B1_RECECI',times
	tinterpol_mxn,rbspx+'_'+'efw_hsk_idpu_fast_B1_THRESH',times
	tinterpol_mxn,rbspx+'_'+'efw_hsk_idpu_fast_B2RECSTATE',times
	tinterpol_mxn,rbspx+'_'+'efw_hsk_idpu_fast_B2_THRESH',times
	tinterpol_mxn,rbspx+'_'+'efw_hsk_idpu_fast_B2_EVALMAX',times
	tinterpol_mxn,rbspx+'_efw_hsk_idpu_eng_IO_ECCSING',times
	tinterpol_mxn,rbspx+'_efw_hsk_idpu_eng_IO_ECCMULT',times
	tinterpol_mxn,rbspx+'_efw_hsk_idpu_eng_RSTCTR',times
	tinterpol_mxn,rbspx+'_efw_hsk_idpu_fast_RSTFLAG',times


	get_data,rbspx+'_'+'efw_hsk_idpu_analog_IMON_BEB',data=imon_beb
	get_data,rbspx+'_'+'efw_hsk_idpu_analog_IMON_IDPU',data=imon_idpu
        get_data,rbspx+'_'+'efw_hsk_idpu_analog_P33IMON',data=imon_p33
        get_data,rbspx+'_'+'efw_hsk_idpu_analog_P15IMON',data=imon_p15

	get_data,rbspx+'_'+'efw_hsk_idpu_analog_P33VD',data=p33vd
	get_data,rbspx+'_'+'efw_hsk_idpu_analog_P15VD',data=p15vd
	get_data,rbspx+'_'+'efw_hsk_idpu_analog_TMON_LVPS',data=lvps
	get_data,rbspx+'_'+'efw_hsk_idpu_analog_TEMP_FPGA',data=fpga
	get_data,rbspx+'_'+'efw_hsk_idpu_analog_TMON_AXB5',data=axb5
	get_data,rbspx+'_'+'efw_hsk_idpu_analog_TMON_AXB6',data=axb6
	get_data,rbspx+'_'+'efw_hsk_idpu_analog_IMON_FVX',data=fvx
	get_data,rbspx+'_'+'efw_hsk_idpu_analog_IMON_FVY',data=fvy
	get_data,rbspx+'_'+'efw_hsk_idpu_analog_IMON_FVZ',data=fvz
	get_data,rbspx+'_'+'efw_hsk_idpu_eng_SC_EFW_SSR_interp',data=ssr
	get_data,rbspx+'_'+'efw_hsk_idpu_fast_B1_EVALMAX_interp',data=b1_evalmax
	get_data,rbspx+'_'+'efw_hsk_idpu_fast_B1_PLAYREQ_interp',data=b1_playreq
	get_data,rbspx+'_'+'efw_hsk_idpu_fast_B1_RECBBI_interp',data=b1_recbbi
	get_data,rbspx+'_'+'efw_hsk_idpu_fast_B1_RECECI_interp',data=b1_receci
	get_data,rbspx+'_'+'efw_hsk_idpu_fast_B1_THRESH_interp',data=b1_thresh
	get_data,rbspx+'_'+'efw_hsk_idpu_fast_B2RECSTATE_interp',data=b2_recstate
	get_data,rbspx+'_'+'efw_hsk_idpu_fast_B2_THRESH_interp',data=b2_thresh
	get_data,rbspx+'_'+'efw_hsk_idpu_fast_B2_EVALMAX_interp',data=b2_evalmax
	get_data,rbspx+'_efw_hsk_idpu_eng_IO_ECCSING_interp',data=eccsing
	get_data,rbspx+'_efw_hsk_idpu_eng_IO_ECCMULT_interp',data=eccmult
	get_data,rbspx+'_efw_hsk_idpu_eng_RSTCTR_interp',data=rstctr
	get_data,rbspx+'_efw_hsk_idpu_fast_RSTFLAG_interp',data=rstflag

        get_data,rbspx+'_efw_hsk_idpu_analog_VMON_BEB_N10VA',data=n10va
        get_data,rbspx+'_efw_hsk_idpu_analog_VMON_BEB_P10VA',data=p10va
        get_data,rbspx+'_efw_hsk_idpu_analog_VMON_BEB_P5VA',data=p5va_b
        get_data,rbspx+'_efw_hsk_idpu_analog_VMON_BEB_P5VD',data=p5vd_b
        get_data,rbspx+'_efw_hsk_idpu_analog_VMON_IDPU_N10VA',data=n10va
        get_data,rbspx+'_efw_hsk_idpu_analog_VMON_IDPU_N5VA',data=n5va
        get_data,rbspx+'_efw_hsk_idpu_analog_VMON_IDPU_P10VA',data=p10va
        get_data,rbspx+'_efw_hsk_idpu_analog_VMON_IDPU_P18VD',data=p18vd
        get_data,rbspx+'_efw_hsk_idpu_analog_VMON_IDPU_P36VD',data=p36vd
        get_data,rbspx+'_efw_hsk_idpu_analog_VMON_IDPU_P5VA',data=p5va_i
        get_data,rbspx+'_efw_hsk_idpu_analog_VMON_IDPU_P5VD',data=p5vd_i



	filename = 'rbsp'+sc+'_hsk_'+strjoin(strsplit(date,'-',/extract))+'.cdf'

	file_copy,source_file,folder+filename,/overwrite

	cdfid = cdf_open(folder+filename)
	cdf_control, cdfid, get_var_info=info, variable='epoch'

	cdf_varput,cdfid,'epoch',epoch


	if is_struct(imon_beb) then cdf_varput,cdfid,'IMON_IDPU_BEB',imon_beb.y
	if is_struct(imon_idpu) then cdf_varput,cdfid,'IMON_IDPU_IDPU',imon_idpu.y
	if is_struct(fvx) then cdf_varput,cdfid,'IMON_IDPU_FVX',fvx.y
	if is_struct(fvy) then cdf_varput,cdfid,'IMON_IDPU_FVY',fvy.y
	if is_struct(fvz) then cdf_varput,cdfid,'IMON_IDPU_FVZ',fvz.y
        if is_struct(imon_p33) then cdf_varput,cdfid,'IMON_IDPU_P33',imon_p33.y
        if is_struct(imon_p15) then cdf_varput,cdfid,'IMON_IDPU_P15',imon_p15.y

	if is_struct(lvps) then cdf_varput,cdfid,'TMON_IDPU_LVPS',lvps.y
	if is_struct(axb5) then cdf_varput,cdfid,'TMON_IDPU_AXB5',axb5.y
	if is_struct(axb6) then cdf_varput,cdfid,'TMON_IDPU_AXB6',axb6.y
        if is_struct(fpga) then cdf_varput,cdfid,'TMON_IDPU_FPGA',fpga.y

	if is_struct(p33vd) then cdf_varput,cdfid,'VMON_IDPU_P33VD',p33vd.y
	if is_struct(p15vd) then cdf_varput,cdfid,'VMON_IDPU_P15VD',p15vd.y
        if is_struct(n10va) then cdf_varput,cdfid,'VMON_BEB_N10VA',n10va.y
        if is_struct(p10va) then cdf_varput,cdfid,'VMON_BEB_P10VA',p10va.y
        if is_struct(p5va_b) then cdf_varput,cdfid,'VMON_BEB_P5VA',p5va_b.y
        if is_struct(p5vd_b) then cdf_varput,cdfid,'VMON_BEB_P5VD',p5vd_b.y
        if is_struct(n10va) then cdf_varput,cdfid,'VMON_IDPU_N10VA',n10va.y
        if is_struct(n5va) then cdf_varput,cdfid,'VMON_IDPU_N5VA',n5va.y
        if is_struct(p10va) then cdf_varput,cdfid,'VMON_IDPU_P10VA',p10va.y
        if is_struct(p18vd) then cdf_varput,cdfid,'VMON_IDPU_P18VD',p18vd.y
        if is_struct(p36vd) then cdf_varput,cdfid,'VMON_IDPU_P36VD',p36vd.y
        if is_struct(p5va_i) then cdf_varput,cdfid,'VMON_IDPU_P5VA',p5va_i.y
        if is_struct(p5vd_i) then cdf_varput,cdfid,'VMON_IDPU_P5VD',p5vd_i.y

	if is_struct(ssr) then cdf_varput,cdfid,'SSR_FILLPER',ssr.y
	if is_struct(b1_evalmax) then cdf_varput,cdfid,'B1_EVALMAX',b1_evalmax.y
	if is_struct(b1_playreq) then cdf_varput,cdfid,'B1_PLAYREQ',b1_playreq.y
	if is_struct(b1_recbbi) then cdf_varput,cdfid,'B1_RECBBI',b1_recbbi.y
	if is_struct(b1_receci) then cdf_varput,cdfid,'B1_RECECI',b1_receci.y
	if is_struct(b1_thresh) then cdf_varput,cdfid,'B1_THRESH',b1_thresh.y
	if is_struct(b2_recstate) then cdf_varput,cdfid,'B2_RECSTATE',b2_recstate.y
	if is_struct(b2_thresh) then cdf_varput,cdfid,'B2_THRESH',b2_thresh.y
	if is_struct(b2_evalmax) then cdf_varput,cdfid,'B2_EVALMAX',b2_evalmax.y
	if is_struct(eccsing) then cdf_varput,cdfid,'IO_ECCSING',eccsing.y
	if is_struct(eccmult) then cdf_varput,cdfid,'IO_ECCMULT',eccmult.y
	if is_struct(rstctr) then cdf_varput,cdfid,'RSTCTR',rstctr.y
	if is_struct(rstflag) then cdf_varput,cdfid,'RSTFLAG',rstflag.y
        

        cdf_varput,cdfid,'eclipse',eclipse
        cdf_varput,cdfid,'auto_bias',auto_bias
        cdf_varput,cdfid,'bias_sweep',bias_sweep
        cdf_varput,cdfid,'ant_deploy',ant_deploy
        cdf_varput,cdfid,'maneuver',maneuver
        cdf_varput,cdfid,'bias_current',transpose(ibias)


	cdf_close, cdfid

	store_data,tnames(),/delete



end
