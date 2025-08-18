;+
;NAME:
;highlight_time_interval
;PURPOSE:
;for a given tplot variable, click on a time interval to highlight
;using the fill_time_intv option
;CALLING SEQUENCE:
;highlight_time_interval, tplot_variable, time_interval=time_interval,
;                         color = color, polyfill_options =
;                         polyfill_options, delete=delete
;INPUT:
;tplot_variable - one or more tplot variables, No input will apply to
;                 all tplot variables.
;KEYWORDS:
;time_interval - a 2 or 2Xntimes array of time intervals. The default
;                is to use interactive ctime calls. If interactive,
;                then n_intervals is used to calculate the number of
;                time_intervals.
;color - a color value or ntimes color values, the default is color
;        zero, string input is ok, e.g., 'rgb' for three intervals
;line_fill - sets polyfill line_fill option, that uses parallel lines
;            instead of solid color
;orientation - angle in degrees for orientation of lines for line_fill
;              option
;linestyle - linestyle for line_fill option
;thick - line thickness for line_fill option
;n_intervals - used for cases with no time inputs, for number of
;              intervals to choose interactively.
;delete - delete highlights.
;refresh - call tplot to show the intervals
;NOTES:
; The same intervals are applied to each of the input tplot variables
; $LastChangedBy: jimm $
; $LastChangedDate: 2019-11-15 11:20:05 -0800 (Fri, 15 Nov 2019) $
; $LastChangedRevision: 28023 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/tplot/highlight_time_interval.pro $
;-
Pro highlight_time_interval, tplot_var, time_interval = time_interval, $
                             color = color, line_fill = line_fill, $
                             orientation = orientation, linestyle = linestyle, $
                             thick = thick, delete = delete, $
                             n_intervals = n_intervals, $
                             refresh = refresh, _extra = _extra

;get tplot variables
  tvar = tnames(tplot_var)
  If(~is_string(tvar)) Then Begin
     dprint, 'No Variables: '
     Return
  Endif
  nvar = n_elements(tvar)

;delete options
  If(keyword_set(delete)) Then Begin
     For j = 0, nvar-1 Do options, tvar[j], 'fill_time_intv', undefined_variable
     Return
  Endif

;get time intervals
  If(keyword_set(time_interval)) Then Begin
     tintv = time_double(time_interval)
     nintv = n_elements(tintv[0, *])
  Endif Else Begin
     If(keyword_set(n_intervals)) Then nintv = n_intervals $
     Else nintv = 1
     tintv = dblarr(2, nintv)
     ctime, tintvj, npoints = 2*nintv, $
               prompt = "Use cursor to select start and end times, for all intervals"     

     tintv = reform(tintvj, 2, nintv)
  Endelse

;Ok, now call options to get all of the time intervals
  If(keyword_set(color)) Then col = get_colors(color) Else col = 0
  opt = {time:tintv, color:col}
  If(keyword_set(line_fill)) Then str_element, opt, 'line_fill', line_fill, /add
  If(keyword_set(orientation)) Then str_element, opt, 'orientation', orientation, /add
  If(keyword_set(linestyle)) Then str_element, opt, 'linestyle', linestyle, /add
  If(keyword_set(thick)) Then str_element, opt, 'thick', thick, /add
  options, tvar, 'fill_time_intv', opt

  If(keyword_set(refresh)) Then tplot
End
