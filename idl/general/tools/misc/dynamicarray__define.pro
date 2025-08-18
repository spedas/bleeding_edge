;+
; Written by Davin Larson - August 2016
; $LastChangedBy: rjolitz $
; $LastChangedDate: 2025-03-04 10:57:07 -0800 (Tue, 04 Mar 2025) $
; $LastChangedRevision: 33161 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/tools/misc/dynamicarray__define.pro $

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


FUNCTION DynamicArray::Init,array, _EXTRA=ex,tplot_tagnames=tplot_tagnames
  COMPILE_OPT IDL2
  ; Call our superclass Initialization method.
  void = self->generic_object::Init(_extra=ex)
  self.xfactor = .5
  self.ptr_array = ptr_new(!null)
  self.dict = dictionary()
  if isa(tplot_tagnames,'string') then  self.dict.tplot_tagnames = tplot_tagnames
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


pro DynamicArray::append, a1, error = error,replace=replace
  compile_opt IDL2

  if n_elements(replace) eq 0 then replace=1
  error = ''
  size_error=error

  if 1 then begin  ;  Don't use old routine append_array
    fillnan =1

    if isa(a1,'Undefined')  then begin              ; n_elements(a1) eq 0;;  Warning- this could have unexpected results if a1 is a null pointer or null object
      dprint,verbose=self.verbose,dlevel=self.dlevel+1,'Appending Null'
      return     ; Quietly do nothing
    endif

    dim1 = size(/dimension,a1)
    n1 = dim1[0] > 1
    a0 = self.ptr_array

    if n_elements(*a0) eq 0 || self.size eq 0  then begin   ; Initialize if  undefined.
      *a0 = [a1]
      dim0 = size(/dimension,*a0)
      self.size = dim0[0]
      if self.dict.haskey('tplot_tagnames') then begin   ; This feature may be disabled in the future  - DON'T use
        tags = self.dict.tplot_tagnames
        dprint,dlevel=2,verbose=self.verbose,'Creating TPLOT variables: '+self.name+'_['+strjoin(tags,',')+']'
        store_data,verbose=0,self.name,data= self ,tagnames=tags,/silent  ;,separator = '_'
      endif
      return
    endif

    dim0 = size(/dimension,*a0)
    n0 = dim0[0] > 1

    type0 = size(/type,*a0)
    type1 = size(/type,a1)
    prefix = 'Dynamic Array: "'+self.name+'" '

    if (type1 eq 8) || (type0 eq 8) then begin   ; structures
      typenam0 =  typename((*a0)[0])
      typenam1 =  typename( a1[0])
      if type1 ne type0 then begin
        error =  Prefix+'Type Mismatch, Unable to concatenate'
      endif else if typenam0 ne typenam1 then begin
        error = Prefix+'Type Mismatch, Unable to cancatenate structure {'+typenam0+'} with structure {'+typenam1 +'}'
      endif else   if ~array_equal( tag_names(*a0) , tag_names(a1)) then begin
        error = Prefix+'Type Mismatch, Unable to concatenate structures with different tagnames'
      endif else   if n_tags(/length,*a0) ne n_tags(/length,a1)  then begin
        error = Prefix+'Type Mismatch, Unable to concatenate structures with different length'
      endif else   if n_tags(/data_length,*a0) ne n_tags(/data_length,a1)  then begin
        error = Prefix+'Type Mismatch, Unable to concatenate structures with different data_length'
      endif
    endif

    if keyword_set(error) && (type1 eq type0) && keyword_set(replace)   then begin
      dprint,verbose=self.verbose,dlevel=self.dlevel,error
      dprint,verbose=self.verbose,dlevel=self.dlevel,Prefix+'Replacing old structure {'+typenam0+'} with newly defined structure {'+typenam1+'}'
      a0_new = replicate( fill_nan(a1[0]), size(/dimen,*a0))
      struct_assign,*a0,a0_new,/nozero,/verbose
      *a0 = a0_new
      error=''
    endif


    if (type0 eq 10 || type1 eq 10) && (type1 ne type0) then begin   ; pointers
      error =Prefix+ 'Type Mismatch, Unable to concatenate'
    endif

    if (type0 eq 11 || type1 eq 11) && (type1 ne type0) then begin   ;  objects
      error = Prefix+'Type Mismatch, Unable to concatenate'
    endif

    if n_elements(dim0) ne n_elements(dim1) || ((n_elements(dim0) ge 2) &&  array_equal(dim0[1,*],dim1[1,*] eq 0))  then begin
      error = Prefix+'Size Mismatch, Unable to concatenate'
      size_error=error
    endif

    index = self.size
    if n1 + index gt n0 then begin    ;   existing buffer not large enough to insert new values - incease size
      ;    xfactor = .5
      fill = (*a0)[0]
      if keyword_set(fillnan) then fill =   fill_nan(fill)
      if n_elements(dim1) ne n_elements(dim0) then begin
        dprint,verbose=self.verbose,dlevel=self.dlevel,Prefix+'Incompatible appending'
      endif
      dim = dim0
      add = floor((n0+n1) * self.xfactor+ n1 )
      dim[0] = add
      fillx = replicate(fill,dim)
      *a0 = [*a0,fillx]                       ;  This is the operation that can take a long time to perform
      dprint,verbose=self.verbose,dlevel=self.dlevel+2,'Enlarging '+self.name+' array by ',add,' elements. New size:', size(/dim,*a0)
      n0=n0+add
    endif

    if keyword_set(error) then begin
      dimstr = '['+string(dim0,format="(8(i0.0,:,','))")+']'
      prefix = 'DynamicArray("'+self.name+'"): '+typename(*a0) + dimstr
      dimstr = '['+string(dim1,format="(8(i0.0,:,','))")+']'
      suffix = typename(a1) + dimstr
      error = prefix +": "+ error +" " + suffix
      dprint,verbose=self.verbose,dlevel=self.dlevel,error
      if ~keyword_set(size_error) then begin
        dprint,verbose=self.verbose,dlevel=self.dlevel,'Attempting to concatenate using "relaxed structure assignment" (STRUCT_ASSIGN)'
        a2=(*a0)[index:index+n1-1,*,*,*]
        struct_assign,a1,a2,/nozero ,verbose=self.verbose
        a1=a2
      endif else return
    endif
    (*a0)[index:index+n1-1,*,*,*] = a1 ; Insert new values
    self.size = index + n1

  endif else begin    ; Usee old version of append_array
    dprint, "Don't use this!!"
;    ind =self.size
;    append_array,*self.ptr_array,a1,index=ind,error=error
;    if keyword_set(error) then begin
;      dprint,verbose=self.verbose,dlevel=self.dlevel,self.name,error
;      ;self.typename
;    endif
;    self.size=ind
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

function DynamicArray::slice,indices,last=last   ;,tagname=tagname
  compile_opt IDL2
  if keyword_set(last) then indices = self.size-1
  if ptr_valid(self.ptr_array) && isa(*self.ptr_array,/array) then return ,(*self.ptr_array)[indices,*,*,*]
  return,!null
end

; ::sample will extract a sample of data from a set of data based on a range of indices
; It is most useful if the stored data is an array of structures
function DynamicArray::sample,nearest=nearest,range=range,tagname=tagname
  compile_opt IDL2
  vals = !null
  if isa(tagname,/string) then begin
    tag_num = where(/null,tag_names(*self.ptr_array) eq strupcase(tagname))
    if isa(tag_num) then begin
      vals= ((*self.ptr_array).(tag_num))[0:self.size-1,*,*,*]
      if keyword_set(nearest) then begin
        w = interp(dindgen(self.size),vals,nearest,/last_value)
        ;printdat,w,vals[w],vals[w]-nearest
        vals = (*self.ptr_array)[w,*,*,*]  
      endif else if isa(range) then begin
        w= where(/null,vals ge min(range[0]) and vals lt max(range[1]))
        vals = (*self.ptr_array)[w,*,*,*]
      endif else begin
        vals = (*self.ptr_array)[0:self.size-1,*,*,*]
      endelse
    endif
  endif else vals = (*self.ptr_array)[0:self.size-1,*,*,*]
  return,vals
end



pro DynamicArray::sort   , tagname    , uniq=uniq   ; Use with caution
  nsize = self.size
  if isa(tagname,/string) && isa(*self.ptr_array,'struct') then begin
    if strlowcase(tagname) ne 'time' then message,'Can only sort on time for now.'

    ;v = ((*self.ptr_array)[0: self.size-1] ).time
    v = (*self.ptr_array).time
    v = v[0:nsize-1]

  endif else begin
    v = (*self.ptr_array)[0: nsize-1] 
  endelse
  s= sort( v )
  (*self.ptr_array)[0:nsize-1]  = (*self.ptr_array)[s]
  if keyword_set(uniq) then begin
    u = uniq( ((*self.ptr_array)[0:nsize-1]).time )
    nusize = n_elements(u)
    self.size = nusize
    (*self.ptr_array)[0:nusize-1]  = (*self.ptr_array)[u]    
  endif


end




pro DynamicArray::make_ncdf,filename=ncdf_filename,verbose=verbose,global_atts=global_atts,ncdf_template=ncdf_template
  dat = (*self.ptr_array)[0:self.size-1,*,*,*]
  swfo_ncdf_create,dat,filename=ncdf_filename,verbose=verbose,global_atts=global_atts,ncdf_template=ncdf_template

end





PRO DynamicArray::GetProperty, array=array, size=size, ptr=ptr, name=name  ,  typestring=typestring, dictionary=dict
  ; This method can be called either as a static or instance.
  COMPILE_OPT IDL2
  IF (ARG_PRESENT(array)) THEN begin
    if self.size eq 0 then array=!null   else  array = (*self.ptr_array)[0:self.size-1,*,*,*]
  ENDIF
  IF (ARG_PRESENT(size)) THEN size = self.size
  IF (ARG_PRESENT(ptr)) THEN ptr = self.ptr_array
  IF (ARG_PRESENT(name)) THEN name = self.name
  IF (ARG_PRESENT(typestring)) THEN typestring = typename(*self.ptr_array)
  if arg_present(dict) then dict = self.dict

END


PRO DynamicArray::SetProperty, array=array, name=name, size=size, xfactor=xfactor, verbose=verbose ,dlevel=dlevel
  COMPILE_OPT IDL2
  ; If user passed in a property, then set it.
  IF (ISA(array) || isa(array,/null)) THEN begin
    dprint,verbose=self.verbose,dlevel=self.dlevel+2,'Changing array: "'+self.name+'"'
    if 0 then begin   ; This section has been commented out because it was not needed and extraordinarily slow for large arrays
      ptrs = ptr_extract(*self.ptr_array)
      if isa(ptrs) then begin
        dprint,verbose=self.verbose,'Warning! old pointers NOT freed in old dynamicarray: "'+self.name+'"',dlevel=self.dlevel+1
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
  if isa(size) then self.size = size
  if isa(dlevel) then self.dlevel = dlevel
  if isa(verbose) then self.verbose = verbose
END


PRO DynamicArray__define
  COMPILE_OPT IDL2
  void = {DynamicArray, $
    ;  inherits IDL_Object, $ ; superclass
    inherits generic_object,  $
    name: '',  $     ; optional name
    size: 0L, $     ; user size  (less than or equal to actual size)  (first dimension of multi dimensional arrays)
    ptr_array: ptr_new(), $ ; pointer to array
    dict: obj_new() , $    general purpose dictionary that can be used by the user for any purpose
    xfactor: 0.  $  ;  Fractional increase in size of array that is use ehen expanding the array
    ;  dlevel: 0 $     ; controls dprint dlevel for debugging
  }
END
