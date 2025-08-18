;+
;Function: icy_test
;
;Purpose:  Tests whether the idl/icy module is installed
;          Provides installation message if not installed
;
;Keywords:
;         None
;
;Returns: 1 on success 0 on failure
;
;Example:
;   if(icy_test() eq 0) then return
;Notes:
;  Should be called in all idl icy wrapper routines
;
; $LastChangedBy: peters $
; $LastChangedDate: 2012-08-01 12:02:01 -0700 (Wed, 01 Aug 2012) $
; $LastChangedRevision: 10763 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/external/IDL_ICY/icy_test.pro $
;-

function icy_test

help, /dlm, output = out

;v_string = '6.7'

filter = strfilter(out, '*ICY*',/index)

if(filter[0] eq -1) then begin
  message, /continue, 'Required module IDL/ICY not installed'
  message, /continue, 'To install ICY please download a copy'
  message, /continue, 'Place the module binary and the .dlm in:'
  message, /continue, !DLM_PATH
  message, /continue, 'and restart IDL to install the package'
  message, /continue, 'more detailed installation instructions'
  message, /continue, 'can be found on the Themis web site, or'
  message, /continue, 'in the Themis software distribution at'
  message, /continue, 'external/IDL_ICY/README.txt'
  return, 0
endif
;
;if ~stregex(out[filter+1],v_string,/boolean) then begin
;  message, /continue, 'Incorrect version of geopack found'
;  message, /continue, 'Version ' + v_string + ' expected'
;  message,/continue, 'Please download the newest version and'
;  message, /continue, 'place the binary(.dll,.so,.etc..) and the .dlm in:'
;  message, /continue, !DLM_PATH
;  message, /continue, 'then restart IDL to install the package'
;  message, /continue, 'More detailed installation instructions'
;  message, /continue, 'can be found on the Themis web site, or'
;  message, /continue, 'in the Themis software distribution at'
;  message, /continue, 'external/IDL_GEOPACK/README.txt'
;  return, 0
; endif

return, 1
  
end
