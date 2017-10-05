
;+
;Function:
;  spd_tplot_trange
;
;Purpose:
;  Return the full or current tplot time range without
;  unnecessary calls to other time procedures.
;
;Calling Sequence:
;  trange = spd_tplot_trange( [/current] )
;
;Input:
;  current:  Flag to return currently plotted time range.
;
;Output:
;  return value:  Two element double-prec. time range as stored by tplot.
;
;Notes:
;  This routine should not modify any variables in the tplot common block.
;
;
;$LastChangedBy: aaflores $
;$LastChangedDate: 2015-02-20 13:46:54 -0800 (Fri, 20 Feb 2015) $
;$LastChangedRevision: 17020 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas_gui/utilities/spd_tplot_trange.pro $
;
;-

function spd_tplot_trange, current=current

    compile_opt idl2, hidden


;access tplot common block directly
;(scope_varfetch willthrow error if the block is not defined)
@tplot_com.pro


tr = [0d,0]


if is_struct(tplot_vars) then begin

  if keyword_set(current) then begin
    tr = tplot_vars.options.trange
  endif else begin
    tr = tplot_vars.options.trange_full
  endelse

endif


return, tr

end