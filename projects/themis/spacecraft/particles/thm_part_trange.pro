
;+
;Procedure:
;  thm_part_trange
;
;Purpose:
;  Store/retrive the last requested time range for a particle data type. 
;  This routine should only be called internally by the particle load routines.
;
;Calling Sequence:
;  thm_part_set_trange, probe, datatype, trange [,sst_cal=sst_cal]
;
;Input:
;  probe: (string) scalar containing probe designation
;  datatype: (string) scalar containing particle data type
;  set: (double) two element array specifying a time range
;  sst_cal: (bool/int) flag to use time range for data loaded with thm_load_sst2  
;
;Output:
;  get: (double) two element array containing the last loaded time range
;       for the specified data, [0,0] if no data has been loaded
;
;See Also:
;  thm_part_check_trange
;  thm_load_esa_pkt
;  thm_load_sst
;  thm_load_sst2
;
;Notes:
;  Get operation performed before set. 
;
;$LastChangedBy: pcruce $
;$LastChangedDate: 2014-10-13 10:38:28 -0700 (Mon, 13 Oct 2014) $
;$LastChangedRevision: 15979 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/spacecraft/particles/thm_part_trange.pro $
;
;-
pro thm_part_trange, probe_in, datatype_in, get=get, set=set, sst_cal=sst_cal

    compile_opt idl2, hidden
    
  
  common thm_part_trange, times
    
  ;initialize timesure if needed
  if ~is_struct(times) then begin
    base = {trange:[0,0d],eclipse:-1}
    temp = { peif:base, $
             peir:base, $
             peib:base, $
             peef:base, $
             peer:base, $
             peeb:base, $
             psif:base, $
             psir:base, $
             psib:base, $ ;datatype not used
             psef:base, $
             pser:base, $
             pseb:base, $
             psif_cal:base, $
             psir_cal:base, $
             psib_cal:base, $ ;datatype not used
             psef_cal:base, $
             pser_cal:base, $
             pseb_cal:base  $
              }
    times = {a:temp, b:temp, c:temp, d:temp, e:temp}
  endif

  
  ;check inputs
  ;----------------
  
  if ~is_string(probe_in) or ~is_string(datatype_in) then begin
    dprint, dlevel=0, 'Must specify probe and datatype'
    return
  endif
  
  datatype = strlowcase(datatype_in[0])
  probe = strlowcase(probe_in[0])

  if ~stregex(datatype,'p[es][ei][frb]',/bool) then begin
    dprint, dlevel=0, 'Invalid data type.'
    return
  endif
  
  if ~stregex(probe,'[abcde]',/bool) then begin
    dprint, dlevel=0, 'Invalid probe.'
    return
  endif
  
  if is_struct(set) then begin
    valid_tags = tag_names(times.a.peif)
    if n_elements(ssl_set_intersection(tag_names(set),valid_tags)) ne n_elements(valid_tags) then begin
      dprint, dlevel=0, 'Invalid input structure.'
      return
    endif
  endif


  ;set time range
  ;----------------

  valid_datatypes = strlowcase(tag_names(times.a))
  valid_probes = strlowcase(tag_names(times))

  ;use separate range for sst_cal
  if keyword_set(sst_cal) then begin
    if stregex(datatype, 'ps[ei][frb]', /bool) then begin
      sst_cal_tvarname = 'th'+probe+'_'+datatype+'_data'
      datatype += '_cal'
     
    endif
  endif

  ;locate probe
  pidx = where(probe eq valid_probes, np)
  if np gt 0 then begin

    ;locate datatype
    didx = where(datatype eq valid_datatypes, nd)
    if nd gt 0 then begin

      ;get value
      if arg_present(get) then begin
        get = times.(pidx).(didx)
        
         ;since SST calibrated data is a tplot variable, you can't assume it will still be around  
        if ~undefined(sst_cal_tvarname) then begin
          get_data,sst_cal_tvarname,data=d
          ;just checks if variable is present.  More elaborate checks are possible, 
          ;  but since the sst_cal variables are quite hard to work with, 
          ;  it is pretty safe to assume that any modifying will be doing so at their own risk.  
          if ~is_struct(d) then begin
            undefine,get
          endif
        endif
      endif
          
      ;set value
      if ~undefined(set) then begin
        temp = times.(pidx).(didx)        ;struct_assign needs named var
        struct_assign, set, temp, /nozero ;in case of differing field types (e.g. int/long)
        times.(pidx).(didx) = temp
      endif

    endif

  endif

end