;
; NOSA HEADER START
;
; The contents of this file are subject to the terms of the NASA Open 
; Source Agreement (NOSA), Version 1.3 only (the "Agreement").  You may 
; not use this file except in compliance with the Agreement.
;
; You can obtain a copy of the agreement at
;   docs/NASA_Open_Source_Agreement_1.3.txt
; or 
;   http://sscweb.gsfc.nasa.gov/WebServices/NASA_Open_Source_Agreement_1.3.txt.
;
; See the Agreement for the specific language governing permissions
; and limitations under the Agreement.
;
; When distributing Covered Code, include this NOSA HEADER in each
; file and include the Agreement file at 
; docs/NASA_Open_Source_Agreement_1.3.txt.  If applicable, add the 
; following below this NOSA HEADER, with the fields enclosed by 
; brackets "[]" replaced with your own identifying information: 
; Portions Copyright [yyyy] [name of copyright owner]
;
; NOSA HEADER END
;
; Copyright (c) 2013 United States Government as represented by the 
; National Aeronautics and Space Administration. No copyright is claimed 
; in the United States under Title 17, U.S.Code. All Other Rights Reserved.
;
;



;+
; This class is an IDL representation of the DistanceFromOptions
; element from the
; <a href="http://sscweb.gsfc.nasa.gov/">Satellite Situation Center</a>
; (SSC) XML schema.
;
; @copyright Copyright (c) 2013 United States Government as represented
;     by the National Aeronautics and Space Administration. No
;     copyright is claimed in the United States under Title 17,
;     U.S.Code. All Other Rights Reserved.
;
; @author B. Harris
;-


;+
; Creates an SpdfDistanceFromOptions object.
;
; @keyword neutralSheet {in} {optional} {type=boolean} {default=false}
;              specifies whether the distance from the neutral sheet
;              is to be included in the output.
; @keyword bowShock {in} {optional} {type=boolean} {default=false}
;              specifies whether the distance from the bow shock is 
;              to be included in the output.
; @keyword mPause {in} {optional} {type=boolean} {default=false}
;              specifies whether the distance from the magneto pause
;              is to be included in the output.
; @keyword bGseXYZ {in} {optional} {type=boolean} {default=false}
;              specifies whether the B GSE X, Y, Z values is to be
;              included in the output.
; @returns reference to an SpdfDistanceFromOptions object.
;-
function SpdfDistanceFromOptions::init, $
    neutralSheet = neutralSheet, $
    bowShock = bowShock, $
    mPause = mPause, $
    bGseXYZ = bGseXYZ
    compile_opt idl2

    if keyword_set(neutralSheet) then begin

        self.neutralSheet = neutralSheet
    endif else begin

        self.neutralSheet = 0b
    endelse

    if keyword_set(bowShock) then begin

        self.bowShock = bowShock
    endif else begin

        self.bowShock = 0b
    endelse

    if keyword_set(mPause) then begin

        self.mPause = mPause
    endif else begin

        self.mPause = 0b
    endelse

    if keyword_set(bGseXYZ) then begin

        self.bGseXYZ = bGseXYZ
    endif else begin

        self.bGseXYZ = 0b
    endelse

    return, self
end


;+
; Performs cleanup operations when this object is destroyed.
;-
pro SpdfDistanceFromOptions::cleanup
    compile_opt idl2

end


;+
; Gets the distance from the neutral sheet value.
;
; @returns distance from the neutral sheet value.
;-
function SpdfDistanceFromOptions::getNeutralSheet
    compile_opt idl2

    return, self.neutralSheet
end


;+
; Gets the distance from the bow shock value.
;
; @returns distance from the bow shock value.
;-
function SpdfDistanceFromOptions::getBowShock
    compile_opt idl2

    return, self.bowShock
end


;+
; Gets the distance from the magneto pause value.
;
; @returns distance from the magneto pause value.
;-
function SpdfDistanceFromOptions::getMPause
    compile_opt idl2

    return, self.mPause
end


;+
; Gets the bGseXYZ value.
;
; @returns bGseXYZ value.
;-
function SpdfDistanceFromOptions::getBGseXYZ
    compile_opt idl2

    return, self.bGseXYZ
end


;+
; Creates an DistanceFromOptions element using the given XML DOM 
; document with the values of this object.
;
; @param doc {in} {type=IDLffXMLDOMDocument}
;            document in which to create the DataRequest element.
; @returns a reference to a new IDLffXMLDOMElement representation of
;     this object.
;-
function SpdfDistanceFromOptions::createDomElement, $
    doc
    compile_opt idl2

    distanceFromOptionsElement = $
        doc->createElement('DistanceFromOptions')

    neutralSheetElement = doc->createElement('NeutralSheet')
    ovoid = distanceFromOptionsElement->appendChild(neutralSheetElement)
    if self.neutralSheet eq 1b then begin

        neutralSheetText = 'true'
    endif else begin

        neutralSheetText = 'false'
    endelse
    neutralSheetNode = doc->createTextNode(neutralSheetText)
    ovoid = neutralSheetElement->appendChild(neutralSheetNode)

    bowShockElement = doc->createElement('BowShock')
    ovoid = distanceFromOptionsElement->appendChild(bowShockElement)
    if self.bowShock eq 1b then begin

        bowShockText = 'true'
    endif else begin

        bowShockText = 'false'
    endelse
    bowShockNode = doc->createTextNode(bowShockText)
    ovoid = bowShockElement->appendChild(bowShockNode)

    mPauseElement = doc->createElement('MPause')
    ovoid = distanceFromOptionsElement->appendChild(mPauseElement)
    if self.mPause eq 1b then begin

        mPauseText = 'true'
    endif else begin

        mPauseText = 'false'
    endelse
    mPauseNode = doc->createTextNode(mPauseText)
    ovoid = mPauseElement->appendChild(mPauseNode)

    bGseXYZElement = doc->createElement('BGseXYZ')
    ovoid = distanceFromOptionsElement->appendChild(bGseXYZElement)
    if self.bGseXYZ eq 1b then begin

        bGseXYZText = 'true'
    endif else begin

        bGseXYZText = 'false'
    endelse
    bGseXYZNode = doc->createTextNode(bGseXYZText)
    ovoid = bGseXYZElement->appendChild(bGseXYZNode)

    return, distanceFromOptionsElement
end


;+
; Defines the SpdfDistanceFromOptions class.
;
; @field neutralSheet specifies whether the distance from the neutral
;            sheet is to be included in the output.
; @field bowShock specifies whether the distance from the bow shock
;            is to be included in the output.
; @field mPause specifies whether the distance from the magneto pause
;            is to be included in the output.
; @field bGseXYZ specifies whether the B GSE X, Y, Z values are
;            to be included in the output.
;-
pro SpdfDistanceFromOptions__define
    compile_opt idl2
    struct = { SpdfDistanceFromOptions, $

        neutralSheet:0b, $
        bowShock:0b, $
        mPause:0b, $
        bGseXYZ:0b $
    }
end
