;+
;PROCEDURE:  init_wind_lib
;
;PURPOSE:
;   Initializes common block variables for the WIND 3DP library.
;   There is no reason for the typical user to execute this routine as it is
;   automatically called from "LOAD_3DP_DATA".  However it can be used to
;   overide the default directories and/or libraries.

;RESTRICTIONS:
;   This procedure is operating system dependent!  (UNIX only)
;   This procedure expects to find two environment variables:
;     WIND_DATA_DIR: the directory containing the master file: 'wi_lz_3dp_files'
;        please see the file help_3dp.html for information on creating this
;        file.
;     IDL_3DP_DIR: the directory containing the source code and the sub-
;         directory/file:  lib/wind_lib.so
;
;KEYWORDS:  (used to overide defaults.)
;  WLIB:  (string)  full pathname of shared object code for wind data
;     extraction library.   Default is $IDL_3DP_DIR/lib/wind_lib.so
;  MASTFILE: (string)  full pathname of the 3DP master data file.
;     default is: $WIND_DATA_DIR/wi_lz_3dp_files
;
;CREATED BY:	Davin Larson
;LAST MODIFICATION:	@(#)init_wind_lib.pro	1.12 02/04/18
;-
pro  init_wind_lib, $
   WLIB = wlib, $
   MASTFILE = mastfile

@wind_com.pro

if n_elements(wlib) ne 0 then wind_lib = wlib
if keyword_set(mastfile) then lz_3dp_files = mastfile

if keyword_set(data_directory) eq 0 then begin
    data_directory=getenv('WIND_DATA_DIR')
    if keyword_set(data_directory) then data_directory = data_directory + '/' $
    else message,'Environment Variable WIND_DATA_DIR not found!',/cont
endif

if keyword_set(lz_3dp_files) eq 0 then $
    lz_3dp_files = data_directory+'wi_lz_3dp_files'

if keyword_set(project_name) eq 0 then begin
    project_name = 'Wind 3D Plasma'
;    tplot_options,title = project_name
endif

if size(/type,wind_lib) ne 7 then begin

;wind_lib =  getenv('IDL_3DP_LIB')    ; old method
;if wind_lib then return

;   wind_lib_dir = getenv('IDL_3DP_LIB_DIR')
;
;   if keyword_set(wind_lib_dir) eq 0 then begin
;      wind_lib_dir = '/home/wind/source/idl/wind'
;      message,/info,'      Warning!'
;      message,/info,'IDL_3DP_LIB_DIR environment variable not set!'
;      message,/info,'Using default value: '+wind_lib_dir
;   endif
;
;   bitsize = '32'
;   if !version.release ge '5.4' then begin
;      if !version.memory_bits ne 32 then begin
;          wind_lib = 0
;          print,'Only 32 bit WIND3DP library available at this time!. (use% idl -32)'
;          message,'Sorry!'
;      endif
;   endif
;   if !version.release ge '5.5' then $
;       libname = 'wind3dp_lib_ls32.so' $
;   else $
;       libname = 'wind3dp_lib_ss32.so'
;

    scptr = scope_traceback(/structure)
    n = n_elements(scptr)
    wind_lib_dir = file_dirname(scptr[n-1].filename)
    libname = 'wind3dp_lib_'+!version.os+'_'+!version.arch+'.so'

    wind_lib = wind_lib_dir+'/'+libname


   if !version.release ge '5.4' then begin
     if file_test(wind_lib) eq 0 then begin
       message,/info,'WIND3DP Library: "'+wind_lib+'" Not found!'
       wind_lib=0
       message,'Sorry!',/info
     endif
   endif

   print
   print,'Using wind library code at: ',wind_lib
   print
endif

return
end

