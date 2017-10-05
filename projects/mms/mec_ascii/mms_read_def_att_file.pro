;+
; FUNCTION:
;         mms_read_def_att_file
;
; PURPOSE:
;         Reads the ASCII definitive attitude files into IDL structures
;
;
;
;$LastChangedBy: egrimes $
;$LastChangedDate: 2015-12-10 14:31:13 -0800 (Thu, 10 Dec 2015) $
;$LastChangedRevision: 19594 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/mec_ascii/mms_read_def_att_file.pro $
;-
function mms_read_def_att_file, filename
    if filename eq '' then begin
        dprint, dlevel = 0, 'Error loading a attitude file - no filename given.'
        return, 0
    endif
    ; from ascii_template on a definitive attitude file
    att_template = { VERSION: 1.00000, $
        DATASTART: 49, $
        DELIMITER: 32b, $
        MISSINGVALUE: !values.D_NAN, $
        COMMENTSYMBOL: 'COMMENT', $
        FIELDCOUNT: 21, $
        FIELDTYPES: [7, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 7], $
        FIELDNAMES: ['Time', 'Elapsed', 'q1', 'q2', 'q3', 'qc', 'wX', 'wY', 'wZ', 'wPhase', 'zRA', 'zDec', 'ZPhase', 'LRA', 'LDec', 'LPhase', 'PRA', 'PDec', 'PPhase', 'Nut', 'QF'], $
        FIELDLOCATIONS: [0, 22, 38, 47, 55, 65, 73, 80, 87, 94, 102, 111, 118, 126, 135, 142, 150, 159, 166, 176, 183], $
        FIELDGROUPS: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20]}

    att = read_ascii(filename, template=att_template, count=num_items)

    return, att
end
