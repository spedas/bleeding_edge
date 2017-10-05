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
; Copyright (c) 2010-2017 United States Government as represented by the 
; National Aeronautics and Space Administration. No copyright is claimed 
; in the United States under Title 17, U.S.Code. All Other Rights Reserved.
;
;



;+
; This class is an IDL representation of the DatasetLink element from 
; the
; <a href="https://cdaweb.gsfc.nasa.gov/">Coordinated Data Analysis System</a>
; (CDAS) XML schema.
;
; @copyright Copyright (c) 2010-2017 United States Government as represented
;     by the National Aeronautics and Space Administration. No
;     copyright is claimed in the United States under Title 17,
;     U.S.Code. All Other Rights Reserved.
;
; @author B. Harris
;-


;+
; Creates an SpdfDatasetLink object.
;
; @param title {in} {type=string}
;            link title value.
; @param text {in} {type=string}
;            link text value.
; @param url {in} {type=string}
;            link URL value.
; @returns reference to an SpdfDatasetLink object.
;-
function SpdfDatasetLink::init, $
    title, text, url
    compile_opt idl2

    self.title = title
    self.text = text
    self.url = url

    return, self
end


;+
; Performs cleanup operations when this object is destroyed.
;-
pro SpdfDatasetLink::cleanup
    compile_opt idl2

end


;+
; Gets the title value.
;
; @returns title value.
;-
function SpdfDatasetLink::getTitle
    compile_opt idl2

    return, self.title
end


;+
; Gets the text value.
;
; @returns text value.
;-
function SpdfDatasetLink::getText
    compile_opt idl2

    return, self.text
end


;+
; Gets the URL value.
;
; @returns URL value.
;-
function SpdfDatasetLink::getUrl
    compile_opt idl2

    return, self.url
end


;+
; Prints a textual representation of this object.
;-
pro SpdfDatasetLink::print
    compile_opt idl2

    print, 'title: ', self.title
    print, 'text: ', self.text
    print, 'url: ', self.url
end


;+
; Defines the SpdfDatasetLink class.
;
; @field title link title value.
; @field text link text value.
; @field url link URL value.
;-
pro SpdfDatasetLink__define
    compile_opt idl2
    struct = { SpdfDatasetLink, $
        title:'', $
        text:'', $
        url:'' $
    }
end
