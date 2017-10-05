;+
; PROCEDURE:
;         mms_load_fpi_fix_spectra
;
; PURPOSE:
;         Helper routine for setting the hard coded energies in the FPI load routine
;
; NOTE:
;         Expect this routine to be made obsolete after adding the energies to the CDF
;
;
;
;$LastChangedBy: egrimes $
;$LastChangedDate: 2016-03-16 09:33:25 -0700 (Wed, 16 Mar 2016) $
;$LastChangedRevision: 20473 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/fpi/mms_load_fpi_fix_spectra.pro $
;-
pro mms_load_fpi_fix_spectra, tplotnames, probe = probe, level = level, data_rate = data_rate, $
    datatype = datatype, suffix = suffix
    if undefined(suffix) then suffix = ''
    if undefined(datatype) then begin
        dprint, dlevel = 0, 'Error, must provide a datatype to mms_load_fpi_fix_spectra'
        return
    endif
    if undefined(level) then begin
        dprint, dlevel = 0, 'Error, must provide a level to mms_load_fpi_fix_spectra'
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
        spec_regex = level eq 'ql' ? prefix + '_?'+species+'?_*nergySpectr_*' : prefix + '_fpi_'+species+'EnergySpectr_*'
        spec_regex = level eq 'l2' ? prefix + '_?'+species+'?_*nergyspectr_*_'+data_rate+suffix : spec_regex+suffix
        spectra_where = strmatch(tplotnames, spec_regex)

        if n_elements(spectra_where) ne 0 then begin
          for var_idx = 0, n_elements(tplotnames)-1 do begin
            if spectra_where[var_idx] ne 0 then begin
              get_data, tplotnames[var_idx], data=fpi_d, dlimits=dl
              if is_struct(fpi_d) then begin
                ; set some metadata before saving
                if level eq 'sitl' || level eq 'ql' then begin
                    options, tplotnames[var_idx], ztitle='Counts'
                endif else begin
                    options, tplotnames[var_idx], ztitle='eV/(cm!U2!N s sr eV)'
                endelse
    
                ; get the direction from the variable name
                spec_pieces = strsplit(tplotnames[var_idx], '_', /extract)
                if level eq 'l2' then begin
                ; assumption here: name of the variable is:
                ; mms3_des_energyspectr_my_fast
                  part_direction = (spec_pieces)[n_elements(spec_pieces)-2]
                endif else if level eq 'sitl' then begin
                  ; assumption here: name of the variable is:
                  ; mms3_fpi_iEnergySpectr_pZ
                  part_direction = (spec_pieces)[n_elements(spec_pieces)-1]
                endif else if level eq 'ql' then begin
                  ; assumption here: name of the variable is:
                  ; mms3_dis_energySpectr_pZ
                  part_direction = (spec_pieces)[n_elements(spec_pieces)-1]
                endif
                species_str = species eq 'e' ? 'electron' : 'ion'
    
                if data_rate ne 'brst' then fpi_energies = mms_fpi_energies(species, suffix = suffix, probe=probe, level=level) $
                else fpi_energies = mms_fpi_burst_energies(species, probe, level = level, suffix = suffix)
    
              ;  options, tplotnames[var_idx], ytitle=strupcase(prefix)+'!C'+species_str+'!C'+part_direction
              ;  options, tplotnames[var_idx], ysubtitle='[eV]'
              ;  options, tplotnames[var_idx], ztitle='Counts'
                ylim, tplotnames[var_idx], 0, 0, 1
                zlim, tplotnames[var_idx], 0, 0, 1
    
                store_data, tplotnames[var_idx], data={x: fpi_d.X, y:fpi_d.Y, v: fpi_energies}, dlimits=dl
              endif
            endif
          endfor
        endif
      
    endfor
end