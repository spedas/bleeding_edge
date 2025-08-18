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
; This class is the SpdfCdawebChooser's specialization of an
; SpdfCdawebChooserAuthenticator.
;
; @copyright Copyright (c) 2010-2017 United States Government as represented
;     by the National Aeronautics and Space Administration. No
;     copyright is claimed in the United States under Title 17,
;     U.S.Code. All Other Rights Reserved.
;
; @author B. Harris
;-


;+
; Creates an SpdfCdawebChooserAuthenticator object.
;
; @param groupLeader {in} {type=long}
;            widget ID of "group leader" for this authentication widget.
; @returns reference to an SpdfCdawebChooserAuthenticator object.
;-
function SpdfCdawebChooserAuthenticator::init, $
    groupLeader
    compile_opt idl2

    self.groupLeader = groupLeader

    return, self
end


;+
; Performs cleanup operations when this object is destroyed.
;-
pro SpdfCdawebChooserAuthenticator::cleanup
    compile_opt idl2

end


;+
; Obtains the user's authentication credentials to access the specified
; dataview.
;
; @param dataview {in} {type=string}
;            name of dataview requiring authentication to access.
; @param username {out} {type=string}
;            user's name.
; @param password {out} {type=string}
;            user's password.
; @returns 1 if username/password has been set.  Otherwise, 0.
;-
function SpdfCdawebChooserAuthenticator::getCredentials, $
    dataview, username, password
    compile_opt idl2

    if self->getCachedCredentials(dataview, username, password) eq 1 then return, 1


    self.tlb = widget_base(title='Authentication Required', /column, $
                  /modal, group_leader=self.groupLeader)

    usernameField = cw_field(self.tlb, title='Username')
    passwordField = cw_field(self.tlb, title='Password')

    enterButton = widget_button(self.tlb, value='Enter')
;        if (values obtained) then begin
;            save value associated with this dataview
;            return, 1
;        endif else being
;            return, 0
;        endelse

    return, 0
end


;+
; Defines the SpdfCdawebChooserAuthenticator class.
;
; @field tlb widet ID of top-level base widet.
;-
pro SpdfCdawebChooserAuthenticator__define
    compile_opt idl2
    struct = { SpdfCdawebChooserAuthenticator, $
        groupLeader:0L, $
        tlb:0L, $
        inherits SpdfAuthenticator $
    }
end
