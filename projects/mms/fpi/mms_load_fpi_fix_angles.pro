;+
; PROCEDURE:
;         mms_load_fpi_fix_angles
;
; PURPOSE:
;         Helper routine for setting the hard coded angles in the FPI load routine
;
; NOTE:
;         Expect this routine to be made obsolete after adding the angles to the CDF
;
;
;
;$LastChangedBy: egrimes $
;$LastChangedDate: 2016-02-24 14:52:46 -0800 (Wed, 24 Feb 2016) $
;$LastChangedRevision: 20165 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/fpi/mms_load_fpi_fix_angles.pro $
;-
pro mms_load_fpi_fix_angles, tplotnames, probe = probe, datatype = datatype, level = level, data_rate = data_rate, $
    suffix = suffix
    if undefined(suffix) then suffix = ''
    if undefined(datatype) then begin
        dprint, dlevel = 0, 'Error, must provide a datatype to mms_load_fpi_fix_angles'
        return
    endif
    if undefined(level) then begin
        dprint, dlevel = 0, 'Error, must provide a level to mms_load_fpi_fix_angles'
        return
    endif
    if undefined(probe) then probe = '1' else probe = strcompress(string(probe), /rem)
    prefix = 'mms' + probe
    
    ; in case the user passes datatype = '*'
    if (datatype[0] eq '*' || datatype[0] eq '') && level eq 'ql' then datatype=['des', 'dis']
    if (datatype[0] eq '*' || datatype[0] eq '') && level ne 'ql' then datatype=['des-dist', 'dis-dist']

    ; the following works because the FPI spectra datatypes are:
    ; QL: des, dis
    ; L1b: des-dist, dis-dist
    species_arr = strmid(datatype, 1, 1)
    
    for species_idx = 0, n_elements(species_arr)-1 do begin
        species = species_arr[species_idx]
        pad_regex = level eq 'ql' ? prefix + '_?'+species+'?_*itchAngDist_*En' : prefix + '_fpi_'+species+'PitchAngDist_*En'
        pad_regex = level eq 'l2' ? prefix + '_?'+species+'?_*itchangdist_*en_*'+suffix : pad_regex+suffix
        spectra_where = strmatch(tplotnames, pad_regex)

        fpi_angles = mms_fpi_angles(probe = probe, level = level, data_rate = data_rate, species = species, suffix = suffix)
        
        if n_elements(spectra_where) ne 0 then begin
            for var_idx = 0, n_elements(tplotnames)-1 do begin
                if spectra_where[var_idx] ne 0 then begin
                    get_data, tplotnames[var_idx], data=fpi_d, dlimits=dl
                    if is_struct(fpi_d) then begin
                        ; set some metadata before saving
                        en = strsplit(tplotnames[var_idx], '_', /extract)
                        en = en[n_elements(strsplit(tplotnames[var_idx], '_', /extract))-1]
                        options, tplotnames[var_idx], ysubtitle='[deg]'
                        ;options, tplotnames[var_idx], ytitle=strupcase(prefix)+'!C'+en+'!CPAD'
                        options, tplotnames[var_idx], ztitle='eV/(cm!U2!N s sr eV)'
                        options, tplotnames[var_idx], ystyle=1
                        zlim, tplotnames[var_idx], 0, 0, 1
                        store_data, tplotnames[var_idx], data={x: fpi_d.X, y:fpi_d.Y, v: fpi_angles}, dlimits=dl
                    endif
                endif
            endfor
        endif
    endfor
end