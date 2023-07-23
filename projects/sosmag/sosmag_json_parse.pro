;+
; Procedure:
;  sosmag_json_parse
;
; Purpose:
;  Returns empty orderedhash if the IDL json_parse function cannot handle the string.
;
;
; Notes:
;  The SOSMAG HAPI server sometimes sends responses that are not json
;  and can cause IDL errors if not handled.
;
;
;$LastChangedBy: nikos $
;$LastChangedDate: 2022-01-07 14:03:52 -0800 (Fri, 07 Jan 2022) $
;$LastChangedRevision: 30505 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/sosmag/sosmag_json_parse.pro $
;-

function sosmag_json_parse, json_string

  emptyhash = orderedhash()

  ; If there is an error return empty hash.
  catch, Error_status
  IF Error_status NE 0 THEN BEGIN
    dprint, 'Error in sosmag_json_parse. Return empty orderedhash.'
    dprint, !ERROR_STATE.MSG
    catch, /cancel
    return, emptyhash
  ENDIF

  data_json = json_parse(json_string)

  return, data_json
end