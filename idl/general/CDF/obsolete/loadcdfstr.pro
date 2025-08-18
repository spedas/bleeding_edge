;+
;PROCEDURE:	loadcdfstr
;PURPOSE:
;  loads data from specified cdf file into a structure.
;INPUT:
;	x:		A named variable to return the structure in
;	novardata:	A named variable to return the non-varying
;			data.
;
;KEYWORDS:
;       FILENAMES:  [array of] CDF filename[s].  (or file id's)
;	PATH:	    CDF file path.
;       VARNAMES:   [array of] CDF variable name[s] to be loaded.
;	NOVARNAMES: [array of] CDF non-varying field names.
;       TAGNAMES:   optional array of structure tag names.
;	NVTAGNAMES: optional array of non-varying structure tag names.
;	RESOLUTION: resolution to return in seconds.
;	APPEND:     if set, append data to the end of x.
;       TIME:     If set, will create tag TIME using the Epoch variable.
;SEE ALSO:
;  "loadcdf2", "loadallcdf", "print_cdf_info","make_cdf_index"
;
;CREATED BY:	Davin Larson
; $LastChangedBy: ali $
; $LastChangedDate: 2021-05-30 19:48:04 -0700 (Sun, 30 May 2021) $
; $LastChangedRevision: 30012 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/CDF/obsolete/loadcdfstr.pro $
;-

pro loadcdfstr,data0,novardata  $
  ,filenames=cdf_files $
  ,path=path  $
  ,varnames=cdf_vars,tagnames=tagnames $
  ,novarnames=novarnames $
  ,resolution = res $
  ,median = med $
  ,filter_proc = filter_proc $
  ,append=append,time=time, nvtagnames=nvtagnames $
  ,novarznames=novarznames, nvztagnames=nvztagnames

  if n_elements(cdf_files) eq 0 then cdf_files=pickfile(filter="*.cdf",path=path,get_path=path)

  ;on_ioerror,skip

  if keyword_set(append) then index=n_elements(data0)

  for num = 0,n_elements(cdf_files)-1 do begin

    cdf_file = cdf_files[num]
    id = 0

    if size(/type,cdf_file) eq 7 then begin
      if ~file_test(/regular,cdf_file) then begin
        dprint,'No such file: ',cdf_file
        continue
      endif
      id = cdf_open(cdf_file)
    endif else id = cdf_file
    if not keyword_set(silent) then dprint,'Loading '+file_info_string(cdf_file)

    tinq = cdf_info(id)
    inq = tinq.inq

    if not keyword_set(cdf_vars) then begin     ;get only variables that vary
      for n=0,inq.nvars-1 do begin
        vinq=cdf_varinq(id,n)
        if vinq.recvar eq 'VARY' then append_array,cdf_vars,vinq.name
      endfor
      for n=0,inq.nzvars-1 do begin
        vinq=cdf_varinq(id,n,/zvar)
        if vinq.recvar eq 'VARY' then append_array,cdf_vars,vinq.name
      endfor
    endif

    nvars = n_elements(cdf_vars)
    if not keyword_set(tagnames) then tagnames = cdf_vars
    tagnames = strcompress(tagnames,/remove_all)

    if not keyword_set(data0) then append=0
    if not keyword_set(append)  then begin      ;define the data structure:
      ;      if keyword_set(time) then dat = {TIME:0.d}
      for n=0,nvars-1 do begin
        vinq = cdf_varinq(id,cdf_vars[n])
        if vinq.is_zvar then dim = vinq.dim else dim = inq.dim*vinq.dimvar
        w = where(dim,ndim)
        if ndim gt 0 then dim=dim[w] else dim=0
        ;print,cdf_vars(n),ndim,dim
        case vinq.datatype of
          'CDF_REAL8' :   value = !values.d_nan
          'CDF_DOUBLE':   value = !values.d_nan
          'CDF_REAL4' :   value = !values.f_nan
          'CDF_FLOAT' :   value = !values.f_nan
          'CDF_INT4'  :   value = 0l
          'CDF_UINT4' :   value = 0ul
          'CDF_INT2'  :   value = 0
          'CDF_UINT2' :   value = 0
          'CDF_INT1'  :   value = 0b
          'CDF_UINT1' :   value = 0b
          'CDF_CHAR'  :   value = 0b
          'CDF_UCHAR' :   value = 0b
          'CDF_BYTE'	:   value = 0b
          'CDF_EPOCH' :   value = !values.d_nan
          'CDF_INT8' : value = 0LL
          'CDF_TIME_TT2000' : value = 0LL
          else        :   message ,'Invalid type,  please fix source...'
        endcase
        if ndim gt 0 then val = make_array(value=value,dim=dim)   $
        else val=value
        a = strpos(tagnames[n],'%')
        aa = strpos(tagnames[n],'*')
        if a ne -1 then begin
          b = strlen(tagnames[n])
          oldname = tagnames[n]
          tagnames[n] = strmid(oldname,0,a)+'q'+strmid(oldname,a+1,b)
        endif
        if aa ne -1 then begin
          b = strlen(tagnames[n])
          oldname = tagnames[n]
          tagnames[n] = strmid(oldname,0,aa)+'x'+strmid(oldname,aa+1,b)
        endif

        str_element,/add,dat,tagnames[n],val
      endfor
      if keyword_set(time) then begin
        w = where(tag_names(dat) eq 'TIME',c)
        if c eq 0 then str_element,/add,dat,'TIME',0.d
      endif
    endif else dat = data0[0]

    vinq = cdf_varinq(id,cdf_vars[0])
    !quiet = 1
    cdf_control,id,variable=cdf_vars[0],get_var_info=varinfo,zvar=vinq.is_zvar
    !quiet = 0
    nrecs = varinfo.maxrec+1
    data = replicate(dat,nrecs)

    del = 0

    if keyword_set(time) then begin
      if cdf_attexists(id,'DEPEND_0',cdf_vars[0],zvar=vinq.is_zvar) then $
        cdf_attget,id,'DEPEND_0',cdf_vars[0],epochnum,zvar=vinq.is_zvar $
      else begin
        for thisvar=0,inq.nvars-1 do begin
          vinq = cdf_varinq(id,thisvar)
          if vinq.datatype eq 'CDF_EPOCH' then $
            epochnum=vinq.name
        endfor
        if n_elements(epochnum) eq 0 then begin
          for thisvar=0,inq.nzvars-1 do begin
            vinq = cdf_varinq(id,thisvar,/zvar)
            if vinq.datatype eq 'CDF_EPOCH' then $
              epochnum=vinq.name
          endfor
        endif
      endelse
      loadcdf2,id,epochnum,x
      epoch0 = 719528.d * 24.* 3600. * 1000.  ;Jan 1, 1970
      data.time = (x - epoch0)/1000.
    endif

    for n=0,nvars-1 do begin
      if cdf_attexists(id,'DEPEND_0',cdf_vars[n],zvar=vinq.is_zvar) then $
        cdf_attget,id,'DEPEND_0',cdf_vars[n],thisepoch,zvar=vinq.is_zvar $
      else thisepoch = epochnum
      if n eq 0 and not keyword_set(time) then epochnum = thisepoch
      if strpos(tagnames[n],'Epoch') ne -1 then thisepoch = tagnames[n]
      if thisepoch eq epochnum then begin
        loadcdf2,id,cdf_vars[n],x,/no_shift,nrecs=nrecs
        if cdf_attexists(id,'FILLVAL',cdf_vars[n],zvar=vinq.is_zvar) then $
          begin
          case size(/type,x) of
            4: nan = !values.f_nan
            5: nan = !values.d_nan
            else: nan = 0
          endcase
          if nan ne 0 then begin
            cdf_attget,id,'FILLVAL',cdf_vars[n],fv,zvar=vinq.is_zvar
            fvindx = where(x eq fv,fvcnt)
            if fvcnt gt 0 then x[fvindx] = nan
          endif
        endif
        str_element,/add,data,tagnames[n],x
      endif else begin
        dprint,'Variable '+cdf_vars[n]+' has different Epoch'
      endelse
    endfor

    if num eq 0 and keyword_set(novarnames) then begin
      novardata = 0
      novartags = strcompress(novarnames,/remove_all)
      for i=0,n_elements(novarnames)-1 do begin
        loadcdf2,id,novarnames[i],val
        if keyword_set(nvtagnames) then nvtag = nvtagnames[i] else $
          nvtag = novartags[i]
        str_element,/add,novardata,nvtag,val
      endfor
    endif

    if num eq 0 and keyword_set(novarznames) then begin
      novarzdata = 0
      novarztags = strcompress(novarznames,/remove_all)
      for i=0,n_elements(novarznames)-1 do begin
        loadcdf2,id,novarznames[i],val,/zvar
        if keyword_set(nvztagnames) then nvztag = nvztagnames[i] else $
          nvztag = novarztags[i]
        str_element,/add,novardata,nvztag,val
      endfor
    endif

    if size(/type,cdf_file) eq 7 then cdf_close,id
    if keyword_set(filter_proc) then call_procedure,filter_proc,data
    if keyword_set(res) then data = average_str(data,res,/nan,median=med)
    append_array,data0,data,index=index
    append = 1
    skip:
    if id eq 0 then dprint,'Unable to open file: ',file_info_string(cdf_file)
  endfor

  append_array,data0,index=index,/done

end


