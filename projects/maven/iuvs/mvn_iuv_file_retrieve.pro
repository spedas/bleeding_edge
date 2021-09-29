; THE PURPOSE OF THIS ROUTINE IS TO RETRIEVE THE FILE NAMES OF IUVS
; FILES FROM EITHER A CERTAIN ORBIT RANGE OR A CERTAIN TIME RANGE.

; KEYWORDS:

; LEVEL: this refers to data level and must be one of the following:
; 'l1b', 'l1c', 'l2', 'l3', or 'ql'

; PRODUCT: this refers to the specific type of data product  within
; the specific level requested. This must be one of the following:
; 'calibration', 'corona', 'disk', 'limb', phobos, centroid, cruise, echelle,
; occultation, transition

;NOTE: for now, this routine only works for l1b, l1c disk and limb files

function mvn_iuv_file_retrieve, trange, level = level, product = product
  
  year_start = floor(secs2yrs(trange [0]))
  year_start_string = time_string (trange [0], Tformat = 'YYYY')
  year_end = floor(secs2yrs(trange [1]))
  year_end_string = time_string (trange [1], Tformat = 'YYYY')
  month_start_string = time_string (trange [0], Tformat = 'MM')
  month_start = floor (float (month_start_string))
  month_end_string = time_string (trange [1], Tformat = 'MM')
  month_end = floor (float (month_end_string))

  path = '/disks/data/maven/data/sci/iuv/'+level+'/'+product+'/'

; figure out how many directories to check
  ndir = 1+12*(year_end - year_start) + month_end_string - month_start_string
  
; npw go through each directory
  year_count = 0
  month_count = 0
  directory_name = strarr(ndir)
  Files = ''
  for K = 0, ndir-1 do begin
     year_string = roundst(year_start + ceil((k + month_start - 12)*1.0/12))
     month_string = numbered_filestring(((month_start + k) mod 12), digits = 2)
     directory_name[k] = path + year_string +'/' + month_string +'/'
; for each directory, grab only the files with time strings inside the
; trange
     these_files = get_file_name_string (directory_name [K], identifier = 'mvn_iuv*.fits.gz')
     nf = n_Elements (these_files)
     for J = 0, nf-1 do begin
        ss = strsplit(these_files[J],'_',/extract); split up the filename
        tst = ss[4]; this is the time part of the filename
        filetime = time_double (tst, Tformat = 'YYYYMMDDThhmmss')
        if filetime gt trange [0] and filetime lt trange [1] then files = $
           [files, directory_name[k]+these_files [j]]
     endfor
  endfor

  if n_elements (files) eq 1 then message, 'No files found that match time range'

  return, files [1:*]
end
  
  
function get_file_name_string,  path,  identifier =  identifier,  $
                                full_name =  full_name, $
                                subdirectory = subdirectory
  if not keyword_set (identifier) then identifier =  ' '
    rmst =  'rm '+'./temp_list_file.txt'
 
  spawn,  rmst
  if not keyword_set (subdirectory) then list_string = 'ls ' +$
     path + identifier + ' > '+ './temp_list_file.txt' else list_string = $
     'ls -R ' +$
     path + identifier + ' > '+ './temp_list_file.txt'
  spawn,  list_string
  openr,  unit, './temp_list_file.txt', /get_lun
  if eof(unit) eq 1 then return,  sqrt (-7.3)
   names = strarr(25000)
  i = 0
  redflag = 0
  
  while redflag eq 0 do begin 
    
    kal = ' '
    readf, unit, kal 
    i = i+1
    if eof(unit) eq 1 then redflag = 1
    print, kal
    print, redflag
    ;names_split =  strsplit (kal, '/', /extract,  count =  count)
   ; if not keyword_set (full_name) then names [i-1] =  $
    ;  names_split [count -1] else 
    names[i-1] = kal
  endwhile
  names = names[0:i-1]
  names = filename_only (names)
; default is to shorten the string to exclude the path
 
    
  close, /all
  rmst =  'rm ' +'./temp_list_file.txt'

  spawn,  rmst
  if keyword_set (full_name) then return,  path + $
    names [0:i -1] else return,  names [0: i -1]
end

function numbered_filestring, i, digits = digits
  if not keyword_set (digits) then digits = 4
  case digits of
      1: return, strcompress(string(i mod 10), /rem)
      2: return,strcompress(string(i/10 mod 10), /rem)+$
    strcompress(string(i mod 10), /rem)
      3: return,strcompress(string((i - 1000*(i/1000))/100), /rem)+$
    strcompress(string(i/10 mod 10), /rem)+$
    strcompress(string(i mod 10), /rem)
      4: return,strcompress(string(i/1000), /rem) +$
    strcompress(string((i - 1000*(i/1000))/100), /rem)+$
    strcompress(string(i/10 mod 10), /rem)+$
    strcompress(string(i mod 10), /rem)
  endcase
end

