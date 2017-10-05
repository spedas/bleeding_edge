
;+
;Procedure:
;  spd_slice2d_getticks_rlog
;
;
;Purpose:
;  Helper function for spd_slice2d_plot. 
;  Return an array of formatted annotation strings to be passed
;  to an IDL plotting procedure through the [xyz]tickname keyword.
;    
;
;Input:
;  range: (float) two element array specifying axis range
;  precision: (int) number of significant digits for annotation
;  style: (int) type of numberical annotation (0=auto, 1=decimal, 2=sci)
;  nticks: (int) # of ticks requested by user, this will only be used 
;          if the axis range is less than 1 order of magnitude (optional)

;  
;
;Output:
;  tickname: (string) Array of tick names
;  tickv: (float) Array of tick values in normalized/shift log space
;  ticks: (int) Number of ticks - 1   
;
;
;Notes:
;  - This function should be called after the plot window has been initialized;
;    otherwise, the AXIS procedure will create an extra window.   
;  - If the axis range is less than 1 order in log space then IDL will determine ticks.
;
;
;$LastChangedBy: aaflores $
;$LastChangedDate: 2015-09-08 18:47:45 -0700 (Tue, 08 Sep 2015) $
;$LastChangedRevision: 18734 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/science/spd_slice2d/plotting/spd_slice2d_getticks_rlog.pro $
;
;-
pro spd_slice2d_getticks_rlog, range=range, grid=grid, $
                                precision=precision, style=style, nticks=nticks, $
                                tickv=tickvals, tickname=ticknames, ticks=ticknum

    compile_opt idl2, hidden

  
  if undefined(style) then style=3
  
  ;Get range and span of axis in log space
  log_range = alog10(range)
  log_span = log_range[1] - log_range[0]

  ;Generate values for ticks in (linear) data space
  if log_span ge 1 then begin
    lin_values = 10 ^ ( findgen(ceil(log_span)+1) + floor(log_range[0]) ) 
  endif else begin
    axis, /yaxis, /ylog, ystyle=1+4, yrange=range, yticks=nticks, ytick_get=lin_values
    ;ensure center tick is present
    if lin_values[0] gt range[0] then begin
      lin_values=[range[0],lin_values]
    endif
    ;in case axis returns ticks completely outside the range (sadly, this happens)
    dummy = where(lin_values gt range[0] and lin_values le range[1], nt)
    if nt eq 0 then begin
      lin_values = lin_values < range[1]
    endif
  endelse
  
  ;Lowest value tick should reflect the minimum range
  ;(this will be the axis's center tick)
  lin_values = range[0] > lin_values

  ;Get values for ticks in log space.
  log_values = alog10(lin_values)
 
  ;Map into normalized range
  ;This should mirror the original operation performed in spd_slice2d_rlog
  log_values = log_values - log_range[0]
  log_values = log_values / log_span

  ;Initialize text output
  ticknames = strarr(n_elements(log_values))

  ;Format ticks with custom routine
  lin_values[0] = round(lin_values[0]) ;for aesthetics
  for i=0, n_elements(lin_values)-1 do begin
    ticknames[i] = formatannotation(0,0,lin_values[i], $
      data={timeaxis:0,formatid:precision,scaling:0,exponent:style})
  endfor

  ;Use spaces to supress text for 0 or 1 ticks
  if size(nticks,/type) ne 0 then begin
    if nticks eq 1 then ticknames[1] = ' '
    if nticks lt 1 then ticknames[*] = ' '
  endif
  
  tickvals = [(-1)*reverse(log_values[1:*]), log_values]
  
  ticknames[0] = '!Z(00B1)' + ticknames[0]
  ticknames = ['-'+reverse(ticknames[1:*]), ticknames]

  ;clip ticks far outside original data range 
  idx = where(tickvals ge 1.1*min(grid) and tickvals le 1.1*max(grid), nok)
  if nok gt 0 then begin
    tickvals = tickvals[idx]
    ticknames = ticknames[idx]
  endif 

  ticknum = n_elements(tickvals)-1 

end