;+
; Name: mms_state_load_cltestsuite.pro 
;
; Purpose: command line test script for loading MMS state data
;
; Notes: run it by compiling in idl and then typing ".go"
;        or copy and paste.
;
;Test 1: No parameters or keywords used
;Test 2: Single probe parameter passed as an integer
;Test 3: Multiple probe parameters passed as an array of strings)
;Test 4: Multiple probe parameters passed as an array of integers
;Test 5: All probes requested (*)
;Test 6: Requested definitive data, all datatypes
;Test 7: Requested predicted data
;Test 8: Used suffix for tplot variable names
;Test 9: All datatypes (*) requested
;Test 10: Mixed case datatype parameter used
;Test 11: All upper case data type used
;Test 12: Time range passed as an array of 2 strings
;Test 13: Time range passed as an array of 2 doubles; Datatype as an array of multiple strings
;Test 14: Requested ephemeris data only
;Test 15: Requested attitude data only
;Test 16: Requested definitive when only predicted data available; default pred_or_def flag set
;Test 17: Turned off pred_or_def flag; no data should be returned
;Test 18: Turned pred_or_def flag back on
;Test 19: No download with no data on disk; should not find data
;Test 20: No download with local data
;Test 21: Invalid datatype requested
;Test 22: Invalid probe requested
;Test 23: Invalid level requested
;Test 24: Both attitude and ephemeris flags set
;
;-

mms_init
spd_init_tests
timespan,'2015-09-23'
t_num = 0

;1 no keywords
;

t_name='No parameters or keywords used'
catch,err
if err eq 0 then begin
  mms_load_state
  spd_print_tvar_info,'mms1_defeph_pos'
  ;just spot checking cause there are a lot of data types
  if ~spd_data_exists('mms1_defeph_vel mms1_defatt_spinras','2015-09-23','2015-09-24')  || $
    spd_data_exists('thb_*','2007-03-23','2007-03-24')  || $
    spd_data_exists('the_*','2007-03-23','2007-03-24')  $
    then message,'data error '+t_name
endif
catch,/cancel
spd_handle_error,err,t_name,++t_num
del_data,'*'
stop


;2 single probe
;

t_name='Single probe parameter passed as an integer'
catch,err
if err eq 0 then begin
  mms_load_state,probe=1
  spd_print_tvar_info,'mms1_defeph_vel'
  ;just spot checking cause there are a lot of data types
  if ~spd_data_exists('mms1_defeph_pos mms1_defatt_spindec','2015-09-23','2015-09-24')  || $
    spd_data_exists('mms2_*','2015-09-23','2015-09-24')  || $
    spd_data_exists('mms3_*','2015-09-23','2015-09-24')  $
    then message,'data error ' + t_name
endif
catch,/cancel
spd_handle_error,err,t_name,++t_num
del_data,'*'


;3 probes (string)
;

t_name='Multiple probe parameters passed as an array of strings)'
catch,err
if err eq 0 then begin
  mms_load_state,probe=['1', '2']
  spd_print_tvar_info,'mms1_defatt_spinras'
  ;just spot checking cause there are a lot of data types
  if ~spd_data_exists('mms2_defeph_pos mms1_defatt_spindec','2015-09-23','2015-09-24')  || $
    spd_data_exists('mms3_*','2015-09-23','2015-09-24')  || $
    spd_data_exists('mms4_*','2015-09-23','2015-09-24')  $
    then message,'data error ' + t_name
endif
catch,/cancel
spd_handle_error,err,t_name,++t_num
del_data,'*'

;4 probes (array)
;

t_name='Multiple probe parameters passed as an array of integers'
catch,err
if err eq 0 then begin
  mms_load_state,probe=[1,3]
  spd_print_tvar_info,'mms1_defatt_spinras'
  ;just spot checking cause there are a lot of data types
  if ~spd_data_exists('mms1_defeph_pos mms1_defatt_spindec','2015-09-23','2015-09-24')  || $
    ~spd_data_exists('mms3_*','2015-09-23','2015-09-24')  || $
    spd_data_exists('mms4_*','2015-09-23','2015-09-24')  $
    then message,'data error ' + t_name
endif
catch,/cancel
spd_handle_error,err,t_name,++t_num
del_data,'*'


;5 probes(all)
;

t_name='All probes requested (*)'
catch,err
if err eq 0 then begin
  mms_load_state,probe='*'
  spd_print_tvar_info,'mms3_defatt_spinras'
  ;just spot checking cause there are a lot of data types
  if ~spd_data_exists('mms2_defeph_pos','2015-09-23','2015-09-24')  || $
    ~spd_data_exists('mms1_*','2015-09-23','2015-09-24')  || $
    ~spd_data_exists('mms4_*','2015-09-23','2015-09-24')  $
    then message,'data error ' + t_name
endif
catch,/cancel
spd_handle_error,err,t_name,++t_num
del_data,'*'


;6 definitive data
;

t_name='Requested definitive data, all datatypes'
catch,err
if err eq 0 then begin
  mms_load_state,probe='1', level='def'
  spd_print_tvar_info,'mms1_defatt_spinras'
  ;just spot checking cause there are a lot of data types
  if ~spd_data_exists('mms1_defeph_pos','2015-09-23','2015-09-24')  || $
    spd_data_exists('mms1_pred*','2015-09-23','2015-09-24')  $
    then message,'data error ' + t_name
endif
catch,/cancel
spd_handle_error,err,t_name,++t_num
del_data,'*'


;7 predicted data
;

t_name='Requested predicted data'
catch,err
if err eq 0 then begin
  timespan, '2015-12-01', 1
  mms_load_state,probe='1', level='pred', datatype='pos'
  spd_print_tvar_info,'mms1_predeph_pos'
  ;just spot checking cause there are a lot of data types
  if ~spd_data_exists('mms1_predeph_pos','2015-12-01','2015-12-02')  || $
    spd_data_exists('mms1_def*','2015-12-01','2015-12-02')  $
    then message,'data error ' + t_name
endif
catch,/cancel
spd_handle_error,err,t_name,++t_num
del_data,'*'


;8 suffix
;

t_name='Used suffix for tplot variable names'
catch,err
if err eq 0 then begin
  timespan, '2015-09-23', 1
  mms_load_state,probe='1',datatype='vel', suffix='_test'
  spd_print_tvar_info,'mms1_defeph_vel_test'
  ;just spot checking cause there are a lot of data types
  if ~spd_data_exists('mms1_defeph_vel_test','2015-09-23','2015-09-24')  || $
    spd_data_exists('mms1_defeph_pos','2015-09-23','2015-09-24')  $
    then message,'data error ' + t_name
endif
catch,/cancel
spd_handle_error,err,t_name,++t_num
del_data,'*'


;9 datatype = '*'
;

t_name='All datatypes (*) requested'
catch,err
if err eq 0 then begin
  mms_load_state,probe='2',datatype='*'
  spd_print_tvar_info,'mms2_defatt_spinras'
  ;just spot checking cause there are a lot of data types
  if ~spd_data_exists('mms2_defeph_pos','2015-09-23','2015-09-24')  || $
     ~spd_data_exists('mms2_defatt_spindec','2015-09-23','2015-09-24')  || $
    spd_data_exists('mms4_*','2015-09-23','2015-09-24')  $
    then message,'data error ' + t_name
endif
catch,/cancel
spd_handle_error,err,t_name,++t_num

del_data,'*'


;10 datatype = pOs
;

t_name='Mixed case datatype parameter used'
catch,err
if err eq 0 then begin
  mms_load_state,probe='3',datatype='pOs'
  spd_print_tvar_info,'mms3_defeph_pos'
  ;just spot checking cause there are a lot of data types
  if ~spd_data_exists('mms3_defeph_pos','2015-09-23','2015-09-24')  || $
    spd_data_exists('mms2_defeph_vel','2015-09-23','2015-09-24')  || $
    spd_data_exists('mms1_*','2015-09-23','2015-09-24')  $
    then message,'data error ' + t_name
endif
catch,/cancel
spd_handle_error,err,t_name,++t_num
del_data,'*'


;11 datatype = [POS, VEL]
;

t_name='All upper case data type used'
catch,err
if err eq 0 then begin
  mms_load_state,probe='3',datatype=['POS','VEL']
  spd_print_tvar_info,'mms3_defeph_pos'
  ;just spot checking cause there are a lot of data types
  if ~spd_data_exists('mms3_defeph_pos','2015-09-23','2015-09-24')  || $
    spd_data_exists('mms2_defeph_vel','2015-09-23','2015-09-24')  || $
    spd_data_exists('mms1_*','2015-09-23','2015-09-24')  $
    then message,'data error ' + t_name
endif
catch,/cancel
spd_handle_error,err,t_name,++t_num
del_data,'*'

t_name='datatype *'


;12 trange as a string array
;

t_name='Time range passed as an array of 2 strings'
catch,err
if err eq 0 then begin
  trange=['2015-10-10', '2015-10-11']
  mms_load_state,probe='4', trange=trange, datatype='vel'
  spd_print_tvar_info,'mms4_defeph_vel'
  ;just spot checking cause there are a lot of data types
  if ~spd_data_exists('mms4_defeph_vel','2015-10-10','2015-10-11')  || $
    spd_data_exists('mms2_defeph_vel','2015-09-23','2015-09-24')  || $
    spd_data_exists('mms1_*','2015-10-10','2015-10-11')  $
    then message,'data error ' + t_name
endif
catch,/cancel
spd_handle_error,err,t_name,++t_num
del_data,'*'


;13 trange as a double array
;

t_name='Time range passed as an array of 2 doubles; Datatype as an array of multiple strings'
catch,err
if err eq 0 then begin
  trange=time_double(trange) 
  mms_load_state,probe='4', trange=trange, datatype=['vel', 'pos', 'spinras']
  spd_print_tvar_info,'mms4_defeph_vel'
  ;just spot checking cause there are a lot of data types
  if ~spd_data_exists('mms4_defeph_vel','2015-10-10','2015-10-11')  || $
    spd_data_exists('mms2_defeph_vel','2015-09-23','2015-09-24')  || $
    spd_data_exists('mms1_*','2015-10-10','2015-10-11')  $
    then message,'data error ' + t_name
endif
catch,/cancel
spd_handle_error,err,t_name,++t_num
del_data,'*'


;14 ephem only
;

t_name='Requested ephemeris data only'
catch,err
if err eq 0 then begin
  mms_load_state,probe='1', trange=trange, /ephemeris_only
  spd_print_tvar_info,'mms4_defeph_pos'
  ;just spot checking cause there are a lot of data types
  if ~spd_data_exists('mms1_defeph_pos','2015-10-10','2015-10-11')  || $
     ~spd_data_exists('mms1_defeph_pos','2015-10-10','2015-10-11')  || $
     spd_data_exists('mms1_*att*','2015-10-10','2015-10-11')  $
    then message,'data error ' + t_name
endif
catch,/cancel
spd_handle_error,err,t_name,++t_num
del_data,'*'


;15 att only
;

t_name='Requested attitude data only'
catch,err
if err eq 0 then begin
  mms_load_state,probe='1', trange=trange, /attitude_only
  spd_print_tvar_info,'mms1_defatt_spinras'
  ;just spot checking cause there are a lot of data types
  if ~spd_data_exists('mms1_defatt_spinras','2015-10-10','2015-10-11')  || $
    ~spd_data_exists('mms1_defatt_spindec','2015-10-10','2015-10-11')  || $
    spd_data_exists('mms2_defatt_spindec','2015-10-10','2015-10-11')  || $
    spd_data_exists('mms1_*eph*','2015-10-10','2015-10-11')  $
    then message,'data error ' + t_name
endif
catch,/cancel
spd_handle_error,err,t_name,++t_num
del_data,'*'


;16 PRED_OR_DEF default 
;

t_name='Requested definitive when only predicted data available; default pred_or_def flag set'
catch,err
if err eq 0 then begin
  timespan, '2016-01-10', 1
  mms_load_state,probe='2', datatype='pos', level='def' 
  spd_print_tvar_info,'mms2_predeph_pos'
  ;just spot checking cause there are a lot of data types
  if ~spd_data_exists('mms2_predeph_pos','2016-01-10','2016-01-11')  || $
    spd_data_exists('mms2_def*','2016-01-10','2016-01-11') $
     then message,'data error ' + t_name
endif
catch,/cancel
spd_handle_error,err,t_name,++t_num
del_data,'*'


;17 PRED_OR_DEF set to zero
;

t_name='Turned off pred_or_def flag; no data should be returned'
catch,err
if err eq 0 then begin
  mms_load_state,probe='2', datatype='pos', pred_or_def=0
  ;spd_print_tvar_info,'mms2_predeph_pos'
  ;there shouldn't be any data types
  if spd_data_exists('mms2_*_pos','2016-01-10','2016-01-11')  || $
    spd_data_exists('mms2_*_vel','2016-01-10','2016-01-11')  $
    then message,'data error ' + t_name
endif
catch,/cancel
spd_handle_error,err,t_name,++t_num
del_data,'*'


;17 PRED_OR_DEF turned back on
;

t_name='Turned pred_or_def flag back on'
catch,err
if err eq 0 then begin
  mms_load_state,probe='2', datatype='pos', pred_or_def=1
  ;spd_print_tvar_info,'mms2_predeph_pos'
  spd_print_tvar_info,'mms2_predeph_pos'
  ;just spot checking cause there are a lot of data types
  if ~spd_data_exists('mms2_predeph_pos','2016-01-10','2016-01-11')  || $
    spd_data_exists('mms2_def*','2016-01-10','2016-01-11') $
    then message,'data error ' + t_name
endif
catch,/cancel
spd_handle_error,err,t_name,++t_num
del_data,'*'


;18 no download with data on disk
;

t_name='No download with no data on disk; should not find data'
catch,err
if err eq 0 then begin
  mms_load_state,probe='2', datatype='pos', /no_download
  ;spd_print_tvar_info,'mms2_predeph_pos'
  ;just spot checking cause there are a lot of data types
  if spd_data_exists('mms2_predeph_pos','2016-01-10','2016-01-11')  || $
    spd_data_exists('mms2_def*','2016-01-10','2016-01-11') $
    then message,'data error ' + t_name
endif
catch,/cancel
spd_handle_error,err,t_name,++t_num
;don't delete this time
;del_data, '*'
;load data for next test
mms_load_state,probe='2', datatype='pos'


;19 no download without data on disk
;

t_name='No download with local data'
catch,err
if err eq 0 then begin
  mms_load_state,probe='2', datatype='pos', /no_download
  ;there should be data this time
  spd_print_tvar_info,'mms2_predeph_pos'
  ;just spot checking cause there are a lot of data types
  if ~spd_data_exists('mms2_predeph_pos','2016-01-10','2016-01-11')  || $
    spd_data_exists('mms2_defeph_pos','2016-01-10','2016-01-11') $
    then message,'data error ' + t_name
endif
catch,/cancel
spd_handle_error,err,t_name,++t_num
del_data, '*'


;INVALID parameters 
 
;20 datatypes
;

t_name='Invalid datatype requested'
catch,err
if err eq 0 then begin
  timespan, '2015-09-23', 1
  mms_load_state,probe='1', datatype=1, level='def'
  ;no data should exist
  if spd_data_exists('mms1_*','2016-01-10','2016-01-11') $  
    then message,'data error ' + t_name
endif
catch,/cancel
spd_handle_error,err,t_name,++t_num
del_data,'*'


;21 probes
;

t_name='Invalid probe requested'
catch,err
if err eq 0 then begin
  mms_load_state,probe='1 2'
  ;no data should exist
  if spd_data_exists('mms*','2016-01-10','2016-01-11') $
    then message,'data error ' + t_name
endif
catch,/cancel
spd_handle_error,err,t_name,++t_num
del_data,'*'


;22 level
;

t_name='Invalid level requested'
catch,err
if err eq 0 then begin
  mms_load_state,probe=['1'], datatype='pos', level='l1b'
  ;no data should exist
  if spd_data_exists('mms*','2016-01-10','2016-01-11') $
    then message,'data error ' + t_name
endif
catch,/cancel
spd_handle_error,err,t_name,++t_num
del_data,'*'


;23 both att eph flags
;

t_name='Both attitude and ephemeris flags set'
catch,err
if err eq 0 then begin
  timespan, '2015-09-23', 1
  mms_load_state,probe=['1'], datatype='pos', /attitude_only, /ephemeris_only
  ;no data should exist
  if spd_data_exists('mms*','2016-01-10','2016-01-11') $
  then message,'data error ' + t_name
endif
catch,/cancel
spd_handle_error,err,t_name,++t_num
del_data,'*'


spd_end_tests

end
