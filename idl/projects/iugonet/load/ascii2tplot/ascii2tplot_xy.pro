;+
; PROCEDURE: ascii2tplot_xy
;   ascii2tplot_xy, files, files=files2, tformat=tformat, delimiter=delimiter, $
;        data_start=data_start, comment_symbol=comment_symbol, tvar_column=tvar_column, $
;        tvarnames=tvarnames 
;
; PURPOSE:
;   Loads data from ascii format files.
;
; KEYWORDS:
;   files : Ascii data files which you want to load.
;   tformat : Format string for date&time such as "YYYY-MM-DD/hh:mm:ss"
;   tvar_column : A scalar or a vector that identifies the column number for output 
;       tplot variables. The number starts from 0 except for the columns for 
;       date&time. (e.g., tvar_column=0 or tvar_column=[0, 1, 2])
;   tvarnames : A string or string array for output tplot variable names.
;       If the number of elements of tvar_column is greater than 1, tvarnames 
;       should have the same number of elememnts or only one element.
;       (e.g., tvarnames='tvar0' or tvarnames=['tvar0','tvar1','tvar2'])
;   delimiter : A scalar string that identifies the end of a field. 
;       One or more single characters are allowed. (e.g., deliminator=', ;')
;   data_start : Number of header lines you want to skip.
;       (e.g., data_start=10)
;   comment_symbol : A string that identifies the character used to delineate 
;       comments.
;   time_column : Optional. If this keyword is set, "tformat" is not used.
;       A vector of 6 melements that shows the existence of date&time data,
;       (year, month, day, hour, minute, second) in the ascii file. For example, 
;       if the data file includes the columns for [hour minute second] only, 
;       then time_column = [0, 0, 0, 1, 1, 1].
;   input_time : Need to set this keyword when the time_column is set.
;       For example, if the data file includes the columns for [hour minute second] 
;       only, then you need to set [year, month day] as follows; 
;       input_time = [2017, 3, 1, 0, 0, 0].       
;
; EXAMPLE:
;   ascii2tplot_xy, files='stn20120301.txt', tformat='YYYY-MM-DD hh:mm:ss.fff', $
;        tvar_column=[1,2,3], tvarnames='mag_stn', $
;        delimiter=',', comment_symbol=';', 
;
; Written by Y.-M. Tanaka, April 25, 2018 (ytanaka at nipr.ac.jp)
;-

pro ascii2tplot_xy, files, files=files2, tformat=tformat, $
        tvar_column=tvar_column, tvarnames=tvarnames, $
        delimiter=delimiter, data_start=data_start, comment_symbol=comment_symbol, $
        time_column=time_column, input_time=input_time

;===== Keyword check =====;
;----- default -----;
if keyword_set(files2) then files=files2
if ~keyword_set(tformat) then tformat='YYYY MM DD hh mm ss'
if ~keyword_set(delimiter) then delimiter=','
if ~keyword_set(data_start) then data_start=0
if ~keyword_set(comment_symbol) then comment_symbol=''
if ~keyword_set(tvarnames) then tvarnames='tplotvar1'

;----- Check input argument -----;
no_use_tformat=0
if keyword_set(time_column) then begin
    if n_elements(time_column) ne 6 then begin
        print, 'Number of elements of time_column must be 6.'
        return
    endif
    if time_column[0]*time_column[1]*time_column[2]*$
        time_column[3]*time_column[4]*time_column[5] eq 0 then begin
        if ~keyword_set(input_time) then begin
            print, '"input_time" is needed if any elements of time_column are zero.'
            return
        endif
    endif
    no_use_tformat=1
    ntimecol=fix(total(time_column gt 0))
endif

tvarnames = strsplit(tvarnames, /extract)
tdiff=0

xvec=''
yvec=''
for fi=0,n_elements(files)-1 do begin
    if file_test(files[fi]) eq 0 then begin
        dprint,dlevel=1,verbose=verbose,'File not found: "'+files[fi]+'"'
        continue
    endif

    xvectmp=''
    yvectmp=''
    ;----- Read each file -----;
    openr, lun, files[fi], /get_lun
    ;----- Skip Header -----;
    if data_start gt 0 then begin
        for i=0, data_start-1 do begin
            line=''
            readf, lun, line
        endfor
    endif

    while ~eof(lun) do begin
        line=''
        readf, lun, line
        if (strlen(comment_symbol) gt 0) and $
           (strmid(line, 0, strlen(comment_symbol)) eq comment_symbol) then begin
            print, line
            continue
        endif
        if no_use_tformat eq 1 then begin
            dat=double(strsplit(line, delimiter, /extract))
            tim=time_struct('')
            itnow=0
            if time_column[0] eq 0 then begin 
                yyyy=input_time[0]
            endif else begin
                yyyy=fix(dat[itnow])
                itnow++
            endelse
            if yyyy lt 100 then begin
                if yyyy lt 70 then yyyy=yyyy+2000 else yyyy=yyyy+1900
            endif
            if time_column[1] eq 0 then begin
                mo=input_time[1]
            endif else begin
                mo=dat[itnow]
                itnow++
            endelse
            if time_column[2] eq 0 then begin
                dd=input_time[2]
            endif else begin
                dd=dat[itnow]
                itnow++
            endelse
            if time_column[3] eq 0 then begin
                hh=input_time[3]
            endif else begin
                hh=fix(dat[itnow])
                itnow++
            endelse
            if time_column[4] eq 0 then begin
                mn=input_time[4]
            endif else begin
                mn=dat[itnow]
                itnow++
            endelse
            if time_column[5] eq 0 then begin
                ss=input_time[5]
            endif else begin
                ss=dat[itnow]
            endelse
            tim.year=yyyy & tim.month=mo & tim.date=dd
            tim.hour=hh & tim.min=mn & tim.sec=ss
            append_array, xvectmp, time_double(tim)
            append_array, yvectmp, transpose(dat[ntimecol:n_elements(dat)-1])
        endif else begin
            tline=strmid(line, 0, strlen(tformat))
            tim=time_parse(tline, tformat=tformat, tdiff=tdiff)
            dline=strmid(line, strlen(tformat), strlen(line)-strlen(tformat))
            dat=double(strsplit(dline, delimiter, /extract))
            append_array, xvectmp, time_double(tim)
            append_array, yvectmp, transpose(dat)
        endelse
    endwhile

    free_lun, lun

    append_array, xvec, xvectmp
    append_array, yvec, yvectmp
endfor

if xvec[0] eq '' then return

if ~keyword_set(tvar_column) then begin
    tvar_column=indgen(n_elements(yvec[0,*]))
endif

nvar=size(tvarnames, /n_elements)
if nvar eq 1 then begin
    tvarname=tvarnames[0]
    tvarname=tvarname[0]
    store_data, tvarname, data={x:xvec, y:yvec[*, tvar_column]}
endif else begin    
    for ivar=0, nvar-1 do begin
        tvarname=tvarnames[ivar]
        tvarname=tvarname[0]
        store_data, tvarname, data={x:xvec, y:yvec[*, tvar_column[ivar]]}
    endfor
endelse

end
