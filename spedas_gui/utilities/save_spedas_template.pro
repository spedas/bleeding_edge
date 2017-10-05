
;+
;PRO:
;  save_spedas_template
;
;PURPOSE:
;
; saves a spedas template
;
;Inputs:
;  template:the template object to be saved
;  filename:name of the file
;  
;Outputs:
;  statuscode: negative value indicates failure, 0 indicates success
;  statusmsg: a message to be returned in the event of an error
;
;
;$LastChangedBy: jimm $
;$LastChangedDate: 2014-02-11 10:54:32 -0800 (Tue, 11 Feb 2014) $
;$LastChangedRevision: 14326 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas_gui/utilities/save_spedas_template.pro $
;-
pro save_spedas_template,template=template,filename=filename,statuscode=statuscode,statusmsg=statusmsg

catch,Error_status

if (Error_status NE 0) then begin
   statusmsg = !ERROR_STATE.MSG
   statuscode = -3
   catch,/cancel
   return
endif

spd_ui_validate_file,filename=filename,statusmsg=statusmsg,statuscode=statuscode,/write

if statuscode lt 0 then return

xml_document=obj_new('IDLffXMLDOMDocument')
root_element=xml_document->CreateElement('body')
template->AppendXMLNewline,root_element
result = xml_document->AppendChild(root_element)
template->AppendXMLNewline,root_element

element = template->GetDOMElement(root_element)
template->AppendXMLNewline,root_element
result = root_element->AppendChild(element)
template->AppendXMLNewline,root_element
xml_document->Save,filename=filename

obj_destroy, xml_document
statuscode=0
statusmsg=STRING(filename,format='("SPEDAS template successfully saved to ",A)')
return

end
