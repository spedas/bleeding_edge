;+
; FUNCTION:
;         mms_read_pred_att_file
;
; PURPOSE:
;         Reads the ASCII predicted attitude files into IDL structures
;
;
;
;$LastChangedBy: egrimes $
;$LastChangedDate: 2015-12-10 14:31:13 -0800 (Thu, 10 Dec 2015) $
;$LastChangedRevision: 19594 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/mec_ascii/mms_read_pred_att_file.pro $
;-
function mms_read_pred_att_file, filename
    if filename eq '' then begin
        dprint, dlevel = 0, 'Error loading a attitude file - no filename given.'
        return, 0
    endif
    ; from ascii_template on a definitive attitude file
    att_template = { VERSION: 1.00000, $
        DATASTART: 32, $
        DELIMITER: 32b, $
        MISSINGVALUE: !values.D_NAN, $
        COMMENTSYMBOL: 'COMMENT', $
        FIELDCOUNT: 5, $
        FIELDTYPES: [7, 4, 4, 4, 4], $
        FIELDNAMES: ['Time', 'Elapsed', 'LRA', 'LDec', 'wtot'], $
        FIELDLOCATIONS: [0, 22, 38, 47, 55], $
        FIELDGROUPS: [0, 1, 2, 3, 4]}

    att = read_ascii(filename, template=att_template, count=num_items)

    return, att
end