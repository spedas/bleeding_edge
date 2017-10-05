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
; This class is an IDL representation of the CdfRequest element from the
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
; Creates an SpdfCdfRequest object.
;
; @param timeIntervals {in} {type=objarr of SpdfTimeIntervals}
;            time intervals that the requested CDF is to contain data 
;            for.
; @param datasetRequest {in} {type=SpdfDatasetRequest}
;            specifies the dataset information.  Note that if the first
;            (only) variableName is "ALL-VARIABLES", the resulting CDF
;            will contain all variables.
; @keyword cdfVersion {in} {type=int} {default=3}
;            version of CDF file.
; @keyword cdfFormat {in} {type=string} {default=Binary}
;            format of CDF file.
; @returns reference to an SpdfCdfRequest object.
;-
function SpdfCdfRequest::init, $
    timeIntervals, datasetRequest, $
    cdfVersion = cdfVersion, cdfFormat = cdfFormat
    compile_opt idl2

    self.timeIntervals = ptr_new(timeIntervals)
    self.datasetRequest = ptr_new(datasetRequest)
    self.cdfVersion = 3
    self.cdfFormat = 'Binary'

    if keyword_set(cdfVersion) then begin
        self.cdfVersion = cdfVersion
    end

    if keyword_set(cdfFormat) then begin
        self.cdfFormat = cdfFormat
    end

    return, self
end


;+
; Performs cleanup operations when this object is destroyed.
;-
pro SpdfCdfRequest::cleanup
    compile_opt idl2

    if ptr_valid(self.timeIntervals) then ptr_free, self.timeIntervals
    if ptr_valid(self.datasetRequest) then ptr_free, self.datasetRequest
end


;+
; Gets the time intervals.
;
; @returns reference to objarr of time intervals.
;-
function SpdfCdfRequest::getTimeIntervals
    compile_opt idl2

    return, *self.timeIntervals
end


;+
; Gets the dataset request.
;
; @returns reference to dataset request.
;-
function SpdfCdfRequest::getDatasetRequest
    compile_opt idl2

    return, *self.datasetRequest
end


;+
; Gets the CDF version.
;
; @returns CDF version.
;-
function SpdfCdfRequest::getCdfVersion
    compile_opt idl2

    return, self.cdfVersion
end


;+
; Gets the CDF format.
;
; @returns CDF format.
;-
function SpdfCdfRequest::getCdfFormat
    compile_opt idl2

    return, self.cdfFormat
end


;+
; Creates a CdfRequest element using the given XML DOM document with the
; values of this object.
;
; @param doc {in} {type=IDLffXMLDOMDocument}
;            document in which to create the CdfRequest element.
; @returns a reference to a new IDLffXMLDOMElement representation of
;     this object.
;-
function SpdfCdfRequest::createDomElement, $
    doc
    compile_opt idl2

    cdfRequestElement = doc->createElement('CdfRequest')

    for i = 0, n_elements(*self.timeIntervals) - 1 do begin

        timeIntervalElement = (*self.timeIntervals)[i]->createDomElement(doc)
        ovoid = cdfRequestElement->appendChild(timeIntervalElement)
    endfor

    datasetRequestElement = (*self.datasetRequest)->createDomElement(doc)
    ovoid = cdfRequestElement->appendChild(datasetRequestElement)

    cdfVersionElement = doc->createElement('CdfVersion')
    ovoid = cdfRequestElement->appendChild(cdfVersionElement)
    cdfVersionText = $
        doc->createTextNode(string(self.cdfVersion, format='(%"%d")'))
    cdfVersionText = cdfVersionElement->appendChild(cdfVersionText)

    cdfFormatElement = doc->createElement('CdfFormat')
    ovoid = cdfRequestElement->appendChild(cdfFormatElement)
    cdfFormatText = doc->createTextNode(self.cdfFormat)
    cdfFormatText = cdfFormatElement->appendChild(cdfFormatText)

    return, cdfRequestElement
end


;+
; Defines the SpdfCdfRequest class.
;
; @field timeIntervals time intervals of this request.
; @field datasetRequest identifies the dataset for this request.
; @field cdfFormat indicates the desired format of the CDF file.
; @field cdfVersion indicates the desired version of the CDF file.
;-
pro SpdfCdfRequest__define
    compile_opt idl2
    struct = { SpdfCdfRequest, $
        timeIntervals:ptr_new(), $
        datasetRequest:ptr_new(), $
        cdfVersion:3S, $
        cdfFormat:'Binary' $
    }
end
