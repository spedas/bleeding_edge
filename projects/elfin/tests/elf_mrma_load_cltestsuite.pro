;+
; Name: elf_mrm_load_cltestsuite.pro
;
; Purpose: command line test script for loading ELFIN MRM data
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
timespan,'2018-12-02'
t_num = 0

;1 no keywords
;

t_name='No parameters or keywords used'
catch,err
if err eq 0 then begin
  elf_load_mrma
  spd_print_tvar_info,'ela_mrma'
  ;just spot checking cause there are a lot of data types
  if ~spd_data_exists('ela_mrma','2018-12-02','2018-12-03')  || $
    spd_data_exists('elb_*','2018-12-02','2018-12-03') || $
    spd_data_exists('elb_mrmi','2018-12-02','2018-12-03')  $
    then message,'data error '+t_name
endif
catch,/cancel
spd_handle_error,err,t_name,++t_num
del_data,'*'
stop

;2 single probe
;

t_name='Single probe'
catch,err
if err eq 0 then begin
  elf_load_mrma, probe='a'
  spd_print_tvar_info,'ela_mrma'
  ;just spot checking cause there are a lot of data types
  if ~spd_data_exists('ela_mrma','2018-12-02','2018-12-03')  || $
    spd_data_exists('elb_*','2018-12-02','2018-12-03')  $
    then message,'data error '+t_name
endif
catch,/cancel
spd_handle_error,err,t_name,++t_num
del_data,'*'
stop

;3 2 probes (string)
;

t_name='Multiple probe parameters passed as an array of strings)'
catch,err
if err eq 0 then begin
  timespan,'2018-11-04'
  elf_load_mrma,probes=['a', 'b']
  spd_print_tvar_info,'ela_mrma'
  spd_print_tvar_info,'elb_mrma'
  ;just spot checking cause there are a lot of data types
  if ~spd_data_exists('ela_mrma elb_mrma','2018-11-04','2018-11-05')  || $
    spd_data_exists('elb_mrmi','2018-11-04','2018-11-05')  $
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
  elf_load_mrma,probe='*'
  spd_print_tvar_info,'elb_mrma'
  ;just spot checking cause there are a lot of data types
  if ~spd_data_exists('ela_mrma elb_mrma','2018-11-04','2018-11-05')  || $
    spd_data_exists('elb_mrmi','2018-12-02','2018-12-03')  $
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
  timespan, '2018-11-06', 1
  elf_load_mrma,probe='b',suffix='_test'
  spd_print_tvar_info,'elb_mrma_test'
  ;just spot checking cause there are a lot of data types
  if ~spd_data_exists('elb_mrma_test', '2018-11-06','2018-11-07')  || $
    spd_data_exists('ela_*','2018-11-06','2018-11-07')  $
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
  elf_load_mrma,probe='b',datatype='mrma'
  spd_print_tvar_info,'elb_mrma'
  ;just spot checking cause there are a lot of data types
  if ~spd_data_exists('elb_mrma',  '2018-11-06','2018-11-07')  || $
    spd_data_exists('ela_mrmi', '2018-11-06','2018-11-07')  $
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
  elf_load_mrma,probe='b',datatype='MRma'
  spd_print_tvar_info,'elb_mrma'
  ;just spot checking cause there are a lot of data types
  if ~spd_data_exists('elb_mrma', '2018-11-06','2018-11-07')  || $
    spd_data_exists('elb_mrmi', '2018-11-06','2018-11-07')  $
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
  timespan, '2019-01-05'
  elf_load_mrma,probe='a',datatype='MRMA'
  spd_print_tvar_info,'ela_mrma'
  ;just spot checking cause there are a lot of data types
  if ~spd_data_exists('ela_mrma', '2019-01-05','2019-01-06')  || $
    spd_data_exists('elb_mrma','2019-01-05','2019-01-06')  $
    then message,'data error ' + t_name
endif
catch,/cancel
spd_handle_error,err,t_name,++t_num
del_data,'*'
stop


;10  Upper case probes
;

t_name='All upper probes'
catch,err
if err eq 0 then begin
  elf_load_mrma,probe=['A', 'B']
  spd_print_tvar_info,'ela_mrma'
  ;just spot checking cause there are a lot of data types
  if ~spd_data_exists('ela_mrma', '2019-01-05','2019-01-06')  || $
    spd_data_exists('elb_pos','2019-01-05','2019-01-06')  $
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
  trange=['2019-01-05','2019-01-06']
  elf_load_mrma,probe='A',trange=trange
  spd_print_tvar_info,'ela_mrma'
  ;just spot checking cause there are a lot of data types
  if ~spd_data_exists('ela_mrma', '2019-01-05','2019-01-06')  || $
    spd_data_exists('elb_mrma', '2019-01-05','2019-01-06')  $
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
  elf_load_mrma,probe='A',trange=trange
  spd_print_tvar_info,'ela_mrma'
  ;just spot checking cause there are a lot of data types
  if ~spd_data_exists('ela_mrma', '2019-01-05','2019-01-06')  || $
    spd_data_exists('elb_mrma','2019-01-05','2019-01-06')  $
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
  elf_load_mrma,probe=1,trange=trange
  spd_print_tvar_info,'ela_mrma'
  ;just spot checking cause there are a lot of data types
  if spd_data_exists('ela_mrma', '2019-01-05','2019-01-06')  || $
    spd_data_exists('elb_pos','2019-01-05','2019-01-06')  $
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
  elf_load_mrma,probe='a',trange=trange, datatype=['xxx']
  spd_print_tvar_info,'ela_mrma'
  ;just spot checking cause there are a lot of data types
  if spd_data_exists('ela_mrma', '2019-01-05','2019-01-06')  || $
    spd_data_exists('elb_mrma', '2019-01-05','2019-01-06')  $
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
  elf_load_mrma,probe='a',trange=['2021-10-10','2021-10-11'], datatype=['mrma']
  spd_print_tvar_info,'ela_mrma'
  ;just spot checking cause there are a lot of data types
  if spd_data_exists('ela_mrma','2021-10-10','2021-10-11')  || $
    spd_data_exists('elb_mrma','2021-10-10','2021-10-11')  $
    then message,'data error ' + t_name
endif
catch,/cancel
spd_handle_error,err,t_name,++t_num
del_data,'*'
stop

; 16 Multiple days
; 

t_name='Multiple days'
catch,err
if err eq 0 then begin
  timespan, '2019-02-24', 2d
  tr=timerange()
  elf_load_mrma,probe='a',trange=tr
  spd_print_tvar_info,'ela_mrma'
  ;just spot checking cause there are a lot of data types
  if ~spd_data_exists('ela_mrma','2019-02-24','2019-02-26')  || $
    spd_data_exists('elb_mrma','2019-02-24','2019-02-24')  $
    then message,'data error ' + t_name
endif
catch,/cancel
spd_handle_error,err,t_name,++t_num
del_data,'*'
stop

; 17 Fractional days
;

t_name='Fractional days'
catch,err
if err eq 0 then begin
  timespan, '2019-02-24', 0.5d
  tr=timerange()
  elf_load_mrma,probe='a',trange=tr
  spd_print_tvar_info,'ela_mrma'
  ;just spot checking cause there are a lot of data types
  if ~spd_data_exists('ela_mrma','2019-02-24/00:00:00','2019-02-25/00:00:00')  || $
    spd_data_exists('ela_mrma','2019-02-25','2019-02-26')  $
    then message,'data error ' + t_name
endif
catch,/cancel
spd_handle_error,err,t_name,++t_num
del_data,'*'
stop

; 18 Probe B mrma (only)
;

t_name='Multiple days for B'
catch,err
if err eq 0 then begin
  timespan, '2018-11-05', 2d
  tr=timerange()
  elf_load_mrma,probe='b',trange=tr
  spd_print_tvar_info,'elb_mrma'
  ;just spot checking cause there are a lot of data types
  if ~spd_data_exists('elb_mrma','2018-11-05','2018-11-07')  || $
    spd_data_exists('ela_mrma','2018-11-05','2018-11-07')  $
    then message,'data error ' + t_name
endif
catch,/cancel
spd_handle_error,err,t_name,++t_num
del_data,'*'
stop

; 18 Probe B mrma (only)
;

t_name='No download flag'
catch,err
if err eq 0 then begin
  timespan, '2018-11-05'
  tr=timerange()
  elf_load_mrma,probe='b',trange=tr, /no_download
  spd_print_tvar_info,'elb_mrma'
  ;just spot checking cause there are a lot of data types
  if ~spd_data_exists('elb_mrma','2018-11-05','2018-11-07')  || $
    spd_data_exists('ela_mrma','2018-11-05','2018-11-07')  $
    then message,'data error ' + t_name
endif
catch,/cancel
spd_handle_error,err,t_name,++t_num
del_data,'*'
stop

spd_end_tests

end
