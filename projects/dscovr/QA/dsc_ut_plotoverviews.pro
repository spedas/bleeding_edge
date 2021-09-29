;+
; Name: dsc_ut_plotoverviews.pro
;
; Purpose: command line test script for plotting DSCOVR overviews
;
; Notes:	Called by dsc_cltestsuite.pro
;					Comparison plots are stored in !dsc.save_plots_dir
;					(Set to !dsc.local_data_dir+'qa/plots/' in dsc_cltestsuite)
;
;Test 1: Mag Overview- No parameters or keywords used
;Test 2: Mag Overview- Single date
;Test 3: Mag Overview- Date range
;Test 4: Mag Overview- Poorly formed date
;Test 5: Mag Overview- Splits keyword
;Test 6: Mag Overview- Save plot
;Test 7: FC Overview- No parameters or keywords used
;Test 8: FC Overview- Single date
;Test 9: FC Overview- Date range
;Test 10: FC Overview- Poorly formed date
;Test 11: FC Overview- Splits keyword
;Test 12: FC Overview- Save plot
;Test 13: General Overview- No parameters or keywords used
;Test 14: General Overview- Single date
;Test 15: General Overview- Date range
;Test 16: General Overview- Poorly formed date
;Test 17: General Overview- Splits keyword
;Test 18: General Overview- Save plot
;-

pro dsc_ut_plotoverviews,t_num=t_num

if ~keyword_set(t_num) then t_num = 0
l_num = 1
utname = 'Overview Plots '


;Test 1: Mag Overview- No parameters or keywords used
;
t_name=utname+l_num.toString()+': Mag Overview- No parameters or keywords used'
catch,err
if err eq 0 then begin
	dsc_overview_mag
endif
catch,/cancel
spd_handle_error,err,t_name,++t_num
++l_num
store_data,delete='*'


;Test 2: Mag Overview- Single date
;
t_name=utname+l_num.toString()+': Mag Overview- Single date'
catch,err
if err eq 0 then begin
	dsc_overview_mag,'2017-04-12'
endif
catch,/cancel
spd_handle_error,err,t_name,++t_num
++l_num
dsc_deletevars
store_data,delete='*'


;Test 3: Mag Overview- Date range
;
t_name=utname+l_num.toString()+': Mag Overview- Date range'
catch,err
if err eq 0 then begin
	dsc_overview_mag,trange=['2017-03-31/14:30:00','2017-03-31/20:00:00']
endif
catch,/cancel
spd_handle_error,err,t_name,++t_num
++l_num
store_data,delete='*'


;Test 4: Mag Overview- Poorly formed date
;
t_name=utname+l_num.toString()+': Mag Overview- Poorly formed date'
catch,err
if err eq 0 then begin
	type = 6
	dsc_overview_mag,type
	dsc_overview_mag,trange=type
	dsc_overview_mag,trange=[type,type]
	
	type = 325.1
	dsc_overview_mag,type
	dsc_overview_mag,trange=type
	dsc_overview_mag,trange=[type,type]
	
	type = boolean(1)
	dsc_overview_mag,type
	dsc_overview_mag,trange=type
	dsc_overview_mag,trange=[type,type]

	type = !null
	dsc_overview_mag,type
	dsc_overview_mag,trange=type
	dsc_overview_mag,trange=[type,type]
	
	type = {x:32, y:'teststructure'}
	dsc_overview_mag,type
	dsc_overview_mag,trange=type
	dsc_overview_mag,trange=[type,type]
endif
catch,/cancel
if err ne 0 then t_name = t_name+' ('+size(type,/tname)+')'
spd_handle_error,err,t_name,++t_num
++l_num


;Test 5: Mag Overview- Splits keyword
;
t_name=utname+l_num.toString()+': Mag Overview- Splits keyword'
catch,err
if err eq 0 then begin
	dsc_overview_mag,'2017-04-12',/splits
endif
catch,/cancel
spd_handle_error,err,t_name,++t_num
++l_num
store_data,delete='*'


;Test 6: Mag Overview- Save plot
;
t_name=utname+l_num.toString()+': Mag Overview- Save plot'
catch,err
if err eq 0 then begin
	dsc_overview_mag,'2017-04-12',/save
endif
catch,/cancel
spd_handle_error,err,t_name,++t_num
++l_num
store_data,delete='*'
dsc_nowin


;Test 7: FC Overview- No parameters or keywords used
;
t_name=utname+l_num.toString()+': FC Overview- No parameters or keywords used'
catch,err
if err eq 0 then begin
	dsc_overview_fc
endif
catch,/cancel
spd_handle_error,err,t_name,++t_num
++l_num
store_data,delete='*'


;Test 8: FC Overview- Single date
;
t_name=utname+l_num.toString()+': FC Overview- Single date'
catch,err
if err eq 0 then begin
	dsc_overview_fc,'2017-04-12'
endif
catch,/cancel
spd_handle_error,err,t_name,++t_num
++l_num
dsc_deletevars
store_data,delete='*'


;Test 9: FC Overview- Date range
;
t_name=utname+l_num.toString()+': FC Overview- Date range'
catch,err
if err eq 0 then begin
	dsc_overview_fc,trange=['2017-03-31/14:30:00','2017-03-31/20:00:00']
endif
catch,/cancel
spd_handle_error,err,t_name,++t_num
++l_num
store_data,delete='*'


;Test 10: FC Overview- Poorly formed date
;
t_name=utname+l_num.toString()+': FC Overview- Poorly formed date'
catch,err
if err eq 0 then begin
	type = 6
	dsc_overview_fc,type
	dsc_overview_fc,trange=type
	dsc_overview_fc,trange=[type,type]

	type = 325.1
	dsc_overview_fc,type
	dsc_overview_fc,trange=type
	dsc_overview_fc,trange=[type,type]

	type = boolean(1)
	dsc_overview_fc,type
	dsc_overview_fc,trange=type
	dsc_overview_fc,trange=[type,type]

	type = !null
	dsc_overview_fc,type
	dsc_overview_fc,trange=type
	dsc_overview_fc,trange=[type,type]

	type = {x:32, y:'teststructure'}
	dsc_overview_fc,type
	dsc_overview_fc,trange=type
	dsc_overview_fc,trange=[type,type]
endif
catch,/cancel
if err ne 0 then t_name = t_name+' ('+size(type,/tname)+')'
spd_handle_error,err,t_name,++t_num
++l_num


;Test 11: FC Overview- Splits keyword
;
t_name=utname+l_num.toString()+': FC Overview- Splits keyword'
catch,err
if err eq 0 then begin
	dsc_overview_fc,'2017-04-12',/splits
endif
catch,/cancel
spd_handle_error,err,t_name,++t_num
++l_num
store_data,delete='*'


;Test 12: FC Overview- Save plot
;
t_name=utname+l_num.toString()+': FC Overview- Save plot'
catch,err
if err eq 0 then begin
	dsc_overview_fc,'2017-04-12',/save
endif
catch,/cancel
spd_handle_error,err,t_name,++t_num
++l_num
store_data,delete='*'
dsc_nowin


;Test 13: General Overview- No parameters or keywords used
;
t_name=utname+l_num.toString()+': General Overview- No parameters or keywords used'
catch,err
if err eq 0 then begin
	dsc_overview
endif
catch,/cancel
spd_handle_error,err,t_name,++t_num
++l_num
store_data,delete='*'


;Test 14: General Overview- Single date
;
t_name=utname+l_num.toString()+': General Overview- Single date'
catch,err
if err eq 0 then begin
	dsc_overview,'2017-04-12'
endif
catch,/cancel
spd_handle_error,err,t_name,++t_num
++l_num
dsc_deletevars
store_data,delete='*'


;Test 15: General Overview- Date range
;
t_name=utname+l_num.toString()+': General Overview- Date range'
catch,err
if err eq 0 then begin
	dsc_overview,trange=['2017-03-31/14:30:00','2017-03-31/20:00:00']
endif
catch,/cancel
spd_handle_error,err,t_name,++t_num
++l_num
store_data,delete='*'


;Test 16: General Overview- Poorly formed date
;
t_name=utname+l_num.toString()+': General Overview- Poorly formed date'
catch,err
if err eq 0 then begin
	type = 6
	dsc_overview,type
	dsc_overview,trange=type
	dsc_overview,trange=[type,type]

	type = 325.1
	dsc_overview,type
	dsc_overview,trange=type
	dsc_overview,trange=[type,type]

	type = boolean(1)
	dsc_overview,type
	dsc_overview,trange=type
	dsc_overview,trange=[type,type]

	type = !null
	dsc_overview,type
	dsc_overview,trange=type
	dsc_overview,trange=[type,type]

	type = {x:32, y:'teststructure'}
	dsc_overview,type
	dsc_overview,trange=type
	dsc_overview,trange=[type,type]
endif
catch,/cancel
if err ne 0 then t_name = t_name+' ('+size(type,/tname)+')'
spd_handle_error,err,t_name,++t_num
++l_num


;Test 17: General Overview- Splits keyword
;
t_name=utname+l_num.toString()+': General Overview- Splits keyword'
catch,err
if err eq 0 then begin
	dsc_overview,'2017-04-12',/splits
endif
catch,/cancel
spd_handle_error,err,t_name,++t_num
++l_num
store_data,delete='*'


;Test 18: General Overview- Save plot
;
t_name=utname+l_num.toString()+': General Overview- Save plot'
catch,err
if err eq 0 then begin
	dsc_overview,'2017-04-12',/save
endif
catch,/cancel
spd_handle_error,err,t_name,++t_num
++l_num
store_data,delete='*'
dsc_nowin
end