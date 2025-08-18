;+
; Read the times when time tags are shifted backward in time by about 1 sec. These times are probably leap second corrections.
;
; The tplot_var is 'rbspx_l1_time_tag_leap_second'.
;-

pro rbsp_efw_read_l1_time_tag_leap_second, probe=probe

    info = [$
        'a', '2015-07-01/00:00:01.785919', $
        'a', '2017-01-01/00:00:06.126586', $
        'b', '2015-07-01/00:00:00.522552', $
        'b', '2017-01-01/00:00:02.134918']

    ndim = 2
    nrec = n_elements(info)/ndim
    infos = transpose(reform(info, ndim,nrec))

    index = where(infos[*,0] eq probe, nrec)
    infos = infos[index,*]

    tformat = 'YYYY-MM-DD/hh:mm:ss.ffffff'
    times = time_double(infos[*,1], tformat=tformat)

    prefix = 'rbsp'+probe+'_'
    var = prefix+'l1_time_tag_leap_second'
    store_data, var, times, times

end