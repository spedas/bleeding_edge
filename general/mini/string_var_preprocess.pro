;+
; Procedure: string_var_preprocess
;
; Purpose: Preprocesses tokenized input from the mini-language to implement string concatenation operator through a preprocessor stage
;   
; Inputs: l : The token list after lexical analyzer.
;
; Outputs: sl : The list of token lists after string var preprocessing.
;
; Keywords: error: Returns an error struct if problem occurred.
; 
; Verbose: Set to get more detailed output
;
; $LastChangedBy: pcruce $
; $LastChangedDate: 2015-09-18 11:13:49 -0700 (Fri, 18 Sep 2015) $
; $LastChangedRevision: 18839 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/mini/string_var_preprocess.pro $
;-

;returns a string token type from a string and index
function sv_make_string_token,s

  compile_opt hidden

  if is_struct(s) then return,s

  out = replicate({type:'string',name:'',value:'',index:0l},n_elements(s))
  
  out.name = '"'+s+'"'
  out.value = out.name

  return,out

end

;Syntactic sugar for error handling
function sv_error,msg,val,verbose=verbose
  error = {type:'error',name:msg,value:val}
  if keyword_set(verbose) then begin
    dprint,'Error: ' + msg + ': '  + val.val
  endif
  return,0
end

;make sure it is a variable not a function
function sv_is_variable,l,i

  compile_opt hidden
  
  if ~is_identifier_type(l[i]) then return,0
  
  if i lt n_elements(l)-1 && l[i+1].value eq '(' then return,0
  
  return,1

end

;Predicate for the concatenation operator
function sv_is_concat,t

  compile_opt hidden
  
  return,is_operator_type(t) && t.value eq '$+'
 
end

;Looks up a normal(non-tplot variable)
function sv_varfetch,input,error=error,verbose=verbose

  compile_opt hidden
  
  error = 0
  
  if is_struct(input) then begin
    output = scope_varfetch(input.value,level=!mini_globals.scope_level)
    if ~is_string(output) then begin
      error = sv_error('String concat operator on variable containing non-string',output.value,verbose=verbose)
      return,0
    endif
    return,output
  endif
  
  return,input
end

;Handles the many different cases for adding a token to SL
; (SL may be 1 or 2d, T may be 0 or 1d)
pro sv_push_token,sl,t,error=error,verbose=verbose

  compile_opt hidden

  error = 0

  if ~is_struct(sl) then begin
    if n_elements(t) eq 1 then begin
      sl = t
    endif else begin
      sl = reform(t,n_elements(t),1)
    endelse
  endif else if ndimen(sl) le 1 then begin
    if n_elements(t) eq 1 then begin
      sl = [sl,t]
    endif else begin
      temp = replicate(sl[0],n_elements(t),n_elements(sl)+1)
      for i = 0,n_elements(t)-1 do begin
        temp[i,0:n_elements(sl)]=[sl,t[i]]
      endfor
      sl = temp
    endelse
  endif else if n_elements(t) eq 1 then begin
    dim = dimen(sl)
    new = replicate(sl[0],dim[0],dim[1]+1)
    for i = 0,dim[1]-1 do begin
      new[*,i] = sl[*,i]
    endfor
    
    new[*,i]=t
    sl = new
  endif else begin
    dim = dimen(sl)
    
    if dim[0] ne n_elements(t) then begin
      error = sv_error('Mismatched string array sizes',t[0].value,verbose=verbose)
      return
    endif
    
    new = replicate(sl[0],dim[0],dim[1]+1)
    for i = 0,dim[1]-1 do begin
      new[*,i] = sl[*,i]
    endfor
    
    new[*,i]=t
    sl = new
     
  endelse


end

;Uses a state machine parser to convert $+ operations into a sequence of normal calc calls
;State machine definition follows:
;STATE:   TOKEN:    NEXTSTATE:    PUSH?:
;START    TVAR      TVAR          N(store prev)
;         VAR       VAR           N(store prev)
;         $+        UNARY         N
;         ELSE      START         Y
;TVAR     $+        BINARY        N
;         ELSE      START         Y
;VAR      $+        BINARY        N
;         ELSE      START         Y
;UNARY    VAR       VAR           N(store prev)
;         ELSE      ERROR         N
;BINARY   VAR       VAR           N(concatenate)
;         TVAR      TVAR          N(concatenate)
;         ELSE      ERROR         N        
;
;Input L will be an array of N token structures
;Output SL will be an array of JxK token structures with K<=N
pro string_var_preprocess,l,sl,error=error,verbose=verbose

  compile_opt idl2,hidden
  
  mini_predicates
  
  STATE_START = 0
  STATE_TVAR = 1
  STATE_VAR = 2
  STATE_UNARY = 3
  STATE_BINARY = 4
  
  st = STATE_START
  sl = 0
  prev = 0
  for i = 0,n_elements(l)-1 do begin
    
    if st eq STATE_START then begin
      if sv_is_variable(l,i) then begin
        st = STATE_VAR
        prev = l[i]
;        sv_push_token,sl,l[i],error=error,verbose=verbose
;        if keyword_set(error) then return
      endif else if is_string_type(l[i]) then begin
        st = STATE_TVAR
        prev = l[i]
;        sv_push_token,sl,l[i],error=error,verbose=verbose
;        if keyword_set(error) then return
      endif else if sv_is_concat(l[i]) then begin
        st = STATE_UNARY
      endif else begin
        sv_push_token,sl,l[i],error=error,verbose=verbose
        if keyword_set(error) then return
      endelse
    endif else if st eq STATE_TVAR then begin
      if sv_is_concat(l[i]) then begin
        st = STATE_BINARY
        if is_struct(prev) then begin
          prev=strmid(prev.value,1,strlen(prev.value)-2)
        endif
      endif else begin
        st = STATE_START
        sv_push_token,sl,sv_make_string_token(prev),error=error,verbose=verbose
        if keyword_set(error) then return
        sv_push_token,sl,l[i],error=error,verbose=verbose
        if keyword_set(error) then return
      endelse
    endif else if st eq STATE_VAR then begin
      if sv_is_concat(l[i]) then begin
        st = STATE_BINARY
        prev = sv_varfetch(prev,error=error,verbose=verbose)
        if keyword_set(error) then return
      endif else begin
        st = STATE_START
        sv_push_token,sl,sv_make_string_token(prev),error=error,verbose=verbose
        if keyword_set(error) then return
        sv_push_token,sl,l[i],error=error,verbose=verbose
        if keyword_set(error) then return
      endelse
    endif else if st eq STATE_UNARY then begin
      if sv_is_variable(l,i) then begin
        st = STATE_VAR
        prev = sv_varfetch(l[i],error=error,verbose=verbose)
        if keyword_set(error) then return
      endif else begin
        error = sv_error("Non-variable token following unary concat",l[i].value)
        return
      endelse
    endif else if st eq STATE_BINARY then begin
      if sv_is_variable(l,i) then begin
        st = STATE_VAR
        prev += sv_varfetch(l[i],error=error,verbose=verbose)
        if keyword_set(error) then return
      endif else if is_string_type(l[i]) then begin
        st = STATE_TVAR
        prev += strmid(l[i].value,1,strlen(l[i].value)-2)
      endif else begin
        error = sv_error("Non-variable or T-variable following unary concat",l[i].value)
        return
      endelse
    endif else begin
      error = sv_error("Unexpected state",st)
      return
    endelse
    
  endfor
  
  if ndimen(sl) eq 1 then begin
    sl = reform(sl,1,n_elements(sl))
  endif
  
  
end