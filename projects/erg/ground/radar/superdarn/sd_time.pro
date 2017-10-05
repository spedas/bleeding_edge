;+
; PROCEDURE/FUNCTION sd_time
;
; :Description:
;		Describe the procedure/function.
;
;	:Params:
;    time:  Set the time for which a 2-D scan data is plotted
;
;	:Keywords:
;    quiet:   If not set, then the plot time is shown in the command-line console
;
; :EXAMPLES:
;   sd_time, '2007-03-24/14:24' 
;   sd_time, 1424 
;
; :Author:
; 	Tomo Hori (E-mail: horit@stelab.nagoya-u.ac.jp)
;
; :HISTORY:
; 	2011/01/11: Created
; 	
; $LastChangedBy: nikos $
; $LastChangedDate: 2016-05-12 16:57:48 -0700 (Thu, 12 May 2016) $
; $LastChangedRevision: 21070 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/erg/ground/radar/superdarn/sd_time.pro $
;-
PRO sd_time, time, quiet=quiet

;Initialize !SDARN system variable
sd_init

;No argument -> print the current time for plotting
npar= n_params()
if npar eq 0 then begin
  print, 'plot_time: '+time_string(!map2d.time )
  return
endif

;Adopt only the 1st element if mistakenly given as an array
t = time[0]

;Set the plot time
CASE (size(t,/type)) OF
  7 : BEGIN  ;string
    !map2d.time = time_double(t)
  END
  5 : BEGIN  ;double-precision floating 
    !map2d.time = time_double(t)
  END
  2 : BEGIN  ;integer, interpreted as 'hhmm'
    if t lt 0 or t gt 2400 then begin
      dprint, 'Invalid sd time'
      return
    endif
    get_timespan, tr & ts = time_struct(tr[0])
    hh = t / 100 & mm = t mod 100 
    time = time_string(ts, tfor='YYYY-MM-DD')+'/'+string(hh,mm,'(I2.2,":",I2.2)')
    !map2d.time = time_double(time)
  end
  3 : BEGIN  ;integer, interpreted as 'hhmm'
    if t lt 0 or t gt 2400 then begin
      dprint, 'Invalid sd time'
      return
    endif
    get_timespan, tr & ts = time_struct(tr[0])
    hh = t / 100 & mm = t mod 100 
    time = time_string(ts, tfor='YYYY-MM-DD')+'/'+string(hh,mm,'(I2.2,":",I2.2)')
    !map2d.time = time_double(time)
  end
  
  
  ELSE: BEGIN
    dprint, 'Invalid sd time'
    return
  END
ENDCASE

if ~keyword_set(quiet) then print, 'plot_time: '+time_string(!map2d.time)


return
end
