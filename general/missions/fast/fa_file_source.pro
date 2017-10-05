;+
; Purpose:
;   specifies source location and retrieval mechanism of FAST data files
; Usage:
;    source = fa_file_source()
; Note:
;   This file should provide the sole location of this information
; Davin Larson
;-
function fa_file_source ,verbose=verbose         ,new_source=new_source

common fa_file_source_com,fa_source

if keyword_set(new_source) then fa_source=new_source

if size(/type,fa_source) ne 8 || fa_source.init eq 0 then begin
    fa_source = file_retrieve(/structure_format)
    fa_source.remote_data_dir = 'http://themis.ssl.berkeley.edu/data/'
;    fa_source.local_data_dir = root_data_dir()  ; unneeded
    file_open,'d',fa_source.local_data_dir,/test,createable=ct
    fa_source.no_download = ct eq 0
    fa_source.init= 1
endif
source = fa_source
if keyword_set(verbose) then source.verbose = verbose
return,source
end
