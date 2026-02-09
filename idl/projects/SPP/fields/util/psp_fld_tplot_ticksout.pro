;+
;
; psp_fld_tplot_ticksout
;
; Adjust xticklen and yticklen for tplot variables based on calculated
; aspect ratio for each plotted tplot variable.
;
; Default parameters are those used by the PSP/FIELDS plot routines.
;
; :Keywords:
;   xmargin: bidirectional, optional, numeric
;     Option to set tplot xmargin.
;   ymargin: bidirectional, optional, numeric
;     Option to set tplot ymargin.
;
; $LastChangedBy: pulupalap $
; $LastChangedDate: 2026-02-02 12:38:39 -0800 (Mon, 02 Feb 2026) $
; $LastChangedRevision: 34102 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/fields/util/psp_fld_tplot_ticksout.pro $
;
;-
pro psp_fld_tplot_ticksout, xmargin = xmargin, ymargin = ymargin
  compile_opt idl2

  @tplot_com.pro

  str_element, tplot_vars.options, 'yticklen', yticklen, success = yticklen_found

  str_element, tplot_vars.options, 'xmargin', xmargin ; , success = yticklen_found
  str_element, tplot_vars.options, 'ymargin', ymargin ; , success = yticklen_found

  if yticklen_found eq 0 then begin
    if !d.name eq 'X' then yticklen = -0.006 else yticklen = -0.006 * 10 / (!d.x_size / 2540d)
  endif

  ; if !D.NAME EQ 'X' then yticklen = -0.004 else yticklen = -0.004

  for i = 0, n_elements(tplot_vars.options.varnames) - 1 do begin
    tplot_name = tplot_vars.options.varnames[i]

    get_data, tplot_name, al = lim

    cl = float(tplot_vars.settings.clip[*, i])

    aspect_ratio = (cl[3] - cl[1]) / (cl[2] - cl[0])

    print, tplot_name, aspect_ratio

    str_element, lim, 'xgridstyle', SUCCESS = xgrid_present

    if xgrid_present eq 0 then begin
      options, tplot_name, 'xticklen', yticklen / aspect_ratio
    end

    str_element, lim, 'ygridstyle', SUCCESS = ygrid_present

    if ygrid_present eq 0 then begin
      options, tplot_name, 'yticklen', yticklen
    end

    str_element, lim, 'zoffset', zoffset, success = zoff_found

    if zoff_found eq 0 then options, tplot_name, 'zoffset', [2, 4]
  endfor

  if n_elements(xmargin) eq 0 then tplot_options, 'xmargin', [16, 16] else $
    tplot_options, 'xmargin', xmargin

  if n_elements(ymargin) eq 0 then tplot_options, 'ymargin', [6, 6] else $
    tplot_options, 'ymargin', ymargin
end
