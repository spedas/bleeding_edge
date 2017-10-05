;+
; NAME: 
;       mvn_euv_load
; SYNTAX: 
;       mvn_euv_load, trange=trange, /all
; PURPOSE:
;       Load procedure for the calibrated EUV irradiances, for
;       channels A (17-22 nm), B (0-7 nm), and C (121-122 nm).
; INPUTS
;       trange
; OUTPUT: 
; KEYWORDS: 
; HISTORY:      
; VERSION: 
;  $LastChangedBy: clee $
;  $LastChangedDate: 2017-04-27 13:57:56 -0700 (Thu, 27 Apr 2017) $
;  $LastChangedRevision: 23232 $
;  $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/euv/mvn_euv_load.pro $
;
;CREATED BY:  Christina O. Lee  02-24-15
;FILE: mvn_euv_load.pro
;-


pro mvn_euv_load, trange=trange, all=all  , download_only = download_only, verbose=verbose
  L2_fileformat = 'maven/data/sci/euv/l2/YYYY/MM/mvn_euv_l2_bands_YYYYMMDD_v??_r??.cdf'
  files = mvn_pfp_file_retrieve(L2_fileformat, trange=trange, /daily_names, /valid_only,/last_version,verbose=verbose)
  
  if ~keyword_set(download_only) then begin
    if keyword_set(all) then vf='data freq dfreq ddata flag' else vf='data'
    cdf2tplot, files, varformat=vf, prefix='mvn_euv_'    
  endif
end
