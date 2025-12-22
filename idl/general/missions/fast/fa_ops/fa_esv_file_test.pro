;Checks fast database for missing esv version 2 files
allfiles_v01 = file_search('/disks/data/fast/l2/esv/?????/fa*v01.cdf')
;allfiles_v02 = file_search('/disks/data/fast/l2/esv/?????/fa*v02.cdf')

nfiles = n_elements(allfiles_v01)

orbs = 0L
openw, unit, 'fa_esv_file_test.txt', /get_lun
For j = 0, nfiles-1 Do Begin
   v01j = allfiles_v01[j]
   v02j = v01j
   str_replace, v02j, 'v01', 'v02'
   If(is_string(file_search(v01j)) && ~is_String(file_search(v02j))) Then Begin
      tmpj = strsplit(v02j, '_', /extract)
      orbj = long(tmpj[5])
      printf, unit, orbj
      orbs = [orbs, orbj]
   Endif
Endfor
orbs = orbs[1:*]
free_lun, unit

End
