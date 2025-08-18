
;+
; Procedure: tplot3d
;
; Purpose: Takes an array of 3-d(Nx3 or MxNx3) vectors or tplot variable
;          holding these vectors and generates a 3d plot of them
;
;Example: tplotxy,'thb_state_pos'
;         tplotxy,'thb_state_pos',/overplot
;
; Inputs: vectors: an Nx3 or MxNx3 list of vectors or the name of a tplot 
;         variable that stores an Nx3 or MxNx3 list of vectors
;
; Keywords:
;         overplot(optional): overplot on an already existing 3d plot
;
;         noreset(optional): iplot changes some internal settings,
;         this procedure resets them to themis defaults, if you do not
;         want this done then set this option.
;
;         also takes all the other options that iplot takes
;
; $LastChangedBy: aaflores $
; $LastChangedDate: 2012-01-26 17:01:34 -0800 (Thu, 26 Jan 2012) $
; $LastChangedRevision: 9630 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/tplot/tplot3d.pro $
;-

;main function
pro tplot3d, vectors,overplot = overplot,noreset=noreset, _extra = _extra

compile_opt idl2

if(size(vectors, /type) eq 7) then begin 

  if(tnames(vectors) eq '') then message, 'tplot variable specified does not exists'

  get_data, vectors, data = d

  vecs = d.y

endif else vecs = vectors

dims = size(vecs, /dimensions)

if(n_elements(dims) ne 2 && n_elements(dims) ne 3) then message, 'vector argument must be a 2 or 3 dimensional array'

if(dims[n_elements(dims)-1] ne 3) then message, 'last dimension of vector argument must be size 3'

;if a 2-d argument is passed, make it 3-d so all cases can be handled
;using the same code
if(n_elements(dims) eq 2) then begin
  vecs = reform(vecs, [1, dims])
  dims = [1, dims]
endif

for i = 0, dims[0]-1 do begin

   ;identify NaNs
    vec_x = reform(vecs[i, *, 0])

    idx1 = where(finite(vec_x))
    
    vec_y = reform(vecs[i, *, 1])

    idx2 = where(finite(vec_y))
    
    vec_z = reform(vecs[i, *, 2])

    idx3 = where(finite(vec_z))
    
    idxt = ssl_set_intersection(idx1, idx2)

    idxt = ssl_set_intersection(idx3, idxt)

    if(idxt[0] eq -1) then begin 
      dprint, 'cannot plot an line composed entirely of NaNs, skipping line'
    
      continue
    endif

    ;filter NaNs
    vec_x = vec_x[idxt]
    
    vec_y = vec_y[idxt]

    vec_z = vec_z[idxt]

    if not keyword_set(overplot) and i eq 0 then $
      iplot, vec_x,vec_y,vec_z, overplot = 0, _extra = _extra $
    else $
      iplot, vec_x, vec_y, vec_z, overplot = 1, _extra = _extra

  endfor

loadct2,43

!P.color=0
!P.background=255

end
