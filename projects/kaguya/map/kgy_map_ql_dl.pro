;+
; PROCEDURE:
;       kgy_map_ql_dl
; PURPOSE:
;       downloads Kaguya MAP quicklook plots
; CALLING SEQUENCE:
;       timespan,'2008-01-01',30
;       kgy_map_ql_dl
; KEYWORDS:
;       trange: time range
;       outfiles: returns plot file paths
; CREATED BY:
;       Yuki Harada on 2016-10-07
;
; $LastChangedBy: haraday $
; $LastChangedDate: 2016-10-07 11:58:34 -0700 (Fri, 07 Oct 2016) $
; $LastChangedRevision: 22067 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/kaguya/map/kgy_map_ql_dl.pro $
;-

pro kgy_map_ql_dl, trange=trange, version=version, outfiles=outfiles

if ~keyword_set(version) then version = '001'

pf = 'PACE_ET1_YYYYMMDD_V'+version
outfiles = kgy_file_retrieve(pf,trange=trange,/public,datasuf='.png')

if total(strlen(outfiles)) gt 0 then dprint,'Summary plots: '+outfiles

return

end
