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
;   https://cdaweb.gsfc.nasa.gov/WebServices/NASA_Open_Source_Agreement_1.3.txt.
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
; Copyright (c) 2018-2020 United States Government as represented by the 
; National Aeronautics and Space Administration. No copyright is claimed 
; in the United States under Title 17, U.S.Code. All Other Rights Reserved.
;
;



;+
; This class is an IDL representation of the BinData element from 
; the
; <a href="https://cdaweb.gsfc.nasa.gov/">Coordinated Data Analysis System</a>
; (CDAS) XML schema.  See 
; <a href="https://cdaweb.gsfc.nasa.gov/CDAWeb_Binning_readme.html">
; CDAWeb data binning</a> for more details.
;
; @copyright Copyright (c) 2018-2020 United States Government as represented
;     by the National Aeronautics and Space Administration. No
;     copyright is claimed in the United States under Title 17,
;     U.S.Code. All Other Rights Reserved.
;
; @author B. Harris
;-


;+
; Creates an SpdfBinData object.
;
; @param interval {in} {type=double}
;            binning interval (seconds).
; @param interpolateMissingValues {in} {type=byte}
;            flag indicating whether to interpolate missing values.
; @param sigmaMultiplier {in} {type=int} 
;            standard deviation multiplier used for rejecting data.
; @param overrideDefaultBinning {in} {type=byte} {default=0B}
;            flag indicating whether to override the default selection
;            of variables to bin.  0 = use default selection (only
;            variables with the ALLOW_BIN attribute set).  1 = bin
;            additional variables beyond just those with the ALLOW_BIN
;            attribute set.
; @returns reference to an SpdfBinData object.
;-
function SpdfBinData::init, $
    interval, $
    interpolateMissingValues, $
    sigmaMultiplier, $
    overrideDefaultBinning
    compile_opt idl2

    self.interval = interval
    self.interpolateMissingValues = interpolateMissingValues
    self.sigmaMultiplier = sigmaMultiplier
    if (n_elements(overrideDefaultBinning) eq 0) then begin
        self.overrideDefaultBinning = 0B
    endif else begin
        self.overrideDefaultBinning = overrideDefaultBinning
    endelse

    return, self
end


;+
; Performs cleanup operations when this object is destroyed.
;-
pro SpdfBinData::cleanup
    compile_opt idl2

end


;+
; Gets the interval value.
;
; @returns interval value
;-
function SpdfBinData::getInterval
    compile_opt idl2

    return, self.interval
end


;+
; Gets the interpolateMissingValues value.
;
; @returns interpolateMissingValues value.
;-
function SpdfBinData::getInterpolateMissingValues
    compile_opt idl2

    return, self.interpolateMissingValues
end


;+
; Gets the sigmaMultiplier value.
;
; @returns sigmaMultiplier value.
;-
function SpdfBinData::getSigmaMultiplier
    compile_opt idl2

    return, self.sigmaMultiplier
end


;+
; Gets the overrideDefaultBinning value.
;
; @returns overrideDefaultBinning value.
;-
function SpdfBinData::getOverrideDefaultBinning
    compile_opt idl2

    return, self.overrideDefaultBinning
end


;+
; Creates a BinData element using the given XML DOM document with 
; the values of this object.
;
; @param doc {in} {type=IDLffXMLDOMDocument}
;            document in which to create the BinData element.
; @returns a reference to a new IDLffXMLDOMElement representation of
;     this object.
;-
function SpdfBinData::createDomElement, $
    doc
    compile_opt idl2

    binDataElement = doc->createElement('BinData')

    intervalElement = doc->createElement('Interval')
    ovoid = binDataElement->appendChild(intervalElement);
    intervalText = doc->createTextNode( $
                       string(self.interval, format='(%"%f")'))
    ovoid = intervalElement->appendChild(intervalText)

    interpolateElement = doc->createElement('InterpolateMissingValues')
    ovoid = binDataElement->appendChild(interpolateElement)
    if self.interpolateMissingValues then begin
        interpolate = 'true' 
    endif else begin
        interpolate = 'false' 
    endelse
    interpolateText = doc->createTextNode(interpolate)
    ovoid = interpolateElement->appendChild(interpolateText)

    sigmaElement = doc->createElement('SigmaMultiplier')
    ovoid = binDataElement->appendChild(sigmaElement)
    sigmaText = doc->createTextNode( $
                    string(self.sigmaMultiplier, format='(%"%d")'));
    ovoid = sigmaElement->appendChild(sigmaText)

    overrideElement = doc->createElement('OverrideDefaultBinning')
    ovoid = binDataElement->appendChild(overrideElement)
    if self.overrideDefaultBinning then begin
        override = 'true' 
    endif else begin
        override = 'false' 
    endelse
    overrideText = doc->createTextNode(override)
    ovoid = overrideElement->appendChild(overrideText)

    return, binDataElement
end


;
; Defines the SpdfBinData class.
;
; @field interval binning interval (seconds).
; @field interpolateMissingValue flag indicating whether to interpolate
;     missing values.
; @field sigmaMultiplier standard deviation multiplier used for rejecting 
;     data.
;-
pro SpdfBinData__define
    compile_opt idl2
    struct = { SpdfBinData, $
        interval:0.0D, $
        interpolateMissingValues:1B, $
        sigmaMultiplier:0L, $
        overrideDefaultBinning:0B $
    }
end
