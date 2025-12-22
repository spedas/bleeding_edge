;+
;  FUNCTION:         SEARCH_FA_INDEX.PRO
;
;   PURPOSE:         Finds FAST summary plot files associated with a
;                    given timespan.  Timespan may be specified by
;                    orbit or a pair of dates.  This function searches
;                    the FAST index file using a quick algorithm.
;
;                    Returns an array of filenames.  If timespan is
;                    specified by orbit, array will contain one
;                    filename.  If specified by dates, array will
;                    contain all files with timespans that overlap the
;                    given timespan.
;
;                    Only the latest version of a file will be
;                    returned.  There should be no duplication.
;
;     NOTES:         Assumes index file is well organized.  Columns
;                    are of constant width.  Entries are sorted first
;                    by orbit number, then version number.
;
;                    Returns [''] if no associated files found.
;
;                    Function will need editing if filename field
;                    changes length.
;
;                    Uses environment variable CDF_INDEX_DIR.
;
; ARGUMENTS:
;
;        T1          Double float or string,  scalar or 2-element
;                    array. If scalar, this is the start time.  If
;                    this is a 2-element array, start time is T1[0],
;                    and end time is T1[1].  Ignored if ORBIT set.
;        T2          If T1 is scalar, this is the end time.  Ignored
;                    if ORBIT set.
;
;  KEYWORDS:
;
;     ORBIT          The orbit requested.  If unset, must supply 
;                    timespan arguments.
;
;     MASTERFILE     Name of a masterfile that contains times and associated 
;                    filenames.  Overrides EES,IES,TMS,ACF,DCF keywords.
;
;     EES,IES,TMS,   Set one of these keywords to identify the data
;     ACF,DCF        quantity, and thus the index file. Must set one
;                    of these or MASTERFILE. 
;
;     EXISTS         Only files that actually exist will be returned.
;
;
;
;  EXAMPLES:         files = search_fa_index(orbit=5000, /ies, /exists)
;                    files = search_fa_index(t1, t2, master='/path/index_file')
;
;
;   CREATED:         98/7/31 By J. Rauchleiba
;-


;-------------------------------------------------------------------
; SUBPROCEDURE:      parse_indexfile_rec
;
; PURPOSE:           Separates index file record into components.
;
pro parse_indexfile_rec, record, start, finish, file, orbit, version

;; Replace newline at end of record with null char

null = byte('')
n_bytes = n_elements(record)
record(n_bytes - 1) = null

;; Parse fields

fields = str_sep(strcompress(record), ' ')
if n_elements(fields) NE 3 then message, 'Bad index file entry: ' + string(record)
start = str_to_time(fields(0))
finish = str_to_time(fields(1))
file = fields(2)

;; Parse filename

path_sep = str_sep(file, '/')
basename = path_sep(n_elements(path_sep) - 1)
orbit = long(strmid(basename, 10, 5))
version = fix(strmid(basename, 17, 2))

return
end
;-------------------------------------------------------------------

;-------------------------------------------------------------------
; SUBFUNCTION :      interval_overlap
;
; PURPOSE:           Returns amount by which two intervals overlap.
; ARGUMENTS:         a, b, c, d: start1, end1, start2, end2
;
function interval_overlap, a, b, c, d
return, (d-c) - ((d-b)>0) - ((a-c)>0) + ((a-d)>0) + ((c-b)>0)
end
;-------------------------------------------------------------------


function search_fa_index, t1, t2, $
               ORBIT=orbit, $
               MASTERFILE=cdf_index_file, $
               EES=ees, IES=ies, TMS=tms, ACF=acf, DCF=dcf, $
               VERBOSE=verbose, $
               EXISTS=exists

;; Handle Arguments

if NOT keyword_set(verbose) then verbose=0
if verbose then help, t1, t2, orbit
;; Determine if using orbit or timespan specs
if NOT keyword_set(orbit) then begin
    if n_elements(t1) EQ 1 then begin
        if NOT keyword_set(t2) then message, 'Must set both T1 and T2'
        if data_type(t1) EQ 7 then start=str_to_time(t1) else start=t1
        if data_type(t2) EQ 7 then finish=str_to_time(t2) else finish=t2
    endif else if n_elements(t1) EQ 2 then begin
        if keyword_set(t2) then message, 'Ambiguous timespan specification.'
        if data_type(t1) EQ 7 then begin
            start = str_to_time(t1[0])
            finish = str_to_time(t1[1])
        endif else begin
            start = t1[0]
            finish = t1[1]
        endelse
    endif else message, 'T1 has incorrect number of elements'
endif

;; Must set either MASTERFILE or QTY to indentify index file

case 1 of
    keyword_set(cdf_index_file) : ;Do nothing
    keyword_set(ees) : qty = 'ees'
    keyword_set(ies) : qty = 'ies'
    keyword_set(tms) : qty = 'tms'
    keyword_set(acf) : qty = 'acf'
    keyword_set(dcf) : qty = 'dcf'
    ELSE: message, 'Must set one of MASTERFILE, EES, IES, TMS, ACF, DCF'
endcase
if NOT keyword_set(cdf_index_file) then begin
    cdf_index_dir = getenv('CDF_INDEX_DIR')
    cdf_index_file = cdf_index_dir + '/fa_k0_' + qty + '_files'
endif

openr, masterfile, /get_lun, cdf_index_file

;; Get master index file information

point_lun, masterfile, 0        ; Rewind
first_line = ''                 ; Initialize
readf, masterfile, first_line   ; Read first line
masterfile_info = fstat(masterfile)
record_len = masterfile_info.cur_ptr
n_records = masterfile_info.size/record_len
if (masterfile_info.size MOD record_len) NE 0 $
  then message, 'Irregular length records in index file: ' + cdf_index_file

;; Associate an array structure with the index file.
;; Entries are one per line, record_len bytes each.

assoc_var = assoc(masterfile, bytarr(record_len))

;; Get total timespan and orbit range of index file

parse_indexfile_rec, assoc_var[0], first_rec_start, first_rec_end, $
  dummy_string, first_orbit, first_ver
parse_indexfile_rec, assoc_var[n_records-1], last_rec_start, last_rec_end, $
  dummy_string, last_orbit, dummy_ver
time_per_entry = (last_rec_end - first_rec_start)/double(n_records)
;;orbits_per_entry = float(last_orbit - first_orbit)/float(n_records)
orbits_per_entry = 1
if verbose then begin
    print, 'Time per entry: ', time_per_entry
    print, 'Orbits per entry: ', orbits_per_entry
endif

;; Check for time out of range

if keyword_set(orbit) then begin
    if orbit LT first_orbit OR orbit GT last_orbit then begin
        message, 'Requested orbit out of index file range', /cont
        free_lun, masterfile
        return, ['']
    endif
endif else begin
    if start LT first_rec_start OR start GT last_rec_end then begin
        message, 'Requested timespan out of index file range', /cont
        free_lun, master
        return, ['']
    endif
endelse

;; Collect desired entries

if keyword_set(orbit) then begin
    ;; Find record with requested orbit
    orbit_diff = orbit - first_orbit
    current_rec = 0L
    rec_file = ''
    rec_orb = first_orbit
    rec_ver = first_ver
    iter = 0
    while orbit_diff NE 0 do begin
        if verbose then help, orbit_diff
        iter = iter + 1
        if iter GT 20 then begin
            message, 'Could not converge on index file entry for orbit: ' + strtrim(orbit, 2), /cont
            free_lun, masterfile
            return, ['']
        endif
        current_rec = 0 > (current_rec + orbit_diff) < (n_records - 1)
        parse_indexfile_rec, assoc_var[current_rec], rec_start, rec_end, $
          rec_file, rec_orb, rec_ver
        if verbose then print, 'Record orbit: ', rec_orb
        orbit_diff = orbit - rec_orb
    endwhile
    ;; Search for higher version of file with same orbit
    ;; Assign name of file to file_list array
    prev_rec_ver = 0
    while rec_orb EQ orbit do begin
        if rec_ver GT prev_rec_ver then begin
            if verbose then print, 'Selected file: ' + rec_file
            if keyword_set(exists) then begin
                if (findfile(rec_file))(0) $
                  then file_list = [rec_file] $
                else message, 'Missing file: ' + rec_file, /cont
            endif else file_list = [rec_file]
            prev_rec_ver = rec_ver
            current_rec = current_rec + 1
            if current_rec LE (n_records -1 ) then begin
                parse_indexfile_rec, assoc_var[current_rec],rec_start,rec_end,$
                  rec_file, rec_orb, rec_ver
            endif else rec_orb=-1
        endif
    endwhile
    if NOT keyword_set(file_list) then file_list = ['']
endif else begin
    ;; Find all overlapping files
    ;; First find an entry with end time just before requested start
    tolerance = 86400L
    current_rec = 0L
    rec_end = first_rec_end
    rec_file = ''
    diff = start - rec_end
    iter = 0
    while abs(diff) GT tolerance OR rec_end GT start do begin
        if verbose then print, 'Difference: ', diff
        iter = iter + 1
        if iter GT 20 then begin
            message, 'Could not converge on index file entry', /cont
            free_lun, masterfile
            return, ['']
        endif
        jump_recs = round(diff/time_per_entry)
        ;; Jump at least one record
        if jump_recs EQ 0 then jump_recs = round(diff/abs(diff))
        if verbose then print, 'Jump Records: ', jump_recs
        ;; Make jump, stay within limits
        previous_rec = current_rec
        current_rec = 0 > (current_rec + jump_recs) < (n_records - 1)
        if verbose then print, 'Current Record: ', current_rec
        if current_rec EQ previous_rec then message, 'Infinite loop'
        parse_indexfile_rec, assoc_var[current_rec], rec_start, rec_end, $
          rec_file, rec_orb, rec_ver
        diff = start - rec_end
    endwhile
    if verbose then print, 'Near file: ' + rec_file
    ;; Now find first entry with end BEYOND requested start
    repeat begin
        current_rec = current_rec + 1
        parse_indexfile_rec, assoc_var[current_rec], rec_start, rec_end, $
          rec_file, rec_orb, rec_ver
    endrep until rec_end GT start
    ;; Collect highest versions of all overlapping files
    ;; Loop through all files that overlap requested timespan
    ;; Assign filenames to file_list array
    prev_rec_orb = 0
    prev_rec_ver = 0
    rec_overlap = long(interval_overlap(start, finish, rec_start, rec_end))
    while rec_overlap NE 0 do begin
        ;; Assign or append filename to array
        if NOT keyword_set(file_list) then begin
            if verbose then print, 'Appending: ' + rec_file
            ;; Check for file existence before assigning
            if keyword_set(exists) then begin
                if (findfile(rec_file))(0) $
                  then file_list = [rec_file] $
                else message, 'Missing file: ' + rec_file, /cont
            endif else file_list = [rec_file]
            list_index = 0
        endif else begin
            ;; If orbit increments, append new array element
            ;; If only version increments, re-assign this element
            if rec_orb GT prev_rec_orb then begin
                if verbose then print, 'Appending: ' + rec_file
                ;; Check for file existence before assigning
                if keyword_set(exists) then begin
                    if (findfile(rec_file))(0) then begin
                        file_list = [file_list, rec_file]
                        list_index = list_index + 1
                    endif else message, 'Missing file: ' + rec_file, /cont
                endif else begin
                    file_list = [file_list, rec_file]
                    list_index = list_index + 1
                endelse
            endif else if rec_ver GT prev_rec_ver then begin
                if verbose then print, 'Replacing: ' + rec_file
                ;; Check for file existence before assigning
                if keyword_set(exists) then begin
                    if (findfile(rec_file))(0) $
                      then file_list[list_index] = rec_file $
                    else message, 'Missing file: ' + rec_file, /cont
                endif else file_list[list_index] = rec_file
            endif else begin
                message, 'Index file record ' + strtrim(current_rec,2) + $
                  ' incremented bizarrely'
            endelse
        endelse
        prev_rec_orb = rec_orb
        prev_rec_ver = rec_ver
        current_rec = current_rec + 1
        if current_rec LE (n_records -1) then begin
            parse_indexfile_rec, assoc_var[current_rec], rec_start, rec_end, $
              rec_file, rec_orb, rec_ver
            rec_overlap = long(interval_overlap(start, finish, rec_start, rec_end))
        endif else rec_overlap = 0
    endwhile
    if NOT keyword_set(file_list) then file_list = ['']
endelse
free_lun, masterfile

return, file_list
end
