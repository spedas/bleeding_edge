;+Checks for missing FAST L2 data files with data from the wrong orbit
Function fast_orbit_oops2, datatype = datatype, $ ;'esv','e4k','e16k','dsp','sfa'
                           version = version, $   ;version number, default is 2
                           end_orbit = end_orbit, $ ;end orbit to test, default is 19999
                           full_test = full_test, $ ;If set then check all of the tplot vars, otherwise check start time
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
  filename = strarr(n1)
  oops_count = 0L
  For j = 0, n1-1 Do Begin
     x1 = strsplit(p1[j], '_', /extract)
     nx1 = n_elements(x1)
     orbno[j] = long(x1[nx1-2])
     orbtime[j] = x1[nx1-3]
;load_data for this orbit, and check times
     If(keyword_set(full_test)) Then Begin
        testj = fa_data_time_test(dtyp, orbno[j])
     Endif Else Begin           ;just check start time for file
        yr = strmid(orbtime[j], 0, 4)
        mm = strmid(orbtime[j], 4, 2)
        dd = strmid(orbtime[j], 6, 2)
        hr = strmid(orbtime[j], 8, 2)
        mn = strmid(orbtime[j], 10, 2)
        ss = strmid(orbtime[j], 12, 2)
        otj = time_double(yr+'-'+mm+'-'+dd+'/'+hr+':'+mn+':'+ss)
        ppp = fa_orbit_to_time(orbno[j])
        otmin = ppp[1] & otmax = ppp[2]
        If(otj Ge (otmin-1) And otj Le otmax) Then testj = 1b $
        Else testj = 0b
     Endelse
     If(testj Eq 0) Then Begin
        oops_count++
        If(oops_count Eq 1) Then Begin
           oops_orbit = orbno[j]
           oops_orbtime = orbtime[j]
           oops_filename = p1[j]
        Endif Else Begin
           oops_orbit = [oops_orbit, orbno[j]]
           oops_orbtime = [oops_orbtime, orbtime[j]]
           oops_filename = [oops_filename, p1[j]]
        Endelse
     Endif
  Endfor

  If(oops_count Gt 0) Then Begin
     openw, unit, 'fast_'+dtyp+'_orbit_oops2', /get_lun
     For j = 0, n_elements(oops_orbit)-1 Do Begin
        printf, unit, oops_filename[j]
        If(keyword_set(remove_files)) Then Begin
           cmd = '/bin/rm -f '+oops_filename[j]
           print, 'Spawning: '+cmd
           spawn, cmd
        Endif
     Endfor
     free_lun, unit
     Return, oops_filename
  Endif Else Return, ''
End


  
