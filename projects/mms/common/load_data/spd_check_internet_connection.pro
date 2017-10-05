;+
; FUNCTION:
;     spd_check_internet_connection
;         
; PURPOSE:
;     check the local internet connection by connecting to Google's homepage; this
;     is so we don't prompt the user for a password if they're sitting in
;     the airport without an internet connection...
;         
; 
;$LastChangedBy: egrimes $
;$LastChangedDate: 2015-12-10 14:33:38 -0800 (Thu, 10 Dec 2015) $
;$LastChangedRevision: 19596 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/common/load_data/spd_check_internet_connection.pro $
;-

function spd_check_internet_connection
    catch, error_status
    if error_status ne 0 then begin
        catch, /cancel
        dprint, dlevel = 0, 'Couldn''t connect to the network.'
        return, -1
    endif
    dummy_obj = obj_new('IDLnetURL', url_host='google.com', url_port=80)
    dummy_get = dummy_obj->get()
    dummy_obj->GetProperty, RESPONSE_CODE=response_code
    obj_destroy, dummy_obj
    return, response_code
end