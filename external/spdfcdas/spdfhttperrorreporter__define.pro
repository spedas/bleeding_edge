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
; Copyright (c) 2010-2021 United States Government as represented by the 
; National Aeronautics and Space Administration. No copyright is claimed 
; in the United States under Title 17, U.S.Code. All Other Rights Reserved.
;
;

;+
; This class represents an object that is used to report HTTP errors.<br>
;
; Notes:
; <ol>
;  <li>This class exists in both the CDAS and SSC web service IDL
;     libraries.  They should be kept identical to void incompatiblities
;     for clients that use both libraries simultaneously.</li>
;  <li>As of release 1.7.35 of the CDAS library the retryAfterTime field
;     and associated logic is obsolete.  The SpdfCdas class now handles
;     a 429/503 http response with a Retry-After header itself and never 
;     calls this class for those responses.  The code here has not yet been
;     deleted because of note 1 above.</li>
; </ol>
;
; @copyright Copyright (c) 2010-2021 United States Government as represented
;     by the National Aeronautics and Space Administration. No
;     copyright is claimed in the United States under Title 17,
;     U.S.Code. All Other Rights Reserved.
;
; @author B. Harris
;-


;+
; Creates an SpdfHttpErrorReporter object.
;
; @returns reference to an SpdfHttpErrorReporter object.
;-
function SpdfHttpErrorReporter::init
    compile_opt idl2

    return, self
end


;+
; Performs cleanup operations when this object is destroyed.
;-
pro SpdfHttpErrorReporter::cleanup
    compile_opt idl2

end


;+
; This procedure is called when an HTTP error occurs.  This default
; implementation merely prints some diagnostic information.
;
; @param responseCode {in} {type=int}
;            the HTTP response code of the request causing the error.
; @param responseHeader {in} {type=string}
;            the HTTP response header of the request causing the error.
; @param responseFilename {in} {type=string}
;            the name of an error response file sent when the error
;            occurred.
;-
pro SpdfHttpErrorReporter::reportError, $
    responseCode, responseHeader, responseFilename
    compile_opt idl2

    case responseCode of
        429 || 503: begin
            print, 'An HTTP 429/503 error has occurred.'
            ;
            ; Currently, SSC/CDAS never sends a date/time string (only 
            ; number of seconds to wait) in the Retry-After header.  If 
            ; it ever starts, then the following code will have to be 
            ; updated to handle that.
            ;
            retryAfter = stregex(responseHeader, $
                                 'Retry-After: ([0-9]+)' + string(13b), $
                                 /extract, /subexpr)

            if n_elements(retryAfter) eq 2 && $
               strlen(retryAfter[1]) gt 0 then begin

                self.retryAfterTime = systime(/seconds) + fix(retryAfter[1])
            endif
        end
        else: begin

            print, 'An HTTP error has occurred.'
            print, !error_state.msg
            print, 'HTTP response code = ', responseCode
            print, 'HTTP response header = ', responseHeader
            if n_elements(responseFilename) ne 0 then begin

                print, 'HTTP response filename = ', responseFilename
                self->printResponse, responseFilename
            endif
        end
    endcase
end


;+
; This procedure prints some diagnostic information from the given
; HTTP error response file.  It only recognizes the "typical" error
; response from the web services.
;
; @param responseFilename {in} {type=string}
;            the name of an error response file sent when the error
;            occurred.
;-
pro SpdfHttpErrorReporter::printResponse, $
    responseFilename
    compile_opt idl2

    if strlen(responseFilename) eq 0 then return

    print, 'HTTP Error Response'

    response = obj_new('IDLffXMLDOMDocument', filename=responseFilename)

    pElements = response->getElementsByTagName('p')

    for i = 0, pElements->getLength() - 1 do begin

        pNode = pElements->item(i)
        pAttributes = pNode->getAttributes()
        pClassAttribute = pAttributes->getNamedItem('class')

        if obj_valid(pClassAttribute) then begin

            pClassValue = pClassAttribute->getNodeValue()
            pLastChild = pNode->getLastChild()

            if obj_valid(pLastChild) then begin

                pLastChildValue = pLastChild->getNodeValue()

                print, pClassValue, ': ', pLastChildValue
            endif else begin

                print, pClassValue
            endelse
        endif
    endfor

    obj_destroy, response
end


;+
; Suspends execution until after any retryAfterTime.  If there has been
; no HTTP 429/503/RetryAfter condition or the current time is after the
; retryAfterTime, then no suspension occurs.
;-
pro SpdfHttpErrorReporter::waitUntilRetryAfterTime
    compile_opt idl2

    waitTime = self.retryAfterTime - systime(/seconds)

    if waitTime gt 0.0 then wait, waitTime

end


;+
; Gets the retryAfterTime value.
;
; @returns the number of seconds elapsed since 1970-01-01 when we can
;     retry a request following an HTTP response with status 429/503
;     and an HTTP Retry-After header value.
;-
function SpdfHttpErrorReporter::getRetryAfterTime
    compile_opt idl2

    return, self.retryAfterTime
end


;+
; Defines the SpdfHttpErrorReporter class.
;
; @field retryAfterTime number of seconds elapsed since 1970-01-01 when
;     we can retry a request following an HTTP response with status 429/503
;     and an HTTP Retry-After header value.
;-
pro SpdfHttpErrorReporter__define
    compile_opt idl2
    struct = { SpdfHttpErrorReporter, $
        retryAfterTime:0.0d $
    }
end
