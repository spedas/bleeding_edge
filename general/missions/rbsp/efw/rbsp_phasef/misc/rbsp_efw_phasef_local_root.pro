;+
; Set the local root for saving RBSP data.
;-

function rbsp_efw_phasef_local_root

    local_root = join_path([diskdir('data'),'rbsp'])
    if file_test(local_root) eq 0 then local_root = join_path([homedir(),'data','rbsp'])
    return, local_root

end
