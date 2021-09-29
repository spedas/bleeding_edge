;+
; Name: dsc_ut_misc.pro
;
; Purpose: command line test script for DSCOVR helper routines
;
; Notes:	Called by dsc_cltestsuite.pro
; 				At start it assumes an empty local data directory 
; 				no existing direct graphics windows as well as
; 				!dsc.no_download = 0
; 				!dsc.no_update = 0
;
;Test 1: Get routine name
;Test 2: Deleting windows - no existing window
;Test 3: Deleting windows - window exists
;Test 4: Deleting windows verbose settings
;Test 5: Clear options no parameters
;Test 6: Clear options pass variable string
;Test 7: Clear options pass variable string array
;Test 8: Clear options pass variable number
;Test 9: Clear options pass variable number array
;Test 10: Clear options invalid variable type passed
;Test 11: Clear options /all flag 
;Test 12: Clear options verbose settings
;Test 13: DSC_EZNAME /help flag
;Test 14: DSC_EZNAME valid string passed
;Test 15: DSC_EZNAME valid string array passed
;Test 16: DSC_EZNAME invalid string passed
;Test 17: DSC_EZNAME mixed valid/invalid string array passed
;Test 18: DSC_EZNAME using /conf where it exists
;Test 19: DSC_EZNAME using /conf where no conf exists 
;Test 20: DSC_EZNAME verbose settings
;Test 21: Delete vars no arguments
;Test 22: Delete vars verbose settings
;-

pro dsc_ut_misc,t_num=t_num

if ~keyword_set(t_num) then t_num = 0
l_num = 1
utname = 'Misc Routines '

;Test 0: Setup - do not continue if basic data load fails
;
t_name=utname+'0 : Setup Failure -- further tests NOT run'
catch, err
if err ne 0 then begin
	spd_handle_error,err,t_name,++t_num
	return
endif
timespan,'2017-01-01'
dsc_load_all
catch,/cancel

;Test 1: Get routine name
;
t_name=utname+l_num.toString()+': Get routine name'
catch,err
if err eq 0 then begin
	rname = dsc_getrname()
	if (rname ne 'DSC_UT_MISC') then message,'data error '+t_name 
endif
catch,/cancel
spd_handle_error,err,t_name,++t_num
++l_num


;Test 2: Deleting windows - no existing window
;
t_name=utname+l_num.toString()+': Deleting windows - no existing window'
catch,err
if err eq 0 then begin
	dsc_nowin
endif
catch,/cancel
spd_handle_error,err,t_name,++t_num
++l_num


;Test 3: Deleting windows - window exists
;
t_name=utname+l_num.toString()+': Deleting windows - window exists'
catch,err
if err eq 0 then begin
	tplot,1
	dsc_nowin
endif
catch,/cancel
spd_handle_error,err,t_name,++t_num
++l_num


;Test 4: Deleting windows verbose settings
;
t_name=utname+l_num.toString()+': Deleting windows verbose settings'
catch,err
if err eq 0 then begin
	dsc_nowin,verbose=1
	dsc_nowin,verbose=2
	dsc_nowin,verbose=4
	dsc_nowin,verbose=15
endif
catch,/cancel
spd_handle_error,err,t_name,++t_num
++l_num


;Test 5: Clear options no parameters
;
t_name=utname+l_num.toString()+': Clear options no parameters'
catch,err
if err eq 0 then begin
	options,tnames(),title="Test Title"
	dsc_clearopts
	foreach name,tnames() do begin
		get_data,name,limits=l
		if ~tag_exist(l,'title') then message,'data error '+t_name $
		else if (l.title ne "Test Title") then message,'data error '+t_name
	endforeach
endif
catch,/cancel
spd_handle_error,err,t_name,++t_num
++l_num


;Test 6: Clear options pass variable string
;
t_name=utname+l_num.toString()+': Clear options pass variable string'
catch,err
if err eq 0 then begin
	options,'dsc_h1_fc_V',title="Test Title"
	dsc_clearopts,'dsc_h1_fc_V'
	get_data,'dsc_h1_fc_V',limits=l
	if isa(l,'STRUCT') then message,'data error '+t_name
	endif
catch,/cancel
spd_handle_error,err,t_name,++t_num
++l_num


;Test 7: Clear options pass variable string array
;
t_name=utname+l_num.toString()+': Clear options pass variable string array'
catch,err
if err eq 0 then begin
	tn = ['dsc_h1_fc_V','dsc_att_GSE_Yaw','dsc_h0_mag_B1GSE']
	options,tn,title="Test Title"
	dsc_clearopts,tn
	foreach name,tn do begin
		get_data,name,limits=l
		if isa(l,'STRUCT') then message,'data error '+t_name
	endforeach
endif
catch,/cancel
spd_handle_error,err,t_name,++t_num
++l_num


;Test 8: Clear options pass variable number
;
t_name=utname+l_num.toString()+': Clear options pass variable number'
catch,err
if err eq 0 then begin
	options,5,title="Test Title"
	dsc_clearopts,5
	get_data,5,limits=l
	if isa(l,'STRUCT') then message,'data error '+t_name
endif
catch,/cancel
spd_handle_error,err,t_name,++t_num
++l_num


;Test 9: Clear options pass variable number array
;
t_name=utname+l_num.toString()+': Clear options pass variable number array'
catch,err
if err eq 0 then begin
	tn = [2,4,7]
	options,tn,title="Test Title"
	dsc_clearopts,tn
	foreach name,tn do begin
		get_data,name,limits=l
		if isa(l,'STRUCT') then message,'data error '+t_name
	endforeach
endif
catch,/cancel
spd_handle_error,err,t_name,++t_num
++l_num


;Test 10: Clear options invalid variable type passed
;
t_name=utname+l_num.toString()+': Clear options invalid variable type passed'
catch,err
if err eq 0 then begin
	type = 35.2
	dsc_clearopts,type

	type = boolean(1)
	dsc_clearopts,type

	type = !null
	dsc_clearopts,type

	type = {x:32, y:'teststructure'}
	dsc_clearopts,type		
endif
if err ne 0 then t_name = t_name+' ('+size(type,/tname)+')'
catch,/cancel
spd_handle_error,err,t_name,++t_num
++l_num


;Test 11: Clear options /all flag
;
t_name=utname+l_num.toString()+': Clear options /all flag'
catch,err
if err eq 0 then begin
	options,tnames(),yrange=[12,34]
	dsc_clearopts,/all
	foreach name,tnames() do begin
		get_data,name,limits=l
		if isa(l,'STRUCT') then message,'data error '+t_name
	endforeach
endif
catch,/cancel
spd_handle_error,err,t_name,++t_num
++l_num


;Test 12: Clear options verbose settings
;
t_name=utname+l_num.toString()+': Clear options verbose settings'
catch,err
if err eq 0 then begin
	options,tnames(),title="Another Test"
	dsc_clearopts,/all,verbose=1
	
	options,tnames(),yrange=[12,34]
	dsc_clearopts,/all,verbose=2

	options,tnames(),dsc_dy=1
	dsc_clearopts,/all,verbose=4

	foreach name,tnames() do begin
		get_data,name,limits=l
		if isa(l,'STRUCT') then message,'data error '+t_name
	endforeach
endif
catch,/cancel
spd_handle_error,err,t_name,++t_num
++l_num


;Test 13: DSC_EZNAME /help flag
;
t_name=utname+l_num.toString()+': DSC_EZNAME /help flag'
catch,err
if err eq 0 then begin
	ezname_strs = dsc_ezname(/help)
endif
catch,/cancel
spd_handle_error,err,t_name,++t_num
++l_num


;Test 14: DSC_EZNAME valid string passed
;
t_name=utname+l_num.toString()+': DSC_EZNAME valid string passed'
catch,err
if err eq 0 then begin
	longname = dsc_ezname(ezname_strs[3])
	if longname eq '' then message,'data error '+t_name
endif
catch,/cancel
spd_handle_error,err,t_name,++t_num
++l_num


;Test 15: DSC_EZNAME valid string array passed
;
t_name=utname+l_num.toString()+': DSC_EZNAME valid string array passed'
catch,err
if err eq 0 then begin
	longnames = dsc_ezname(ezname_strs[[3,4,8]])
	foreach name,longnames do if name eq '' then message,'data error '+t_name
endif
catch,/cancel
spd_handle_error,err,t_name,++t_num
++l_num


;Test 16: DSC_EZNAME invalid string passed
;
t_name=utname+l_num.toString()+': DSC_EZNAME invalid string passed'
catch,err
if err eq 0 then begin
	longname = dsc_ezname('not_a_valid_string')
	if longname ne '' then message,'data error '+t_name
endif
catch,/cancel
spd_handle_error,err,t_name,++t_num
++l_num


;Test 17: DSC_EZNAME mixed valid/invalid string array passed
;
t_name=utname+l_num.toString()+': DSC_EZNAME mixed valid/invalid string array passed'
catch,err
if err eq 0 then begin
	input = [ezname_strs[0],'not_a_valid_string',ezname_strs[[10,15,18]]]
	longnames = dsc_ezname(input)
	
	if longnames.length ne input.length then message,'data error '+t_name
	
	for i = 0,input.length-1 do begin
		if i eq 1 then begin
			if longnames[i] ne '' then message,'data error '+t_name
		endif else begin
			if name eq '' then message,'data error '+t_name
		endelse
	endfor
endif
catch,/cancel
spd_handle_error,err,t_name,++t_num
++l_num


;Test 18: DSC_EZNAME using /conf where it exists
;
t_name=utname+l_num.toString()+': DSC_EZNAME using /conf where it exists'
catch,err
if err eq 0 then begin
	longname = dsc_ezname('vx',/conf)
	if ~longname.Matches('_wCONF$') then message,'data error ',t_name
endif
catch,/cancel
spd_handle_error,err,t_name,++t_num
++l_num


;Test 19: DSC_EZNAME using /conf where no conf exists
;
t_name=utname+l_num.toString()+': DSC_EZNAME using /conf where no conf exists'
catch,err
if err eq 0 then begin
	longname = dsc_ezname('b',/conf)
	if longname.Matches('_wCONF$') then message,'data error ',t_name
endif
catch,/cancel
spd_handle_error,err,t_name,++t_num
++l_num


;Test 20: DSC_EZNAME verbose settings
;
t_name=utname+l_num.toString()+': DSC_EZNAME verbose settings'
catch,err
if err eq 0 then begin
	longname = dsc_ezname('np',		verbose=0)
	longname = dsc_ezname('by',		verbose=1)
	longname = dsc_ezname('temp',	verbose=2)
	longname = dsc_ezname('pos',	verbose=3)
	longname = dsc_ezname('bgse',	verbose=4)
	longname = dsc_ezname('vth',	verbose=19)
endif
catch,/cancel
spd_handle_error,err,t_name,++t_num
++l_num


;Test 21: Delete vars no arguments
;
t_name=utname+l_num.toString()+': Delete vars no arguments
catch,err
if err eq 0 then begin
	store_data,'NewVariable1',data={x:[2,3,4], y:[15,16,19]}
	store_data,'NewVariable2',data={x:[2,3,4], y:[15,16,19]}
	dsc_deletevars
	tn = tnames()
	dscvars = tn.Matches('^(dsc)')
	expectedvars = tn.Matches('(NewVariable1|NewVariable2)')
	if total(dscvars) gt 0 then message,'data error '+t_name 
	if total(expectedvars) lt 0 then message,'data error '+t_name
endif
catch,/cancel
spd_handle_error,err,t_name,++t_num
++l_num


;Test 22: Delete vars verbose settings
;
t_name=utname+l_num.toString()+': Delete vars no arguments
catch,err
if err eq 0 then begin
	dsc_load_att
	dsc_deletevars,verbose=1
	
	dsc_load_or
	dsc_deletevars,verbose=2
	
	dsc_load_fc
	dsc_deletevars,verbose=4
endif
catch,/cancel
spd_handle_error,err,t_name,++t_num
++l_num
store_data,delete='*'

end