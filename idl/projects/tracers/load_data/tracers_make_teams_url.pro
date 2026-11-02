;
function tracers_make_teams_url, $
    source_remote_dir=source_remote_dir, $
    probe=probe, $
    level=level, $
    instrument=instrument, $
    datatype=datatype, $
    daily_name=daily_name
    
    if in_set(level,['l1a','l1b']) then begin
        file_remote_path = 'SOC' + '/' + strupcase('ts' +  probe) + '/' + strupcase(level) + '/' + strupcase(instrument) + '/' + strmid(daily_name,0,4) + '/' + strmid(daily_name,4,2) + '/' + strmid(daily_name,6,2) + '/'
    endif else begin
        case instrument of
            'aci': file_remote_path = strupcase(instrument) + '/' + 'ts' +  probe + '/' + level + '/' + instrument + '/' + strmid(daily_name,0,4) + '/' + strmid(daily_name,4,2) + '/'
            'efi': file_remote_path = strupcase(instrument) + '/' + 'ts' + probe + '/' + level + '/' + strmid(daily_name,0,4) + '/' + strmid(daily_name,4,2) + '/' + strmid(daily_name,6,2) + '/'
            'mag': file_remote_path = strupcase(instrument) + '/' + 'publish' + '/'
            'magic': file_remote_path = strupcase(instrument) + '/' + 'publish' + '/' + strupcase(probe) + '/' + strupcase(level) + '/' + strmid(daily_name,0,4) + '/' + strmid(daily_name,4,2) + '/' + strmid(daily_name,6,2) + '/'
            else: file_remote_path = strupcase(instrument) + '/' + 'ts' + probe + '/' + level + '/' + strmid(daily_name,0,4) + '/' + strmid(daily_name,4,2) + '/'
        endcase    
    endelse
    tracers_url = source_remote_dir + file_remote_path
    return, tracers_url
end

