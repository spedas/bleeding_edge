;+
; NAME: rbsp_load_collection
; SYNTAX: 
; PURPOSE: Load collection time <remote_dir>/burst_selection/rbspx_b1_rec.dat.
; INPUT:   
;	cts, out, dblarr[n,2], req. Collection times in UT second.
;   probe, in, 'a' or 'b', opt. Default is 'a'.
; OUTPUT: 
; KEYWORDS: 
; HISTORY: 2014-04-09, created by Sheng Tian, UMN
; VERSION: 
;   $LastChangedBy: aaronbreneman $
;   $LastChangedDate: 2014-04-10 08:52:58 -0700 (Thu, 10 Apr 2014) $
;   $LastChangedRevision: 14788 $
;   $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/missions/rbsp/efw/examples/rbsp_load_collection.pro $
;-

pro rbsp_load_collection, cts, probe
    on_error, 0

    rbsp_efw_init
    if n_elements(probe) eq 0 then probe = 'a' else probe = probe[0]
    sep = path_sep()

    ; update b1_rec.
    remdir = !rbsp_efw.remote_data_dir
    locdir = !rbsp_efw.local_data_dir
    dirpath = 'burst_selection'+sep

    fn = dirpath+'rbsp'+strlowcase(probe)+'_b1_rec.cdf'
    ; download the wanted files.
    fn = file_retrieve(fn, remote_data_dir = remdir, local_data_dir = locdir)

    ; collection times b/w wanted time range.
    tr = timerange() & tr = [tr[0]-86400D,tr[1]]

    ; find a rough range to read data.
    cdfid = cdf_open(fn)
    cdf_control, cdfid, variable = 'epoch', get_var_info = vinfo, /zvariable
    maxrec = vinfo.maxrec+1
    recdel = 100
    cdf_varget, cdfid, 'epoch', tmp, rec_start = 0, rec_interval = recdel, $
        rec_count = maxrec/recdel

    t0 = real_part(tmp)-62167219200D +imaginary(tmp)*1D-12 
    idx = where(t0 gt tr[0] and t0 lt tr[1], nrec)
    if nrec eq 0 then return
    rec0 = (idx[0]-1)*recdel & rec1 = (idx[nrec-1]+1)*recdel

    ; find the exact range to read data.
    nrec = rec1-rec0+1
    cdf_varget, cdfid, 'epoch', tmp, rec_start = rec0, rec_count = nrec

    t0 = real_part(tmp)-62167219200D +imaginary(tmp)*1D-12 
    idx = where(t0 ge tr[0] and t0 le tr[1], nrec)
    rec0 = idx[0] & rec1 = idx[nrec-1]
    t0 = t0[idx]
    cdf_varget, cdfid, 'B1_REC', b1rec, rec_start = rec0, rec_count = nrec
    cdf_close, cdfid

    dt = 2D*4     ; b1rec file time resolution.
    idx = where(t0[1:nrec-1]-t0[0:nrec-2] gt dt, cnt)
    cts = dblarr(cnt+1,2)
    ; start time.
    cts[0,0] = t0[0] & cts[1:cnt,0] = t0[idx+1]
    ; end time.
    cts[0:cnt-1,1] = t0[idx] & cts[cnt,1] = t0[nrec-1]
    for i = 0, 5 do print, time_string(reform(cts[i,*]))
end
