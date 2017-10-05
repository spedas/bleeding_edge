;+
; Function: csvector
;
;
; Purpose:  This procedure implements the create,add, and read
;           methods for a traditional computer science 
;           data structure: the vector.The vector
;           list of elements of any type and of any length.
;            
;           Advantages over array:
;           1. store heterogenous elements of any type in a list.
;           2. Lists can grow as large as memory and you don't
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
;           Keywords: read(optional): set this if you want 
;                                     to read an element
;                     length(optional): set this if you want
;                                       to read the length          
;                     free(optional): set this if you want to free the
;                                     vector's memory without
;                                     creating a leak, it will return
;                                     the number of elements free'd
;         
;           Outputs: a vector, the internal representation is
;           abstracted, use the methods to access this data structure
;
;           Syntax(each method is followed by examples): 
;
;                   create:
;                     v = csvector(some_element)
;                     v = csvector(1)
;                     v = csvector([1,2])
;                     v = csvector({a:1,b:2})
;                   add:
;                     vector = csvector(some_element,vector) 
;                     v = csvector(1,v)
;                     v = csvector('a',v)
;                     v = csvector([1,2],v)
;                   read: 
;                     element = csvector(element_index,vector,/read)
;                     e = csvector(0,v,/read) ;first element
;                     e = csvector(csvector(v,/L)-1,v,/r) ;last element 
;                   length: 
;                     length = csvector(vector,/length)
;                     l = csvector(v,/l)
;                     l = csvector(v,/length)
;                   free:
;                     num = csvector(vector,/free)
;                     temp = csvector(v,/free)
;                   
;
;
;       NOTES: in the event of overflow during add the vector.a
;       component will double in size
;
;       Add/Create stores a copy of the element not the element itself
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
;-


function csvector,arg1,arg2,read=read,length=length,free=free

if keyword_set(length) then begin ;length

   if ~keyword_set(arg1) then begin
      message,'Illegal syntax(arg1 must be set)'
   endif

   if keyword_set(arg2) then begin
      message,'Illegal syntax(arg2 and length are set)'
   endif

   if keyword_set(read) then begin
      message,'Illegal syntax(length and read are set)'
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

   if keyword_set(read) then begin
      message,'Illegal syntax(free and read are set)'
   endif

   ptr_free,arg1.d

   return,arg1.l

endif else if ~keyword_set(arg2) then begin ;create

   if keyword_set(read) then begin
      message,'Illegal syntax(read is set)'
   endif

   data = ptr_new(arg1)

   return, {d:[data],l:1L}

endif else if keyword_set(read) then begin ;read
   
   ;check type of arg1=int

   ;check arg1 < arg2.l

   return,*(arg2.d[arg1])

endif else begin ;add

   data = ptr_new(arg1)

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

end
