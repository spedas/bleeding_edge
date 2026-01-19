;+Checks for missing FAST L2 data files
Function fast_file_missing, datatype = datatype, $ ;'esv','e4k','e16k','dsp','sfa'
                            version = version, $ ;version number, default is 2
                            end_orbit = end_orbit ;end orbit to test, default is 19999
;-
  If(keyword_set(datatype)) Then Begin
     dtyp = strcompress(/remove_all, strlowcase(datatype))
  Endif Else dtyp = 'esv'
  If(keyword_set(version)) Then Begin
     vno = 'v'+string(version, format = '(i2.2)')
  Endif Else vno = 'v02'
  If(keyword_set(end_orbit)) Then enorb = end_orbit Else enorb = 19999
  
  p1 = file_search('/disks/data/fast/l2/'+dtyp+'/*/*'+vno+'.cdf')
  n1 = n_elements(p1)
  orbno = lonarr(n1)
  For j = 0, n1-1 Do Begin
     x1 = strsplit(p1[j], '_', /extract)
     nx1 = n_elements(x1)
     orbno[j] = long(x1[nx1-2])
  Endfor


  test_orbit = lindgen(enorb)
  xx = sswhere_arr(test_orbit, orbno, /notequal)
  openw, unit, 'fast_'+dtyp+'_missing', /get_lun
  For j = 0, n_elements(xx)-1 Do printf, unit, xx[j]
  free_lun, unit
  Return, xx
End


  
