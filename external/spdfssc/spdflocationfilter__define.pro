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
; This class is an IDL representation of the LocationFilter
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
; Creates an SpdfLocationFilter object.
;
; @keyword minimum {in} {optional} {type=boolean}
;              specifies that the minimum value that should be
;              included in the results.
; @keyword maximum {in} {optional} {type=boolean}
;              specifies that the maximum value that should be 
;              included in the results.
; @keyword lowerLimit {in} {optional} {type=double}
;              specifies that the lower limit of values that should 
;              be included in the results.
; @keyword upperLimit {in} {optional} {type=double}
;              specifies that the upper limit of values that should 
;              be included in the results.
; @returns reference to an SpdfLocationFilter object.
;-
function SpdfLocationFilter::init, $
    minimum = minimum, $
    maximum = maximum, $
    lowerLimit = lowerLimit, $
    upperLimit = upperLimit
    compile_opt idl2

    if keyword_set(minimum) then begin

        self.minimum = minimum
    endif else begin

        self.minimum = 0b
    endelse

    if keyword_set(maximum) then begin

        self.maximum = maximum
    endif else begin

        self.maximum = 0b
    endelse

    if keyword_set(lowerLimit) then begin

        self.lowerLimit = lowerLimit
    endif else begin

        self.lowerLimit = !values.d_nan
    endelse

    if keyword_set(upperLimit) then begin

        self.upperLimit = upperLimit
    endif else begin

        self.upperLimit = !values.d_nan
    endelse

    self.spdfTime = obj_new('SpdfTimeInterval', $
                        '2014-01-01T00:00:00.000Z', $
                        '2014-01-02T00:00:00.000Z')

    return, self
end


;+
; Performs cleanup operations when this object is destroyed.
;-
pro SpdfLocationFilter::cleanup
    compile_opt idl2

end


;+
; Gets the Minimum value.
;
; @returns Minimum value.
;-
function SpdfLocationFilter::getMinimum
    compile_opt idl2

    return, self.minimum
end


;+
; Gets the Maximum value.
;
; @returns Maximum value.
;-
function SpdfLocationFilter::getMaximum
    compile_opt idl2

    return, self.maximum
end


;+
; Gets the LowerLimit value.
;
; @returns LowerLimit value.
;-
function SpdfLocationFilter::getLowerLimit
    compile_opt idl2

    return, self.lowerLimit
end


;+
; Gets the UpperLimit value.
;
; @returns UpperLimit value.
;-
function SpdfLocationFilter::getUpperLimit
    compile_opt idl2

    return, self.upperLimit
end



;+
; Creates an LocationFilter element using the given XML DOM document 
; with the values of this object.
;
; @param doc {in} {type=IDLffXMLDOMDocument}
;            document in which to create the DataRequest element.
; @param subClassName {in} {type=string}
;            name of sub-class.
; @returns a reference to a new IDLffXMLDOMElement representation of
;     this object.
;-
function SpdfLocationFilter::createDomElement, $
    doc, $
    subClassName
    compile_opt idl2

    locationFilterElement = doc->createElement(subClassName)

    minElement = doc->createElement('Minimum')
    ovoid = locationFilterElement->appendChild(minElement)
    if self.minimum eq 1b then begin

        minText = 'true'
    endif else begin

        minText = 'false'
    endelse
    minNode = doc->createTextNode(minText)
    ovoid = minElement->appendChild(minNode)

    maxElement = doc->createElement('Maximum')
    ovoid = locationFilterElement->appendChild(maxElement)
    if self.maximum eq 1b then begin

        maxText = 'true'
    endif else begin

        maxText = 'false'
    endelse
    maxNode = doc->createTextNode(maxText)
    ovoid = maxElement->appendChild(maxNode)

    if finite(self.lowerLimit) then begin

        lowerLimitElement = doc->createElement('LowerLimit')
        ovoid = locationFilterElement->appendChild(lowerLimitElement)
        lowerLimitNode = $
            doc->createTextNode( $
                string(self.lowerLimit, format='(%"%e")'))
        ovoid = lowerLimitElement->appendChild(lowerLimitNode)
    endif

    if finite(self.upperLimit) then begin

        upperLimitElement = doc->createElement('UpperLimit')
        ovoid = locationFilterElement->appendChild(upperLimitElement)
        upperLimitNode = $
            doc->createTextNode( $
                string(self.upperLimit, format='(%"%e")'))
        ovoid = upperLimitElement->appendChild(upperLimitNode)
    endif

    return, locationFilterElement
end


;+
; Defines the SpdfLocationFilter class.
;
; @field minimum specifies that the minimum value should be included 
;            in the results.
; @field maximum specifies that the maximum value should be included 
;            in the results.
; @field lowerLimit specifies that the lower limit of values that 
;            should be included in the results.
; @field upperLimit specifies that the upper limit of values that 
;            should be included in the results.
; @field spdfTime constant object used to call "static" methods of
;            SpdfTimeInterval class.
;-
pro SpdfLocationFilter__define
    compile_opt idl2
    struct = { SpdfLocationFilter, $

        minimum:0b, $
        maximum:0b, $
        lowerLimit:0d, $
        upperLimit:0d, $
        spdfTime:obj_new() $
    }
end
