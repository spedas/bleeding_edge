;+
; $LastChangedBy: pulupalap $
; $LastChangedDate: 2026-02-02 12:38:39 -0800 (Mon, 02 Feb 2026) $
; $LastChangedRevision: 34102 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/fields/util/psp_fld_tplot_pdf.pro $
;-

pro psp_fld_tplot_pdf, filename, timestamp = timestamp, $
  timebars = timebars, abc = abc, $
  delete_eps = delete_eps, no_png = no_png, _extra = _extra, $
  lim = lim, $
  overplot = overplot, $
  bottom_spacer = bottom_spacer, eps_clip = eps_clip, round_eps = round_eps, $
  open_only = open_only, close_only = close_only
  compile_opt idl2

  @tplot_com.pro

  old_p = !p
  old_x = !x
  old_y = !y
  old_z = !z

  if n_elements(filename) eq 0 then begin
    print, 'Must specify filename'
    return
  endif

  if keyword_set(open_only) and keyword_set(close_only) then begin
    print, 'Cannot set OPEN_ONLY and CLOSE_ONLY simultaneously'
    return
  endif

  tplot_options, get_options = topts
  str_element, topts, 'ygap', ygap0, success = ygap_found

  str_element, topts, 'title', title, success = title_found

  if title_found then begin
    if title.startsWith('PSP') then begin
      if n_elements(topts.title.split('!C')) eq 2 then begin
        if (topts.trange[1] - topts.trange[0]) eq 86400 and $
          time_string(topts.trange[0], tformat = 'hh:mm:ss') eq '00:00:00' then begin
          tr_str = time_string(topts.trange[0], tformat = 'YYYY-MM-DD (YYYY-DOY)')
        endif else begin
          tr_str = trange_str(topts.trange)
        endelse

        tplot_options, 'title', (topts.title.split('!C'))[0] + '!C' + tr_str
      endif
    endif
  endif

  if n_elements(thick) eq 0 then thick = 3

  if n_elements(delete_eps) eq 0 then delete_eps = 1

  if n_elements(bottom_spacer) eq 0 then bottom_spacer = 1

  if (keyword_set(close_only) eq 0) then begin
    if keyword_set(bottom_spacer) then begin
      get_timespan, spacer_ts

      store_data, 'spp_fld_tplot_eps_spacer', /delete

      store_data, 'spp_fld_tplot_eps_spacer', dat = {x: spacer_ts, y: [-1, -1]}

      options, 'spp_fld_tplot_eps_spacer', 'xticklen', 0.5
      options, 'spp_fld_tplot_eps_spacer', 'ytitle', ' '
      options, 'spp_fld_tplot_eps_spacer', 'panel_size', 0.001
      options, 'spp_fld_tplot_eps_spacer', 'ystyle', 5
      options, 'spp_fld_tplot_eps_spacer', 'xgridstyle', 4
      options, 'spp_fld_tplot_eps_spacer', 'xstyle', 8
      options, 'spp_fld_tplot_eps_spacer', 'xthick', 0.5 ; , 8
      options, 'spp_fld_tplot_eps_spacer', 'yrange', [0, 1]

      tplot_panel_label, 'spp_fld_tplot_eps_spacer', ' ', 0.5, 0.5

      ; options, 'spp_fld_tplot_eps_spacer', 'color', 6 ; set to 1-6 to see the faint extra line
    endif

    if keyword_set(timestamp) then $
      filename += '_' + (time_string(topts.trange, format = 2)).join('_')
    ; stop

    ; t0 = systime(/seconds)

    psp_fld_popen, filename, _extra = _extra

    device, decompose = 0
    ; !p.color = 6

    ; if n_elements(set_font) gt 0 then device, SET_FONT = set_font ; , /TT_FONT

    if n_elements(bottom_spacer) gt 0 then begin
      if ygap_found then begin
        ygap = [ygap0, 0.]

        tplot_options, 'ygap', ygap
      endif else begin
        nvar = n_elements(topts.varnames)

        if nvar gt 1 then $

          tplot_options, 'ygap', [fltarr(nvar) + 1., 0.] else $
          tplot_options, 'ygap', 0.
      endelse

      tplot, 'spp_fld_tplot_eps_spacer', add = 99
    endif else begin
      tplot
    endelse

    ; if n_elements(xsize) eq 1 then $
    ; options, 'yticklen', -0.004 * 10 / xsize

    psp_fld_tplot_ticksout, xmargin = xmargin, ymargin = ymargin, _extra = _extra

    if n_elements(no_png) eq 0 then no_png = 1 ; default

    if no_png then begin
      psp_fld_pclose
    endif else begin
      psp_fld_pclose, /png
    endelse

    psp_fld_popen, filename, _extra = _extra

    device, decompose = 0
    ; !p.color = 6

    ; if n_elements(set_font) gt 0 then device, SET_FONT = set_font ; , /TT_FONT

    @tplot_com

    foreach var, tplot_vars.settings.varnames, var_i do begin
      get_data, var, lim = lim

      str_element, lim, 'zstretch', zstr, success = zstr_found

      if zstr_found then begin
        xw0 = tplot_vars.settings.x.window
        yw0 = tplot_vars.settings.y[var_i].window

        str_element, lim, 'zoffset', offset, success = zoff_found

        if zoff_found eq 0 then offset = [1., 2]
        if not keyword_set(charsize) then charsize = !p.charsize
        if charsize eq 0. then charsize = 1.0
        space = charsize * !d.x_ch_size / !d.x_size

        xw = xw0[1] + offset * space
        yw = [yw0[0], yw0 + (yw0[1] - yw0) * zstr[1]]

        zpos = [xw[0], yw[0], xw[1], yw[1]]

        options, var, 'zposition', zpos
      endif
    endforeach

    if keyword_set(abc) then psp_fld_tplot_abc

    tplot

    foreach var, tplot_vars.settings.varnames, var_i do begin
      xw0 = tplot_vars.settings.x.window
      yw0 = tplot_vars.settings.y[var_i].window

      xw = [xw0[0], xw0[1], xw0[1], xw0[0], xw0[0]]
      yw = [yw0[0], yw0[0], yw0[1], yw0[1], yw0[0]]

      plot, findgen(10), xthick = thick, ythick = thick, $
        color = 0, /norm, /noerase, /nodata, $
        position = [xw0[0], yw0[0], xw0[1], yw0[1]], $
        xticks = 1, yticks = 1, xminor = 1, yminor = 1, $
        xtickformat = 'psp_fld_ticks_blank', ytickformat = 'psp_fld_ticks_blank'
    endforeach

    ; stop
    if keyword_set(overplot) then tplot, overplot, /oplot

    if keyword_set(timebars) then begin
      foreach tb, timebars do begin
        tb_color = !null
        tb_linestyle = !null
        tb_thick = !null
        tb_verbose = !null
        tb_varname = !null
        tb_between = !null
        tb_transient = !null
        tb_databar = !null

        str_element, tb, 'kw', success = kw_found

        if kw_found then begin
          str_element, tb.kw, 'color', value = tb_color
          str_element, tb.kw, 'linestyle', value = tb_linestyle
          str_element, tb.kw, 'thick', value = tb_thick
          str_element, tb.kw, 'verbose', value = tb_verbose
          str_element, tb.kw, 'varname', value = tb_varname
          str_element, tb.kw, 'between', value = tb_between
          str_element, tb.kw, 'transient', value = tb_transient
          str_element, tb.kw, 'databar', value = tb_databar
        endif

        timebar, tb.t, $
          color = tb_color, $
          linestyle = tb_linestyle, $
          thick = tb_thick, $
          verbose = tb_verbose, $
          varname = tb_varname, $
          between = tb_between, $
          transient = tb_transient, $
          databar = tb_databar
      endforeach
    endif
  endif

  if (keyword_set(open_only) eq 0) then begin
    if n_elements(t1) eq 0 then t1 = systime(/seconds)

    psp_fld_pclose
  endif

  ; if (keyword_set(open_only) EQ 0) then begin

  !p = old_p
  !x = old_x
  !y = old_y
  !z = old_z

  if n_elements(bottom_spacer) gt 0 then begin
    store_data, 'spp_fld_tplot_eps_spacer', /delete

    if ygap_found then begin
      tplot_options, 'ygap', ygap0
    endif else begin
      tplot_options, 'ygap'
    endelse

    if (keyword_set(open_only) eq 0) then tplot, topts.varnames
  endif

  ; endif
end
