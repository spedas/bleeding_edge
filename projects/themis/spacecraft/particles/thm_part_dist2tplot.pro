;+
;NAME:
; thm_part_dist2tplot
;PURPOSE:
; Convert convert some of the 3d particle structures into a set of tplot variables
;INPUT:
;  probe    = strinf denoted to the satellite
;            'a','b','c','d','e'
;  datatype = string denoted to the instrument
;             'peef', 'peeb', 'peer', 'peif', 'peib', 'peir', 
;             'psef', 'pseb', 'pser', 'psif', 'psib', 'psir'
;  trange   = Two elements in array specifing the time range 
; OUTPUT:
;    tplot variables
;
; AUTHOR:
;   Alexander Drozdov
;
; SVN:  
;  $LastChangedBy: sppswpsoc $
;  $LastChangedDate: 2017-10-24 17:15:39 -0700 (Tue, 24 Oct 2017) $
;  $LastChangedRevision: 24208 $
;  $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/spacecraft/particles/thm_part_dist2tplot.pro $

pro thm_part_dist2tplot, probe=probe, datatype=datatype, trange=trange
    
    ; check the input
    ; exit if wrong probe input
    if keyword_set(probe) then begin
      if where(probe eq ['a', 'b', 'c', 'd', 'e']) eq -1 then begin      
        dprint, "ERROR: Wrong probe input",dlevel=1
        return
      endif
    endif else begin
      ; Default value
      probe='a';
    endelse
    
    ; exit if wrong datatype input
    if keyword_set(datatype) then begin
      if ~stregex(datatype, '^p[es][ei][fbr]$', /bool) then begin
        dprint, "ERROR: Wrong datatype input",dlevel=1
        return
      endif
    endif else begin
      ; default ?
      datatype = ''
    endelse
    
    ; function thm_part_dist_array will handle undefined trange. No need to check
      
    ; retrieve the dist_array 
    ; example: dist_array = thm_part_dist_array(probe='a',datatype='peef', trange='2008-2-26/04:'+['00:00','55:00'])
    dist_array = thm_part_dist_array(probe=probe,datatype=datatype, trange=trange)
     
    ; check dist_array, exit if we cannot get the pointer
    if size(dist_array,/TYPE) ne 10 then return
        
    allowed_fields = ['time', 'valid',  'end_time',  'config1', 'config2', 'an_ind', 'en_ind', 'mode', 'nenergy', 'nbins', 'scpot', 'eclipse_dphi', 'magf', 'velocity']
    
    ; for the loop of dist_array element
    dist_array_n = size(dist_array, /N_ELEMENTS)        
    ; count time samples
    total_sample_count = 0

    ; create the arrays container
    arr = {}    
    arr_names = [] ; this array helps to track the names
    ;;arr_types = []
           
    for idx=0,dist_array_n-1 do begin
      ; Chech if dist_array pointer is valid and if store structure
      if ptr_valid(dist_array[idx]) && (size(*dist_array[idx],/TYPE) eq 8) then begin        
        total_sample_count = total_sample_count + size(*dist_array[idx],/N_ELEMENTS)
        
        ; get the structure to check the fields that we have from the first element
        dist_structure = *dist_array[idx]
        dist_structure = dist_structure[0]
        
        ; all field in the current structure
        dist_names = strlowcase(tag_names(dist_structure))
        numel_dist_names = size(dist_names,/N_ELEMENTS)
        
        ; initialize the array container
        for jdx=0,numel_dist_names-1 do begin          
          str_name = dist_names(jdx)
          if (where(str_name eq allowed_fields ) ne -1) && (where(str_name eq arr_names) eq -1) then begin
              arr_names = [arr_names, str_name]
              ; note, that we remember the dimentions for only first occurance of the field
              arr = CREATE_STRUCT(str_name, {name:str_name, type:size(dist_structure.(jdx),/TYPE),dim:size(dist_structure.(jdx),/DIMENSIONS),dimn:size(dist_structure.(jdx),/N_DIMENSIONS)},arr)                                
          endif          
        endfor                  
      endif
    endfor
    ; names that correcpond to the corect index
    arr_names      = strlowcase(tag_names(arr))
    ; if no samples - return
    numel_names = size(arr_names,/N_ELEMENTS)    
    if (total_sample_count eq 0) || (numel_names  eq 0) then return
    
    ; memory allocation    
    ; we need a new structure
    data = {}
    for idx=0,numel_names-1 do begin         
          dim_arr = []
          ; index of the currect structure field
          arr_idx = where(arr_names[idx] eq arr_names)
          ; Check the dim. If it is 0, we will not add additional dimentions          
          if arr.(arr_idx).dimn ne 0 then dim_arr = arr.(arr_idx).dim               
                           
          data = CREATE_STRUCT(arr.(arr_idx).name, MAKE_ARRAY([total_sample_count, dim_arr], type=arr.(arr_idx).type), data)          
    endfor
    ; names that correcpond to the corect data index
    data_names      = strlowcase(tag_names(data))


    ; fill the data
    start_idx = 0
    end_idx   = 0    
    for idx=0,dist_array_n-1 do begin
      if ptr_valid(dist_array[idx]) && (size(*dist_array[idx],/TYPE) eq 8) then begin
        dist_structure = *dist_array[idx]
        dist_names     = strlowcase(tag_names(dist_structure))       
        ; use only named fields        
        end_idx = start_idx + size(*dist_array[idx],/N_ELEMENTS)-1
        for jdx=0,numel_names-1 do begin
          
            arr_idx  = where(arr_names[jdx] eq arr_names)
            data_idx = where(arr_names[jdx] eq data_names)
            dist_idx = where(arr_names[jdx] eq dist_names)
            
            ; Unfortunetelly, direct call of the dist_structure.(dist_idx) will move the time dimention to the last position
            ; It is nessesary to have time dimention at the first position      
            ; Here wew support up to 2 additional dimentions
            if arr.(arr_idx).dimn ne 0 then begin 
             for kdx=0,end_idx-start_idx do begin
              data_sample = dist_structure[kdx]
              switch arr.(arr_idx).dimn of
                1: data.(data_idx)[start_idx + kdx, *] = data_sample.(dist_idx)
                2: data.(data_idx)[start_idx + kdx, *, *] = data_sample.(dist_idx)
              endswitch
             endfor
            endif else begin
              data.(data_idx)[start_idx:end_idx] = dist_structure.(dist_idx)
            endelse
            
        endfor
        start_idx = end_idx+1
      endif
    endfor
    
      
    ; create tplot variables
    ; TODO: add check for time variable
    time_array = data.time
 
     for idx=0,numel_names-1 do begin
      str_name = data_names(idx)
      if str_name ne 'time' then begin
        y = data.(idx)
        tplot_name = 'th' + probe + '_' + datatype + '_dist_array_' + str_name
        store_data,tplot_name,data={x:time_array,y:y}
      endif
    endfor    
end