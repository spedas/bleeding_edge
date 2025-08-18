;+
;NAME:
; fa_esa_cmn_tclip
;PURPOSE:
; applies a trange to a FAST ESA L2 structure
;CALLING SEQUENCE:
; dat = fa_esa_cmn_tclip(dat, trange)
;INPUT:
; dat1 = a FAST ESA data structure: e.g., 
;OUTPUT:
; dat = structure with data only in the input time range
;NOTES:
; Only will work if the record varying arrays are 5D or less 
;HISTORY:
; 19-may-2014, jmm, jimm@ssl.berkeley.edu
; $LastChangedBy: jimm $
; $LastChangedDate: 2015-09-01 16:30:31 -0700 (Tue, 01 Sep 2015) $
; $LastChangedRevision: 18687 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/missions/fast/fa_esa/l2util/fa_esa_cmn_tclip.pro $
;-
Function fa_esa_cmn_tclip, dat1, trange

  If(n_elements(trange) Ne 2) Then Begin
     dprint, dlevel = [0], 'Bad time range:'
     Return, -1
  Endif

;Record varying arrays are clipped rv_flag is 'Y' for tags that will
;be clipped.
  rv_arr = fa_esa_cmn_l2vararr(dat1.data_name)
  
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

