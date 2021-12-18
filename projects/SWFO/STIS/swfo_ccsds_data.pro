;$LastChangedBy: davin-mac $
;$LastChangedDate: 2021-12-17 09:47:01 -0800 (Fri, 17 Dec 2021) $
;$LastChangedRevision: 30471 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SWFO/STIS/swfo_ccsds_data.pro $

function swfo_ccsds_data,ccsds
  if typename(ccsds) eq 'SWFO_CCSDS_FORMAT' then data = *ccsds.pdata  else data=ccsds.data
  return,data
end
