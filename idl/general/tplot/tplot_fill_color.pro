;+
; NAME:
;     tplot_fill_color
;
; PURPOSE:
;     Fills the area under a line in a tplot panel
;
; INPUT:
;     vars: string or array of strings specifying which tplot variables to fill
;     colors: int or array of ints specifying the fill colors; must match the number
;           of elements in 'vars'
;
;
; EXAMPLE:
;     >> tplot, 'kyoto_dst'
;     >> tplot_fill_color, 'kyoto_dst', spd_get_color('blue')
;     
; WARNING:
;     if you see strange results with a variable containing NaNs, run 'tdegap' 
;     on the variable prior to creating the figure to remove the NaNs
;
;$LastChangedBy: egrimes $
;$LastChangedDate: 2020-02-12 12:40:17 -0800 (Wed, 12 Feb 2020) $
;$LastChangedRevision: 28296 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/tplot/tplot_fill_color.pro $
;-

pro tplot_fill_color, vars, colors, pos=pos;, _extra=_extra
  @tplot_com.pro
  tvinfo = tplot_vars
  
  if keyword_set(pos) then pos = pos else tplot, get_plot_position=pos;, _extra=_extra
  
  if undefined(colors) then color = 6
  if undefined(vars) || n_elements(tnames(vars)) eq 0 then begin
    dprint, dlevel=0, 'Error, please specify a valid variable name to plot'
    return
  endif else vars = tnames(vars)
  
  for var_idx=0, n_elements(tvinfo.options.varnames)-1 do begin
    if array_contains(vars, tvinfo.options.varnames[var_idx]) then begin
      var = tvinfo.options.varnames[var_idx]
      get_data, var, data=d

      color_idx = where(vars eq var)
      
      positive_y = where(d.Y[*, 0] ge 0, pos_y_count)
      neg_y = where(d.Y[*, 0] lt 0, neg_y_count)

      if pos_y_count ne 0 then begin
        pos_y = d.y
        if neg_y_count ne 0 then begin
          pos_y[neg_y, 0] = 0.0
        endif
        if tvinfo.settings.y[var_idx].type eq 0 then t_scale = ([d.x, reverse(d.x)]-tvinfo.settings.time_offset)/tvinfo.settings.time_scale $
          else t_scale = ([reverse(d.x), d.x]-tvinfo.settings.time_offset)/tvinfo.settings.time_scale 
        nx = data_to_normal(t_scale, tvinfo.settings.x)
        if tvinfo.settings.y[var_idx].type eq 0 then ny = data_to_normal([pos_y[*, 0], dblarr(n_elements(pos_y[*, 0]))], tvinfo.settings.y[var_idx]) $
          else ny = data_to_normal([dblarr(n_elements(pos_y[*, 0])), pos_y[*, 0]], tvinfo.settings.y[var_idx])
          
        nonfinite = where(~finite(ny), nancount)
        if nancount ne 0 then ny[where(~finite(ny))] = 0.0
        polyfill, nx, ny, color=colors[color_idx[0]], /normal, clip=pos[*, var_idx], noclip=0
      endif

      if neg_y_count ne 0 then begin
        if pos_y_count ne 0 then d.Y[positive_y, 0] = 0.0

        t_scale = ([d.x, reverse(d.x)]-tvinfo.settings.time_offset)/tvinfo.settings.time_scale
        nx = data_to_normal(t_scale, tvinfo.settings.x)
        ny = data_to_normal([dblarr(n_elements(d.y[*, 0])), reverse(d.y[*, 0])], tvinfo.settings.y[var_idx])
        polyfill, nx, ny, color=colors[color_idx[0]], /normal, clip=pos[*, var_idx], noclip=0
      endif
    endif
  endfor
    
end