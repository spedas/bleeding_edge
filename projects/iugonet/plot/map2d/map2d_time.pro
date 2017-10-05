;+
; PROCEDURE map2d_time
;
; :Description:
;    Describe the procedure/function.
;
; :Params:
;    time:  Set the time for which 2D data is drawn on the world map
;
; :Keywords:
;    quiet:   If not set, then the plot time is shown in the command-line console
;
; :EXAMPLES:
;    map2d_time, '2007-03-24/14:24' 
;    map2d_time, 1424 
;
; :Author:
;    Y.-M. Tanaka (E-mail: ytanaka@nipr.ac.jp)
;
; :HISTORY:
;    2014/07/28: Created
;
;-
pro map2d_time, time, quiet=quiet

;Initialize !map2d system variable
map2d_init

;No argument -> print the current time for plotting
npar= n_params()
if npar eq 0 then begin
    print, 'plot_time: '+time_string(!map2d.time )
    return
endif

;Adopt only the 1st element if mistakenly given as an array
t = time[0]

;Set the plot time
case (size(t,/type)) of
    7 : begin  ;string
        !map2d.time = time_double(t)
    end
    5 : begin  ;double-precision floating 
        !map2d.time = time_double(t)
    end
    2 : begin  ;integer, interpreted as 'hhmm'
        if t lt 0 or t gt 2400 then begin
            dprint, 'invalid map2d time'
            return
        endif
        get_timespan, tr & ts = time_struct(tr[0])
        hh = t / 100 & mm = t mod 100 
        time = time_string(ts, tfor='YYYY-MM-DD')+'/'+string(hh,mm,'(i2.2,":",i2.2)')
        !map2d.time = time_double(time)
    end
    3 : begin  ;integer, interpreted as 'hhmm'
        if t lt 0 or t gt 2400 then begin
            dprint, 'invalid map2d time'
            return
        endif
        get_timespan, tr & ts = time_struct(tr[0])
        hh = t / 100 & mm = t mod 100 
        time = time_string(ts, tfor='YYYY-MM-DD')+'/'+string(hh,mm,'(i2.2,":",i2.2)')
        !map2d.time = time_double(time)
    end
    else: begin
        dprint, 'invalid map2d time'
        return
    end
endcase

if ~keyword_set(quiet) then print, 'time: '+time_string(!map2d.time)

return
end
