;+
; PROCEDURE:
;         spd_smooth_time
;
; PURPOSE:
;         Smooths a tplot variable in time using a simple boxcar average
;         This routine is essentially just a wrapper around the IDL smooth
;         function that allows the /NAN keyword, unlike tsmooth_in_time
;
; KEYWORDS:
;        newname: name of the tplot variable to store the data in; default is input_name+"_smth"
;        nan: ignore NaNs in the input (treat as missing data)
;
;
;
;$LastChangedBy: egrimes $
;$LastChangedDate: 2017-07-27 09:01:57 -0700 (Thu, 27 Jul 2017) $
;$LastChangedRevision: 23712 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas_gui/utilities/spd_smooth_time.pro $
;-


Function spd_temp_dtx_test, dtx0, min_dtx_fraction = min_dtx_fraction, _extra = _extra
    ; Function to get an effective minimum value for dtx, this will reject
    ; any negative or unduly small values, that show up fewer times than
    ; min_dtx_fraction (default is 0.10) times the peak value
    ;No zero values are allowed
    If(keyword_set(min_dtx_fraction)) Then mf = min_dtx_fraction Else mf = 0.10
    xxx = where(dtx0 Gt 0)
    If(xxx[0] Eq -1) Then Return, 1.0 ;you've got troubles
    ;Get a histogram of log(dtx)
    dtx = alog10(dtx0[xxx])       ;bin in orders of magnitude
    minv = double(long(min(dtx)))-1.0d0
    maxv = double(long(max(dtx)))+1.0d0 ;note that there should always be 3 bins
    h = histogram(dtx, min = minv, max = maxv, binsize = 1.0)
    edges = minv+findgen(n_elements(h)+1)
    lowest_reasonable_bin = min(where(h Ge mf*max(h)))
    otp = min(dtx[where(dtx Ge edges[lowest_reasonable_bin])])
    otp = 10.0^otp
    Return, otp
End

pro spd_smooth_time, tname, dt, newname=newname, nan=nan
    if undefined(newname) then newname = tname + '_smth'
    
    get_data, tname, data=d, dlimits=dl, limits=l
    
    ; the following was heisted from smooth_in_time, 3/24/17
    tx = d.X
    dtx = tx[1:*]-tx
    bad_dtx = where(dtx Le 0.0, nbad_dtx)
    If(nbad_dtx Gt 0) Then Begin ;sort the data
        dprint, 'Data is non-monotonic, Sorting...', display_object=display_object
        ss_tx = sort(tx)
        tx = tx[ss_tx]
    ;    ax = ax[ss_tx]
        dtx = tx[1:*]-tx
    Endif
    dtx0 = spd_temp_dtx_test(dtx, _extra = _extra)
    dtx0 = dtx0[0] ;needs to be scalar

    ;          dtx0 = min(dtx[where(dtx Gt 0.0)]) ;min value of t resolution
    not_min = where(abs(dtx-dtx0) Gt dtx0/100.0, cnot_min) ;small allowance
    nrv = ceil(dt/dtx0)
    ;Note that for non-forward or backwards, this value must be an odd
    ;number gt 3
    If(nrv Lt 3) Then begin
        dprint, 'Number of smoothing points is LT 3, Smoothing over 3*minimum resolution', display_object=display_object
    endif
    nrv = nrv > 3
    If(nrv Mod 2 Eq 0) Then Begin
        dprint, 'Even number of smoothing points:'+strcompress(string(nrv))+', Adding 1', display_object=display_object
        nrv = nrv+1
    Endif

    out = dblarr(n_elements(d.x), n_elements(d.Y[0, *]))
    for var_idx = 0, n_elements(d.Y[0, *])-1 do begin
        out[*, var_idx] = smooth(reform(d.Y[*, var_idx]), nrv, nan=nan, /edge_truncate)
    endfor
    if tag_exist(d, 'v') then $
      store_data, newname, data={x: d.x, y: out, v: d.v}, dlimits=dl, limits=l $
    else $
      store_data, newname, data={x: d.x, y: out}, dlimits=dl, limits=l
end



