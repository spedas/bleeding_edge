;$LastChangedBy: davin-mac $
;$LastChangedDate: 2023-12-11 00:17:46 -0800 (Mon, 11 Dec 2023) $
;$LastChangedRevision: 32281 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/swx/swx_ccsds_data.pro $

function swx_ccsds_data,ccsds
  data = *ccsds.pdata
  ;if typename(ccsds) eq 'SWX_CCSDS_FORMAT' then data = *ccsds.pdata  else data=ccsds.data
  return,data
end
