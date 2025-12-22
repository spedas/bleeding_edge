;+
;FUNCTION:
;
;data_only
;
;PURPOSE:
;
; To find non-empty invervals in data.  Good for selecting the
; N. hem. and S. hem. passes out of an orbit's worth of data.  Given
; the string name of a preloaded tplot structure, will return an array
; containing pairs of times designating data intervals.  
;
; array(0,0) contains the start time of the first data interval and 
; array(1,0) contains the end time of the first data interval.
;
; Returns either one or two pairs of times.  Only works with 2-D data.
;
;ARGUMENTS:
;
; qty      Name of tplot data structure: 'Je', 'Ji', etc.
;
;KEYWORDS:
;
; thresh   minimum number of seconds between data intervals.  By
;          default this is set to 900 which should be enough to
;          discern the northern and southern passes.
;
;-
function data_only, qty, THRESH=thresh

if NOT keyword_set(thresh) then thresh=900

get_data, qty, data=tmp
nan_ind = where(finite(tmp.y) NE 1, n_nan)
npts = n_elements(tmp.x)

if n_nan LE 1 then begin
    intervals = [[tmp.x(0)], [tmp.x(npts-1)]]
endif else begin
    ; Find the biggest gap in the data
    duration = 0.D
    for i=0, (n_nan-1) do begin
        if (nan_ind(i)+1) LT (npts-1) then begin
            if NOT finite(tmp.y(nan_ind(i)+1)) then begin
                nan_st_tmp = tmp.x(nan_ind(i))
                nan_en_tmp = tmp.x(nan_ind(i)+1)
                duration_tmp = nan_en_tmp - nan_st_tmp
                if duration_tmp GT duration then begin
                    duration = duration_tmp
                    nan_st = nan_st_tmp
                    nan_en = nan_en_tmp
                    nan_st_ind = nan_ind(i)
                    nan_en_ind = nan_ind(i)+1
                endif
            endif
        endif
    endfor
    min_dur = double(thresh)
    if (NOT keyword_set(nan_st_ind)) OR (duration LT min_dur) then begin
        intervals = [[tmp.x(0)], [tmp.x(npts-1)]]
    endif else begin
        if nan_st_ind EQ 0 then intervals=[[tmp.x(nan_en_ind)],[tmp.x(npts-1)]] $
        else intervals=[[tmp.x(0), tmp.x(nan_st_ind)], $
                        [tmp.x(nan_en_ind), tmp.x(npts-1)]]
    endelse
endelse
    
return, intervals

end
            
