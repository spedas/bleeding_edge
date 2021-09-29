;+
; FUNCTION:
;         spd_times_from_top_panel
;
; PURPOSE:
;         Returns the times from the top panel in the current tplot window
;
;
;$LastChangedBy: egrimes $
;$LastChangedDate: 2018-08-09 15:30:24 -0700 (Thu, 09 Aug 2018) $
;$LastChangedRevision: 25621 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/spedas_tools/flipbookify/spd_times_from_top_panel.pro $
;-

function spd_times_from_top_panel
  @tplot_com.pro

  tpv_opt_tags = tag_names(tplot_vars.options)
  idx = where( tpv_opt_tags eq 'DATANAMES', icnt)
  if icnt gt 0 then begin
    tplotnames = tplot_vars.options.datanames
    tplotnames = tnames(tplotnames, nd, /all, index=ind)
    get_data, tplotnames[0], data=top_panel
    ; in case the top panel contains a pseudovariable
    if ~is_struct(top_panel) && is_array(top_panel) then get_data, top_panel[0], data=top_panel
    if is_struct(top_panel) then times = top_panel.x
  endif else begin
    dprint, dlevel=0, 'Error, no tplot window found'
    return, -1
  endelse
  return, times
end