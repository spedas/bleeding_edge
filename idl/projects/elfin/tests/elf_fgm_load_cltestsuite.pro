;+
; Name: elf_fgm_load_cltestsuite.pro
;
; Purpose: command line test script for loading ELFIN fgm data
;
; Notes: run it by compiling in idl and then typing ".go"
;        or copy and paste.
;
;Test 1: No parameters or keywords used
;Test 2: Single probe
;Test 3: Multiple probe parameters passed as an array of strings)
;Test 4: All probes requested (*)
;Test 5: Requested predictive data, all datatypes
;Test 6: Tested suffix for tplot var names
;Test 7: One data type
;Test 8: Mixed case datatype parameter used
;Test 9: All upper case datatype
;Test 10: All upper case multiple datatypes used
;Test 11: Time range passed as an array of 2 strings
;Test 12: Time range passed as an array of 2 doubles; Datatype as an array of multiple strings
;Test 13: Invalid probe
;Test 14: Invalid datatype
;Test 15: No data available for date
;Test 16: Bad date
;
;-

elf_init
spd_init_tests
timespan,'2019-01-26'
tr=timerange()
t_num = 0

;1 no keywords
;

t_name='No parameters or keywords used'
catch,err
if err eq 0 then begin
  elf_load_fgm
  spd_print_tvar_info,'ela_fgs'
  ;just spot checking cause there are a lot of data types
  if ~spd_data_exists('ela_fgs','2019-01-26','2019-01-27')  || $
    ~spd_data_exists('ela_*','2019-01-26','2019-01-27') || $
    spd_data_exists('elb_*','2018-10-14','2018-10-15')  $
    then message,'data error '+t_name
endif
catch,/cancel
spd_handle_error,err,t_name,++t_num
stop
del_data,'*'


;2 single probe
;

t_name='Single probe'
catch,err
if err eq 0 then begin
  timespan,'2019-02-05'
  elf_load_fgm,probe='b'
  spd_print_tvar_info,'elb_fgs'
  ;just spot checking cause there are a lot of data types
  if ~spd_data_exists('elb_fgs','2019-02-05','2019-02-06')  || $
    spd_data_exists('ela_*','2019-01-26','2019-01-27')   $
    then message,'data error ' + t_name
endif
catch,/cancel
spd_handle_error,err,t_name,++t_num
del_data,'*'
stop

;3 2 probes (string)
;  Temporarily commented out since there is no FGM data for probe b on the same day
;
t_name='Multiple probe parameters passed as an array of strings)'
catch,err
if err eq 0 then begin
  timespan,'2019-07-09'
  elf_load_fgm,probe=['a', 'b'], datatype='fgs'
  spd_print_tvar_info,'elb_fgs'
  ;just spot checking cause there are a lot of data types
  if ~spd_data_exists('ela_fgs elb_fgs','2019-07-09','2019-07-10')  || $
    spd_data_exists('elb_*','2018-12-14','2018-12-15')  $
    then message,'data error '+t_name
endif
catch,/cancel
spd_handle_error,err,t_name,++t_num
del_data,'*'
stop


;4 All probes ('*')
;

t_name='All probes requested (*)'
catch,err
if err eq 0 then begin
  timespan,'2019-01-26'
  elf_load_fgm,probe='*'
  spd_print_tvar_info,'ela_fgs'
  ;just spot checking cause there are a lot of data types
  if ~spd_data_exists('ela_fgs','2019-01-26','2019-01-27')  || $
    spd_data_exists('elb_*','2019-01-26','2019-01-27')  $
    then message,'data error '+t_name
endif
catch,/cancel
spd_handle_error,err,t_name,++t_num
del_data,'*'
stop

;6 suffix
;

t_name='Used suffix for tplot variable names'
catch,err
if err eq 0 then begin
  elf_load_fgm,probe='a',suffix='_test'
  spd_print_tvar_info,'ela_fgs_test'
  ;just spot checking cause there are a lot of data types
  if ~spd_data_exists('ela_fgs_test', '2019-01-26','2019-01-27')  || $
    spd_data_exists('elb_vel','2019-01-26','2019-01-27')  $
    then message,'data error ' + t_name
endif
catch,/cancel
spd_handle_error,err,t_name,++t_num
del_data,'*'
stop

;7 one datatype
;

t_name='Only one data type requested'
catch,err
if err eq 0 then begin
  elf_load_fgm,probe='a',datatype='fgs'
  spd_print_tvar_info,'ela_fgs'
  ;just spot checking cause there are a lot of data types
  if ~spd_data_exists('ela_fgs', '2019-01-26','2019-01-27')  || $
    spd_data_exists('ela_fgf','2019-01-26','2019-01-27')  $
    then message,'data error ' + t_name
endif
catch,/cancel
spd_handle_error,err,t_name,++t_num
del_data,'*'
stop

;8 datatype = pOs
;

t_name='Mixed case datatype parameter used'
catch,err
if err eq 0 then begin
  elf_load_fgm,probe='a',datatype='fGs'
  spd_print_tvar_info,'ela_fgs'
  ;just spot checking cause there are a lot of data types
  if ~spd_data_exists('ela_fgs', '2019-01-26','2019-01-27')  || $
    spd_data_exists('elb_fgf','2019-01-26','2019-01-27')  $
    then message,'data error ' + t_name
endif
catch,/cancel
spd_handle_error,err,t_name,++t_num
del_data,'*'
stop

;9 All upper case datatype
;

t_name='All uppper case datatype'
catch,err
if err eq 0 then begin
  elf_load_fgm,probe='a',datatype='FGS'
  spd_print_tvar_info,'ela_fgs'
  ;just spot checking cause there are a lot of data types
  if ~spd_data_exists('ela_fgs', '2019-01-26','2019-01-27')  || $
    spd_data_exists('elb_fgs','2019-01-26','2019-01-27') || $
    spd_data_exists('ela_fgf','2018-10-14','2018-10-15')  $
    then message,'data error ' + t_name
endif
catch,/cancel
spd_handle_error,err,t_name,++t_num
del_data,'*'
stop


;10 datatype = [FGS]
;

t_name='All upper probe and datatypes'
catch,err
if err eq 0 then begin
  timespan,'2019-02-05'
  elf_load_fgm,probe='B',datatype=['FGS']
  spd_print_tvar_info,'elb_fgs'
  ;just spot checking cause there are a lot of data types
  if ~spd_data_exists('elb_fgs', '2019-02-05','2019-02-06')  || $
    spd_data_exists('ela_pos','2019-01-26','2019-01-27')  $
    then message,'data error ' + t_name
endif
catch,/cancel
spd_handle_error,err,t_name,++t_num
del_data,'*'
stop

;11 trange as a string array
;

t_name='Time range passed as an array of 2 strings'
catch,err
if err eq 0 then begin
  trange=['2018-11-10','2018-11-11']
  elf_load_fgm,probe='A',trange=trange
  spd_print_tvar_info,'ela_fgs'
  ;just spot checking cause there are a lot of data types
  if ~spd_data_exists('ela_fgs', '2018-11-10','2018-11-11')  || $
    spd_data_exists('elb_fgf', '2018-11-10','2018-11-11')  $    
;    spd_data_exists('ela_fgf','2018-10-14','2018-10-15')  $
    then message,'data error ' + t_name
endif
catch,/cancel
spd_handle_error,err,t_name,++t_num
del_data,'*'
stop

;12 trange as a double array
;

t_name='Time range passed as an array of 2 doubles; Datatype as an array of multiple strings'
catch,err
if err eq 0 then begin
  trange=time_double(trange)
  elf_load_fgm,probe='A',trange=trange, datatype=['fgs']
  spd_print_tvar_info,'ela_fgs'
  ;just spot checking cause there are a lot of data types
  if ~spd_data_exists('ela_fgs',  '2018-11-10','2018-11-11')  || $
    spd_data_exists('elb_fgs elb_fgf ', '2018-11-10','2018-11-11')  $
    then message,'data error ' + t_name
endif
catch,/cancel
spd_handle_error,err,t_name,++t_num
del_data,'*'
stop

;13 Ivalid probe
;

t_name='Invalid probe'
catch,err
if err eq 0 then begin
  elf_load_fgm,probe=1,trange=trange, datatype=['fgs']
  spd_print_tvar_info,'elb_fgs'
  ;just spot checking cause there are a lot of data types
  if spd_data_exists('ela_fgs', '2018-11-10','2018-11-11')  || $
    spd_data_exists('elb_fgs', '2018-11-10','2018-11-11')  $
    then message,'data error ' + t_name
endif
catch,/cancel
spd_handle_error,err,t_name,++t_num
del_data,'*'
stop

;14 Invalid datatype
;

t_name='Invalid datatype'
catch,err
if err eq 0 then begin
  elf_load_fgm,probe='a',trange=trange, datatype=['xxx']
  spd_print_tvar_info,'ela_fgs'
  ;just spot checking cause there are a lot of data types
  if spd_data_exists('ela_fgs',  '2018-11-10','2018-11-10')  || $
    spd_data_exists('elb_pos',  '2018-11-10','2018-11-10')  $
    then message,'data error ' + t_name
endif
catch,/cancel
spd_handle_error,err,t_name,++t_num
del_data,'*'
stop

;15 Invalid date
;

t_name='Invalid date'
catch,err
if err eq 0 then begin
  elf_load_fgm,probe='a',trange=['2021-10-10','2021-10-11'], datatype=['fgs']
  spd_print_tvar_info,'ela_fgs'
  ;just spot checking cause there are a lot of data types
  if spd_data_exists('ela_fgs', '2018-10-14','2018-10-15')  || $
    spd_data_exists('elb_pos','2018-10-14','2018-10-15')  $
    then message,'data error ' + t_name
endif
catch,/cancel
spd_handle_error,err,t_name,++t_num
del_data,'*'
stop

;16 Test fgf (for probe a only) 
;

;t_name='FGF data'
;catch,err
;if err eq 0 then begin
;  timespan,'2019-03-22'
;  elf_load_fgm,probe='a',datatype='fgf'
;  spd_print_tvar_info,'ela_fgf'
;  ;just spot checking cause there are a lot of data types
;  if ~spd_data_exists('ela_fgf', '2019-03-22','2019-03-23')  || $
;    spd_data_exists('ela_fgs','2019-02-26','2019-02-27')  $
;    then message,'data error ' + t_name
;endif
;catch,/cancel
;spd_handle_error,err,t_name,++t_num
;del_data,'*'
;stop

;17 Test for multiple days
;

t_name='Multiple days'
catch,err
if err eq 0 then begin
  timespan,'2019-02-17', 2d
  elf_load_fgm,probe='a',datatype=['fgs']
  spd_print_tvar_info,'ela_fgs'
  ;just spot checking cause there are a lot of data types
  if ~spd_data_exists('ela_fgs', '2019-02-17','2019-02-19')  || $
    spd_data_exists('ela_fgf', '2019-02-17','2019-02-19')  $
    then message,'data error ' + t_name
endif
catch,/cancel
spd_handle_error,err,t_name,++t_num
del_data,'*'
stop

;18 Fractional days
;

t_name='Multiple days'
catch,err
if err eq 0 then begin
  timespan,'2019-02-17', 0.5d
  elf_load_fgm,probe='a',datatype=['fgs']
  spd_print_tvar_info,'ela_fgs'
  ;just spot checking cause there are a lot of data types
  if ~spd_data_exists('ela_fgs', '2019-02-17','2019-02-18')  || $
    spd_data_exists('ela_fgf', '2019-02-17','2019-02-18')  $
    then message,'data error ' + t_name
endif
catch,/cancel
spd_handle_error,err,t_name,++t_num
del_data,'*'
stop

;19 Test for Fast mode data
;

t_name='Fast Mode'
catch,err
if err eq 0 then begin
  timespan,'2019-03-13', 0.5d
  elf_load_fgm,probe='a',datatype=['fgf']
  spd_print_tvar_info,'ela_fgf'
  ;just spot checking cause there are a lot of data types
  if ~spd_data_exists('ela_fgf', '2019-03-13','2019-03-14')  || $
    spd_data_exists('ela_fgs', '2019-03-13','2019-03-14')  $
    then message,'data error ' + t_name
endif
catch,/cancel
spd_handle_error,err,t_name,++t_num
del_data,'*'
stop

;19 Test no download flag
;

t_name='No download flag'
catch,err
if err eq 0 then begin
  timespan,'2019-03-13
  elf_load_fgm,probe='a',datatype=['fgf'], /no_download
  spd_print_tvar_info,'ela_fgf'
  ;just spot checking cause there are a lot of data types
  if ~spd_data_exists('ela_fgf', '2019-03-13','2019-03-14')  || $
    spd_data_exists('ela_fgs', '2019-03-13','2019-03-14')  $
    then message,'data error ' + t_name
endif
catch,/cancel
spd_handle_error,err,t_name,++t_num
del_data,'*'
stop


spd_end_tests

end
