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
; Copyright (c) 2010-2018 United States Government as represented by the 
; National Aeronautics and Space Administration. No copyright is claimed 
; in the United States under Title 17, U.S.Code. All Other Rights Reserved.
;
;



;+
; This class is an IDL representation of the TextRequest element from 
; the
; <a href="https://cdaweb.gsfc.nasa.gov/">Coordinated Data Analysis System</a>
; (CDAS) XML schema.
;
; @copyright Copyright (c) 2010-2018 United States Government as represented
;     by the National Aeronautics and Space Administration. No
;     copyright is claimed in the United States under Title 17,
;     U.S.Code. All Other Rights Reserved.
;
; @author B. Harris
;-


;+
; Creates an SpdfTextRequest object.
;
; @param timeInterval {in} {type=SpdfTimeIntervals}
;            time interval of the data to include in result.
; @param datasetRequest {in} {type=SpdfDatasetRequest}
;            specifies the dataset information.
; @keyword compression {in} {optional} {type=strarr} 
;            compression algorithms to apply to result file.
; @keyword format {in} {optional} {type=string} {default='Plain'}
;            format of result file.  Valid values are: Plain, CSV.
; @keyword binData {in} {optional} {type=SpdfBinData} 
;            data binning parameters to apply to result file.
; @returns reference to an SpdfTextRequest object.
;-
function SpdfTextRequest::init, $
    timeInterval, datasetRequest, $
    compression = compression, $
    format = format, $
    binData = binData
    compile_opt idl2

    self.timeInterval = ptr_new(timeInterval)
    self.datasetRequest = ptr_new(datasetRequest)

    if keyword_set(compression) then begin
        self.compression = ptr_new(compression)
    end

    if keyword_set(format) then begin
        if format eq 'Plain' || format eq 'CSV' then begin
            self.format = format
        end
    end

    if keyword_set(binData) then begin
        self.binData = ptr_new(binData)
    end

    return, self
end


;+
; Performs cleanup operations when this object is destroyed.
;-
pro SpdfTextRequest::cleanup
    compile_opt idl2

    if ptr_valid(self.timeInterval) then ptr_free, self.timeInterval
    if ptr_valid(self.datasetRequest) then ptr_free, self.datasetRequest
    if ptr_valid(self.compression) then ptr_free, self.compression
    if ptr_valid(self.binData) then ptr_free, self.binData
end


;+
; Gets the time interval of this request.
;
; @returns request's time interval.
;-
function SpdfTextRequest::getTimeInterval
    compile_opt idl2

    return, *self.timeInterval
end


;+
; Gets the dataset information.
;
; @returns dataset specification.
;-
function SpdfTextRequest::getDatasetRequest
    compile_opt idl2

    return, *self.datasetRequest
end


;+
; Gets the compression options.
;
; @returns compression options.
;-
function SpdfTextRequest::getCompression
    compile_opt idl2

    return, *self.compression
end


;+
; Gets the format option.
;
; @returns format option.
;-
function SpdfTextRequest::getFormat
    compile_opt idl2

    return, self.format
end


;+
; Gets the binData parameters.
;
; @returns binData parameters.
;-
function SpdfTextRequest::getBinData
    compile_opt idl2

    return, *self.binData
end


;+
; Creates a TextRequest element using the given XML DOM document with 
; the values of this object.
;
; @param doc {in} {type=IDLffXMLDOMDocument}
;            document in which to create the TextRequest element.
; @returns a reference to a new IDLffXMLDOMElement representation of
;     this object.
;-
function SpdfTextRequest::createDomElement, $
    doc
    compile_opt idl2

    textRequestElement = doc->createElement('TextRequest')

    timeIntervalElement = (*self.timeInterval)->createDomElement(doc)
    ovoid = textRequestElement->appendChild(timeIntervalElement)

    datasetRequestElement = (*self.datasetRequest)->createDomElement(doc)
    ovoid = textRequestElement->appendChild(datasetRequestElement)

    if ptr_valid(self.compression) then begin

        for i = 0, n_elements(*self.compression) - 1 do begin
    
            compressionElement = doc->createElement('Compression')
            ovoid = textRequestElement->appendChild(compressionElement)
            compressionText = doc->createTextNode((*self.compression)[i])
            ovoid = compressionElement->appendChild(compressionText)
        endfor
    end

    if strlen(self.format) gt 0 then begin

        formatElement = doc->createElement('Format')
        ovoid = textRequestElement->appendChild(formatElement)
        formatText = doc->createTextNode(self.format)
        ovoid = formatElement->appendChild(formatText)
    end

    if ptr_valid(self.binData) then begin

        binDataElement = (*self.binData)->createDomElement(doc)
        ovoid = textRequestElement->appendChild(binDataElement)
    end

    return, textRequestElement
end


;+
; Defines the SpdfTextRequest class.
;
; @field timeInterval time interval of request.
; @field datasetRequest dataset specification.
; @field compression compression options of result.
; @field format format of result.
; @field binData data binning parameters.
;-
pro SpdfTextRequest__define
    compile_opt idl2
    struct = { SpdfTextRequest, $
        timeInterval:ptr_new(), $
        datasetRequest:ptr_new(), $
        compression:ptr_new(), $
        format:'', $
        binData:ptr_new() $
    }
end
