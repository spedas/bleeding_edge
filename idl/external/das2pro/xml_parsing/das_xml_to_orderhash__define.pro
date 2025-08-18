;+
; PROCEDURE:
;         das_xml_to_orderhash
;
; PURPOSE:
;         Parses XML from DAS files (metadata is stored in XML)
;
;$LastChangedBy: adrozdov $
;$LastChangedDate: 2019-08-19 13:48:54 -0700 (Mon, 19 Aug 2019) $
;$LastChangedRevision: 27621 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/external/das2pro/xml_parsing/das_xml_to_orderhash__define.pro $
;-

function das_xml_to_orderhash::getHash
; Return ordered hash array after parsing
  compile_opt strictarr
  return, *self.xml
end


pro das_xml_to_orderhash::startElement, uri, local, name, attname, attvalue
  compile_opt strictarr
; Reads xml elements and puts the data into the stack.

    p = ptr_new(orderedhash()) ; hash of the reference (can be replased with data)
    
   
   if n_elements(attname) ne 0 then begin
    h = *p
      for i=0, n_elements(attname)-1 do begin
        h['%' + attname[i]] = attvalue[i] ; attributes has % prefix
        endfor
    p = ptr_new(h)  
    endif
    
    self.stack.add, {name:name, ptr: p}       
 
end

pro das_xml_to_orderhash::endElement, uri, local, name, attname, attvalue
  compile_opt strictarr
; When xml element is closed, take the data from the stack and put it in orderedhash array
  element = self.stack.remove() 
  
  if self.stack.count() eq 0 then begin 
    *self.xml = orderedhash(element.name, *element.ptr)
  endif else begin
    parent = self.stack[self.stack.count() - 1]
    h = *(parent.ptr)     
    
    ; check if it is a list
    if h.hasKey(element.name) then begin
      if ISA(h[element.name], 'LIST') then begin
        h[element.name].add, *(element.ptr)
      endif else begin
        h[element.name] = list(h[element.name], *(element.ptr))                
      endelse
            
    endif else begin    
      h[element.name] = *(element.ptr)
    endelse
    
    parent.ptr = ptr_new(h)    
    self.stack[self.stack.count() - 1] = parent  
  endelse
  
end

pro das_xml_to_orderhash::endDocument
  compile_opt strictarr
; Not in use
end

pro das_xml_to_orderhash::startDocument
  compile_opt strictarr
  *self.xml = orderedhash()
  self.stack = list()
end

pro das_xml_to_orderhash::cleanup
  compile_opt strictarr
  self->idlffxmlsax::cleanup

  ptr_free, self.xml
  self.stack.remove, /all  
end

function das_xml_to_orderhash::init, _extra=e
  compile_opt strictarr

  if (~self->idlffxmlsax::init(_extra=e)) then return, 0

  self.xml = ptr_new(orderedhash())
  self.stack = list()
  return, 1
end

pro das_xml_to_orderhash__define
  compile_opt strictarr

  define = {das_xml_to_orderhash, inherits IDLffXMLSAX, xml: ptr_new(), stack: list()}
end