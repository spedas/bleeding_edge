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
; This class is an IDL representation of the RegionOptions
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
; Creates an SpdfRegionOptions object.
;
; @keyword spacecraft {in} {optional} {type=boolean} {default=false}
;              specifies whether the spacecraft regions are to be
;              included in the output.
; @keyword radialTracedFootpoint {in} {optional} {type=boolean} 
;              {default=false}
;              specifies whether the radial traced footpoint regions 
;              are to be included in the output.
; @keyword northBTracedFootpoint {in} {optional} {type=boolean} 
;              {default=false}
;              specifies whether the north B traced footpoint regions 
;              are to be included in the output.
; @keyword southBTracedFootpoint {in} {optional} {type=boolean} 
;              {default=false}
;              specifies whether the south B traced footpoint regions 
;              are to be included in the output.
; @returns reference to an SpdfRegionOptions object.
;-
function SpdfRegionOptions::init, $
    spacecraft = spacecraft, $
    radialTracedFootpoint = radialTracedFootpoint, $
    northBTracedFootpoint = northBTracedFootpoint, $
    southBTracedFootpoint = southBTracedFootpoint
    compile_opt idl2

    if keyword_set(spacecraft) then begin

        self.spacecraft = spacecraft
    endif else begin

        self.spacecraft = 0b
    endelse

    if keyword_set(radialTracedFootpoint) then begin

        self.radialTracedFootpoint = radialTracedFootpoint
    endif else begin

        self.radialTracedFootpoint = 0b
    endelse

    if keyword_set(northBTracedFootpoint) then begin

        self.northBTracedFootpoint = northBTracedFootpoint
    endif else begin

        self.northBTracedFootpoint = 0b
    endelse

    if keyword_set(southBTracedFootpoint) then begin

        self.southBTracedFootpoint = southBTracedFootpoint
    endif else begin

        self.southBTracedFootpoint = 0b
    endelse

    return, self
end


;+
; Performs cleanup operations when this object is destroyed.
;-
pro SpdfRegionOptions::cleanup
    compile_opt idl2

end


;+
; Gets the spacecraft value.
;
; @returns spacecraft value.
;-
function SpdfRegionOptions::getSpacecraft
    compile_opt idl2

    return, self.spacecraft
end


;+
; Gets the radial traced footpoint value.
;
; @returns radial traced footpoint value.
;-
function SpdfRegionOptions::getRadialTracedFootpoint
    compile_opt idl2

    return, self.radialTracedFootpoint
end


;+
; Gets the north B traced footpoint value.
;
; @returns north B traced footpoint value.
;-
function SpdfRegionOptions::getNorthBTracedFootpoint
    compile_opt idl2

    return, self.northBTracedFootpoint
end


;+
; Gets the south B traced footpoint value.
;
; @returns south B traced footpoint value.
;-
function SpdfRegionOptions::getSouthBTracedFootpoint
    compile_opt idl2

    return, self.southBTracedFootpoint
end


;+
; Creates an RegionOptions element using the given XML DOM document 
; with the values of this object.
;
; @param doc {in} {type=IDLffXMLDOMDocument}
;            document in which to create the DataRequest element.
; @returns a reference to a new IDLffXMLDOMElement representation of
;     this object.
;-
function SpdfRegionOptions::createDomElement, $
    doc
    compile_opt idl2

    regionOptionsElement = doc->createElement('RegionOptions')

    spacecraftElement = doc->createElement('Spacecraft')
    ovoid = regionOptionsElement->appendChild(spacecraftElement)
    if self.spacecraft eq 1b then begin

        spacecraftText = 'true'
    endif else begin

        spacecraftText = 'false'
    endelse
    spacecraftNode = doc->createTextNode(spacecraftText)
    ovoid = spacecraftElement->appendChild(spacecraftNode)

    radialTracedFootpointElement = $
        doc->createElement('RadialTracedFootpoint')
    ovoid = $
        regionOptionsElement->appendChild(radialTracedFootpointElement)
    if self.radialTracedFootpoint eq 1b then begin

        radialTracedFootpointText = 'true'
    endif else begin

        radialTracedFootpointText = 'false'
    endelse
    radialTracedFootpointNode = $
        doc->createTextNode(radialTracedFootpointText)
    ovoid = radialTracedFootpointElement->appendChild( $
                radialTracedFootpointNode)

    northBTracedFootpointElement = $
        doc->createElement('NorthBTracedFootpoint')
    ovoid = $
        regionOptionsElement->appendChild(northBTracedFootpointElement)
    if self.northBTracedFootpoint eq 1b then begin

        northBTracedFootpointText = 'true'
    endif else begin

        northBTracedFootpointText = 'false'
    endelse
    northBTracedFootpointNode = $
        doc->createTextNode(northBTracedFootpointText)
    ovoid = northBTracedFootpointElement->appendChild( $
                northBTracedFootpointNode)

    southBTracedFootpointElement = $
        doc->createElement('SouthBTracedFootpoint')
    ovoid = $
        regionOptionsElement->appendChild(southBTracedFootpointElement)
    if self.southBTracedFootpoint eq 1b then begin

        southBTracedFootpointText = 'true'
    endif else begin

        southBTracedFootpointText = 'false'
    endelse
    southBTracedFootpointNode = $
        doc->createTextNode(southBTracedFootpointText)
    ovoid = southBTracedFootpointElement->appendChild( $
                southBTracedFootpointNode)

    return, regionOptionsElement
end


;+
; Defines the SpdfRegionOptions class.
;
; @field spacecraft specifies whether the spacecraft regions are to be
;            included in the output.
; @field radialTracedFootpoint specifies whether the radial traced
;            footpoint regions are to be included in the output.
; @field northBTracedFootpoint specifies whether the north B traced
;            footpoint regions are to be included in the output.
; @field southBTracedFootpoint specifies whether the south B traced
;            footpoint regions are to be included in the output.
;-
pro SpdfRegionOptions__define
    compile_opt idl2
    struct = { SpdfRegionOptions, $

        spacecraft:0b, $
        radialTracedFootpoint:0b, $
        northBTracedFootpoint:0b, $
        southBTracedFootpoint:0b $
    }
end
