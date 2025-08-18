; $LastChangedBy: davin-mac $
; $LastChangedDate: 2018-12-08 17:22:50 -0800 (Sat, 08 Dec 2018) $
; $LastChangedRevision: 26288 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/COMMON/spp_apdat.pro $

function spp_apdat,apid,get_info=get_info

spp_apdat_info,apid,apdats=apdats,/quick

common spp_apdat_info_com, all_apdat, alt_apdat, all_info,temp1,temp2
if keyword_set(get_info) then begin
  return,all_info
endif
  
return, apdats

end
  
