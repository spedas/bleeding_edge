;$LastChangedBy: davin-mac $
;$LastChangedDate: 2021-08-18 22:38:54 -0700 (Wed, 18 Aug 2021) $
;$LastChangedRevision: 30223 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SWFO/STIS/swfo_ccsds_data.pro $

function swfo_ccsds_data,ccsds
  if typename(ccsds) eq 'CCSDS_FORMAT' then data = *ccsds.pdata  else data=ccsds.data
  return,data
end
