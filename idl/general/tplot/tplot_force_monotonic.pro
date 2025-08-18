;+
; Procedure: tplot_force_monotonic
;
; Purpose:
;    This routine checks tplot variables for sample time (abscissa: data.x) monotonicity
;     and forces them so through removal or replacement of non-monotonic segments, if requested;
;     the corresponding elements of data.y and data.v are also repaired.
;    Indices of consecutively repeated header times and piece-wise monotonic segment "negative jumps"
;     are identified and used to determine monotonicity of tplot variables. If checking,
;     the routine will report cause of failures (i.e. negative jumps, repeats).  
;    Three repair methods are available: /forward, /reverse and /sort (see Keywords) 
;    
; Inputs:   [optional] tplot variable name(s) string/array or wild-card name string or tplot variable number(s); same as input for tnames()
;                    
; Keywords:
;           forward:      the recommended repair method, which keeps the older time elements of over-lapping time segments
;           reverse:      repair method which keeps the newer time elements over-lapping time segments
;           sort:         repair method which sorts time-lines chronologically, using bsort()
;           
;           keep_repeats: [optional] do not remove consecutively repeated header times
;           replace_NaN:  [optional] instead of removing 'bad' elements, replace them with NaN (only applied to data.y and data.v elements, data.x is not modified)
;           
;              
; Outputs:
;           If checking, PASS/FAIL console message per tplot variable, including cause of failures
;           If repairing, PASS/FAIL console message per tplot variable and repaired tplot variable(s) (via store_data) 
;              
; Examples:
;           tplot_force_monotonic                           ; check all tplot variables
;           tplot_force_monotonic,'*'                       ; check all tplot variables
;           tplot_force_monotonic,'var1'                    ; check tplot variable named var1
;           tplot_force_monotonic,['var1','var2']           ; check tplot variables named var1 and var2
;           tplot_force_monotonic,[6,7,9]                   ; check tplot variables 6, 7 and 9
;           tplot_force_monotonic,/forward                  ; repair all tplot variables using 'forward' method, discarding repeated sample times (recommended repair method)
;           tplot_force_monotonic,/reverse,/keep_repeats    ; repair all tplot variables using 'reverse' method, keeping repeated sample times
;           tplot_force_monotonic,/sort                     ; repair all tplot variables using 'sort' method, discarding consecutively repeated sample times
;           tplot_force_monotonic,'var?',/forward,/replace_nan  ; repair tplot variable(s) in var? using 'forward' method and replace bad elements with NaNs
;        
; Notes:
;     1. tplot variables repaired with the /replace_nan keyword will not pass a monotonicity check.
;     2. tplot variables repaired with the /keep_repeats keyword may not pass a monotonicity check.
;     3. A warning is issued if more than 10% of tplot variable elements are removed or replaced.
;      
; ToDo: nothing yet
;
; $LastChangedBy: egrimes $
; $LastChangedDate: 2016-04-25 12:07:51 -0700 (Mon, 25 Apr 2016) $
; $LastChangedRevision: 20911 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/tplot/tplot_force_monotonic.pro $
;-

function keep_overlap, i_keep, i_new, time_array, REVERSE=REVERSE, KEEP_REPEATS=KEEP_REPEATS
;;; returns the indices of overlapping time segments to keep
if keyword_set(reverse) then begin
  if keyword_set(KEEP_REPEATS) then begin i_keep_new = where( time_array[i_new] le min(time_array[i_keep]) ,c_new)
  endif else i_keep_new = where( time_array[i_new] lt min(time_array[i_keep]) ,c_new)
endif else begin
  if keyword_set(KEEP_REPEATS) then begin i_keep_new = where( time_array[i_new] ge max(time_array[i_keep]) ,c_new)
  endif else i_keep_new = where( time_array[i_new] gt max(time_array[i_keep]) ,c_new)
endelse

if c_new gt 0 then begin
  if keyword_set(reverse) then begin
    i_keep = [i_new[i_keep_new], i_keep]
  endif else i_keep = [i_keep, i_new[i_keep_new]]
endif

return, i_keep
end

function set_difference, set_a, set_b
;;; returns the elements present in set_a but not in set_b (if their intersection is not empty)
;;; returns -1 if intersection of set_a and set_b is empty
mm = minmax(set_a)
r = where((histogram(set_a, Min=mm[0], Max=mm[1]) ne 0) and (histogram(set_b, Min=mm[0], Max=mm[1]) eq 0))
diff = r + mm[0]
if n_elements(set_a) eq n_elements(diff) then begin
  return, -1
endif else return, diff
end

pro tplot_force_monotonic, tplot_vars, FORWARD=FORWARD, REVERSE=REVERSE, SORT=SORT, KEEP_REPEATS=KEEP_REPEATS, REPLACE_NAN=REPLACE_NAN

;;; Get and check tplot variable names/numbers
tplot_vars = tnames(tplot_vars)
if strlen(strjoin(tplot_vars)) eq 0 then begin
  dprint, 'Invalid tplot variable name(s) or number(s)'
  return
endif
max_var_len = 32

;;; Loop over requested tplot variables
for j=0L,n_elements(tplot_vars)-1L do begin
  tplot_var = tplot_vars[j]
  
  ; the following fixes a crash when the tplot variable name is the same length as max_var_len
  if strlen(tplot_var) ge max_var_len then max_var_len = strlen(tplot_var) + 1
  
  get_data,tplot_var,data=data,dlimits=dlimits,limits=limits
  
  ;;; Check if data is a structure
  if not is_struct(data) then begin
    dprint,' ',tplot_var,':'+strjoin(strarr(max_var_len-strlen(tplot_var))+' ')+'FAIL - not a valid tplot variable'
    continue
  endif
  time_array = data.x
  n_time_array = n_elements(time_array)
  ;;; Check if time array has only one element
  if (n_time_array eq 1) then begin
    dprint,tplot_var,':'+strjoin(strarr(max_var_len-strlen(tplot_var))+' ')+'PASS, variable has one time element'
    continue
  endif
  
  ;;; Identify consecutive repeats and boundaries of piece-wise monotonic segments "negative jumps"
  i_non_monotonic = where((time_array[1:n_time_array-1]-time_array[0:n_time_array-2]) lt 0d, c_non_monotonic) +1L
  i_repeat = where((time_array[1:n_time_array-1]-time_array[0:n_time_array-2]) eq 0d, c_repeat) +1L

  ;;; If time_array is monotonic (i.e. has no negative jumps) and has no repeats, then it PASSES
  if ((c_non_monotonic eq 0) and (c_repeat eq 0)) then begin 
    dprint,tplot_var,':'+strjoin(strarr(max_var_len-strlen(tplot_var))+' ')+'PASS'
    continue
  endif else begin
    
    ;;; case: tplot variable is non-monotonic
    if keyword_set(forward) or keyword_set(reverse) or keyword_set(SORT) then begin
      if c_non_monotonic eq 0 then GOTO, ONLY_REPEATS
      
      ;;; Keep forward portion of overlaps
      if keyword_set(forward) then begin
        if i_non_monotonic[0] eq 0 then begin
          i_keep = 0L
        endif else i_keep = lindgen(i_non_monotonic[0])
        for k = 0L, c_non_monotonic-2L do begin
            i_new = lindgen(i_non_monotonic[k+1] - i_non_monotonic[k]) + i_non_monotonic[k]
            i_keep = keep_overlap(i_keep,i_new,time_array,KEEP_REPEATS=KEEP_REPEATS)
        endfor
        i_new = lindgen(n_time_array - i_non_monotonic[k] ) + i_non_monotonic[k]
        i_keep = keep_overlap(i_keep,i_new,time_array,KEEP_REPEATS=KEEP_REPEATS)
      endif 
    
      ;;; Keep reverse portion of overlaps
      if keyword_set(reverse) then begin
        n = c_non_monotonic-1
        if i_non_monotonic[n] eq 0 then begin
          i_keep = lindgen(n_time_array -1L) +1L
        endif else i_keep = lindgen( n_time_array - i_non_monotonic[n]) +i_non_monotonic[n]
        for k = c_non_monotonic-2L,0,-1 do begin
            i_new = lindgen(i_non_monotonic[k+1]-i_non_monotonic[k]) + i_non_monotonic[k]
            i_keep = keep_overlap(i_keep,i_new,time_array,/reverse,KEEP_REPEATS=KEEP_REPEATS)
        endfor
        if i_non_monotonic[0] eq 0 then begin
          i_new = 0L
        endif else i_new = lindgen(i_non_monotonic[0])
        i_keep = keep_overlap(i_keep,i_new,time_array,/reverse,KEEP_REPEATS=KEEP_REPEATS)
      endif
      
      ;;; Sort time-series using bsort()
      if keyword_set(SORT) then i_keep = bsort(time_array)

      ;;; Keep repeats or not
      ONLY_REPEATS: if c_non_monotonic eq 0 then i_keep = lindgen(n_time_array)
      if not keyword_set(KEEP_REPEATS) then begin
        if (c_repeat gt 0) then begin
          i_non_repeats = set_difference([i_keep],[i_repeat])
          if min(i_non_repeats) ne -1 then i_keep = i_non_repeats
        endif
      endif

      ;;; Repair tplot variable and print summary
        ;;; Remove "bad" elements of data.x, data.y and data.v
      if not keyword_set(replace_nan) then begin
        x = data.x[i_keep]
        y_dim = size(data.y,/n_dimensions)
        if y_dim eq 1 then begin
          y = data.y[i_keep]
          if tag_exist(data,'v') then begin
            v = data.v
            if n_elements(data.y) eq n_elements(data.v) then v = data.v[i_keep]
          endif 
        endif
        if y_dim eq 2 then begin
          y = data.y[i_keep,*]
          if tag_exist(data,'v') then begin
            v_dim = size(data.v,/n_dimensions)
            if v_dim eq 2 then begin
              v = data.v[i_keep,*]
            endif else v = data.v
          endif
        endif
        if y_dim eq 3 then begin
          y = data.y[i_keep,*,*]
          if tag_exist(data,'v1') then begin
            v1 = data.v1
            v2 = data.v2
          endif
        endif
        ;;; Replace "bad" elements of data.y and data.v with NaN
      endif else begin
        x = data.x
        i_all = lindgen(n_elements(x))
        i_replace = set_difference([i_all],[i_keep])
        if min(i_replace) ne -1 then begin
          y_dim = size(data.y,/n_dimensions)
          if y_dim eq 1 then begin
            y = data.y
            y[i_replace] = 'NaN'
            if tag_exist(data,'v') then begin
              v = data.v
              if n_elements(data.y) eq n_elements(data.v) then v[i_replace] = 'NaN'
            endif
          endif
          if y_dim eq 2 then begin
            y = data.y
            y[i_replace,*] = 'NaN'
            if tag_exist(data,'v') then begin
              v = data.v
              v_dim = size(data.v,/n_dimensions)
              if v_dim eq 2 then v[i_replace,*] = 'NaN'
            endif
          endif
          if y_dim eq 3 then begin
            y = data.y
            y[i_replace,*,*] = 'NaN'
            if tag_exist(data,'v1') then begin
              v1 = data.v1
              v2 = data.v2
            endif
          endif
        endif            
       endelse
      
      ;;; Write modified data to tplot variable
      if (tag_exist(data,'v') or tag_exist(data,'v1')) then begin
        if tag_exist(data,'v') then store_data,tplot_var,data={x:x,y:y,v:v},dlimits=dlimits,limits=limits
        if tag_exist(data,'v1') then store_data,tplot_var,data={x:x,y:y,v1:v1,v2:v2},dlimits=dlimits,limits=limits
      endif else store_data,tplot_var,data={x:x,y:y},dlimits=dlimits,limits=limits
      
      ;;; Determine percentage of elements removed or replaced, and report them
      percent_removed = (n_time_array - n_elements(i_keep)) / float(n_time_array) * float(100)
      if not keyword_set(replace_nan) then begin
        dprint,tplot_var,':'+strjoin(strarr(max_var_len-strlen(tplot_var))+' ')+'FAIL - repaired: '+ strtrim(percent_removed,2) + ' % removed'
      endif else dprint,tplot_var,':'+strjoin(strarr(max_var_len-strlen(tplot_var))+' ')+'FAIL - repaired: '+ strtrim(percent_removed,2) + ' % replaced with NaN'   
      if percent_removed gt 10d then dprint,'********** Warning: Over 10% removed or replaced from '+strtrim(tplot_var,2)+' **********'
    endif else begin
      ;;; Checking case: report causes of failures
      if ((c_repeat gt 0) and (c_non_monotonic) gt 0) then dprint,tplot_var,':'+strjoin(strarr(max_var_len-strlen(tplot_var))+' ')+'FAIL - '+strtrim(c_non_monotonic,2)+' negative jump(s), '+strtrim(c_repeat,2)+' repeat(s)'
      if ((c_repeat gt 0) and (c_non_monotonic) eq 0) then dprint,tplot_var,':'+strjoin(strarr(max_var_len-strlen(tplot_var))+' ')+'FAIL - '+strtrim(c_repeat,2)+' repeat(s)'
      if ((c_repeat eq 0) and (c_non_monotonic) gt 0) then dprint,tplot_var,':'+strjoin(strarr(max_var_len-strlen(tplot_var))+' ')+'FAIL - '+strtrim(c_non_monotonic,2)+' negative jump(s)'
      
    endelse
  endelse

endfor  ;;; end of loop over tplot variables
end