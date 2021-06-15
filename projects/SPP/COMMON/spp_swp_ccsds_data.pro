;$LastChangedBy: ali $
;$LastChangedDate: 2021-06-14 10:41:21 -0700 (Mon, 14 Jun 2021) $
;$LastChangedRevision: 30043 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/COMMON/spp_swp_ccsds_data.pro $

function spp_swp_ccsds_data,ccsds
  if typename(ccsds) eq 'CCSDS_FORMAT' then data = *ccsds.pdata  else data=ccsds.data
  return,data
end
