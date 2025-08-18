;+
; Name: dsc_ut_loadfc.pro
;
; Purpose: command line test script for loading DSCOVR Faraday Cup data
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
;Test 21: Pass valid type flag string
;Test 22: Pass invalid type flag string
;Test 23: Pass invalid type flag non-string
;Test 24: Use /keep_bad keyword flag 
;-

pro dsc_ut_loadfc,t_num=t_num

if ~keyword_set(t_num) then t_num = 0
l_num = 1
utname = 'Faraday Cup Load '

timespan,'2016-09-23'


; Test 1: No parameters or keywords used
;
t_name=utname+l_num.toString()+': No parameters or keywords used'
catch,err
if err eq 0 then begin
	dsc_load_fc
	;spot check some variables
	if ~spd_data_exists('dsc_h1_fc_Np dsc_h1_fc_Np+DY','2016-09-23','2016-09-24')  || $
		~spd_data_exists('dsc_h1_fc_V_GSE','2016-09-23','2016-09-24')  || $
		~spd_data_exists('dsc_h1_fc_V','2016-09-23','2016-09-24') || $
		spd_data_exists('*DQF*','2016-09-23','2016-09-24') $ 
		then message,'data error (1)'+t_name
	
	;Check for compound variables
	tn = tnames()
	mask = tn.Matches('(DY$|_wCONF$|_V$)')
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
	dsc_load_fc,trange=['2017-01-01/02:00:00','2017-01-02/00:00:00']
	;spot check some variables
	if ~spd_data_exists('dsc_h1_fc_Np dsc_h1_fc_Np-DY','2017-01-01','2017-01-02')  || $
		~spd_data_exists('dsc_h1_fc_V_GSE dsc_h1_fc_V_GSE_x+DY','2017-01-01','2017-01-02')  || $
		~spd_data_exists('dsc_h1_fc_V','2017-01-01','2017-01-02') $
		then message,'data error '+t_name
		
	;Check for compound variables
	tn = tnames()
	mask = tn.Matches('(DY$|_wCONF$|_V$)')
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


;Test 3: Time range passed as an array of 2 doubles
;
t_name=utname+l_num.toString()+': Time range passed as an array of 2 doubles'
catch,err
if err eq 0 then begin
	trg = timerange(['2017-01-01/02:00:00','2017-01-02/00:00:00'])
	dsc_load_fc,trange=trg
	;spot check some variables
	if ~spd_data_exists('dsc_h1_fc_Np','2017-01-01','2017-01-02')  || $
		~spd_data_exists('dsc_h1_fc_V_GSE','2017-01-01','2017-01-02')  || $
		~spd_data_exists('dsc_h1_fc_V','2017-01-01','2017-01-02') $
		then message,'data error '+t_name
		
	;Check for compound variables
	tn = tnames()
	mask = tn.Matches('(DY$|_wCONF$|_V$)')
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


;Test 4: Time range requested where no data exists
;
t_name=utname+l_num.toString()+': Time range requested where no data exists'
catch,err
if err eq 0 then begin
	dsc_load_fc,trange=['2012-01-01','2012-01-02']
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
	dsc_load_fc,trange='2017-01-02'
	;spot check some variables
	if ~spd_data_exists('dsc_h1_fc_Np','2017-01-02','2017-01-03')  || $
		~spd_data_exists('dsc_h1_fc_V_GSE','2017-01-02','2017-01-03')  || $
		~spd_data_exists('dsc_h1_fc_V','2017-01-02','2017-01-03') $
		then message,'data error '+t_name
		
	;Check for compound variables
	tn = tnames()
	mask = tn.Matches('(DY$|_wCONF$|_V$)')
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


;Test 6: Time range passed as array of 3 strings
;
t_name=utname+l_num.toString()+': Time range passed array of 3 strings'
catch,err
if err eq 0 then begin
	dsc_load_fc,trange=['2017-01-02','2016-12-29','2017-01-03']
	;spot check some variables
	if ~spd_data_exists('dsc_h1_fc_Np','2016-12-29','2017-01-03')  || $
		~spd_data_exists('dsc_h1_fc_V_GSE','2016-12-29','2017-01-03')  || $
		~spd_data_exists('dsc_h1_fc_V','2016-12-29','2017-01-03') $
		then message,'data error '+t_name
	
	;Check for compound variables
	tn = tnames()
	mask = tn.Matches('(DY$|_wCONF$|_V$)')
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


;Test 7: Time range passed as double
;
t_name=utname+l_num.toString()+': Time range passed as double'
catch,err
if err eq 0 then begin
	trg = timerange('2017-01-02')
	dsc_load_fc,trange=trg
	;spot check some variables
	if ~spd_data_exists('dsc_h1_fc_Np','2017-01-02','2017-01-03')  || $
		~spd_data_exists('dsc_h1_fc_V_GSE','2017-01-02','2017-01-03')  || $
		~spd_data_exists('dsc_h1_fc_V','2017-01-02','2017-01-03') $
		then message,'data error '+t_name

	;Check for compound variables
	tn = tnames()
	mask = tn.Matches('(DY$|_wCONF$|_V$)')
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


;Test 8: Time range passed as array of 3 doubles
;
t_name=utname+l_num.toString()+': Time range passed array of 3 doubles'
catch,err
if err eq 0 then begin
	t1 = timerange('2017-01-02')
	t2 = timerange('2016-12-29')
	t3 = timerange('2017-01-03')
	trg = [t1[0],t2[0],t3[0]]
	dsc_load_fc,trange=trg
	;spot check some variables
	if ~spd_data_exists('dsc_h1_fc_Np','2016-12-29','2017-01-03')  || $
		~spd_data_exists('dsc_h1_fc_V_GSE','2016-12-29','2017-01-03')  || $
		~spd_data_exists('dsc_h1_fc_V','2016-12-29','2017-01-03') $
		then message,'data error '+t_name
	
	;Check for compound variables
	tn = tnames()
	mask = tn.Matches('(DY$|_wCONF$|_V$)')
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


;Test 9: No download with no data on disk; should not find data
;
t_name=utname+l_num.toString()+': No download with no data on disk; should not find data'
catch,err
if err eq 0 then begin
	dsc_load_fc,trange=['2016-11-01','2016-11-02'],/no_download
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
	dsc_load_fc,trange=['2017-01-01','2017-01-02'],/no_download
	;spot check some variables
	if ~spd_data_exists('dsc_h1_fc_Np','2017-01-01','2017-01-02')  || $
		~spd_data_exists('dsc_h1_fc_V_GSE','2017-01-01','2017-01-02')  || $
		~spd_data_exists('dsc_h1_fc_V','2017-01-01','2017-01-02') $
		then message,'data error '+t_name
		
	;Check for compound variables
	tn = tnames()
	mask = tn.Matches('(DY$|_wCONF$|_V$)')
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


;Test 11: No update with no data on disk
;
t_name=utname+l_num.toString()+': No update with no data on disk'
catch,err
if err eq 0 then begin
	dsc_load_fc,trange=['2016-11-01','2016-11-02'],/no_update
	;spot check some variables
	if ~spd_data_exists('dsc_h1_fc_Np','2016-11-01','2016-11-02')  || $
		~spd_data_exists('dsc_h1_fc_V_GSE','2016-11-01','2016-11-02')  || $
		~spd_data_exists('dsc_h1_fc_V','2016-11-01','2016-11-02') $
		then message,'data error '+t_name

	;Check for compound variables
	tn = tnames()
	mask = tn.Matches('(DY$|_wCONF$|_V$)')
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


;Test 12: No update with data on disk
;
t_name=utname+l_num.toString()+': No update with data on disk'
catch,err
if err eq 0 then begin
	dsc_load_fc,trange=['2017-01-01','2017-01-02'],/no_update
	;spot check some variables
	if ~spd_data_exists('dsc_h1_fc_Np','2017-01-01','2017-01-02')  || $
		~spd_data_exists('dsc_h1_fc_V_GSE','2017-01-01','2017-01-02')  || $
		~spd_data_exists('dsc_h1_fc_V','2017-01-01','2017-01-02') $
		then message,'data error '+t_name

	;Check for compound variables
	tn = tnames()
	mask = tn.Matches('(DY$|_wCONF$|_V$)')
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


;Test 13: Download only; should not find data
;
t_name=utname+l_num.toString()+': Download only'
catch,err
if err eq 0 then begin
	dsc_load_fc,trange=['2017-03-01','2017-03-02'],/downloadonly
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
	dsc_load_fc,varformat='*GSE*'
	;spot check some variables
	if ~spd_data_exists('dsc_h1_fc_V_GSE dsc_h1_fc_V_GSE+DY dsc_h1_fc_V_GSE_z','2016-09-23','2016-09-24') || $
		~spd_data_exists('dsc_h1_fc_V','2016-09-23','2016-09-24') || $
		spd_data_exists('dsc_h1_fc_Np','2016-09-23','2016-09-24') || $
		spd_data_exists('dsc_h1_fc_THERMAL_TEMP','2016-09-23','2016-09-24') $
		then message,'data error '+t_name

	;Check for compound variables
	tn = tnames()
	mask = tn.Matches('(DY$|_wCONF$|_V$)')
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


;Test 15: Varformat multi-pattern match that exists in cdf
;
t_name=utname+l_num.toString()+': Varformat multi-pattern match that exists in cdf'
catch,err
if err eq 0 then begin
	dsc_load_fc,varformat='*THERMAL* *Np*'
	; spot check for appropriate variables
	if ~spd_data_exists('dsc_h1_fc_THERMAL_TEMP dsc_h1_fc_THERMAL_SPD dsc_h1_fc_Np','2016-09-23','2016-09-24') || $
		spd_data_exists('dsc_h1_fc_V_GSE dsc_h1_fc_V_GSE+DY dsc_h1_fc_V_GSE_z','2016-09-23','2016-09-24') || $
		spd_data_exists('dsc_h1_fc_DQF','2016-09-23','2016-09-24') $
		then message,'data error '+t_name

	;Check for compound variables
	tn = tnames()
	mask = tn.Matches('(DY$|_wCONF$|_V$)')
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


;Test 16: Varformat multi-pattern match mixed existence in cdf; should find some data
;
t_name=utname+l_num.toString()+': Varformat multi-pattern match mixed existence in cdf'
catch,err
if err eq 0 then begin
	dsc_load_fc,varformat='*THERMAL* *error*'
	; spot check for appropriate variables
	if ~spd_data_exists('dsc_h1_fc_THERMAL_TEMP dsc_h1_fc_THERMAL_TEMP-DY dsc_h1_fc_THERMAL_SPD','2016-09-23','2016-09-24') || $
		spd_data_exists('dsc_h1_fc_V_GSE dsc_h1_fc_V_GSE+DY dsc_h1_fc_V_GSE_z','2016-09-23','2016-09-24') || $
		spd_data_exists('dsc_h1_fc_DQF','2016-09-23','2016-09-24') $
		then message,'data error '+t_name
		
	;Check for compound variables
	tn = tnames()
	mask = tn.Matches('(DY$|_wCONF$|_V$)')
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


;Test 17: Verbosity level 1
t_name=utname+l_num.toString()+': Verbosity level 1'
catch,err
if err eq 0 then begin
	dsc_load_fc,verbose=1
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
	dsc_load_fc,verbose=2
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
	dsc_load_fc,verbose=4
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
	dsc_load_fc
	tn_before = [tnames('*',create_time=cn_before)]
	dsc_load_fc,varformat='*TEMP*',tplotnames=tn_tempload
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


;Test 21: Pass valid type flag string
;
t_name=utname+l_num.toString()+': Pass valid type flag string'
catch,err
if err eq 0 then begin
	dsc_load_fc,type='h1'
	; spot check - will fail if testes with '*h1*' because of compound variables '*_wCONF'
	if ~spd_data_exists('dsc_h1_fc_THERMAL_SPD dsc_h1_fc_V_GSE_y-DY','2016-09-23','2016-09-24') $	
			then message,'data error '+t_name
			
	;Check for compound variables
	tn = tnames()
	mask = tn.Matches('(DY$|_wCONF$|_V$)')
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


;Test 22: Pass invalid type flag string
;
t_name=utname+l_num.toString()+': Pass invalid type flag string'
catch,err
if err eq 0 then begin
	dsc_load_fc,type='h11'
	tn = tnames()
	if tn[0] ne '' $
		then message,'data error '+t_name

endif
catch,/cancel
spd_handle_error,err,t_name,++t_num
++l_num
store_data,delete='*'


;Test 23: Pass invalid type flag non-string
;
t_name=utname+l_num.toString()+': Pass invalid type flag non-string'
catch,err
if err eq 0 then begin
	dsc_load_fc,type=6
	tn = tnames()
	if tn[0] ne '' then message,'data error (int)'+t_name
	
	dsc_load_fc,type=54.2
	tn = tnames()
	if tn[0] ne '' then message,'data error (float)'+t_name
	
	dsc_load_fc,type=boolean(0)
	tn = tnames()
	if tn[0] ne '' then message,'data error (boolean)'+t_name
	
	dsc_load_fc,type=!NULL
	tn = tnames()
	if tn[0] ne '' then message,'data error (null)'+t_name
	
	dsc_load_fc,type={x:32, y:'teststructure'}
	tn = tnames()
	if tn[0] ne '' then message,'data error (struct)'+t_name
endif
catch,/cancel
spd_handle_error,err,t_name,++t_num
++l_num
store_data,delete='*'


;Test 24: Use /keep_bad keyword flag
;
t_name=utname+l_num.toString()+': Use /keep_bad keyword flag'
catch,err
if err eq 0 then begin
	dsc_load_fc,/keep_bad
	if ~spd_data_exists('*DQF*','2016-09-23','2016-09-24') $
		then message,'data error (1)'+t_name
	
	;Check for compound variables
	tn = tnames()
	mask = tn.Matches('(DY$|_wCONF$|_V$|DQF$)')
	tnbase = tn[where(mask eq 0)]
	foreach name,tnbase do begin
		if ~tn.HasValue(name+'+DY') || ~tn.HasValue(name+'-DY') || $
			~tn.HasValue(name+'_wCONF') $
			then message,'data error (2)'+t_name
	endforeach
	
	tn = tnames('*DQF*')	 
	get_data,tn[0],data=d
	bad = where(d.y ne 0, badcount)
	if badcount gt 0 then begin
		num = size(d.x,/dim)
		numy = size(d.y,/dim)
		if num ne numy then message,'data error (2)'+t_name
		
		tn = tnames()
		tn = strfilter(tn,'*_wCONF',/negate)
		foreach name,tn do begin
			get_data,name,data=dd
			if (size(dd.x,/dim) ne num) || (size(dd.y,/dim) ne num) $
				then message,'data error (3)'+t_name
			if (~name.Matches('(DY|_V|DQF)$')) then begin
				if (size(dd.dy,/dim) ne num) then message,'data error (4)'+t_name
			endif
		endforeach
	endif
endif
catch,/cancel
spd_handle_error,err,t_name,++t_num
++l_num
store_data,delete='*'


end