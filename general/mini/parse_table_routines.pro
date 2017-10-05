;+
;Procedure: parse_table_routines
;
;Purpose: Compiles a library of helper routines for the parse_table generator
;          It contains general purpose routing routines
;          anything table specific will be stored in slr.pro,
;          lk1.pro & lalr.pro (right now there is only support for slr parse tables)
;
; $LastChangedBy: pcruce $
; $LastChangedDate: 2012-07-12 15:50:21 -0700 (Thu, 12 Jul 2012) $
; $LastChangedRevision: 10702 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/mini/parse_table_routines.pro $
;-




;constructs an item or a set of items from a production
;an item is just like a product with the exception that
;it has a placeholder that can be placed before the right side
;of the production,after it, or between any element on the right side.
;This is specified with pos. Pos is a number from 0 to length
;which specifies up to length + 1 different positions.
function make_item,prod,pos

  compile_opt idl2,hidden

  item = {type:'item',left:prod[0].left,right:prod[0].right,op:prod[0].op,index:prod[0].index,length:prod[0].length,pos:long(pos[0])}

  items = replicate(item,n_elements(prod))

  items[*].left = prod[*].left
  items[*].right = prod[*].right
  items[*].op = prod[*].op
  items[*].index = prod[*].index
  items[*].length = prod[*].length
  items[*].pos = long(pos)

  return,items

end

;helper function checks if an element is in a vector of elements
function in_vector,ele,vec

  compile_opt idl2,hidden

  len = csvector(vec,/length)

  for i = 0,len-1 do begin

     out = csvector(i,vec,/read)

     if is_equal(ele,out) then begin
        return,1
     endif

  end

  return,0

end

;find the index of an item
function vec_index,ele,vec

  compile_opt idl2,hidden

  len = csvector(vec,/length)

  for i = 0,len-1 do begin

     out = csvector(i,vec,/read)

     if is_equal(ele,out) then begin
        return,i
     endif

  end

  return,-1

end

;syntactic sugar to concatenate arrays in a way that is a little more
;useful that the standard idl syntax
function concat,val,arr

  compile_opt idl2,hidden

  if ~keyword_set(arr) || (is_string(arr) && arr[0] eq '') then begin
    return,[val]
  endif else begin
    return,[arr,val]
  endelse

end


;empty is fail(although not necessarily serious)
;the function first is a standard function used in
;LL, top-down parsers, SLR, LR(k) & bottom-up parsers
;you will found this routine described in those texts
function parse_first,ele,grammar,added

  compile_opt hidden,idl2
  
  out = ''
  
  for i = 0, n_elements(ele) - 1 do begin
  
    if in_set(ele[i],grammar.terminals) then begin
      return,concat(ele[i],out)
    endif else if ele[i] eq grammar.empty then begin
      return,concat(ele[i],out)
    endif else begin
     
      idx = where(ele[i] eq grammar.production_list.left)
      
      ;consider adding error checking on this har index
      
      ;prevent infinite loop
    
      if ~keyword_set(added) then begin
        added = intarr(n_elements(grammar.production_list))
      endif
      
      prods = grammar.production_list[idx]
      
      first_list = ''
  
      for j = 0,n_elements(prods)-1 do begin
      
        if added[idx[j]] eq 0 then begin 
      
          added[idx[j]] = 1
      
          first = parse_first(prods[j].right,grammar,added)
      
          if first[0] ne '' then begin
            first_list = concat(first,first_list)
          endif
        endif
    
      endfor
      
      first_list = first_list[uniq(first_list,sort(first_list))]
      
      out = concat(first_list,out)
      
      out = out[uniq(out,sort(out))]
      
      if ~in_set(grammar.empty,first_list) then begin
        return,out
      endif
    endelse 
     
  endfor
  
  out = concat(grammar.empty,out)
  
  out = out[uniq(out,sort(out))]
  
  return,out
  
end

;empty is fail(although not necessarily serious)
;the function follow is a standard function used in
;LL, top-down parsers, SLR, LR(k) & bottom-up parsers
;you will find this routine described in texts referenced in calc.pro
function parse_follow,nonterminal,grammar,added

  compile_opt hidden,idl2

  ;only nonterminal are acceptable inputs
  if in_set(nonterminal,grammar.terminals) then begin
    ;error
    return,''
  endif
  
  ;if the input is the start symbol add a newline to follow
  if is_equal(nonterminal[0],grammar.start) then begin
    follow =[grammar.endline] 
  endif else begin 
    follow = ''  ;otherwise initialize as blank
  endelse
  
  ;initialize added if it was not passed in
  ;this argument should only be initialized if this is
  ;a non-user recursive call.  added exists to prevent
  ;an infinite loop
  if ~keyword_set(added) then begin
    added = intarr(n_elements(grammar.nonterminals))
  endif
  
  ;get the numerical index of the input nonterminal
  idx = where(nonterminal eq grammar.nonterminals)
  
  ;so added will be correctly marked
  if added[idx] eq 1 then begin
    return,''
  endif else begin
    added[idx] = 1
  endelse
  
  ;now loop over all the productions
  for i = 0,n_elements(grammar.production_list)-1 do begin
    
    ;local variable for this iteration, just for ease of typing
    prod = grammar.production_list[i]
    
    ;if the requested nonterminal exists in the right side of the production
    if in_set(nonterminal,prod.right) then begin
      
      idx = where(prod.right eq nonterminal)
      
      for j = 0,n_elements(idx) - 1 do begin

      ;if the nonterminal is at the rightmost on the right side of production
        if idx[j] eq prod.length-1 then begin
          follow_tmp = parse_follow(prod.left,grammar,added) ;make a recursive call
        
          if ~is_equal(follow_tmp[0],'') then begin
            follow = concat(follow_tmp,follow) ;if there is a valid result add it to the outpu
          endif
        
        endif else begin

          first = parse_first(prod.right[idx+1],grammar) ;generate first for the symbol next to the right
        
          if in_set(grammar.empty,first) then begin ;if empty symbol is in first
        
            follow_tmp = parse_follow(prod.left,grammar,added) ;make a recursive call to follow
        
            if ~is_equal(follow_tmp[0],'') then begin ;and add valid outputs to overall output
              follow = concat(follow_tmp,follow)
            endif
          
            idx = where(first ne grammar.empty) ;also add all non-empty symbols in first to output
          
            follow = concat(first[idx],follow)
          
          endif else begin
        
            follow = concat(first,follow) ;add the symbols in first to the output
          
          endelse
        endelse
      endfor
    endif
  endfor
  
  return,follow[uniq(follow,sort(follow))] ;the recursive method may duplicate some results, eliminate dups
end  

pro parse_table_routines

;just compiles the appropriate routines

end
