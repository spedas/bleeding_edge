;+
; Remove spin tone in RBSP data.
;-

function rbsp_remove_spintone, data, times

    time_step = total(times[0:1]*[-1,1])
    spin_period = 11d
    smooth_width = spin_period/time_step
    if smooth_width le 5 then return, data

    bg = data
    dims = size(data,/dimensions)
    if n_elements(dims) eq 1 then ndim = 1 else ndim = dims[1]
    for ii=0,ndim-1 do begin
        bg[*,ii] = smooth(data[*,ii],/nan, smooth_width)
    endfor

    return, bg
end
