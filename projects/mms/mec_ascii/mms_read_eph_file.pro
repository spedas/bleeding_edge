;+
; FUNCTION:
;         mms_read_eph_file
;
; PURPOSE:
;         Reads the ASCII ephemeris files into IDL structures
;
;
;
;$LastChangedBy: egrimes $
;$LastChangedDate: 2015-12-10 14:31:13 -0800 (Thu, 10 Dec 2015) $
;$LastChangedRevision: 19594 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/mec_ascii/mms_read_eph_file.pro $
;-
function mms_read_eph_file, filename
    if filename eq '' then begin
        dprint, dlevel = 0, 'Error loading a attitude file - no filename given.'
        return, 0
    endif
    ; from ascii_template on a definitive attitude file
    eph_template = { VERSION: 1.00000, $
        DATASTART: 14, $
        DELIMITER: 32b, $
        MISSINGVALUE: !values.D_NAN, $
        COMMENTSYMBOL: 'COMMENT', $
        FIELDCOUNT: 9, $
        FIELDTYPES: [7, 4, 4, 4, 4, 4, 4, 4, 4], $
        FIELDNAMES: ['Time', 'Elapsed', 'x', 'y', 'z', 'vx', 'vy', 'vz', 'kg'], $
        FIELDLOCATIONS: [0, 22, 40, 62, 88, 113, 138, 162, 188], $
        FIELDGROUPS: [0, 1, 2, 3, 4, 5, 6, 7, 8]}

    ephdata = read_ascii(filename, template=eph_template, count=num_items)

    ephpos = make_array(n_elements(ephdata.x),3, /double)
    ephpos[*,0] = ephdata.x
    ephpos[*,1] = ephdata.y
    ephpos[*,2] = ephdata.z
    ephvel = make_array(n_elements(ephdata.x),3, /double)
    ephvel[*,0] = ephdata.vx
    ephvel[*,1] = ephdata.vy
    ephvel[*,2] = ephdata.vz
    eph={time:ephdata.time, pos:ephpos, vel:ephvel}

    return, eph
end