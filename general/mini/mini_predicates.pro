;+
;
;Procedure: mini_predicates
;
;Purpose:  mini_predicates compiles a library of type checking predicates for 
;          many of the different types used in the mini language.  Type predicates
;          that are not defined here are defined in evaluator_routines.pro
;
;
; $LastChangedBy: pcruce $
; $LastChangedDate: 2013-05-10 17:04:22 -0700 (Fri, 10 May 2013) $
; $LastChangedRevision: 12331 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/mini/mini_predicates.pro $
;- 


function is_endline_type,token

  compile_opt idl2,hidden
  
  if token.type eq 'endline' then begin
    return,1
  endif else begin
    return,0
  endelse

end

function is_string_type,token

  compile_opt idl2,hidden

  if token.type eq 'string' then begin
    return,1
  endif else begin
    return,0
  endelse

end

function is_numerical_type,token

  compile_opt idl2,hidden

  if token.type eq 'number' then begin
    return,1
  endif else begin
    return,0
  endelse

end

function is_continuation_type,token

  compile_opt idl2,hidden

 if token.type eq 'continuation' then begin
    return,1
  endif else begin
    return,0
  endelse

end

function is_termination_type,token

  compile_opt idl2,hidden

  if token.type eq 'termination' then begin
    return,1
  endif else begin
    return,0
  endelse

end


function is_error_type,token

  compile_opt idl2,hidden

  if token.type eq 'error' then begin
    return,1
  endif else begin
    return,0
  endelse
    
end

function is_syscall_type,token

  compile_opt idl2,hidden

  if token.type eq 'syscall' then begin
    return,1
  endif else begin
    return,0
  endelse
  
end

function is_whitespace_type,token

  compile_opt idl2,hidden

  if token.type eq 'whitespace' then begin
    return,1
  endif else begin
    return,0
  endelse
  
end

function is_comment_type,token

  compile_opt idl2,hidden

  if token.type eq 'comment' then begin
    return,1
  endif else begin
    return,0
  endelse 
   
end

function is_operator_type,token

  compile_opt idl2,hidden

  if token.type eq 'operator' then begin
    return,1
  endif else begin
    return,0
  endelse 
   
end

function is_assignment_type,token

  compile_opt idl2,hidden
  
  if token.type eq 'assignment' then begin
    return,1
  endif else begin
    return,0
  endelse
  
end

function is_punctuation_type,token

  compile_opt idl2,hidden

  if token.type eq 'punctuation' then begin
    return,1
  endif else begin
    return,0
  endelse 
   
end

function is_identifier_type,token

  compile_opt idl2,hidden

  if token.type eq 'identifier' then begin
    return,1
  endif else begin
    return,0
  endelse 
   
end

function is_function_type,token

  compile_opt idl2,hidden

  mini_routines
  
  if token.type eq 'function' then begin
    return,1
  endif else if is_identifier_type(token) then begin
  
    idx = where(token.name eq  (function_list()).name)
    
    if idx[0] ne -1L then begin
      return,1
    endif
  endif
  
  return,0
  
end 

function is_invalid_type,token

  compile_opt idl2,hidden

  if is_syscall_type(token) || $
     is_error_type(token) || $
     is_termination_type(token) || $
     is_continuation_type(token) $
  then begin
    return,1
  endif else begin
    return,0
  endelse

end 

function is_blank_type,token

  compile_opt idl2,hidden

  if is_whitespace_type(token) || is_comment_type(token) then begin
    return,1
  endif else begin
    return,0
  endelse
      
end

function is_unary_plus,current,previous

  compile_opt idl2,hidden
  
  if keyword_set(current) && $
     keyword_set(previous) && $
     is_operator_type(current) && $
     current.name eq '+' then begin
     
    if is_assignment_type(previous) then begin
      return,1
    endif
       
    if is_punctuation_type(previous) && $
       (previous.name eq '(' || $
        previous.name eq ',' || $
        previous.name eq '?' || $
        previous.name eq ':') then begin
      return,1
    endif
       
    if is_operator_type(previous) then begin
      return,1
    endif
  endif
   
  return,0
   
end

function is_unary_minus,current,previous

  compile_opt idl2,hidden
  
  if keyword_set(current) && $
     keyword_set(previous) && $
     is_operator_type(current) && $
     current.name eq '-' then begin
     
    if is_assignment_type(previous) then begin
      return,1
    endif
       
    if is_punctuation_type(previous) && $
       (previous.name eq '(' || $
        previous.name eq ',' || $
        previous.name eq '?' || $
        previous.name eq ':') then begin
      return,1
    endif
       
    if is_operator_type(previous) then begin
      return,1
    endif
  endif
   
  return,0
   
end

;keyword slash operates as a new unary operator
function is_keyword_slash,current,previous

  if keyword_set(current) && $
    keyword_set(previous) && $
    is_operator_type(current) && $
    current.name eq '/' then begin
    
    if is_punctuation_type(previous) && $
      (previous.name eq ',' || $
       previous.name eq '(')  then begin
      return,1
    endif
     
  endif
  
  return,0

end

;after evaluation, determine if keyword identifier is a keyword
function is_keyword_type,in

  if is_identifier_type(in) then begin
    if in.name eq 'keyword' then return,1
  endif
  
  return,0

end

function is_tvar_data,in

  compile_opt idl2,hidden
  
  if ~is_struct(in) then begin 
    return,0
  endif
  
  if in.type ne 'tvar_data' then begin
    return,0
  endif
  
  return,1

end

function is_var_data,in

  compile_opt idl2,hidden
  
  if ~is_struct(in) then begin 
    return,0
  endif
  
  if in.type ne 'var_data' then begin
    return,0
  endif
  
  return,1

end

function is_empty_type,in   ;should be careful about usage, as empty type is also configurable within the grammar


  if ~is_struct(in) then begin 
    return,0
  endif
  
  if in.type ne 'empty' then begin
    return,0
  endif
  
  return,1
  
end

function is_list_data,in

  compile_opt idl2,hidden
  
  if ~is_struct(in) then begin 
    return,0
  endif
  
  if in.type ne 'list_data' then begin
    return,0
  endif
  
  return,1

end

pro mini_predicates

 compile_opt idl2,hidden

 ;here thar be compiled predicates

end