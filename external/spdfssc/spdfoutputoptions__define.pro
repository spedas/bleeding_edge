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
; This class is an IDL representation of the OutputOptions
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
; Creates an SpdfOutputOptions object.
;
; @param coordinateOptions {in} {type=objarr of SpdfCoordinateOptions}
;              specifies the coordinate options.
; @keyword allLocationFilters {in} {optional} {type=boolean} 
;              {default=true}
;              specifies whether all or just one or more of the
;              specified location filters must be satisfied.
; @keyword regionOptions {in} {optional} {type=SpdfRegionOptions}
;              specifies the region options.
; @keyword valueOptions {in} {optional} {type=SpdfValueOptions}
;              specifies the value options.
; @keyword distanceFromOptions {in} {optional} 
;              {type=SpdfDistanceFromOptions)
;              specifies distance-from options.
; @keyword minMaxPoints {in} {optional} {type=int} {default=2}
;              number of points used to determin minima or maxima 
;              values.
; @keyword bFieldTraceOptions {in} {optional} 
;              {type=objarr of SpdfBFieldTraceOptions}
;              magnetic field trace options
; @returns reference to an SpdfOutputOptions object.
;-
function SpdfOutputOptions::init, $
    coordinateOptions, $
    allLocationFilters = allLocationFilters, $
    regionOptions = regionOptions, $
    valueOptions = valueOptions, $
    distanceFromOptions = distanceFromOptions, $
    minMaxPoints = minMaxPoints, $
    bFieldTraceOptions = bFieldTraceOptions
    compile_opt idl2

    self.coordinateOptions = ptr_new(coordinateOptions)

    if keyword_set(allLocationFilters) then begin

        self.allLocationFilters = 1b
    endif else begin

        self.allLocationFilters = 0b
    endelse

    if keyword_set(regionOptions) then begin

        self.regionOptions = regionOptions
    endif

    if keyword_set(valueOptions) then begin

        self.valueOptions = valueOptions
    endif

    if keyword_set(distanceFromOptions) then begin

        self.distanceFromOptions = distanceFromOptions
    endif

    if keyword_set(minMaxPoints) then begin

        self.minMaxPoints = minMaxPoints
    endif else begin

        self.minMaxPoints = 2
    endelse

    if keyword_set(bFieldTraceOptions) then begin

        self.bFieldTraceOptions = ptr_new(bFieldTraceOptions)
    endif

    return, self
end


;+
; Performs cleanup operations when this object is destroyed.
;-
pro SpdfOutputOptions::cleanup
    compile_opt idl2

    if ptr_valid(self.coordinateOptions) then begin

        ptr_free, self.coordinateOptions
    endif

    if obj_valid(self.regionOptions) then begin

        obj_destroy, self.regionOptions
    endif

    if obj_valid(self.valueOptions) then begin

        obj_destroy, self.valueOptions
    endif

    if obj_valid(self.distanceFromOptions) then begin

        obj_destroy, self.distanceFromOptions
    endif

    if ptr_valid(self.bFieldTraceOptions) then begin

        ptr_free, self.bFieldTraceOptions
    endif
end


;+
; Gets the all-location-filters value.
;
; @returns all-location-filters value.
;-
function SpdfOutputOptions::getAllLocationFilters
    compile_opt idl2

    return, self.allLocationFilters 
end


;+
; Gets the coordinate options value.
;
; @returns objarr of CoordinateOptions or an objarr(1) whose first
;     element is ~obj_valid().
;-
function SpdfOutputOptions::getCoordinateOptions
    compile_opt idl2

    if ptr_valid(self.coordinateOptions) then begin

        return, *self.coordinateOptions
    endif else begin

        return, objarr(1)
    endelse
end


;+
; Gets the region options value.
;
; @returns RegionOptions or a null object reference.
;-
function SpdfOutputOptions::getRegionOptions
    compile_opt idl2

    if obj_valid(self.regionOptions) then begin

        return, self.regionOptions
    endif else begin

        return, obj_new()
    endelse
end


;+
; Gets the ValueOptions value.
;
; @returns ValueOptions or a null object reference.
;-
function SpdfOutputOptions::getValueOptions
    compile_opt idl2

    if obj_valid(self.valueOptions) then begin

        return, self.valueOptions
    endif else begin

        return, obj_new()
    endelse
end


;+
; Gets the DistanceFromOptions value.
;
; @returns DistanceFromOptions value or a null object reference.
;-
function SpdfOutputOptions::getDistanceFromOptions
    compile_opt idl2

    if obj_valid(self.distanceFromOptions) then begin

        return, self.distanceFromOptions
    endif else begin

        return, obj_new()
    endelse
end


;+
; Gets the minMaxPoints value.
;
; @returns minMaxPoints value or a null object reference.
;-
function SpdfOutputOptions::getMinMaxPoints
    compile_opt idl2

    if obj_valid(self.minMaxPoints) then begin

        return, self.minMaxPoints
    endif else begin

        return, obj_new()
    endelse
end


;+
; Gets the BFieldTraceOptions value.
;
; @returns objarr containing BFieldTraceOptions or objarr(1) whose
;     first element is ~obj_valid.
;-
function SpdfOutputOptions::getBFieldTraceOptions
    compile_opt idl2

    if ptr_valid(self.bFieldTraceOptions) then begin

        return, *self.bFieldTraceOptions
    endif else begin

        return, objarr(1)
    endelse
end


;+
; Creates an OutputOptions element using the given XML DOM document 
; with the values of this object.
;
; @param doc {in} {type=IDLffXMLDOMDocument}
;            document in which to create the DataRequest element.
; @returns a reference to a new IDLffXMLDOMElement representation of
;     this object.
;-
function SpdfOutputOptions::createDomElement, $
    doc
    compile_opt idl2

    outputOptionsElement = doc->createElement('OutputOptions')

    allLocationFiltersElement = doc->createElement('AllLocationFilters')
    ovoid = outputOptionsElement->appendChild(allLocationFiltersElement)
    if self.allLocationFilters eq 1b then begin

        allLocationFiltersText = 'true'
    endif else begin

        allLocationFiltersText = 'false'
    endelse
    allLocationFilterNode = doc->createTextNode(allLocationFiltersText)
    ovoid = allLocationFiltersElement->appendChild( $
                allLocationFilterNode)

    if ptr_valid(self.coordinateOptions) then begin

        for i = 0, n_elements(*self.coordinateOptions) - 1 do begin

            coordinateOptionsElement = $
                ((*self.coordinateOptions)[i])->createDomElement(doc)

            ovoid = outputOptionsElement->appendChild( $
                        coordinateOptionsElement)
        endfor
    endif

    if obj_valid(self.regionOptions) then begin

        regionOptionsElement = $
            self.regionOptions->createDomElement(doc)

        ovoid = outputOptionsElement->appendChild(regionOptionsElement)
    endif

    if obj_valid(self.valueOptions) then begin

        valueOptionsElement = $
            self.valueOptions->createDomElement(doc)

        ovoid = outputOptionsElement->appendChild(valueOptionsElement)
    endif

    if obj_valid(self.distanceFromOptions) then begin

        distanceFromOptionsElement = $
            self.distanceFromOptions->createDomElement(doc)

        ovoid = outputOptionsElement->appendChild( $
                    distanceFromOptionsElement)
    endif

    if ptr_valid(self.bFieldTraceOptions) then begin

        for i = 0, n_elements(*self.bFieldTraceOptions) - 1 do begin

            bFieldTraceOptionsElement = $
                ((*self.bFieldTraceOptions)[i])->createDomElement(doc)

            ovoid = outputOptionsElement->appendChild( $
                        bFieldTraceOptionsElement)
        endfor
    endif

    minMaxPointsElement = doc->createElement('MinMaxPoints')
    ovoid = outputOptionsElement->appendChild(minMaxPointsElement)
    minMaxPointsText = $
        doc->createTextNode(string(self.minMaxPoints, format='(%"%d")'))
    ovoid = minMaxPointsElement->appendChild(minMaxPointsText)

    return, outputOptionsElement
end


;+
; Defines the SpdfOutputOptions class.
;
; @field allLocationFilters boolean flag indicating whether all 
;            specified location filters must be true.
; @field coordinateOptions coordinate options.
; @field regionOptions region options.
; @field valueOptions value options.
; @field distanceFromOptions distance from options.
; @field minMaxPoints number of point to define minimum/maximum.
; @field bFieldTraceOptions magnetic field trace options.
;-
pro SpdfOutputOptions__define
    compile_opt idl2
    struct = { SpdfOutputOptions, $

        allLocationFilters:1b, $
        coordinateOptions:ptr_new(), $
        regionOptions:obj_new(), $
        valueOptions:obj_new(), $
        distanceFromOptions:obj_new(), $
        minMaxPoints:2, $
        bFieldTraceOptions:ptr_new() $
    }
end
