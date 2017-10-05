
;+
; Procedure: evaluate
;
; Purpose:  This routine performs the actual evaluation of an expression in the mini_language
;           It basically combines an slr shift/reduce parser with an evaluator
;           
; Description(of how it works, super-concise version):
;   This routine is essentially a table-driven stack machine.  
;   It uses two tables action & goto.(both are 2-d arrays) to determine how to behave at any given step.  Prior states are pushed onto the stack.
;   At each step, an action is performed, determined by the action table, and a new state is pushed onto the stack, determined by the goto table.
;   Some actions may also pop a certain number of states off of the stack.
;    
;   Actions can be either shift actions or reduce actions(using reduction N). 
;     A shift action, means that it doesn't have enough tokens yet to determine the next operation, so it should process an additional token.
;     A reduce action, means that it should perform some operation.  Replacing a complex expression with a simplified expression by using one of the production rules.
;      
;   One more note, the stack has flexible type.  Each push or pop operation generally pushes or pops two items.  One will be a numerical state(long int), another will be a data item.
;     The data items are often implemented as structs but can represent various types of items. (tokens, intermediate processing results, outputs, operators, variable identifiers)
;     Generally the data items on the stack are anything that might be required as an input to perform a reduction.
;           
; Inputs:
;    tk_list:  a list of token structures from the lex routine
;    grammar:  a grammar description structure
;    parse_tables: a parse table structure
;    
; Keywords: error: On error this routine returns a structure that describes the error that occurred
;
; $LastChangedBy: pcruce $
; $LastChangedDate: 2013-05-10 17:04:22 -0700 (Fri, 10 May 2013) $
; $LastChangedRevision: 12331 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/mini/evaluate.pro $
;-

pro evaluate,tk_list,grammar,parse_tables,error=error

  compile_opt idl2
  
  evaluator_routines
  
  stk = csstack(parse_tables.initial_state)
  
  i = 0
  
  while 1 do begin
  
    s = csstack(stk,/peek)
    
    if i ge n_elements(tk_list) then begin
      message,'parse error'
    endif
    
    if i eq 0 then begin
      previous = 0
    endif else begin
      previous = tk_list[i-1]
    endelse  
    
    tk = eval_token(tk_list[i],previous,grammar)

    if is_shift_code(parse_tables.action_table[s,tk.index]) then begin
    
      s = get_shift_num(parse_tables.action_table[s,tk.index])
    
      if s eq -1 then begin
        message,'shift code error'
      endif
    
      stk = csstack(tk,stk,/push)
      
      stk = csstack(s,stk,/push)
      
      i++
          
    endif else if is_reduce_code(parse_tables.action_table[s,tk.index]) then begin
    
      red = get_reduce_num(parse_tables.action_table[s,tk.index])
      
      if red[0] eq -1 then begin
        message,'reduce code error'
      endif
    
      reduction = grammar.production_list[red]
      
      ;do reduction here
      
      for j = reduction.length,1,-1 do begin
        stk = csstack(stk,/pop)
        (scope_varfetch('input'+strtrim(string(j),2),level=0)) = csstack(stk,/peek)
        stk = csstack(stk,/pop)
      endfor
        
      catch,err
        
      if err eq 0 then begin
        
      ;  dprint,reduction.fun,reduction.length
        
        if reduction.length eq 1 then begin
          output = call_function(reduction.fun,input1)
         ; dprint,input1
        endif else if reduction.length eq 2 then begin
          output = call_function(reduction.fun,input1,input2)
         ; dprint,input1,input2
        endif else if reduction.length eq 3 then begin
          output = call_function(reduction.fun,input1,input2,input3)
         ; dprint,input1,input2,input3
        endif else if reduction.length eq 4 then begin
          output = call_function(reduction.fun,input1,input2,input3,input4)
          ;dprint,input1,input2,input3,input4
        endif else begin
          message,'unhandled reduction length'
        endelse
        
      endif else begin
        
        help, /Last_Message, Output=theErrorMessage
        catch,/cancel
        error = {type:'error',name:'reduction error',value:theErrorMessage,reduction:red}
        return
        
      endelse
     
      catch,/cancel
     
      s = csstack(stk,/peek)
      stk = csstack(output,stk,/push)
      idx = where(reduction.left eq grammar.nonterminals)
      s2 = long(parse_tables.goto_table[s,idx])
      stk = csstack(s2,stk,/push)
      
    endif else if parse_tables.action_table[s,tk.index] eq 'acc' then begin
    
      ;parsing completed! we're done
      return
      
    endif else if parse_tables.action_table[s,tk.index] eq 'err' then begin
    
      ;unspecified error
      error = {type:'error',name:'User statement syntax error',state:s,token:tk}
      return
      
    endif else begin
      message,'Unhandled parse table entry'
    endelse
  
  endwhile
  
end