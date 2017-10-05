;+
;Procedure: slr
;
;Purpose: This routine will generate SLR(1) parse tables for a bottom-up shift/
;         reduce parcer.  The entire algorithm is described in "Compilers:
;         Principles, Tools, and Techniques" by Aho, Sethi, & Ullman 1986 Section 
;         4.7
;         
;         Helper functions in this file are specific to the SLR technique
;         and uses a similar naming schema to that used in Aho,Sethi & Ullman.
;         Different versions of closure, goto, & items are needed for LARL or LRK parse table generation methods.
;         These have not been implemented
;         
; Inputs: grammar:  A grammar description structure from which the parse_tables are generated 
;                   (see productions.pro)
;                   
; Keywords: parse_tables:  A structure storing the parse tables for the grammar are returned through this named variable
; 
;  
; $LastChangedBy: pcruce $
; $LastChangedDate: 2013-05-10 17:04:22 -0700 (Fri, 10 May 2013) $
; $LastChangedRevision: 12331 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/mini/slr.pro $
;-


;closure is a helper routine that is important for the generation
;of SLR tables, it is a standard routine that you should find
;described in texts that describe top-down and bottom up parsers
;uses a recursive call to generate set, the first call will
;not have added set.  Added will be set automatically in recursive
;calls
function closure_slr,items,grammar,added

  compile_opt idl2,hidden
 
  ;initialize added
  if ~keyword_set(added) then begin
     added = intarr(n_elements(grammar.production_list))
  end

  ;NOTE:consider using vector, this is messy
  out = '' ; empty string is the fail case

  ;loop over items
  for i = 0,n_elements(items)-1 do begin

    item = items[i]
   
    ;if the item has not already been added
    if added[item.index] eq 0 then begin
       
       ;add it
      out = concat(item,out)

      ;set it to added
      if item.pos eq 0 then begin
        added[item.index] = 1
     endif

      ;if there is any item to the right of the item
      if item.pos lt item.length then begin
         ;get the element
        ele = item.right[item.pos]

        ;find all productions that begin with the element
        idx = where(grammar.production_list.left eq ele and not added)

        if idx[0] ne -1L then begin

           ;calculate the closure of these as prods as items with 
           ;placeholder on left
          result = closure_slr(make_item(grammar.production_list[idx],0),grammar,added)

          ;if we get any results, add them to the output
          if is_struct(result) then begin
            out = [out,result]
          endif
        endif
      endif
    endif

  endfor

  return, out
end

;empty is fail(although not necessarily serious)
;the function goto is a standard function used in
;LL, top-down parsers, SLR, LR(k) & bottom-up parsers
;you will find this routine described in
;references listed in calc.pro header
function goto_slr,items,ele,grammar

  compile_opt idl2,hidden

  pos = items[*].pos

  length = items[*].length

  idx = where(pos lt length)

  if idx[0] ne -1 then begin
    
     items_tmp = items[idx]
     eles_arr = items_tmp.right

     eles = eles_arr[items_tmp.pos + lindgen(n_elements(items))*6]

     items_tmp.pos += 1
     
     if in_set(ele,eles) then begin

        idx = where(eles eq ele)

        return,closure_slr(items_tmp[idx],grammar)

     endif

  endif

  return,''
  
end

;constructs the set of sets that are needed for an slr parser 
function items_slr,grammar

  compile_opt idl2,hidden

  idx = where(grammar.augment eq grammar.production_list.left)
  
  if idx[0] eq -1L then begin
  
    return,{type:'error',name:'grammar error',value:'grammar has no augment production'}
    
  endif

  set = closure_slr(make_item(grammar.production_list[idx],0),grammar)

  out_sets = csvector(set)

  symbols = ssl_set_union(grammar.terminals,grammar.nonterminals)

  num_sets = 1

  i = 0

  while(1) do begin
    
    if i ge num_sets then begin
      return,{type:'set',vector:out_sets}
    endif

    set = csvector(i,out_sets,/read)
    
    for j = 0,n_elements(symbols) -1 do begin

       out = goto_slr(set,symbols[j],grammar)

       if is_struct(out) && ~in_vector(out,out_sets) then begin
          out_sets = csvector(out,out_sets)
          num_sets++
       endif
    endfor

    i++

 endwhile

end

;constructs an slr parsing table from a grammar
function make_table_slr,grammar

  compile_opt hidden,idl2

  parse_table_routines
  
  set_of_items = items_slr(grammar)
  
  if set_of_items[0].type eq 'error' then begin
    return,set_of_items
  endif

  set_num = csvector(set_of_items.vector,/length)
  
  terminal_num = n_elements(grammar.terminals)
  nonterminal_num = n_elements(grammar.nonterminals)

  action_table = strarr(set_num,terminal_num)
  goto_table = strarr(set_num,nonterminal_num)
  
  state_symbols = strarr(set_num)

  for i = 0,set_num-1 do begin

    items = csvector(i,set_of_items.vector,/read)

    item_num = n_elements(items)

    ;construct actions
    for j = 0,item_num-1 do begin
    
      item = items[j]
      
      if item.left eq grammar.augment && item.pos eq 0 then begin
        
        initial = i
        
      endif
      
      ;action = shift
      if item.pos lt item.length then begin
      
        element = item.right[item.pos]
        
        element_index = where(element eq grammar.terminals)

        if element_index[0] ne -1 then begin 
        
          goto_out = goto_slr(items,element,grammar)
          
          if is_equal(goto_out[0],'') then begin
             return,{type:'error',name:'unexpected output',value:'unexpected goto output while processing: ' + strtrim(long(i),2) + ' ele: ' + element}
          endif
          
          goto_index = vec_index(goto_out,set_of_items.vector)

          if goto_index[0] ne -1 then begin
          
            ;conflict
            if action_table[i,element_index] ne '' && action_table[i,element_index] ne 's' + strtrim(string(goto_index),2) then begin
            
              ;not sure how to handle shift/shift conflict
              if strmid(action_table[i,element_index],0,1) eq 's' then begin
                return,{type:'error',name:'action shift conflict',value:'shift/shift state conflict',state_num:i,state_symbols:state_symbols,goto_index:goto_index,element:element,element_index:element_index[0],action_table:action_table,set_of_items:set_of_items}
              endif
            
              op1_index = where(element eq grammar.operators)
              
              ;cant resolve non-operator precedence conflicts
              if op1_index eq -1 then begin
                return,{type:'error',name:'action shift conflict',value:'precendence state conflict',state_num:i,state_symbols:state_symbols,goto_index:goto_index,element:element,element_index:element_index[0],action_table:action_table,set_of_items:set_of_items}
              endif
              
              production_index = long(strmid(action_table[i,element_index],1))
              
              op2_index = where(grammar.production_list[production_index].op eq grammar.operators)
              
              ;I *think* this will only occur from malformed grammar.
              if op2_index eq -1 then begin
                return,{type:'error',name:'action shift conflict',value:'invalid grammar state conflict',state_num:i,state_symbols:state_symbols,goto_index:goto_index,element:element,element_index:element_index[0],action_table:action_table,set_of_items:set_of_items}
              endif
              
              ;shift beats reduce?
              ;This section resolves operator precedences.  All operators are left-associative if they're at same precedence. (ie same-precedence -> reduce beats shift)
              ;if op1_index gt op2_index then begin
              
              if grammar.precedences[op1_index] gt grammar.precedences[op2_index] then begin
                state_symbols[goto_index] = element
          
                action_table[i,element_index] = 's' + strtrim(string(goto_index),2)
                
               ; dprint,'Shift :' + element + ' Beats Reduce: ' + grammar.production_list[production_index].op
             
              endif else begin
              
                ;dprint,'Shift :' + element + ' Loses to Reduce: ' + grammar.production_list[production_index].op
              
              endelse
              
            endif else begin
            
               state_symbols[goto_index] = element
          
               action_table[i,element_index] = 's' + strtrim(string(goto_index),2)
            
            endelse
                 
          endif else begin
            return,{type:'error',name:'index error',value:'unexpected invalid index while processing: ' + strtrim(long(i),2) + ' ele: ' + element} ;all goto outputs should be set
          endelse
        endif
      endif  
      
      ;action reduce
      if item.pos eq item.length && item.left ne grammar.augment then begin
        
        follow_out = parse_follow(item.left,grammar)
        
        if is_equal(follow_out[0],'') then begin
          return,{type:'error',name:'unexpected output',value:'unexpected follow output while processing: ' + strtrim(long(i),2) + ' ele:' + item.left}
        endif  
        
        for k = 0,n_elements(follow_out)-1 do begin
        
          ind = where(follow_out[k] eq grammar.terminals)
          
          if ind[0] ne -1 then begin
            
            if action_table[i,ind] ne '' then begin
              return,{type:'error',name:'action reduce conflict',value:'conflict with state: ' + strtrim(long(i),2) + ' ele: ' + item.left + ' entry = ' + action_table[i,ind]}
            endif 
              
            action_table[i,ind] = 'r'+strtrim(string(item.index),2)
              
          endif else begin            
            return,{type:'error',name:'index error',value:'unexpected invalid index while processing: ' + strtrim(long(i),2) + ' ele: ' + item.left} ;all goto outputs should be set
          endelse
;            
;          endfor
        
        endfor
      endif
          
      ;action accept
      
      if item.left eq grammar.augment && item.pos eq 1 then begin
      
        ind = where(grammar.endline eq grammar.terminals)
        
        if ind[0] ne -1 then begin
        
          if action_table[i,ind] ne '' then begin
              return,{type:'error',name:'action accept conflict',value:'conflict with state: ' + strtrim(long(i),2) + ' ele: ' + item.left + ' entry = ' + action_table[i,ind]}
          endif 
        
          action_table[i,ind] = 'acc'
          
        endif else begin
          return,{type:'error',name:'index error',value:'unexpected invalid index while processing: ' + strtrim(long(i),2) + ' ele: ' + item.left} ;all goto outputs should be set
        endelse
      endif
    endfor
    
    ;construct gotos
    
    for j = 0,nonterminal_num -1 do begin
    
      nt = grammar.nonterminals[j]
      
      goto_out = goto_slr(items,nt,grammar)     
           
       if is_equal(goto_out,'') then begin
          continue
       endif
          
       goto_index = vec_index(goto_out,set_of_items.vector)

       if goto_index[0] ne -1 then begin 
       
        goto_table[i,j] = goto_index

       endif else begin
         return,{type:'error',name:'index error',value:'unexpected invalid index while processing: ' + strtrim(long(i),2) + ' nt: ' + nt} ;all goto outputs should be set
       endelse

    endfor
    
  endfor
  
  idx = where(action_table eq '')
  
  if idx[0] ne -1 then begin
    action_table[idx] = 'err'
  endif
  
  idx = where(goto_table eq '')
  
  if idx[0] ne -1 then begin
    goto_table[idx] = 'err'
  endif
  
  return,{type:'parse_table',action_table:action_table,goto_table:goto_table,initial_state:initial}

end

pro slr,grammar,parse_tables=parse_tables
  
  parse_tables = make_table_slr(grammar) 

end
