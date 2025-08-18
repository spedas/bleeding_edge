;+
; Name: dsc_ut_loadatt.pro
;
; Purpose: command line test script for loading DSCOVR Attitude data
;
; Notes:	Called by dsc_cltestsuite.pro
; 				At start it assumes an empty local data directory as well as
; 				!dsc.no_download = 0
; 				!dsc.no_update = 0
;
;Test 1: No parameters or keywords used
;Test 2: Time range passed as an array of 2 strings
;Test 3: Time range passed as an array of 2 doubles
;Test 4: Time range requested where no data exists
;Test 5: Time range passed as string
;Test 6: Time range passed as array of 3 strings 
;Test 7: Time range passed as double
;Test 8: Time range passed as array of 3 doubles
;Test 9: No download with no data on disk; should not find data
;Test 10: No download with local data
;Test 11: No update with no data on disk
;Test 12: No update with data on disk 
;Test 13: Download only; should not find data
;Test 14: Varformat one pattern match that exists in cdf
;Test 15: Varformat multi-pattern match that exists in cdf
;Test 16: Varformat multi-pattern match mixed existence in cdf; should find some data
;Test 17: Verbosity level 1
;Test 18: Verbosity level 2
;Test 19: Verbosity level 4
;Test 20: TPLOTNAMES flag returns the newly loaded variables;
;-

pro dsc_ut_loadatt,t_num=t_num

if ~keyword_set(t_num) then t_num = 0
l_num = 1
utname = 'Attitude Load '

timespan,'2016-09-23'


; Test 1: No parameters or keywords used
;
t_name=utname+l_num.toString()+': No parameters or keywords used'
catch,err
if err eq 0 then begin
	dsc_load_att
	if ~spd_data_exists('dsc_att_GSE_Yaw dsc_att_GSE_Roll dsc_att_GSE_Pitch','2016-09-23','2016-09-24')  || $
		~spd_data_exists('dsc_att_J2000_Yaw dsc_att_J2000_Roll dsc_att_J2000_Pitch','2016-09-23','2016-09-24')  || $
		~spd_data_exists('dsc_att_GCI_Yaw dsc_att_GCI_Roll dsc_att_GCI_Pitch','2016-09-23','2016-09-24') $ 
		then message,'data error '+t_name
endif
catch,/cancel
spd_handle_error,err,t_name,++t_num
++l_num
store_data,delete='*'


;Test 2: Time range passed as an array of 2 strings
;
t_name=utname+l_num.toString()+': Time range passed as an array of 2 strings'
catch,err
if err eq 0 then begin
	dsc_load_att,trange=['2017-01-01/02:00:00','2017-01-02/00:00:00']
	if ~spd_data_exists('dsc_att_GSE_Yaw dsc_att_GSE_Roll dsc_att_GSE_Pitch','2017-01-01','2017-01-02')  || $
		~spd_data_exists('dsc_att_J2000_Yaw dsc_att_J2000_Roll dsc_att_J2000_Pitch','2017-01-01','2017-01-02')  || $
		~spd_data_exists('dsc_att_GCI_Yaw dsc_att_GCI_Roll dsc_att_GCI_Pitch','2017-01-01','2017-01-02') $
		then message,'data error '+t_name
endif
catch,/cancel
spd_handle_error,err,t_name,++t_num
++l_num
store_data,delete='*'


;Test 3: Time range passed as an array of 2 doubles
;
t_name=utname+l_num.toString()+': Time range passed as an array of 2 doubles'
catch,err
if err eq 0 then begin
	trg = timerange(['2017-01-01/02:00:00','2017-01-02/00:00:00'])
	dsc_load_att,trange=trg
	if ~spd_data_exists('dsc_att_GSE_Yaw dsc_att_GSE_Roll dsc_att_GSE_Pitch','2017-01-01','2017-01-02')  || $
		~spd_data_exists('dsc_att_J2000_Yaw dsc_att_J2000_Roll dsc_att_J2000_Pitch','2017-01-01','2017-01-02')  || $
		~spd_data_exists('dsc_att_GCI_Yaw dsc_att_GCI_Roll dsc_att_GCI_Pitch','2017-01-01','2017-01-02') $
		then message,'data error '+t_name
endif
catch,/cancel
spd_handle_error,err,t_name,++t_num
++l_num
store_data,delete='*'


;Test 4: Time range requested where no data exists
;
t_name=utname+l_num.toString()+': Time range requested where no data exists'
catch,err
if err eq 0 then begin
	dsc_load_att,trange=['2012-01-01','2012-01-02']
	tn = tnames()
	if tn[0] ne '' $
		then message,'data error '+t_name
endif
catch,/cancel
spd_handle_error,err,t_name,++t_num
++l_num
store_data,delete='*'


;Test 5: Time range passed as scalar string
;
t_name=utname+l_num.toString()+': Time range passed as scalar string'
catch,err
if err eq 0 then begin
	dsc_load_att,trange='2017-01-02'
	if ~spd_data_exists('dsc_att_GSE_Yaw dsc_att_GSE_Roll dsc_att_GSE_Pitch','2017-01-02','2017-01-03')  || $
		~spd_data_exists('dsc_att_J2000_Yaw dsc_att_J2000_Roll dsc_att_J2000_Pitch','2017-01-02','2017-01-03')  || $
		~spd_data_exists('dsc_att_GCI_Yaw dsc_att_GCI_Roll dsc_att_GCI_Pitch','2017-01-02','2017-01-03') $
		then message,'data error '+t_name
endif
catch,/cancel
spd_handle_error,err,t_name,++t_num
++l_num
store_data,delete='*'


;Test 6: Time range passed as array of 3 strings
;
t_name=utname+l_num.toString()+': Time range passed array of 3 strings'
catch,err
if err eq 0 then begin
	dsc_load_att,trange=['2017-01-02','2016-12-29','2017-01-03']
	if ~spd_data_exists('dsc_att_GSE_Yaw dsc_att_GSE_Roll dsc_att_GSE_Pitch','2016-12-29','2017-01-03')  || $
		~spd_data_exists('dsc_att_J2000_Yaw dsc_att_J2000_Roll dsc_att_J2000_Pitch','2016-12-29','2017-01-03')  || $
		~spd_data_exists('dsc_att_GCI_Yaw dsc_att_GCI_Roll dsc_att_GCI_Pitch','2016-12-29','2017-01-03') $
		then message,'data error '+t_name
endif
catch,/cancel
spd_handle_error,err,t_name,++t_num
++l_num
store_data,delete='*'


;Test 7: Time range passed as double
;
t_name=utname+l_num.toString()+': Time range passed as double'
catch,err
if err eq 0 then begin
	trg = timerange('2017-01-02')
	dsc_load_att,trange=trg
	if ~spd_data_exists('dsc_att_GSE_Yaw dsc_att_GSE_Roll dsc_att_GSE_Pitch','2017-01-02','2017-01-03')  || $
		~spd_data_exists('dsc_att_J2000_Yaw dsc_att_J2000_Roll dsc_att_J2000_Pitch','2017-01-02','2017-01-03')  || $
		~spd_data_exists('dsc_att_GCI_Yaw dsc_att_GCI_Roll dsc_att_GCI_Pitch','2017-01-02','2017-01-03') $
		then message,'data error '+t_name
endif
catch,/cancel
spd_handle_error,err,t_name,++t_num
++l_num
store_data,delete='*'


;Test 8: Time range passed as array of 3 doubles
;
t_name=utname+l_num.toString()+': Time range passed array of 3 doubles'
catch,err
if err eq 0 then begin
	t1 = timerange('2017-01-02')
	t2 = timerange('2016-12-29')
	t3 = timerange('2017-01-03')
	trg = [t1[0],t2[0],t3[0]]
	dsc_load_att,trange=trg
	if ~spd_data_exists('dsc_att_GSE_Yaw dsc_att_GSE_Roll dsc_att_GSE_Pitch','2016-12-29','2017-01-03')  || $
		~spd_data_exists('dsc_att_J2000_Yaw dsc_att_J2000_Roll dsc_att_J2000_Pitch','2016-12-29','2017-01-03')  || $
		~spd_data_exists('dsc_att_GCI_Yaw dsc_att_GCI_Roll dsc_att_GCI_Pitch','2016-12-29','2017-01-03') $
		then message,'data error '+t_name
endif
catch,/cancel
spd_handle_error,err,t_name,++t_num
++l_num
store_data,delete='*'


;Test 9: No download with no data on disk; should not find data
;
t_name=utname+l_num.toString()+': No download with no data on disk; should not find data'
catch,err
if err eq 0 then begin
	dsc_load_att,trange=['2016-11-01','2016-11-02'],/no_download
	if spd_data_exists('dsc_att_GSE_Yaw dsc_att_GSE_Roll dsc_att_GSE_Pitch','2016-11-01','2016-11-02')  || $
		spd_data_exists('dsc_att_J2000_Yaw dsc_att_J2000_Roll dsc_att_J2000_Pitch','2016-11-01','2016-11-02')  || $
		spd_data_exists('dsc_att_GCI_Yaw dsc_att_GCI_Roll dsc_att_GCI_Pitch','2016-11-01','2016-11-02') $ 
		then message,'data error '+t_name
endif
catch,/cancel
spd_handle_error,err,t_name,++t_num
++l_num
store_data,delete='*'


;Test 10: No download with local data
;
t_name=utname+l_num.toString()+': No download with local data'
catch,err
if err eq 0 then begin
	dsc_load_att,trange=['2017-01-01','2017-01-02'],/no_download
	if ~spd_data_exists('dsc_att_GSE_Yaw dsc_att_GSE_Roll dsc_att_GSE_Pitch','2017-01-01','2017-01-02')  || $
		~spd_data_exists('dsc_att_J2000_Yaw dsc_att_J2000_Roll dsc_att_J2000_Pitch','2017-01-01','2017-01-02')  || $
		~spd_data_exists('dsc_att_GCI_Yaw dsc_att_GCI_Roll dsc_att_GCI_Pitch','2017-01-01','2017-01-02') $
		then message,'data error '+t_name
endif
catch,/cancel
spd_handle_error,err,t_name,++t_num
++l_num
store_data,delete='*'


;Test 11: No update with no data on disk
;
t_name=utname+l_num.toString()+': No update with no data on disk'
catch,err
if err eq 0 then begin
	dsc_load_att,trange=['2016-11-01','2016-11-02'],/no_update
	if ~spd_data_exists('dsc_att_GSE_Yaw dsc_att_GSE_Roll dsc_att_GSE_Pitch','2016-11-01','2016-11-02')  || $
		~spd_data_exists('dsc_att_J2000_Yaw dsc_att_J2000_Roll dsc_att_J2000_Pitch','2016-11-01','2016-11-02')  || $
		~spd_data_exists('dsc_att_GCI_Yaw dsc_att_GCI_Roll dsc_att_GCI_Pitch','2016-11-01','2016-11-02') $
		then message,'data error '+t_name
endif
catch,/cancel
spd_handle_error,err,t_name,++t_num
++l_num
store_data,delete='*'


;Test 12: No update with data on disk
;
t_name=utname+l_num.toString()+': No update with data on disk'
catch,err
if err eq 0 then begin
	dsc_load_att,trange=['2017-01-01','2017-01-02'],/no_update
	if ~spd_data_exists('dsc_att_GSE_Yaw dsc_att_GSE_Roll dsc_att_GSE_Pitch','2017-01-01','2017-01-02')  || $
		~spd_data_exists('dsc_att_J2000_Yaw dsc_att_J2000_Roll dsc_att_J2000_Pitch','2017-01-01','2017-01-02')  || $
		~spd_data_exists('dsc_att_GCI_Yaw dsc_att_GCI_Roll dsc_att_GCI_Pitch','2017-01-01','2017-01-02') $
		then message,'data error '+t_name
endif
catch,/cancel
spd_handle_error,err,t_name,++t_num
++l_num
store_data,delete='*'


;Test 13: Download only; should not find data
;
t_name=utname+l_num.toString()+': Download only'
catch,err
if err eq 0 then begin
	dsc_load_att,trange=['2017-03-01','2017-03-02'],/downloadonly
	tn = tnames()
	if tn[0] ne '' $
		then message,'data error '+t_name
endif
catch,/cancel
spd_handle_error,err,t_name,++t_num
++l_num
store_data,delete='*'


;Test 14: Varformat one pattern match that exists in cdf
;
t_name=utname+l_num.toString()+': Varformat one pattern match that exists in cdf'
catch,err
if err eq 0 then begin
	dsc_load_att,varformat='*Yaw*'
	if ~spd_data_exists('dsc_att_GSE_Yaw dsc_att_J2000_Yaw dsc_att_GCI_Yaw','2016-09-23','2016-09-24') || $
		spd_data_exists('dsc_att_GSE_Pitch dsc_att_J2000_Pitch dsc_att_GCI_Pitch','2016-09-23','2016-09-24') || $
		spd_data_exists('dsc_att_GSE_Roll dsc_att_J2000_Roll dsc_att_GCI_Roll','2016-09-23','2016-09-24') $
		then message,'data error '+t_name
endif
catch,/cancel
spd_handle_error,err,t_name,++t_num
++l_num
store_data,delete='*'


;Test 15: Varformat multi-pattern match that exists in cdf
;
t_name=utname+l_num.toString()+': Varformat multi-pattern match that exists in cdf'
catch,err
if err eq 0 then begin
	dsc_load_att,varformat='*Yaw* *Roll*'
	if ~spd_data_exists('dsc_att_GSE_Yaw dsc_att_J2000_Yaw dsc_att_GCI_Yaw','2016-09-23','2016-09-24') || $
		spd_data_exists('dsc_att_GSE_Pitch dsc_att_J2000_Pitch dsc_att_GCI_Pitch','2016-09-23','2016-09-24') || $
		~spd_data_exists('dsc_att_GSE_Roll dsc_att_J2000_Roll dsc_att_GCI_Roll','2016-09-23','2016-09-24') $
		then message,'data error '+t_name
endif
catch,/cancel
spd_handle_error,err,t_name,++t_num
++l_num
store_data,delete='*'


;Test 16: Varformat multi-pattern match mixed existence in cdf; should find some data
;
t_name=utname+l_num.toString()+': Varformat multi-pattern match mixed existence in cdf'
catch,err
if err eq 0 then begin
	dsc_load_att,varformat='*yw* *GSE*'
	if ~spd_data_exists('*GSE*','2016-09-23','2016-09-24') || $
		spd_data_exists('dsc_att_J2000_Yaw dsc_att_J2000_Roll dsc_att_J2000_Pitch','2016-09-23','2016-09-24')  || $
		spd_data_exists('dsc_att_GCI_Yaw dsc_att_GCI_Roll dsc_att_GCI_Pitch','2016-09-23','2016-09-24') $ 
		then message,'data error '+t_name
endif
catch,/cancel
spd_handle_error,err,t_name,++t_num
++l_num
store_data,delete='*'


;Test 17: Verbosity level 1
t_name=utname+l_num.toString()+': Verbosity level 1'
catch,err
if err eq 0 then begin
	dsc_load_att,verbose=1
endif
catch,/cancel
spd_handle_error,err,t_name,++t_num
++l_num
store_data,delete='*'


;Test 18: Verbosity level 2
;
t_name=utname+l_num.toString()+': Verbosity level 2'
catch,err
if err eq 0 then begin
	dsc_load_att,verbose=2
endif
catch,/cancel
spd_handle_error,err,t_name,++t_num
++l_num
store_data,delete='*'

;Test 19: Verbosity level 4
;
t_name=utname+l_num.toString()+': Verbosity level 4'
catch,err
if err eq 0 then begin
	dsc_load_att,verbose=4
endif
catch,/cancel
spd_handle_error,err,t_name,++t_num
++l_num
store_data,delete='*'


;Test 20: TPLOTNAMES flag returns the newly loaded variables
;
t_name=utname+l_num.toString()+': TPLOTNAMES flag returns the newly loaded variables'
catch,err
if err eq 0 then begin
	dsc_load_att
	tn_before = [tnames('*',create_time=cn_before)]
	dsc_load_att,varformat='*GSE*',tplotnames=tn_gseload
	spd_ui_cleanup_tplot,tn_before,create_time_before=cn_before,new_vars=new_vars
	
	if 	size(tn_gseload,/dim) ne size(new_vars,/dim) $
		then message,'data error '+t_name $
	else begin
		foreach tname,tn_gseload do begin
			res = where(new_vars eq tname, count)
			if count lt 1 then message,'data error '+t_name
		endforeach
	endelse
endif
catch,/cancel
spd_handle_error,err,t_name,++t_num
++l_num
store_data,delete='*'


end