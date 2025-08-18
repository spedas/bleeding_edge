; $LastChangedBy: davin-mac $
; $LastChangedDate: 2023-12-02 00:05:21 -0800 (Sat, 02 Dec 2023) $
; $LastChangedRevision: 32261 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/swx/swx_apdat.pro $

function swx_apdat,apid,get_info=get_info

swx_apdat_info,apid,apdats=apdats,/quick

common spp_apdat_info_com, all_apdat, alt_apdat, all_info,temp1,temp2
if keyword_set(get_info) then begin
  return,all_info
endif
  
return, apdats

end
  
