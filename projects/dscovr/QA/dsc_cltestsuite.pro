;+
; Name: dsc_cltestsuite.pro
;
; Purpose: command line test script for DSCOVR data
;-       

pro dsc_cltestsuite
dsc_init
spd_init_tests

catch,err
if err ne 0 then begin
	print,!ERROR_STATE.msg
	print,!ERROR_STATE.sys_msg
	!dsc=cfg
	timespan,gopts.trange_full
	return
endif

; Setup test configuration
tplot_options,get_options=gopts
cfg = !dsc
!dsc.local_data_dir = cfg.local_data_dir+'qa/'
!dsc.save_plots_dir = cfg.local_data_dir+'qa/plots/'
!dsc.no_download = 0
!dsc.no_update = 0
file_delete,!dsc.local_data_dir,/allow_nonex,/recur	;For accurate tests of no_download flags, etc.

 

t_num = 0
dsc_ut_loadatt,t_num=t_num
dsc_ut_loador,t_num=t_num
dsc_ut_loadmag,t_num=t_num
dsc_ut_loadfc,t_num=t_num
dsc_ut_loadall,t_num=t_num
dsc_ut_setytitle,t_num=t_num
dsc_ut_misc,t_num=t_num
dsc_ut_timeabsolute,t_num=t_num
dsc_ut_shiftline,t_num=t_num
dsc_ut_missioncompare,t_num=t_num
dsc_ut_plotoverviews,t_num=t_num

spd_end_tests
print,'Action Needed: Compare generated plots to reference plots'
print,'-Reference plots: ''QA/ComparisonPlots/''
print,'-Generated plots: '''+!dsc.SAVE_PLOTS_DIR+'''

; Restore initial configuration
!dsc = cfg
dprint,setverbose=0
timespan,gopts.trange_full
dprint,setverbose=2
end