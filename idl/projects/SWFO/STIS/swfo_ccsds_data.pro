;$LastChangedBy: davin-mac $
;$LastChangedDate: 2023-12-02 00:12:52 -0800 (Sat, 02 Dec 2023) $
;$LastChangedRevision: 32262 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SWFO/STIS/swfo_ccsds_data.pro $

function swfo_ccsds_data,ccsds
  data = *ccsds.pdata
  ;if typename(ccsds) eq 'SWFO_CCSDS_FORMAT' then data = *ccsds.pdata  else data=ccsds.data
  return,data
end
