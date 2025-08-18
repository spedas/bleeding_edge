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
;   https://cdaweb.gsfc.nasa.gov/WebServices/NASA_Open_Source_Agreement_1.3.txt.
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
; Copyright (c) 2010-2017 United States Government as represented by the 
; National Aeronautics and Space Administration. No copyright is claimed 
; in the United States under Title 17, U.S.Code. All Other Rights Reserved.
;
;


;+
; This class is an IDL representation of the DataRequest element from the
; <a href="https://cdaweb.gsfc.nasa.gov/">Coordinated Data Analysis System</a>
; (CDAS) XML schema.
;
; @copyright Copyright (c) 2010-2017 United States Government as represented
;     by the National Aeronautics and Space Administration. No
;     copyright is claimed in the United States under Title 17,
;     U.S.Code. All Other Rights Reserved.
;
; @author B. Harris
;-


;+
; Creates an SpdfCdasDataRequest object.
;
; @param dataRequestEntity {in} {type=SpdfCdasDataRequestEntity}
;            a data request.
; @returns reference to an SpdfCdasDataRequest object.
;-
function SpdfCdasDataRequest::init, $
    dataRequestEntity
    compile_opt idl2

    self.dataRequestEntity = ptr_new(dataRequestEntity)
    return, self
end


;+
; Performs cleanup operations when this object is destroyed.
;-
pro SpdfCdasDataRequest::cleanup
    compile_opt idl2

    if ptr_valid(self.dataRequestEntity) then ptr_free, self.dataRequestEntity
end


;+
; Gets the data-request entity.
;
; @returns reference to dataRequestEntity
;-
function SpdfCdasDataRequest::getDataRequestEntity
    compile_opt idl2

    return, *self.dataRequestEntity
end


;+
; Creates a DataRequest element using the given XML DOM document with the
; values of this object.
;
; @param doc {in} {type=IDLffXMLDOMDocument}
;            document in which to create the DataRequest element.
; @returns a reference to a new IDLffXMLDOMElement representation of
;     this object.
;-
function SpdfCdasDataRequest::createDomElement, $
    doc
    compile_opt idl2

    dataRequestElement = doc->createElement('DataRequest')
    dataRequestElement->setAttribute, 'xmlns', $
        'http://cdaweb.gsfc.nasa.gov/schema'

    requestEntityElement = (*self.dataRequestEntity)->createDomElement(doc)
    ovoid = dataRequestElement->appendChild(requestEntityElement)

    return, dataRequestElement
end


;+
; Defines the SpdfCdasDataRequest class.
;
; @field dataRequestEntity data-requent entity.
;-
pro SpdfCdasDataRequest__define
    compile_opt idl2
    struct = { SpdfCdasDataRequest, $
        dataRequestEntity:ptr_new() $
    }
end
