;+
; FUNCTION:
;   iug_parsexml_mddb
;
; PURPOSE:
;   Parses XML file and extract information.
;
; KEYWORDS:
;   filename: filename of the XML file.
;   tag: tag name to extract information. 
;
; EXAMPLE:
;   iug_parsexml_mddb, filename='tmp.xml', tag='ResourceID'
;
; Written by Y.-M. Tanaka, Feb. 13, 2010 (ytanaka at nipr.ac.jp)
;-

function iug_parsexml_mddb, filename=filename, tag=tag

output=''

if ~keyword_set(filename) then begin
    print, 'No input argument: filename.'
    return, output
endif

;----- parse XML and get URL -----;
oDoc = OBJ_NEW('IDLffXMLDOMDocument', filename=filename, $
		schema_checking=0)  ; Create IDLffXMLLOM objects
; oDoc->Load, filename=filename   ; Load XML
; oPlugin = oDoc->GetFirstChild()
; oNodeList = oPlugin->GetElementsByTagname('dc:identifier')

oNodeList = oDoc->GetElementsByTagname(tag)
n = oNodeList->GetLength()

if n gt 0 then begin        
    output=strarr(n)
    for i=0, n-1 do begin
        oName = oNodeList->Item(i)

        if OBJ_VALID(oName) then begin
            oNameText = oName->GetFirstChild()
            output(i)=oNameText->GetNodeValue()
        endif
    endfor
endif

OBJ_DESTROY, oDoc

return, output

end
