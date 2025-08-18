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
; This class is an IDL representation of the BFieldTraceOptions
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
; Creates an SpdfBFieldTraceOptions object.
;
; @keyword coordinateSystem {in} {optional} {type=string} 
;              {default='Gse'}
;              specifies the coordinate system is to be included in 
;              the output.
; @keyword hemisphere {in} {optional} {type=string} {default='North'}
;              specifies the hemisphere to be included in the output.
; @keyword footpointLatitude {in} {optional} {type=boolean} 
;              {default=false}
;              specifies whether the footpoint latitude value is to 
;              be included in the output.
; @keyword footpointLongitude {in} {optional} {type=boolean} 
;              {default=false}
;              specifies whether the footpoint longitude value is to 
;              be included in the output.
; @keyword fieldLineLength {in} {optional} {type=boolean} 
;              {default=false}
;              specifies whether the field line length value is to be 
;              included in the output.
; @returns reference to an SpdfBFieldTraceOptions object.
;-
function SpdfBFieldTraceOptions::init, $
    coordinateSystem = coordinateSystem, $
    hemisphere = hemisphere, $
    footpointLatitude = footpointLatitude, $
    footpointLongitude = footpointLongitude, $
    fieldLineLength = fieldLineLength
    compile_opt idl2

    if keyword_set(coordinateSystem) then begin

        self.coordinateSystem = coordinateSystem
    endif else begin

        self.coordinateSystem = 'Gse'
    endelse

    if keyword_set(hemisphere) then begin

        self.hemisphere = hemisphere
    endif else begin

        self.hemisphere = 'North'
    endelse

    if keyword_set(footpointLatitude) then begin

        self.footpointLatitude = footpointLatitude
    endif else begin

        self.footpointLatitude = 0b
    endelse

    if keyword_set(footpointLongitude) then begin

        self.footpointLongitude = footpointLongitude
    endif else begin

        self.footpointLongitude = 0b
    endelse

    if keyword_set(fieldLineLength) then begin

        self.fieldLineLength = fieldLineLength
    endif else begin

        self.fieldLineLength = 0b
    endelse

    return, self
end


;+
; Performs cleanup operations when this object is destroyed.
;-
pro SpdfBFieldTraceOptions::cleanup
    compile_opt idl2

end


;+
; Gets the coordinate system value.
;
; @returns coordinate system value.
;-
function SpdfBFieldTraceOptions::getCoordinateSystem
    compile_opt idl2

    return, self.coordinateSystem
end


;+
; Gets the hemisphere value.
;
; @returns hemisphere value.
;-
function SpdfBFieldTraceOptions::getHemisphere
    compile_opt idl2

    return, self.hemisphere
end


;+
; Gets the footpoint latitude value.
;
; @returns footpoint latitude value.
;-
function SpdfBFieldTraceOptions::getFootpointLatitude
    compile_opt idl2

    return, self.footpointLatitude
end


;+
; Gets the footpoint longitude value.
;
; @returns footpoint longitude value.
;-
function SpdfBFieldTraceOptions::getFootpointLongitude
    compile_opt idl2

    return, self.footpointLongitude
end


;+
; Gets the field-line length value.
;
; @returns field-line length value.
;-
function SpdfBFieldTraceOptions::getFieldLineLength
    compile_opt idl2

    return, self.fieldLineLength
end


;+
; Creates an BFieldTraceOptions element using the given XML DOM 
; document with the values of this object.
;
; @param doc {in} {type=IDLffXMLDOMDocument}
;            document in which to create the DataRequest element.
; @returns a reference to a new IDLffXMLDOMElement representation of
;     this object.
;-
function SpdfBFieldTraceOptions::createDomElement, $
    doc
    compile_opt idl2

    bFieldTraceOptionsElement = doc->createElement('BFieldTraceOptions')

    coordinateSystemElement = doc->createElement('CoordinateSystem')
    ovoid = $
        bFieldTraceOptionsElement->appendChild(coordinateSystemElement)
    coordinateSystemNode = doc->createTextNode(self.coordinateSystem)
    ovoid = coordinateSystemElement->appendChild(coordinateSystemNode)

    hemisphereElement = doc->createElement('Hemisphere')
    ovoid = bFieldTraceOptionsElement->appendChild(hemisphereElement)
    hemisphereNode = doc->createTextNode(self.hemisphere)
    ovoid = hemisphereElement->appendChild(hemisphereNode)

    footpointLatitudeElement = doc->createElement('FootpointLatitude')
    ovoid = $
        bFieldTraceOptionsElement->appendChild(footpointLatitudeElement)
    if self.footpointLatitude eq 1b then begin

        footpointLatitudeText = 'true'
    endif else begin

        footpointLatitudeText = 'false'
    endelse
    footpointLatitudeNode = doc->createTextNode(footpointLatitudeText)
    ovoid = footpointLatitudeElement->appendChild(footpointLatitudeNode)

    footpointLongitudeElement = doc->createElement('FootpointLongitude')
    ovoid = $
        bFieldTraceOptionsElement->appendChild( $
            footpointLongitudeElement)
    if self.footpointLongitude eq 1b then begin

        footpointLongitudeText = 'true'
    endif else begin

        footpointLongitudeText = 'false'
    endelse
    footpointLongitudeNode = doc->createTextNode(footpointLongitudeText)
    ovoid = $
        footpointLongitudeElement->appendChild(footpointLongitudeNode)

    fieldLineLengthElement = doc->createElement('FieldLineLength')
    ovoid = $
        bFieldTraceOptionsElement->appendChild(fieldLineLengthElement)
    if self.fieldLineLength eq 1b then begin

        fieldLineLengthText = 'true'
    endif else begin

        fieldLineLengthText = 'false'
    endelse
    fieldLineLengthNode = doc->createTextNode(fieldLineLengthText)
    ovoid = $
        fieldLineLengthElement->appendChild(fieldLineLengthNode)

    return, bFieldTraceOptionsElement
end


;+
; Defines the SpdfBFieldTraceOptions class.
;
; @field coordinateSystem specifies whether the coordinate system is 
;            to be included in the output.
; @field hemisphere specifies whether the hemisphere to be included
;            in the output.
; @field footpointLatitude specifies whether the footpoint latitude
;            value is to be included in the output.
; @field footpointLongitude specifies whether the footpoint longitude
;            value is to be included in the output.
; @field fieldLineLength specifies whether the field line length 
;            value is to be included in the output.
;-
pro SpdfBFieldTraceOptions__define
    compile_opt idl2
    struct = { SpdfBFieldTraceOptions, $

        coordinateSystem:'', $
        hemisphere:'', $
        footpointLatitude:0b, $
        footpointLongitude:0b, $
        fieldLineLength:0b $
    }
end
