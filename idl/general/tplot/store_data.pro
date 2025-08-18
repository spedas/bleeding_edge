;+
;PROCEDURE:  store_data,name,DATA=data,LIMITS=limits,DLIMITS=dlimits,
;     NEWNAME=newname,DELETE=delete
;PURPOSE:
;   Store time series structures in static memory for later retrieval
;   by the tplot routine.  Three structures can be associated with the
;   string 'name':  a data structure (DATA) that typically contains the x and
;   y data. A default limits structure (DLIMITS) and a user limits structure
;   (LIMITS) that will typically contain user defined limits and options
;   (typically plot and oplot keywords).  The data structure and the default
;   limits structure will be
;   over written each time a new data set is loaded.  The limit structure
;   is not over-written.
;INPUT:
;   name:   string name to be associated with the data structure and/or
;     the limits structure.  Also, can enter tplot index as name.
;     The name should not contain spaces or the characters '*' and '?'
;KEYWORDS:
;    DATA:  variable that contains the data structure.
;    LIMITS; variable that contains the limit structure.
;    DLIMITS; variable that contains the default limits structure.
;    NEWNAME: new tplot handle.  Use to rename tplot names.
;    DELETE: array of tplot handles or indices to delete from common block.
;    CLEAR:  Set this keyword to erase the data structure but not the LIMITS or DLIMITS structures
;    TAGNAMES: Set this keyword to a string containing tagnames that are to be extracted from an array of
;       structures passed in through the DATA structure.  Use TAGNAMES='*' to extract all tagnames.
;    MIN: if set, data values less than this value will be made NaN.               (obsolete)
;    MAX: if set, data values greater than this value will be made NaN.            (obsolete)
;    NOSTRSW: if set, do not transpose multidimensional data arrays in             (obsolete)
;         structures.  The default is to transpose.
;    ERROR: if set returns error code for store_data, values are:
;    0=NO ERROR
;    1=INVALID HANDLE ERROR
;    2=OTHER ERROR
;
;SEE ALSO:    "GET_DATA", "TPLOT_NAMES",  "TPLOT", "OPTIONS"
;
;CREATED BY:    Davin Larson
; $LastChangedBy: davin-mac $
; $LastChangedDate: 2024-11-01 10:10:49 -0700 (Fri, 01 Nov 2024) $
; $LastChangedRevision: 32918 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/tplot/store_data.pro $
;-
pro store_data,name, time,ydata,values, $
  data = data, $
  append=append, $
  tagnames = tagnames, $
  seperator = seperator, $
  time_tag = time_tag, $
  vardef = vardef, $
  gap_tag  = gap_tag,  $
  val_tag  = val_tag,  $
  limits= limits, $
  dlimits = dlimits, $
  newname = newname, $
  min=min, max=max, $
  delete = delete, $
  clear = clear, $
  verbose = verbose_t, $
  nostrsw = nostrsw,$
  except_ptrs = except_ptrs, $
  error=error, $
  silent=silent

  compile_opt idl2, hidden

  @tplot_com.pro

  error = 0

  if size(verbose_t,/type) eq 0 then begin
    str_element,tplot_vars,'options.verbose',verbose ; get default verbose value if it exists
  endif else verbose = verbose_t

  if size(/type,tagnames) eq 7 then begin
    if isa(data,'dynamicarray') then begin
      if size(/type,time_tag) ne 7 then time_tag = 'TIME'
      if data.size eq 0 then begin
        dprint,verbose=verbose,dlevel=1,name,': Dynamic array has no data. Unable to create tplot variables for "',data.name,'"'
        return
      endif
      data_sample = data.slice(/last)
      tags = tag_names( data_sample )
      ok   = strfilter(tags,strupcase(tagnames),delimiter=' ',/byte)
      if ~keyword_set(seperator) then seperator = '_'
      ;nd = size(/n_elements,data)
      for i=0,n_elements(tags)-1 do begin
        if ok[i] eq 0 then continue
        if tags[i] eq strupcase(time_tag) then continue
        if keyword_set(gap_tag) && tags[i] eq gap_tag then continue
        vardef = dictionary('X',time_tag,'Y',tags[i])   
        if isa(val_tag,/string) && total(tags[i]+strupcase(val_tag) eq tags,/pres) ne 0 then begin
          vardef.v = tags[i]+strupcase(val_tag)
        endif 
        y = data_sample.(i)
        if size(/type,y) eq 10 then continue   ; ignore pointers
        ;if size(/type,y) eq 7 then continue    ; ignore strings
        if size(/type,y) eq 8  then begin      ; ignore substructures for now
          continue
          ;str_element,/add,y,'time',time
          ;store_data,name+seperator+tags[i],data=y,tagnames = '*',seperator='.'
        endif
        store_data,name+seperator+tags[i],data=data,vardef=vardef,verbose=verbose,silent=silent

      endfor
      return

    endif else if size(/type,data) ne 8 then begin
      dprint,dlevel=2,'Variable "'+name +'":  Data must be a structure or dynamicarray object'
      return
    endif
    ;printdat,data,tagnames
    if size(/type,time_tag) ne 7 then time_tag = 'TIME'
    ;  if size(/type,gap_tag) ne 7 then gap_tag = 'GAP'
    tags = tag_names(data)
    str_element,data,time_tag,time    ;  time = data.time
    ok   = strfilter(tags,strupcase(tagnames),delimiter=' ',/byte)
    if ~keyword_set(seperator) then seperator = '_'
    nd = size(/n_elements,data)
    for i=0,n_elements(tags)-1 do begin
      if ok[i] eq 0 then continue
      if tags[i] eq time_tag then continue
      if keyword_set(gap_tag) && tags[i] eq gap_tag then continue
      y = data.(i)
      if size(/type,y) eq 10 then continue   ; ignore pointers
      ;if size(/type,y) eq 7 then continue    ; ignore strings
      if size(/type,y) eq 8  then begin      ; recursively handle substructures
        str_element,/add,y,'time',time
        store_data,name+seperator+tags[i],data=y,tagnames = '*',seperator='.'
        continue
      endif
      dimy = size(/n_dimen,y)
      if dimy eq 2 || nd eq 1 then begin
        y = transpose([y])
        ;       dimy2 = size(/dimen,y)
        ;       v = findgen(dimy2[1])
      endif ;else undefine,v
      dl=0
      str_element,dlimits,tags[i],dl
      store_data,name+seperator+tags[i],time,y,v,append=append,dlimit=dl,verbose=verbose
    endfor
    return
  endif

  ;dprint,dlevel=5,verbose,/phelp

  if keyword_set(clear) then begin
    names = tnames(name,n)
    for i=0,n-1 do begin
      index = find_handle(names[i])
      if index gt 0 then begin
        dq = data_quants[index]
        ptr = *dq.dh
        if not(keyword_set(silent)) then dprint,dlevel=2,verbose=verbose,'Clearing: ',names[i]
        if size(/type,ptr) eq 8 then tags = tag_names(ptr) else undefine,tags
        for j=0,n_elements(tags)-1 do begin
          if size(ptr.(j),/type) eq 10 then  *(ptr.(j)) = 0  $
          else  (*dq.dh).(j) = 0
        endfor
        dq.trange = !values.d_nan
        dq.create_time = systime(1)
        data_quants[index] = dq
      endif else message,'This should never occur'
    endfor
    return
  endif

  if keyword_set(delete) then begin
    if n_elements(name) ne 0 then delete=name
    delnames = tnames(delete,cnt)
    if cnt ne 0 then begin
      au = array_union(data_quants.name,delnames)
      savevars = where(au eq -1)
      delevars = where(au ne -1)
      saveptrs = ptr_extract(except_ptrs)
      saveptrs = [saveptrs,ptr_extract(data_quants[savevars])]
      delptrs = ptr_extract(data_quants[delevars],except=saveptrs)
      data_quants=data_quants[savevars]
      ptr_free,delptrs
      if not(keyword_set(silent)) then dprint,dlevel=1,verbose=verbose,'Deleted ',cnt,' variables'
    endif else dprint,dlevel=1,verbose=verbose,'No matching variables to delete'
    return
  endif


  dt = size(name,/type)
  if size(name,/n_dimen) ne 0 then begin
    dprint,verbose=verbose,'Input name must be scalar!'
    error=1
    return
  endif

  if dt eq 7 then begin
    if name eq '' then begin
      dprint, verbose=verbose, 'Invalid name: Cannot use empty string to name tplot variable'
      error=1
      return
    endif
    if total( array_union(byte(name),byte(' *?[]\'))  ge 0) then begin
      dprint,verbose=verbose,'Invalid name: "'+name+'"; Name may not contain spaces, or the characters: "* ? [ ] \"'
      invc = [' ', '*', '?', '[', ']', '\']
      For ii = 0, n_elements(invc)-1 Do name = ssw_str_replace(name, invc[ii], '$')
      dprint, verbose=verbose,'Replaced invalid characters with $, name: '+name
        ;       error = 1
        ;       return
      endif
    if n_elements(data_quants) eq 0 then index = 0 else  index = find_handle(name)
  endif else if (dt ge 1) and (dt le 3) then begin
    index = name
    name = data_quants[index].name
  endif else if not keyword_set(delete) then begin
    dprint,dlevel=2,verbose=verbose,'Invalid handle name or index'
    error=1
    return
  endif

  dq = {tplot_quant}

  if n_elements(data_quants) eq 0 then data_quants = [dq]


  if index eq 0 then begin        ; new variable
    orig_name = name+'x'          ; required due to compile bug in early versions of IDL
    dq.name = strmid(orig_name,0,strlen(name))
    ;  if keyword_set(verbose) then print,'Creating new tplot variable: ',dq.name
    verb = 'Creating'
    dq.dh = ptr_new(0)  ;/allocate)
    dq.lh = ptr_new(0)  ;/allocate)
    dq.dl = ptr_new(0)  ;/allocate)
    data_quants = [data_quants,dq]
    index = n_elements(data_quants) - 1
    dq.trange = !values.d_nan
    dq.create_time = systime(1)
  endif else begin
    dq = data_quants[index]
    if keyword_set(append) then verb = 'Appending' else verb = 'Altering'
  endelse

  if n_params() ge 3 then begin
    if keyword_set(append) &&  keyword_set( *dq.dh ) && keyword_set(*(*dq.dh).x) then begin
      ;        dqdh = (*dq.dh)
      ;        oldind= dqdh.x_ind
      if append eq 2 then begin
        append_array,*(*dq.dh).x, !values.d_nan  , index=(*dq.dh).x_ind ,new_index=ind ,/fillnan   &   (*dq.dh).x_ind = ind
        append_array,*(*dq.dh).y, fill_nan(ydata), index=(*dq.dh).y_ind ,new_index=ind ,/fillnan   &   (*dq.dh).y_ind = ind
        ;    dprint,dlevel=2,'Data gap in ',dq.name,ind
      endif
      append_array,*(*dq.dh).x, time , index=(*dq.dh).x_ind ,new_index=ind ,/fillnan
      (*dq.dh).x_ind = ind
      append_array,*(*dq.dh).y, ydata, index=(*dq.dh).y_ind ,new_index=ind ,/fillnan ,error = error
      if keyword_set(error) && debug(3) then begin
        printdat,name
      endif
      (*dq.dh).y_ind = ind
      ;    dprint,dlevel=3,'Normal in ',dq.name,ind
      ;        if keyword_set(values) then append_array,*dqdh.v,values,index = *dqdy.v_ind,/fill_nan
      ;        dprint,dlevel=4,verbose=verbose,'Appending to ',name
      dq.trange = minmax([dq.trange,time])
      data_quants[index] = dq
      ;        tplot_panel,time,ydata,var= name,psym=-3   ; real time plotting
      return
    endif
    if keyword_set(data) then dprint,'Warning! Data keyword ignored!'
    data = {x:time, y:ydata}                ; First time appending uses normal method
    if n_elements(values) ne 0 then data = create_struct(data,'v',values)
  endif


  if keyword_set(min) then begin
    bad = where(data.y lt min,c)
    if c ne 0 then data.y[bad] = !values.f_nan
  endif

  if keyword_set(max) then begin
    bad = where(data.y gt max,c)
    if c ne 0 then data.y[bad] = !values.f_nan
  endif


  ; set values:
  if n_elements(newname) ne 0 then begin
    if total( array_union(byte(newname),byte(' *?[]\'))  ge 0) then begin
      dprint,verbose=verbose,dlevel=0,'Invalid name: "'+name+'"; Name may not contain spaces, or the characters: "* ? [ ] \"'
      error=2
      return
    endif
    nindex = where(data_quants.name eq newname, count)
    if count gt 0 then begin
      dprint,verbose=verbose,dlevel=0,'New name must not already be in use!'
      error=2
      return
    endif else dq.name = newname
  endif

  if n_elements(limits) ne 0 then *dq.lh = limits
  if n_elements(dlimits) ne 0 then *dq.dl = dlimits
  
  if isa(data,'DYNAMICARRAY') then begin
    if ~isa(time_tag,'STRING') then time_tag='time'
    if ~isa(data_tag,'STRING') then data_tag='data'
    if ~(keyword_set(silent)) then begin
      dprint,verbose=verbose,dlevel=1,verb+' tplot variable: '+strtrim(index,2)+' '+dq.name+' from DynamicArray: "'+data.name+'"'
    endif
    if ~isa(vardef,'dictionary') then vardef = dictionary('x',time_tag,'y',data_tag)
    dh = {ddata:data,vardef:vardef}
    *dq.dh = dh
    dq.dtype = 4
    sz = dh.ddata.size
    str_fl = dh.ddata.slice([0,sz-1])
;    dq.trange = (dh.ddata.slice([0,sz-1])).time
    tags = tag_names(str_fl)
    tag_num =  where(/null,tags eq strupcase(vardef.x))
    if isa(tag_num) then dq.trange = str_fl.(tag_num) + [-1,1]

    dq.create_time = systime(1)
    data_quants[index] = dq
    return
  endif else if n_elements(data) ne 0 then begin
    undefine, save_ptrs          ;save_ptrs test later, jmm, 2017-09-25
    if not(keyword_set(silent)) then $
      dprint,verbose=verbose,dlevel=1,verb+' tplot variable: ',strtrim(index,2),' ',dq.name
    dq.create_time = systime(1)
    if size(/type,data) eq 8 then begin  ; structures
      mytags = tag_names(data)
      myptrstr = 0
      for i = 0, n_elements(mytags) - 1 do begin
        newv = data.(i)    ;  faster than:   str_element,data,mytags(i),foo
        dim_newv = size(/dimension,newv)
        oldp = ptr_new()   ; this line is not necessary
        str_element,*dq.dh,mytags[i],oldp
        if ptr_valid(oldp) then begin ;test for existing pointers if oldp exists, jmm, 2017-09-25
          if undefined(save_ptrs) then begin ;get save_ptrs once for a given variable
            save_ptrs = ptr_extract(except_ptrs)
            save_ptrs = [save_ptrs, ptr_extract(limits)]
            save_ptrs = [save_ptrs, ptr_extract(dlimits)]
            save_ptrs = [save_ptrs, ptr_extract(data)]
            save_ptrs = [save_ptrs, ptr_extract(data_quants[where(data_quants.name ne dq.name)])]
          endif
        endif
        if size(/type,newv) ne 10 then begin       ; newv is not a pointer
          if(ptr_valid(oldp)) then ptr_free,ptr_extract(oldp,except=save_ptrs) ;free old stuff (if any exist)
          newv = ptr_new([newv],/no_copy)
        endif else begin ; newv is a pointer
          if ptr_valid(oldp) && oldp ne newv then ptr_free,ptr_extract(oldp,except=save_ptrs)
        endelse
        str_element,/add_replace,myptrstr,mytags[i],newv
        if strpos(mytags[i],'_IND') lt 0 then str_element,/add_replace,myptrstr,mytags[i]+'_ind',dim_newv[0] > 1
      endfor
      *dq.dh = myptrstr
    endif else *dq.dh = data
  endif

  ;if n_elements(data) ne 0 then if data_type(data) eq 10 then $
  ;   dq.dh = data else *dq.dh = data

  extract_tags,dstr,data      ; this command can be extremely time consuming and should be removed
  extract_tags,dstr,dlimits
  extract_tags,dstr,limits


  str_element,dstr,'x',value=x
  str_element,dstr,'y',value=y
  if size(/type,x) eq 10 then if ptr_valid(x) then x=*x
  if size(/type,y) eq 10 then if ptr_valid(y) then y=*y
  if n_elements(x) ne 0 and n_elements(y) ne 0 then begin
    dq.dtype = 1
    dq.trange = minmax(x)
  endif
  str_element,dstr,'time',value=time0
  if size(/type,time0) eq 10 then time0=*time0
  if n_elements(time0) ne 0 then begin                ; obsolete format of passing in an array of structures
    dq.dtype = 2
    dprint, dlevel=0,'Obsolete storage method. Use TAGNAMES keyword to use arrays of structures. May be disabled in the future'
    dq.trange = minmax(time0)
    dqtags = tag_names(*dq.dh)
    data_quants[index] = dq
    for i=0,n_elements(dqtags)-1 do if dqtags[i] ne 'TIME' then begin
      subname = dq.name+'.'+dqtags[i]
      str_element,*dq.dh,dqtags[i],foo
      if(ptr_valid(foo)) then begin ;there is a variable here, otherwise do nothing
        if ndimen(*foo) ne 1 then $
          if dimen((*foo)[0]) ne n_elements(time0) then $
          if keyword_set(NOSTRSW) eq 0 then $
          *foo = transpose(*foo)
        dl=0
        str_element,dlimits,dqtags[i],dl
        ;  dprint,dlevel=2,phelp=3,subname,dl,foo,time0
        store_data,subname,data={x: time0, y:foo},   dlimits= dl ;*dq.dl, limits=*dq.lh
      endif
    endif
  endif

  if size(/type,data) eq 7 then begin
    dq.dtype = 3
    names = tnames(data,trange=tr)
    dprint,verbose=verbose,dlevel=2,'Multi-'+' tplot variable: ',strtrim(index,2),' ',dq.name,' : ' ,names
    dq.trange = minmax(tr)
  endif

  data_quants[index] = dq

  ;pos = strpos(name,'.')
  ;if (pos gt 0) then begin
  ;   names = strarr(2)
  ;        names(0) = strmid(name,0,pos)
  ;        names(1) = strmid(name,pos+1,100)
  ;   superind = find_handle(names(0))
  ;   dq.trange = data_quants(superind).trange
  ;endif

end
