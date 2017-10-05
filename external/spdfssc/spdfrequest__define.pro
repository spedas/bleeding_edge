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
; This class is an IDL representation of the Request element from the
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
; Creates an SpdfRequest object.
;
; @param timeInterval {in} {type=SpdfTimeInterval}
;            time interval of this request.
; @keyword description {in} {optional} {type=string}
;            a textual description of this request.
; @keyword bFieldModel {in} {optional} {type=SpdfBFieldModel}
;            magnetic field model to use.  If not given, the 
;            Tsyganenko 89c model is used.
; @returns reference to an SpdfRequest object.
;-
function SpdfRequest::init, $
    timeInterval, $
    description = description, $
    bFieldModel = bFieldModel
    compile_opt idl2

    if obj_valid(timeInterval) then begin

        self.timeInterval = timeInterval
    endif else begin

        return, 0
    endelse

    if keyword_set(description) then self.description = description

    if keyword_set(bFieldModel) then begin

        self.bFieldModel = bFieldModel
    endif

    return, self
end


;+
; Performs cleanup operations when this object is destroyed.
;-
pro SpdfRequest::cleanup
    compile_opt idl2

    if obj_valid(self.timeInterval) then obj_destroy, self.timeInterval
    if obj_valid(self.bFieldModel) then obj_destroy, self.bFieldModel
end


;+
; Gets the description value.
;
; @returns description value.
;-
function SpdfRequest::getDescription
    compile_opt idl2

    return, self.description
end


;+
; Gets the timeInterval value.
;
; @returns reference to timeInterval
;-
function SpdfRequest::getTimeInterval
    compile_opt idl2

    return, self.timeInterval
end


;+
; Gets the bFieldModel value.
;
; @returns reference to bFieldModel
;-
function SpdfRequest::getBFieldModel
    compile_opt idl2

    return, self.bFieldModel
end


;+
; Creates a Request element using the given XML DOM document with the
; values of this object.
;
; @param doc {in} {type=IDLffXMLDOMDocument}
;            document in which to create the Request element.
; @param subClassName {in} {type=string}
;            name of sub-class.
; @returns a reference to a new IDLffXMLDOMElement representation of
;     this object.
;-
function SpdfRequest::createDomElement, $
    doc, $
    subClassName
    compile_opt idl2

    requestElement = doc->createElement(subClassName)
    requestElement->setAttribute, 'xmlns', $
        'http://sscweb.gsfc.nasa.gov/schema'

    if self.description ne '' then begin

        descriptionElement = doc->createElement('Description')
        ovoid = requestElement->appendChild(descriptionElement)
        descriptionText = doc->createTextNode(self.description)
        descriptionText = $
            descriptionElement->appendChild(descriptionText)
    endif

    timeIntervalElement = self.timeInterval->createDomElement(doc)
    ovoid = requestElement->appendChild(timeIntervalElement)

    if obj_valid(self.bFieldModel) then begin

        bFieldModelElement = self.bFieldModel->createDomElement(doc)
        ovoid = requestElement->appendChild(bFieldModelElement)
    endif

    return, requestElement
end


;+
; Defines the SpdfRequest class.
;
; @field description a textual description of this request.
; @field timeInterval time interval of query.
; @field bFieldModel magnetic field model to use.
;-
pro SpdfRequest__define
    compile_opt idl2
    struct = { SpdfRequest, $
        description:'', $
        timeInterval:obj_new(), $
        bFieldModel:obj_new() $
    }
end
