;+
; Return the valid range for certain data_type and probe.
;
; data_type. A string for the data type.
; probe=probe. A string 'a' or 'b'.
;-

function phasef_get_valid_range_string, data_type, probe=probe

    if data_type eq 'vsvy_l1' then begin
        if probe eq 'a' then begin
            return, ['2012-09-05','2019-10-15'] ; 2019-10-14 is the last day has data.
        endif else begin
            return, ['2012-09-05','2019-07-17'] ; 2019-07-16 is the last day has data.
        endelse
    endif else if data_type eq 'esvy_l1' then begin
        return, phasef_get_valid_range_string('vsvy_l1', probe=probe)
    endif else if data_type eq 'vsvy_hires' then begin
        if probe eq 'a' then begin
            return, ['2012-09-05','2019-10-13']
        endif else begin
            return, ['2012-09-05','2019-07-16']
        endelse
    endif else if data_type eq 'e_hires_uvw' then begin
        if probe eq 'a' then begin
            return, ['2012-09-13','2019-10-13']
        endif else begin
            return, ['2012-09-13','2019-07-16']
        endelse
    endif else if data_type eq 'efw_qual' then begin
        return, phasef_get_valid_range_string('vsvy_hires', probe=probe)
    endif else if data_type eq 'spice' then begin
        if probe eq 'a' then begin
            return, ['2012-09-05','2019-10-15']
        endif else begin
            return, ['2012-09-05','2019-07-17']
        endelse
    endif else if data_type eq 'spinaxis_gse' then begin
        return, phasef_get_valid_range_string('spice', probe=probe)
    endif else if data_type eq 'boom_property' then begin
        return, phasef_get_valid_range_string('spice', probe=probe)
    endif else if data_type eq 'pos_var' then begin
        return, phasef_get_valid_range_string('spice', probe=probe)
    endif else if data_type eq 'esvy_despun' then begin
        return, phasef_get_valid_range_string('vsvy_hires', probe=probe)
    endif else if data_type eq 'efw_hsk' then begin
        if probe eq 'a' then begin
            return, ['2012-09-05','2019-10-15']
        endif else begin
            return, ['2012-09-05','2019-07-17']
        endelse
    endif else if data_type eq 'e_spinfit' then begin
        return, phasef_get_valid_range_string('e_hires_uvw', probe=probe)
    endif else if data_type eq 'diag_var' then begin
        if probe eq 'a' then begin
            return, ['2012-09-05','2019-10-15']
        endif else begin
            return, ['2012-09-05','2019-07-17']
        endelse
    endif else if data_type eq 'flags_all' then begin
        return, phasef_get_valid_range_string('efw_qual', probe=probe)
    endif else if data_type eq 'spec' then begin
        if probe eq 'a' then begin
            return, ['2012-09-05','2019-10-13']
        endif else begin
            return, ['2012-09-05','2019-07-15']
        endelse
    endif else if data_type eq 'fbk' then begin
        if probe eq 'a' then begin
            return, ['2012-09-05','2019-10-13']
        endif else begin
            return, ['2012-09-05','2019-07-15']
        endelse
    endif

    return, !null
end


function phasef_get_valid_range, data_type, probe=probe
    return, time_double(phasef_get_valid_range_string(data_type, probe=probe))
end
