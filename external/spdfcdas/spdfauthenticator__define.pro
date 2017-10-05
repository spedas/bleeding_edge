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
; This class represents an object that knows how to obtain authentication
; for the
; <a href="https://cdaweb.gsfc.nasa.gov/">Coordinated Data Analysis System</a>
; (CDAS).  Usually, it will do this by prompting the user for information.
;
; @copyright Copyright (c) 2010-2017 United States Government as represented
;     by the National Aeronautics and Space Administration. No
;     copyright is claimed in the United States under Title 17,
;     U.S.Code. All Other Rights Reserved.
;
; @author B. Harris
;-


;+
; Creates an SpdfAuthenticator object.
;
; @returns reference to an SpdfAuthenticator object.
;-
function SpdfAuthenticator::init
    compile_opt idl2

    return, self
end


;+
; Performs cleanup operations when this object is destroyed.
;-
pro SpdfAuthenticator::cleanup
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
function SpdfAuthenticator::getCredentials, $
    dataview, username, password
    compile_opt idl2

    if self->getCachedCredentials(dataview, username, password) eq 1 then return, 1


    print, dataview, ' requires authentication'
    read, username, prompt='Enter your username: '
    read, password, prompt='Enter your password: '

    status = self->cacheCredentials(dataview, username, password)

    return, 1
end


;+
; Gets the cached credentials for the specified dataview.
; @private
;
; @param dataview {in} {type=string}
;            name of dataview requiring authentication to access.
; @param username {out} {type=string}
;            user's name.
; @param password {out} {type=string}
;            user's password.
; @returns 1 if username/password has been set.  Otherwise, 0.
;-
function SpdfAuthenticator::getCachedCredentials, $
    dataview, username, password
    compile_opt idl2

    i = where(self.dataviewCache eq dataview, count)

    if count eq 1 then begin

        username = self.credentialsCache[i[0], 0]
        password = self.credentialsCache[i[0], 1]
        return, 1
    endif

    return, 0
end
   

;+
; Stores the given credentials for the specified dataview in the cache.
; @private
;
; @param dataview {in} {type=string}
;            name of dataview requiring authentication to access.
; @param username {in} {type=string}
;            user's name.
; @param password {in} {type=string}
;            user's password.
; @returns 1 if credentials  have been cached.  Otherwise, 0.
;-
function SpdfAuthenticator::cacheCredentials, $
    dataview, username, password
    compile_opt idl2

    i = where(self.dataviewCache eq dataview, count)

    case count of
        0: return, self->addToCachedCredentials(dataview, username, password)
        1: begin
            self.credentialsCache[i[0], 0] = username
            self.credentialsCache[i[0], 1] = password
            return, 1
           end
    endcase

    return, 0
end
   

;+
; Adds the given credentials for the specified dataview to the cache.
; @private
;
; @param dataview {in} {type=string}
;            name of dataview requiring authentication to access.
; @param username {in} {type=string}
;            user's name.
; @param password {in} {type=string}
;            user's password.
; @returns 1 if credentials  have been cached.  Otherwise, 0.
;-
function SpdfAuthenticator::addToCachedCredentials, $
    dataview, username, password
    compile_opt idl2

    i = where(self.dataviewCache eq '', count)

    if count gt 0 then begin

        self.dataviewCache[i[0]] = dataview
        self.credentialsCache[i[0], 0] = username
        self.credentialsCache[i[0], 1] = password

        return, 1
    endif

    return, 0
end
   

;+
; Defines the SpdfAuthenticator class.
;
; @field dataviewCache cache of dataview names.  A dataview's index in
;            this array corresponds to its authentication credentials
;            in the credentialsCaches.  For example, if 
;            dataviewCache[5] = 'dv1', then the authenticaion credentials
;            for 'dv1' are credentialsCache[5, 0] and 
;            credentialsCache[5, 1].
; @field credentialsCache cache of authentication credentials.
;-
pro SpdfAuthenticator__define
    compile_opt idl2
    struct = { SpdfAuthenticator, $
        dataviewCache:strarr(10), $
        credentialsCache:strarr(10, 2) $
    }
end
