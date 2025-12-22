;+
; PROCEDURE:   gts_concatenate.pro
;
; PURPOSE:     Restores IDL "save" files containing FAST trending data
;              and concatenates the contents.
;
; ARGUMENTS:   (None)
;
; KEYWORDS:    DATA_DIRECTORY      The directory containing the save
;                                  files. (scalar or string array)
;              QUANTITIES          String array of variable names
;                                  contained in the save files.
;              PREFIX              Initial string in filenames. (default=`*')
;              YEAR_RE             Regular expression for year field
;                                  in filename.
;              DOY1_RE             RE for start DOY in file name.
;              DOY2_RE             RE for ending DOY in filename.
;
; BY:          J.Rauchleiba        1998/8/21
;-

pro gts_concatenate, $
       DATA_DIRECTORY=datadir, $
       QUANTITIES=qtylist, $
       PREFIX=prefix, $
       YEAR_RE=yrre, $
       DOY1_RE=d1re, $
       DOY2_RE=d2re

if NOT keyword_set(qtylist) then message, 'Must set QUANTITIES'
n_qty = n_elements(qtylist)

;; Regular expression used to find files

if NOT keyword_set(prefix) then prefix='*'
if NOT keyword_set(yrre) then yrre='*'
if NOT keyword_set(d1re) then d1re='*'
if NOT keyword_set(d2re) then d2re='*'

;; Get the array of data files

n_datafiles = 0
for d=0, (n_elements(datadir) - 1) do begin
    ;; Construct the data file Regular Expression
    datafile_RE = datadir[d] + '/' + prefix + '_' + yrre + '_' + d1re + '_' + d2re + '.dat'
    ;; Find the files
    found_files = findfile(datafile_RE, count=n_found)
    if ( n_found GT 0 ) then $
      if ( n_elements(datafiles) EQ 0) then datafiles = found_files else datafiles = [datafiles, found_files]
    n_datafiles = n_datafiles + n_found
endfor
if n_datafiles LT 1 then message, 'No data files found.'

;; Form an array of base names only for sorting

base_names = [ (reverse(str_sep(datafiles[0], '/')))[0] ]
for b=1, (n_datafiles - 1) do begin
    base_names = [base_names, (reverse(str_sep(datafiles[b], '/')))[0] ]
endfor
datafiles = datafiles(sort(base_names))

;; Process each data file
;; Initialize loop variables

prev_year = 0
prev_firstday = 0
prev_lastday = 0

;; Loop through each data file

already_inited = intarr(n_qty) ;; tells to assign or append data
for f=0, n_datafiles - 1 do begin
    ;; Parse filename
    
    data_file = datafiles(f)
    base_name = (reverse(str_sep(data_file, '/')))[0]
    name_fields = str_sep(base_name, '_')
    year = fix(name_fields(1))
    firstday = fix(name_fields(2))
    lastday = fix( strmid(name_fields(3),0,3) )
    
    ;; Check for non-monotonic loading
    
    if year GT prev_year then begin
        prev_firstday = 0
        prev_lastday = 0
    endif
    if year LT prev_year OR firstday LE prev_lastday $
      then message, 'Data not loaded monotonically. Filename: ' + data_file
    if lastday LT firstday then message, 'Corrupted filename: ' + data_file
    
    ;; Load all data quantities in this file
    
    print, 'Loading data file: ' + data_file
    restore, /relaxed, data_file
    
    ;; Append data for each quantity in this file
    
    for t=0, n_qty-1 do begin
        valid = 0
        success = execute('valid = ' + qtylist(t) + '.valid')
        if success NE 1 $
          then message, 'Unable to validate data: '+ qtylist(t)
        ;; Append only if data is valid
        if valid NE 1 then begin
            message, 'Data invalid: ' + qtylist(t) + $
                  '   Data file: ' + data_file, /continue
        endif else begin
            struc_name = 'store_' + qtylist(t)
            ;; Substitute regular assignments for appends if first
            if NOT already_inited(t) then begin
                time_append = 'x:[' + qtylist(t) + '.time]'
                data_append = 'y:[' + qtylist(t) + '.' + qtylist(t) + ']'
                already_inited(t) = 1
            endif else begin
                ;; True append
                time_append = 'x:['+struc_name+'.x,' + qtylist(t) + '.time]'
                data_append = 'y:['+struc_name+'.y,' + qtylist(t) + '.' + qtylist(t) + ']'
            endelse
            success = execute(struc_name + '={'+time_append+','+data_append+'}')
            if success NE 1 then message, $
              'Unsuccessful data append: ' + qtylist(t) + $
              '  Data file: ' + data_file, /continue
        endelse
    endfor
    
    ;; Update loop variables
    
    prev_year = year
    prev_firstday = firstday
    prev_lastday = lastday
    
endfor

;; Store the data into tplot structures

for t=0, n_qty-1 do begin
    struc_name = 'store_' + qtylist(t)
    success = execute('temporary = ' + struc_name)
    if success NE 1 $
      then message, 'Unable to assign '+struc_name+' to temporary.'
    print, 'Storing tplot structure: ' + qtylist(t)
    store_data, qtylist(t), data=temporary
endfor

;; Use period as plotting symbol

tplot_options, 'psym', 3


end
