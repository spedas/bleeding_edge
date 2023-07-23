;+
; Construct and return remote paths.
;-

function rbsp_efw_remote_sub_dirs, level=level, datatype=datatype


    if level eq 'l3' then begin
        sub_dirs = ['YYYY']
    endif else begin
        sub_dirs = [datatype,'YYYY']
    endelse

    remote_root = rbsp_efw_remote_root()
    is_cdaweb = remote_root eq 'https://cdaweb.gsfc.nasa.gov/pub/data/rbsp'
    path = is_cdaweb? [level,'efw',sub_dirs]: [level,sub_dirs]
    return, path

end
