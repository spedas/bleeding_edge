;+
;Determine whether SPICE kernels are loaded in to IDL memory, and if so, which ones. Returns a data structure with this information in.
;
;
;For testing:
;.r /Users/cmfowler/IDL/STATIC_routines/Generic/mvn_sta_anc_determine_spice_kernels.pro
;-
;

function mvn_sta_anc_determine_spice_kernels

sl = path_sep()   ;'/' or '\' for windows vs mac

cspice_ktotal, 'ALL', count  ;Look at all kernels loaded; count is the number loaded.

;ARRAY:
if count gt 0 then kernels = strarr(count) else kernels = ''

for ii = 0, count-1l do begin
    cspice_kdata, ii, 'ALL', file, type, source, handle, found
    
    if found eq 1 then kernels[ii] = file  ;load in file name   
endfor

;Create fields containing the number of specific types of kernels. The most useful are usually lsk, sclk and fk, although this depends on
;the user request.
nLSK = total(strmatch(kernels, '*'+sl+'lsk'+sl+'*'),/nan)
nPCK = total(strmatch(kernels, '*'+sl+'pck'+sl+'*'),/nan)
nSPK = total(strmatch(kernels, '*'+sl+'spk'+sl+'*'),/nan)
nSCLK = total(strmatch(kernels, '*'+sl+'sclk'+sl+'*'),/nan)
nFK = total(strmatch(kernels, '*'+sl+'fk'+sl+'*'),/nan)
nIK = total(strmatch(kernels, '*'+sl+'ik'+sl+'*'),/nan)
nCK = total(strmatch(kernels, '*'+sl+'ck'+sl+'*'),/nan)

output = create_struct('nLSK'     ,   nLSK    , $   ;number of each kernel type
                       'nPCK'     ,   nPCK    , $
                       'nSPK'     ,   nSPK    , $
                       'nSCLK'    ,   nSCLK   , $
                       'nFK'      ,   nFK     , $
                       'nIK'      ,   nIK     , $
                       'nCK'      ,   nCK     , $
                       'nTOT'     ,   count   , $  ;total number of kernels
                       'kernels'  ,   kernels)     ;kernel filenames

return, output

end


