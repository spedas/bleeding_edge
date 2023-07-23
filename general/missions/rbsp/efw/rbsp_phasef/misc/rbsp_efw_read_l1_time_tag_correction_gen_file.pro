;+
; Write the start and end time of sections shifted in time tag, and the wanted correction.
; To correct: read data in the time range, add the correction to the old_times:
;   new_times = old_times+correction
;-

pro rbsp_efw_read_l1_time_tag_correction_gen_file, probe=probe

    info = [$
        'A', '2014-01-05/12:42:34.450798','2014-01-05/13:27:05.419235', $
        'A', '2014-04-23/18:17:28.683166','2014-04-23/18:57:11.651718', $
        'A', '2014-04-24/15:26:31.677452','2014-04-24/16:06:46.645874', $
        'A', '2014-05-22/06:31:51.498458','2014-05-22/07:10:14.466918', $
        'A', '2014-06-16/00:00:07.590774','2014-06-16/04:52:24.342498', $
        'A', '2014-06-20/00:00:02.727035','2014-06-20/08:09:23.317199', $
        'A', '2014-07-08/07:28:46.208732','2014-07-08/08:05:33.177345', $
        'A', '2014-07-09/03:09:01.203872','2014-07-09/03:46:20.172317', $
        'A', '2014-07-09/22:55:24.198844','2014-07-09/23:32:43.167533', $
        'A', '2014-07-11/14:26:34.189186','2014-07-11/15:03:05.157585', $
        'A', '2016-08-09/23:59:51.192207','2016-08-10/00:36:22.160964', $
        'A', '2016-10-19/08:28:43.235839','2016-10-19/09:02:34.204597', $
        'A', '2016-10-20/01:57:14.236579','2016-10-20/02:31:05.205253', $
        'A', '2016-10-20/19:27:37.236976','2016-10-20/20:00:56.205871', $
        'A', '2016-10-21/12:57:28.237754','2016-10-21/13:30:15.206344', $
        'A', '2016-10-22/06:26:47.238235','2016-10-22/06:58:46.207061', $
        'A', '2016-10-22/23:55:50.238731','2016-10-23/00:00:05.234603', $
        'A', '2016-10-29/13:22:21.244438','2016-10-29/13:55:24.213134', $
        'A', '2016-11-02/05:12:40.247650','2016-11-02/05:47:03.216316', $
        'A', '2016-11-02/22:52:07.248321','2016-11-02/23:27:34.217048', $
        'A', '2016-11-11/07:29:00.256393','2016-11-11/08:04:11.225013', $
        'A', '2016-11-14/22:25:12.260253','2016-11-14/23:13:43.228935', $
        'A', '2016-11-20/00:00:04.239898','2016-11-20/00:09:07.235038', $
        'A', '2016-11-21/06:48:35.267776','2016-11-21/07:49:22.236633', $
        'A', '2016-11-24/02:32:49.271362','2016-11-24/03:41:36.240249', $
        'A', '2019-06-06/00:00:29.803977','2019-06-06/00:03:40.801582', $
        'B', '2014-04-22/19:58:55.036964','2014-04-22/22:49:02.060295', $
        'B', '2014-06-15/00:00:21.690292','2014-06-18/00:00:23.089233', $
        'B', '2016-04-07/23:58:59.704216','2016-04-08/02:10:10.728927']

    ndim = 3
    nrec = n_elements(info)/ndim
    infos = transpose(reform(info, ndim,nrec))
    tformat = 'YYYY-MM-DD/hh:mm:ss.ffffff'
    time_step = 1d/32
    tab = '    '
    log_file = join_path([homedir(),'rbsp_l1_shifted_section_info.txt'])
    if file_test(log_file) eq 1 then file_delete, log_file
    ftouch, log_file
    for ii=0,nrec-1 do begin
        the_info = reform(infos[ii,*])
        probe = strlowcase(the_info[0])
        prefix = 'rbsp'+probe+'_'
        time_range = time_double(the_info[1:2],tformat=tformat)
        the_time_range = time_range[1]+[-1,1]*60
        rbsp_load_efw_waveform, probe=probe, datatype='esvy', type='raw', coord='uvw', /noclean, trange=the_time_range
        evar = prefix+'efw_esvy'
        data = get_var_data(evar, times=times, in=the_time_range)
        dtimes = times[1:-1]-times[0:-2]
        index = where(round(abs(dtimes)) eq 1, count)
        if count eq 0 then message, 'Inconsistency ...'
        dtime = times[index+1]-times[index]-time_step
        the_info = [the_info,string(dtime,format='(F10.7)')]
        the_info[0] = strlowcase(the_info[0])
        lprmsg, strjoin(the_info,tab), log_file
    endfor
    stop

end
