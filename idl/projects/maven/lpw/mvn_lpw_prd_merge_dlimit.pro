;+
;PROCEDURE:   mvn_lpw_prd_merge_dlimit
;
;Routine combines dlimit structures for tplot variables. Input variables must have the same size dlimit structures, with the same field names. 
;
;INPUTS:         
;
; - found_variables: a string array of tplot variables in IDL memory, whose dlimits are to be merged. THE FIRST ENTRY of this array is assumed to be
;                    a dummy string with text information.
;   
;KEYWORDS:
; NONE
; 
;EXAMPLE:
; dlimit_merge = mvn_lpw_prd_merge_dlimit(['Variables to merge', 'mvn_lpw_act_e12', 'mvn_lpw_pas_e12'])
;
;
;CREATED BY:   Chris Fowler  05-21-2014
;FILE:         mvn_lpw_prd_merge_dlimit.pro
;VERSION:      1.0
;LAST MODIFICATION: 
;
;
;-

function mvn_lpw_prd_merge_dlimit, found_variables

;Checks:
if size(found_variables, /type) ne 7 then begin
     print, "### WARNING ###: mvn_lpw_prd_merge_dlimit: input tplot variables must be a string array, returning empty dlimit structure..."
     return, create_struct('NO_DLIMIT_INFO', fltarr(10)) ;return an empty structure if no string inputs given
endif

nele_vars = n_elements(found_variables)-1  ;first element is text  
;-----------------------
;get_data for input  variables:
st_string = "get_data,'"+strtrim(found_variables[1],2)+"',dlimit=dl1"  ;first element is dummy text
for z = 2, nele_vars do st_string = st_string+" & get_data,'"+strtrim(found_variables[z],2)+"',dlimit=dl"+strtrim(string(z),2)
;print,st_string
st_result = execute(st_string)  ;use get_data on all tplot dlimit variables we want to get
;-----------------------

if nele_vars eq 1 then begin  ;we only have one dlimit variable
    dlimit_merge = dl1  ;straight copy
endif

if nele_vars gt 1 then begin  ;more than 1 tplot dlimit to merge
    ;dlimit and limit info should be identical for most fields. The fields that differ are: time_start, time_end, min, max, yrange
    ;Make an structure, within which we place the dlimit structures
    
    dlimit_merge = dl1  ;use dl1 as the main copy, edit fields from here:
    
    dl_st = replicate(dl1, nele_vars)  ;replicate dl1. Now replace each field with those from dl2, dl3, etc:
    nele_tags = n_tags(dl1)  ;number of dlimit tags
    fieldnames = tag_names(dl1)  ;names of the dlimit fields, assumed the same for all entered tplot variables
    
    for aa = 1, nele_vars-1 do begin
        
        for bb = 0, nele_tags-1 do begin
            tn = strtrim(string(fieldnames[bb]),2)  ;dlimit field name
            
            st_string = "dl_st["+strtrim(string(aa),2)+"]."+tn+" = dl"+strtrim(string(aa)+1,2)+"."+tn      
            st_result = execute(st_string)  ;time field            
            
        endfor  ;over bb
        
    endfor ;over aa     
  
    ;Now merge specific dlimit fields:
    
    nmf = ['time_start', 'time_end', 'scalemin', 'scalemax'] ;number merge fields
    smf = ['Generation_date', 'SPICE_kernel_version', 'SPICE_kernel_flag', 'L0_datafile', 'cal_vers', $
           'cal_y_const1', 'cal_source', 'cal_v_const1']   ;dlimit fields to merge; some may not be present. String merge field
    single_mf = ['SPICE_kernel_version', 'SPICE_kernel_flag', 'L0_datafile'] ;we only want one copy of these if they're all the same for each tplot variable
    
    ;Fields not merged as they are identical: 
    ;time_field,
    
    nele_nmf = n_elements(nmf) 
    nele_smf = n_elements(smf)
    nele_single_mf = n_elements(single_mf)
    
    for aa = 0, nele_nmf-1 do begin  ;first 3 are SPICE, deal with here
        if total(strmatch(fieldnames, nmf[aa], /fold_case)) eq 1 then begin  ;if that tag names exists
            ;When checking start and stop times, the size of the array depends on whether we've used SPICE or not. This line determines which line to check.
            if n_elements(dl_st[0].time_start) eq 2 then tc_ind = 1. else tc_ind = 4.
            
            if nmf[aa] eq 'time_start' then begin  ;time_start arrays must be the same size for all variables. Same for time_end
                tst = dblarr(nele_vars)  ;store start unix times for each variable
                for zz = 0, nele_vars-1 do tst[zz] = dl_st[zz].time_start[tc_ind]  ;add start times to tst
                soort = sort(tst)  ;last element in soort is the highest, first element is lowest start time               
                dlimit_merge.time_start = dl_st[soort[0]].time_start
            endif
            if nmf[aa] eq 'time_end' then begin
                est = dblarr(nele_vars)  ;store start unix times for each variable
                for zz = 0, nele_vars-1 do est[zz] = dl_st[zz].time_end[tc_ind]  ;add start times to tst
                soort = reverse(sort(est))  ;first element in soort is the highest, last element is lowest start time               
                dlimit_merge.time_end = dl_st[soort[0]].time_end
            endif
            if nmf[aa] eq 'scalemin' then begin
                tmi = dblarr(nele_vars)  ;store start unix times for each variable
                for zz = 0, nele_vars-1 do tmi[zz] = dl_st[zz].scalemin  ;add start times to tst
                soort = sort(tmi)  ;last element in soort is the highest, first element is lowest start time               
                dlimit_merge.scalemin = dl_st[soort[0]].scalemin
            endif            
            if nmf[aa] eq 'scalemax' then begin
                tma = dblarr(nele_vars)  ;store start unix times for each variable
                for zz = 0, nele_vars-1 do tma[zz] = dl_st[zz].scalemax  ;add start times to tst
                soort = reverse(sort(tma))  ;last element in soort is the highest, first element is lowest start time               
                dlimit_merge.scalemax = dl_st[soort[0]].scalemax
            endif                             
            
        endif        
    endfor  ;over aa
    
   
    for aa = 0, nele_smf -1 do begin  ;Only STRINGS can be combined in this loop:
        if total(strmatch(fieldnames, smf[aa], /fold_case)) eq 1 then begin  ;if that tag names exists
            st_string = "dlimit_merge."+strtrim(string(smf[aa]),2)+" = dl1."+strtrim(string(smf[aa]),2)
            for bb = 1, nele_vars-1 do begin 
                st_string = st_string+"+' # '+dl"+strtrim(string(bb)+1,2)+"."+strtrim(string(smf[aa]),2)
            endfor  ;over bb
            st_result = execute(st_string)
            
        endif
        
    endfor  ;over aa
    
    for aa = 0, nele_single_mf-1 do begin
          ;Extract strings separated by ' # ' into a string array so we can compare them and ignore copies:
          if total(strmatch(fieldnames, single_mf[aa], /fold_case)) eq 1 then begin  ;if the tag name exists
              string = "st_string = dlimit_merge."+strtrim(single_mf[aa],2)  ;the string to look at
              st_result = execute(string)  ;get the dlimit string
              ;Extract the field entries based on splitting by ' # ':
              inds = strsplit(st_string, ' # ', /regex)
              nele_inds = n_elements(inds)
              if nele_inds gt 1 or nele_inds ne -1 then begin  ;if '#' is found, we have at least two entries
                  tmp_str = ['tmp']  ;temp array
                  for kk = 0, nele_inds-2 do begin
                      new_tmp = strtrim(strmid(st_string, inds[kk], (inds[kk+1] - inds[kk]-2)),2)
                      tmp_str = [tmp_str, new_tmp]
                      
                  endfor  ;over kk
                  ;get last point use strlen
                  slen = strlen(st_string)
                  new_tmp = strtrim(strmid(st_string, inds[nele_inds-1], slen-inds[nele_inds-1]),2)
                  tmp_str = [tmp_str, new_tmp]
                  
                  ;Make another temp array to store final entries which are not repeated:
                  tmp_final = ['temp_final']
                  nele_tmp = n_elements(tmp_str)
                  for ll = 1, nele_tmp -1 do if total(strmatch(tmp_final, tmp_str[ll])) eq 0 then tmp_final = [tmp_final, tmp_Str[ll]]
                  
                  ;Remove first line of tmp_final as its dummy text:
                  nele_tmp_final = n_elements(tmp_final)
                  tmp_final = tmp_final[1:nele_tmp_final-1]
                  
                  ;Add tmp_final to dlimit_merge:
                  st_string2 = "dlimit_merge."+strtrim(single_mf[aa],2)+" = '"
                  for ll = 0, nele_tmp_final-2 do st_string2 = st_string2 + " # "+strtrim(tmp_final[ll],2)
                  st_string2 = st_string2+"'"
                  result2 = execute(st_string2)
                                   
              endif
                        
          endif  ;tag name exists
   
    endfor  ;over aa
    
endif  ;multiple variables to merge

return, dlimit_merge

end

