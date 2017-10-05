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
; This class is an IDL representation of the SatelliteSpecification 
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
; Creates an SpdfSatelliteSpecification object.
;
; @param id {in} {type=string}
;            satellite identifier.
; @param resolutionFactor {in} {type=int}
;            resolution factor.
; @returns reference to an SpdfSatelliteSpecification object.
;-
function SpdfSatelliteSpecification::init, $
    id, $
    resolutionFactor
    compile_opt idl2

    self.id = id
    self.resolutionFactor = resolutionFactor

    return, self
end


;+
; Performs cleanup operations when this object is destroyed.
;-
pro SpdfSatelliteSpecification::cleanup
    compile_opt idl2

end


;+
; Gets the id value.
;
; @returns id value.
;-
function SpdfSatelliteSpecification::getId
    compile_opt idl2

    return, self.id
end


;+
; Gets the resolutionFactor value.
;
; @returns resolutionFactor value.
;-
function SpdfSatelliteSpecification::getResolutionFactor
    compile_opt idl2

    return, self.resolutionFactor
end


;+
; Creates a SatelliteSpecification element using the given XML DOM 
; document with the values of this object.
;
; @param doc {in} {type=IDLffXMLDOMDocument}
;            document in which to create the SatelliteSpecification 
;            element.
; @returns a reference to a new IDLffXMLDOMElement representation of
;     this object.
;-
function SpdfSatelliteSpecification::createDomElement, $
    doc
    compile_opt idl2

    ssElement = doc->createElement('Satellites')

    idElement = doc->createElement('Id')
    ovoid = ssElement->appendChild(idElement)
    idText = doc->createTextNode(self.id)
    idText = idElement->appendChild(idText)

    resolutionFactorElement = doc->createElement('ResolutionFactor')
    ovoid = ssElement->appendChild(resolutionFactorElement)
    resolutionFactorText = $
        doc->createTextNode( $
            string(self.resolutionFactor, format='(%"%d")'))
    resolutionFactorText = $
        resolutionFactorElement->appendChild(resolutionFactorText)

    return, ssElement
end


;+
; Defines the SpdfSatelliteSpecification class.
;
; @field id satellite identifier.
; @field resolutionFactor resolution factor.
;-
pro SpdfSatelliteSpecification__define
    compile_opt idl2
    struct = { SpdfSatelliteSpecification, $
        id:'', $
        resolutionFactor:2 $
    }
end
