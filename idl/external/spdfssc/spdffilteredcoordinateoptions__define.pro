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
; Copyright (c) 2014 United States Government as represented by the 
; National Aeronautics and Space Administration. No copyright is claimed 
; in the United States under Title 17, U.S.Code. All Other Rights Reserved.
;
;



;+
; This class is an IDL representation of the FilteredCoordinateOptions
; element from the
; <a href="http://sscweb.gsfc.nasa.gov/">Satellite Situation Center</a>
; (SSC) XML schema.
;
; Note: SSC's filtering features do not support CDF output so this
;     class is not required until this IDL library supports requests
;     for text output.
;
; @copyright Copyright (c) 2014 United States Government as represented
;     by the National Aeronautics and Space Administration. No
;     copyright is claimed in the United States under Title 17,
;     U.S.Code. All Other Rights Reserved.
;
; @author B. Harris
;-


;+
; Creates an SpdfFilteredCoordinateOptions object.
;
; @param coordinateSystem {in} {type=string} 
;            specifies the coordinateSystem.  Must be one of the
;            following values: Geo, Gm, Gsm, Sm, GeiTod, or GeiJ2000.
; @param component {in} {type=string}
;            specifies the coordinate component.  Must be one of the
;            following values: X, Y, Z, Lat, Lon, or Local_Time.
; @param filter {in} {type=SpdfLocationFilter}
;            coordinate value filter.
; @returns reference to an SpdfFilteredCoordinateOptions object.
;-
function SpdfFilteredCoordinateOptions::init, $
    coordinateSystem, $
    component, $
    filter
    compile_opt idl2

    if ~(self->SpdfCoordinateOptions::init( $
            coordinateSystem, component)) then begin

        return, 0
    endif

    self.filter = filter

    return, self
end


;+
; Performs cleanup operations when this object is destroyed.
;-
pro SpdfFilteredCoordinateOptions::cleanup
    compile_opt idl2

    if obj_valid(self.filter) then obj_destroy, self.filter

;    self->SpdfCoordinateOptions::cleanup
end


;+
; Gets the filter value.
;
; @returns filter value.
;-
function SpdfFilteredCoordinateOptions::getFilter
    compile_opt idl2

    if obj_valid(self.filter) then begin

        return, self.filter
    endif else begin

        return, obj_new()
    endelse
end



;+
; Creates an FilteredCoordinateOptions element using the given XML DOM 
; document with the values of this object.
;
; @param doc {in} {type=IDLffXMLDOMDocument}
;            document in which to create the DataRequest element.
; @returns a reference to a new IDLffXMLDOMElement representation of
;     this object.
;-
function SpdfFilteredCoordinateOptions::createDomElement, $
    doc
    compile_opt idl2

    filteredCoordinateOptionsElement = $
        self->SpdfCoordinateOptions::createDomElement(doc)

    if obj_valid(self.filter) then begin

        filterElement = self.filter->createDomElement(doc, 'Filter')

        ovoid = filteredCoordinateOptionsElement->appendChild( $
                    filterElement)
    endif

    return, filteredCoordinateOptionsElement
end


;+
; Defines the SpdfFilteredCoordinateOptions class.
;
; @field filter specifies filter criteria.
;-
pro SpdfFilteredCoordinateOptions__define
    compile_opt idl2
    struct = { SpdfFilteredCoordinateOptions, $

        inherits SpdfCoordinateOptions, $
        filter:obj_new() $
    }
end
