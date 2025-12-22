;+
; A program to insert NaN's into an X array whenever there is a gap
; larger then GAP_SIZE in the T array. The X point beginning and
; ending each gap is lost. This compensates for a feature of TPLOT,
; where spectrograms are interpolated 1/2 way back to the previous
; NaN. 
;
; Bill Peria 29-April-1999
;
;-
pro nan_gap, t, x, gap_size, tdim

if not (defined(t) and defined(x) and defined(gap_size)) then begin
    message,'You must define T, X, and GAP_SIZE', /continue
    return
endif

dt = t[1:*] - t[0:*]
gap = where(dt ge gap_size, ngap) 
if ngap eq 0 then return
nt = n_elements(t) 
gap = gap < (nt-2l)

xdims = dimen(x)
ndims = n_elements(xdims)
if not defined(tdim) then begin
    tdim = where(xdims eq n_elements(t), ntdim)
    if ntdim ne 1 then begin
        message,'Unable to determine which dimension of X goes with ' + $
          'T. ',/continue
        help,x,t
        return
    endif
endif

flip = lindgen(ndims)
flip[0] = tdim
flip[tdim] = 0l
tmp = transpose(x, flip)

tmp[gap,*,*,*,*,*,*,*] = !values.f_nan
tmp[gap+1L,*,*,*,*,*,*,*] = !values.f_nan

x = transpose(tmp, flip)

return
end

