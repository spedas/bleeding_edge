;+
; Purpose: Object that provides an efficient means of concatenating arrays
; da= DynamicArray([InitialArray][,name='name1')
; Purpose:  Returns a "dynamic array" object.  This dynamic array can have any number of elements and can be efficiently 
; appended to. 
; 
; This routine is particularly useful when appending to large arrays on numerous occassions.  This is especially useful
; when the final size of the array is not known when first initialized.
; 
; It is functionally equivalent to:
; a= findgen(10)
; b = 1.
; a = [a,b]
; but considerably more effiecient because the array size does not need to be increased at every append operation.
; 
; Because one can produce arrays of objects, it is a conveniant way of constructing arrays of arrays
; containing different things.
; 
; Works with multidimensional arrays too.
; 
; USAGE:
;   da = dynamicarray(findgen(1000000), name='Test1')
;      Or 
;   da.array = findgen(1000000)    ; equivalent
;      Or
;   da = dynamicarray()     &   da.append, findgen(1000000)
;   da.append,  findgen(1000)  ;  append some data
;   da.append, !values.f_nan      ; add a NAN at the end.
;   da.name = 'NewName'   ; change name
;   
;   a = da.array   ; retrieve a copy of the array
;   print,da.size   ; print the number of elements in the array  (first dimension of multidimensional arrays)
;   help,da.name   ; display the optional user name
;   
;   object_destroy, da   ; cleanup when done.
;   
;   Written by Davin Larson - August 2016
;-

pro dynamicarray_example
  t0=systime(1)
  ;  start_array = lindgen(10)   ; execution time is highly dependent on the size of the array that is appended to.
  start_array = !null
  printdat,start_array
  n=2000  ;*2
  block = replicate(1,1000)

  print,'Using dynamic array:'
  da1 = dynamicarray(start_array,name='example1')
  for i=0L,n-1 do  begin
    da1.append,i*block
  endfor
  a = da1.array
  t1 = systime(1)
  dt = t1-t0
  printdat,a,dt
  print,'Appending to end of array ',n,' times takes ',dt,' seconds'
  obj_destroy,da1

  print,'Using standard array concatenation:  time increases as n^2'
  a = start_array
  for i=0L,n-1 do begin
    a = [a,i*block]
  endfor
  t2 = systime(1)
  dt = t2-t1
  printdat,a,dt
  print,'Appending to end of array ',n,' times takes ',dt,' seconds'
end





FUNCTION DynamicArray::Init,array, _EXTRA=ex
COMPILE_OPT IDL2
; Call our superclass Initialization method.
void = self->generic_object::Init(_extra=ex)
self.xfactor = .5
self.ptr_array = ptr_new(!null)
;dim = size(/dimen,array)
;self.size = dim[0]
;self.dlevel = 4
IF (ISA(ex)) THEN self->SetProperty, _EXTRA=ex
self.append,array
dprint,verbose=verbose,dlevel=self.dlevel+2,'Created new '+typename(self)+ ': "'+self.name+'"'
RETURN, 1
END
 
 
PRO DynamicArray::Cleanup
COMPILE_OPT IDL2
; Call our superclass Cleanup method
;  *self.ptr_array = !null   ;; line not needed
dprint,verbose=verbose,dlevel=self.dlevel+2,'Cleanup of '+typename(self)+ ': '+self.name
ptr_free,self.ptr_array
;   self->generic_object::Cleanup  ;  not required???
END

;
;function DynamicArray::printdat_string,full=full
;  COMPILE_OPT IDL2
;  outstr = !null
;  if keyword_set(full) then help,self,/object
;  printdat,self.name,varname='NAME',output=str   &   outstr = [outstr,str]
;  printdat,self.ptr_array,varname='PTR_ARRAY',output=str    &   outstr = [outstr,str]
;  printdat,self.size,varname='SIZE',output=str   &   outstr = [outstr,str]
;  dim = size(/dimen,*self.ptr_array)
;  printdat,dim,output=str   &   outstr = [outstr,str]
;  printdat,typename(*self.ptr_array),varname='TYPE',output=str   &   outstr = [outstr,str]
;  return,outstr
;END



;PRO DynamicArray::help,full=full
;  COMPILE_OPT IDL2
;  if keyword_set(full) then help,self,/object
;  printdat,self.ptr_array,varname='PTR_ARRAY'
;  printdat,self.size,varname='SIZE'
;  dim = size(/dimen,*self.ptr_array)
;  printdat,dim
;  printdat,self.name,varname='NAME'
;  printdat,typename(*self.ptr_array),varname='TYPE'
;END



pro DynamicArray::append, a1, error = error
compile_opt IDL2

error = ''

if 1 then begin  ;  Don't use old routine append_array
  fillnan =1

  if isa(a1,'Undefined')  then begin              ; n_elements(a1) eq 0;;  Warning- this could have unexpected results if a1 is a null pointer or null object
    dprint,verbose=verbose,dlevel=self.dlevel+1,'Appending Null'
    return     ; Quietly do nothing
  endif

  dim1 = size(/dimension,a1)  
  n1 = dim1[0] > 1
  a0 = self.ptr_array

  if n_elements(*a0) eq 0   then begin   ; Initialize if  undefined.     
    *a0 = [a1]
    dim0 = size(/dimension,*a0)
    self.size = dim0[0]
    return
  endif
  
  dim0 = size(/dimension,*a0) 
  n0 = dim0[0] > 1
    
  type0 = size(/type,*a0)
  type1 = size(/type,a1)
  
  
  a0_set = 1
  if a0_set then begin
    if (type1 eq 8) || (type0 eq 8) then begin   ; structures
      if type1 ne type0 then begin
        error = 'Type Mismatch, Unable to concatenate'
      endif else   if n_tags(*a0) ne n_tags(a1) then begin
        error = 'Type Mismatch, Unable to concatenate structures with different tags'
      endif else   if n_tags(/length,*a0) ne n_tags(/length,a1)  then begin
        error = 'Type Mismatch, Unable to concatenate structures with different size'
      endif
    endif

    if (type0 eq 10 || type1 eq 10) && (type1 ne type0) then begin   ; pointers
      error = 'Type Mismatch, Unable to concatenate'
    endif

    if (type0 eq 11 || type1 eq 11) && (type1 ne type0) then begin   ;  objects
      error = 'Type Mismatch, Unable to concatenate'
    endif

    if n_elements(dim0) ne n_elements(dim1) || ((n_elements(dim0) ge 2) &&  array_equal(dim0[1,*],dim1[1,*] eq 0))  then begin
      error = 'Size Mismatch, Unable to concatenate'
    endif
    
    if keyword_set(error) then begin
      dimstr = '['+string(dim0,format="(8(i0.0,:,','))")+']'
      prefix = 'DynamicArray("'+self.name+'"): '+typename(*a0) + dimstr
      dimstr = '['+string(dim1,format="(8(i0.0,:,','))")+']'
      suffix = typename(a1) + dimstr
      error = prefix +": "+ error +" " + suffix      
    endif
  endif


  if keyword_set(error) then begin
    dprint,verbose=verbose,dlevel=self.dlevel,error
    return
  endif
  
  index = self.size

  if n1 + index gt n0 then begin    ;   existing buffer not large enough to insert new values - incease size
;    xfactor = .5
    fill = (*a0)[0]
    if keyword_set(fillnan) then fill =   fill_nan(fill) 
    if n_elements(dim1) ne n_elements(dim0) then begin
      dprint,verbose=verbose,dlevel=self.dlevel,'Incompatible appending'
    endif
    dim = dim0
    add = floor((n0+n1) * self.xfactor+ n1 )
    dim[0] = add
    fillx = replicate(fill,dim)
    *a0 = [*a0,fillx]                       ;  This is the operation that can take a long time to perform
    dprint,verbose=verbose,dlevel=self.dlevel+2,'Enlarging '+self.name+' array by ',add,' elements. New size:', size(/dim,*a0)
    n0=n0+add
  endif


  (*a0)[index:index+n1-1,*,*,*] = a1               ; Insert new values
  self.size  = index + n1

  return
 
endif else begin    ; Usee old version of append_array
  ind =self.size
  append_array,*self.ptr_array,a1,index=ind,error=error
  if keyword_set(error) then begin
    dprint,verbose=verbose,dlevel=self.dlevel,self.name,error
    ;self.typename
  endif
  self.size=ind  
endelse
end


pro DynamicArray::trim    ; Truncate ptr_array to its proper value
compile_opt IDL2
if 1 then begin
  *self.ptr_array = (*self.ptr_array)[0:self.size-1,*]
endif else begin
  ind = self.size
  append_array,*self.ptr_array,index= ind
  self.size = ind  
endelse
end

 
 
 
PRO DynamicArray::GetProperty, array=array, size=size, ptr=ptr, name=name  ,  typestring=typestring
; This method can be called either as a static or instance.
COMPILE_OPT IDL2
IF (ARG_PRESENT(array)) THEN begin
  if self.size eq 0 then array=!null   else  array = (*self.ptr_array)[0:self.size-1,*,*,*]
ENDIF
IF (ARG_PRESENT(size)) THEN size = self.size
IF (ARG_PRESENT(ptr)) THEN ptr = self.ptr_array
IF (ARG_PRESENT(name)) THEN name = self.name
IF (ARG_PRESENT(typestring)) THEN typestring = typename(*self.ptr_array)
END
 
 
 
PRO DynamicArray::SetProperty, array=array, name=name, xfactor=xfactor ;,dlevel=dlevel
COMPILE_OPT IDL2
; If user passed in a property, then set it.
IF (ISA(array) || isa(array,/null)) THEN begin
  dprint,verbose=verbose,dlevel=self.dlevel+2,'Changing array: "'+self.name+'"'
  if 0 then begin   ; This section has been commented out because it was not needed and extraordinarily slow for large arrays
    ptrs = ptr_extract(*self.ptr_array)
    if isa(ptrs) then begin
      dprint,verbose=verbose,'Warning! old pointers NOT freed in old dynamicarray: "'+self.name+'"',dlevel=self.dlevel+1
 ;     ptr_free,ptrs
    endif
  endif
  *self.ptr_array = !null    ; Warning there is possibility of leaving dangling pointers.
  self.size = 0
  self.append, array
ENDIF
if isa(name,/string) then begin
  self.name = name
endif
if isa(xfactor) then self.xfactor = xfactor
;if isa(dlevel) then self.dlevel = dlevel
END
 
 
 
PRO DynamicArray__define
COMPILE_OPT IDL2
void = {DynamicArray, $
;  inherits IDL_Object, $ ; superclass
  inherits generic_object,  $
  name: '',  $     ; optional name
  size: 0L, $     ; user size  (less than or equal to actual size)  (first dimension of multi dimensional arrays)
  ptr_array: ptr_new(), $ ; pointer to array
  xfactor: 0.  $  ;  Fractional increase in size of array
;  dlevel: 0 $     ; controls dprint dlevel for debugging
}
END
