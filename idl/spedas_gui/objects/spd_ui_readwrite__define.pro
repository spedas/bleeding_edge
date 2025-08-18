;+ 
;NAME: 
; spd_ui_readwrite__define
;
;PURPOSE:  
; Base class for object serialize/de-serialize methods.  This class
; has no data members and should not be instantiated, only inherited
; from.  It uses IDL's rudimentary reflection capabilities to 
; figure out which fields need to be read/written, and what their
; types are.
;
;
;INPUT:
; none
;
;KEYWORDS:
; none
;
;OUTPUT:
; none
;
;METHODS:
; read  Read an object from a file
; write Write an object to a file
; test  Write an object, read it back into a new object, write new object
; 
;HISTORY:
;
;$LastChangedBy: pcruce $
;$LastChangedDate: 2015-01-12 16:43:43 -0800 (Mon, 12 Jan 2015) $
;$LastChangedRevision: 16649 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas_gui/objects/spd_ui_readwrite__define.pro $
;-----------------------------------------------------------------------------------


FUNCTION SPD_UI_READWRITE::Init
                   
RETURN, 1
END

;helper function to add line feeds/carriage returns to document
pro spd_ui_readwrite::appendXMLNewline,parent

  document = parent->getOwnerDocument()
  element = document->createTextNode(string(13B)+string(10B))
  tmp = parent->appendChild(element)    
end

;This method takes a node list object and returns
;an array of the nodes in the list, but with extraneous
;text objects removed
function spd_ui_readwrite::getNodeArray,nodelist

  compile_opt idl2

  length = nodelist->getlength()
  
  for i = 0,length-1 do begin
  
    item = nodelist->item(i)
  
    if ~obj_isa(item,'IDLFFXMLDOMTEXT') then begin
    
      if ~keyword_set(out) then begin
        out = [item]
      endif else begin
        out = [out,item]
      endelse
    
    endif
  
  endfor
    if ~keyword_set(out) then begin
    return,0
  endif else begin
    return,out
  endelse

end

function spd_ui_readwrite::GetDOMElement,parent_node

type_strings=['undefined','byte','int','long','float','double','complex', $
             'string','struct','dcomplex','pointer','object','uint','ulong',$
             'long64','ulong64']
format_strings=['(I)','(I)','(I)','(I)','(E14.6)','(E21.13)','(D)',$
                '(A)','(A)','(D)','(A)','(A)','(I)','(I)','(I)']
is_primitive=[0,1,1,1,1,1,0, $
             1,0,0,0,0,1,1,1,1]

; Enumerate this object's fields with tag_names, then write each field
; (possibly recursively, for objects and containers) in a form that
; can easily be read back in later, without loss of precision for
; floating point types.

; Unfortunately (insert profuse swearing here!) tag_names() doesn't work on 
; objects, only structures.  So even though we already have the object in 
; hand, we need to create a structure of the same type, solely for the
; purpose of enumerating the tags.  At least the self.(tag_index) syntax
; still works for objects...

structname=obj_class(self)
self_as_structure=create_struct(name=structname)
tagnames=tag_names(self_as_structure)

; From this point on, we use the original object instead of 
; self_as_structure, whose only purpose is to give us a way to
; look up the tag names at runtime.

; Get the owner document from the parent node, and create the node
; to represent the element currently being built.

owner=parent_node->GetOwnerDocument()
dom_element = owner->CreateElement(structname)
self->appendXMLNewline,dom_element

; Loop through each tag
for i=0, n_elements(tagnames)-1 do begin
 
   ; Skip fields that match the regex '_+_DUMMY$', because IDL doesn't allow classes with no members.
   ; (This allows fields like ___DUMMY, and ____DUMMY....etc...
   if stregex(tagnames[i],'_+_DUMMY$',/boolean) then continue
   
   fieldval=self.(i)
   nelem=n_elements(fieldval)
   fieldtype=size(fieldval,/type)
   primitive_flag=is_primitive[fieldtype]
   format_code=format_strings[fieldtype]
   type_string=type_strings[fieldtype]

   ; Not sure how to handle these cases yet...
   if (type_string EQ 'pointer') then begin
      continue
   endif else if (type_string EQ 'struct') then begin
      continue
   endif

   ; Make an attribute element

   thisattr=owner->CreateElement('attribute')
   thisattr->SetAttribute,'name',tagnames(i)
   nelem_str=strtrim(string(nelem,format='(I)'),2)
   thisattr->SetAttribute,'nelem',nelem_str
   thisattr->SetAttribute,'type',type_string

   child = dom_element->AppendChild(thisattr)
   self->appendXMLNewline,dom_element

   for j=0,nelem-1 do begin
      if (primitive_flag EQ 1) then begin
         ; primitive type
         valobj=owner->CreateElement('value')
         valobj->SetAttribute,'index',strtrim(string(j,format='(I)'),2)
         valobj->SetAttribute,'type','primitive'
         child=thisattr->AppendChild(valobj)

         valstr=string(fieldval[j],format=format_code)
         val=owner->CreateTextNode(valstr)
         child=valobj->AppendChild(val)
         self->appendXMLNewline,thisattr
      endif else if (type_string EQ 'object') then begin
         ; objects
         valobj=owner->CreateElement('value')
         valobj->SetAttribute,'index',strtrim(string(j,format='(I)'),2)
         valobj->SetAttribute,'type','object'
         if ~obj_valid(fieldval[j]) then begin
            ; null
            valobj->SetAttribute,'class','NULLOBJ'
         endif else if obj_isa(fieldval[j],'IDL_CONTAINER') then begin
            ; idl_container
            valobj->SetAttribute,'class','IDL_CONTAINER'
            ; Get children
            child_array=(fieldval[j])->Get(/all,count=container_count)
            valobj->SetAttribute,'container_count',strtrim(string(container_count,format='(I)'),2)
            if (container_count GT 0) then begin
;               contained_type=obj_class(child_array[0])
               ;get all contained types and join into a single string
               ;leave duplicates for now 2014-03-??
               for k=0, n_elements(child_array)-1 do begin
                  contained_type = array_concat(obj_class(child_array[k]),contained_type)
               endfor
               contained_type = strjoin(contained_type,' ')
               valobj->SetAttribute,'contained_type',contained_type
               for container_index=0,container_count-1 do begin
                  this_obj=child_array[container_index]
                  child_val=owner->CreateElement('value')
                  child_val->SetAttribute,'index',strtrim(string(container_index,format='(I)'),2)
                  child_val->SetAttribute,'type','object'
                  child_val->SetAttribute,'class',obj_class(this_obj)
                  this_dom_element = this_obj->GetDOMElement(child_val)
                  dummy=child_val->AppendChild(this_dom_element)
                  dummy=valobj->AppendChild(child_val)
                  self->appendXMLNewline,valobj
               endfor
            endif 
         endif else begin
            ; ui obj
            valobj->SetAttribute,'class',obj_class(fieldval[j])
            subobj=(fieldval[j])->GetDOMElement(valobj)
            child=valobj->AppendChild(subobj)
         endelse

         child=thisattr->AppendChild(valobj)

      endif else begin
         message,'Unhandled case: type '+type_string
      endelse
   endfor

endfor ; loop over field names
return,dom_element
end

pro spd_ui_readwrite::BuildFromDOMElement,dom_element
type_strings=['undefined','byte','int','long','float','double','complex', $
             'string','struct','dcomplex','pointer','object','uint','ulong',$
             'long64','ulong64']
format_strings=['(I)','(I)','(I)','(I)','(E14.6)','(E21.13)','(D)',$
                '(A)','(A)','(D)','(A)','(A)','(I)','(I)','(I)']
is_primitive=[0,1,1,1,1,1,0, $
             1,0,0,0,0,1,1,1,1]

; Enumerate this object's fields with tag_names, then write each field
; (possibly recursively, for objects and containers) in a form that
; can easily be read back in later, without loss of precision for
; floating point types.

; Unfortunately (insert profuse swearing here!) tag_names() doesn't work on 
; objects, only structures.  So even though we already have the object in 
; hand, we need to create a structure of the same type, solely for the
; purpose of enumerating the tags.  At least the self.(tag_index) syntax
; still works for objects...

structname=obj_class(self)
self_as_structure=create_struct(name=structname)
tagnames=tag_names(self_as_structure)

; From this point on, we use the original object instead of 
; self_as_structure, whose only purpose is to give us a way to
; look up the tag names at runtime.

element_name=dom_element->GetNodeName()
;dprint, 'In BuildFromDOMElement: '+element_name

; Check that the node name matches the object type.

if (element_name NE structname) then begin
   message,'Mismatched types: object type '+structname+', DOM node name '+element_name
endif

; Get the attribute tags, which are children of dom_element. Filter
; out anything that's not an attribute.

sib=dom_element->GetFirstChild()
while (obj_valid(sib)) do begin
  sibname=sib->GetNodeName()
  if (sibname EQ 'attribute') then begin
     if ~keyword_set(attribute_list) then begin
        attribute_list=[sib]
     endif else begin
        attribute_list=[attribute_list,sib]
     endelse
  endif
  sib=sib->GetNextSibling()
endwhile

att_count = n_elements(attribute_list)
;dprint, att_count,format='("Found ",I," attributes:")'
for i=0, att_count-1 do begin
  att=attribute_list[i]
  name=att->GetAttribute('name')
  type=att->GetAttribute('type')
  nelem=att->GetAttribute('nelem')
  ;dprint, name,type,nelem,format='("Name: ",A," Type: ",A," nelem: ",A)'

  ; Check that the attribute name corresponds to a field name for this object.

  tagindex=where(name EQ tagnames)
  if (tagindex < 0) then begin
    message,'Attribute name '+name+' is not valid for class '+structname
  end

  ; Get the current value of this field of self
  proto_val=self.(tagindex)
  proto_type=size(proto_val,/type)
  proto_typestring = type_strings[proto_type]
  proto_nelem = n_elements(proto_val)

  ; Check that types match
  if (proto_typestring NE type) then begin
     message,'Type mismatch: class '+structname+', attribute '+name+', expected '+proto_typestring+', got '+type
  endif
 
  ; Check that element counts match
  if (proto_nelem NE nelem) then begin
     message,'Element count mismatch: class '+structname+', attribute '+name+', expected '+string(proto_nelem)+', got '+string(nelem)
  endif

  ; Get the list of child value tags
  sib = att->GetFirstChild()
  first=1
  while (obj_valid(sib)) do begin
     if (sib->GetNodeName() EQ 'value') then begin
        if (first) then begin
           vals_list=[sib]
        endif else begin
           vals_list=[vals_list,sib]
        endelse
        first=0
     endif
     sib = sib->GetNextSibling()
  endwhile

  ; Check that child count equals expected number of elements

  vals_count=n_elements(vals_list)
  if (vals_count NE proto_nelem) then begin
     message,'Wrong number of value nodes: class '+structname+', attribute '+name+', expected '+string(proto_nelem)+', got '+string(vals_count)
  endif

  ; Loop over all elements, extracting values and assigning them to self

  for j=0,proto_nelem-1 do begin
    valobj=vals_list[j]
    if (is_primitive[proto_type]) then begin
       ; Needed for READS to get the type correct
       proto_variable=proto_val[0]
       ; Get child node of current value; should be a text object
       valtext=valobj->GetFirstChild()
       if obj_valid(valtext) then begin
          valstring=valtext->GetNodeValue()
       endif else begin
          if (proto_typestring EQ 'string') then begin
              valstring=''
          endif else begin
              message,'Missing child node for non-string attribute '+name
          endelse
       endelse
       valindexstr=valobj->GetAttribute('index')
       valindex=0
       reads,valindexstr,valindex,format='(I)'
       fmt=format_strings[proto_type]
       ;dprint, 'Value '+valindexstr+' '+valstring+' '+fmt
       reads,valstring,proto_variable,format=fmt
       ;dprint, 'converted value: '+string(proto_variable,format=fmt)+' index: '+string(valindex,format='(I)')
       ; Do the assignment
       self.(tagindex)[valindex] = proto_variable
    endif else if (proto_typestring EQ 'object') then begin
        ; What kind of object?
        classname=valobj->GetAttribute('class')
        valindexstr=valobj->GetAttribute('index')
        valindex=0
        reads,valindexstr,valindex,format='(I)'
        if (classname EQ 'NULLOBJ') then begin
            ; Assign a null object reference
            ;dprint, 'Assigning null object reference'
           
            ;If-else statement below is quick work around for syntax ambiguity in our serializer
            ;serialization code doesn't properly distinguish between zero element(scalar) and one element arrays
            ;This was fine until IDL8.4(may be due to a bug in IDL 8.4)
            ;IDL 8.3 or earlier: self.(tagindex)[0] = proto_value (zero indexing scalar, just returns element)
            ;IDL 8.4 and later: self.(tagindex)[0] = proto_value (zero indexing an object with overloaded [], tries to store proto_value inside object, instead of replacing 
            ;Better solution is to adopt the fix we put into the call_sequence serialization code:  proto_nelem=0 implies scalar,proto_nelem=1 or more implies 1 to N element array
            if proto_nelem eq 1 then begin
              self.(tagindex) = obj_new()
            endif else begin
              self.(tagindex)[valindex] = obj_new()
            endelse

        endif else if (classname EQ 'IDL_CONTAINER') then begin
           contained_type=valobj->GetAttribute('contained_type')
           ;support multiple types, space separated
           contained_type = strsplit(contained_type,' ',/extract)
           container_count_str=valobj->GetAttribute('container_count')
           container_count = 0
           reads,container_count_str,container_count,format='(I)' 
           ;dprint, 'Making IDL_CONTAINER of '+string(container_count)+' objects, tclass '+contained_type
           proto_value=obj_new('IDL_CONTAINER')
           if (container_count GT 0) then begin
             ; Get child objects
             child_count = 0
             container_sib=valobj->GetFirstChild()
             while obj_valid(container_sib) do begin
                 sibname=container_sib->GetNodeName()
                 if (sibname EQ 'value') then begin
                    tgt_dom_element=container_sib->GetFirstChild()
                    tgt_type=tgt_dom_element->GetNodeName()
                    if in_set(tgt_type,contained_type) then begin
                       child_count = child_count + 1
                       this_container_child=obj_new(tgt_type)
                       this_container_child->BuildFromDOMElement,tgt_dom_element
                       proto_value->Add,this_container_child
                    endif else begin
                       ;dprint, 'Loading IDL_CONTAINER, ignored node name '+tgt_type
                    endelse
                 endif else begin
                    ;dprint, 'Loading IDL_CONTAINER, ignored node name '+sibname
                 endelse
                 container_sib=container_sib->GetNextSibling()
             endwhile
 
             ; Check child count against container count
             if (child_count NE container_count) then begin
                message,'IDL_CONTAINER wrong count, expected '+string(container_count)+', got '+string(child_count)
             endif
           endif
           
           
           ; Make the assignment to self
           
           ;If-else statement below is quick work around for syntax ambiguity in our serializer
           ;serialization code doesn't properly distinguish between zero element(scalar) and one element arrays
           ;This was fine until IDL8.4(may be due to a bug in IDL 8.4)
           ;IDL 8.3 or earlier: self.(tagindex)[0] = proto_value (zero indexing scalar, just returns element)
           ;IDL 8.4 and later: self.(tagindex)[0] = proto_value (zero indexing an object with overloaded [], tries to store proto_value inside object, instead of replacing object
           ;Better solution is to adopt the fix we put into the call_sequence serialization code:  proto_nelem=0 implies scalar,proto_nelem=1 or more implies 1 to N element array
           if proto_nelem eq 1 then begin
             self.(tagindex) = proto_value
           endif else begin
             self.(tagindex)[valindex] = proto_value
           endelse
           
        endif else begin
           ; Assume it's a SPD_UI object
           ; Construct an object
           child_obj = obj_new(classname)
           ; Get the DOM element, child of current valobj
           child_dom_element=valobj->GetFirstChild()
           ; Invoke BuildFromDOMElement on child
           child_obj->BuildFromDOMElement,child_dom_element
           ; Assign to self
           
           ;If-else statement below is quick work around for syntax ambiguity in our serializer
           ;serialization code doesn't properly distinguish between zero element(scalar) and one element arrays
           ;This was fine until IDL8.4(may be due to a bug in IDL 8.4)
           ;IDL 8.3 or earlier: self.(tagindex)[0] = proto_value (zero indexing scalar, just returns element)
           ;IDL 8.4 and later: self.(tagindex)[0] = proto_value (zero indexing an object with overloaded [], tries to store proto_value inside object, instead of replacing object
           ;Better solution is to adopt the fix we put into the call_sequence serialization code:  proto_nelem=0 implies scalar,proto_nelem=1 or more implies 1 to N element array
           if proto_nelem eq 1 then begin
             self.(tagindex) = child_obj
           endif else begin
             self.(tagindex)[valindex] = child_obj
           endelse
           
        endelse
    endif else begin
        ; not a primitive, not an obj?
        message,'Unrecognized type, not primitive, not object'
    end
    
  endfor
endfor

end

pro spd_ui_readwrite::write,lun

; Enumerate this object's fields with tag_names, then write each field
; (possibly recursively, for objects and containers) in a form that
; can easily be read back in later, without loss of precision for
; floating point types.

; Unfortunately (insert profuse swearing here!) tag_names() doesn't work on 
; objects, only structures.  So even though we already have the object in 
; hand, we need to create a structure of the same type, solely for the
; purpose of enumerating the tags.  At least the self.(tag_index) syntax
; still works for objects...

structname=obj_class(self)
self_as_structure=create_struct(name=structname)
tagnames=tag_names(self_as_structure)

printf,lun,structname,format='("<",A,">")'

; From this point on, we use the original object instead of 
; self_as_structure, whose only purpose is to give us a way to
; look up the tag names at runtime.

; Loop through each tag
for i=0, n_elements(tagnames)-1 do begin

   ; Skip fields that match the regex '_+_DUMMY$', because IDL doesn't allow classes with no members.
   ; (This allows fields like ___DUMMY, and ____DUMMY....etc...
   if stregex(tagnames[i],'_+_DUMMY$',/boolean) then continue

   fieldval=self.(i)
   nelem=n_elements(fieldval)
   fieldtype=size(fieldval,/type)

   if (nelem GT 1) then begin
      ; This field is an array.

      ; Find the format code for the fieldtype, or fail if the type is
      ; unsupported for arrays
      case fieldtype of
         1: format='(I)'
         2: format='(I)'
         3: format='(I)'
         4: format='(E14.6)'
         5: format='(E21.13)'
         7: format='(A)'
        12: format='(I)'
        13: format='(I)'
        14: format='(I)'
        15: format='(I)'
      else: begin
               print,structname,tagnames[i],fieldtype,format='("Class name ",A,", tag name ",A," is an array of  unsupported type code ",I)'
               message,'Unsupported field type'
            end
      endcase

      ; Print the tag name, array marker, and array size
      printf,lun,tagnames(i),nelem,format='(A," = array ",I)'
      ; Dump the array, one value per line
      for j=0, nelem-1 do begin
         printf,lun,fieldval[j],format=format
      endfor
   endif else begin
      case fieldtype of
         1: printf,lun,tagnames(i),fieldval,format='(A," = ",I)'
         2: printf,lun,tagnames(i),fieldval,format='(A," = ",I)'
         3: printf,lun,tagnames(i),fieldval,format='(A," = ",I)'
         4: printf,lun,tagnames(i),fieldval,format='(A," = ",E14.6)'
         5: printf,lun,tagnames(i),fieldval,format='(A," = ",E21.13)'
         7: printf,lun,tagnames(i),fieldval,format='(A," = ",A)'
        10:   ; Silently ignore pointer fields
        12: printf,lun,tagnames(i),fieldval,format='(A," = ",I)'
        13: printf,lun,tagnames(i),fieldval,format='(A," = ",I)'
        14: printf,lun,tagnames(i),fieldval,format='(A," = ",I)'
        15: printf,lun,tagnames(i),fieldval,format='(A," = ",I)'
        11: begin
              objname=obj_class(fieldval)
              if (objname EQ '') then begin
                 ; Must be a null object

                 printf,lun,tagnames(i),'<NULLOBJ>',format='(A," = ",A)'
              endif else if (objname EQ 'IDL_CONTAINER') then begin
                 ; Special case: IDL container object, which doesn't
                 ; have a write method.

                 ; First, does it even contain anything?
                 contents = fieldval->Get(/all,count=objcount)
                 if (objcount EQ 0) then begin
                    ; It's empty.
                    printf,lun,tagnames(i),'IDL_CONTAINER',0,'<NULLOBJ>',format='(A," = ",A," ",I," ",A)'
                 endif else begin
                    ; It had objects in it: we assume they're all the same
                    ; type as the first object returned by get(/all).

                    contained_type=obj_class(contents[0])
                    printf,lun,tagnames(i),'IDL_CONTAINER',objcount,contained_type,format='(A," = ",A," ",I," ",A)'

                    ; Now invoke the write method on each contained object
                    for j=0,objcount-1 do begin
                       thisobj=contents[j]
                       thisobj->write,lun
                    endfor
                 endelse
              endif else begin
                 ; Normal case: a single object with a write method
                 printf,lun,tagnames(i),objname,format='(A," = ",A)'
                 fieldval->write,lun
              endelse
            end
      else: begin
               print,structname,tagnames(i),fieldtype,format='("Class name ",A,", tag name ",A," has unsupported type code ",I)'
               message,'Unsupported type code'
            end
      endcase
   endelse
endfor ; loop over field names
printf,lun,structname,format='("</",A,">")'
end

pro spd_ui_readwrite::read,lun

; Enumerate field names, using self_as_structure kludge
structname=obj_class(self)
self_as_structure=create_struct(name=structname)
tagnames=tag_names(self_as_structure)

; Define opening and closing tags
opening_tag='<'+structname+'>'
closing_tag='</'+structname+'>'

; Look for opening tag
inputline=''
readf,lun,inputline
inputline=strtrim(inputline,2)
if ~strcmp(inputline,opening_tag,/fold_case) then begin
   message,'Read error: expected '+opening_tag+', found '+inputline
endif

readf,lun,inputline
inputline=strtrim(inputline,2)

; loop through attr=value lines, quit when closing tag encountered

while ~strcmp(inputline,closing_tag,/fold_case) do begin

; We expect to see an equals sign.  Split the input into left hand and
; right hand sides, error if equals sign not found.

  index=strpos(inputline,'=')
  if (index EQ -1) then begin
     message,'Read error: expected ATTR=VALUE, got: '+inputline
  endif

  len=strlen(inputline)
  lhs=strtrim(strmid(inputline,0,index),2)
  rhs=strtrim(strmid(inputline,index+1,(len-index)-1),2)
  ; print,'input: '+inputline+' lhs: '+lhs+' rhs: '+rhs

  ; Find the tag index corresponding to LHS

  tag_index = where(strcmp(lhs,tagnames,/fold_case),count)
  if (count EQ 0) then begin
    message,'Read error: tag name '+lhs+' not recognized for class '+structname
  endif

  fieldval=self.(tag_index[0])
  field_nelems=n_elements(fieldval)
  field_type=size(fieldval,/type)

  ; Figure out what format code to use on RHS

  format='(I)' ; default

  case field_type of
    1: begin
         format='(I)'
         rhsval=0B
       end
    2: begin
         format='(I)'
         rhsval=0
       end
    3: begin
         format='(I)'
         rhsval=0L
       end
    4: begin
         format='(E14.6)'
         rhsval=0.0
       end
    5: begin
         format='(E21.13)'
         rhsval=0.0D
       end
    7: begin
         format='(A)'
         rhsval=''
       end
   11: format='(A)'  ; object; format code not used
   12: begin
         format='(I)'
         rhsval=0U
       end
   13: begin
         format='(I)'
         rhsval=0UL
       end
   14: begin
         format='(I)'
         rhsval=0LL
       end
   15: begin
         format='(I)'
         rhsval=0ULL
       end
   else: begin
            message,'Read error: class '+structname+', field '+lhs+' has unsuppoted type code '+string(field_type)
         end
  endcase

;
; Scalar fields (objects or primitives)
;
  if (field_nelems EQ 1) then begin
     if (field_type EQ 11) then begin
;
; Scalar objects
;
        expected_class=strupcase(obj_class(self.(tag_index)))
        split_rhs=strsplit(rhs,' ',/extract)
        case n_elements(split_rhs) of
           1: begin
                 observed_class=strupcase(split_rhs[0])
                 if (observed_class EQ '<NULLOBJ>') then begin
                   observed_class=''
                 endif else if (observed_class EQ 'IDL_CONTAINER') then begin
                   message,'Read error: IDL_CONTAINER type without item count or item type'
                 endif
              end
           3: begin
                 observed_class=strupcase(split_rhs[0])
                 container_count=string(split_rhs[1])
                 contained_type=strupcase(split_rhs[2])
                 if (contained_type EQ '<NULLOBJ>') then begin
                   contained_type=''
                   if (container_count NE 0) then begin
                      message,'Read error: IDL_CONTAINER with non-zero count of <NULLOBJ> contained objects'
                   endif
                 endif
                 if (observed_class NE 'IDL_CONTAINER') then begin
                    message,'Read error: Multiple tokens on RHS, but class name not IDL_CONTAINER'
                 endif
              end
        else: begin
                message,'Read error: Wrong number of RHS fields for scalar object'
              end
          
        endcase
        ; Special case #1: expected_class is IDL_CONTAINER
        if (expected_class EQ 'IDL_CONTAINER') then begin
           if (observed_class EQ '') then begin
              ; Make an empty container
              self.(tag_index) = obj_new('IDL_CONTAINER')
           endif else if (observed_class EQ 'IDL_CONTAINER') then begin
              ; Build the collection
              self.(tag_index) = obj_new('IDL_CONTAINER')
              for i=0,container_count-1 do begin
                 foo=obj_new(contained_type)
                 if ~obj_valid(foo) then begin
                    message,'Read error: constructor for '+contained_type+' returned an invalid object.'
                 endif
                 foo->read,lun
                 self.(tag_index)->Add,foo
              endfor
           endif else begin
              message,'Read error: expected IDL_CONTAINER, saw '+observed_class
           endelse
        ; Special case #2: observed_class is IDL_CONTAINER
        endif else if (observed_class EQ 'IDL_CONTAINER') then begin
           if (expected_class EQ '') then begin
              ; Build the collection
              self.(tag_index) = obj_new('IDL_CONTAINER')
              for i=0,container_count-1 do begin
                 foo=obj_new(contained_type)
                 if ~obj_valid(foo) then begin
                    message,'Read error: constructor for '+contained_type+' returned an invalid object.'
                 endif
                 foo->read,lun
                 self.(tag_index)->Add,foo
              endfor
           endif else begin
              ; Special case #1 covers IDL_CONTAINER, and the expected
              ; class is not '', so it must be a mismatch
              message,'Read error: mismatch, expected class '+expected_class+', observed '+observed_class
           endelse
        ; Special case #3: observed class is '', make a null object
        endif else if (observed_class EQ '') then begin
           self.(tag_index) = obj_new()
        ; Special case #4: expected class is '', observed class non-null
        endif else if (expected_class EQ '') then begin
           self.(tag_index) = obj_new(observed_class)
           if ~obj_valid(self.(tag_index)) then begin
                message,'Read error: constructor for '+observed_class+' returned an invalid object.'
           endif
           self.(tag_index)->read,lun
        ; General case: observed type and expected type are known, and
        ; neither one is an IDL_CONTAINER (handled by cases #1 and #2)

        ; Get object type from RHS, ensure that it matches field type
        endif else if ~strcmp(expected_class,observed_class) then begin
           message,'Read error: expected '+expected_class+', observed '+observed_class
        endif else begin
           ;
           ; General case: SPD_UI class with a read method and no-argument
           ; constructor
           ;
           self.(tag_index) = obj_new(expected_class)
           if ~obj_valid(self.(tag_index)) then begin
                message,'Read error: constructor for '+observed_class+' returned an invalid object.'
           endif
           self.(tag_index)->read,lun
        endelse
     endif else begin
;
; Scalar primitives
;
        ;dprint, 'Field assignment: '+inputline
        reads,rhs,rhsval,format=format
        self.(tag_index) = rhsval 
     endelse
  endif else begin
     if (field_type EQ 11) then begin
        message,'Read error: arrays of objects not supported'
     endif else begin
;
;   Array of primitives 
;
        ; Look for 'array' and count in RHS
        split_rhs=strsplit(rhs,' ',/extract)
        token_count=n_elements(split_rhs)
        if (token_count NE 2) then begin
           message,'Read error: field type is array, expected 2 tokens on RHS, found '+string(token_count)
        endif else if ~strcmp('array',split_rhs[0],/fold_case) then begin
           message,'Read error: field type is array, first RHS token not array'
        endif else begin
           arraycount=0
           reads,split_rhs[1],arraycount
           if (arraycount LE 0) then begin
              message,'Read error: invalid array count '+string(arraycount)
           endif else begin
              for i=0,arraycount-1 do begin
                 readf,lun,inputline
                 inputline=strtrim(inputline,2)
                 reads,inputline,rhsval,format=format
                 self.(tag_index)[i] = rhsval
              endfor
           endelse
        endelse
     endelse
  endelse


  readf,lun,inputline
  inputline=strtrim(inputline,2)
endwhile

; Closing tag seen: we're done!

end

PRO SPD_UI_READWRITE__DEFINE

   struct = { SPD_UI_READWRITE, __dummy:0 }

END

