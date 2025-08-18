;+
;FUNCTION:  thm_component_to_tplot, plot_type, active_vnames
;PURPOSE:
;   Checks the plot type (SPACECRAFT  or COMPONENTS) and creates
;   (if necessary) new tplot variables 
;INPUT:  active_vars  string array of variable names (these are the 
;                     active variables that are currently available)
;        cw           gui id for history window
;        mw           gui id for progress window 
;OUTPUT: new_vars     string array of new active variables, these 
;                     variables are regrouped by SPACECRAFT or COMPONENT
;KEYWORDS:
;SEE ALSO:  "STORE_DATA", "GET_DATA", "SPLIT_VEC", "OPTIONS", "TPLOT"
;
;CREATED BY:  Cindy Goethel
;MODIFICATION BY:   
;LAST MODIFICATION: 
;
;-
function thm_component_to_tplot, active_vars, cw, mw

  ;First check that the active data is in spacecraft mode
  valid_probes=['a', 'b', 'c', 'd', 'e', 'g']
  compare=strmid(active_vars, 2, 1)
  for i=0,n_elements(active_vars)-1 do Begin
    result=where(compare(i) eq valid_probes)
    if result ge 0 then Begin
       mtext = 'Active variable '+active_vars(i)+$
                     ' is already grouped by spacecract. Reselect active data.'
       SPD_UI_UPDATE_PROGRESS, cw, mtext, message_wid = mw
       return, active_vars
    endif 
  endfor
    
  ;OK, so we do need to retrieve the original tplot variables
  ;first get the root name
  root_names=make_array(n_elements(active_vars), /string)
  for i=0,n_elements(active_vars)-1 do Begin
    nlength=strlen(active_vars(i))-1
    root_names(i)=strmid(active_vars(i), 4, nlength)
  endfor
  sort_names=root_names[sort(root_names)]
  uniq_names=sort_names[uniq(sort_names)]

  ;create the wild card search name and retrieve those
  ;tplot variables
  search_names= 'th?_'+uniq_names
  tplot_names, search_names, names=new_names

  ;for each name found, make sure that it is a 
  ;spacecraft variable
  test_names=strmid(new_names, 2, 1)
  new_vars=['']
  for i=0, n_elements(new_names)-1 do Begin
     result=where(test_names(i) eq valid_probes)
     if result ge 0 then new_vars=[new_vars, new_names(i)]
  endfor
  
  if n_elements(new_vars) le 1 &&  new_vars eq '' then Begin
    mtext = 'No loaded variables were found that match the active data. '$
            +'Reselect active data.'
    SPD_UI_UPDATE_PROGRESS, cw, mtext, message_wid = mw
    return, active_vars
  endif else Begin
    new_vars=new_vars(1:*)
  endelse

  tplot, new_vars
  thm_ui_update_data_all, cw, new_vars
  
  return, new_vars
end
