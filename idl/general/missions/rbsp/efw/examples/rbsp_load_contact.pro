;+
; Type: procedure.
; Purpose: Load contact time <remote_dir>/MOC_data_products/RBSPX/contact_plan'.
; Parameters:
;   cts, out, dblarr[n,2], req. Contact times in UT second.
;   probe, in, 'a' or 'b', opt. Default is 'a'.
; Keywords: none.
; Notes: none.
; Dependence: tdas.
; History:
;   2014-04-09, Sheng Tian, create.
;-
pro rbsp_load_contact, cts, probe
    on_error, 2

    rbsp_efw_init
    if n_elements(probe) eq 0 then probe = 'a' else probe = probe[0]
    sep = path_sep()

    ; find all contact files.
    remdir = !rbsp_efw.remote_data_dir
    locdir = !rbsp_efw.local_data_dir
    dirpath = 'MOC_data_products'+sep+'RBSP'+strupcase(probe)+sep+$
        'contact_plan'+sep

    file_http_copy, dirpath, links = fns, $
        localdir = locdir, serverdir = remdir

    ; get contact start times.
    nfn = n_elements(fns)
    t0s = dblarr(nfn)
    for i = 0, nfn-1 do begin
        tmp = strmid(fns[i], 6, 15)
        t0s[i] = time_double(tmp, tformat = 'YYYY_DOY_hhmmss')
    endfor

    ; choose the files in wanted time range.
    tr = timerange() & tr = [tr[0]-86400D,tr[1]]
    idx = where(t0s ge tr[0] and t0s le tr[1], cnt)
    if cnt eq 0 then return
    t0s = t0s[idx] & fns = fns[idx]

    idx = uniq(t0s)
    t0s = t0s[idx] & fns = fns[idx]
    nfn = n_elements(fns)

    ; download the wanted files.
    fns = file_retrieve(dirpath+fns, $
        remote_data_dir = remdir, local_data_dir = locdir)

    ; read the contact times.
    cts = dblarr(nfn,2)
    header = strarr(9) & tmp = ''
    for i = 0, nfn-1 do begin
        openr, lun, fns[i], /get_lun
        readf, lun, header
        readf, lun, tmp
        cts[i,0] = time_double(strmid(tmp,9,17),tformat='YYYY:DOY:hh:mm:ss')
        readf, lun, tmp
        cts[i,1] = time_double(strmid(tmp,9,17),tformat='YYYY:DOY:hh:mm:ss')
        free_lun, lun
    endfor

end
