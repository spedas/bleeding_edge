;+
;Function: THM_TPLOT_VAR
;
;Purpose:  Creates TPLOT variable name from SC id and data qty strings.
;keywords:
;   /VERBOSE or VERBOSE=n ; set to enable diagnostic message output.
;		higher values of n produce more and lower-level diagnostic messages.
;   /ALL
;
;Example:
;	sc = 'a'
;	name = 'eff'
;   tplot_var = thm_tplot_var( sc, name)
;Notes:
;
; $LastChangedBy: kenb-mac $
; $LastChangedDate: 2007-02-08 10:02:45 -0800 (Thu, 08 Feb 2007) $
; $LastChangedRevision: 329 $
; $URL $
;-
function thm_tplot_var, sc, name, verbose=verbose

thm_init

return, string( sc, name, format='("th",A,"_",A)')
end
