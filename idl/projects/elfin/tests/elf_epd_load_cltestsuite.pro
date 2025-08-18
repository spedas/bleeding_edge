;+
; Name: elf_epd_load_cltestsuite.pro
;
; Purpose: command line test script for loading ELFIN epd data
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
timespan,'2019-02-14'
t_num = 0

;1 no keywords
;

t_name='No parameters or keywords used'
catch,err
if err eq 0 then begin
  elf_load_epd
  spd_print_tvar_info,'ela_pef_nflux'
  ;just spot checking cause there are a lot of data types
  if ~spd_data_exists('ela_pef_nflux','2019-02-14','2019-02-15')  || $
    spd_data_exists('elb_pif_nflux','2019-02-14','2019-02-15')  $
    then message,'data error '+t_name
endif
catch,/cancel
spd_handle_error,err,t_name,++t_num
tplot_names
stop
del_data,'*'


;2 single probe
;

t_name='Single probe'
catch,err
if err eq 0 then begin
  elf_load_epd,probe='a'
  spd_print_tvar_info,'ela_pef_nflux'
  spd_print_tvar_info,'ela_pif_nflux'
  ;just spot checking cause there are a lot of data types
  if ~spd_data_exists('ela_pef_nflux ela_pif_nflux','2019-02-14','2019-02-15')  || $
    spd_data_exists('ela_pes_nflux','2019-02-15','2019-02-16') || $
    spd_data_exists('elb_pis','2019-02-14','2019-02-15')  $
    then message,'data error '+t_name
endif
catch,/cancel
spd_handle_error,err,t_name,++t_num
tplot_names
stop
del_data,'*'


;3 2 probes (string)
;  Temporarily commented out since there is no FGM data for probe b - yet
;
;t_name='Multiple probe parameters passed as an array of strings)'
;catch,err
;if err eq 0 then begin
;  elf_load_fgm,probe=['a', 'b']
;  spd_print_tvar_info,'elb_pos'
;  ;just spot checking cause there are a lot of data types
;  if ~spd_data_exists('ela_vel elb_vel','2018-10-14','2018-10-15')  || $
;    spd_data_exists('elb_*','2018-12-14','2018-12-15')  $
;    then message,'data error '+t_name
;endif
;catch,/cancel
;spd_handle_error,err,t_name,++t_num
;del_data,'*'
;stop


;4 All probes ('*')
;

t_name='All probes requested (*)'
catch,err
if err eq 0 then begin
  timespan,'2018-12-23'
  elf_load_epd,probe='*'
  spd_print_tvar_info,'ela_pef_nflux'
  ;just spot checking cause there are a lot of data types
  if ~spd_data_exists('ela_pif_nflux ela_pef_nflux','2018-12-23','2018-12-24')  || $
    spd_data_exists('elb_pif','2018-12-23','2018-12-24')  $
    then message,'data error '+t_name
endif
catch,/cancel
spd_handle_error,err,t_name,++t_num
tplot_names
stop
del_data,'*'

;6 suffix
;

t_name='Used suffix for tplot variable names'
catch,err
if err eq 0 then begin
  elf_load_epd,probe='a',suffix='_test'
  spd_print_tvar_info,'ela_pef_nflux_test'
  ;just spot checking cause there are a lot of data types
  if ~spd_data_exists('ela_pef_nflux_test','2018-12-23','2018-12-24')  || $
    spd_data_exists('ela_pef_nflux','2018-12-23','2018-12-24')  $
    then message,'data error '+t_name
endif
catch,/cancel
spd_handle_error,err,t_name,++t_num
tplot_names
stop
del_data,'*'

;7 one datatype
;

t_name='Only one data type requested'
catch,err
if err eq 0 then begin
  timespan, '2019-02-18',1d
  elf_load_epd,probe='a',datatype='pif'
  spd_print_tvar_info,'ela_pif_nflux'
  ;just spot checking cause there are a lot of data types
  if ~spd_data_exists('ela_pif_nflux', '2019-02-18','2019-02-19')  || $
    spd_data_exists('ela_pef_nflux','2019-02-18','2019-02-19')  $
    then message,'data error ' + t_name
endif
catch,/cancel
spd_handle_error,err,t_name,++t_num
tplot_names
stop
del_data,'*'

;8 datatype = PiF
;

t_name='Mixed case datatype parameter used'
catch,err
if err eq 0 then begin
  elf_load_epd,probe='a',datatype='PiF'
  spd_print_tvar_info,'ela_pif_nflux'
  ;just spot checking cause there are a lot of data types
  if ~spd_data_exists('ela_pif_nflux', '2019-02-18','2019-02-19')  || $
    spd_data_exists('ela_pef_nflux','2019-02-18','2019-02-19')  $
    then message,'data error ' + t_name
endif
catch,/cancel
spd_handle_error,err,t_name,++t_num
tplot_names
stop
del_data,'*'

;9 All upper case datatype
;

t_name='All upper case datatype'
catch,err
if err eq 0 then begin
  timespan, '2018-12-23'
  elf_load_epd,probe='a',datatype='PEF'
  spd_print_tvar_info,'ela_pef_nflux'
  ;just spot checking cause there are a lot of data types
  if ~spd_data_exists('ela_pef_nflux', '2018-12-23','2018-12-24')  || $
    spd_data_exists('elb_pif_nflux','2019-01-26','2019-01-27') || $
    spd_data_exists('ela_pef_nflux','2018-10-14','2018-10-15')  $
    then message,'data error ' + t_name
endif
catch,/cancel
spd_handle_error,err,t_name,++t_num
tplot_names
stop
del_data,'*'


;10 datatype = [FGS]
;

t_name='All upper probe and datatypes'
catch,err
if err eq 0 then begin
  elf_load_epd,probe='A',datatype=['PEF'], type='raw'
  spd_print_tvar_info,'ela_pef_raw'
  ;just spot checking cause there are a lot of data types
  if ~spd_data_exists('ela_pef_raw', '2018-12-23','2018-12-24')  || $
    spd_data_exists('ela_pif_raw','2019-01-26','2019-01-27') $
    then message,'data error ' + t_name
endif
catch,/cancel
spd_handle_error,err,t_name,++t_num
tplot_names
get_data, 'ela_pef_raw', data=d
help, d
;print, d.v
stop
del_data,'*'

;11 trange as a string array
;

t_name='Time range passed as an array of 2 strings'
catch,err
if err eq 0 then begin
  trange=['2018-12-23','2018-12-24']
  elf_load_epd,probe='a',trange=trange, type='cps'
  spd_print_tvar_info,'ela_pef_cps'
  ;just spot checking cause there are a lot of data types
  if ~spd_data_exists('ela_pef_cps', '2018-12-23','2018-12-24')  || $
    spd_data_exists('ela_pif_cps','2019-01-26','2019-01-27') $
    then message,'data error ' + t_name
endif
catch,/cancel
spd_handle_error,err,t_name,++t_num
tplot_names
get_data, 'ela_pef_cps', data=d
help, d
print, d.v
stop
del_data,'*'

;12 trange as a double array
;

t_name='Time range passed as an array of 2 doubles; Datatype as an array of multiple strings'
catch,err
if err eq 0 then begin
  trange=time_double(trange)
  elf_load_epd,probe='a',trange=trange, datatype=['pef']
  spd_print_tvar_info,'ela_pef_nflux'
  ;just spot checking cause there are a lot of data types
  if ~spd_data_exists('ela_pef_nflux', '2018-12-23','2018-12-24')  || $
    spd_data_exists('ela_pif_elfux','2019-01-26','2019-01-27') $
    then message,'data error ' + t_name
endif
catch,/cancel
tplot_names
spd_handle_error,err,t_name,++t_num
stop
del_data,'*'

;13 Ivalid probe
;

t_name='Invalid probe'
catch,err
if err eq 0 then begin
  elf_load_epd,probe=1,trange=trange, datatype=['pef']
  spd_print_tvar_info,'ela_pef_nflux'
  ;just spot checking cause there are a lot of data types
  if spd_data_exists('ela_pef_nflux', '2018-12-23','2018-12-24')  || $
    spd_data_exists('elb_pef_raw', '2018-12-23','2018-12-24')  $
    then message,'data error ' + t_name
endif
catch,/cancel
tplot_names
spd_handle_error,err,t_name,++t_num
stop
del_data,'*'

;14 Invalid datatype
;

t_name='Invalid datatype'
catch,err
if err eq 0 then begin
  elf_load_epd,probe='a',trange=trange, datatype=['xxx']
  spd_print_tvar_info,'ela_pif_nflux'
  ;just spot checking cause there are a lot of data types
  if spd_data_exists('ela_pif_nflux',  '2018-12-23','2018-12-23')  || $
    spd_data_exists('elb_xxx',  '2018-11-10','2018-11-10')  $
    then message,'data error ' + t_name
endif
catch,/cancel
tplot_names
spd_handle_error,err,t_name,++t_num
stop
del_data,'*'

;15 Invalid date
;

t_name='Invalid date'
catch,err
if err eq 0 then begin
  elf_load_epd,probe='a',trange=['2021-10-10','2021-10-11'], datatype=['pef']
  spd_print_tvar_info,'ela_pef_nflux'
  ;just spot checking cause there are a lot of data types
  if spd_data_exists('ela_pef_nflux', '2021-10-10','2021-10-11')  || $
    spd_data_exists('elb_pif_nflux','2018-10-14','2018-10-15')  $
    then message,'data error ' + t_name
endif
catch,/cancel
tplot_names
spd_handle_error,err,t_name,++t_num
stop
del_data,'*'

;16 Test for both datatypes 
;

t_name='Both data types'
catch,err
if err eq 0 then begin
  elf_load_epd,probe='a',trange=['2019-02-17','2019-02-18'], datatype=['pef', 'pif']
  spd_print_tvar_info,'ela_pef_nflux'
  ;just spot checking cause there are a lot of data types
  if ~spd_data_exists('ela_pef_nflux ela_pif_nflux', '2019-02-17','2019-02-18')  || $
    spd_data_exists('elb_pif_nflux','2018-10-14','2018-10-15')  $
    then message,'data error ' + t_name
endif
catch,/cancel
tplot_names
spd_handle_error,err,t_name,++t_num
stop
del_data,'*'

;17 More than one day
;

t_name='Two days'
catch,err
if err eq 0 then begin
  elf_load_epd,probe='a',trange=['2019-02-17','2019-02-19'], datatype=['pef', 'pif']
  spd_print_tvar_info,'ela_pef_nflux'
  ;just spot checking cause there are a lot of data types
  if ~spd_data_exists('ela_pef_nflux ela_pif_nflux', '2019-02-17','2019-02-19')  || $
    spd_data_exists('elb_pif_nflux','2018-10-14','2018-10-15')  $
    then message,'data error ' + t_name
endif
catch,/cancel
tplot_names
spd_handle_error,err,t_name,++t_num
stop
del_data,'*'

;18 Fractional days
;

t_name='Fractional days'
catch,err
if err eq 0 then begin
  timespan, '2019-02-17', 0.5d
  tr=timerange()
  elf_load_epd,probe='a',trange=tr, datatype=['pef', 'pif'], type='nflux'
  spd_print_tvar_info,'ela_pef_nflux'
  ;just spot checking cause there are a lot of data types
  if ~spd_data_exists('ela_pef_nflux ela_pif_nflux', '2019-02-17','2019-02-19')  || $
    spd_data_exists('elb_pif','2018-10-14','2018-10-15')  $
    then message,'data error ' + t_name
endif
catch,/cancel
tplot_names
spd_handle_error,err,t_name,++t_num
stop
del_data,'*'

;18 No spec flag
;

t_name='Fractional days'
catch,err
if err eq 0 then begin
  timespan, '2019-02-17', 0.5d
  tr=timerange()
  elf_load_epd,probe='a',trange=tr, datatype=['pef', 'pif'], /no_spec
  spd_print_tvar_info,'ela_pef_nflux'
  ;just spot checking cause there are a lot of data types
  if ~spd_data_exists('ela_pef_nflux ela_pif_nflux', '2019-02-17','2019-02-18')  || $
    spd_data_exists('elb_pif_raw','2018-10-14','2018-10-15')  $
    then message,'data error ' + t_name
endif
catch,/cancel
tplot_names
spd_handle_error,err,t_name,++t_num
stop
del_data,'*'

;19 Test cal flag
;

t_name='EPDe calibration'
catch,err
if err eq 0 then begin
  timespan, '2019-02-17'
  tr=timerange()
  elf_load_epd,probe='a',trange=tr, datatype=['pef'], /no_spec, type='cps'
  spd_print_tvar_info,'ela_pef_cps'
  ;just spot checking cause there are a lot of data types
  if ~spd_data_exists('ela_pef_cps', '2019-02-17','2019-02-18')  || $
    spd_data_exists('elb_pif_cps','2018-10-14','2018-10-15')  $
    then message,'data error ' + t_name
endif
catch,/cancel
tplot_names
spd_handle_error,err,t_name,++t_num
stop
del_data,'*'

;19 Test cal flag
;

t_name='EPDe and EPDi calibration'
catch,err
if err eq 0 then begin
  timespan, '2019-02-17'
  tr=timerange()
  elf_load_epd,probe='a',trange=tr, datatype=['pef', 'pif'], type='nflux'
  spd_print_tvar_info,'ela_pef_nflux'
  spd_print_tvar_info,'ela_pif_nflux'
  ;just spot checking cause there are a lot of data types
  if ~spd_data_exists('ela_pef_nflux ela_pif_nflux', '2019-02-17','2019-02-18')  || $
    spd_data_exists('elb_pif_nflux','2018-10-14','2018-10-15')  $
    then message,'data error ' + t_name
endif
catch,/cancel
tplot_names
spd_handle_error,err,t_name,++t_num
tplot, 'ela_pef_nflux'
stop
del_data,'*'

;19 Test cal flag
;

t_name='EPDe and EPDi no_spec'
catch,err
if err eq 0 then begin
  timespan, '2019-07-26'
  tr=timerange()
  elf_load_epd,probe=['a','b'],trange=tr, datatype=['pef', 'pif'], /no_spec, type='nflux'
  spd_print_tvar_info,'ela_pef_nflux'
  spd_print_tvar_info,'ela_pif_nflux'
  ;just spot checking cause there are a lot of data types
  if ~spd_data_exists('ela_pef_nflux elb_pif_nflux', '2019-07-26','2019-07-27')  || $
    spd_data_exists('elb_pif_nflux','2018-10-14','2018-10-15')  $
    then message,'data error ' + t_name
endif
catch,/cancel
tplot_names
spd_handle_error,err,t_name,++t_num
tplot, 'ela_pef_nflux' 
stop
del_data,'*'

;20 Test no download
;

t_name='EPDe and EPDi calibration with no_download'
catch,err
if err eq 0 then begin
  timespan, '2019-07-26'
  tr=timerange()
  elf_load_epd,probe=['a','b'],trange=tr, datatype=['pef', 'pif'], /no_download, type='nflux'
  spd_print_tvar_info,'ela_pef_nflux'
  spd_print_tvar_info,'ela_pif_nflux'
  ;just spot checking cause there are a lot of data types
  if ~spd_data_exists('ela_pef_nflux elb_pif_nflux', '2019-07-26','2019-07-27')  || $
    spd_data_exists('elb_pif_nflux','2018-10-14','2018-10-15')  $
    then message,'data error ' + t_name
endif
catch,/cancel
tplot_names
spd_handle_error,err,t_name,++t_num
tplot, 'ela_pef_nflux'
stop
del_data,'*'

;22 Test not using no_download
;

t_name='EPDe and EPDi calibration with download'
catch,err
if err eq 0 then begin
  timespan, '2019-07-26'
  tr=timerange()
  elf_load_epd,probe=['a','b'],trange=tr, datatype=['pef', 'pif']
  spd_print_tvar_info,'elb_pef_nflux'
  spd_print_tvar_info,'ela_pif_nflux'
  ;just spot checking cause there are a lot of data types
  if ~spd_data_exists('ela_pef_nflux elb_pif_nflux', '2019-07-26','2019-07-27')  || $
    spd_data_exists('elb_pif','2018-10-14','2018-10-15')  $
    then message,'data error ' + t_name
endif
catch,/cancel
tplot_names
spd_handle_error,err,t_name,++t_num
stop
del_data,'*'


spd_end_tests

end
