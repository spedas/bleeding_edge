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
; $LastChangedDate: 2017-11-21 12:02:46 -0800 (Tue, 21 Nov 2017) $
; $LastChangedRevision: 24333 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/kaguya/map/kgy_map_ql_dl.pro $
;-

pro kgy_map_ql_dl, trange=trange, version=version, outfiles=outfiles

if ~keyword_set(version) then version = '001'
version2 = strmid(version,2,1)+'.0'

tr = timerange(trange)
res = round(24*3600L) ;- daily files
sres = 0l
str = (tr-sres)/res
dtr = (ceil(str[1]) - floor(str[0]) )  > 1
times = res * (floor(str[0]) + lindgen(dtr))+sres
 
pf = 'sln-l-pace-5-et-summary-v'+version2+time_string(times,tf='/YYYYMMDD/data/PACE_ET1_YYYYMMDD_V'+version+'.png')
outfiles = kgy_file_retrieve(pf,/public,daily=0)

if total(strlen(outfiles)) gt 0 then dprint,'Summary plots: '+outfiles

return

end
