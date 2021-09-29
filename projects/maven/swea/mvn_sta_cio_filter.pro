;+
;PROCEDURE:   mvn_sta_cio_filter
;PURPOSE:
;   A tag 'filter' is added to the input data structure.  This tag holds
;   a pointer to a filter structure, which contains the filter definition
;   and the indices of data that pass through the filter.  If a filter
;   is already attached to the data structure then it will be overwritten
;   with the new filter.
;
;USAGE:
;  mvn_sta_cio_filter, ptr, filter
;
;INPUTS:
;       ptr    :    A pointer to the CIO data structure.
;
;       filter :    A structure containing allowed ranges for any of
;                   the parameters, including time.  This structure can
;                   have any combination of tags found in the CIO result
;                   structure (see mvn_sta_cio_struct.pro).  Each tag
;                   is given a range of values [min,max] that pass 
;                   through that component of the filter.  For example:
; 
;                     filter = {tag1 : [min1, max1] , $
;                               tag2 : [min2, max2] , $
;                                 |          |
;                               tagN : [minN, maxN]    }
;
;                   If a tag is missing or set to 0, then no filter is
;                   applied to that variable.  Only data that pass though
;                   all the filters are used to calculate distributions.
;
;                   The time range can be in any format accepted by
;                   time_double().
;
;KEYWORDS:
;       LIST   :    Print information about the filter, return
;                   its value via the 'filter' input (if present).
;
;       SUCCESS :   Returns 1 if there were no problems.
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2021-08-25 09:09:17 -0700 (Wed, 25 Aug 2021) $
; $LastChangedRevision: 30249 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swea/mvn_sta_cio_filter.pro $
;
;CREATED BY:	David L. Mitchell
;FILE:  mvn_sta_cio_filter.pro
;-
pro mvn_sta_cio_filter, ptr, in_filter, list=list, success=ok

; Check inputs

  ok = 0

  if (data_type(ptr) ne 10) then begin
    print,'  You must provide a pointer to the data!'
    return
  endif

  if (data_type(*ptr) ne 8) then begin
    print,'  Data must be a structure!'
    return
  endif

  if keyword_set(list) then begin
    str_element,(*ptr),'filter',value=filter,success=ok
    if (ok) then begin
      tag = strlowcase(tag_names(*filter))
      indx = where(tag ne 'f_indx', ntag)
      tag = tag[indx]
      for i=0,(ntag-1) do begin
        print,tag[i],format='(2x,a6," : ",$)'
        value = (*filter).(indx[i])
        case tag[i] of
          'time' : print,time_string(value),format='(2(a19,3x))'
           else  : print, value, format='(2(f9.2))'
        endcase
      endfor

      print,' '
      npass = n_elements((*filter).f_indx)
      print,'  Number of points passing through all filters: ',npass
    endif else begin
      print,'  No filters defined.'
      in_filter = 0
    endelse
    return
  endif

  if (data_type(in_filter) ne 8) then begin
    print,'  You must provide a structure defining the filter!'
    return
  endif

; Check for valid filter structure

  filter = in_filter
  n_filters = n_tags(filter)
  filter_tags = strlowcase(tag_names(filter))

  nfe = intarr(n_filters)
  for i=0,(n_filters-1) do nfe[i] = n_elements(filter.(i))

  indx = where(nfe lt 2, cnt)
  for i=0,(cnt-1) do str_element, filter, filter_tags[indx[i]], /del

  indx = where(((nfe > 2) mod 2) ne 0, cnt)
  if (cnt gt 0) then begin
    print,'  Syntax error in filter structure!'
    return
  endif

  n_filters = n_tags(filter)
  filter_tags = strlowcase(tag_names(filter))

  if (n_filters eq 0) then begin
    print,'  No filters are defined!'
    return
  endif

; Get the data tags

  data_tags   = strlowcase(tag_names(*ptr))
  n_vars      = n_tags(*ptr)

; If 'time' is one of the filter tags, then process time range

  i = where(filter_tags eq 'time', cnt)
  if (cnt gt 0L) then trange = time_double(filter.time)

; Check for valid filter tags

  gndx = [-1L]
  bndx = [-1L]

  for i=0,(n_filters-1) do begin
    j = where(data_tags eq filter_tags[i], cnt)
    if (cnt gt 0L) then gndx = [gndx, i] else bndx = [bndx, i]
  endfor

  ngud = n_elements(gndx) - 1L
  nbad = n_elements(bndx) - 1L

  if (nbad gt 0L) then begin
    bndx = bndx[1L:nbad]
    print,'  Invalid filter tag(s):',format='(a,$)'
    for i=0L,(nbad-1L) do print,filter_tags[bndx[i]],format='(a4,$)'
    print,''
    return
  endif

  if (ngud eq 0L) then begin
    print,'  No valid filter tags!'
    return
  endif

  gndx=n_elements(filter_tags)
  f_order = indgen(gndx)

; Get indices that pass through all valid filters

  npts = n_elements((*ptr).(0))
  indx = lindgen(npts)

  print,"  Applying filters: ",format='(a,$)'

  for i=0,(ngud-1L) do begin

    if (indx[0L] ne -1L) then begin
      j = where(data_tags eq filter_tags[f_order[i]])
      tag = j[0]

      if (filter_tags[f_order[i]] eq 'time') then range = trange $
       else range = filter.(f_order[i])

      if ((filter_tags[i] ne 'glon') and (filter_tags[i] ne 'slon') and $
          (filter_tags[i] ne 'bclk')) then begin
        range = range[sort(range)]
        jndx = where(((*ptr).(tag)[indx] ge range[0]) and $
                     ((*ptr).(tag)[indx] le range[1]), count)
      endif else begin
        if (range[0] lt range[1]) then $
          jndx = where(((*ptr).(tag)[indx] ge range[0]) and $
                       ((*ptr).(tag)[indx] le range[1]), count) $
        else $
          jndx = where(((*ptr).(tag)[indx] ge range[0]) or $
                       ((*ptr).(tag)[indx] le range[1]), count)
      endelse
    endif

    if (count eq 0L) then indx = -1L else indx = indx[jndx]

    print,filter_tags[f_order[i]],format='(a," ",$)'

  endfor

  print," "

; Attach the indices to the filter structure

  if (indx[0] eq -1L) then begin
    print,'  No data passed through all filters!'
    npass = 0L
    ok = 0
  endif else begin
    npass = n_elements(indx)
    ok = 1
  endelse

  if (npass eq npts) then print,'  All data passed through the filters!'

  filt = ptr_new(create_struct(filter,'f_indx',indx))

; Attach the filter structure to the data structure
; (overwrite previous filter)

  j = where(data_tags eq 'filter', cnt)
  if (cnt eq 0L) then begin
    (*ptr) = create_struct((*ptr),'filter',filt)
  endif else begin
    if (ptr_valid((*ptr).filter)) then ptr_free,(*ptr).filter
    (*ptr).filter = filt
  endelse

  print,'  Number of points passing through all filters: ',npass

  return

end
