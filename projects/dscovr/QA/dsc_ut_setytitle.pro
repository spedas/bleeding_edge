;+
; Name: dsc_ut_setytitle.pro
;
; Purpose: command line test script for setting tvar ytitle for DSCOVR data
;
; Notes:	Called by dsc_cltestsuite.pro
;
;Test 1: Valid variable name, no keywords
;Test 2: Valid variable number, no keywords
;Test 3: Variable name array
;Test 4: Variable number array
;Test 5: Invalid variable name
;Test 6: Invalid variable number
;Test 7: Invalid variable type passed
;Test 8: Pass valid metadata structure
;Test 9: Pass invalid metadata structure
;Test 10: Use title= keyword
;Test 11: Change verbosity settings
;Test 12: Verify success for all DSC variables
;-

pro dsc_ut_setytitle,t_num=t_num

if ~keyword_set(t_num) then t_num = 0
l_num = 1
utname = 'Set YTitle '


;Test 0: Setup - do not continue if basic data load fails
;
t_name=utname+'0 : Setup Failure -- further tests NOT run'
catch, err
if err ne 0 then begin
	spd_handle_error,err,t_name,++t_num
	return
endif
timespan,'2016-09-23'
dsc_load_all
options,/def,tnames(),'ytitle'
catch,/cancel


;Test 1: Valid variable name, no keywords
;
t_name=utname+l_num.toString()+': Valid variable name, no keywords'
catch,err
if err eq 0 then begin
	dsc_set_ytitle,'dsc_orbit_J2000_POS'
	get_data,'dsc_orbit_J2000_POS',dlim=dl
	if ~(tag_exist(dl,'ytitle')) then message,'data error (1)'+t_name $
		else if ~isa(dl.ytitle,/string) then message,'data error (2)'+t_name
endif
catch,/cancel
spd_handle_error,err,t_name,++t_num
++l_num
options,/def,tnames(),'ytitle'



;Test 2: Valid variable number, no keywords
;
t_name=utname+l_num.toString()+': Valid variable number, no keywords'
catch,err
if err eq 0 then begin
	dsc_set_ytitle,5
	get_data,5,dlim=dl
	if ~(tag_exist(dl,'ytitle')) then message,'data error (1)'+t_name $
	else if ~isa(dl.ytitle,/string) then message,'data error (2)'+t_name
endif
catch,/cancel
spd_handle_error,err,t_name,++t_num
++l_num
options,/def,tnames(),'ytitle'



;Test 3: Variable name array
;
t_name=utname+l_num.toString()+': Variable name array'
catch,err
if err eq 0 then begin
	dsc_set_ytitle,['dsc_h0_mag_B1GSE_PHI','dsc_h1_fc_V']
	get_data,'dsc_h0_mag_B1GSE_PHI',dlim=dl1
	get_data,'dsc_h1_fc_V',dlim=dl2
	if tag_exist(dl1,'ytitle') or tag_exist(dl2,'ytitle') then message,'data error '+t_name
endif
catch,/cancel
spd_handle_error,err,t_name,++t_num
++l_num
options,/def,tnames(),'ytitle'



;Test 4: Variable number array
;
t_name=utname+l_num.toString()+': Variable number array'
catch,err
if err eq 0 then begin
	dsc_set_ytitle,[3,7,12]
	get_data,3,dlim=dl1
	get_data,7,dlim=dl2
	get_data,12,dlim=dl3
	if tag_exist(dl1,'ytitle') or tag_exist(dl2,'ytitle') or tag_exist(dl3,'ytitle') $
		then message,'data error '+t_name
endif
catch,/cancel
spd_handle_error,err,t_name,++t_num
++l_num
options,/def,tnames(),'ytitle'


;Test 5: Invalid variable name
;
t_name=utname+l_num.toString()+': Invalid variable name'
catch,err
if err eq 0 then begin
	dsc_set_ytitle,'dsc_badname_orbit_J2000_POS'
endif
catch,/cancel
spd_handle_error,err,t_name,++t_num
++l_num
options,/def,tnames(),'ytitle'


;Test 6: Invalid variable number
;
t_name=utname+l_num.toString()+': Invalid variable number'
catch,err
if err eq 0 then begin
	dsc_set_ytitle,100
endif
catch,/cancel
spd_handle_error,err,t_name,++t_num
++l_num
options,/def,tnames(),'ytitle'


;Test 7: Invalid variable type passed
;
t_name=utname+l_num.toString()+': Invalid variable type passed'
catch,err
if err eq 0 then begin
	type = 35.2
	dsc_set_ytitle,type
	
	type = boolean(1)
	dsc_set_ytitle,type
	
	type = !null
	dsc_set_ytitle,type
	
	type = {x:32, y:'teststructure'}
	dsc_set_ytitle,type
endif
if err ne 0 then t_name = t_name+' ('+size(type,/tname)+')'
catch,/cancel
spd_handle_error,err,t_name,++t_num
++l_num
options,/def,tnames(),'ytitle'


;Test 8: Pass valid metadata structure
;
t_name=utname+l_num.toString()+': Pass valid metadata structure'
catch,err
if err eq 0 then begin
	dsc_load_fc,/no_download
	get_data,'dsc_h1_fc_Np',dlim=dl
	dsc_set_ytitle,'dsc_h1_fc_Np',metadata=dl
	get_data,'dsc_h1_fc_Np',dlim=dlout
	if ~(tag_exist(dlout,'ytitle')) then message,'data error (1)'+t_name $
	else if ~isa(dlout.ytitle,/string) then message,'data error (2)'+t_name

	get_data,'dsc_h0_mag_B1GSE',dlim=dl
	dsc_set_ytitle,'dsc_h1_fc_Np',metadata=dl
	get_data,'dsc_h1_fc_Np',dlim=dlout
	if ~(tag_exist(dlout,'ytitle')) then message,'data error (3)'+t_name $
	else if ~isa(dlout.ytitle,/string) then message,'data error (4)'+t_name
endif
catch,/cancel
spd_handle_error,err,t_name,++t_num
++l_num
options,/def,tnames(),'ytitle'


;Test 9: Pass invalid metadata structure
;
t_name=utname+l_num.toString()+': Pass invalid metadata structure
catch,err
if err eq 0 then begin
	var = 'dsc_h1_fc_Np'
	type = 35.2
	dsc_set_ytitle,var,metadata=type

	type = boolean(1)
	dsc_set_ytitle,var,metadata=type

	type = !null
	dsc_set_ytitle,var,metadata=type

	type = {x:32, y:'teststructure'}
	dsc_set_ytitle,var,metadata=type
endif
if err ne 0 then t_name = t_name+' ('+size(type,/tname)+')'
catch,/cancel
spd_handle_error,err,t_name,++t_num
++l_num
options,/def,tnames(),'ytitle'


;Test 10: Use title= keyword
;
t_name=utname+l_num.toString()+': Use title= keyword'
catch,err
if err eq 0 then begin
	newtitle = ''
	dsc_set_ytitle,'dsc_orbit_J2000_POS',title=newtitle
	
	if newtitle eq '' then message,'data error (1)'+t_name
	
	get_data,'dsc_orbit_J2000_POS',dlim=dl
	if ~(tag_exist(dl,'ytitle')) then message,'data error (2)'+t_name $
	else if ~isa(dl.ytitle,/string) then message,'data error (3)'+t_name $
	else if dl.ytitle ne newtitle then message,'data error (4)'+t_name
endif
catch,/cancel
spd_handle_error,err,t_name,++t_num
++l_num
options,/def,tnames(),'ytitle'


;Test 11: Change verbosity settings
;
t_name=utname+l_num.toString()+': Change verbosity settings'
catch,err
if err eq 0 then begin
	dsc_set_ytitle,'dsc_att_GCI_Roll',verbose=0
	dsc_set_ytitle,'dsc_att_GCI_Roll',verbose=1
	dsc_set_ytitle,'dsc_att_GCI_Roll',verbose=2
	dsc_set_ytitle,'dsc_att_GCI_Roll',verbose=4
	dsc_set_ytitle,'dsc_att_GCI_Roll',verbose=9	
endif
catch,/cancel
spd_handle_error,err,t_name,++t_num
++l_num
options,/def,tnames(),'ytitle'


;Test 12: Verify success for all DSC variables
;
t_name=utname+l_num.toString()+': Verify success for all DSC variables'
catch,err
if err eq 0 then begin
	tn = tnames()
	foreach name,tn do begin
		dsc_set_ytitle,name,title=newtitle
		get_data,name,dlim=dl
		if ~(tag_exist(dl,'ytitle')) then message,'data error (1)'+name+'-'+t_name $
		else if ~isa(dl.ytitle,/string) then message,'data error (2)'+name+'-'+t_name
	endforeach
endif
catch,/cancel
spd_handle_error,err,t_name,++t_num
++l_num
store_data,delete='*'

end