;+
;PROCEDURE:   mvn_sta_cio_load
;PURPOSE:
;  Loads all available MAVEN cold ion outflow data that were 
;  processed by mvn_sta_coldion.pro.
;
;INPUTS:
;     ptr   : A named variable to hold a pointer to the data.
;  species  : Which database to load?  ('h', 'o1', 'o2')
;
;KEYWORDS:
;
;    FROOT  : File root for save file (default = 'cio_AtoQ_').
;
;     TAGS  : A named variable to hold a string array of the names
;             of the data structure tags.
;
;     NPTS  : A named variable to hold the number of data points.
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2026-09-01 12:06:25 -0700 (Tue, 01 Sep 2026) $
; $LastChangedRevision: 34858 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swea/mvn_sta_cio_load.pro $
;
;CREATED BY:	David L. Mitchell
;FILE:  mvn_sta_cio_load.pro
;-
pro mvn_sta_cio_load, ptr, species, froot=froot, tags=tags, npts=npts

  common cio_com, cname, cstart, cstop

; CIO campaign times

  if (n_elements(cname) eq 0) then begin
    cname = ['A','B','C','D','E','F','G','H','I','J','K','L','M','N','O','P','Q']
    cstart = time_double(['2016-08-24','2016-11-23','2017-05-08','2017-10-31','2018-02-27','2019-10-14', $
                          '2020-09-22','2021-08-02','2021-12-09','2022-07-24','2022-09-09','2022-12-22', $
                          '2023-05-04','2023-08-31','2024-05-01','2024-09-12','2025-01-30'])
    cstop = time_double(['2016-09-25','2017-02-01','2017-07-02','2018-01-12','2018-05-08','2019-11-26', $
                         '2020-10-29','2021-08-23','2022-01-14','2022-08-01','2022-09-21','2022-12-27', $
                         '2023-06-03','2023-10-18','2024-05-23','2024-10-10','2025-03-07'])
  endif

  mvn_sta_cio_clear, ptr
  path = '/Users/mitchell/Documents/Home/Mars/MAVEN/Cold Ion Outflow/'
  if (size(froot,/type) ne 7) then froot = 'cio_AtoQ_'

  if (size(species,/type) ne 7) then species = 'O2' else species = strupcase(species[0])
  case species of
    'H'  : fname = path + froot + 'h.sav'
    'O1' : fname = path + froot + 'o1.sav'
    'O2' : fname = path + froot + 'o2.sav'
    else : begin
             print,'Species not recognized: ',species
             return
           end
  endcase

  finfo = file_info(fname)
  if (~finfo.exists) then begin
    print," Can't find data file: ",fname
    return
  endif   

  print,'  Reading data ... ',format='(a,$)'
  restore, fname
  print,'done.'

  case species of
    'H'  : data = temporary(cio_h)
    'O1' : data = temporary(cio_o1)
    'O2' : data = temporary(cio_o2)
    else : begin
             print,'Unrecognized variable name.'
             return
           end
  endcase

; Convert from array of structures to structure of arrays

  print,'  Converting data ... ',format='(a,$)'
  mvn_sta_cio_convert, data
  print,'done.'

; Make sure it is a pointer

  if (data_type(data) eq 8) then data = ptr_new(data,/no_copy)
  if (data_type(data) ne 10) then begin
    print,'  No data structure found.'
    return
  endif

; Report the result and return

  ptr = data
  tags = tag_names(*ptr)
  npts = n_elements((*ptr).time)
  print,''

  return

end
