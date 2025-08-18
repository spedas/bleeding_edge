; This function returns an array of  file names for all files of a
; given observation type, for a given time range
; this is a simple program that doesn't check the Internet for
; new files. It just looks in a local directory.

; NOTE: this function is currently aimed at, and optimized for, data
; from the EMUS instrument. It may need to be updated/tweaked for
; accessing data from, for example, EMIRS

; RETURNS: a structure with the following tags:
;   FILES: array of filenames the full within the specified time range
;   TIMES: string array of start times
;   UNIX_TIMES: array of start times in seconds after January 1, 1970
;   FILE_INDICES: a 3xN array of integers representing the
;   indices within the returned array of filenames corresponding to
;   image sets within each observation sequence, e.g. the three swaths
;   across the disc comprising on OS2 observation sequence. This is
;   useful for grouping the files into image sets.


; KEYWORDS:
;   INSTRUMENT: which of the three EMM instruments
;                'emu': Emirates Mars Ultraviolet Spectrometer
;                'emi': Emirates Mars Infrared Spectrometer
;                'exi': Emirates Exploration Imager
;
;   LEVEL:     Data level, e.g. for EMUS:
;                'l1' : raw photon counts
;                'l2a': calibrated brightness fn. of wavelength
;                'l2b': Same as L2a but also including brightnesses
;                for specific emissions resulting from multiple linear
;                regression fits of the spectrum. This is DEFAULT
;
;   MODE:      Observation mode. E.g. for EMUS Here are the options. 
;              See paper by Holsclaw et al. [2021], figure 3 for details/pictures
;  os1: disk scans, mostly on the dayside (images)
;  os2: disk and inner Corona scans (images)
;  osr: "ride along" single-swath disk scans (images)
;  os3: asterisk-shaped scans of the whole Corona
;  os4: 'strafes' along the sun line

;   LOCAL_PATH:  Directory where files are kept. Note this directory
;   must have the same structure as the file source kept on
;   AWS:
;   https://mdhkq4bfae.execute-api.eu-west-1.amazonaws.com/prod/science-files-metadata?".  
;   The default will work fine for people working on the UC Berkeley SSL network

; the purpose of this routine is to take the full name of the file
; including the directory structure, and return only the filename,
; after the last forward slash

Function filename_only, full_filename
  ss = strsplit (full_filename, '/',/extract)
  if n_elements (full_filename) eq 1 then begin
      n_sub_strings = n_elements (ss)
      return, ss[n_sub_strings -1]
  endif else begin
      output_string =' '        ; give falsefirst element
      for J = 0, n_elements (full_filename)-1 do begin
          n_sub_strings = n_elements(ss [J,*])
          output_string = [output_string,ss[J,n_sub_strings-1]]
      endfor
      output_string = output_string [1:*] ; remove false first element
      return, output_string
  endelse
end



function get_file_name_string,  path,  identifier =  identifier,  $
                                full_name =  full_name, $
                                subdirectory = subdirectory
  if not keyword_set (identifier) then identifier =  ' '
  file_delete,'./temp_list_file.txt',/allow_nonexistent
;  rmst =  'rm '+
 
 ; spawn,  rmst
  if not keyword_set (subdirectory) then list_string = 'ls ' +$
     path + identifier + ' > '+ './temp_list_file.txt' else list_string = $
     'ls -R ' +$
     path + identifier + ' > '+ './temp_list_file.txt'
  spawn,  list_string
  close,/all
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
    ;print, kal
    ;print, redflag
    ;names_split =  strsplit (kal, '/', /extract,  count =  count)
   ; if not keyword_set (full_name) then names [i-1] =  $
    ;  names_split [count -1] else 
    names[i-1] = kal
 endwhile
  free_lun, Unit
  names = names[0:i-1]
  names = filename_only (names)
; default is to shorten the string to exclude the path
 
    
  close, /all
  file_delete,'./temp_list_file.txt',/allow_nonexistent
;  rmst =  'rm ' +'./temp_list_file.txt'

 ; spawn,  rmst
  if keyword_set (full_name) then return,  path + $
    names [0:i -1] else return,  names [0: i -1]
end


function numbered_filestring, i, digits = digits

  ii = round (i)
  if not keyword_set (digits) then digits = 4
  ni = n_elements (i)
  output = strarr (ni) 
  
  if digits eq 1 then begin
     for k = 0, ni-1 do output [k] =  strcompress(string(ii[k] mod 10), /rem)
  endif else if digits eq 2 then begin
     for k = 0, ni-1 do output [k] = strcompress(string(ii[k]/10 mod 10), /rem)+$
        strcompress(string(ii[k] mod 10), /rem)
  endif else if digits eq 3 then begin
     for k = 0, ni-1 do output [k] = $
        strcompress(string((ii[k] - 1000*(ii[k]/1000))/100), /rem)+$
        strcompress(string(ii[k]/10 mod 10), /rem)+$
        strcompress(string(ii[k] mod 10), /rem)
  endif else if digits eq 4 then begin
     for k = 0, ni-1 do output [k] = strcompress(string(ii[k]/1000), /rem) +$
        strcompress(string((ii[k] - 1000*(ii[k]/1000))/100), /rem)+$
        strcompress(string(ii[k]/10 mod 10), /rem)+$
        strcompress(string(ii[k] mod 10), /rem)
  endif else begin 
     message, 'digits keyword must be specified and must be between 1 and 4'
  endelse
  return, output
end


function emm_file_retrieve, time_range, level = level, mode = mode, $
                            local_path = local_path, $
                            instrument = instrument

; assume you always want the latest file
  latest = 'true'

; Assume the user wants EMUS data (as opposed to EMIRS or EXI)
  if not keyword_set (instrument) then instrument = 'emu'

; unless specified, assume you want reconstructed ephemeris, not
; predicted ephemeris
  ;if not keyword_set (pred_rec) then pred_rec= 'r'

; mostly working with Level 2b files
  if not keyword_set (level) then level = 'l2b'

  if not keyword_set (mode) then message, 'need to specify mode'

; make sure the start and end dates are full days at least 2 hours apart
  start_time = time_double (time_range [0])
  end_time = Max ([time_double (time_range [1]), start_time +3600])
  ;end_date = time_double (time_range [1])

  Start_date = time_string (start_time, tformat = 'YYYY-MM-DD-hh')
  end_date = time_string (end_time, tformat = 'YYYY-MM-DD-hh')

; here's the location of the files on the UC Berkeley Space
; Sciences Lab network. Change if you want to use your local disk.
  if not keyword_set (local_path) then local_path = $
     '/disks/hope/data/emm/data/'
  
; need to figure out how many directories to check
  start_split = strsplit (start_date, '-',/extract)
  Start_year = round (float (start_split[0]))
  start_month = round (float (start_split[1]))
  start_day = round (float (start_split[2]))
  Start_hour = round (float (start_split[3]))
  
  end_split = strsplit (end_date, '-',/extract)
  End_year = round (float (end_split[0]))
  end_month = round (float (end_split[1]))
  end_day = round (float (end_split[2]))
  End_hour = round (float (end_split[3]))
  
; if everything is in the same year
  if start_year eq end_year then begin
     nd =  1+end_month - start_month
     Year_strings = Replicate (start_split [0],nd)
     month_strings =  numbered_filestring (start_month + indgen (nd), digits = 2)
     
  endif else begin 
     ny = 1+end_year - start_year;# years
     nm = intarr (ny);# months
     nm[0] = 13 - start_month;# months year 1
     year_strings = replicate (start_split [0],nm[0])
     month_strings = numbered_filestring (start_month + indgen (nm [0]), $
                                          digits = 2)
     for k = 1, ny-1 do begin        
        if k lt ny -1 then begin
           nm [k] = 12 
           year_strings = [year_strings, replicate (roundst (start_year + k), 12)]
           month_strings = [month_strings, $
                            numbered_filestring (1+indgen (12), digits = 2)]
        endif else begin
           nm [k] = end_month
           year_strings = [year_strings,replicate (end_split [0], nm[k])]
           month_strings = [month_strings, $
                            numbered_filestring (1+indgen (nm[k]), digits = 2)]
        endelse
        
     endfor
     nd = total (nm)
                      
  endelse

; Now go through each directory
;emm_emu_l2b_20220331t212107_0191_os2_sw1of3_r_v01-04.fits.gz

  big_files = ''
  big_date_string = ''
  big_year_string = ''
  big_month_string = ''
  big_directory = ''

  big_swath_number = 0b
  big_swaths_per_set = 0b

  for i = 0, nd-1 do begin
     directory = Local_path+instrument + '/' + level + '/' + $
                 mode + '/' + year_strings [i] + '/' + $
                 month_strings [i]+ '/'
     
     files = $
        get_file_name_string (directory, identifier = 'emm_'+ instrument + '_' + $
                              level + '_*.fits.gz')
     if size (files,/type) ne 7 then continue
     nf = n_elements(files)

     
  
;now find the year and month directory string
     year_string = strarr (nf)
     month_string = year_string
     date_string = year_string
     swath_string = year_string
    version = bytarr (nf)
     revision = bytarr (nf)
     swath_number = bytarr (nf)
;array to keep track of stale files (i.e. old revisions)
     stale = bytarr(nf)
     swaths_per_set = swath_number
     set_count = 0L
; temporary variable
     this_set = indgen (3)

     for K = 0,nf-1 do begin 
        temp = strsplit(directory, '/',/Extract ) 
        year_string [k] = temp [-2] 
        month_string [k] = temp [-1] 
        temp = strsplit (files [k], '_',/extract)
        date_string[k] = temp [3]
        swath_string [k] = temp [6]
; these two types of OS always have just one swath
        if mode eq 'osr' or mode eq 'EMU035' or mode eq 'EMU042' or mode eq 'osp' then begin
           swath_number [k] = 1 
           swaths_per_set [k] = 1
; other types of OS have more than one swath
        endif else begin 
           swath_number [k] = round (float (strmid (swath_string [k], 2, 1)))
           swaths_per_set[k] = round (float (strmid (swath_string [k], 5, 1)))
        endElse
   
        trunk = Strsplit (temp [8], '.',/Extract)
        version_revision = trunk [0]
        version [k] = round (float (strmid (version_revision, 1, 2)))
        revision [k] = round (float (strmid (version_revision,4, 2)))

        ;Print, k, swath_number [k], swaths_per_set [k], version [k], revision [k]
; check to see if the date string is equal to any other date strings.
; If so, check to see which one has the highest version and revision
; numbers, as long as the file exists.
        for j = 0, k-1 do begin
           if date_string[k] eq date_string [j] then begin
              if version [k] gt version [j] then begin
                 date_string [j] = '19800101t000000'
              endif else if version [k] lt version [j] then begin
                 date_string [k] = '19800101t000000'
              endif else if version [k] eq version [j] then begin
                 if revision [k] gt revision [j] then begin
                    date_string [j] = '19800101t000000'
                 endif else if revision [k] le revision [j] then begin
                    date_string [k] = '19800101t000000'
                    
                 endif
              endif
           endif
        endfor
        
     endfor
     

     big_date_string = [big_date_string, date_string]
     big_month_string = [big_month_string, month_string]
     big_directory = [big_directory, replicate (directory, nf)]
     big_year_string = [big_year_string, year_string]
     big_files = [big_files, files]
     big_swath_number = [big_swath_number, swath_number]
     big_swaths_per_set = [big_swaths_per_set, swaths_per_set]
     
  endfor

; if there are no valid files
  if n_elements (big_date_string) eq 1 then return, 0
; remove the first element
  big_date_string = big_date_string [1:*]
  big_month_string = big_month_string [1:*]
  big_year_string = big_year_string [1:*]
  big_directory = big_directory [1:*]
  big_swath_number = big_swath_number [1:*]
  big_swaths_per_set = big_swaths_per_set [1:*]
  big_files = big_files [1:*]

; now get the right order
  UNIX_time = round (time_double (big_date_string, tformat = 'YYYYMMDDthhmmss'))
  good = where (UNIX_time gt 1e9 and UNIX_time gt start_time and $
                UNIX_time lt end_time)
  
  if good [0] eq -1 then return, 0
  order_good = sort (UNIX_time[Good])
  order = good [order_good]

  good_files = big_files[order]

  good_times = big_date_string [order]; strings
  good_UNIX_times = UNIX_time [order]; seconds since 1970
  good_years = big_year_string [order]
  good_months = big_month_string [order]
  good_directory = big_directory [order]
  
; now go through the files in order and set the file indices  
  ng = n_elements (good_files)
  File_indices = [-1, -1, -1]
  this_set = [-1, -1, -1]
  
  for K = 0, ng-1 do begin & $
     print,good_files [k]& $
     this_set [big_swath_number [order[k]] -1] = k& $
     if big_swath_number [order [k]] eq big_swaths_per_set [order [k]] then begin& $
        set_count++& $
        file_indices = [[file_indices], [this_set]]& $
        
        print, 'set complete: ', this_set& $
        this_set= [-1, -1, -1]& $
      
     endif& $
  endfor

;go through the file list and keep only those with
  ;print, file_indices
; chop off the first row because it's just -1s
  if n_elements (file_indices) eq 3 then return, 0
  file_indices = file_indices [*, 1:*]
  
  output = {directory: good_directory,files: good_files, $
            Full_files: good_directory + good_files,times: good_times, $
            UNIX_times: good_UNIX_times, $
            file_indices: file_indices}
  return, output

end

