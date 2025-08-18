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
; This class is an IDL representation of the Tsyganenko96BFieldModel
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
; Creates an SpdfTsyganenko96BFieldModel object.
;
; @keyword solarWindPressure {in} {optional} {type=double}
;              solar wind pressure (range: 0 - 30 nP, default=2.1).
; @keyword dstIndex {in} {optional} {type=int}
;              Disturbance Storm Time (DST) index 
;              (range: -400 - 200 nT, default=-20).
; @keyword byImf {in} {optional} {type=double}
;              BY Interplanetary Magnetic Field (IMF)
;              (range: -100 - 100 nT, default=0.0).
; @keyword bzImf {in} {optional} {type=double}
;              BZ Interplanetary Magnetic Field (IMF)
;              (range: -100 - 100 nT, default=0.0).
; @returns reference to an SpdfTsyganenko96BFieldModel object.
;-
function SpdfTsyganenko96BFieldModel::init, $
    solarWindPressure = solarWindPressure, $
    dstIndex = dstIndex, $
    byImf = byImf, $
    bzImf = bzImf
    compile_opt idl2

    if keyword_set(solarWindPressure) then begin

        self.solarWindPressure = solarWindPressure
    endif else begin

        self.solarWindPressure = 2.1D
    endelse

    if keyword_set(dstIndex) then begin

        self.dstIndex = dstIndex
    endif else begin

        self.dstIndex = -20L
    endelse

    if keyword_set(byImf) then begin

        self.byImf = byImf
    endif else begin

        self.byImf = 0.0D
    endelse

    if keyword_set(bzImf) then begin

        self.bzImf = bzImf
    endif else begin

        self.bzImf = 0.0D
    endelse

    return, self
end


;+
; Performs cleanup operations when this object is destroyed.
;-
pro SpdfTsyganenko96BFieldModel::cleanup
    compile_opt idl2

end


;+
; Get the solar wind pressure value.
;
; @returns the solar wind pressure value.
;-
function SpdfTsyganenko96BFieldModel::getSolarWindPressure
    compile_opt idl2

    return, self.solarWindPressure
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
function SpdfTsyganenko96BFieldModel::createDomElement, $
    doc
    compile_opt idl2

    bFieldModelElement = doc->createElement('ExternalBFieldModel')
    bFieldModelElement->setAttribute, 'xmlns:xsi', $
        'http://www.w3.org/2001/XMLSchema-instance'
    bFieldModelElement->setAttribute, 'xsi:type', $
        'Tsyganenko96BFieldModel'

    swpElement = doc->createElement('SolarWindPressure')
    ovoid = bFieldModelElement->appendChild(swpElement)
    swpNode = doc->createTextNode( $
                  string(self.solarWindPressure, format='(%"%d")'))
    ovoid = swpElement->appendChild(swpNode)

    dstIndexElement = doc->createElement('DstIndex')
    ovoid = bFieldModelElement->appendChild(dstIndexElement)
    dstIndexNode = doc->createTextNode( $
                       string(self.dstIndex, format='(%"%d")'))
    ovoid = dstIndexElement->appendChild(dstIndexNode)

    byImfElement = doc->createElement('ByImf')
    ovoid = bFieldModelElement->appendChild(byImfElement)
    byImfNode = doc->createTextNode( $
                    string(self.byImf, format='(%"%d")'))
    ovoid = byImfElement->appendChild(byImfNode)

    bzImfElement = doc->createElement('BzImf')
    ovoid = bFieldModelElement->appendChild(bzImfElement)
    bzImfNode = doc->createTextNode( $
                    string(self.bzImf, format='(%"%d")'))
    ovoid = bzImfElement->appendChild(bzImfNode)

    return, bFieldModelElement
end


;+
; Defines the SpdfTsyganenko96BFieldModel class.
;
; @field solarWindPressure solar wind pressure 
;            (range: 0 - 30 nP, default=2.1).
; @field dstIndex Disturbance Storm Time (DST) index 
;            (range: -400 - 200 nT, default=-20).
; @field byImf BY Interplanetary Magnetic Field (IMF)
;            (range: -100 - 100 nT, default=0.0).
; @field bzImf BZ Interplanetary Magnetic Field (IMF)
;            (range: -100 - 100 nT, default=0.0).
;-
pro SpdfTsyganenko96BFieldModel__define
    compile_opt idl2
    struct = { SpdfTsyganenko96BFieldModel, $

        inherits SpdfExternalBFieldModel, $
        solarWindPressure:2.1D, $
        dstIndex:-20L, $
        byImf:0.0D, $
        bzImf:0.0D $
    }
end
