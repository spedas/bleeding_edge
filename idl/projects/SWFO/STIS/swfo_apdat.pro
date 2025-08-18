; $LastChangedBy: davin-mac $
; $LastChangedDate: 2023-12-02 00:12:52 -0800 (Sat, 02 Dec 2023) $
; $LastChangedRevision: 32262 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SWFO/STIS/swfo_apdat.pro $

function swfo_apdat,apid,get_info=get_info

swfo_apdat_info,apid,apdats=apdats,/quick

common spp_apdat_info_com, all_apdat, alt_apdat, all_info,temp1,temp2
if keyword_set(get_info) then begin
  return,all_info
endif
  
return, apdats

end
  
