;+Checks for missing FAST L2 data files
Function fast_orbit_oops, datatype = datatype, $ ;'esv','e4k','e16k','dsp','sfa'
                          version = version, $   ;version number, default is 2
                          end_orbit = end_orbit, $ ;end orbit to test, default is 19999
                          remove_files = remove_files ;if set, then delete the files
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
  orbtime = strarr(n1)
  oops_filename = ''
  oops_count = 0L
  For j = 0, n1-1 Do Begin
     x1 = strsplit(p1[j], '_', /extract)
     nx1 = n_elements(x1)
     orbno[j] = long(x1[nx1-2])
     orbtime[j] = x1[nx1-3]
     If(j Gt 0) Then Begin
        If(orbtime[j] Eq orbtime[j-1]) Then Begin
           oops_count++
           If(oops_count Eq 1) Then Begin
              oops_orbit = orbno[j]
              oops_orbtime = orbtime[j]
              ooops_filename = p1[j]
           Endif Else Begin
              oops_orbit = [oops_orbit, orbno[j]]
              oops_orbtime = [oops_orbtime, orbtime[j]]
              oops_filename = [oops_filename, p1[j]]
           Endelse
        Endif
     Endif
  Endfor

  If(oops_count Gt 0) Then Begin
     openw, unit, 'fast_'+dtyp+'_orbit_oops', /get_lun
     For j = 0, n_elements(oops_orbit)-1 Do Begin
        printf, unit, oops_filename[j]
        If(keyword_set(remove_files)) Then Begin
           cmd = '/bin/rm -f '+oops_filename[j]
           print, 'Spawning: '+cmd
           spawn, cmd
        Endif
     Endfor
     free_lun, unit
  Endif
  Return, oops_filename
End


  
