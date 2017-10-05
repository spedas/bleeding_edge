


function spp_swp_ccsds_data,ccsds
  if typename(ccsds) eq 'CCSDS_FORMAT' then data = *ccsds.pdata  else data=ccsds.data
return,data
end



