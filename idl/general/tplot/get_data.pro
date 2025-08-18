;+
;PROCEDURE:  get_data , name, time, data, values
;PURPOSE:
;   Retrieves the data and or limit structure associated with a name handle.
;   This procedure is used by the "TPLOT" routines.
;INPUT:  name    scalar string or index of TPLOT variable
;        time	 named variable to return time values.
;        data    named variable to return data (y) values.
;        values  named variable to return additional (v) values.
;KEYWORDS:
;   DATA:   named variable to hold the data structure.
;   LIMITS: named variable to hold the limits structure.
;   DLIMITS: named variable to hold the default limits structure.
;   ALIMITS: named variable to hold the combined limits and default limits
;            structures.
;   DTYPE: named variable to hold the data type value.  These values are:
;		0: undefined data type
;		1: normal data in x,y format
;		2: structure-type data in time,y1,y2,etc. format
;		3: an array of tplot variable names
;   PTR:   named variable to hold pointers to data structure.
;   INDEX:  named variable to hold the name index.  This value will be 0
;     if the request was unsuccessful.
;   TRANGE: named variable to hold the time range (output variable only,
;           does not affect data returned).
;
;SEE ALSO:	"STORE_DATA", "TPLOT_NAMES", "TPLOT"
;
;CREATED BY:	Davin Larson
;MODIFICATION BY: 	Peter Schroeder
;LAST MODIFICATION:	@(#)get_data.pro	1.28 02/04/17
; $LastChangedBy: davin-mac $
; $LastChangedDate: 2023-11-19 11:39:45 -0800 (Sun, 19 Nov 2023) $
; $LastChangedRevision: 32251 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/tplot/get_data.pro $
;
;-
pro get_data,name, time, data, values, $
  data_str = data_str, $
  limits_str = lim_str, $
  alimits_str = alim_str, $
  dlimits_str = dlim_str, $
  ptr_str = ptr_str, $
  index = index, $
  dtype = dtype, $
  null = null, $
  trange = trange

  @tplot_com.pro
  time = 0
  data = 0
  values = 0
  data_str = 0
  lim_str = 0
  alim_str = 0
  dlim_str = 0
  dtype = 0
  ptr_str = 0
  trange = 0
  if keyword_set(null) then begin
    time = !null
    data = !null
    values = !null
    data_str = !null
    lim_str = !null
    alim_str = !null
    dlim_str = !null
    dtype = !null
    ptr_str = !null
    trange = !null
  endif

  index = find_handle(name)

  if index ne 0 then begin
    dq = data_quants[index]
    if arg_present(data) or arg_present(time) or arg_present(values) or arg_present(data_str) then begin
      if dq.dtype eq 4 then begin    ; dynamicarray 
        dh = (*dq.dh)
        datastr_array = dh.ddata.sample()
        tags = tag_names(datastr_array)
        vardef = dh.vardef
        labels = vardef.keys()
        data_str = {}
        for i = 0,n_elements(labels)-1 do begin
          label = labels[i]
          tag_num =  (where(/null,tags eq strupcase(vardef[label])))
          dprint,dlevel=4,label +' : ' + vardef[label],tag_num
          if isa(tag_num) then begin
            val = datastr_array.(tag_num)   ; there is a bug here if size of datastr_array eq 1
            if 1 && n_elements(datastr_array) gt 1 then begin   ; put time at the beginning
              ndim = size(/n_dimension,val)
              p = shift(indgen(ndim),1)
              val = transpose(val,p)
            endif
            if arg_present(trange)  && label eq 'X' then trange = minmax(val)
            if arg_present(data_str) then data_str = create_struct(data_str,label,val)
            if arg_present(time)   && label eq 'X'  then time = temporary(val)
            if arg_present(data)   && label eq 'Y'  then data = temporary(val)
            if arg_present(values) && label eq 'V'  then values = temporary(val)
          endif else dprint,dlevel=2, 'Label '+label+' not found in '+dh.ddata.name 
        endfor
        ptr_str = *dq.dh
      endif else if size(/type,*dq.dh) eq 8 then begin
        ; 	  		mytags = tag_names_r(*dq.dh)             Too goofy to be useful!!!   see similar line in store_data
        mytags = tag_names(*dq.dh)
        for i=0,n_elements(mytags)-1 do begin
          str_element,*dq.dh,mytags[i],foo
          if ptr_valid(foo) then $
            str_element,data_str,mytags[i],*foo,/add
        endfor
        ; Old style: get x,y and v tag names:
        str_element,data_str,'x',value= time
        str_element,data_str,'y',value= data
        str_element,data_str,'v',value= values

        ; New style: get time, data tag names:
        str_element,data_str,'time',value= time
        str_element,data_str,'data',value= data
        ptr_str = *dq.dh

      endif else data_str = *dq.dh     ; typically will be a string or array of strings
      if arg_present(trange) then trange = dq.trange


      ;str_element,dq,'dtype',dtype
      dtype = dq.dtype


      if size(/type,data_str) ne 8 then $
        dprint, dlevel = 6, 'No Data Structure for: '+name
    endif



    if arg_present(lim_str) or arg_present(alim_str) then begin
      lim_str = *dq.lh
      if size(/type, lim_str) ne 8 then $
        dprint, dlevel = 6, 'No Limits Structure for: '+name
    endif
    if arg_present(dlim_str) or arg_present(alim_str) then begin
      dlim_str = *dq.dl
      if size(/type, dlim_str) ne 8 then $
        dprint, dlevel = 6, 'No Dlimits Structure for: '+name
    endif

    extract_tags,alim_str,dlim_str,/replace
    extract_tags,alim_str,lim_str,/replace
    dtype = dq.dtype
    if arg_present(ptr_str) && ptr_valid(dq.dh) then begin
      ptr_str = *dq.dh
    endif
    ;if size(/type,*dq.dh) eq 8 then ptr_str = *dq.dh
    if arg_present(trange) then trange = dq.trange

  endif else dprint, dlevel = 6, 'Variable '+string(name)+ ' Not Found'
  return
end

