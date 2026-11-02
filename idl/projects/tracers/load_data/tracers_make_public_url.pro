;
function tracers_make_public_url, $
    source_remote_dir=source_remote_dir, $
    probe=probe, $
    level=level, $
    instrument=instrument, $
    datatype=datatype, $
    daily_name=daily_name
    
    case instrument of
        'magic': file_remote_path = strupcase(instrument) + '/' + strupcase('ts' + probe) + '/' + strupcase(level) + '/' + strmid(daily_name,0,4) + '/' + strmid(daily_name,4,2) + '/'
        else: file_remote_path = strupcase(level) + '/' + strupcase('ts' + probe) + '/' + strmid(daily_name,0,4) + '/' + strmid(daily_name,4,2) + '/' + strmid(daily_name,6,2) + '/' ; public
    endcase
    
    tracers_url = source_remote_dir + file_remote_path
    return, tracers_url
end