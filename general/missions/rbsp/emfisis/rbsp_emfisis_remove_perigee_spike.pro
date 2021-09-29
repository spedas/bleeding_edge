;+
; Remove spikes around perigee due to mode switch.
;-

function rbsp_emfisis_remove_perigee_spike_do_work, times, b_vec

    b_mag = sqrt(total(b_vec^2,2))
    b_mag_threshold = 2500.
    index = where(b_mag ge b_mag_threshold, count)
    if count eq 0 then return, b_vec

    duration = total(minmax(times)*[-1,1])
    window = 60d    ; large enough to include spikes.
    if duration le window then return, b_vec

    time_step = total(times[0:1]*[-1,1])
    ntime = n_elements(times)
    width = window/time_step
    uts = times[0]+findgen(ceil(duration/window))*window
    nut = n_elements(uts)
    b_mag_bg = fltarr(nut-1)
    for ii=0,nut-2 do b_mag_bg[ii] = min(b_mag[where(times ge uts[ii] and times lt uts[ii+1])])
    b_mag_bg = interpol(b_mag_bg, (uts[1:nut-1]+uts[0:nut-2])*0.5, times)

    b_ratio = b_mag/b_mag_bg
    b_ratio1 = b_ratio-smooth(b_ratio, width, /nan, /edge_zero)
    b_ratio2 = b_ratio1*sqrt(b_mag_bg)    ; b_ratio1 propto r^-1.5, i.e., b^0.5
    b_ratio_threshold = stddev(b_ratio2,/nan)*1
    index = where(abs(b_ratio2) ge b_ratio_threshold, count)
    if count ne 0 then begin
        ; Fix spikes.
        flags = bytarr(ntime)
        spin_period = 12.   ; sec.
        pad_window = spin_period*2
        pad_width = pad_window/time_step
        foreach ii, index do begin
            i0 = (ii-pad_width)>0
            i1 = (ii+pad_width)<(ntime-1)
            flags[i0:i1] = 1
        endforeach
        index = where(flags eq 0)
        b_vec = sinterpol(b_vec[index,*], times[index], times)
    endif
    return, b_vec

end

pro rbsp_emfisis_remove_perigee_spike, b_var, newname=b_var_new

    get_data, b_var, times, b_vec, limits=lims
    b_vec = rbsp_emfisis_remove_perigee_spike_do_work(times, b_vec)
    if n_elements(b_var_new) eq 0 then b_var_new = b_var
    store_data, b_var_new, times, b_vec, limits=lims
end


;time_range = time_double(['2014-01-01','2014-01-02'])
;probe = 'b'
;rbsp_read_bfield, time_range, probe=probe, resolution='hires'
;prefix = 'rbsp'+probe+'_'
;rbsp_emfisis_remove_perigee_spike, prefix+'b_gsm', newname=prefix+'b_gsm2'
;end