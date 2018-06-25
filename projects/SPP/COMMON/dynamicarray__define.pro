;+
; da= DynamicArray([InitialArray][,name='name1')
; Purpose:  Returns a "dynamic array" object.  This dynamic array can have any number of elements and can be efficiently 
; appended to.  Because one can produce arrays of objects, it is a conveniant way of constructing arrays of arrays 
; containing different things.
; 
; This routine is particularly useful when appending to large arrays on multiple occassions.  This is especially useful
; when the final size of the array is not known when first initialized.
; 
; USAGE:
;   da = dynamicarray(name='Test1')
;   da.append,  findgen(1000000)  ;
;   da.append, !values.f_nan      ; add a NAN at the end.
;   
;   a = da.array   ; retrieve a copy of the array
;   print,da.size   ; print the number of elements in the array
;   help,da.name   ; display the optional user name
;   
;-




FUNCTION DynamicArray::Init,a, _EXTRA=ex
COMPILE_OPT IDL2
; Call our superclass Initialization method.
void = self->IDL_Object::Init()
;printdat,a
self.ptr_array = ptr_new(a)
self.size = n_elements(a)
IF (ISA(ex)) THEN self->SetProperty, _EXTRA=ex
RETURN, 1
END
 
PRO DynamicArray::Cleanup
COMPILE_OPT IDL2
; Call our superclass Cleanup method
;  *self.ptr_array = !null   ;; line not needed
ptr_free,self.ptr_array
self->IDL_Object::Cleanup
END

PRO DynamicArray::help
  COMPILE_OPT IDL2
  printdat,self.ptr_array,varname='PTR_ARRAY'
  printdat,self.size,varname='SIZE'
  printdat,self.name,varname='NAME'
  printdat,typename(*self.ptr_array),varname='TYPE'
END



pro DynamicArray::append, b
compile_opt IDL2
ind =self.size
append_array,*self.ptr_array,b,index=ind,error=error
if keyword_set(error) then begin
  dprint,dlevel=2,self.name
  ;self.typename
endif
self.size=ind
end


pro DynamicArray::trim
compile_opt IDL2
ind = self.size
append_array,*self.ptr_array,index= ind
self.size = ind
end


pro dynamicarray_example
  t0=systime(1)
  start_array = lindgen(1000000)   ; execution time is highly dependent on the size of the array that is appended to.
  n=2000
  da1 = dynamicarray(start_array,name='example1')
  for i=0L,n-1 do     da1.append,i
  a = da1.array
  t1 = systime(1)
  dt = t1-t0
  printdat,a,dt
  a = start_array
  for i=0L,n-1 do a = [a,i]
  t2 = systime(1)
  dt = t2-t1
  printdat,a,dt
end
 
 
 
 
PRO DynamicArray::GetProperty, array=array, size=size, ptr=ptr, name=name,  typename=typename
; This method can be called either as a static or instance.
COMPILE_OPT IDL2
IF (ARG_PRESENT(array)) THEN begin
  if self.size eq 0 then array=!null   else  array = (*self.ptr_array)[0:self.size-1]
ENDIF
IF (ARG_PRESENT(size)) THEN size = self.size
IF (ARG_PRESENT(ptr)) THEN ptr = self.ptr_array
IF (ARG_PRESENT(name)) THEN name = self.name
IF (ARG_PRESENT(typename)) THEN typename = typename(*self.ptr_array)
END
 
 
 
PRO DynamicArray::SetProperty, array=array, name=name
COMPILE_OPT IDL2
; If user passed in a property, then set it.
IF (ISA(array) || isa(array,/null)) THEN begin
  ptrs = ptr_extract(*self.ptr_array)
  if isa(ptrs) then begin
    dprint,'Warning! old pointers freed in old dynamicarray: '+self.name,dlevel=2
    ptr_free,ptrs
  endif
  *self.ptr_array = array
  self.size = n_elements(array)
ENDIF
if isa(name,/string) then begin
  self.name = name
endif
END
 
 
 
PRO DynamicArray__define
COMPILE_OPT IDL2
void = {DynamicArray, $
  inherits IDL_Object, $ ; superclass
  ptr_array: ptr_new(), $ ; pointer to array
  size: 0L, $     ; user size  (less than or equal to actual size)
  name: ''  $     ; optional name 
}
END
