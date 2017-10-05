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
; This class is an IDL representation of the CoordinateOptions
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
; Creates an SpdfCoordinateOptions object.
;
; @keyword coordinateSystem {in} {type=string} 
;              specifies the coordinateSystem.  Must be one of the
;              following values: Geo, Gm, Gsm, Sm, GeiTod, or GeiJ2000.
; @keyword component {in} {type=string}
;              specifies the coordinate component.  Must be one of the
;              following values: X, Y, Z, Lat, Lon, or Local_Time.
; @returns reference to an SpdfCoordinateOptions object.
;-
function SpdfCoordinateOptions::init, $
    coordinateSystem = coordinateSystem, $
    component = component
    compile_opt idl2

    self.coordinateSystem = coordinateSystem
    self.component = component

    return, self
end


;+
; Performs cleanup operations when this object is destroyed.
;-
pro SpdfCoordinateOptions::cleanup
    compile_opt idl2

end


;+
; Gets the coordinate system value.
;
; @returns coordinate system value.
;-
function SpdfCoordinateOptions::getCoordinateSystem
    compile_opt idl2

    return, self.coordinateSystem
end


;+
; Gets the coordinate component value.
;
; @returns coordinate component value.
;-
function SpdfCoordinateOptions::getComponent
    compile_opt idl2

    return, self.component
end


;+
; Creates an CoordinateOptions element using the given XML DOM document 
; with the values of this object.
;
; @param doc {in} {type=IDLffXMLDOMDocument}
;            document in which to create the DataRequest element.
; @returns a reference to a new IDLffXMLDOMElement representation of
;     this object.
;-
function SpdfCoordinateOptions::createDomElement, $
    doc
    compile_opt idl2

    coordinateOptionsElement = doc->createElement('CoordinateOptions')

    coordinateSystemElement = doc->createElement('CoordinateSystem')
    ovoid = coordinateOptionsElement->appendChild( $
                coordinateSystemElement)
    coordinateSystemNode = doc->createTextNode(self.coordinateSystem)
    ovoid = coordinateSystemElement->appendChild(coordinateSystemNode)

    componentElement = doc->createElement('Component')
    ovoid = coordinateOptionsElement->appendChild(componentElement)
    componentNode = doc->createTextNode(self.component)
    ovoid = componentElement->appendChild(componentNode)

    return, coordinateOptionsElement
end


;+
; Defines the SpdfCoordinateOptions class.
;
; @field coordinateSystem specifies the coordinate system.
; @field component specifies the coordinate component.
;-
pro SpdfCoordinateOptions__define
    compile_opt idl2
    struct = { SpdfCoordinateOptions, $

        coordinateSystem:'', $
        component:'' $
    }
end
