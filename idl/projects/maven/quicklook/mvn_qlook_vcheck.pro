;+
;NAME:
; mvn_qlook_vcheck
;PURPOSE:
; CHecks to see if data exists for a list of variables. Also will
; return the overall time range:
;CALLING SEQUENCE:
; vlist_ok = mvn_qlook_vcheck(varlist, tr = tr, ok_vars=ok_vars)
;INPUT:
; vlist = a list of TPLOT variables, can be anything that can be
;         resolved by TNAMES, scalar or vector, wildcards, etc...
;OUTPUT:
; vlist_ok = A cleaned list
;KEYWORDS:
; tr = the time range of all of the variables
; ok_vars = subscripts of the good variables in the input list.
; blankp = if set, add a blank panel for missing variables
;HISTORY:
; jmm, jimm@ssl.berkeley.edu, 21-May-2013
; $LastChangedBy: jimm $
; $LastChangedDate: 2014-03-26 14:17:04 -0700 (Wed, 26 Mar 2014) $
; $LastChangedRevision: 14676 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/quicklook/mvn_qlook_vcheck.pro $
;-
Function mvn_qlook_vcheck, varlist0, tr = tr, ok_vars=ok_vars, blankp=blankp

vlist_ok = ''
tr = -1
ok_vars = -1
If(~is_string(varlist0)) Then Begin
   dprint, 'No variables input'
   Return, vlist_ok
Endif
varlist = varlist0
nv = n_elements(varlist)
ok_var = bytarr(nv)
ok_count = 0
tok_count = 0
For j = 0, nv-1 Do Begin
    get_data, varlist[j], data = dj
    If(is_struct(dj)) Then Begin
        ok_var[j]=1
        ok_count = ok_count+1
        tok_count = tok_count+1
        If(tok_count Eq 1) Then t = minmax(dj.x) Else t = [t, minmax(dj.x)]
    Endif Else If is_string(dj) Then Begin ;compound variable
        ok_var[j]=1
        ok_count = ok_count+1
        tempx = mvn_qlook_vcheck(tnames(dj), tr = trj)
        If(trj[0] Ne -1) Then Begin
            tok_count = tok_count+1
            If(tok_count Eq 1) Then t = trj Else t = [t, trj]
        Endif
    Endif
Endfor
If(n_elements(t) Gt 0) Then tr = minmax(t[where(t Gt 0)]) Else tr = -1
;Create tplot variables for missing data, if requested
If(keyword_set(blankp)) Then Begin
    bad_vars = where(ok_var Eq 0, nbad_vars)
    If(nbad_vars Gt 0) Then Begin
        For j = 0, nbad_vars-1 Do Begin
            store_data, varlist[bad_vars[j]], data={x:tr, y:[!values.f_nan, !values.f_nan]}
            ok_var[bad_vars[j]] = 1 
        Endfor
    Endif
Endif

ok_vars = where(ok_var Eq 1, nok_vars)
If(nok_vars Eq 0) Then Begin
    dprint, 'No data available'
    Return, ''
Endif

vlist_ok = varlist[ok_vars]

Return, vlist_ok

End
