;+ 
;FUNCTION:  thm_tplot_to_component, active_vnames, cw, mw
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
function thm_tplot_to_component, active_vars, cw, mw

  probe_colors=['m','r','g','c','b','y']   ; Standard color choices

  ;First check that the active data is in spacecraft mode
  valid_probes=['a', 'b', 'c', 'd', 'e', 'g']
  compare=strmid(active_vars, 2, 1)
  for i=0,n_elements(active_vars)-1 do Begin
    result=where(compare(i) eq valid_probes)
    if result lt 0 then Begin
       mtext = 'Active variable '+active_vars(i)+$
               ' is not a valid probe data set. Reselect active data.'
       SPD_UI_UPDATE_PROGRESS, cw, mtext, message_wid = mw
       return, active_vars
    endif 
  endfor
  
  ;then check for validity of active data
  for i=0,n_elements(active_vars)-1 do Begin
     get_data, active_vars(i), data=d, dlimits=dl
     if size(d, /type) eq 8 then Begin
        s = size(d.y, /dimensions)
        if n_elements(s) le 1 then Begin
          mtext = 'Active variable '+active_vars(i)+$
                  ' has only one component. Reselect active data.'
          SPD_UI_UPDATE_PROGRESS, cw, mtext, message_wid = mw
          return, active_vars
        endif 
        if s[1] gt 6 then Begin
          n_components=strcompress(string(s[1]))
          mtext = 'Active variable '+active_vars(i)+$
                     ' has'+n_components+' components.'
          SPD_UI_UPDATE_PROGRESS, cw, mtext, message_wid = mw
          question_list=strarr(2)
          question_list[0]= string('Active variable '+active_vars(i)+$
                     ' has'+n_components+' components. ')
          question_list[1]='Do you really want to do this?'
          answer = dialog_message(question_list, /question, title='Components')
          if answer eq 'No' then return, active_vars        
        endif
        dnames=tag_names(dl)
        index=where(dnames eq 'SPEC') 
        if index ge 0 then Begin
          if dl.spec eq 1 then Begin
            mtext = 'Active variable '+active_vars(i)+$
                  ' is spectrographic data. Reselect active data.'
            SPD_UI_UPDATE_PROGRESS, cw, mtext, message_wid = mw
            return, active_vars
          endif
        endif       
     endif else begin
        mtext = 'Active variable '+active_vars(i)+$
                ' does not contain valid data. Reselect active data.'
        SPD_UI_UPDATE_PROGRESS, cw, mtext, message_wid = mw
        return, active_vars
     endelse
  endfor      
  
  ;OK, so we do need to create new variables
  ;first sort active vars by instrument and determine which are unique
  uniq_names=make_array(n_elements(active_vars), /string)
  for i=0,n_elements(active_vars)-1 do Begin
    nlength=strlen(active_vars(i))-1
    uniq_names(i)=strmid(active_vars(i), 4, nlength)
  endfor
  sort_names=uniq_names[sort(uniq_names)]
  instr_names=sort_names[uniq(sort_names)]

  ;now for each uniq instrument
  for inst=0, n_elements(instr_names)-1 do Begin

     ;pull out the variables for this instrument and split
     ;the vector into it's components
     instr_index=where(uniq_names eq instr_names(inst))
     split_vec, active_vars(instr_index), names_out=component_vars    

     ;figure the unique component names
     slength=strlen(component_vars)
     unames=make_array(n_elements(component_vars), /string)
     for i=0,n_elements(component_vars)-1 do Begin
       unames(i)=strmid(component_vars(i), fix(slength(i)-2), 2)
     endfor
     sort_names=unames[sort(unames)]
     component_names=sort_names[uniq(sort_names)]

     ;and for each unique component name regroup the 
     ;variables, create new tplot names, labels, and colors
     rlength=n_elements(component_names)
     new_names=make_array(rlength, /string)
     new_titles=make_array(rlength, /string)     
     for i=0, rlength-1 do Begin
       ind=where(unames eq component_names(i))
       if i eq 0 then data_names=strarr(rlength, n_elements(ind))
       new_names(i)='th'+strmid(component_names(i),1,1)+'_'+instr_names(inst)
       if strmid(instr_names(inst),0,3) eq 'mag' then Begin
          new_titles(i)='th'+strmid(component_names(i),1,1)+'_'+instr_names(inst)
       endif else Begin
          new_titles(i)='th'+strmid(component_names(i),1,1)+'_'+strmid(instr_names(inst),0,3)
       endelse       
       data_names(i,*)=component_vars(ind)
     endfor

     ;finally ready to create tplot variables
     dsize = size(data_names, /dimension)
     if n_elements(dsize) lt 2 then nsize=1 else nsize=dsize(1)
     for i=0, dsize(0)-1 do Begin
       get_data, data_names(i,0), data=d, dlimits=dl
       if size(d,/type) ne 8 then Begin
          mtext = 'Variable '+data_names(i:0)+$
                  ' are not valid tplot data. Reselect active data.'
          SPD_UI_UPDATE_PROGRESS, cw, mtext, message_wid = mw
          return, active_vars
       endif
       dx = d.x
       dnew = [d.y]
       probe_letter = strmid(data_names(i,0),2,1)
       pnum = byte(probe_letter) - (byte('a'))[0]
       pn=[probe_colors(pnum)]
       for j=1, nsize(0)-1 do Begin
          get_data, data_names(i,j), data=d, dlimits=dl            
          if size(d,/type) ne 8 then Begin
             mtext = 'Variable '+data_names(i,j)+$
                     ' are not valid tplot data. Reselect active data.'
             SPD_UI_UPDATE_PROGRESS, cw, mtext, message_wid = mw
             return, active_vars
          endif
          dy=congrid(d.y, n_elements(dx))
          dnew = [dnew, dy]
          probe_letter = strmid(data_names(i,j),2,1)
          pnum = byte(probe_letter) - (byte('a'))[0]
          pn=[pn,probe_colors(pnum)]
        endfor
        dnew=reform(dnew, n_elements(dx), nsize)
        d2={x:dx, y:dnew}
        labels=reform(string(strmid(data_names(i,*), 0, 3)))
        dl2={colors:pn,labels:labels, labflag:1}
        store_data, new_names(i), data=d2, dlimits=dl2
        options, new_names(i), ytitle=new_titles(i), labflag=1, labels=labels,$
        color_table=39 
     endfor
     if inst eq 0 then new_vars=new_names else new_vars=[new_vars, new_names]
  endfor   

  tplot, new_vars
  thm_ui_update_data_all, cw, new_vars
  
  return, new_vars
end
