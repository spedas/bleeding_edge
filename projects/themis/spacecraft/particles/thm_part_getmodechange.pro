
;+
;Purpose: Helper function to access ESA common blocks and 
;         return array of indices for mode changes.
;
;Notes:
;  When editing this code:
;   -make sure calls to scope_varfetch do not copy 
;    unnecessary data (see IDL documentation)
;
;-
function thm_part_getmodechange_esa, probe, datatype, tindex

    compile_opt idl2, hidden


  ;Determine common block & variable names
  case datatype of 
    'peif': apid = '454'
    'peir': apid = '455'
    'peib': apid = '456'
    'peef': apid = '457'
    'peer': apid = '458'
    'peeb': apid = '459'
    else: begin
            dprint, dlevel=0, 'Invalid data type: '+datatype
            return, -1
          end
  endcase
  
  common_name = 'th'+probe+'_'+apid
  data_name = common_name + '_dat'
  
  
  ;Copy config bytes for time range
  c1 = ( (scope_varfetch(data_name, common=common_name)).config1 )[tindex]
  c2 = ( (scope_varfetch(data_name, common=common_name)).config2 )[tindex]


  ;Get indices of all mode changes
  u1 = where(c1 ne shift(c1,1), n1)
  u2 = where(c2 ne shift(c2,1), n1)
    
  
  ;Combine indices
  ;-if first and last mode are identical then the 0th index
  ; will not be counted, add it here just in case
  ;-account for negative output form where()
  u = [0,u1,u2] > 0
  u = u[ uniq(u, sort(u)) ]

  return, u
  
end




;+
;Purpose: Helper function to access SST common block and 
;         return array of indices for mode changes.
;
;Notes:
;  When editing this code:
;   -make sure calls to scope_varfetch do not copy 
;    unnecessary data (see IDL documentation)
;   -make sure not to free pointers copied from the 
;    common block
;
;-
function thm_part_getmodechange_SST, probe, datatype, tindex

    compile_opt idl2, hidden


  common_name = 'data_cache_com'
  data_name = 'dcache'
  
  
  ;Get index to sst data structure in common block
  names = (scope_varfetch(data_name, common=common_name)).name
  
  idx = where(names eq 'th'+probe+'_sst_raw_data',nm)
  if nm lt 1 then begin
    dprint, dlevel=0, 'No SST data in common block for probe: '+probe
    return, -1
  endif
  
  
  ;Get pointer to loaded SST data
  ;DO NOT FREE THIS POINTER
  ptr = ((scope_varfetch(data_name, common=common_name))[idx]).ptr
  
  
  ;Get config data for specified data type
  case datatype of
    'psif': c = (  *(*ptr).sif_064_cnfg  )[tindex]
    'psef': c = (  *(*ptr).sef_064_cnfg  )[tindex]
    'pseb': c = (  *(*ptr).seb_064_cnfg  )[tindex]
    'psir': begin
              c1 = (  *(*ptr).sir_001_cnfg  )[tindex]
              c6 = (  *(*ptr).sir_006_cnfg  )[tindex]
              m  = (  *(*ptr).sir_mix_mode  )[tindex]
            end
    'pser': begin
              c1 = (  *(*ptr).ser_001_cnfg  )[tindex]
              c6 = (  *(*ptr).ser_006_cnfg  )[tindex]
              m  = (  *(*ptr).ser_mix_mode  )[tindex]
            end
    else: begin
            dprint, dlevel=0, 'Invalid data type: '+datatype
            return, -1
          end
  endcase
  
  
  ;Account for mixed modes on reduced data
  if keyword_set(m) then begin  

    ;Get indicies for single/six angle modes
    idx1 = where(m, n1, comp=idx6, ncomp=n6)

    if n1+n6 ne n_elements(tindex) then begin
      dprint, dlevel=0, 'Error determining SST reduced modes.'
      return, -1
    endif

    ;Create combined mode array
    c = uintarr(n_elements(tindex), /nozero)    
    if n1 gt 0 then c[idx1] = c1[idx1]
    if n6 gt 0 then c[idx6] = c6[idx6]
    
  endif
  

  ;Get indices for all mode changes
  u1 = where(c ne shift(c,1))
  u2 = keyword_set(m) ? where(m ne shift(m,1)):0
  
  
  ;Combine indices
  ;-if first and last mode are identical then the 0th index
  ; will not be counted, add it here just in case
  ;-account for negative output form where()
  u  = [0,u1,u2] > 0 
  u = u[ uniq(u, sort(u)) ]

  return, u

end




;+
;Purpose: Helper function to access raw SST data stored in tplot
;         variables and return array of indices for mode changes.
;         Data loaded with thm_load_sst2 (/sst_cal keyword on higher
;         level routines) is stored in tplot vars instead of the 
;         original common block.
;         
;
;Notes:
;
;-
function thm_part_getmodechange_SST2, probe, datatype, tindex

    compile_opt idl2, hidden


  flag = 0ul-1 ;doubt this is a valid SST config
  

  ;Get top-level structure from tplot variable
  name = 'th' + probe + '_' + datatype + '_data'

  get_data, name, data=data
  
  if ~is_struct(data) then begin
    dprint, dlevel=0, 'No tplot variable for: ' + name
    return, -1
  end
  
  
  ;Get pointers to raw data structures
  ptrs = data.mdistdat.distptrs
  
  ;Initialize array of config modes corresponding to
  ;the monotonic time array for the specified time range.
  c = replicate(flag, n_elements(tindex))
  
  ;Loop over pointers and copy the config modes from each 
  ;distribution into their appropriate place in the new
  ;config mode array.
  for i=0, n_elements(ptrs)-1 do begin
  
    if ~ptr_valid(ptrs[i]) then continue
    
    ;get indices of times where this distribution is used
    idx = where( (data.y)[tindex] eq i, n)
    
    ;copy the config modes for this distribution
    if n gt 0 then begin
      c[idx] = (   ( *(*ptrs[i]).cnfg )[tindex]   )[idx]
    endif
    
  endfor
  
  
  ;Check that all samples have a valid mode
  dummy = where(c eq flag, nf)
  if nf gt 0 then begin
    dprint, dlevel=0, $
      'Could not extract mode for all time samples from: '+name
    return, -1
  endif
  
  
  ;Get indices of mode changes
  ;-if first and last mode are identical then the 0th index
  ; will not be counted, add it here just in case
  ;-account for negative output form where()
  u = where(c ne shift(c,1))
  u = [0,u] > 0
  u = u[ uniq(u, sort(u)) ]

  return, u
  


end




;+
; Purpose:
;   Access particle data common blocks to determine
; where mode changes occure and how many samples are
; in each configuration.
; 
; Input: 
;   probe: String specifying the spacecraft (e.g. 'a','b',...)
;   datatype: String specifying the type of data (e.g. 'peif')
;   tindex: Array of indices specifying which samples are 
;           within the time range.
; 
; Output:
;   returned value: Array of indices correspinding to the first
;                   distribution for each new configuration.
;                n: The total number of samples for each 
;                   configuration.
;
; Usage:
;   indices = thm_part_dist_array_getmodechange(probe='a', datatype='psif', $
;                                          tindex=time_index_array, n=n)
;-
function thm_part_getmodechange, probe, $
                                 datatype, $
                                 tindex, $
                                 sst_cal=sst_cal, $
                                 n=n

    compile_opt idl2, hidden

  
  ;Get config data out of appropriate common blocks
  ;The following routines will return arrays of indices
  ;to the first sample from each config mode.
  if strmid(datatype,1,1) eq 'e' then begin
    ;ESA
    u = thm_part_getmodechange_ESA( probe, datatype, tindex )
  endif else begin
    if keyword_set(sst_cal) then begin
      ;SST data loaded with thm_load_sst2
      u = thm_part_getmodechange_SST2( probe, datatype, tindex )
    endif else begin
      ;Original SST data
      u = thm_part_getmodechange_SST( probe, datatype, tindex )
    endelse
  endelse
  
  
  ;an error occured
  if u[0] eq -1 then begin
    n = 0
    return, u
  endif
  

  ;get number of samples in each group
  if n_elements(u) lt 2 then begin
    n = n_elements(tindex) ;no mode changes
  endif else begin
    n = shift( [u,n_elements(tindex)], -1)  -  u
  endelse
 

  return, u

end
