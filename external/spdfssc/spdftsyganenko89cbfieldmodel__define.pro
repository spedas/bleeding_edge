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
; This class is an IDL representation of the Tsyganenko89cBFieldModel
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
; Creates an SpdfTsyganenko89cBFieldModel object.
;
; @keyword keyParameterValues {in} {optional} {type=string} 
;              {default='KP3_3_3'}
;              Model's key parameter values.  Must be one of the 
;              following: KP0_0, KP1_1_1, KP2_2_2, KP3_3_3, KP4_4_4,
;              KP5_5_5, or KP6.
; @returns reference to an SpdfTsyganenko89cBFieldModel object.
;-
function SpdfTsyganenko89cBFieldModel::init, $
    keyParameterValues = keyParameterValues
    compile_opt idl2

    if keyword_set(keyParameterValues) then begin

        self.keyParameterValues = keyParameterValues
    endif else begin

        self.keyParameterValues = 'KP3_3_3'
    endelse

    return, self
end


;+
; Performs cleanup operations when this object is destroyed.
;-
pro SpdfTsyganenko89cBFieldModel::cleanup
    compile_opt idl2

end


;+
; Creates an ExternalBFieldModel element using the given XML DOM 
; document with the values of this object.
;
; @param doc {in} {type=IDLffXMLDOMDocument}
;            document in which to create the DataRequest element.
; @returns a reference to a new IDLffXMLDOMElement representation of
;     this object.
;-
function SpdfTsyganenko89cBFieldModel::createDomElement, $
    doc
    compile_opt idl2

    bFieldModelElement = doc->createElement('ExternalBFieldModel')
    bFieldModelElement->setAttribute, 'xmlns:xsi', $
        'http://www.w3.org/2001/XMLSchema-instance'
    bFieldModelElement->setAttribute, 'xsi:type', $
        'Tsyganenko89cBFieldModel'

    kpElement = doc->createElement('KeyParameterValues')
    ovoid = bFieldModelElement->appendChild(kpElement)
    kpNode = doc->createTextNode(self.keyParameterValues)
    ovoid = kpElement->appendChild(kpNode)

    return, bFieldModelElement
end


;+
; Defines the SpdfTsyganenko89cBFieldModel class.
;
; @field keyParameterValues model's key parameter values.
;-
pro SpdfTsyganenko89cBFieldModel__define
    compile_opt idl2
    struct = { SpdfTsyganenko89cBFieldModel, $

        inherits SpdfExternalBFieldModel, $
        keyParameterValues:'' $
    }
end
