;+
;NAME:
; thm_esa_cmn_l2tclip
;PURPOSE:
; applies a trange to a THEMIS ESA L2 structure
;CALLING SEQUENCE:
; dat = thm_esa_cmn_l2tclip(dat, trange)
;INPUT:
; dat1 = a THEMIS ESA L2 3D data structure: e.g., 
;OUTPUT:
; dat = structure with data only in the input time range
;NOTES:
; Only will work if the record varying arrays are 5D or less 
;HISTORY:
; 8-Nov-2022 jmm, jimm@ssl.berkeley.edu
; $LastChangedBy: jimm $
; $LastChangedDate: 2022-11-08 11:43:51 -0800 (Tue, 08 Nov 2022) $
; $LastChangedRevision: 31249 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/spacecraft/particles/ESA/thm_esa_cmn_l2tclip.pro $
;-
Function thm_esa_cmn_l2tclip, dat1, trange

  If(n_elements(trange) Ne 2) Then Begin
     dprint, dlevel = [0], 'Bad time range:'
     Return, -1
  Endif

;Record varying arrays are clipped rv_flag is 'Y' for tags that will
;be clipped.
  rv_arr = thm_esa_cmn_l2vararr(dat1.data_name)
  
  nvar = n_elements(rv_arr[0, *])
  tags1 = tag_names(dat1)
  ntags1 = n_elements(tags1)

  xtime = where(tags1 Eq 'TIME', nxtime)
  If(nxtime Eq 0) Then Begin
     dprint, dlev = [0], 'Missing tag: TIME'
     Return, -1
  Endif Else Begin
     tr0 = time_double(trange)
     ok = where(dat1.time Ge tr0[0] And dat1.time Lt tr0[1], nok)
     If(nok Eq 0) Then Begin
        dprint, dlev = [0], 'No data in interval: '
        dprint, dlev = [0], time_string(tr0[0])+ ' -- '+time_string(tr0[1])
        Return, -1
     Endif
  Endelse
        
;The ok array exists here
  count = 0
  dat = -1
  For j = 0, nvar-1 Do Begin
     x1 = where(tags1 Eq rv_arr[0, j], nx1)
     If(nx1 Eq 0) Then Begin
        dprint, 'Ignoring missing tag: '+rv_arr[0, j]
     Endif Else Begin
        If(rv_arr[2, j] Eq 'N') Then Begin
           If(count Eq 0) Then undefine, dat
           count = count+1
           str_element, dat, rv_arr[0, j], dat1.(x1), /add_replace
        Endif Else Begin        ;records vary
           t1 = dat1.(x1)
           If(count Eq 0) Then undefine, dat
           count = count+1
           str_element, dat, rv_arr[0, j], t1[ok, *, *, *, *], /add_replace
        Endelse
     Endelse
  Endfor

  Return, dat
End

