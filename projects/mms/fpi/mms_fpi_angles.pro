;+
; PROCEDURE:
;         mms_fpi_angles
;
; PURPOSE:
;         Returns the hard coded angles for the SITL FS FPI pitch angle distributions
;
; NOTE:
;         Expect this routine to be made obsolete after adding the angles to the CDF
; 
;
;
;$LastChangedBy: egrimes $
;$LastChangedDate: 2016-02-24 14:52:46 -0800 (Wed, 24 Feb 2016) $
;$LastChangedRevision: 20165 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/fpi/mms_fpi_angles.pro $
;-
function mms_fpi_angles, probe = probe, level = level, data_rate = data_rate, species = species, suffix = suffix
    if undefined(suffix) then suffix = ''
    if ~undefined(level) && level eq 'l2' then begin
        get_data, 'mms'+strcompress(string(probe), /rem)+'_d'+species+'s_alpha_'+data_rate+suffix, data=alpha_data
        if is_struct(alpha_data) then return, alpha_data.Y
        
        dprint, dlevel = 0, 'Error finding the variable containing the angles for PAD; defaulting to hard-coded values'
    endif
    
    ; fall back to the hard coded values 
    return, [0,6,12,18, $
        24,30,36,42,48,54,60,66,72,78,84,90,96,102, $
        108,114,120,126,132,138,144,150,156,162,168,174] + 3
end