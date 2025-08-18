
;+
; Procedure: evaluator_routines
;
; Purpose: When called this routine compiles a library of helper routines
;          for the evaluator of the mini_language
;           
; $LastChangedBy: pcruce $
; $LastChangedDate: 2016-06-16 16:20:59 -0700 (Thu, 16 Jun 2016) $
; $LastChangedRevision: 21331 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/mini/evaluator_routines.pro $
;- 

;constructs a tvar data struct for mini_routines used in evaluation
function make_tvar_data,name,data,limits,dlimits

  compile_opt hidden

  if in_set('x',strlowcase(tag_names(data))) then begin
     x = data.x
  endif else begin
     x = ''
  endelse

  if in_set('y',strlowcase(tag_names(data))) then begin
     y = data.y
  endif else begin
     message,'Y component of tplot variable missing.  Name: ' + name
  endelse

  if in_set('v',strlowcase(tag_names(data))) then begin
     v = data.v
  endif else begin
     v = ''
  endelse

  if is_equal(limits,0) then begin
     l = ''
  endif else begin
     l = limits
  endelse

  if is_equal(dlimits,0) then begin
     dl = ''
  endif else begin
     dl = dlimits
  endelse

  return,{type:'tvar_data',name:name,times:x,data:y,yvalues:v,limits:l,dlimits:dl}

end

;constructs a var data struct for mini_routines used in evaluation
function make_var_data,name,data

  compile_opt hidden

  return,{type:'var_data',name:name,data:data}

end

;list is optional
function make_arg_list,arg,list

  compile_opt hidden

  if ~keyword_set(list) then begin
    return,{type:'arg_list',data:arg,length:1,next:''}
  endif
  
  return,{type:'arg_list',data:arg,length:(list.length+1),next:list}

end

;turns a tvar data type from evaluation into a data component for use with store_data
function make_data_type,tvar_type

  compile_opt hidden

  if ~is_tvar_data(tvar_type) || (is_equal(tvar_type.yvalues,'') && is_equal(tvar_type.times,'')) then begin
     
     return,{y:tvar_type.data}

  endif else if is_equal(tvar_type.yvalues,'') then begin

     return,{x:tvar_type.times,y:tvar_type.data}

  endif else if is_equal(tvar_type.times,'') then begin

     return,{y:tvar_type.data,v:tvar_type.yvalues}

  endif else begin

     return,{x:tvar_type.times,y:tvar_type.data,v:tvar_type.yvalues}

  endelse

end

;turns a tvar data type from evaluation into a limits component for use with store_data
function make_limits_type,tvar_type

  compile_opt hidden

  if ~is_tvar_data(tvar_type) || is_equal(tvar_type.limits,'') then begin
     return,0
  endif else begin
     return,tvar_type.limits
  endelse

end

;turns a tvar data type from evaluation into a dlimits component for use with store_data
function make_dlimits_type,tvar_type

  compile_opt hidden

  if ~is_tvar_data(tvar_type) || is_equal(tvar_type.dlimits,'') then begin
     return,0
  endif else begin
     return,tvar_type.dlimits
  endelse

end


;replaces the data component of variable or tplot variable
;This is for use in cases where the new data compnent may have
;different dimensions
function replace_data,var,data

  compile_opt hidden
  
  if is_var_data(var) then begin
    return,make_var_data(var.name,data)
  endif else begin
    return,{type:var.type, $
            name:var.name, $
            times:var.times, $
            data:data,$
            yvalues:var.yvalues,$
            limits:var.limits,$
            dlimits:var.dlimits}
  endelse
  
end

;performs a dimensional correction so
;that operations that would collapse the leading
;dimension transform from MxN to 1xN, this
;makes handling elsewhere more consistent
function dim_correct_data,data,xdim,opdim

  compile_opt hidden

    if opdim eq 1 && xdim gt 1 then begin
      return,reform(data,[1,dimen(data)])
    endif else begin
      return,data
    endelse

end

;Certain operations will result in fewer dimensions.
;If there are associated times, these must
;have a corresponding reduction for the quantity to remain
;well-formed
function reduce_times,var,dim

  compile_opt hidden
  
  if is_tvar_data(var) && ~is_equal(var.times,'') && $   
     (~keyword_set(dim) || dim.data eq 0 || dim.data eq 1) then begin
    
    return,{type:var.type, $
            name:var.name, $
            times:ndimen(var.times)?median(var.times,/even):median([var.times],/even), $
            data:var.data,$
            yvalues:var.yvalues,$
            limits:var.limits,$
            dlimits:var.dlimits}
    
  endif else begin
  
    return,var
    
  endelse
  
end

;Certain operations will result in fewer dimensions.
;If there are associated yvalues, these must
;have a corresponding reduction for the quantity to remain
;well-formed
function reduce_yvalues,var,dim

  compile_opt hidden
  
  if is_tvar_data(var) && ~is_equal(var.yvalues,'') then begin
    if ~keyword_set(dim) || dim.data eq 0 then begin
      return,{type:var.type, $
              name:var.name, $
              times:var.times, $
              data:var.data,$
              yvalues:ndimen(var.yvalues)?median(var.yvalues,/even):median([var.yvalues],/even),$
              limits:var.limits,$
              dlimits:var.dlimits}    
    endif else if dim.data eq 1 then begin
      if ndimen(var.yvalues) ge 2 then begin
        return,{type:var.type, $
                name:var.name, $
                times:var.times, $
                data:var.data,$
                yvalues:dim_correct_data(median(var.yvalues,dim=1,/even),ndimen(var.yvalues),1),$
                limits:var.limits,$
                dlimits:var.dlimits}
      endif
    endif else if dim.data eq 2 then begin
      if ndimen(var.yvalues) ge 2 then begin
       return,{type:var.type, $
              name:var.name, $
              times:var.times, $
              data:var.data,$
              yvalues:median(var.yvalues,dim=2,/even),$
              limits:var.limits,$
              dlimits:var.dlimits}
      endif else begin
       return,{type:var.type, $
              name:var.name, $
              times:var.times, $
              data:var.data,$
              yvalues:ndimen(var.yvalues)?median(var.yvalues,/even):median([var.yvalues],/even),$
              limits:var.limits,$
              dlimits:var.dlimits}
      endelse
    endif
  endif
  
  return,var

end

;Certain operations will result in fewer dimensions.
;If there are associated limits/dlimits, this
;will reduce the labels/colors
function reduce_dlimits,var,label,dim

  if ~keyword_set(dim) || dim.data ne 2 then return,var  ; only applies if totaling over dim 2

  var_out = var
  dlimits = make_dlimits_type(var)

  if keyword_set(dlimits) then begin
    if in_set(strlowcase(tag_names(dlimits)),'dlimits') then begin
      dl = dlimits.dlimits
    endif else begin
      dl = dlimits
    endelse
    
    if in_set(strlowcase(tag_names(dl)),'colors') && n_elements(dl.colors) gt 1 then begin
      str_element,dl,'colors',0,/add
    endif
    
    if in_set(strlowcase(tag_names(dl)),'labels') && n_elements(dl.labels) gt 1 then begin
      str_element,dl,'labels',label,/add
    endif
    
    if in_set(strlowcase(tag_names(dlimits)),'dlimits') then begin
      str_element,dlimits,'dlimits',dl,/add
    endif else begin
      dlimits = dl
    endelse
    
    str_element,var_out,'dlimits',dlimits,/add
  endif
  
  limits = make_limits_type(var)
  
  if keyword_set(limits) then begin
  
    if in_set(strlowcase(tag_names(limits)),'colors') && n_elements(limits.colors) gt 1 then begin
      str_element,limits,'colors',0,/add
    endif
    
    if in_set(strlowcase(tag_names(limits)),'labels') && n_elements(limits.labels) gt 1 then begin
      str_element,limits,'labels',label,/add
    endif
    
    str_element,var_out,'limits',limits,/add
  
  endif
  
  return,var_out
  
end

;abstraction routine determines whether its input is a tvar type or not
; this is different from a tvar data type 1=yes 0=no
function is_tvar_type,in

  compile_opt idl2,hidden
  
  mini_predicates
  
  if is_string_type(in) then begin
    return,1
  endif else begin
    return,0
  endelse

end

;abstraction routine determines whether its input is a var type or not
;this is different from a var data type 1=yes 0=no
function is_var_type,in 

  compile_opt idl2,hidden
  
  mini_predicates

  if is_identifier_type(in) then begin
    return,1
  endif else begin
    return,0
  endelse
  
end

;abstracts the data storage process
pro store_var_data,name,value

  compile_opt hidden

  if is_tvar_type(name) then begin
  overwrite_selection = ''
  overwrite_count = (*!mini_globals.replay_struct).overwrite_count
  gui_prompt_obj = (*!mini_globals.replay_struct).calc_prompt_obj

  ; correctly handle 'yes to all' and 'no to all' selections
  if (*!mini_globals.replay_struct).replay ne 1 then begin
      ; not replaying a document, check the user's previous selection. If the user selected '*toall', it *should* be stored as the last selection
      previous_selection = (*!mini_globals.replay_struct).overwrite_selections[n_elements((*!mini_globals.replay_struct).overwrite_selections)-1]
  endif else begin
      ; Need to check if the user selected yestoall or notoall in the saved document to correctly handle the
      ; case where a user selects 'no' followed by 'yestoall', or 'yes' followed by 'notoall'
      ; we need to check where the 'yes/notoall' is in the array relative to where we are in replaying the calc operations
      whereyestoall = where((*!mini_globals.replay_struct).overwrite_selections eq 'yestoall', yestoallcount)
      wherenotoall = where((*!mini_globals.replay_struct).overwrite_selections eq 'notoall', notoallcount)
      if yestoallcount then if (*!mini_globals.replay_struct).overwrite_count ge whereyestoall[0] then overwrite_selection = 'yestoall'
      if notoallcount then if (*!mini_globals.replay_struct).overwrite_count ge wherenotoall[0] then overwrite_selection = 'notoall'
      previous_selection = ''
  endelse 
  
  if previous_selection eq 'notoall' then overwrite_selection = 'notoall'
  if previous_selection eq 'yestoall' then overwrite_selection = 'yestoall'
  ; check if we're storing tplot data in the TDAS GUI
  ; if so, check if the variable exists in the loadedData object
  ; if it exists, prompt the user to overwrite it
    if obj_valid(!mini_globals.gui_data_obj) then begin 
        names = !mini_globals.gui_data_obj->getall()

        wherenames = where(name.value eq names, wherecount)

        if wherecount gt 0 then begin
           ; new variable already exists  
           if overwrite_selection ne 'yestoall' then begin
              if overwrite_selection eq 'notoall' then return
               
               overwrite_selection = ''
               
               if (*!mini_globals.replay_struct).replay ne 0 then begin
                   if overwrite_count gt n_elements((*!mini_globals.replay_struct).overwrite_selections) then begin
                     hwin = (*!mini_globals.replay_struct).historywin
                     sbar = (*!mini_globals.replay_struct).statusbar
                     if obj_valid(hwin) then hwin->update,"ERROR:Discrepancy in themis document, may have lead to a document load error"
                     if obj_valid(sbar) then sbar->update,"ERROR:Discrepancy in themis document, may have lead to a document load error"
                     overwrite_selection = "yestoall"
                   endif else begin
                     overwrite_selection = ((*!mini_globals.replay_struct).overwrite_selections)[overwrite_count]
                   endelse         
               endif else begin
                   prompt = 'Do you want to overwrite '+name.value+' with the new data?'

                   if obj_valid(gui_prompt_obj) then begin
                       overwrite_selection = gui_prompt_obj->sendtoScreen(prompt, 'Overwrite Existing Data?', gui_id = (*!mini_globals.replay_struct).gui_id)
                   endif else begin
                       dprint,dlevel=0,'Error in store_var_data, no valid GUI prompt object'
                   endelse
                   newarray = array_concat_wrapper(overwrite_selection,(*!mini_globals.replay_struct).overwrite_selections)
                   str_element, *!mini_globals.replay_struct, 'overwrite_selections', newarray, /add_rep
               endelse
               ; increase the count by one
               (*!mini_globals.replay_struct).overwrite_count = (*!mini_globals.replay_struct).overwrite_count + 1

               if overwrite_selection eq 'no' || overwrite_selection eq 'notoall' then begin
                 return
               endif
           endif

        endif 
       
       data = make_data_type(value)
       limits = make_limits_type(value)
       tmp_limits = make_dlimits_type(value)
       
       dlimits = tmp_limits.dlimits
              
       store_data,name.value,data=data,limits=limits,dlimits=dlimits,error=e

       if e then begin
         message,'store_data error'
       endif
       
       if ~!mini_globals.gui_data_obj->add(name.value) then begin
         message,'loaded_data error'
       endif

    endif else begin
    limits = make_limits_type(value)
    dlimits = make_dlimits_type(value)
    ;unset inherited parameters
    str_element,limits,'ytitle',/delete
    str_element,dlimits,'ytitle',/delete
    str_element,limits,'ysubtitle',/delete
    str_element,dlimits,'ysubtitle',/delete
    str_element,limits,'yrange',/delete
    str_element,dlimits,'yrange',/delete
    
    str_element,limits,'ztitle',/delete
    str_element,dlimits,'ztitle',/delete
    str_element,limits,'zsubtitle',/delete
    str_element,dlimits,'zsubtitle',/delete
    str_element,limits,'zrange',/delete
    str_element,dlimits,'zrange',/delete
    
    ;log scaling still inherited
    
      store_data,name.value,data=make_data_type(value),limits=limits,dlimit=dlimits,error=e
           
      if e then begin
        message,'store_data error'
      endif
    endelse

  ;  dprint,setdebug=g

  endif else if is_var_type(name) then begin
  
    (scope_varfetch(name.value,/enter,level=!mini_globals.scope_level)) = value.data
   
  endif else begin
  
    message,'Wrong type in store_var_data'
  
  endelse

end

;determines whether an entry in the parse table is an error or not
function is_error_code,in

  compile_opt idl2,hidden
  
  if is_equal(in,'') then begin 
    return,1
  endif else begin
    return,0
  endelse
  
end 
   
;determines whether an entry in the parse table is a shift code or not
function is_shift_code,in 

  compile_opt idl2,hidden 
  
  if strlen(in) gt 1 && strmid(in,0,1) eq 's' then begin
    return,1
  endif else begin
    return,0
  endelse
  
end

;gets the shift code from a parse table entry
function get_shift_num,in

  compile_opt idl2,hidden
  
  if strlen(in) lt 2 then begin
    return,-1
  endif else begin
    return,long(strmid(in,1))
  endelse
  
end

;determines whether an entry in the parse table is a reduce code or not
function is_reduce_code,in 

  compile_opt idl2,hidden 
  
  if strlen(in) gt 1 && strmid(in,0,1) eq 'r' then begin
    return,1
  endif else begin
    return,0
  endelse
  
end

;determines if binary operator arguments are compatible
function is_valid_bop_arg,arg1,arg2,arg3

  compile_opt idl2,hidden
  
  dim1 = dimen(arg1.data)
  dim2 = dimen(arg3.data)
  ndim1 = ndimen(arg1.data)
  ndim2 = ndimen(arg3.data) 
  
  ;scalar exemption
  if product(dim1) eq 1 || product(dim2) eq 1 then return,1
  
  ;matrix multiplication rules type 1
  if arg2.name eq '#' then begin
  
    if ndim1 eq 1 && ndim2 eq 1 then return,1
    
    if ndim1 eq 1 && ndim2 eq 2 && $
       dim1[0] eq dim2[0] then return,1
    
    if ((ndim1 eq 2 && ndim2 eq 1) || $
       (ndim1 eq 2 && ndim2 eq 2)) && $
       dim1[1] eq dim2[0] then return,1
  
  ;matrix multiplication rules type 2
  endif else if arg2.name eq '##' then begin
  
    if ndim1 eq 1 && ndim2 eq 1 then return,1
    
    if ndim1 eq 2 && ndim2 eq 1 && $
       dim1[0] eq dim2[0] then return,1
       
    if ((ndim1 eq 1 && ndim2 eq 2) || $
        (ndim1 eq 2 && ndim2 eq 2)) && $
        dim1[0] eq dim2[1] then return,1
        
  ;other operation rules
  endif else begin

     if array_equal(dim1,dim2) then return,1  
       
  endelse
       
  return,0

end

;gets the reduce code from a parse table entry
function get_reduce_num,in

  compile_opt idl2,hidden
  
  if strlen(in) lt 2 then begin
    return,-1
  endif else begin
    return,long(strmid(in,1))
  endelse
  
end

;evaluates each token passed to it.
;the most important aspect of this function
;is to translate tokens from the lexer into a format that
;the evaluator can read.  This entails making sure the name component of
;the output structure is a terminal from the language grammar 
function eval_token,token,previous,grammar

  compile_opt idl2,hidden
  
  mini_predicates
  mini_routines
  
  if is_function_type(token) then begin
      
      tk = get_function(token)
            
      if ~is_struct(tk) then begin
        return, {type:'error',name:'function lookup error',value:token.name,position:n}
      endif else begin
      
        tk.name = 'func'
      
        ev = tk
      endelse
      
  endif else if is_var_type(token) then begin
  
    ev = {type:token.type,name:'var',value:token.name,index:0}
     
  endif else if is_tvar_type(token) then begin
  
    ev = {type:token.type,name:'tvar',value:strmid(token.name,1,strlen(token.name)-2),index:0}
    
  endif  else if is_operator_type(token) then begin
    
    ev = token
    
    if token.name eq '-' then begin
      if is_unary_minus(token,previous) then begin 
        ev.name = 'u-'
      endif else begin
        ev.name = 'b-'
      endelse
      ev.value = token.name
    endif else if token.name eq '+' then begin
      if is_unary_plus(token,previous) then begin
        ev.name = 'u+'
      endif else begin
        ev.name = 'b+'
      endelse
      ev.value = token.name
    endif else if token.name eq '/' then begin
      if is_keyword_slash(token,previous) then begin
        ev.name = 'k/'
      endif else begin
        ev.name = 'b/'
      endelse
      ev.value = ev.name
    endif
     
  endif else if is_assignment_type(token) then begin
    
   ev = token 
   
   if strlen(token.value) gt 1 then begin
     ev.value = strmid(token.value,0,1)
   endif
    
   if ev.value eq '-' then begin
     ev.value = 'b-'
   endif else if ev.value eq '+' then begin
     ev.value = 'b+'
   endif
      
  endif else if is_numerical_type(token) then begin
  
    if strpos(token.name,'u') ne -1 then begin
      unsigned = 1
    endif else begin
      unsigned = 0
    endelse
    
    if strpos(token.name,'b') ne -1 then begin
    
      ev = {type:token.type,name:'number',value:byte(token.name),index:0}
      
    endif else if strpos(token.name,'s') ne -1 then begin
    
      if unsigned then begin   
        ev = {type:token.type,name:'number',value:uint(token.name),index:0}        
      endif else begin
        ev = {type:token.type,name:'number',value:fix(token.name),index:0}
      endelse
    
    endif else if strpos(token.name,'d') ne -1 then begin
    
      ev = {type:token.type,name:'number',value:double(token.name),index:0}  
                  
    endif else if strpos(token.name,'e') ne -1 || $
                  strpos(token.name,'.') ne -1 then begin
                  
      ev = {type:token.type,name:'number',value:float(token.name),index:0}
      
    endif else if strpos(token.name,'ll') ne -1 then begin
    
      if unsigned then begin   
        ev = {type:token.type,name:'number',value:ulong64(token.name),index:0}        
      endif else begin
        ev = {type:token.type,name:'number',value:long64(token.name),index:0}
      endelse
    
    endif else if strpos(token.name,'l') ne -1 then begin
      
      if unsigned then begin   
        ev = {type:token.type,name:'number',value:ulong(token.name),index:0}
      endif else begin
        ev = {type:token.type,name:'number',value:long(token.name),index:0}   
      endelse
      
    endif else begin
    
      ev = {type:token.type,name:'number',value:float(token.name),index:0}
      
    endelse
  endif else begin
  
    ev = {type:token.type,name:token.name,value:token.name,index:0}
    
  endelse
  
  idx = where(ev.name eq grammar.terminals)
  
  if idx[0] eq -1 then begin
  
    message,'token should always evaluate to a terminal in language'
    
  endif
  
  ev.index = idx
  
  return,ev
  
end

;validates arguments for mini functions
;No return value, throws error on fail(using message)
;required_args: The number of required positional arguments
;optional_args: The number of optional arguments
;keyword_list: The list of accepted keywords list of strings('' or 0 if none)
;arg_list: The list of arguments to be validated
;Checks:
;  Number of args matches required
;  No more than requested # of optional args
;  No illegal keywords (keyword arguments that match no valid keywords)
;  No ambiguous keywords (partial keyword arguments that match multiple valid keywords)
 
pro validate_mini_func_args,required_args,optional_args,keyword_list,arg_list

  compile_opt hidden,strictarr

  arg_count = 0
  keyword_count = lonarr(n_elements(keyword_list))
  arg_iter = arg_list
  
  while keyword_set(arg_iter) do begin ;next will be undefined or '' or 0 in base case
  
    if ~is_keyword_type(arg_iter.data) then begin
      arg_count++
    endif else begin
    
      ;no keywords accepted
      if ~keyword_set(keyword_list) then message,'Illegal keyword: ' + arg_iter.data.value
      
      keyword_matches = stregex(keyword_list,'^'+arg_iter.data.value,/boolean,/fold_case)
      
      idx = where(keyword_matches ne 0,c)
      if c eq 0 then message,'Illegal keyword: ' + arg_iter.data.value
      
      keyword_count += keyword_matches
      idx = where(keyword_count gt 1,c)
      if c gt 0 then message,'Ambiguous keyword: ' + arg_iter.data.value
      
    endelse
  
    arg_iter = arg_iter.next
  
  endwhile

  if arg_count lt required_args then message,'Missing required argument(s)'
  if arg_count gt optional_args+required_args then message,'Too many arguments'
  
end
;Checks linked list arg-struct structure to
;determine if the keyword is set.
;Argument validation is done elsewhere(ambiguous keywords,illegal keywords)
;Returns the element number(not index) of the argument that matches the keyword, done for backward compatibility with keyword_set calls
function is_mini_keyword_set,arg_list,keyword

  compile_opt hidden,strictarr

  if ~keyword_set(arg_list) then return,0 ; could be 0 or '' or undefined
  if is_keyword_type(arg_list.data) && $
     stregex(keyword,'^'+arg_list.data.value,/boolean,/fold_case) then return,1
 
  ;recursive call 
  if arg_list.length gt 1 then begin
    result = is_mini_keyword_set(arg_list.next,keyword)
    if result gt 0 then return,result+1
  endif
  
  return,0 
  
  
;  matches = stregex(keyword_list,'^'+arg_struct.value,/boolean,/fold_case)
;  idx = where(matches,c)
;  
;  if c eq 0 then begin
;    message,'Illegal keyword: ' + arg_struct.value
;  endif else if c gt 1 then begin
;    message,'Ambiguous keyword: ' + arg_struct.value
;  endif
  
  
end

;Checks linked list arg-structure to 
;  find the nth positional argument. (counting from 0)
;  keyword arguments are skipped
function get_positional_arg,arg_list,n

  compile_opt hidden,strictarr
  
  if ~keyword_set(arg_list) then return,0

  if is_keyword_type(arg_list.data) then begin
    if arg_list.length eq 1 then begin ;keyword and no more elements
      return, 0 ;element not found
    endif else begin ;keyword and more elements
      return, get_positional_arg(arg_list.next,n) ;check next element 
    endelse
  endif 
  
  if n eq 0 then return, arg_list.data ;not keyword and 0th requested(found it!)
  
  if arg_list.length eq 1 then return,0 ;not keyword and gt 0th requested(not enough elements)
  
  return, get_positional_arg(arg_list.next,n-1) ;otherwise, skip this position, and decrement positional arg
  
  ;cases covered above
  ;length == 1, type==keyword, return 0
  ;length == 1, type!=keyword, n == 0, return type
  ;length > 1, type==keyword, return recursive(next,n)
  ;length > 1, type!=keyword, n==0, return type
  ;length > 1, type!=keyword, n>0, return recursive(next,n-1)
    
  
end  

;Checks linked list arg-structure to
;  find the nth positional argument. (counting from 0)
;  keyword arguments are not skipped
function get_keyword_arg,arg_list,n

  compile_opt hidden,strictarr

  if ~keyword_set(arg_list) then return,0

  if n eq 0 then return, arg_list.data ;0th requested(found it!)

  if arg_list.length eq 1 then return,0 ;gt 0th requested(not enough elements)

  return, get_keyword_arg(arg_list.next,n-1) ;otherwise, skip this position, and decrement positional arg

end
;this routine just compiles all the routines in this file 
pro evaluator_routines

end
 
