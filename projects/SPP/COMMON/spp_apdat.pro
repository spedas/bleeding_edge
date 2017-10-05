function spp_apdat,apid,matchname=matchname

  common spp_apdat_info_com, all_apdat, misc1


  if ~keyword_set(all_apdat) || ~obj_valid( all_apdat[apid] ) then spp_apdat_info,apid,matchname=matchname
  
  return, all_apdat[apid]
  
 end
  
