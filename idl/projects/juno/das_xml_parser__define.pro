;+
; PROCEDURE:
;         das_xml_parser
;
; PURPOSE:
;         Parses XML from DAS files (metadata is stored in XML)
;
;
;
;
;$LastChangedBy: egrimes $
;$LastChangedDate: 2016-12-05 12:03:15 -0800 (Mon, 05 Dec 2016) $
;$LastChangedRevision: 22436 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/juno/das_xml_parser__define.pro $
;-

function das_xml_parser::getPackets
    compile_opt strictarr
    return, *self.packets
end

function das_xml_parser::getMetadata
    compile_opt strictarr
    return, *self.metadata
end

pro das_xml_parser::startElement, uri, local, name, attname, attvalue
    compile_opt strictarr

    p = *self.metadata
    for i=0, n_elements(attname)-1 do begin
      p[attname[i]] = attvalue[i]
    endfor
    self.metadata = ptr_new(p)
end

pro das_xml_parser::startDocument
    compile_opt strictarr
    
    if (n_elements(*self.packets) gt 0l) then begin
      dummy = temporary(*self.packets)
    endif
end

pro das_xml_parser::cleanup
  compile_opt strictarr
  self->idlffxmlsax::cleanup
  
  ptr_free, self.metadata
  ptr_free, self.packets
end

function das_xml_parser::init, _extra=e
    compile_opt strictarr
    
    if (~self->idlffxmlsax::init(_extra=e)) then return, 0
    
    self.packets = ptr_new(/allocate_heap)
    self.metadata = ptr_new(hash())
    return, 1
end

pro das_xml_parser__define
    compile_opt strictarr
    
    define = {das_xml_parser, inherits IDLffXMLSAX, packets: ptr_new(), metadata: ptr_new()}
end