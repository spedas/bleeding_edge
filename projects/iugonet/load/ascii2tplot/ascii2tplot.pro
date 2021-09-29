;+
; PROCEDURE: ascii2tplot
;   ascii2tplot, files, files=files2, format_type=format_type, tformat=tformat, $
;       tvar_column=tvar_column, tvarnames=tvarnames, $
;       delimiter=delimiter, data_start=data_start, comment_symbol=comment_symbol, $
;       v_column=v_column, vvec=vvec, $
;       time_column=time_column, input_time=input_time
;
; PURPOSE:
;   Loads data from ascii format files.
;
; KEYWORDS:
;   files : Ascii data files which you want to load.
;   format_type: 0 or 1 or 2. It specifies the function used to read the ascii 
;       files, i.e., 0:ascii2tplot_xy, 1:ascii2tplot_xyv_1, 2:ascii2tplot_xyv_2.
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
;   v_column : A scalar that specifies the number of column of vdata, where
;       vdata[1:nx,1:nv] is used to create tplot variations by the command as follows;
;       store_data, tvarnames, data={x:xdata, y:ydata, v:vdata}.
;       xdata[1:nx] is made from date&time and ytada[1:nx,1:nv] is identified 
;       by tvar_column.
;   vvec : A vector for vdata, where vdata[1:nv] is used to create tplot variations 
;       by the command as follows;
;       store_data, tvarnames, data={x:xdata, y:ydata, v:vdata}.
;       xdata[1:nx] is made from date&time and ytada[1:nx,1:nv] is identified 
;       by tvar_column.
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
;   ascii2tplot, files='stn20120301.txt', format_type=0, 
;        tformat='YYYY-MM-DD hh:mm:ss.fff', tvar_column=[1,2,3], $
;        tvarnames='mag_stn', delimiter=',', comment_symbol=';'
;
; Written by Y.-M. Tanaka, April 25, 2018 (ytanaka at nipr.ac.jp)
;-

pro ascii2tplot, files, files=files2, format_type=format_type, tformat=tformat, $
        tvar_column=tvar_column, tvarnames=tvarnames, $
        delimiter=delimiter, data_start=data_start, comment_symbol=comment_symbol, $
        v_column=v_column, vvec=vvec, $
        time_column=time_column, input_time=input_time

;===== Keyword check =====;
;----- default -----;
if keyword_set(files2) then files=files2
if ~keyword_set(format_type) then format_type=0
if ~keyword_set(tformat) then tformat='YYYY MM DD hh mm ss'
if ~keyword_set(delimiter) then delimiter=','
if ~keyword_set(data_start) then data_start=0
if ~keyword_set(comment_symbol) then comment_symbol=''
if ~keyword_set(v_column) then v_column=0
if ~keyword_set(tvarnames) then tvarnames='tplotvar1'

case format_type of
    0: ascii2tplot_xy, files, files=files2, tformat=tformat, $
        tvar_column=tvar_column, tvarnames=tvarnames, $
        delimiter=delimiter, data_start=data_start, comment_symbol=comment_symbol, $
        time_column=time_column, input_time=input_time
    1: ascii2tplot_xyv_1, files, files=files2, tformat=tformat, $
        tvar_column=tvar_column, tvarnames=tvarnames, v_column=v_column, $
        delimiter=delimiter, data_start=data_start, comment_symbol=comment_symbol, $
        time_column=time_column, input_time=input_time
    2: ascii2tplot_xyv_2, files, files=files2, tformat=tformat, $
        tvarnames=tvarnames, vvec=vvec, $
        delimiter=delimiter, data_start=data_start, comment_symbol=comment_symbol, $
        time_column=time_column, input_time=input_time
    else: print, 'Please enter a value between 0 and 2 for format_ype.'
endcase

end

