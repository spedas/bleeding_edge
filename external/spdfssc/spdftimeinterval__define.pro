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
; Copyright (c) 2010-2013 United States Government as represented by the 
; National Aeronautics and Space Administration. No copyright is claimed 
; in the United States under Title 17, U.S.Code. All Other Rights Reserved.
;
;



;+
; This class is an IDL representation of the TimeInterval element from 
; the
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
; Creates an SpdfTimeInterval object.
;
; @param start {in} {type=string/julday}
;            start time of interval.  Value may be either an
;            <a href="http://en.wikipedia.org/wiki/ISO_8601">
;            ISO 8601</a> date/time string or a julday value.
; @param stop {in} {type=string/julday}
;            stop time of interval.  Value may be either an
;            <a href="http://en.wikipedia.org/wiki/ISO_8601">
;            ISO 8601</a> date/time string or a julday value.
; @returns reference to an SpdfTimeInterval object.
;-
function SpdfTimeInterval::init, $
    start, stop
    compile_opt idl2

    self.cdawebFormat = $
        '(I4, "/", I02, "/", I02, " ", I02, ":", I02, ":", I02)'

    self.iso8601Format = $
        '(I4, "-", I02, "-", I02, "T", I02, ":", I02, ":", I02, ".000Z")'

    self.shortIso8601Format = $
        '(I4, 1X, I2, 1X, I2, 1X, I2, 1X, I2, 1X, I2)'

    if (size(start, /type) eq 7) then begin

        self.start = self->getJulDateFromIso8601(start)
    endif else begin

        self.start = start
    endelse

    if size(stop, /type) eq 7 then begin

        self.stop = self->getJulDateFromIso8601(stop)
    endif else begin

        self.stop = stop
    endelse

    return, self
end


;+
; Performs cleanup operations when this object is destroyed.
;-
pro SpdfTimeInterval::cleanup
    compile_opt idl2

end


;+
; Get the start value.
;
; @returns julday start value.
;-
function SpdfTimeInterval::getStart
    compile_opt idl2

    return, self.start
end


;+
; Sets the start value.
;
; @param value {in} {type=julday} new value
;-
pro SpdfTimeInterval::setStart, $
    value
    compile_opt idl2

    self.start = value
end


;+
; Get the stop value.
;
; @returns julday stop value.
;-
function SpdfTimeInterval::getStop
    compile_opt idl2

    return, self.stop
end


;+
; Sets the stop value.
;
; @param value {in} {type=julday} new value
;-
pro SpdfTimeInterval::setStop, $
    value
    compile_opt idl2

    self.stop = value
end


;+
; Get the start value.
;
; @returns start value as an ISO 8601 string.
;-
function SpdfTimeInterval::getIso8601Start
    compile_opt idl2

    caldat, self.start, month, day, year, hour, minute, second

    return, string(year, month, day, hour, minute, second, $
                   format=self.iso8601Format)
end


;+
; Get the stop value.
;
; @returns stop value as an ISO 8601 string.
;-
function SpdfTimeInterval::getIso8601Stop
    compile_opt idl2

    caldat, self.stop, month, day, year, hour, minute, second

    return, string(year, month, day, hour, minute, second, $
                   format=self.iso8601Format)
end


;+
; Get the start value.
;
; @returns start value as an cdaweb format string.
;-
function SpdfTimeInterval::getCdawebStart
    compile_opt idl2

    caldat, self.start, month, day, year, hour, minute, second

    return, string(year, month, day, hour, minute, second, $
                   format=self.cdawebFormat)
end


;+
; Get the stop value.
;
; @returns stop value as an cdaweb format string.
;-
function SpdfTimeInterval::getCdawebStop
    compile_opt idl2

    caldat, self.stop, month, day, year, hour, minute, second

    return, string(year, month, day, hour, minute, second, $
                   format=self.cdawebFormat)
end


;+
; Determines if the start time is less than the stop time.
;
; @returns true if the start time is less than the stop time.
;             Otherwise false.
;-
function SpdfTimeInterval::isStartLessThanStop
    compile_opt idl2

    return, self.start lt self.stop
end


;+
; Determines if this interval is larger than one day.
;
; @returns true if this interval is larger than one day.
;              Otherwise false.
;-
function SpdfTimeInterval::isGreaterThan1Day
    compile_opt idl2

    return, (self.stop - self.start) gt 1
end


;+
; Converts the given ISO 8601 time value string into the 
; corresponding julday value.
;
; @param value {in} {type=string}
;            ISO 8601 date/time value
; @returns julday value corresponding to the given iso8601 value.
;-
function SpdfTimeInterval::getJulDateFromIso8601, $
    value
    compile_opt idl2

    iso8601 = value 

    if strlen(value) eq 10 then begin

        iso8601 = value + ' 00:00:00'
    endif 

    reads, iso8601, format=self.shortIso8601Format, $
        year, month, day, hour, minute, second

    return, julday(month, day, year, hour, minute, second)
end


;+
; Prints a textual representation of this object.
;-
pro SpdfTimeInterval::print
    compile_opt idl2

    print, 'TimeInterval: ', self->getIso8601Start(), ' to ', $
           self->getIso8601Stop()
end


;+
; Creates a TimeInterval element using the given XML DOM document with the
; values of this object.
;
; @param doc {in} {type=IDLffXMLDOMDocument}
;            document in which to create the TimeInterval element.
; @returns a reference to a new IDLffXMLDOMElement representation of
;     this object.
;-
function SpdfTimeInterval::createDomElement, $
    doc
    compile_opt idl2

    timeIntervalElement = doc->createElement('TimeInterval')
    startElement = doc->createElement('Start')
    ovoid = timeIntervalElement->appendChild(startElement)
    startTextNode = doc->createTextNode(self->getIso8601Start())
    ovoid = startElement->appendChild(startTextNode)
    endElement = doc->createElement('End')
    ovoid = timeIntervalElement->appendChild(endElement)
    endTextNode = doc->createTextNode(self->getIso8601Stop())
    ovoid = endElement->appendChild(endTextNode)

    return, timeIntervalElement
end


;+
; Defines the SpdfTimeInterval class.
;
; @field start julday start value of interval.
; @field stop julday stop value of interval.
; @field cdawebFormat constant format string for a "cdaweb" time format.
; @field iso8601Format constant format string for an ISO 8601 value.
; @field shortIso8601Format short version of a constant format string 
;            for an ISO 8601 value.
;-
pro SpdfTimeInterval__define
    compile_opt idl2
    struct = { SpdfTimeInterval, $
        start:0d, $
        stop:0d, $
        cdawebFormat:'', $
        iso8601Format:'', $
        shortIso8601Format:'' $
    }
end
