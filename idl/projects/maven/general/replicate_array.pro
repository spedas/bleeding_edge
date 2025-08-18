; takes an array of any dimension or number of dimensions and
; replicates it  so it becomes an array with the dimension specified
; by the second argument.  For example,
; replicate_array, findgen (5), [2, 3], will result in a 5 x 2 x 3
; array where the initial array is copied into the second and third dimensions.

function replicate_array, x, extra_dimensions,  before =  before
  nd =  size (x, /n_dimensions)
  nex =  n_elements (extra_dimensions)
  dims =  size (x, /dimensions)
  type = size (x, /type)
  if keyword_set (before) then begin
     ans = make_array ([extra_dimensions,  dims],  $
                       type =  type) 
     
     if nd eq 1 then begin
        if nex eq 1 then begin
           for i =  0,  extra_dimensions [0] - 1 do ans [i, *] =  x
        endif else if nex eq 2 then begin
           for i =  0,  extra_dimensions [0] - 1 do begin
              for j =  0,  extra_dimensions [1] -1 do ans [i,  j, *] =  x
           endfor
        endif else if nex eq 3 then begin
           for i =  0,  extra_dimensions [0] - 1 do begin
              for j =  0,  extra_dimensions [1] -1 do begin
                 for k =  0,  extra_dimensions [2] -1 do ans [i,  j, k, *] =  x
              endfor
           endfor
        endif else if nex eq 4 then begin
           for i =  0,  extra_dimensions [0] - 1 do begin
              for j =  0,  extra_dimensions [1] -1 do begin
                 for k =  0,  extra_dimensions [2] -1 do begin
                    for l =  0,  extra_dimensions [3] -1 do ans [i,  j, k, l, *] =  x
                 endfor
              endfor
           endfor
        endif
     endif else if nd eq 2 then begin
        if nex eq 1 then begin
           for i =  0,  extra_dimensions [0] - 1 do ans [i, *, *] =  x
        endif else if nex eq 2 then begin
           for i =  0,  extra_dimensions [0] - 1 do begin
              for j =  0,  extra_dimensions [1] -1 do ans [i, j, *, *] =  x
           endfor
        endif else if nex eq 3  then begin
           for i =  0,  extra_dimensions [0] - 1 do begin
              for j =  0,  extra_dimensions [1] -1 do begin
                 for k =  0,  extra_dimensions [2] -1 do ans [i, j, k, *,*] =  x
              endfor
           endfor
        endif
     endif else if nd eq 3 then begin
        if nex eq 1 then begin
           for i =  0,  extra_dimensions [0] - 1 do ans [i,*, *,*] =  x
        endif else if nex eq 2 then begin
           for i =  0,  extra_dimensions [0] - 1 do begin
              for j =  0,  extra_dimensions [1] -1 do ans [i, j,*, *,*] =  x
           endfor
        endif else if nex eq 3 then begin
           for i =  0,  extra_dimensions [0] - 1 do begin
              for j =  0,  extra_dimensions [1] -1 do begin
                 for k =  0,  extra_dimensions [2] -1 do ans [i, j, k,*, *,  *] =  x
              endfor
           endfor
        endif
     endif else if nd eq 4 then begin
        if nex eq 1 then begin
           for i =  0,  extra_dimensions [0] - 1 do ans [i,*, *,*,*] =  x
        endif else if nex eq 2 then begin
           for i =  0,  extra_dimensions [0] - 1 do begin
              for j =  0,  extra_dimensions [1] -1 do ans [i, j,*, *,*,*] =  x
           endfor
        endif else if nex eq 3 then begin
           for i =  0,  extra_dimensions [0] - 1 do begin
              for j =  0,  extra_dimensions [1] -1 do begin
                 for k =  0,  extra_dimensions [2] -1 do ans [i, j, k,*, *,  *, *] =  x
              endfor
           endfor
        endif
     endif

  endif else begin
     ans = $
        make_array ([dims,  extra_dimensions],  type =  type)
     
     if nd eq 1 then begin
        if nex eq 1 then begin
           for i =  0,  extra_dimensions [0] - 1 do ans [*,  i] =  x
        endif else if nex eq 2 then begin
           for i =  0,  extra_dimensions [0] - 1 do begin
              for j =  0,  extra_dimensions [1] -1 do ans [*,  i,  j] =  x
           endfor
        endif else if nex eq 3 then begin
           for i =  0,  extra_dimensions [0] - 1 do begin
              for j =  0,  extra_dimensions [1] -1 do begin
                 for k =  0,  extra_dimensions [2] -1 do ans [*,  i,  j, k] =  x
              endfor
           endfor
        endif else if nex eq 4 then begin
           for i =  0,  extra_dimensions [0] - 1 do begin
              for j =  0,  extra_dimensions [1] -1 do begin
                 for k =  0,  extra_dimensions [2] -1 do begin
                    for l =  0,  extra_dimensions [3] -1 do ans [*, i,  j, k, l] =  x
                 endfor
              endfor
           endfor
        endif
     endif else if nd eq 2 then begin
        if nex eq 1 then begin
           for i =  0,  extra_dimensions [0] - 1 do ans [*, *,  i] =  x
        endif else if nex eq 2 then begin
           for i =  0,  extra_dimensions [0] - 1 do begin
              for j =  0,  extra_dimensions [1] -1 do ans [*, *,  i,  j] =  x
           endfor
        endif else if nex eq 3 then begin
           for i =  0,  extra_dimensions [0] - 1 do begin
              for j =  0,  extra_dimensions [1] -1 do begin
                 for k =  0,  extra_dimensions [2] -1 do ans [*, *,  i,  j, k] =  x
              endfor
           endfor
        endif else if nex eq 4 then begin
           for i =  0,  extra_dimensions [0] - 1 do begin
              for j =  0,  extra_dimensions [1] -1 do begin
                 for k =  0,  extra_dimensions [2] -1 do begin
                    for l =  0,  extra_dimensions [3] -1 do ans [*, *,  i,  j, k, l] =  x
                 endfor
              endfor
           endfor
        endif
     endif else if nd eq 3 then begin
        if nex eq 1 then begin
           for i =  0,  extra_dimensions [0] - 1 do ans [*, *,*,  i] =  x
        endif else if nex eq 2 then begin
           for i =  0,  extra_dimensions [0] - 1 do begin
              for j =  0,  extra_dimensions [1] -1 do ans [*, *,*,  i,  j] =  x
           endfor
        endif else if nex eq 3 then begin
           for i =  0,  extra_dimensions [0] - 1 do begin
              for j =  0,  extra_dimensions [1] -1 do begin
                 for k =  0,  extra_dimensions [2] -1 do ans [*, *,  *, i,  j, k] =  x
              endfor
           endfor
        endif
     endif else if nd eq 4 then begin
        if nex eq 1 then begin
           for i =  0,  extra_dimensions [0] - 1 do ans [*, *,*,*,  i] =  x
        endif else if nex eq 2 then begin
           for i =  0,  extra_dimensions [0] - 1 do begin
              for j =  0,  extra_dimensions [1] -1 do ans [*, *,*,*,  i,  j] =  x
           endfor
        endif else if nex eq 3 then begin
           for i =  0,  extra_dimensions [0] - 1 do begin
              for j =  0,  extra_dimensions [1] -1 do begin
                 for k =  0,  extra_dimensions [2] -1 do ans [*, *,  *, *, i,  j, k] =  x
              endfor
           endfor
        endif
     endif
  endelse
  return,  ans
end



    
