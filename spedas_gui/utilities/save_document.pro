
;+
;PRO:
;  save_document
;
;PURPOSE:
;
; saves a spedas document
;
;Inputs:
;  windowstorage: windowstorage object storing the draw tree to be save
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
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas_gui/utilities/save_document.pro $
;-
pro save_document,windowstorage=windowstorage,filename=filename,statuscode=statuscode,statusmsg=statusmsg

catch,Error_status

if (Error_status NE 0) then begin
   statusmsg = !ERROR_STATE.MSG
   statuscode = -3
   catch,/cancel
   return
endif

spd_ui_validate_file,filename=filename,statusmsg=statusmsg,statuscode=statuscode,/write

if statuscode lt 0 then return

; Make document object, initialized from windowstorage object

document_to_save=obj_new('SPD_UI_DOCUMENT',windowstorage)

xml_document=obj_new('IDLffXMLDOMDocument')
root_element=xml_document->CreateElement('body')
document_to_save->AppendXMLNewline,root_element
result = xml_document->AppendChild(root_element)
document_to_save->AppendXMLNewline,root_element

element = document_to_save->GetDOMElement(root_element)
document_to_save->AppendXMLNewline,root_element
result = root_element->AppendChild(element)
document_to_save->AppendXMLNewline,root_element
xml_document->Save,filename=filename


obj_destroy, xml_document
obj_destroy, document_to_save
statuscode=0
statusmsg=STRING(filename,format='("Document successfully saved to ",A)')
return
end
