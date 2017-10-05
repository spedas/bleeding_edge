;+
;Procedure: minvar_matrix_make
;
;Purpose: tplot wrapper for minvar.pro.  This routine generates a
;matrix or set of matrices from a time series of 3-d vector data that
;will transform three dimensional data into a minimum variance
;coordinate system.  This routine takes a tplot variable that stores 3 
;dimensional vector data as an argument and produces a tplot variable
;storing the transformation matrix or matrices.
;
;The minimum variance coordinate system is taken by generating the covariance
;matrix for an interval of data.  This matrix is then diagonalized to
;identify the eigenvalues and eigenvectors of the covariance matrix.
;The eigenvector with the smallest eigenvalue will form the direction
;of the z component of the new coordinate system.  The eigenvector
;with the largest eigenvalue will form the direction of the x
;component of the new coordinate system.  The third eigenvector will
;form the y direction of the coordinate system.
;
;Warning:  The resulting transformation matrices will only correctly
;transform data from the coordinate system of the input variable to
;the minimum variance coordinate system.  So if in_var_name is in gse 
;coordinates then you should only use the output matrices to transform
;other data in gse coordinates.
;
;Arguments:
;       in_var_name: the name of the tplot variable holding the input
;       data, can be any sort of timeseries 3-d data
;
;       tstart(optional): the start time of the data you'd like to
;       consider for generating the transformation matrix(defaults to
;       minimum time of in_var timeseries)
;
;       tstop(optional): the stop time of the data you'd like to
;       consider for generating the transformation matrix(defaults to
;       maximum time of in_var timeseries)
;
;       twindow(optional): the size of the window(in seconds) you'd like to
;       consider when using a moving boxcar average to generate
;       multiple transformations. (defaults to the entire time series)
;
;       tslide(optional):  the number of seconds the boxcar should
;       slide forward after each average.(defaults to twindow/2)
;       set tslide=0 to cause the program to generate only a single
;       matrix
;
;       newname(optional): the name of the tplot variable in which to
;       store the transformation matrix(matrices) (defaults to
;       in_var_name+'_mva_mat'
;
;       evname(optional): the name of the tplot variable in which to
;       store the eigenvalues of the mva matrix(matrices) (defaults to
;       nowhere, ie if unset doesn't store them
;
;       error(optional): named variable that holds the error state of
;       the computation, 1=success 0 = failure
;
;       tminname(optional): name of a tplot variable in which you would
;       like to store the minimum variance direction vectors this
;       vector will be represented in the original coordinate system
;
;       tmidname(optional):  name of a tplot variable in which you would
;       like to store the intermediate variance direction vectors this
;       vector will be represented in the original coordinate system
;
;       tmaxname(optional): name of a tplot variable in which you would
;       like to store the minimum variance direction vectors this
;       vector will be represented in the original coordinate system
;
;
;  SEE ALSO:
;     minvar.pro
;     tvector_rotate.pro
;     thm_crib_mva.pro (THEMIS project) 
;
; $LastChangedBy: aaflores $
; $LastChangedDate: 2014-06-06 17:26:00 -0700 (Fri, 06 Jun 2014) $
; $LastChangedRevision: 15328 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/cotrans/special/minvar/minvar_matrix_make.pro $
;-

pro minvar_matrix_make,in_var_name,tstart=tstart,tstop=tstop,twindow=twindow,tslide=tslide,newname=newname,evname=evname,error=error,tminname=tminname,tmidname=tmidname,tmaxname=tmaxname

error = 0

if not keyword_set(in_var_name) then begin
    dprint,' fx requires in_var_name to be set'
    return
endif

if tnames(in_var_name) eq '' then begin
    dprint,' fx requires in_var_name to be set'
    return
endif

get_data,in_var_name,data=d,limits=l,dlimits=dl

d_s = size(d.y,/dimensions)

if n_elements(d_s) ne 2 then begin
    dprint,' fx requires in_var_name.y to have 2 dimensions'
    return
endif

if d_s[1] ne 3 then begin
    dprint,' fx requires cardinality of the second dimensions of in_var_name.y to equal 3'
    return
endif

if not keyword_set(tstart) then start_d = d.x[0] $
else start_d = time_double(tstart)

if not keyword_set(tstop) then stop_d = d.x[n_elements(d.x)-1L] $
else stop_d = time_double(tstop)

if(start_d ge stop_d) then begin
  dprint, 'fx requires tstart to be greater than or equal to tstop'
  return
endif

if not keyword_set(twindow) then twindow = stop_d - start_d

;sets it to something large enough that it will only generate one
;matrix in the default case
if not keyword_set(tslide) then tslide = twindow/2

if not keyword_set(newname) then newname = in_var_name+'_mva_mat'

current_d = start_d

;estimate the number of output matrices to generate temporary storage
if tslide ne 0 then $
  o_num = (stop_d - start_d) / tslide $
else $
  o_num = 1



o_times = dindgen(o_num)  ;allocate output storage space

o_lams = dindgen(o_num, 3)

o_eigs = dindgen(o_num, 3, 3)

i =  0

while(current_d + twindow le stop_d) do begin ;loop over time windows

  if(i ge o_num) then begin ;output storage should never exceed allocated space
    dprint, ' fx output array index out of bounds'
    return
  endif

  o_times[i] = current_d + twindow/2 ;output time for the mva matrix is the midpoint time for the interval

  idx = where(d.x ge current_d and d.x le current_d + twindow)

  if(size(idx, /n_dim) eq 0 && idx eq -1L) then begin
  
    ;non-fatal, this prevents output spam
    ;dprint, 'fx had where index error'
    
    current_d += tslide
    i++
    continue

  endif

  in_data = transpose(d.y[idx, *]) ;minvar takes dimensions transposed from tplot storage convention

  minvar, in_data, o_eig, lambdas2 = o_lam

  o_lam = reform(o_lam) ;minvar returns a 1x3 array instead of just a 3-d array

;the conditionals below should never fail, but it doesn't hurt to test
  if not array_equal(size(o_eig, /dimensions), [3, 3]) then begin
    dprint, 'minvar produced transformation matrix with wrong dimensions'
    return
  endif

  if not array_equal(size(o_lam, /dimensions), [3]) then begin
    dprint, 'minvar produced lambda matrix with wrong dimensions'
    return
  endif

  ;o_eigs[i, *, *] = o_eig
  o_eigs[i, *, *] = transpose(o_eig)


  o_lams[i, *] = o_lam

  i++ ;increment output storage index

  current_d += tslide          ;increment loop variable 

  if(tslide eq 0) then break
  
endwhile


str_element,d,'v',SUCCESS=s

if(s) then $
  o_d = {x:o_times[0:i-1L], y:o_eigs[0:i-1L, *, *], v:d.v} $
else $
  o_d = {x:o_times[0:i-1L], y:o_eigs[0:i-1L, *, *]}

if keyword_set(dl) then begin
o_dl = dl
endif else begin

datt = {coord_sys:'unknown'}
o_dl = {data_att:datt}

endelse

str_element,o_dl,'data_att.coord_sys',success=s

if s eq 1 then begin
  str_element,o_dl,'data_att.source_sys',o_dl.data_att.coord_sys,/add_replace
endif

str_element,o_dl,'data_att.coord_sys','minvar',/add_replace

str_element,o_dl,'labels',SUCCESS=s

if s then begin
  o_dl.labels = ['maxvar','midvar','minvar'] 
endif else begin
  str_element,o_dl,'labels',['maxvar','midvar','minvar'],/add
endelse
  
str_element,o_dl,'labflag',SUCCESS=s

if s then begin 
  o_dl.labflag = 1 
endif else begin
  str_element,o_dl,'labflag',1,/add
endelse

str_element,o_dl,'colors',SUCCESS=s

if s then begin 
  o_dl.colors = [2,4,6] 
endif else begin
  str_element,o_dl,'colors',[2,4,6],/add
endelse

store_data, newname, data = o_d, limits = l, dlimits = o_dl

if keyword_set(evname) then begin


    str_element,d,'v',SUCCESS=s

    if(s) then $
      e_d = {x:o_times[0:i-1L], y:o_lams[0:i-1L, *], v:d.v} $
    else $
      e_d = {x:o_times[0:i-1L], y:o_lams[0:i-1L, *]}

  e_dl = dl

  e_dl.data_att.coord_sys = 'minvar'

  store_data, evname, data = e_d, limits = l, dlimits = e_dl

endif

if keyword_set(tminname) then begin

    
    str_element,d,'v',SUCCESS=s

    if(s) then $
      tm_d = {x:o_times[0:i-1L], y:reform(o_eigs[0:i-1L, 2, *],i,3), v:d.v} $
    else $
      tm_d = {x:o_times[0:i-1L], y:reform(o_eigs[0:i-1L, 2, *],i,3)}

  store_data, tminname, data = tm_d, limits = l, dlimits = dl

endif

if keyword_set(tmidname) then begin


    str_element,d,'v',SUCCESS=s

    if(s) then $
      tm_d = {x:o_times[0:i-1L], y:reform(o_eigs[0:i-1L, 1, *],i,3), v:d.v} $
    else $
      tm_d = {x:o_times[0:i-1L], y:reform(o_eigs[0:i-1L, 1, *],i,3)}

  store_data, tmidname, data = tm_d, limits = l, dlimits = dl

endif

if keyword_set(tmaxname) then begin

    
    str_element,d,'v',SUCCESS=s

    if(s) then $
      tm_d = {x:o_times[0:i-1L], y:reform(o_eigs[0:i-1L, 0, *],i,3), v:d.v} $
    else $
      tm_d = {x:o_times[0:i-1L], y:reform(o_eigs[0:i-1L, 0, *],i,3)}

  store_data, tmaxname, data = tm_d, limits = l, dlimits = dl

endif

;if we make it all the way to the end success!!!
error = 1

end
