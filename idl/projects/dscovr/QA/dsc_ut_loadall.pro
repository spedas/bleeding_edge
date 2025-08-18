;+
; Name: dsc_ut_loadall.pro
;
; Purpose: command line test script for loading all DSCOVR data
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
;Test 14: Verbosity levels
;Test 15: TPLOTNAMES flag returns the newly loaded variables;
;Test 16: Use /keep_bad keyword flag 
;-

pro dsc_ut_loadall,t_num=t_num

if ~keyword_set(t_num) then t_num = 0
l_num = 1
utname = 'All Load '

timespan,'2016-09-23'


; Test 1: No parameters or keywords used
;
t_name=utname+l_num.toString()+': No parameters or keywords used'
catch,err
if err eq 0 then begin
	dsc_load_all
	;spot check some variables
	if ~spd_data_exists('dsc_*mag*','2016-09-23','2016-09-24')  || $
		~spd_data_exists('dsc_*or*','2016-09-23','2016-09-24')  || $
		~spd_data_exists('dsc_*att*','2016-09-23','2016-09-24') || $
		~spd_data_exists('dsc_h1_fc_V_GSE dsc_h1_fc_THERMAL_SPD dsc_h1_fc_Np dsc_h1_fc_THERMAL_TEMP dsc_h1_fc_V','2016-09-23','2016-09-24') || $
		spd_data_exists('*DQF*','2016-09-23','2016-09-24') || $
		spd_data_exists('*FLAG*','2016-09-23','2016-09-24') $ 
		then message,'data error (1)'+t_name
	
	;Check for compound variables
	tn = tnames()
	mask1 = tn.Matches('(DY$|_wCONF$|_V$)')
	mask2 = tn.Matches('(_orbit_|_att_|_mag_)')
	mask = mask1 + mask2
	tnbase = tn[where(mask eq 0)]
	foreach name,tnbase do begin
		if ~tn.HasValue(name+'+DY') || ~tn.HasValue(name+'-DY') || $
			~tn.HasValue(name+'_wCONF') $
			then message,'data error (2)'+t_name
	endforeach
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
	dsc_load_all,trange=['2017-01-01/02:00:00','2017-01-02/00:00:00']
	;spot check some variables
	if ~spd_data_exists('dsc_*mag*','2017-01-01','2017-01-02')  || $
		~spd_data_exists('dsc_*or*','2017-01-01','2017-01-02')  || $
		~spd_data_exists('dsc_*att*','2017-01-01','2017-01-02') || $
		~spd_data_exists('dsc_h1_fc_V_GSE dsc_h1_fc_THERMAL_SPD dsc_h1_fc_Np dsc_h1_fc_THERMAL_TEMP dsc_h1_fc_V','2017-01-01','2017-01-02') $
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
	dsc_load_all,trange=trg
	;spot check some variables
	if ~spd_data_exists('dsc_*mag*','2017-01-01','2017-01-02')  || $
		~spd_data_exists('dsc_*or*','2017-01-01','2017-01-02')  || $
		~spd_data_exists('dsc_*att*','2017-01-01','2017-01-02') || $
		~spd_data_exists('dsc_h1_fc_V_GSE dsc_h1_fc_THERMAL_SPD dsc_h1_fc_Np dsc_h1_fc_THERMAL_TEMP dsc_h1_fc_V','2017-01-01','2017-01-02') $
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
	dsc_load_all,trange=['2012-01-01','2012-01-02']
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
	dsc_load_all,trange='2017-01-02'
	;spot check some variables
	if ~spd_data_exists('dsc_*mag*','2017-01-02','2017-01-03')  || $
		~spd_data_exists('dsc_*or*','2017-01-02','2017-01-03')  || $
		~spd_data_exists('dsc_*att*','2017-01-02','2017-01-03') || $
		~spd_data_exists('dsc_h1_fc_V_GSE dsc_h1_fc_THERMAL_SPD dsc_h1_fc_Np dsc_h1_fc_THERMAL_TEMP dsc_h1_fc_V','2017-01-02','2017-01-03') $
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
	dsc_load_all,trange=['2017-01-02','2016-12-29','2017-01-03']
	;spot check some variables
	if ~spd_data_exists('dsc_*mag*','2016-12-29','2017-01-03')  || $
		~spd_data_exists('dsc_*or*','2016-12-29','2017-01-03')  || $
		~spd_data_exists('dsc_*att*','2016-12-29','2017-01-03') || $
		~spd_data_exists('dsc_h1_fc_V_GSE dsc_h1_fc_THERMAL_SPD dsc_h1_fc_Np dsc_h1_fc_THERMAL_TEMP dsc_h1_fc_V','2016-12-29','2017-01-03') $
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
	dsc_load_all,trange=trg
	;spot check some variables
if ~spd_data_exists('dsc_*mag*','2017-01-02','2017-01-03')  || $
		~spd_data_exists('dsc_*or*','2017-01-02','2017-01-03')  || $
		~spd_data_exists('dsc_*att*','2017-01-02','2017-01-03') || $
		~spd_data_exists('dsc_h1_fc_V_GSE dsc_h1_fc_THERMAL_SPD dsc_h1_fc_Np dsc_h1_fc_THERMAL_TEMP dsc_h1_fc_V','2017-01-02','2017-01-03') $
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
	dsc_load_all,trange=trg
	;spot check some variables
	if ~spd_data_exists('dsc_*mag*','2016-12-29','2017-01-03')  || $
		~spd_data_exists('dsc_*or*','2016-12-29','2017-01-03')  || $
		~spd_data_exists('dsc_*att*','2016-12-29','2017-01-03') || $
		~spd_data_exists('dsc_h1_fc_V_GSE dsc_h1_fc_THERMAL_SPD dsc_h1_fc_Np dsc_h1_fc_THERMAL_TEMP dsc_h1_fc_V','2016-12-29','2017-01-03') $
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
	dsc_load_all,trange=['2017-02-18','2017-02-19'],/no_download
	tn = tnames()
	if tn[0] ne '' $
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
	dsc_load_all,trange=['2017-01-01','2017-01-02'],/no_download
	;spot check some variables
	if ~spd_data_exists('dsc_*mag*','2017-01-01','2017-01-02')  || $
		~spd_data_exists('dsc_*or*','2017-01-01','2017-01-02')  || $
		~spd_data_exists('dsc_*att*','2017-01-01','2017-01-02') || $
		~spd_data_exists('dsc_h1_fc_V_GSE dsc_h1_fc_THERMAL_SPD dsc_h1_fc_Np dsc_h1_fc_THERMAL_TEMP dsc_h1_fc_V','2017-01-01','2017-01-02') $
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
	dsc_load_all,trange=['2016-11-01','2016-11-02'],/no_update
	;spot check some variables
	if ~spd_data_exists('dsc_*mag*','2016-11-01','2016-11-02')  || $
		~spd_data_exists('dsc_*or*','2016-11-01','2016-11-02')  || $
		~spd_data_exists('dsc_*att*','2016-11-01','2016-11-02') || $
		~spd_data_exists('dsc_h1_fc_V_GSE dsc_h1_fc_THERMAL_SPD dsc_h1_fc_Np dsc_h1_fc_THERMAL_TEMP dsc_h1_fc_V','2016-11-01','2016-11-02') $
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
	dsc_load_all,trange=['2017-01-01','2017-01-02'],/no_update
	;spot check some variables
	if ~spd_data_exists('dsc_*mag*','2017-01-01','2017-01-02')  || $
		~spd_data_exists('dsc_*or*','2017-01-01','2017-01-02')  || $
		~spd_data_exists('dsc_*att*','2017-01-01','2017-01-02') || $
		~spd_data_exists('dsc_h1_fc_V_GSE dsc_h1_fc_THERMAL_SPD dsc_h1_fc_Np dsc_h1_fc_THERMAL_TEMP dsc_h1_fc_V','2017-01-01','2017-01-02') $
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
	dsc_load_all,trange=['2017-03-01','2017-03-02'],/downloadonly
	tn = tnames()
	if tn[0] ne '' $
		then message,'data error '+t_name
endif
catch,/cancel
spd_handle_error,err,t_name,++t_num
++l_num
store_data,delete='*'


;Test 14: Verbosity levels
t_name=utname+l_num.toString()+': Verbosity levels'
catch,err
if err eq 0 then begin
	dsc_load_all,verbose=1
	dsc_load_all,verbose=2
	dsc_load_all,verbose=4
endif
catch,/cancel
spd_handle_error,err,t_name,++t_num
++l_num
store_data,delete='*'


;Test 15: TPLOTNAMES flag returns the newly loaded variables
;
t_name=utname+l_num.toString()+': TPLOTNAMES flag returns the newly loaded variables'
catch,err
if err eq 0 then begin
	tn_before = [tnames('*',create_time=cn_before)]
	dsc_load_all,tplotnames=tn_tempload
	spd_ui_cleanup_tplot,tn_before,create_time_before=cn_before,new_vars=new_vars

	if 	size(tn_tempload,/dim) ne size(new_vars,/dim) $
		then message,'data error '+t_name $
	else begin
		foreach tname,tn_tempload do begin
			res = where(new_vars eq tname, count)
			if count lt 1 then message,'data error '+t_name
		endforeach
	endelse
endif
catch,/cancel
spd_handle_error,err,t_name,++t_num
++l_num
store_data,delete='*'


;Test 16: Use /keep_bad keyword flag
;
t_name=utname+l_num.toString()+': Use /keep_bad keyword flag'
catch,err
if err eq 0 then begin
	dsc_load_all,/keep_bad
	if ~spd_data_exists('*DQF*','2016-09-23','2016-09-24') || $
			~spd_data_exists('*FLAG*','2016-09-23','2016-09-24') $
		then message,'data error (1)'+t_name
	
	;Check for compound variables
	tn = tnames()
	mask1 = tn.Matches('(DY$|_wCONF$|_V$|DQF$)')
	mask2 = tn.Matches('(_orbit_|_att_|_mag_)')
	mask = mask1 + mask2
	tnbase = tn[where(mask eq 0)]
	foreach name,tnbase do begin
		if ~tn.HasValue(name+'+DY') || ~tn.HasValue(name+'-DY') || $
			~tn.HasValue(name+'_wCONF') $
			then message,'data error (2)'+t_name
	endforeach
	
	;check for flagged Faraday Cup data
	dqf_names = tnames('*DQF*')	 
	get_data,dqf_names[0],data=d
	bad = where(d.y ne 0, badcount)
	if badcount gt 0 then begin
		num = size(d.x,/dim)
		numy = size(d.y,/dim)
		if num ne numy then message,'data error (2)'+t_name
		
		fc_names = tn[where(mask2 eq 0)]
		fc_names = strfilter(fc_names,'*_wCONF',/negate)
		foreach name,fc_names do begin
			get_data,name,data=dd
			if (size(dd.x,/dim) ne num) || (size(dd.y,/dim) ne num) $
				then message,'data error (3)'+t_name
			if (~name.Matches('(DY|_V|DQF)$')) then begin
				if (size(dd.dy,/dim) ne num) then message,'data error (4)'+t_name
			endif
		endforeach
	endif
	
	;check for flagged Magnetometer data
	flag_names = tnames('*FLAG*')	 
	get_data,flag_names[0],data=d
	bad = where(d.y ne 0, badcount)
	if badcount gt 0 then begin
		num = size(d.x,/dim)
		numy = size(d.y,/dim)
		if num ne numy then message,'data error (2)'+t_name
		
		mag_names = tnames('*_mag_*')
		foreach name,mag_names do begin
			get_data,name,data=dd
			if (size(dd.x,/dim) ne num) || (size(dd.y,/dim) ne num) $
				then message,'data error (3)'+t_name
		endforeach
	endif
endif
catch,/cancel
spd_handle_error,err,t_name,++t_num
++l_num
store_data,delete='*'


end