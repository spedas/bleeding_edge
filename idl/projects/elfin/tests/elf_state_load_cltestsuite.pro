;+
; Name: elf_state_load_cltestsuite.pro
;
; Purpos_geie: command line test script for loading ELFIN state data
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
timespan,'2018-10-14'
t_num = 0

;1 no keywords
;

t_name='No parameters or keywords used'
catch,err
if err eq 0 then begin
  elf_load_state, probe='a'
  spd_print_tvar_info,'ela_pos_gei'
  ;just spot checking cause there are a lot of data types
  if spd_data_exists('elb_*','2018-10-14','2018-10-15')  $
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
  elf_load_state,probe='b'
  spd_print_tvar_info,'elb_vel_gei'
  ;just spot checking cause there are a lot of data types
  if ~spd_data_exists('elb_vel_gei elb_pos_gei','2018-10-14','2018-10-15')  || $
    spd_data_exists('ela_*','2018-10-14','2018-10-15')   $
    then message,'data error ' + t_name
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
  elf_load_state,probe=['a', 'b']
  spd_print_tvar_info,'elb_pos_gei'
  ;just spot checking cause there are a lot of data types
  if ~spd_data_exists('ela_vel_gei elb_vel_gei','2018-10-14','2018-10-15')  || $
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
  elf_load_state,probe='*'
  spd_print_tvar_info,'ela_vel_gei'
  ;just spot checking cause there are a lot of data types
  if ~spd_data_exists('ela_pos_gei elb_pos_gei','2018-10-14','2018-10-15')  || $
    ~spd_data_exists('elb_*','2018-10-14','2018-10-15')  $
    then message,'data error '+t_name
endif
catch,/cancel
spd_handle_error,err,t_name,++t_num
del_data,'*'
stop


;5 predictive data
;

t_name='Requested predicted data, all datatypes'
catch,err
if err eq 0 then begin
  elf_load_state,probe='a', /pred
  spd_print_tvar_info,'ela_vel_gei'
  ;just spot checking cause there are a lot of data types
  if ~spd_data_exists('ela_vel_gei ela_pos_gei','2018-10-14','2018-10-15')  || $
    spd_data_exists('elb_*','2018-10-14','2018-10-15')  $
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
  timespan, '2018-12-04', 1
  elf_load_state,probe='a',suffix='_test'
  spd_print_tvar_info,'ela_vel_gei_test'
  ;just spot checking cause there are a lot of data types
  if ~spd_data_exists('ela_vel_gei_test ela_pos_gei_test', '2018-12-04','2018-12-05')  || $
    spd_data_exists('elb_vel_gei','2018-12-04','2018-12-05')  $
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
  elf_load_state,probe='b',datatype='vel_gei'
  spd_print_tvar_info,'elb_vel_gei'
  ;just spot checking cause there are a lot of data types
  if ~spd_data_exists('elb_vel_gei', '2018-12-04','2018-12-05')  || $
    spd_data_exists('ela_pos_gei','2018-12-04','2018-12-05')  $
    then message,'data error ' + t_name
endif
catch,/cancel
spd_handle_error,err,t_name,++t_num
del_data,'*'
stop

;8 datatype = pos_gei
;

t_name='Mixed case datatype parameter used'
catch,err
if err eq 0 then begin
  elf_load_state,probe='b',datatype='pOs_gei'
  spd_print_tvar_info,'elb_pos_gei'
  ;just spot checking cause there are a lot of data types
  if ~spd_data_exists('elb_pos_gei', '2018-12-04','2018-12-05')  || $
    spd_data_exists('ela_vel_gei','2018-12-04','2018-12-05')  $
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
  elf_load_state,probe='a',datatype='VEL_GEI'
  spd_print_tvar_info,'ela_vel_gei'
  ;just spot checking cause there are a lot of data types
  if ~spd_data_exists('ela_vel_gei', '2018-12-04','2018-12-05')  || $
    spd_data_exists('elb_pos_gei','2018-12-04','2018-12-05')  $
    then message,'data error ' + t_name
endif
catch,/cancel
spd_handle_error,err,t_name,++t_num
del_data,'*'
stop


;10 datatype = [POS_GEI, vel_gei]
;

t_name='All upper probe and datatypes'
catch,err
if err eq 0 then begin
  elf_load_state,probe='A',datatype=['VEL_GEI', 'POS_GEI']
  spd_print_tvar_info,'ela_vel_gei'
  ;just spot checking cause there are a lot of data types
  if ~spd_data_exists('ela_vel_gei ela_pos_gei', '2018-12-04','2018-12-05')  || $
    spd_data_exists('elb_pos_gei','2018-12-04','2018-12-05')  $
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
  trange=['2018-10-10', '2018-10-11']
  elf_load_state,probe='A',trange=trange
  spd_print_tvar_info,'ela_vel_gei'
  ;just spot checking cause there are a lot of data types
  if ~spd_data_exists('ela_vel_gei ela_pos_gei', '2018-10-10','2018-10-11')  || $
    spd_data_exists('elb_pos_gei','2018-10-10','2018-10-11')  $
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
  trange=['2018-10-15', '2018-10-16']
  tr=time_double(trange)
  elf_load_state,probe='B',trange=tr, datatype=['vel_gei', 'POS_GEI']
  spd_print_tvar_info,'elb_vel_gei'
  ;just spot checking cause there are a lot of data types
  if ~spd_data_exists('elb_vel_gei elb_pos_gei', '2018-10-15','2018-10-16')  || $
    spd_data_exists('ela_pos_gei','2018-10-15','2018-10-16')  $
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
  elf_load_state,probe=1,trange=trange, datatype=['vel_gei']
  spd_print_tvar_info,'elb_vel_gei'
  ;just spot checking cause there are a lot of data types
  if spd_data_exists('ela_vel_gei ela_pos_gei', '2018-10-10','2018-10-11')  || $
    spd_data_exists('elb_pos_gei','2018-10-10','2018-10-11')  $
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
  elf_load_state,probe='a',trange=trange, datatype=['xxx']
  spd_print_tvar_info,'elb_vel_gei'
  ;just spot checking cause there are a lot of data types
  if spd_data_exists('ela_vel_gei ela_pos_gei', '2018-10-10','2018-10-11')  || $
    spd_data_exists('elb_pos_gei', '2018-10-10','2018-10-11')  $
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
  elf_load_state,probe='a',trange=['2021-10-10','2021-10-11'], datatype=['pos_gei']
  spd_print_tvar_info,'elb_vel_gei'
  ;just spot checking cause there are a lot of data types
  if spd_data_exists('ela_vel_gei ela_pos_gei', '2018-12-04','2018-12-05')  || $
    spd_data_exists('elb_pos_gei','2018-12-04','2018-12-05')  $
    then message,'data error ' + t_name
endif
catch,/cancel
spd_handle_error,err,t_name,++t_num
del_data,'*'
stop

;;;;;;;;;;;;;; NEW TESTS ;;;;;;;;;;;;;;;;;;;;
;16 Set predicted flag for past dates
;

t_name='Predicted data flag (past)'
catch,err
if err eq 0 then begin
  elf_load_state,probe='b',trange=['2018-10-10','2018-10-11'], datatype=['pos_gei', 'vel_gei'], /pred
  spd_print_tvar_info,'elb_pos_gei'
  spd_print_tvar_info,'elb_vel_gei'
  ;just spot checking cause there are a lot of data types
  if ~spd_data_exists('elb_pos_gei elb_vel_gei', '2018-10-10','2018-10-11')  || $
    spd_data_exists('ela_pos_gei','2018-12-04','2018-12-05')  $
    then message,'data error ' + t_name
endif
catch,/cancel
spd_handle_error,err,t_name,++t_num
del_data,'*'
stop

;17 Set predicted flag for future dates
;

t_name='Predicted data flag (future)'
catch,err
if err eq 0 then begin
  elf_load_state,probe='b',trange=['2019-09-13','2019-09-14'], /pred
  spd_print_tvar_info,'elb_pos_gei'
  spd_print_tvar_info,'elb_vel_gei'
  ;just spot checking cause there are a lot of data types
  if ~spd_data_exists('elb_vel_gei elb_pos_gei', '2019-09-13','2019-09-14')  || $
    spd_data_exists('ela_pos_gei','2018-12-04','2018-12-05')  $
    then message,'data error ' + t_name
endif
catch,/cancel
spd_handle_error,err,t_name,++t_num
del_data,'*'
stop


;18 Set predicted flag for past dates
;

t_name='No predicted flag set but future date'
t_name='Predicted data flag (future)'
catch,err
if err eq 0 then begin
  elf_load_state,probe='b',trange=['2019-09-13','2019-09-13']
  spd_print_tvar_info,'elb_pos_gei'
  spd_print_tvar_info,'elb_vel_gei'
  ;just spot checking cause there are a lot of data types
  if ~spd_data_exists('elb_vel_gei elb_pos_gei', '2019-09-13','2019-09-14')  || $
    spd_data_exists('ela_pos_gei','2019-09-13','2019-09-14')  $
    then message,'data error ' + t_name
endif
catch,/cancel
spd_handle_error,err,t_name,++t_num
del_data,'*'
stop

;19 Test for multiple days
;

t_name='Multiple days'
catch,err
if err eq 0 then begin
  elf_load_state,probe='a',trange=['2019-02-10','2019-02-12'], datatype=['pos_gei']
  spd_print_tvar_info,'ela_pos_gei'
  ;just spot checking cause there are a lot of data types
  if ~spd_data_exists('ela_pos_gei', '2019-02-10','2019-02-12')  || $
    ~spd_data_exists('ela_vel_gei', '2019-02-10','2019-02-12')  || $
    spd_data_exists('elb_pos_gei','2019-02-10','2019-02-12')  $
    then message,'data error ' + t_name
endif
catch,/cancel
spd_handle_error,err,t_name,++t_num
del_data,'*'
stop

;20 Test for factional days
;

;t_name='Fractional days'
;catch,err
;if err eq 0 then begin
;  timespan, '2019-02-10/12:00:00', 0.5d
;  elf_load_state,probe='a', datatype=['vel_gei']
;  spd_print_tvar_info,'ela_vel_gei'
;  ;just spot checking cause there are a lot of data types
;  if ~spd_data_exists('ela_vel_gei', '2019-02-10','2019-02-11')  || $
;    spd_data_exists('elb_pos_gei','2018-12-04','2018-12-05')  $
;    then message,'data error ' + t_name
;endif
;catch,/cancel
;spd_handle_error,err,t_name,++t_num
;del_data,'*'
;stop

;21 Test for other coord
;

;t_name='Mag Coordinates'
;catch,err
;if err eq 0 then begin
;  timespan, '2019-02-11'
;  elf_load_state,probe='a', datatype=['vel_mag']
;  spd_print_tvar_info,'ela_vel_mag'
;  ;just spot checking cause there are a lot of data types
;  if ~spd_data_exists('ela_vel_mag', '2019-02-11','2019-02-12')  || $
;    spd_data_exists('elb_pos_gei','2018-12-04','2018-12-05')  $
;    then message,'data error ' + t_name
;endif
;catch,/cancel
;spd_handle_error,err,t_name,++t_num
;del_data,'*'
;stop

;21 Test for other coord
;

;t_name='SM Coordinates'
;catch,err
;if err eq 0 then begin
;  timespan, '2019-02-11'
;  elf_load_state,probe='a', datatype=['pos_sm']
;  spd_print_tvar_info,'ela_pos_mag'
;  ;just spot checking cause there are a lot of data types
;  if ~spd_data_exists('ela_pos_sm', '2019-02-11','2019-02-12')  || $
;    spd_data_exists('elb_pos_gei','2018-12-04','2018-12-05')  $
;    then message,'data error ' + t_name
;endif
;catch,/cancel
;spd_handle_error,err,t_name,++t_num
;del_data,'*'
;stop


;1 no download keyword
;

t_name='No parameters or keywords used'
catch,err
if err eq 0 then begin
  timespan,'2018-10-14'
  elf_load_state, /no_download, probe='a'
  spd_print_tvar_info,'ela_pos_gei'
  ;just spot checking cause there are a lot of data types
  if ~spd_data_exists('ela_vel_gei ela_pos_gei','2018-10-14','2018-10-15')  || $
    spd_data_exists('elb_*','2018-10-14','2018-10-15')  $
    then message,'data error '+t_name
endif
catch,/cancel
spd_handle_error,err,t_name,++t_num
del_data,'*'
stop


spd_end_tests

end
