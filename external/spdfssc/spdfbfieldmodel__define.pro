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
; This class is an IDL representation of the BFieldModel
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
; Creates an SpdfBFieldModel object.
;
; @keyword internalBFieldModel {in} {type=string} {default="IGRF-10"}
;              internal magnetic field model (valid values: "IGRF-10",
;              "SimpleDipole").
; @keyword externalBFieldModel {in} {type=SpdfExternalBFieldModel}
;              {default=SpdfTsyganenko89c}
;              external magnetic field model.
; @keyword traceStopAltitude {in} {optional} {type=int} {default=100}
;              stop altitude for downward tracing of field.
;
; @returns reference to an SpdfBFieldModel object.
;-
function SpdfBFieldModel::init, $
    internalBFieldModel = internalBFieldModel, $
    externalBFieldModel = externalBFieldModel, $
    traceStopAltitude = traceStopAltitude
    compile_opt idl2

    if keyword_set(internalBFieldModel) then begin

        self.internalBFieldModel = internalBFieldModel
    endif else begin

        self.internalBFieldModel = 'IGRF-10'
    endelse

    if keyword_set(externalBFieldModel) then begin

        self.externalBFieldModel = externalBFieldModel
    endif else begin

        self.externalBFieldModel = obj_new('SpdfTsyganenko89c')
    endelse

    if keyword_set(traceStopAltitude) then begin

        self.traceStopAltitude = traceStopAltitude
    endif else begin

        self.traceStopAltitude = 100
    endelse

    return, self
end


;+
; Performs cleanup operations when this object is destroyed.
;-
pro SpdfBFieldModel::cleanup
    compile_opt idl2

    if obj_valid(self.externalBFieldModel) then begin

        obj_destroy, self.externalBFieldModel
    endif
end


;+
; Gets the internal B field model value.
;
; @returns internal B field model value.
;-
function SpdfBFieldModel::getInternalBFieldModel
    compile_opt idl2

    return, self.internalBFieldModel
end


;+
; Gets the external B field model.
;
; @returns a reference to the external B field model.
;-
function SpdfBFieldModel::getExternalBFieldModel
    compile_opt idl2

    return, self.externalBFieldModel
end


;+
; Gets the trace stop altitude value.
;
; @returns trace stop altitude value.
;-
function SpdfBFieldModel::getTraceStopAltitude
    compile_opt idl2

    return, self.traceStopAltitude
end


;+
; Creates an BFieldModel element using the given XML DOM document 
; with the values of this object.
;
; @param doc {in} {type=IDLffXMLDOMDocument}
;            document in which to create the DataRequest element.
; @returns a reference to a new IDLffXMLDOMElement representation of
;     this object.
;-
function SpdfBFieldModel::createDomElement, $
    doc
    compile_opt idl2

    bFieldModelElement = doc->createElement('BFieldModel')

    internalModelElement = doc->createElement('InternalBFieldModel')
    ovoid = bFieldModelElement->appendChild(internalModelElement)
    internalModelNode = doc->createTextNode(self.internalBFieldModel)
    ovoid = internalModelElement->appendChild(internalModelNode)

    if ptr_valid(self.externalBFieldModel) then begin

        externalModelElement = $
            self.externalBFieldModel->createDomElement(doc)
        ovoid = bFeildModelElement->appendChild(externalModelElement)
    endif

    traceStopElement = doc->createElement('TraceStopAltitude')
    ovoid = bFieldModelElement->appendChild(traceStopElement)
    traceStopNode = doc->createTextNode(self.traceStopAltitude)
    ovoid = traceStopElement->appendChild(traceStopNode)

    return, bFieldModelElement
end


;+
; Defines the SpdfBFieldModel class.
;
; @field internalBFieldModel internal B-Field model.
; @field externalBFieldModel external B-Field model.
; @field traceStopAltitude stop altitude for downward tracing of field 
;            lines.
;-
pro SpdfBFieldModel__define
    compile_opt idl2
    struct = { SpdfBFieldModel, $

        internalBFieldModel:'IGRF-10', $
        externalBFieldModel:obj_new(), $
        traceStopAltitude:100 $
    }
end
