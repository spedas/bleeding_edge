FUNCTION nn,data,time,x=x,y=y,v=v,progress=progress   ;nearest neighbor function
;+
;NAME:                  nn
;PURPOSE:               Find the index of the data point(s) nearest to the specified time(s)
;                       You can use find_nearest_neighbor2 function to find the nearest time.
;
;                       This routine can be inefficient when operating on large arrays.  In
;                       such cases it is better, if possible, to divide the time arrays into
;                       smaller segments and work on one segment at a time.
;                       
;CALLING SEQUENCE:      ind=nn(data,time)
;INPUTS:                data:  a data structure, a tplot variable name/index,
;                          or a time array
;                       time:  (double) seconds from 1970-01-01, scalar or array
;                              if not present, "ctime" is called to get time(s)
;OPTIONAL INPUTS:       none
;KEYWORD PARAMETERS:    x, y, & v:  set to named keywords to return the values
;			of the x, y, & v arrays, if applicable
;
;                       progress: If set, then report progress in increments of 1%.
;                                 No effect when n_elements(time) lt 100.
;			
;OUTPUTS:               a long scalar index or long array of indicies
;                       on failure, returns: -2 if bad inputs, 
;                                            -1 if nearest neighbor not found
;EXAMPLE:               ctime,times,npoints=2
;                       inds=nn('Np',times)
;                       get_data,'Np',data=dens & get_data,'Tp',data=temp
;                       plot,dens.y(inds(0):inds(1)),temp(inds(0):inds(1))
;LAST MODIFICATION:     @(#)nn.pro	1.8 02/04/17
;CREATED BY:            Frank Marcoline
; 
; See also:
;   find_nearest_neighbor2, find_nearest_neighbor
; 
; $LastChangedBy: jwl $
; $LastChangedDate: 2025-08-20 11:11:05 -0700 (Wed, 20 Aug 2025) $
; $LastChangedRevision: 33563 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/misc/nn.pro $
;-
  nd = n_elements(data)         ;1 if a str, more if an array

; There is a possible ambiguity if nd = 1.  Data could refer to a tplot variable index,
; or it could refer to a single time.  So, use the data type again.  Assume a single
; integer is a tplot variable index.  Anything else is a time.  (Note: The code assumes
; that tplot variable indices are never double-longs [data type 14].)  Of course, it's
; pointless to search for the nearest neighbor to a single time, but this limiting case 
; could occur when processing large data sets.

  dtype = size(data,/type)

  case dtype of 
    0: begin 
        dprint, 'Must supply input data'
        return,-2
       end 
    8: begin 
         if data_type(data.x) eq 10 then begin ;struct of pointers
           tn = tag_names(data)                ;remake the struct w/o pointers
	       for i=0,n_tags(data)-1 do str_element,/add,dat,tn[i],*data.(i)
         endif else dat = data                 ;input is a standard tplot structure
       end
    7: get_data,data,data=dat                  ;input is a tplot variable name
    6: begin 
         dprint, 'Can''t handle complex inputs'
         help,data
         return,-2
       end
    else: begin
            if nd eq 1 then begin
              if (dtype lt 4) then begin
                get_data,data[0],data=dat,index=k
                if (k eq 0) then begin
                  dprint, 'Input does not refer to a tplot variable.'
                  return,-2
                endif
              endif else dat = {x:time_double(data[0])}
            endif else dat = {x:time_double(data)}
          end
  endcase 

  t = time_double(time)
  n = n_elements(t)
  if n eq 1 then inds = 0l else inds = lonarr(n)

  if keyword_set(progress) and (n ge 100) then begin
    k = 0
    onepct = n/100L
    cr = string(13B)
    for i=0l,n-1l do begin
      a = abs(dat.x-t[i])
      b = min(a,c)                ;c contains the index to b
      inds[i] = c
      if ~(i mod onepct) then print, cr, k++, format='(a,i5," % ",$)'
    endfor
    print, cr + "  100 % "
  endif else begin
    for i=0l,n-1l do begin 
      a = abs(dat.x-t[i])
      b = min(a,c)                ;c contains the index to b
      inds[i] = c
    endfor
  endelse

  tn = tag_names(dat)
  if arg_present(x) then x = dat.x[inds]
  if arg_present(y) then if (where(tn eq 'Y'))[0] ne -1 then y = dat.y[inds,*,*]
  if arg_present(v) then if (where(tn eq 'V'))[0] ne -1 then begin 
    if ndimen(dat.v) eq 2 then v = dat.v[inds,*] else v = dat.v
  endif
  return,inds
end
