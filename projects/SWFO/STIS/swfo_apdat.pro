; $LastChangedBy: davin-mac $
; $LastChangedDate: 2021-08-17 02:32:37 -0700 (Tue, 17 Aug 2021) $
; $LastChangedRevision: 30212 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SWFO/STIS/swfo_apdat.pro $

function swfo_apdat,apid,get_info=get_info

swfo_apdat_info,apid,apdats=apdats,/quick

common swfo_apdat_info_com, all_apdat, alt_apdat, all_info,temp1,temp2
if keyword_set(get_info) then begin
  return,all_info
endif
  
return, apdats

end
  
