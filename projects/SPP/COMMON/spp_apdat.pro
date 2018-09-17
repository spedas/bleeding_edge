; $LastChangedBy: phyllisw2 $
; $LastChangedDate: 2018-09-09 14:57:44 -0700 (Sun, 09 Sep 2018) $
; $LastChangedRevision: 25757 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/COMMON/spp_apdat.pro $

function spp_apdat,apid

spp_apdat_info,apid,apdats=apdats,/quick
  
return, apdats

end
  
