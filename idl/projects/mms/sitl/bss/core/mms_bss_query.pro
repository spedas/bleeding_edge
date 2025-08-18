;+
; NAME: mms_bss_query
;
; PURPOSE: 
;     To query the back-structure. Somehow, the SDC code "get_mms_burst_segment_status"
;     does not work well for querying by status. Here, the program loads the entire
;     set of the back-structure (or you can limit it by 'trange') and then analyze
;     the segments. 
;     
; CREATED BY: Mitsuo Oka   Aug 2015
;
; $LastChangedBy: moka $
; $LastChangedDate: 2015-09-13 22:04:34 -0700 (Sun, 13 Sep 2015) $
; $LastChangedRevision: 18784 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/sitl/bss/core/mms_bss_query.pro $
;-
FUNCTION mms_bss_query, trange=trange, bss=bss, category=category, $
  frange=frange, status=status, IDs=IDs, withdeleted=withdelete, $
  exclude=exclude,isPending=isPending, inPlayList=inPlayList, fin=fin
  compile_opt idl2

  if n_elements(bss) eq 0 then begin
    bss = mms_bss_load(trange=trange,fin=fin)
    idx = mms_bss_cleanup(bss,withdeleted=withdeleted); remove bad segments
  endif else begin
    idx = lindgen(n_elements(bss.FOM))
  endelse

  ;-----------------
  ; QUERY BY FLAG
  ;-----------------
  if keyword_set(isPending) then begin
    idx=mms_bss_filter_by_flag(bss,isPending=isPending,idx=idx)
  endif
  if keyword_set(inPlayList) then begin
    idx=mms_bss_filter_by_flag(bss,inPlaylist=inPlaylist,idx=idx)
  endif

  ;-----------------
  ; EXCLUDE STATUS
  ;-----------------
  nmax = n_elements(exclude)
  if nmax gt 0 then begin
    if nmax eq 1 then begin
      sttarr = strsplit(exclude,' ',/extract)
    endif else begin
      sttarr = exclude
    endelse
    mmax = n_elements(sttarr)
    for m=0,mmax-1 do begin
      idx = mms_bss_filter_by_status(bss,sttarr[m],idx=idx,/ex)
    endfor
  endif
  
  ;-----------------
  ; QUERY BY STATUS
  ;-----------------
  nmax = n_elements(status)
  if nmax gt 0 then begin
    if nmax eq 1 then begin
      sttarr = strsplit(status,' ',/extract)
    endif else begin
      sttarr = status
    endelse
    mmax = n_elements(sttarr)
    superset = [-1]
    for m=0,mmax-1 do begin; for each status
      superset = [superset,mms_bss_filter_by_status(bss,sttarr[m],idx=idx)]
    endfor
    superset = superset[1:*]
    idx0 = where(Histogram(superset,Omin=omin))+omin;; Return combined set
    ; Here, we search elements in either one of the given statuses.
    ; 'Histogram' returns the count of each index in superset
    ; 'where' takes the index if the count (in the Histogram) is > 0
    ; Thus, idx is the elements from the superset.
    i = where(idx0 ge 0, ct)
    idx = (ct eq 0) ? [-1] : idx0[i]
  endif

  ;----------------------
  ; QUERY BY CATEGORY
  ;----------------------
  if n_elements(category) eq 1 then begin
    idx = mms_bss_filter_by_category(bss,category,idx=idx)
  endif
  
  ;--------------------
  ; QUERY BY FOM-RANGE
  ;--------------------
  if n_elements(frange) eq 2 then begin
    idx = mms_bss_filter_by_fom(bss,frange,idx=idx)
  endif

  ;----------------------
  ; QUERY BY SEGMENT IDs
  ;----------------------
  if n_elements(IDs) gt 0 then begin
    idx = mms_bss_filter_by_id(bss,IDs,idx=idx)
  endif
  
  return, mms_bss_replace(bss,idx)
END
