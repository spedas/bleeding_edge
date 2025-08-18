;+
; PRO erg_version_table
;
; The program for output data information readed by load procedures 
;
; :Keywords:
;   filename: the name of output file (***.csv and ***.txt)
;             default is 'erg_version_table_YYYYMMDDhhss'
;
; :Examples:
;   IDL> timespan, '2017-04-01'
;   IDL> erg_load_pwe_hfa
;   IDL> erg_version_table, filename='datalist'
;-

pro erg_version_table, filename=filename 


get_data, 'erg_load_datalist', data=datalist

; check datalist format
if ~ISA(datalist,'hash') then begin
   dprint, 'Input variable must be a hash variable. Use keyword of load procedures: version_num.'
   return
endif

print, ''
print, '----- erg load data list -----'
print, ''

; make output filename if not specified
if ~keyword_set(filename) then begin
   spawn,'date +%Y',yyyy
   spawn,'date +%m',mm
   spawn,'date +%d',dd
   spawn,'date +%M',hh
   spawn,'date +%S',ss
   filename='erg_version_table_'+yyyy+mm+dd+hh+ss
endif

; output files
openw, lun_csv, filename+'.csv', /get_lun
openw, lun_txt, filename+'.txt', /get_lun

; sort each data
filelist = datalist.keys()  
filelist = filelist.Sort()

; print header of csv
printf, lun_csv, 'dataname, date, major version, minor version, filepath'

foreach file, filelist do begin

   i_file = datalist[file]
   datelist = i_file.keys()
   datelist = datelist.Sort()

   v = ''
   d = ''
   ; make all data csv
   foreach date, datelist do begin

      printf, lun_csv, file + ', ' + date+', '+i_file[date,'major']+', '+i_file[date, 'minor']+', '+i_file[date, 'fullpath']

      d = [d, date]
      v = [v, 'v'+i_file[date,'major']+'.'+i_file[date, 'minor']]

   endforeach

   ; make compressed txt

   d = d[1l:*]
   v = v[1l:*]

   idx = [-1l, uniq(v)]
   n = n_elements(idx)

   keys = v[uniq(v, sort(v))]
   h = hash(keys, replicate('',n_elements(keys)))

   for i=0, n-2l do begin

      idx1 = idx[i]+1l
      idx2 = idx[i+1l] 

      IF (idx2 NE idx1) THEN h[v[idx2]] = h[v[idx2]] + ', ' + d[idx1] + ' - ' + d[idx2] 
      IF (idx2 EQ idx1) THEN h[v[idx2]] = h[v[idx2]] + ', ' + d[idx2]

   endfor

   vlist = h.keys()
   vlist = vlist.Sort()

   print, file + ' : '
   printf, lun_txt, file + ' : '

   foreach v, vlist do begin

      print, '   ' + v + ' : '
      printf, lun_txt, '   ' + v + ' : '
      print, '   ' + '   ' + strmid(h[v], 2)
      printf, lun_txt, '   ' + '   ' + strmid(h[v], 2)

   endforeach

   print, ' '
   printf, lun_txt, ' '


endforeach
print, '-----------------------------'

free_lun, lun_csv
free_lun, lun_txt

END
