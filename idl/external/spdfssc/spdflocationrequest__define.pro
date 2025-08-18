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
; This class is an IDL representation of the LocationRequest element 
; from the
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
; Creates an SpdfLocationRequest object.
;
; @param timeInterval {in} {type=SpdfTimeInterval}
;            time interval of this request.
; @param satellites {in} {type=objarr of SpdfSatelliteSpecification}
;            requested satellites.
; @keyword description {in} {optional} {type=string}
;            a textual description of this request.
; @keyword bFieldModel {in} {optional} {type=SpdfBFieldModel}
;            magnetic field model to use.  If not given, the 
;            Tsyganenko 89c model is used.
; @returns reference to an SpdfLocationRequest object.
;-
function SpdfLocationRequest::init, $
    timeInterval, $
    satellites, $
    description = description, $
    bFieldModel = bFieldModel
    compile_opt idl2

    if ~(self->SpdfRequest::init( $
             timeInterval, description = description, $
             bFieldModel = bFieldModel)) then begin

        return, 0
    endif

    self.satellites = ptr_new(satellites)

    return, self
end


;+
; Performs cleanup operations when this object is destroyed.
;-
pro SpdfLocationRequest::cleanup
    compile_opt idl2

    if ptr_valid(self.satellites) then ptr_free, self.satellites
end


;+
; Gets the satellites.
;
; @returns objarr containing satellites or objarr(1) whose first 
;     element is !obj_valid().
;-
function SpdfLocationRequest::getSatellites
    compile_opt idl2

    if ptr_valid(self.satellites) then begin

        return, *self.satellites
    endif else begin

        return, objarr(1)
    endelse
end


;+
; Creates a LocationRequest element using the given XML DOM document 
; with the values of this object.
;
; @param doc {in} {type=IDLffXMLDOMDocument}
;            document in which to create the LocationRequest element.
; @param subClassName {in} {type=string]
;            sub-class name.
; @returns a reference to a new IDLffXMLDOMElement representation of
;     this object.
;-
function SpdfLocationRequest::createDomElement, $
    doc, $
    subClassName
    compile_opt idl2

    requestElement = self->SpdfRequest::createDomElement(doc, subClassName)

    for i = 0, n_elements(*self.satellites) - 1 do begin

        satelliteElement = (*self.satellites)[i]->createDomElement(doc)
        ovoid = requestElement->appendChild(satelliteElement)
    endfor

    return, requestElement
end


;+
; Defines the SpdfLocationRequest class.
;
; @field satellites requested satellites.
;-
pro SpdfLocationRequest__define
    compile_opt idl2
    struct = { SpdfLocationRequest, $
        inherits SpdfRequest, $
        satellites:ptr_new() $
    }
end
