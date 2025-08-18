deprecated

pro spp_apid_data,apid,name=name,$
                  clear=clear,$
                  reset=reset,$
                  save=save,$
                  finish=finish,$
                  apdata=apdat,$
                  tname=tname,$
                  tfields=tfields,$
                  rt_tags=rt_tags,$
                  routine=routine,$
                  print=print, $
                  increment=increment,$
                  rt_flag=rt_flag

  message,'obsolete routine'
  common spp_swp_raw_data_block_com, all_apdat

  if keyword_set(reset) then begin
     ptr_free,ptr_extract(all_apdat)    ; this might not be required in IDL8.x and above
     all_apdat=0
     return
  endif

  if ~keyword_set(all_apdat) then begin
     apdat0 = {  apid:-1 ,name:'',$
                 counter:0uL,$
                 nbytes:0uL, $
                 maxsize: 0,$
                 routine:   '',$
                 tname: '',$
                 tfields: '', $
                 rt_flag:0b,$
                 rt_tags: '',$
                 save:0b, $
                 ccsds_save:0b, $
                 ;status_ptr: ptr_new(), $
                 last_ccsds: ptr_new(),  $
                 ccsds_array: obj_new(),  $
;                 ccsds_all: ptr_new(),  $
;                 ccsds_ind: ptr_new(), $
                 last_decom: ptr_new(),  $
                 data_array: obj_new(),  $
;                 dataptr:  ptr_new(),   $
;                 dataindex: ptr_new() , $
                 dlimits:ptr_new() }
    all_apdat = replicate( apdat0,2^11 ) 
  endif
  
  
  if keyword_set(finish) then begin
     for i=0,n_elements(all_apdat)-1 do begin
        ap = all_apdat[i]
        da = ap.data_array
        if isa(da,'dynamicarray') then begin
          data = da.array
          if keyword_set(data) then begin
            if isa(data[0],'dynamicarray') then begin    ; special case for multiple products per APID
              for j=0,da.size-1 do begin
                foo = data[j]
                store_data,ap.tname+foo.name,data=foo.array, tagnames=ap.rt_tags
              endfor
            endif else  begin
              store_data,ap.tname,data=da.array, tagnames=ap.rt_tags
            endelse            
          endif
        endif
;          res = call_function(ap.routine,apdat=ap)
;          if ptr_valid(ap.dataptr) then $
;            append_array,*ap.dataptr,index = *ap.dataindex
;          if keyword_set(ap.tfields) && 1 then $
;            store_data,ap.tname,data= *ap.dataptr,tagnames=ap.tfields
    endfor
    return
  endif



  if n_elements(apid) ne 0 then begin
     apdat = all_apdat[apid]
     if n_elements(name)     ne 0 then apdat.name = name
     if n_elements(routine)  ne 0 then apdat.routine=routine
     if n_elements(rt_flag)  ne 0 then apdat.rt_flag = rt_flag
     if n_elements(tname)    ne 0 then apdat.tname = tname
     if n_elements(tfields)  ne 0 then apdat.tfields = tfields
     if n_elements(save)     ne 0 then apdat.save   = save
     if n_elements(rt_tags)  ne 0 then apdat.rt_tags=rt_tags
     if keyword_set(increment) then apdat.counter += 1
     for i=0,n_elements(apdat)-1 do begin
        if apdat[i].apid lt 0 then begin
           if ~ptr_valid(apdat[i].last_ccsds) then  apdat[i].last_ccsds = ptr_new(/allocate_heap)
           if ~ptr_valid(apdat[i].last_decom) then  apdat[i].last_decom = ptr_new(/allocate_heap)
           if ~obj_valid(apdat[i].data_array) then  apdat[i].data_array = dynamicarray(name= apdat[i].tname)
;           if ~ptr_valid(apdat[i].dataptr)    then  apdat[i].dataptr    = ptr_new(/allocate_heap)
;           if ~ptr_valid(apdat[i].dataindex)  then  apdat[i].dataindex  = ptr_new(/allocate_heap)
;           if ~ptr_valid(apdat[i].ccsds_ind)  then  apdat[i].ccsds_ind  = ptr_new(/allocate_heap)
           if ~ptr_valid(apdat[i].dlimits)    then   apdat[i].dlimits    = ptr_new(/allocate_heap)
        endif
     endfor
     apdat.apid = apid
     ;; Put it all back in all
     all_apdat[apid] = apdat    
  endif  else begin
     w= where(all_apdat.apid ge 0,nw)
     if nw ne 0 then begin
        if n_elements(rt_flag) ne 0 then all_apdat[w].rt_flag=rt_flag
        if n_elements(save) ne 0 then all_apdat[w].save=save
        apdat = all_apdat[w]
     endif else apdat=0
  endelse

  if keyword_set(clear) and keyword_set(apdat) then begin
    dprint,dlevel=1,'Clearing data'
    ptrs = ptr_extract(apdat,except=apdat.dlimits)
    for i=0,n_elements(ptrs)-1 do *ptrs[i] = !null       ;; This is clearing all counters - not just the subset.
    for i=0,n_elements(apdat)-1 do  apdat[i].data_array.array = !null
    all_apdat.counter = 0
    dprint,dlevel=1,'Data Cleared'
  endif
  
  if keyword_set(print) then begin
     print_struct,apdat
     print,heap_refcount(apdat.data_array)
  endif

end

