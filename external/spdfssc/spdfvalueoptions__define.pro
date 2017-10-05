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
; This class is an IDL representation of the ValueOptions
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
; Creates an SpdfValueOptions object.
;
; @keyword radialDistance {in} {optional} {type=boolean} {default=false}
;              specifies whether the radial distance is to be
;              included in the output.
; @keyword bFieldStrength {in} {optional} {type=boolean} {default=false}
;              specifies whether the magnetic field strength is to be
;              included in the output.
; @keyword dipoleLValue {in} {optional} {type=boolean} {default=false}
;              specifies whether the dipole L value is to be included
;              in the output.
; @keyword dipoleInvLat {in} {optional} {type=boolean} {default=false}
;              specifies whether the dipole invariant latitude is to be
;              included in the output.
; @returns reference to an SpdfValueOptions object.
;-
function SpdfValueOptions::init, $
    radialDistance = radialDistance, $
    bFieldStrength = bFieldStrength, $
    dipoleLValue = dipoleLValue, $
    dipoleInvLat = dipoleInvLat
    compile_opt idl2

    if keyword_set(radialDistance) then begin

        self.radialDistance = radialDistance
    endif else begin

        self.radialDistance = 0b
    endelse

    if keyword_set(bFieldStrength) then begin

        self.bFieldStrength = bFieldStrength
    endif else begin

        self.bFieldStrength = 0b
    endelse

    if keyword_set(dipoleLValue) then begin

        self.dipoleLValue = dipoleLValue
    endif else begin

        self.dipoleLValue = 0b
    endelse

    if keyword_set(dipoleInvLat) then begin

        self.dipoleInvLat = dipoleInvLat
    endif else begin

        self.dipoleInvLat = 0b
    endelse

    return, self
end


;+
; Performs cleanup operations when this object is destroyed.
;-
pro SpdfValueOptions::cleanup
    compile_opt idl2

end


;+
; Gets the radialDistance value.
;
; @returns radialDistance value.
;-
function SpdfValueOptions::getRadialDistance
    compile_opt idl2

    return, self.radialDistance
end


;+
; Gets the magnetic field strength value.
;
; @returns magnetic field strength value.
;-
function SpdfValueOptions::getBFieldStrength
    compile_opt idl2

    return, self.bFieldStrength
end


;+
; Gets the dipole L value.
;
; @returns dipole L value.
;-
function SpdfValueOptions::getDipoleLValue
    compile_opt idl2

    return, self.dipoleLValue
end


;+
; Gets the dipole invariant latitude value.
;
; @returns dipole invariant latitude value.
;-
function SpdfValueOptions::getDipoleInvLat
    compile_opt idl2

    return, self.dipoleInvLat
end


;+
; Creates an ValueOptions element using the given XML DOM document 
; with the values of this object.
;
; @param doc {in} {type=IDLffXMLDOMDocument}
;            document in which to create the DataRequest element.
; @returns a reference to a new IDLffXMLDOMElement representation of
;     this object.
;-
function SpdfValueOptions::createDomElement, $
    doc
    compile_opt idl2

    valueOptionsElement = doc->createElement('ValueOptions')

    radialDistanceElement = doc->createElement('RadialDistance')
    ovoid = valueOptionsElement->appendChild(radialDistanceElement)
    if self.radialDistance eq 1b then begin

        radialDistanceText = 'true'
    endif else begin

        radialDistanceText = 'false'
    endelse
    radialDistanceNode = doc->createTextNode(radialDistanceText)
    ovoid = radialDistanceElement->appendChild(radialDistanceNode)

    bFieldStrengthElement = doc->createElement('BFieldStrength')
    ovoid = valueOptionsElement->appendChild(bFieldStrengthElement)
    if self.bFieldStrength eq 1b then begin

        bFieldStrengthText = 'true'
    endif else begin

        bFieldStrengthText = 'false'
    endelse
    bFieldStrengthNode = doc->createTextNode(bFieldStrengthText)
    ovoid = bFieldStrengthElement->appendChild(bFieldStrengthNode)

    dipoleLValueElement = doc->createElement('DipoleLValue')
    ovoid = valueOptionsElement->appendChild(dipoleLValueElement)
    if self.dipoleLValue eq 1b then begin

        dipoleLValueText = 'true'
    endif else begin

        dipoleLValueText = 'false'
    endelse
    dipoleLValueNode = doc->createTextNode(dipoleLValueText)
    ovoid = dipoleLValueElement->appendChild(dipoleLValueNode)

    dipoleInvLatElement = doc->createElement('DipoleInvLat')
    ovoid = valueOptionsElement->appendChild(dipoleInvLatElement)
    if self.dipoleInvLat eq 1b then begin

        dipoleInvLatText = 'true'
    endif else begin

        dipoleInvLatText = 'false'
    endelse
    dipoleInvLatNode = doc->createTextNode(dipoleInvLatText)
    ovoid = dipoleInvLatElement->appendChild(dipoleInvLatNode)

    return, valueOptionsElement
end


;+
; Defines the SpdfValueOptions class.
;
; @field radialDistance specifies whether the radial distance is to be
;            included in the output.
; @field bFieldStrength specifies whether the magnetic field strength
;            is to be included in the output.
; @field dipoleLValue specifies whether the dipole L value is to be
;            included in the output.
; @field dipoleInvLat specifies whether the dipole invariant latitude
;            is to be included in the output.
;-
pro SpdfValueOptions__define
    compile_opt idl2
    struct = { SpdfValueOptions, $

        radialDistance:0b, $
        bFieldStrength:0b, $
        dipoleLValue:0b, $
        dipoleInvLat:0b $
    }
end
