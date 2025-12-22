p1 = file_search('/disks/data/fast/l2/esv/*/*.cdf')
n1 = n_elements(p1)
orbno = lonarr(n1)
For j = 0, n1-1 Do Begin
   x1 = strsplit(p1[j], '_', /extract)
   nx1 = n_elements(x1)
   orbno[j] = long(x1[nx1-2])
Endfor

end_orbit = 19999
test_orbit = lindgen(end_orbit)
xx = sswhere_arr(test_orbit, orbno, /notequal)
openw, unit, 'fast_esv_missing2', /get_lun
For j = 0, n_elements(xx)-1 Do printf, unit, xx[j]
free_lun, unit
End


  
