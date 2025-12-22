;Testing SDT+IDL
Pro eb_config_test_pls
  p = file_search('*.cdf')
  openw, unit, 'eb_config_test_pls.txt', /get_lun
  printf, unit, p
  free_lun, unit
End
