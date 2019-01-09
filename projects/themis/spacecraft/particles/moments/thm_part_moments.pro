;+
;PROCEDURE: thm_part_moments
;
;PURPOSE:
;  Generate moments from particle data.
;  This routine is a wrapper that allows backwards compatibility 
;  with calls to the old moments routine (thm_part_moments.pro).
;
;Input Keywords:
;  Argument description inline below.
;
;Deprecated Keywords:
;  
;
;Notes:
;  Old version in particles/deprecated
;  
;
;$LastChangedBy: jimm $
;$LastChangedDate: 2019-01-08 14:13:15 -0800 (Tue, 08 Jan 2019) $
;$LastChangedRevision: 26440 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/spacecraft/particles/moments/thm_part_moments.pro $
;-
pro thm_part_moments, probes = probes, $ ;string specifying probe(s)
                      
                      ;**identical keywords**
                      ;particle data type, e.g. 'peif', 'pseb'
                      ;data_type originally added to make consistency b/t this & thm_part_getspec
                      instruments_types = instruments, $
                      data_type=data_type, $
                      datatypes=datatypes,$

                      ;**deprecated** 
                      ;list of moments to return
                      ;specifying moments does not shorten calculation
                      ;therefore all moments are exported to tplot in new code
                      moments_types = moments_types, $

                      ;time range
                      trange = trange, $
                      
                      ;energy range
                      erange = erange, $
                      
                      ;**deprecated**
                      ;string specifying units
                      units = units, $
                      
                      ;flag to return error estimates ( *_sigma vars)
                      get_error = get_error, $

                      ;new code allows specification of whole tplot var name
                      scpot_suffix = scpot_suffix, $
                      mag_suffix = mag_suffix, $ 
                      
                      ;**identical keywords**
                      tplotsuffix = tplotsuffix, $
                      suffix=suffix, $
                      
                      method_clean=method_clean,$ ;enable sun decontamination
                      sun_bins=sun_bins,$ ;set decontamination bins, 64-element 0-1 array

                      ;**deprecated**
                      ;usage output keywords
                      ;cribs should example usage more completely
                      set_opts = set_opts, $ ;was not previously used
                      comps = comps, $   ;was not previously used
                      get_moments = get_moments, $
                      usage = usage, $
                      bins2mask=bins2mask,$
                      badbins2mask=badbins2mask,$
                      enoise_bins=enoise_bins,$ 
                      
                      ;ptr(s) to 3d particle structure arrays
                      dist_array=dist_array, $
                      
                      ;array of names of tplot vars created core routines
                      tplotnames = tplotnames, $
                      
                      ;will probably be added to new code...
                      verbose = verbose, $
                      coord = coord, $
                      
                      _extra = ex
   
                      
    compile_opt idl2

  ;----------------------------------------------------------------------------
  ;Notify user of newer version and deprecated keywords.
  ;----------------------------------------------------------------------------
  dprint,dlevel=0,"WARNING: This routine is now wrapper.  For new code, we recommend using the core routine thm_part_products.pro, see thm_crib_part_products.pro for examples."

  if keyword_set(get_moments) || keyword_set(usage) then begin
    dprint, dlevel=0, 'The "get_moments" and "usage" keywords are no longer supported.  Usage instructions and examples can be found in thm_crib_part_products.pro.'
    return ;neither keyword was intended to be used with actual run
  endif

  if keyword_set(bins2mask) then begin
    message,'ERROR: Keyword bins2mask is fully deprecated.  Use sun_bins for sst sun decontamination, and dist_array otherwise'
  endif
  
  if keyword_set(badbins2mask) then begin
    message,'ERROR: Keyword badbins2mask is fully deprecated.  Use sun_bins for sst sun decontamination, and dist_array otherwise'
  endif
  
  if keyword_set(enoise_bins) then begin
    message,'ERROR: enoise_bins is fully deprecated.  Use sun_bins for sst sun decontamination'
  endif

  ;----------------------------------------------------------------------------
  ;Overwrite probe/datatype input if data structure pointers were passed in
  ;  -if dist_array is set there is no need to loop over probe/datatypes
  ;  -probe will be needed to load correct support data if the support suffix keywords are set
  ;  -data type will primarily be used for variable naming
  ;----------------------------------------------------------------------------

  ;Data Pointers
  ;--------------
  ; -assumes all data is of same type
  ; -use "instruments" in case "datatype" is set
  thm_pgs_get_datatype, dist_array, probe=probes, datatype=instruments


  ;----------------------------------------------------------------------------
  ;Get/check string inputs
  ;  -The logic here should match that from the original thm_part_moments
  ;----------------------------------------------------------------------------
  
  ;Probes
  ;------------
  valid_probes = ['a','b','c','d','e']
  if is_string(probes) then begin
    probes_lc = strfilter(valid_probes, probes, /fold_case, delimiter=' ')
    probes_lc = strlowcase(probes_lc)
    if probes_lc[0] eq '' then begin
      dprint, dlevel=1, 'Input did not contain a valid probe designation.'
      return
    endif
  endif else begin
    dprint, dlevel=1, 'Input did not contain a valid probe designation.'
    return
  endelse
  
  ;Data types
  ;------------
  valid_datatypes = ['peif','peef','psif','psef','peir','peer', $
                     'psir','pser','peib','peeb','pseb']
  if is_string(data_type) then datatypes = data_type
  if is_string(instruments) then datatypes = instruments
  if is_string(datatypes) then begin
    datatypes_lc = strfilter(valid_datatypes, datatypes, /fold_case, delimiter=' ')
    datatypes_lc = strlowcase(datatypes_lc)
    if datatypes_lc[0] eq '' and ~keyword_set(dist_array)then begin
      dprint, dlevel=1, 'Input did not include a valid data type.'
      return
    endif
  endif else begin
    dprint, dlevel=1, 'Input did not include a valid data type.'
    return
  endelse
  
  ;remap sun decontamination keywords
  if keyword_set(method_clean) then begin
    if strlowcase(method_clean) eq 'automatic' then begin
      dprint,dlevel=1,'Automatic SST decontamination method no longer supported, Defaulting to manual with good default.'
    endif
    sst_method_clean='manual'
  endif
  
  ;new code uses bin number instead of 0-1 array
  if keyword_set(sun_bins) then begin
    sst_sun_bins = where(~sun_bins)
  endif

  ;Output Variables
  ;----------------
  ;  -All moments are produced simultaneously by moments_3d, therefore
  ;   if any are requested all will be returned by the new code.
  ;  -Energy spec was automatically returned by original thm_part_moments
  ;  -Energy spec created here will be renamed later with old naming convention.
  outputs = 'moments energy'
  ;this should allow only an energy spec to be produced if moments_types==''
  if ~undefined(moments_types) && ~keyword_set(moments_types)then begin
    outputs = 'energy'
  endif

  ;Output Suffix
  ;-------------
  if keyword_set(tplotsuffix) then suffix = tplotsuffix
  
  ;Support Data Suffixes
  ;---------------------
  if undefined(mag_suffix) then mag_suffix=''
  if undefined(scpot_suffix) then scpot_suffix=''
  if undefined(units) then units = 'eflux'
  
  
  ;Output Variable List
  ;------------
  ;  -if set, this prevents concatenation from previous calls
  undefine,tplotnames
  
  
  ;----------------------------------------------------------------------------
  ;Loop over spacecraft and data type
  ;----------------------------------------------------------------------------
  
  ;Loop over probes
  for i=0, n_elements(probes_lc)-1 do begin
  
  
    ;Convert support data suffixes to full names
    ;Ensure names are defined, if not then the defaults used by thm_part_products
    ;will be passed back and used in subsequent loop iterations.  This also 
    ;preserves the behavior of the original thm_part_moments in that no potential
    ;or mag data will be used unless explicitly specified by the user.
    
    if keyword_set(mag_suffix) then begin
      mag_name = 'th'+probes_lc[i]+mag_suffix
    endif else begin
      mag_name = ''
    endelse
    
    if keyword_set(scpot_suffix) then begin
      sc_pot_name = 'th'+probes_lc[i]+scpot_suffix
    endif else begin
      sc_pot_name = ''
    endelse
  
    ;Loop over data types
    for j=0, n_elements(datatypes_lc)-1 do begin
    
    
      ;-----------------------------------------------------------------------
      ;Call new code with correct set of keywords
      ;-----------------------------------------------------------------------
      thm_part_products, probe=probes_lc[i], $ ;loop over probes
                         datatype=datatypes_lc[j], $ ;loop over data types
                         
                         units=units, $ ;pass through (for energy spectra only)
                         
                         trange=trange, $ ;pass through
                         energy=erange, $ ;pass through to new kewords
                         
                         outputs=outputs, $ ;energy spectra and (usually) moments
                         
                         get_error=get_error, $ ;pass through
                         
                         mag_name=mag_name, $ ;suffix appended to probe  
                         sc_pot_name=sc_pot_name, $ ;suffix appended to probe
                         
                         dist_array=dist_array, $ ;pass through
                         
                         suffix=suffix, $ ;pass through

                         tplotnames=tplotnames_tmp, $ ;will be cleared on each call
                          
                         sst_method_clean=sst_method_clean, $
                         sst_sun_bins=sst_sun_bins,$   
                         
                         sst_cal=sst_cal, $ ;not an explicit keyword, required to retrieve correct data
                         coord = coord, $ ;jmm, 2019-01-08
                         _extra=ex

      ;Collect names of new tplot variables
      ;------------------------------------
      if ~undefined(tplotnames_tmp) then begin
      
        ;rename energy spectrograms to use old naming convention and
        ;expand single-dimension y axes to two dimensions to match old code
        ename = 'th'+probes_lc[i]+'_'+datatypes_lc[j]+'_'+strlowcase(units)+'_energy'+suffix
        ename_idx = where(tplotnames_tmp eq ename, nnames)
        if nnames gt 0 then begin
          newname = 'th'+probes_lc[i]+'_'+datatypes_lc[j]+'_en_'+strlowcase(units)+suffix
          tplotnames_tmp[ename_idx] = newname
          
          tplot_rename,ename,newname
          
          thm_pgs_expand_yaxis, newname
          
        endif
        ;concatenate tplot names as the variable will be cleared each time in the above call
        tplotnames = array_concat(tplotnames_tmp,tplotnames)        

      endif
    
    
    endfor
    
  endfor
  
  
  
end
