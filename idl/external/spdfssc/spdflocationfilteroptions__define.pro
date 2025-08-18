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
; This class is an IDL representation of the LocationFilterOptions
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
; Creates an SpdfLocationFilterOptions object.
;
; @keyword allFilters {in} {optional} {type=boolean} 
;              {default=true}
;              specifies whether all or just one or more of the
;              specified location filters must be satisfied.
; @keyword distanceFromCenterOfEarth {in} {optional} 
;              {type=SpdfLocationFilter}
;              distance from the center of the Earth filter.
; @returns reference to an SpdfLocationFilterOptions object.
;-
function SpdfLocationFilterOptions::init, $
    allFilters = allFilters, $
    distanceFromCenterOfEarth = distanceFromCenterOfEarth, $
    magneticFieldStrength = magneticFieldStrength, $
    distanceFromNeutralSheet = distanceFromNeutralSheet, $
    distanceFromBowShock = distanceFromBowShock, $
    distanceFromMagnetopause = distanceFromMagnetopause, $
    dipoleLValue = dipoleLValue, $
    dipoleInvariantLatitude = dipoleInvariantLatitude
    compile_opt idl2

    if keyword_set(allFilters) then begin

        self.allFilters = 1b
    endif else begin

        self.allFilters = 0b
    endelse

    if keyword_set(distanceFromCenterOfEarth) then begin

        self.distanceFromCenterOfEarth = $
            ptr_new(distanceFromCenterOfEarth)
    endif

    if keyword_set(magneticFieldStrength) then begin

        self.magneticFieldStrength = $
            ptr_new(magneticFieldStrength)
    endif

    if keyword_set(distanceFromNeutralSheet) then begin

        self.distanceFromNeutralSheet = $
            ptr_new(distanceFromNeutralSheet)
    endif

    if keyword_set(distanceFromBowShock) then begin

        self.distanceFromBowShock = $
            ptr_new(distanceFromBowShock)
    endif 

    if keyword_set(distanceFromMagnetopause) then begin

        self.distanceFromMagnetopause = $
            ptr_new(distanceFromMagnetopause)
    endif

    if keyword_set(dipoleLValue) then begin

        self.dipoleLValue = $
            ptr_new(dipoleLValue)
    endif

    if keyword_set(dipoleInvariantLatitude) then begin

        self.dipoleInvariantLatitude = $
            ptr_new(dipoleInvariantLatitude)
    endif

    return, self
end


;+
; Performs cleanup operations when this object is destroyed.
;-
pro SpdfLocationFilterOptions::cleanup
    compile_opt idl2

    if ptr_valid(self.distanceFromCenterOfEarth) then begin

        ptr_free, self.distanceFromCenterOfEarth
    endif

    if obj_valid(self.magneticFieldStrength) then begin

        obj_destroy, self.magneticFieldStrength
    endif

    if obj_valid(self.distanceFromNeutralSheet) then begin

        obj_destroy, self.distanceFromNeutralSheet
    endif

    if obj_valid(self.distanceFromBowShock) then begin

        obj_destroy, self.distanceFromBowShock
    endif

    if ptr_valid(self.distanceFromMagnetopause) then begin

        ptr_free, self.distanceFromMagnetopause
    endif

    if ptr_valid(self.dipoleLValue) then begin

        ptr_free, self.dipoleLValue
    endif

    if ptr_valid(self.dipoleInvariantLatitude) then begin

        ptr_free, self.dipoleInvariantLatitude
    endif
end


;+
; Gets the all-filters value.
;
; @returns all-filters value.
;-
function SpdfLocationFilterOptions::getAllFilters
    compile_opt idl2

    return, self.allFilters 
end


;+
; Gets the distance from center of Earth filter value.
;
; @returns distance from center of Earth SpdfLocationFilter or 
;     a null object reference.
;-
function SpdfLocationFilterOptions::getDistanceFromCenterOfEarth
    compile_opt idl2

    if obj_valid(self.distanceFromCenterOfEarth) then begin

        return, self.distanceFromCenterOfEarth
    endif else begin

        return, obj_new()
    endelse
end


;+
; Gets the magnetic field strength filter value.
;
; @returns magnetic field strength SpdfLocationFilter or 
;     a null object reference.
;-
function SpdfLocationFilterOptions::getMagneticFieldStrength
    compile_opt idl2

    if obj_valid(self.magneticFieldStrength) then begin

        return, self.magneticFieldStrength
    endif else begin

        return, obj_new()
    endelse
end


;+
; Gets the distance from neutral sheet filter value.
;
; @returns distance from neutral sheet SpdfLocationFilter or 
;     a null object reference.
;-
function SpdfLocationFilterOptions::getDistanceFromNeutralSheet
    compile_opt idl2

    if obj_valid(self.distanceFromNeutralSheet) then begin

        return, self.distanceFromNeutralSheet
    endif else begin

        return, obj_new()
    endelse
end


;+
; Gets the distance from bowshock filter value.
;
; @returns distance from bowshock SpdfLocationFilter or 
;     a null object reference.
;-
function SpdfLocationFilterOptions::getDistanceFromBowShock
    compile_opt idl2

    if obj_valid(self.distanceFromBowShock) then begin

        return, self.distanceFromBowShock
    endif else begin

        return, obj_new()
    endelse
end


;+
; Gets the distance from magnetopause filter value.
;
; @returns distance from magnetopause SpdfLocationFilter or 
;     a null object reference.
;-
function SpdfLocationFilterOptions::getDistanceFromMagnetopause
    compile_opt idl2

    if obj_valid(self.distanceFromMagnetopause) then begin

        return, self.distanceFromMagnetopause
    endif else begin

        return, obj_new()
    endelse
end


;+
; Gets the dipole L value filter value.
;
; @returns dipole L value SpdfLocationFilter or 
;     a null object reference.
;-
function SpdfLocationFilterOptions::getDipoleLValue
    compile_opt idl2

    if obj_valid(self.dipoleLValue) then begin

        return, self.dipoleLValue
    endif else begin

        return, obj_new()
    endelse
end


;+
; Gets the dipole invariant latitude value filter value.
;
; @returns dipole invariant latitude value SpdfLocationFilter or 
;     a null object reference.
;-
function SpdfLocationFilterOptions::getDipoleInvariantLatitude
    compile_opt idl2

    if obj_valid(self.dipoleInvariantLatitude) then begin

        return, self.dipoleInvariantLatitude
    endif else begin

        return, obj_new()
    endelse
end


;+
; Creates an LocationFilterOptions element using the given XML DOM 
; document with the values of this object.
;
; @param doc {in} {type=IDLffXMLDOMDocument}
;            document in which to create the DataRequest element.
; @returns a reference to a new IDLffXMLDOMElement representation of
;     this object.
;-
function SpdfLocationFilterOptions::createDomElement, $
    doc
    compile_opt idl2

    locationFilterOptionsElement = $
        doc->createElement('LocationFilterOptions')

    allFiltersElement = doc->createElement('AllFilters')
    ovoid = outputOptionsElement->appendChild(allFiltersElement)
    if self.allFilters eq 1b then begin

        allFiltersText = 'true'
    endif else begin

        allFiltersText = 'false'
    endelse
    allFilterNode = doc->createTextNode(allFiltersText)
    ovoid = allLocationFiltersElement->appendChild( $
                allFilterNode)

    if obj_valid(self.distanceFromCenterOfEarth) then begin

        distanceFromCenterOfEarthElement = $
            self.distanceFromCenterOfEarth->createDomElement(doc)

        ovoid = locationFilterOptionsElement->appendChild( $
                    distanceFromCenterOfEarthElement)
    endif

    if obj_valid(self.magneticFieldStrength) then begin

        magneticFieldStrengthElement = $
            self.magneticFieldStrength->createDomElement(doc)

        ovoid = locationFilterOptionsElement->appendChild( $
                    magneticFieldStrengthElement)
    endif

    if obj_valid(self.distanceFromNeutralSheet) then begin

        distanceFromNeutralSheetElement = $
            self.distanceFromCenterOfEarth->createDomElement(doc)

        ovoid = locationFilterOptionsElement->appendChild( $
                    distanceFromNeutralSheetElement)
    endif

    if obj_valid(self.distanceFromBowShock) then begin

        distanceFromBowShockElement = $
            self.distanceFromBowShock->createDomElement(doc)

        ovoid = locationFilterOptionsElement->appendChild( $
                    distanceFromBowShockElement)
    endif

    if obj_valid(self.distanceFromMagnetopause) then begin

        distanceFromMagnetopauseElement = $
            self.distanceFromMagnetopause->createDomElement(doc)

        ovoid = locationFilterOptionsElement->appendChild( $
                    distanceFromMagnetopauseElement)
    endif

    if obj_valid(self.dipoleLValue) then begin

        dipoleLValueElement = $
            self.dipoleLValue->createDomElement(doc)

        ovoid = locationFilterOptionsElement->appendChild( $
                    dipoleLValueElement)
    endif

    if obj_valid(self.dipoleInvariantLatitude) then begin

        dipoleInvariantLatitudeElement = $
            self.dipoleInvariantLatitude->createDomElement(doc)

        ovoid = locationFilterOptionsElement->appendChild( $
                    dipoleInvariantLatitudeElement)
    endif

    return, locationFilterOptionsElement
end


;+
; Defines the SpdfLocationFilterOptions class.
;
; @field allFilters boolean flag indicating whether all 
;            specified location filters must be true.
; @field distanceFromCenterOfEarth distance from center of Earth filter.
; @field magneticFieldStrength magnetic field strength filter.
; @field distanceFromNeutralSheet distance from neutral sheet filter.
; @field distanceFromBowShock distance from bowshock filter.
; @field distanceFromMagnetopause distance from magnetopause filter.
; @field dipoleLValue dipole L value filter.
; @field dipoleInvariantLatitude dipole invariant latitude filter.
;-
pro SpdfLocationFilterOptions__define
    compile_opt idl2
    struct = { SpdfLocationFilterOptions, $

        allFilters:1b, $
        distanceFromCenterOfEarth:ptr_new(), $
        magneticFieldStrength:obj_new(), $
        distanceFromNeutralSheet:obj_new(), $
        distanceFromBowShock:obj_new(), $
        distanceFromMagnetopause:ptr_new(), $
        dipoleLValue:ptr_new(), $
        dipoleInvariantLatitude:ptr_new() $
    }
end
