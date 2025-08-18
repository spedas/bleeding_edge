function spp_swp_spani_thermaltest1_files
  src = spp_file_source()
  pathnames = 'spp/sweap/prelaunch/gsedata/EM/spanai/201502??_*/PTP_data.dat'
  printdat,src
  files=file_retrieve(pathnames,_extra=src)
  return,files
end


