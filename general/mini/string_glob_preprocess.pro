;+
; Procedure: string_glob_preprocess
;
; Purpose: Preprocesses tokenized input from the mini-language to add globbing support
; Each time there is a '?' or '*' character in a tplot variable, it creates another copy of 
; the token list with specific values filled in.  Because an output variable must be selected
; the output variable should contain globbing tokens to avoid errors.
; 
; Inputs: l : The token list after lexical analyzer.
; 
; Outputs: gl : The list of token lists after glob preprocessing.
; 
; Keywords: error: Returns an error struct if illegal globbing is used
;
; $LastChangedBy: pcruce $
; $LastChangedDate: 2015-09-12 11:37:42 -0700 (Sat, 12 Sep 2015) $
; $LastChangedRevision: 18779 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/mini/string_glob_preprocess.pro $
;-


function sgp_is_globbable,s

  compile_opt idl2
  
  return,is_string_type(s) and (strpos(s.value,'*') ne -1 or strpos(s.value,'?') ne -1 or strpos(s.value,'[') ne -1)

end

function sgp_match_vars,s
 
  compile_opt idl2
  
  tvar_list = tnames('*')
  
  s_len = strlen(s)
  
  delim_a = strmid(s,0,1)
  match_var = strmid(s,1,s_len-2)
  delim_b = strmid(s,s_len-1,1)
  
  match = where(strmatch(tvar_list,match_var),c)
  
  if c eq 0 then begin
    return,-1
  endif else begin
    return,delim_a+tvar_list[match]+delim_b
  endelse

end

;replaces globbing codes with regular expression capture codes
;this way we can find out which tplot variables get matched and create appropriate target variables
function sgp_regex_capture_replace,s

  compile_opt idl2
  
  ;will move characters from s_front to s_back as algorithm progresses.  Regex should search from back to front.  
  s_front = strmid(s,1,strlen(s)-2) ;removes the quotation marks from the comparison
  s_back = ''
  
  r = stregex(s_front,'.*(\*).*',/subexpr,length=l)  
 
  while r[0] ne -1 do begin 
    s_back = '(.*)' + strmid(s_front,r[1]+l[1],strlen(s_front)-(r[1]+l[1])) + s_back
    
    s_front = strmid(s_front,0,r[1])
    
    r = stregex(s_front,'.*(\*).*',/subexpr,length=l)
  endwhile
  
  s_front = s_front + s_back
  s_back = ''
  
  r = stregex(s_front,'.*(\?).*',/subexpr,length=l)  
  
  while r[0] ne -1 do begin 
    s_back = '(.)' + strmid(s_front,r[1]+l[1],strlen(s_front)-(r[1]+l[1])) + s_back
    
    s_front = strmid(s_front,0,r[1])
    
    r = stregex(s_front,'.*(\?).*',/subexpr,length=l)
  endwhile
  
  s_front = s_front + s_back
  s_back = ''
  
  r = stregex(s_front,'.*(\[.*\]).*',/subexpr,length=l)  
  
  while r[0] ne -1 do begin 
    s_back = '('+strmid(s_front,r[1],l[1])+')' + strmid(s_front,r[1]+l[1],strlen(s_front)-(r[1]+l[1])) + s_back
    
    s_front = strmid(s_front,0,r[1])
    
    r = stregex(s_front,'.*(\[.*\]).*',/subexpr,length=l)
  endwhile
  
  s_front = s_front + s_back
  s_back = ''
  
  return,'^'+s_front+'$'
end

function sgp_regex_match_replace,target_var,source_var,r,l

  compile_opt idl2
  
  out_var = target_var
  
  for i = 1,n_elements(r)-1 do begin
  
    ;The bracket regex is tricky.  regex matches greedily, which means that \[.*\] will find a single match for multiple bracket globs it a row.  We want it to match each separately. Thus we disallow left brackets inside our bracket match
    out_r = stregex(out_var,'\?|\[[^[]*\]|\*',length=out_l)
    
    if out_r[0] eq -1 then return,-1
  
    out_var = strmid(out_var,0,out_r) + strmid(source_var,r[i],l[i]) + strmid(out_var,out_r+out_l,strlen(out_var)-out_l)
  
  endfor

  return,out_var

end

function sgp_out_vars,target,source,verbose=verbose,error=error

  compile_opt idl2

  if ~sgp_is_globbable(source) then return,-1 

  reg_var = sgp_regex_capture_replace(source.value)

  tvar_list = tnames('*')
  
  r = stregex(tvar_list,reg_var,/subexpr,length=l)
  
  idx = where(r[0,*] ne -1,c)
  
  if c eq 0 then begin
    if keyword_set(verbose) then begin
      dprint,'ERROR Globbing operand has no matches'
    endif
    
    error = {type:'error',name:'Globbing operand with no match',value:source.value}
    return,-1
  endif

  out = strarr(c)
  
  for i = 0,c-1 do begin
  
    out_replace = sgp_regex_match_replace(target.value,tvar_list[idx[i]],r[*,idx[i]],l[*,idx[i]])
    
    if is_num(out_replace) then begin
    
      if keyword_set(verbose) then begin
        dprint,'Output variable globs do not match operand variable globs'
      endif
      
      error = {type:'error',name:'Output variable globs do not match operand variable globs',value:target.value}
      return,-1
    endif
  
    out[i] = out_replace
  
  endfor
  
  return,out
  
end

pro string_glob_preprocess,l,gl,error=error,verbose=verbose

  compile_opt idl2
   
  ;don't even bother preprocessing.  Can't work with fewer than 3 tokens
  if n_elements(l) lt 3 then return

  ;If they don't use globbing at the beginning then 
  ;they can't have multiple outputs, so we just need to
  ;resolve the variables and continue
  if ~sgp_is_globbable(l[0]) then begin
    tmp_list = l
    for i = 1l, n_elements(l)-1 do begin
      if sgp_is_globbable(l[i]) then begin       
          
          if keyword_set(verbose) then begin
            dprint,'Warning: globbing used in operand variable when output variable is not a globbable'
          endif
               
          matches = sgp_match_vars(l[i].value)     
                    
          if is_num(matches) then begin
            if keyword_set(verbose) then begin
              dprint,'Error: globbing variable has no match: ' + l[i].value
            endif
            error = {type:'error',name:'Globbing variable with no match',value:l[i].value}
            return
          endif
          
          tmp_list[i] = {type:'string',name:matches[0],value:matches[0],index:i}
          
        endif 
    endfor
    
    gl = reform(tmp_list,1,n_elements(tmp_list))
  endif else begin ;The tricky case. Uses the first variable as a guide for the rest
                   ;Globbing can be one to one, or one to many, but not many to many
  
    ;since output variables don't necessarily exist, we need to figure out what their names will be
    ;and create them.
    for i=1,n_elements(l)-1 do begin
    
       matches = sgp_out_vars(l[0],l[i],verbose=verbose,error=error)
    
       if is_struct(error) then return
    
       if ~is_num(matches) then break
    
    endfor

    
    if i eq n_elements(l) then begin
      if keyword_set(verbose) then begin
        dprint,'Error: output globbing variable has no match: ' + l[0].value
      endif
      error = {type:'error',name:'Output globbing variable with no match',value:l[0].value}
      return
    endif
    
    n_matches = n_elements(matches)
    
    temp_struct = l[0]
    gl = replicate(temp_struct,n_elements(matches),n_elements(l))
    
    gl[*,0].name = matches
    gl[*,0].value = matches
    
    
    
    for i = 1,n_elements(l)-1 do begin
      if sgp_is_globbable(l[i]) then begin
      
        matches = sgp_match_vars(l[i].value)
        
        if n_elements(matches) ne n_matches then begin
          if keyword_set(verbose) then begin
            dprint,'Error: number of globbing matches for operand does not match number of matches for other operands ' + l[i].value
          endif
          error = {type:'error',name:'Globbing variable with wrong number of matches',value:l[i].value}
          return
        endif
        
        gl[*,i].name = matches
        gl[*,i].value = matches
              
      endif else begin
        gl[*,i] = l[i]
      endelse
    endfor
  
  endelse

end