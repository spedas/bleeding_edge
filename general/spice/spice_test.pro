;+
;Function: spice_test
;
;Purpose:  Tests whether the SPICE (idl/icy) module is installed
;          Provides installation message if not installed
;
;Keywords:
;         VERBOSE  (see "DPRINT")
;
;Returns: 1 on success; 0 on failure
;
;Example:
;   if(spice_test() eq 0) then return
;Notes:
;  Should be called in all idl spice wrapper routines
;  
;see also:
;  "SPICE_INSTALL"
;  "SPICE_STANDARD_KERNELS"
;  "SPICE_CRIB"
;
; Author: Davin Larson   (based on icy_test.pro by Peter S.)
; $LastChangedBy: $
; $LastChangedDate: $
; $LastChangedRevision: $
; $URL: $
;-
function spice_test,files,verbose=verbose,set_flag=set_flag
common spice_test_com, tested

on_error,2
if n_elements(set_flag) ne 0 then tested=set_flag

if ~keyword_set(tested) then begin
  help, 'icy', /dlm, output = out
  dprint,verbose=verbose,dlevel=2,out
  filter = strfilter(out, '*ICY*',/index)
  no_icy = filter[0] eq -1

  if(no_icy) then begin
    dprint,dlevel=0,verbose=verbose, 'Required module IDL/ICY is not installed!'
    dprint,dlevel=1,verbose=verbose, 'There are several options to install ICY on your computer:'
    dprint,dlevel=1,verbose=verbose, '(1) Run the IDL procedure: SPICE_INSTALL  (This may not work for all platforms).'
    dprint,dlevel=1,verbose=verbose, '    OR'
    dprint,dlevel=1,verbose=verbose, '(2)  a) Go to: http://naif.jpl.nasa.gov/pub/naif/toolkit/IDL/'
    dprint,dlevel=1,verbose=verbose, '     b) Find the appropriate file for your platform'
    dprint,dlevel=1,verbose=verbose, '             NOTE: Mac OSX V10.7 and newer - Go to: http://naif.jpl.nasa.gov/naif/bugs.html
    dprint,dlevel=1,verbose=verbose, '     c) Uncompress (unzip) the file
    dprint,dlevel=1,verbose=verbose, '     d) Find the binary (.so or .dll) AND .dlm file  (usually in the lib directory)'
    dprint,dlevel=1,verbose=verbose, '     e) Copy these 2 files to: '+ !DLM_PATH
    dprint,dlevel=1,verbose=verbose, '    OR'
    dprint,dlevel=1,verbose=verbose, '(3)  For old versions of IDL (prior to 6.0), Follow the NAIF directions at:'
    dprint,dlevel=1,verbose=verbose, '     http://naif.jpl.nasa.gov/naif/toolkit_IDL.html'
    dprint,dlevel=1,verbose=verbose, '     AND'
    dprint,dlevel=1,verbose=verbose, '     http://naif.jpl.nasa.gov/pub/naif/toolkit_docs/IDL/req/icy.html#Using Icy'
    dprint,dlevel=1,verbose=verbose, ''
    dprint,dlevel=1,verbose=verbose, 'Then you will need to restart IDL to use the newly installed package.'
    tested=0
    return,0
  endif else tested=1

  if !version.os eq 'darwin' && out[1] lt '    Version: 1.6.6' then begin
    on_error,1
    dprint,dlevel=0,verbose=verbose,out
    dprint,dlevel=0,verbose=verbose,'Warning! This version of ICY is known to have a major bug with Mac OS X 10.7 or newer'
    dprint,dlevel=0,verbose=verbose,'Please use SPICE_INSTALL,/FORCE to get a newer version of ICY'
    dprint,dlevel=0,verbose=verbose,'OR download the special build from: '
    dprint,dlevel=0,verbose=verbose,'http://naif.jpl.nasa.gov/pub/naif/misc/tmp/edw/ticy.zip'
    message,'SORRY!'
    tested=0
  endif
  if tested eq 0 then return,0
endif

if keyword_set(files) then begin
   kind = 'ALL'
   cspice_ktotal,kind,count
   if count gt 0 then kernels = strarr(count) else kernels=''
   kind = 'ALL'
   for i=0,count-1 do begin
      cspice_kdata,i,kind,filename,ft,source,handle,found
      kernels[i] = filename
   endfor
;   printdat,kernels
   mf = strfilter(kernels,files)
   return,mf
endif

return, tested
  
end
