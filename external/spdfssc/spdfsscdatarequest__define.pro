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
; This class is an IDL representation of the DataRequest element 
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
; Creates an SpdfSscDataRequest object.
;
; @param timeInterval {in} {type=SpdfTimeInterval}
;            time interval of this request.
; @param satellites {in} {type=SpdfSatelliteSpecification objarr}
;            requested satellites.
; @param outputOptions {in} {type=SpdfOutputOptions}
;            requested output options.
; @keyword description {in} {optional} {type=string}
;            a textual description of this request.
; @keyword bFieldModel {in} {optional} {type=SpdfBFieldModel}
;            magnetic field model to use.  If not given, a default 
;            model of IGRF-10 and Tsyganenko 89c with KP values of 
;            3-,3,3+ is used. 
; @keyword regionOptions {in} {optional} {type=SpdfRegionOptions}
;            requested region options.
; @keyword locationFilterOptions {in} {optional} 
;            {type=SpdfLocationFilterOptions}
;            requested location filter options.
; @keyword formatOptions {in} {optional} {type=SpdfFormatOptions}
;            requested format options.
; @returns reference to an SpdfSscDataRequest object.
;-
function SpdfSscDataRequest::init, $
    timeInterval, $
    satellites, $
    outputOptions, $
    description = description, $
    bFieldModel = bFieldModel, $
    regionOptions = regionOptions, $
    locationFilterOptions = locationFilterOptions, $
    formatOptions = formatOptions
    compile_opt idl2

    if ~(self->SpdfLocationRequest::init( $
             timeInterval, satellites, $
             description = description, $
             bFieldModel = bFieldModel)) then begin

        return, 0
    endif

    self.outputOptions = outputOptions

    if keyword_set(regionOptions) then begin

        self.regionOptions = ptr_new(regionOptions)
    endif

    if keyword_set(locationFilterOptions) then begin

        self.locationFilterOptions = ptr_new(locationFilterOptions)
    endif

    if keyword_set(formatOptions) then begin
 
        self.formatOptions = ptr_new(formatOptions)
    endif

    return, self
end


;+
; Performs cleanup operations when this object is destroyed.
;-
pro SpdfSscDataRequest::cleanup
    compile_opt idl2

    if ptr_valid(self.satellites) then ptr_free, self.satellites
    if obj_valid(self.outputOptions) then begin

        obj_destroy, self.outputOptions
    endif

    if ptr_valid(self.regionFilterOptions) then begin

        ptr_free, self.regionFilterOptions
    endif
    if ptr_valid(self.locationFilterOptions) then begin

        ptr_free, self.locationFilterOptions
    endif
    if ptr_valid(self.formatOptions) then begin

        ptr_free, self.formatOptions
    endif
end


;+
; Gets the output options.
;
; @returns reference to output options.
;-
function SpdfSscDataRequest::getOutputOptions
    compile_opt idl2

    return, self.outputOptions
end


;+
; Creates a DataRequest element using the given XML DOM document 
; with the values of this object.
;
; @param doc {in} {type=IDLffXMLDOMDocument}
;            document in which to create the DataRequest element.
; @returns a reference to a new IDLffXMLDOMElement representation of
;     this object.
;-
function SpdfSscDataRequest::createDomElement, $
    doc
    compile_opt idl2

    dataRequestElement = $
        self->SpdfLocationRequest::createDomElement(doc, 'DataRequest')

    if obj_valid(self.outputOptions) then begin

        outputOptionsElement = $
            self.outputOptions->createDomElement(doc)

        ovoid = dataRequestElement->appendChild(outputOptionsElement)
    endif

    if ptr_valid(self.regionFilterOptions) then begin

        regionFilterOptionsElement = $
            (*self.regionFilterOptions)->createDomElement(doc)

        ovoid = dataRequestElement->appendChild( $
                    regionFilterOptionsElement)
    endif

    if ptr_valid(self.locationFilterOptions) then begin

        locationFilterOptionsElement = $
            (*self.locationFilterOptions)->createDomElement(doc)

        ovoid = dataRequestElement->appendChild( $
                    locationFilterOptionsElement)
    endif


    if ptr_valid(self.formatOptions) then begin

        formatOptionsElement = $
            (*self.formatOptions)->createDomElement(doc)

        ovoid = dataRequestElement->appendChild(formatOptionsElement)
    endif

    return, dataRequestElement
end


;+
; Defines the SpdfSscDataRequest class.
;
; @field outputOptions request's output options.
; @field regionFilterOptions request's region filter options.
; @field locationFilterOptions request's location filter options.
; @field formatOptions request's format options.
;-
pro SpdfSscDataRequest__define
    compile_opt idl2
    struct = { SpdfSscDataRequest, $
        inherits SpdfLocationRequest, $
        outputOptions:obj_new(), $
        regionFilterOptions:ptr_new(), $
        locationFilterOptions:ptr_new(), $
        formatOptions:ptr_new() $
    }
end
