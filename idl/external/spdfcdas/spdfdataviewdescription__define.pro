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
; This class is an IDL representation of the DataviewDescription 
; element from the
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
; Creates an SpdfDataviewDescription object.
;
; @param id {in} {type=string}
;            dataview identifier.
; @param endpointAddress {in} {type=string}
;            URL to access this dataview.
; @param title {in} {type=string}
;            title of dataview.
; @param subtitle {in} {type=string}
;            sub-title of dataview.
; @param overview {in} {type=string}
;            overview description of this dataview.
; @param underConstruction {in} {type=byte}
;            indicates whether the dataview is in the process of being
;            constructed.
; @param noticeUrl {in} {type=string}
;            URL of notice concerning this dataview.
;            constructed.
; @param publicAccess {in} {type=byte}
;            indicates whether the dataview requires authentication
;            to access.
; @returns reference to an SpdfDataviewDescription object.
;-
function SpdfDataviewDescription::init, $
    id, endpointAddress, title, subtitle, overview, $
    underConstruction, noticeUrl, publicAccess
    compile_opt idl2

    self.id = id
    self.endpointAddress = endpointAddress
    self.title = title
    self.subtitle = subtitle
    self.overview = overview
    self.underConstruction = underConstruction
    self.noticeUrl = noticeUrl
    self.publicAccess = publicAccess

    return, self
end


;+
; Gets the identifier.
;
; @returns identifier value.
;-
function SpdfDataviewDescription::getId
    compile_opt idl2

    return, self.id
end


;+
; Gets the endpointAddress.
;
; @returns endpointAddress value.
;-
function SpdfDataviewDescription::getEndpointAddress
    compile_opt idl2

    return, self.endpointAddress
end


;+
; Gets the title.
;
; @returns title value.
;-
function SpdfDataviewDescription::getTitle
    compile_opt idl2

    return, self.title
end


;+
; Gets the sub-title.
;
; @returns sub-title value.
;-
function SpdfDataviewDescription::getSubtitle
    compile_opt idl2

    return, self.subtitle
end


;+
; Gets the overview description.
;
; @returns overview value
;-
function SpdfDataviewDescription::getOverview
    compile_opt idl2

    return, self.overview
end


;+
; Gets the underConstruction flag.
;
; @returns underConstruction value.
;-
function SpdfDataviewDescription::getUnderConstruction
    compile_opt idl2

    return, self.underConstruction
end


;+
; Gets the notice URL.
;
; @returns notice URL value.
;-
function SpdfDataviewDescription::getNoticeUrl
    compile_opt idl2

    return, self.noticeUrl
end


;+
; Gets the public-access flag.
;
; @returns public-access value.
;-
function SpdfDataviewDescription::getPublicAccess
    compile_opt idl2

    return, self.publicAccess
end


;+
; Prints a textual representation of this object.
;-
pro SpdfDataviewDescription::print
    compile_opt idl2

    print, 'id: ', self.id
    print, '  endpointAddress: ', self.endpointAddress
    print, '  title: ', self.title
    print, '  subtitle: ', self.subtitle
    print, '  overview: ', self.overview
    print, '  underConstruction: ', self.underConstruction
    print, '  noticeUrl: ', self.noticeUrl
    print, '  publicAccess: ', self.publicAccess

end


;+
; Defines the SpdfDataviewDescription class.
;
; @field id identifier.
; @field endpointAddress access URL.
; @field title title.
; @field subtitle sub-title.
; @field overview overview description.
; @field underConstruction under-construction flag.
; @field noticeUrl URL of notice.
; @field publicAccess public-access flag.
;-
pro SpdfDataviewDescription__define
    compile_opt idl2
    struct = { SpdfDataviewDescription, $
        id:'', $
        endpointAddress:'', $
        title:'', $
        subtitle:'', $
        overview:'', $
        underConstruction:0b, $
        noticeUrl:'', $
        publicAccess:1b $
    }
end
