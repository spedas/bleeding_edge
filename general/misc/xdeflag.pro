;+ NAME: 
; xdeflag 
;PURPOSE:
; Replaces FLAGs in arrays with interpolated or other values
;CALLING SEQUENCE:
; xdeflag, method, t, y, flag=flag, _extra=_extra
;INPUT:
; method = set to "repeat", this will repeat the last good value.
;          set to "linear", then linear interpolation is used, but for
;          the edges, the closest value is used, there is no
;          extrapolation
; t = time array, in any useable tplot format
; y = the input array, n_elements(t) by n
;OUTPUT:
; y = either interpolated or repated, where the value is > 0.98*flag,
;     or NaN
;KEYWORDS:
; flag = all values greater than 0.98 times this value will be removed; 
;        default is 6.879e28, NaNs and +/-Infinity are always removed
; maxgap = the maximum number of rows that can be filled? the default
;           is n_elements(t)
; display_object = Object reference to be passed to dprint for output.
;
;HISTORY:
; 2-feb-2007, jmm, jimm.ssl.berkeley.edu from Vassilis' clip_deflag.pro
;
;$LastChangedBy: pcruce $
;$LastChangedDate: 2012-07-05 11:21:00 -0700 (Thu, 05 Jul 2012) $
;$LastChangedRevision: 10684 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/misc/xdeflag.pro $
;-
Pro xdeflag, method0, t0, y, flag=flag, maxgap = maxgap, _extra=_extra, display_object=display_object

  compile_opt idl2

  if ~keyword_set(method0) then begin
    message,'method variable must be set'
  endif

  method = strtrim(strlowcase(method0), 2)
  If size(flag, /type) GT 1 Then big = flag Else big = 6.879e28
  big98 = 0.98*big
  t = time_double(t0)
  nrows = n_elements(t)
  if (keyword_set(maxgap)) then mxgp = maxgap $
  else mxgp = nrows
;
  If(n_elements(y[*, 0]) ne nrows) Then Begin
    dprint, 'number of rows does not agree between time and yarray(s)', display_object=display_object
    help, t0
    help, y
    Return
  Endif
  ndims = size(y, /dimensions)
  ncols = 0 & nlayers = 0
  if (n_elements(ndims) ge 2) then ncols = ndims[1]
  if (n_elements(ndims) eq 3) then nlayers = ndims[2]
  if (ncols eq 0) then nycols = 1 else nycols = ncols
  if (nlayers eq 0) then nylayers = 1 else nylayers = nlayers
  nycolayers = nycols*nylayers
  y = reform(y, nrows, nycolayers)
  for j=0,nycolayers-1 do begin
    jiwhere = where((y[*, j] gt BIG98) Or (finite(y[*, j]) Eq 0), jiany)
    if ((jiany gt 0) and (jiany lt nrows))  then begin
      if (jiany eq 1) then begin
        ngaps = 1l
        kbegin = lonarr(1)
        kbegin[0] = long(jiwhere[0])
        kend = kbegin
        ksize = kend-kbegin+1l
        kslope = dblarr(1)
        tk0 = dblarr(1)
        yk0 = dblarr(1)
        if (kbegin[0] eq 0) then begin
          tk0[0] = 0l
          yk0[0] = y[kend[0]+1, j]
          kslope[0] = 0l
        endif
        if (kend[0] eq (nrows-1)) then begin
          tk0[0] = t[kbegin[0]-1]
          yk0[0] = y[kbegin[0]-1, j]
          kslope[0] = 0l
        endif
        if ((kbegin[0] ne 0) and (kend[0] ne (nrows-1))) then begin
          tk0[0] = t[kbegin[0]-1]
          yk0[0] = y[kbegin[0]-1, j]
          kslope[0] = (y[kend[0]+1, j]-y[kbegin[0]-1, j])/(t[kend[0]+1]-tk0[0])
        endif
      endif else begin
        kany = make_array(jiany-1, /long, /index)
        difji = jiwhere[kany+1]-jiwhere[kany]
        kdif = where(difji gt 1, knum)
        ngaps = knum+1
        kbegin = lonarr(ngaps)
        kend = lonarr(ngaps)
        kbegin[0] = jiwhere[0]
        kend[ngaps-1] = jiwhere[jiany-1]
        if (ngaps gt 1) then begin
          kindex1 = make_array(ngaps-1, /long, /index)
          kend[kindex1] = jiwhere[kdif[kindex1]]
          kbegin[kindex1+1] = jiwhere[kdif[kindex1]+1]
        endif
        ksize = kend-kbegin+1
        kslope = dblarr(ngaps)
        tk0 = dblarr(ngaps)
        yk0 = dblarr(ngaps)
        if (kbegin[0] eq 0) then begin
          tk0[0] = 0l
          yk0[0] = y[kend[0]+1, j]
          kslope[0] = 0l
        endif else begin
          if (kend[0] ne (nrows-1)) then begin
            tk0[0] = t[kbegin[0]-1]
            yk0[0] = y[kbegin[0]-1, j]
            kslope[0] = (y[kend[0]+1, j]-y[kbegin[0]-1, j])/(t[kend[0]+1]-tk0[0])
          endif
        endelse
        if (kend[ngaps-1] eq (nrows-1)) then begin
          tk0[ngaps-1] = t[kbegin[ngaps-1]-1]
          yk0[ngaps-1] = y[kbegin[ngaps-1]-1, j]
          kslope[ngaps-1] = 0l
        endif else begin
          if (kbegin[ngaps-1] ne 0) then begin
            tk0[ngaps-1] = t[kbegin[ngaps-1]-1]
            yk0[ngaps-1] = y[kbegin[ngaps-1]-1, j]
            kslope[ngaps-1] = (y[kend[ngaps-1]+1, j]-y[kbegin[ngaps-1]-1, j])/(t[kend[ngaps-1]+1]-tk0[ngaps-1])
          endif
        endelse
        if (ngaps gt 2) then begin
          kindex2 = make_array(ngaps-2, /long, /index)
          tk0[kindex2+1] = t[kbegin[kindex2+1]-1]
          yk0[kindex2+1] = y[kbegin[kindex2+1]-1, j]
          kslope[kindex2+1] = (y[kend[kindex2+1]+1, j]-y[kbegin[kindex2+1]-1, j])/(t[kend[kindex2+1]+1]-tk0[kindex2+1])
        endif
      endelse
      case method of
        "repeat":begin
          repeat_loop:
          kthgood = where(ksize le mxgp, ianygood)
          if (ianygood gt 0) then begin
;                print,'ianygood=',ianygood
            for kthgap = 0l, long(ianygood-1) do begin
              kindices = kbegin[kthgood[kthgap]]+lindgen(ksize[kthgood[kthgap]])
              y[kindices, j] = yk0[kthgood[kthgap]]
            endfor
          endif
        end
        "linear":begin
          kthgood = where(ksize le mxgp, ianygood)
;                print,'ianygood=',ianygood
          if (ianygood gt 0) then begin
            for kthgap = 0l, long(ianygood-1) do begin
              kindices = kbegin[kthgood[kthgap]]+lindgen(ksize[kthgood[kthgap]])
              y[kindices, j] = yk0[kthgood[kthgap]]+$
                (t[kindices]-tk0[kthgood[kthgap]])*kslope[kthgood[kthgap]]
            endfor
          endif
        end
        else:Begin
          dprint, 'Invalid Method input, Set to ''repeat''', display_object=display_object
          goto, repeat_loop
        end
      endcase
    endif
    
    if (jiany eq nrows) then begin
      dprint, 'One row is all FLAGs: left as is by deflag', display_object=display_object
    endif
   
  endfor

    if ((ncols gt 0) and (nlayers gt 0)) then y=reform(y,nrows,ncols,nlayers)
    if ((ncols gt 0) and (nlayers eq 0)) then y=reform(y,nrows,ncols)
    if ((ncols eq 0) and (nlayers eq 0)) then y=reform(y,nrows)
    
  Return
End
