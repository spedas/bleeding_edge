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
; This class is an IDL representation of the DatasetRequest element 
; from the
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
; Creates an SpdfDatasetRequest object.
;
; @param datasetId {in} {type=string}
;            dataset identifier.
; @param variableNames {in} {type=strarr}
;            names of variables.
; @returns reference to an SpdfDatasetRequest object.
;-
function SpdfDatasetRequest::init, $
    datasetId, variableNames
    compile_opt idl2

    self.datasetId = datasetId
    self.variableNames = ptr_new(variableNames)

    return, self
end


;+
; Performs cleanup operations when this object is destroyed.
;-
pro SpdfDatasetRequest::cleanup
    compile_opt idl2

    if ptr_valid(self.variableNames) then ptr_free, self.variableNames

end


;+
; Gets the dataset identifier.
;
; @returns dataset identifier.
;-
function SpdfDatasetRequest::getDatasetId
    compile_opt idl2

    return, self.datasetId
end


;+
; Get the variable names.
;
; @returns variable names.
;-
function SpdfDatasetRequest::getVariableNames
    compile_opt idl2

    return, *self.variableNames
end


;+
; Creates a DataRequest element using the given XML DOM document with 
; the values of this object.
;
; @param doc {in} {type=IDLffXMLDOMDocument}
;            document in which to create the DataRequest element.
; @returns a reference to a new IDLffXMLDOMElement representation of
;     this object.
;-
function SpdfDatasetRequest::createDomElement, $
    doc
    compile_opt idl2

    datasetRequestElement = doc->createElement('DatasetRequest')
    datasetIdElement = doc->createElement('DatasetId')
    ovoid = datasetRequestElement->appendChild(datasetIdElement)
    datasetIdText = doc->createTextNode(self.datasetId)
    ovoid = datasetIdElement->appendChild(datasetIdText)

    for i = 0, n_elements(*self.variableNames) - 1 do begin

        variableNameElement = doc->createElement('VariableName')
        ovoid = $
            datasetRequestElement->appendChild(variableNameElement)
        variableNameText = doc->createTextNode((*self.variableNames)[i])
        ovoid = $
            variableNameElement->appendChild(variableNameText)
    endfor

    return, datasetRequestElement
end


;+
; Defines the SpdfDatasetRequest class.
;
; @field datasetId dataset identifier.
; @field variableNames variable names.
;-
pro SpdfDatasetRequest__define
    compile_opt idl2
    struct = { SpdfDatasetRequest, $
        datasetId:'', $
        variableNames:ptr_new() $
    }
end
