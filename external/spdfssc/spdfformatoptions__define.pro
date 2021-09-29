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
; This class is an IDL representation of the FormatOptions
; element from the
; <a href="http://sscweb.gsfc.nasa.gov/">Satellite Situation Center</a>
; (SSC) XML schema.
;
; @copyright Copyright (c) 2014 United States Government as represented
;     by the National Aeronautics and Space Administration. No
;     copyright is claimed in the United States under Title 17,
;     U.S.Code. All Other Rights Reserved.
;
; @author B. Harris
;-


;+
; Creates an SpdfFormatOptions object.
;
; @keyword dateFormat {in} {optional} {type=string} {default='yyyy_ddd'}
;              specifies the format for date values ('yyyy_ddd', 
;              'yy_mm_dd', 'yy_Mmm_dd', 'yy_CMMM_dd')
; @keyword timeFormat {in} {optional} {type=string} {default='hh_hhhh'}
;              specifies the format for time values ('hh_hhhh', 
;              'hh_mm_ss', 'hh_mm')
; @keyword distanceFormat {in} {optional} {type=string} {default='Km'}
;              specifies the units for distance values ('Re', 'Km', 
;              'IntegerKm', 'ScientificNotationKm')
; @keyword distanceDigits {in} {optional} {type=int} {default=2}
;              specifies the number of decimal places to include when 
;              displaying distance values in scientific notation.
; @keyword degreeFormat{in} {optional} {type=string} {default='Decimal'}
;              specifies the format for degree values ('Decimal', 
;              'Minutes', 'MinutesSeconds')
; @keyword degreeDigits {in} {optional} {type=int} {default=2}
;              specifies the number of decimal places to include when 
;              displaying degree values.
; @keyword latLonFormat {in} {optional} {type=string} 
;              {default='Lat90Lon360'}
;              specifies the format for direction/range values
;              ('Lat90Lon360', 'Lat90Lon180', 'Lat90SnLon180We')
; @keyword cdf {in} {optional} {type=boolean} {default=false}
;              boolean value indicating whether the output should be a
;              CDF file.
; @keyword linesPerPage {in} {optional} {type=int} {default=55}
;              specifies the number of lines per page for text output.
; @returns reference to an SpdfFormatOptions object.
;-
function SpdfFormatOptions::init, $
    dateFormat = dateFormat, $
    timeFormat = timeFormat, $
    distanceFormat = distanceFormat, $
    distanceDigits = distanceDigits, $
    degreeFormat = degreeFormat, $
    degreeDigits = degreeDigits, $
    latLonFormat = latLonFormat, $
    cdf = cdf, $
    linesPerPage = linesPerPage
    compile_opt idl2

    if keyword_set(dateFormat) then begin

        self.dateFormat = dateFormat
    endif else begin

        self.dateFormat = 'yyyy_ddd'
    endelse

    if keyword_set(timeFormat) then begin

        self.timeFormat = timeFormat
    endif else begin

        self.timeFormat = 'hh_hhhh'
    endelse

    if keyword_set(distanceFormat) then begin

        self.distanceFormat = distanceFormat
    endif else begin

        self.distanceFormat = 'Km'
    endelse

    if keyword_set(distanceDigits) then begin

        self.distanceDigits = distanceDigits
    endif else begin

        self.distanceDigits = 2
    endelse

    if keyword_set(degreeFormat) then begin

        self.degreeFormat = degreeFormat
    endif else begin

        self.degreeFormat = 'Decimal'
    endelse

    if keyword_set(degreeDigits) then begin

        self.degreeDigits = degreeDigits
    endif else begin

        self.degreeDigits = 2
    endelse

    if keyword_set(latLonFormat) then begin

        self.latLonFormat = latLongFormat
    endif else begin

        self.latLonFormat = 'Lat90Lon360'
    endelse

    if keyword_set(cdf) then begin

        self.cdf = cdf
    endif else begin

        self.cdf = 0b
    endelse

    if keyword_set(linesPerPage) then begin

        self.linesPerPage = linesPerPage
    endif else begin

        self.linesPerPage = 55
    endelse

    return, self
end


;+
; Performs cleanup operations when this object is destroyed.
;-
pro SpdfFormatOptions::cleanup
    compile_opt idl2

end


;+
; Gets the dateFormat value.
;
; @returns dateFormat value.
;-
function SpdfFormatOptions::getDateFormat
    compile_opt idl2

    return, self.dateFormat
end


;+
; Gets the timeFormat value.
;
; @returns timeFormat value.
;-
function SpdfFormatOptions::getTimeFormat
    compile_opt idl2

    return, self.timeFormat
end


;+
; Gets the distanceFormat value.
;
; @returns distanceFormat value.
;-
function SpdfFormatOptions::getDistanceFormat
    compile_opt idl2

    return, self.distanceFormat
end


;+
; Gets the distanceDigits value.
;
; @returns distanceDigits value.
;-
function SpdfFormatOptions::getDistanceDigits
    compile_opt idl2

    return, self.distanceDigits
end


;+
; Gets the degreeFormat value.
;
; @returns degreeFormat value.
;-
function SpdfFormatOptions::getDegreeFormat
    compile_opt idl2

    return, self.degreeFormat
end


;+
; Gets the degreeDigits value.
;
; @returns degreeDigits value.
;-
function SpdfFormatOptions::getDegreeDigits
    compile_opt idl2

    return, self.degreeDigits
end


;+
; Gets the latLonFormat value.
;
; @returns latLonFormat value.
;-
function SpdfFormatOptions::getLatLonFormat
    compile_opt idl2

    return, self.latLonFormat
end


;+
; Gets the cdf value.
;
; @returns cdf value.
;-
function SpdfFormatOptions::getCdf
    compile_opt idl2

    return, self.cdf
end


;+
; Gets the linesPerPage value.
;
; @returns linesPerPage value.
;-
function SpdfFormatOptions::getLinesPerPage
    compile_opt idl2

    return, self.linesPerPage
end



;+
; Creates an FormatOptions element using the given XML DOM document 
; with the values of this object.
;
; @param doc {in} {type=IDLffXMLDOMDocument}
;            document in which to create the DataRequest element.
; @returns a reference to a new IDLffXMLDOMElement representation of
;     this object.
;-
function SpdfFormatOptions::createDomElement, $
    doc
    compile_opt idl2

    formatOptionsElement = doc->createElement('FormatOptions')

    dateFormatElement = doc->createElement('DateFormat')
    ovoid = formatOptionsElement->appendChild(dateFormatElement)
    dateFormatNode = doc->createTextNode(self.dateFormat)
    ovoid = dateFormatElement->appendChild(dateFormatNode)

    timeFormatElement = doc->createElement('TimeFormat')
    ovoid = formatOptionsElement->appendChild(timeFormatElement)
    timeFormatNode = doc->createTextNode(self.timeFormat)
    ovoid = timeFormatElement->appendChild(timeFormatNode)

    distanceFormatElement = doc->createElement('DistanceFormat')
    ovoid = formatOptionsElement->appendChild(distanceFormatElement)
    distanceFormatNode = doc->createTextNode(self.distanceFormat)
    ovoid = distanceFormatElement->appendChild(distanceFormatNode)

    distanceDigitsElement = doc->createElement('DistanceDigits')
    ovoid = formatOptionsElement->appendChild(distanceDigitsElement)
    distanceDigitsNode = $
        doc->createTextNode( $
            string(self.distanceDigits, format='(%"%d")'))
    ovoid = distanceDigitsElement->appendChild(distanceDigitsNode)

    degreeFormatElement = doc->createElement('DegreeFormat')
    ovoid = formatOptionsElement->appendChild(degreeFormatElement)
    degreeFormatNode = doc->createTextNode(self.degreeFormat)
    ovoid = degreeFormatElement->appendChild(degreeFormatNode)

    degreeDigitsElement = doc->createElement('DegreeDigits')
    ovoid = formatOptionsElement->appendChild(degreeDigitsElement)
    degreeDigitsNode = $
        doc->createTextNode( $
            string(self.degreeDigits, format='(%"%d")'))
    ovoid = degreeDigitsElement->appendChild(degreeDigitsNode)

    latLonFormatElement = doc->createElement('LatLonFormat')
    ovoid = formatOptionsElement->appendChild(latLonFormatElement)
    latLonFormatNode = doc->createTextNode(self.latLonFormat)
    ovoid = latLonFormatElement->appendChild(latLonFormatNode)

    cdfElement = doc->createElement('Cdf')
    ovoid = formatOptionsElement->appendChild(cdfElement)
    if self.cdf eq 1b then begin

        cdfText = 'true'
    endif else begin

        cdfText = 'false'
    endelse
    cdfNode = doc->createTextNode(cdfText)
    ovoid = cdfElement->appendChild(cdfNode)

    linesPerPageElement = doc->createElement('LinesPerPage')
    ovoid = formatOptionsElement->appendChild(linesPerPageElement)
    linesPerPageNode = $
        doc->createTextNode( $
            string(self.linesPerPage, format='(%"%d")'))
    ovoid = linesPerPageElement->appendChild(linesPerPageNode)

    return, formatOptionsElement
end


;+
; Defines the SpdfFormatOptions class.
;
; @field dateFormat value indicating the format for date values
;            ('yyyy_ddd', 'yy_mm_dd', 'yy_Mmm_dd', 'yy_CMMM_dd')
; @field timeFormat value indicating the format for time values
;            ('hh_hhhh', 'hh_mm_ss', 'hh_mm')
; @field distanceFormat value indicating the format for distance values
;            ('Re', 'Km', 'IntegerKm', 'ScientificNotationKm')
; @field distanceDigits integer value specifying the number of decimal
;            digits to include when displaying distance values in
;            scientific notation.
; @field degreeFormat value indicating the format for degree values
;            ('Decimal', 'Minutes', 'MinutesSeconds')
; @field degreeDigits integer value specifying the number of decimal
;            places to include when displaying degree values.
; @field latLonFormat value indicating the format for direction/range 
;            values ('Lat90Lon360', 'Lat90Lon180', 'Lat90SnLon180We')
; @field cdf boolean value indicating whether the output should be a
;            CDF file.
; @field linesPerPage integer value indicating the number of lines per
;            page for text output.
;-
pro SpdfFormatOptions__define
    compile_opt idl2
    struct = { SpdfFormatOptions, $

        dateFormat:'yyyy_ddd', $
        timeFormat:'hh_hhhh', $
        distanceFormat:'Km', $
        distanceDigits:2, $
        degreeFormat:'Decimal', $
        degreeDigits:2, $
        latLonFormat:'Lat90Lon360', $
        cdf:0b, $
        linesPerPage:55 $
    }
end
