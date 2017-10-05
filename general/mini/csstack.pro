;+
; Function: csstack
;
; Purpose:  This procedure implements the push,pop,& peek
;           methods for a traditional computer science 
;           data structure: the stack.  It is a basic
;           LIFO data structure.
;           
;           Advantages over array:
;           1. store heterogenous elements of any type in a stack.
;           2. stack can grow as large as memory and you don't
;           need to know how big it will be in advance
;           3. You don't need to worry about how the data is stored
;           
;           Disadvantages over array:
;           1. You can't directly apply operations to the data
;           structure
;           2. You are forced to use abstraction
;
;
;           Inputs: arg1:the meaning of the argument varies with syntax
;                   arg2:the meaning of the argument varies with syntax
;
;           Keywords: push(optional) : set this to add an item to the stack and return the modified stack
;                     pop(optional) : set this to remove an item from the stack and return the modified stack
;                     peek(optional) : set this to return the top element on the stack
;                     length(optional): set this if you want
;                                       to return the length          
;                     free(optional): set this if you want to free the
;                                     vector's memory without
;                                     creating a leak, it will return
;                                     the number of elements free'd
;                                    
;                    If no keywords are set, default behavior is push
;                    
;      
;           Outputs: If push or pop are set it returns the modified stack
;                    If peek is set it returns the top element on the stack
;                    If length or free are set it returns a number of items
;
;           Syntax(each method is followed by examples): 
;
;                   push
;                    stk = csstack(item)
;                    stk = csstack(item,stk)  ;stk can be defined or not
;                    stk = csstack(item,stk,/push)
;                   pop:
;                    stk = csstack(stk,/pop) ;must have at least one element 
;                   peek:
;                    item = csstack(stk,/peek) ;must have at least one element
;                   length: 
;                     length = csvector(stk,/length)
;                   free:
;                     num = csvector(stk,/free)
;                     
;       NOTES: in the event of overflow during add the vector.a
;       component will double in size
;
;       Push stores a copy of the element not the element itself
; 
;       If you want to do manual lengths and reads you can look
;       at the code, but I would recommend against cause you are
;       violating abstraction which means the internal representation
;       could change and invalidate your code.
;
;       This might be worth writing in O.O. idl as well
;
;       To get type flexibility it uses a pointer for every object
;       Thus if you aren't careful this function will eat your
;       system memory for breakfast.  Use heap_gc to clean up if you 
;       are running out of memory.
;
; 
; $LastChangedBy: pcruce $
; $LastChangedDate: 2008-09-12 16:21:16 -0700 (Fri, 12 Sep 2008) $
; $LastChangedRevision: 3487 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/mini/csstack.pro $
;-
;
;-


function csstack,arg1,arg2,push=push,pop=pop,peek=peek,length=length,free=free

if keyword_set(length) then begin ;length

   if ~keyword_set(arg1) then begin
      message,'Illegal syntax(arg1 must be set)'
   endif

   if keyword_set(arg2) then begin
      message,'Illegal syntax(arg2 and length are set)'
   endif

   if keyword_set(push) then begin
      message,'Illegal syntax(length and push are set)'
   endif
   
   if keyword_set(pop) then begin
      message,'Illegal syntax(length and pop are set)'
   endif
   
   if keyword_set(peek) then begin
      message,'Illegal syntax(length and peek are set)'
   endif

   if keyword_set(free) then begin
      message,'Illegal syntax(length and free are set)'
   endif

   return, arg1.l

endif else if keyword_set(free) then begin ;free

   if ~keyword_set(arg1) then begin
      message,'Illegal syntax(arg1 must be set)'
   endif

   if keyword_set(arg2) then begin
      message,'Illegal syntax(arg2 and free are set)'
   endif

   if keyword_set(push) then begin
      message,'Illegal syntax(free and push are set)'
   endif
   
   if keyword_set(pop) then begin
      message,'Illegal syntax(free and pop are set)'
   endif
   
   if keyword_set(peek) then begin
      message,'Illegal syntax(free and peek are set)'
   endif

   ptr_free,arg1.d

   return,arg1.l

endif else if keyword_set(peek) then begin

   if ~keyword_set(arg1) then begin
      message,'Illegal syntax(arg1 must be set)'
   endif
   
   if keyword_set(arg2) then begin
      message,'Illegal syntax(arg2 and peek are set)'
   endif
     
   if keyword_set(push) then begin
      message,'Illegal syntax(peek and push are set)'
   endif
   
   if keyword_set(pop) then begin
      message,'Illegal syntax(peek and pop are set)'
   endif
   
   if arg1.l le 0 then begin
      message,'Cannot peek empty stack'
   endif
   
   return,*(arg1.d[arg1.l-1L])
   
endif else if keyword_set(pop) then begin

   if ~keyword_set(arg1) then begin
      message,'Illegal syntax(arg1 must be set)'
   endif
   
   if keyword_set(arg2) then begin
      message,'Illegal syntax(arg2 and pop are set)'
   endif
   
   if keyword_set(push) then begin
      message,'Illegal syntax(pop and push are set)'
   endif
   
   if arg1.l le 0 then begin
      message,'Cannot pop empty stack'
   endif
   
   arg1.l--
   
   ptr_free,arg1.d[arg1.l]
   
   return,arg1
   
endif else begin ;push

  if size(arg1,/type) eq 0 then begin
    message,'Illegal syntax(arg1 must be set)'
  endif
   
  data = ptr_new(arg1)

  if ~keyword_set(arg2) then begin ;new stack

    return, {d:[data],l:1L}
    
  endif else begin
  
    if arg2.l eq n_elements(arg2.d) then begin

      out = {d:replicate(data,arg2.l*2L),l:arg2.l}

      out.d[0:arg2.l-1L] = arg2.d[0L:arg2.l-1L]

    endif else begin

      out = arg2

    endelse

    out.d[arg2.l] = data

    out.l++

    return,out
    
  endelse

endelse

end
