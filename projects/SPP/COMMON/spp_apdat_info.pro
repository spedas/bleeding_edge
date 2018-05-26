; This is the master routine that changes or accesses the ccsds data structures for each type of packet that is received



pro spp_apdat_info,apid_description,name=name,verbose=verbose,$
                  clear=clear,$
                  zero=zero, $
                  reset=reset,$
                  apdats = apdats, $
                  ;matchname = matchname,  $  obsolete - use string as input
                  save_flag=save_flag,$
                  sort_flag=sort_flag,$
                  cdf_pathname = cdf_pathname, $
                  nonzero=nonzero,  $
                  dlevel=dlevel, $
                  all = all, $
                  finish=finish,$
                  window_obj=window_obj, $
                  tname=tname,$
                  ttags=ttags,$
                  routine=routine,$
                  file_save=file_save, file_restore=file_restore,compress=compress, $
                  apid_obj_name = apid_obj_name, $
                  print=print, $
                  rt_flag=rt_flag

  common spp_apdat_info_com, all_apdat, alt_apdat

  if keyword_set(reset) then begin   ; not recommended!
    obj_destroy,all_apdat    ; this might not be required in IDL8.x and above
    all_apdat=!null
    alt_apdat= !null
    return
  endif

  if keyword_set(file_restore) then restore,file=file_restore,/verbose

  if ~keyword_set(all_apdat) then all_apdat = replicate( obj_new() , 2^11 )
  
  if ~keyword_set(alt_apdat) then alt_apdat = orderedhash()
  
  if keyword_set(file_save) then save,file=file_save,all_apdat,/verbose,compress=compress

  valid_apdat = all_apdat[ where( obj_valid(all_apdat),nvalid ) ]

  if isa(apid_description,/string) then begin
    if nvalid ne 0 then begin
      names = strarr(nvalid)
      apids = intarr(nvalid)
      for i = 0,nvalid -1 do begin
        names[i] = valid_apdat[i].name
        apids[i] = valid_apdat[i].apid
      endfor
    endif
    ind = strfilter(names,apid_description,/index,/null)
    apids = apids[ind]
;    printdat,names[ind],apids
  endif else if isa(apid_description,/integer) then begin
    apids = apid_description
  endif else  apids = where(all_apdat,/null)
 
  ;printdat,apids
  
  default_apid_obj_name =  'spp_gen_apdat'

  for i=0,n_elements(apids)-1 do begin
    apid = apids[i]
    if alt_apdat.haskey(apid) eq 0 then alt_apdat[apid] = obj_new()   ; initialize new apid
    apdat_obj = all_apdat[apid]
    
    if ~obj_valid(apdat_obj)  || (isa(/string,apid_obj_name) && (typename(apdat_obj) ne strupcase(apid_obj_name) ) )  then begin
      dprint,verbose=verbose,dlevel=3,'Initializing APID: ',apid        ; potential memory leak here - old version should be destroyed
      apdat_new = obj_new( (isa(/string,apid_obj_name) && keyword_set(apid_obj_name)) ? apid_obj_name : default_apid_obj_name, apid) 
      all_apdat[apid] = apdat_new       
      alt_apdat[apid] = apdat_new
    endif
    apdat = all_apdat[apid]
    if n_elements(name)       ne 0 then apdat.name = name
    if n_elements(routine)    ne 0 then apdat.routine=routine
    if n_elements(rt_flag)    ne 0 then apdat.rt_flag = rt_flag
    if n_elements(sort_flag)  ne 0 then apdat.sort_flag = sort_flag
    if n_elements(dlevel)     ne 0 then apdat.dlevel = dlevel
    if n_elements(tname)      ne 0 then apdat.tname = tname
    if n_elements(ttags)      ne 0 then apdat.ttags = ttags
    if n_elements(window_obj) ne 0 then  apdat.window_obj = window(window_title=apdat.name)
    if n_elements(save_flag)  ne 0 then apdat.save_flag = save_flag
    if n_elements(cdf_pathname) ne 0 then apdat.cdf_pathname= cdf_pathname
    if ~keyword_set(all)  &&  (apdat.npkts eq 0) then continue
    if keyword_set(finish) then    apdat.finish
    if keyword_set(clear)  then    apdat.clear
    if keyword_set(zero)   then    apdat.zero
    if keyword_set(print)  then    apdat.print, header = i eq 0
  endfor

  apdats=all_apdat[apids]
  
end

