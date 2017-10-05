restore, 'radar_list.tmpl'
rd = read_ascii('radar_list', templ=tmpl )

bm=16
rg=75
lst_16_110 = 'hok hkw'
lst_24_110 = 'bks wal ade adw'
lst_22_110 = 'fhe fhw'
lst_24_75 = 'cve cvw'
lst_16_100 = 'gbr inv kap rkn cly'

file_mkdir, 'sdfov'

for i=0, n_elements(rd.stid)-1 do begin
  
  id = rd.stid[i]
  stn= rd.stn[i]
  
  bm=16 & rg=75
  if strpos(lst_16_110,stn) ne -1 then begin & bm=16 & rg=110 & endif
  if strpos(lst_24_110,stn) ne -1 then begin & bm=24 & rg=110 & endif
  if strpos(lst_22_110,stn) ne -1 then begin & bm=22 & rg=110 & endif
  if strpos(lst_24_75,stn) ne -1 then begin & bm=24 & rg=75 & endif
  if strpos(lst_16_100,stn) ne -1 then begin & bm=16 & rg=100 & endif
  
  print, id, stn, 'bm=',bm, 'rg=',rg
  
  define_beams, force_coord='geog',station=id, /normal
  glon = x[0:bm,0:rg]
  glat = y[0:bm,0:rg]
  sdfovtbl = {glat:glat, glon:glon}

  savfn = 'sdfov/sdfovtbl_'+stn+'.sav'
  save, sdfovtbl, file=savfn
  print, '..saved as '+savfn 

endfor

end





