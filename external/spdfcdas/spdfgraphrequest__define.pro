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
; This class is an IDL representation of the GraphRequest element from 
; the
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
; Creates an SpdfGraphRequest object.
;
; @param timeInterval {in} {type=SpdfTimeInterval}
;            time interval that the requested graph is to contain data
;            for.
; @param datasetRequests {in} {type=objarr of SpdfDatasetRequests}
;            specifies the dataset information.
; @keyword graphOptions {in} {type=int} {default=0}
;            graph option bit-mask value.
; @keyword imageFormats {in} {type=strarr} {default=PNG}
;            format of graph file.
; @returns reference to an SpdfGraphRequest object.
;-
function SpdfGraphRequest::init, $
    timeInterval, datasetRequests, $
    graphOptions = graphOptions, imageFormats = imageFormats
    compile_opt idl2

    self.timeInterval = ptr_new(timeInterval)
    self.datasetRequests = ptr_new(datasetRequests)

    if keyword_set(graphOptions) then begin
        self.graphOptions = ptr_new(graphOptions)
    end

    if keyword_set(imageFormats) then begin
        self.imageFormats = ptr_new(imageFormats)
    end

    return, self
end


;+
; Performs cleanup operations when this object is destroyed.
;-
pro SpdfGraphRequest::cleanup
    compile_opt idl2

    if ptr_valid(self.timeInterval) then ptr_free, self.timeInterval
    if ptr_valid(self.datasetRequests) then ptr_free, self.datasetRequests
    if ptr_valid(self.graphOptions) then ptr_free, self.graphOptions
    if ptr_valid(self.imageFormats) then ptr_free, self.imageFormats
end


;+
; Gets the time interval of this request.
;
; @returns time interval of this request.
;-
function SpdfGraphRequest::getTimeInterval
    compile_opt idl2

    return, *self.timeInterval
end


;+
; Gets the dataset information of this request.
;
; @returns reference to objarr of SpdfDatasetRequest's.
;-
function SpdfGraphRequest::getDatasetRequests
    compile_opt idl2

    return, *self.datasetRequests
end


;+
; Gets the graph options of this request.
;
; @returns graph options of this request.
;-
function SpdfGraphRequest::getGraphOptions
    compile_opt idl2

    return, *self.graphOptions
end


;+
; Gets the image formats of this request.
;
; @returns reference to strarr of image formats.
;-
function SpdfGraphRequest::getImageFormats
    compile_opt idl2

    return, *self.imageFormats
end


;+
; Creates a GraphRequest element using the given XML DOM document with 
; the values of this object.
;
; @param doc {in} {type=IDLffXMLDOMDocument}
;            document in which to create the GraphRequest element.
; @returns a reference to a new IDLffXMLDOMElement representation of
;     this object.
;-
function SpdfGraphRequest::createDomElement, $
    doc
    compile_opt idl2

    graphRequestElement = doc->createElement('GraphRequest')

    timeIntervalElement = (*self.timeInterval)->createDomElement(doc)
    ovoid = graphRequestElement->appendChild(timeIntervalElement)

    for i = 0, n_elements(*self.datasetRequests) - 1 do begin

        datasetRequestElement = $
            (*self.datasetRequests)[i]->createDomElement(doc)
        ovoid = graphRequestElement->appendChild(datasetRequestElement)
    endfor

    if ptr_valid(self.graphOptions) then begin

        for i = 0, n_elements(*self.graphOptions) - 1 do begin
    
            graphOptionElement = doc->createElement('GraphOption')
            ovoid = graphRequestElement->appendChild(graphOptionElement)
            graphOptionText = doc->createTextNode((*self.graphOptions)[i])
            ovoid = graphOptionElement->appendChild(graphOptionText)
        endfor
    end

    if ptr_valid(self.imageFormats) then begin

        for i = 0, n_elements(*self.imageFormats) - 1 do begin
    
            imageFormatElement = doc->createElement('ImageFormat')
            ovoid = graphRequestElement->appendChild(imageFormatElement)
            imageFormatText = doc->createTextNode((*self.imageFormats)[i])
            ovoid = imageFormatElement->appendChild(imageFormatText)
        endfor
    end

    return, graphRequestElement
end


;+
; Defines the SpdfGraphRequest class.
;
; @field timeInterval time interval of this request.
; @field datasetRequests identifies the datasets for this request.
; @field graphOptions graph options for this request.
; @field imageFormats format options for this request.
;-
pro SpdfGraphRequest__define
    compile_opt idl2
    struct = { SpdfGraphRequest, $
        timeInterval:ptr_new(), $
        datasetRequests:ptr_new(), $
        graphOptions:ptr_new(), $
        imageFormats:ptr_new() $
    }
end
