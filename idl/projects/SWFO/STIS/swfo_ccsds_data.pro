;$LastChangedBy: davin-mac $
;$LastChangedDate: 2025-11-05 10:13:48 -0800 (Wed, 05 Nov 2025) $
;$LastChangedRevision: 33828 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SWFO/STIS/swfo_ccsds_data.pro $

function swfo_ccsds_data,ccsds
  
  ;data = *ccsds.pdata
  data = ccsds.data[0:ccsds.pkt_size-1]
  
  ;if typename(ccsds) eq 'SWFO_CCSDS_FORMAT' then data = *ccsds.pdata  else data=ccsds.data
  return,data
end
