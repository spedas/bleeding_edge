; 
function tracers_make_spdf_url, $
    source_remote_dir=source_remote_dir, $
    probe=probe, $
    level=level, $
    instrument=instrument, $
    datatype=datatype, $
    daily_name=daily_name
    
    instrument_dir = instrument
    datatype_dir = datatype
    case instrument of
        'ace': begin
            instrument_dir = instrument + '_cusp-electrons'
            if datatype eq 'def' then datatype_dir = 'def_diff-en-flux'
            if datatype eq 'pitch-angle-dist' then datatype_dir = 'def_pitch-angle-dist'
        end
        'aci': begin
            instrument_dir = instrument + '_cusp-ions'
            if datatype eq 'ipd' then datatype_dir = 'ipd_ion-dist'
        end
        'efi': begin
            if datatype eq 'ehf' then datatype_dir = 'highfrequency'
        end
        'msc': begin
            instrument_dir = instrument + '_searchcoil'
        end
        else: begin
            instrument_dir = instrument
            datatype_dir = datatype
        end
    endcase
    tracers_url = source_remote_dir + 'tracers' + probe + '/' + instrument_dir + '/' + level + '/' + datatype_dir + '/' + strmid(daily_name,0,4) + '/'
    return, tracers_url
end

