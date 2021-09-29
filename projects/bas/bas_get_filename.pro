pro bas_get_filename, site=site, year=year2, doy=doy, filename=filename

  res=routine_info('bas_get_filename', /source)
  path=strmid(res.path,0,strlen(res.path)-20)
  filelist=path+'lpm_list.txt'

  get_lun, lun  
  openr, lun, filelist
 
  search_str='.lpm.dg4.' + year2 + '.' + doy + '.txt' 
  filename=''
  while not eof(lun) do begin
    readf, lun, filename
    if strpos(filename, search_str) NE -1 then break
  endwhile
  
end