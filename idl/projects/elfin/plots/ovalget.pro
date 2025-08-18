;+
; PROCEDURE:
;         ovalget
;
; PURPOSE:
;   reads oval files and returns values for poleward/equatorward lon/lat (arrays)
;         
;
; INPUT: 
;   qindx
;   
; OUTPUT
;   pwdboundlonlat: p for poleward longitude and latitude (nx2)
;   ewdboundlonlat: e for equatorward longitude and latitude (nx2)
;
;-
pro ovalget,qindx,pwdboundlonlat,ewdboundlonlat

  res=routine_info('ovalget', /source)
  ovaldir=strmid(res.path,0,strlen(res.path)-11)+'ovals\'
  ovalpfile='ov_q'+strtrim(long(qindx),1)+'_p.dat' ; p for poleward ; fixed to not bomb for q=6
  ovalefile='ov_q'+strtrim(long(qindx),1)+'_e.dat' ; e for equatorward ; fixed to not bomb for q=6

  pblatlon=read_ascii_cmdline(ovaldir+ovalpfile)
  ;pblatlon.field2[*]=(pblatlon.field2[*]+180.) mod 360 ; mlt -> smlon
  eblatlon=read_ascii_cmdline(ovaldir+'\'+ovalefile)
  ;eblatlon.field2[*]=(eblatlon.field2[*]+180.) mod 360 ; mlt -> smlon
  ipbascendlon=sort(pblatlon.field2[*]) ; ascending poleward boundary (pb) longitude indx
  iebascendlon=sort(eblatlon.field2[*]) ; ascending poleward boundary (pb) longitude indx
  
  print,'min max values of smlon'
  print,'p num=',n_elements(pblatlon.field2)
  print,min(pblatlon.field2),max(pblatlon.field2)
  print,'e num=',n_elements(eblatlon.field2)
  print,min(eblatlon.field2),max(eblatlon.field2)
  pwdb_lonlat_wgaps=[[pblatlon.field2[ipbascendlon],360.],[pblatlon.field1[ipbascendlon],pblatlon.field1[ipbascendlon[0]]]]
  ewdb_lonlat_wgaps=[[eblatlon.field2[iebascendlon],360.],[eblatlon.field1[iebascendlon],eblatlon.field1[iebascendlon[0]]]]
  
  ; ensure no gaps in longitudes
  xdegap, 1, 0.5, pwdb_lonlat_wgaps[*,0], pwdb_lonlat_wgaps[*,1], newpmlts, newplats
  xdeflag,'linear',newpmlts,newplats

  ; remove last point (360) cast to smlon, resort, add last point
  nppnts=n_elements(newpmlts)
  newpmlts=newpmlts[0:nppnts-2]
  newplats=newplats[0:nppnts-2]
  newplongs=(newpmlts+180.) mod 360.
  i2sortp=sort(newplongs)
  pwdboundlonlat=make_array(361,2,/float)
  pwdboundlonlat[*,0]=[newplongs[i2sortp],360.]
  pwdboundlonlat[*,1]=[newplats[i2sortp],newplats[i2sortp[0]]]
  
  xdegap, 1, 0.25, ewdb_lonlat_wgaps[*,0], ewdb_lonlat_wgaps[*,1], newemlts, newelats
  xdeflag,'linear',newemlts,newelats

  ; remove last point (360) cast to smlon, resort, add last point
  nepnts=n_elements(newemlts)
  newemlts=newemlts[0:nepnts-2]
  newelats=newelats[0:nepnts-2]
  newelongs=(newemlts+180.) mod 360.
  i2sorte=sort(newelongs)
  ewdboundlonlat=make_array(361,2,/float)
  ewdboundlonlat[*,0]=[newelongs[i2sorte],360.]
  ewdboundlonlat[*,1]=[newelats[i2sorte],newelats[i2sorte[0]]]
  
  return

end
