FUNCTION nn,data,time,x=x,y=y,v=v   ;nearest neighbor function
;+
;NAME:                  nn
;PURPOSE:               Find the index of the data point(s) nearest to the specified time(s)
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
;OUTPUTS:               a long scalar index or long array of indicies
;                       on failure, returns: -2 if bad inputs, 
;                                            -1 if nearest neighbor not found
;EXAMPLE:               ctime,times,npoints=2
;                       inds=nn('Np',times)
;                       get_data,'Np',data=dens & get_data,'Tp',data=temp
;                       plot,dens.y(inds(0):inds(1)),temp(inds(0):inds(1))
;LAST MODIFICATION:     @(#)nn.pro	1.8 02/04/17
;CREATED BY:            Frank Marcoline
;-
  nd = n_elements(data)         ;1 if a str, more if an array

  case data_type(data) of 
    0: begin 
      dprint, 'Must supply input data'
      return,-2
    end 
    8: begin 
      if data_type(data.x) eq 10 then begin ;struct of pointers
        tn = tag_names(data)                ;remake the struct w/o pointers
	for i=0,n_tags(data)-1 do str_element,/add,dat,tn(i),*data.(i)
      endif else dat = data           ;input is a standard tplot structure
    endcase 
    7: get_data,data,data=dat       ;
    6: begin 
      dprint, 'Can''t handle complex inputs'
      help,data
      return,-2
    endcase
    else: if nd gt 1 then dat = {x:data} else get_data,data(0),data=dat
  endcase 

  t = time_double(time)
  n = n_elements(t)
  if n eq 1 then inds = 0l else inds = lonarr(n)

  for i=0l,n-1l do begin 
    a = abs(dat.x-t(i))
    b = min(a,c)                ;c contains the index to b
    inds(i) = c
  endfor 

  tn = tag_names(dat)
  if arg_present(x) then x = dat.x(inds)
  if arg_present(y) then if (where(tn eq 'Y'))(0) ne -1 then y = dat.y(inds,*,*)
  if arg_present(v) then if (where(tn eq 'V'))(0) ne -1 then begin 
    if ndimen(dat.v) eq 2 then v = dat.v(inds,*) else v = dat.v
  endif
  return,inds
end
