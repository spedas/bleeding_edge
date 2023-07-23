;+
; Download predicted files.
;-

function rbsp_efw_read_xxx_download_files, local_files, remote_files

    ; download settings.
    _extra = {$
        init: 1, $
        preserve_mtime: 1, $
        use_wget: 0, $
        verbose: 2}

    nfile = n_elements(local_files)
    for file_id=0,nfile-1 do begin
        url = remote_files[file_id]
        spd_download_expand, url, last_version=1, $
            ssl_verify_peer=0, ssl_verify_host=0, _extra=_extra
        if url eq '' then begin
            ; This means no file is found.
            local_files[file_id] = ''
        endif else begin
            base = file_basename(url)
            local_file = join_path([file_dirname(local_files[file_id]),base])
            tmp = spd_download_file(url=url, filename=local_file, $
                ssl_verify_peer=0, ssl_verify_host=0, _extra=_extra)
            local_files[file_id] = local_file
        endelse
    endfor
    index = where(local_files ne '', count)
    if count eq 0 then return, !null else return, local_files[index]

end
