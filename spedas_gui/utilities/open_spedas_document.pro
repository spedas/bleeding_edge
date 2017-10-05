
;+
;PRO:
;  open_spedas_document
;
;PURPOSE:
;
; opens a spedas document
;
;Inputs:
;  info: info struct from main gui event handler
;  filename:name of the file
;  nodelete:indicates that preexisting data should not be deleted during read
;  
;Outputs:
;  statuscode: negative value indicates failure, 0 indicates success
;  statusmsg: a message to be returned in the event of an error
;
;
;$LastChangedBy: jimm $
;$LastChangedDate: 2014-02-11 10:54:32 -0800 (Tue, 11 Feb 2014) $
;$LastChangedRevision: 14326 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas_gui/utilities/open_spedas_document.pro $
;-

pro open_spedas_document,info=info,filename=filename,statuscode=statuscode,statusmsg=statusmsg,nodelete=nodelete

catch,Error_status

if (Error_status NE 0) then begin
   statusmsg = !ERROR_STATE.MSG
   statuscode = -3
   catch,/cancel
   return
endif

historywin=info.historywin
statustext=info.statusbar
guiId = info.master

spd_ui_validate_file,filename=filename,statusmsg=statusmsg,statuscode=statuscode

if statuscode lt 0 then return

statustext->Update,'Opening SPEDAS document '+filename
widget_control, /hourglass

; Load XML document from the filename
xmldoc=obj_new('IDLffXMLDOMDocument')
xmldoc->Load,filename=filename

; Create spd_ui_document object to receive XML data, using the
; no-arguments constructor

doc_to_load=obj_new('spd_ui_document')

; Drill down into the DOM tree to get the first non-whitespace child
; of <body> element

body=xmldoc->GetFirstChild() ; should be 'body'
if (body->GetNodeName() NE 'body') then begin
  message,'Expected body node, got '+body->GetNodeName()
endif

sib=body->GetFirstChild()
; Skip any extraneous text elements (newlines, etc)
while (sib->GetNodeName() EQ '#text')  do begin
   sib=sib->GetNextSibling()
endwhile

; sib should be a SPD_UI_DOCUMENT node
if (sib->GetNodeName() NE 'SPD_UI_DOCUMENT') then begin
  message,'Expected SPD_UI_DOCUMENT node, got '+sib->GetNodeName()
endif

doc_to_load->BuildFromDOMElement,sib

; We're done with the XML DOM tree

obj_destroy,xmldoc

; Invoke the onLoad method, passing in the windowstorage, loadedData,
; and windowMenus objects.
; This sets the loadedData element of the newly created
; callSequence object, replays the calls, and adds all the window objects
; to windowStorage while keeping windowMenus updated.

; Reset loadedData object (there may be other objects that hold references
; to the loadedData object, so obj_destroy/obj_new is too drastic).

if ~keyword_set(nodelete) then begin
  info.loadedData->reset
endif

doc_to_load->onLoad, ptr_new(info)

; Update the draw window
spd_ui_orientation_update,info.drawObject,info.windowStorage
info.drawObject->update,info.windowStorage, info.loadedData
info.drawObject->draw

statuscode=0
statusmsg=STRING(filename,format='("SPEDAS document successfully read from ",A)')
return
end
