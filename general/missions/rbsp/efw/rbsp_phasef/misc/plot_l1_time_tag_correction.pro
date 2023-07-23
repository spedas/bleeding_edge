;+
; Plot the start and end of section.
;-

    probes = ['a','b']
    plot_dir = join_path([homedir(),'time_tag_correction'])
    margins = [12,5,10,6]
test = 0
    tplot_options, 'labflag', -1
    tplot_options, 'version', 2
    tplot_options, 'xticklen', -0.03
    tplot_options, 'yticklen', -0.02
    


    foreach probe, probes do begin
        prefix = 'rbsp'+probe+'_'
        rbsp_efw_read_l1_time_tag_correction, probe=probe
        get_data, prefix+'l1_time_tag_correction', tmp, time_ranges, corrections

        ntime_range = n_elements(time_ranges)*0.5
        for section_id=0,ntime_range-1 do begin
            section_time_range = reform(time_ranges[section_id,*])
            data_time_range = section_time_range+[-1,1]*300

            ; Plot settings.
            base_name = prefix+'_time_tag_correction_'+strjoin(time_string(section_time_range,tformat='YYYY_MMDD_hhmm'),'_')+'.pdf'
            plot_file = join_path([plot_dir,base_name])
            if keyword_set(test) then plot_file = 0
            sgopen, plot_file, xsize=6, ysize=4
            poss = sgcalcpos(2, xchsz=xchsz, ychsz=ychsz, ypad=5, margins=margins)


;            ; Load E MGSE correct.
;            rbsp_efw_read_e_mgse, data_time_range, probe=probe
;            tpos = poss[*,0]
;            the_var = prefix+'e_mgse'
;            get_data, the_var, times, data
;            data[*,0] = !values.f_nan
;            store_data, the_var, times, data
;            tplot, the_var, trange=data_time_range, position=tpos, /noerase
;            for ii=0,1 do begin
;                plot_time_range = section_time_range[ii]+[-1,1]*30
;                timebar, plot_time_range, color=sgcolor('red')
;            endfor


            ; Load E survey.
            rbsp_load_efw_waveform, probe=probe, datatype='esvy', type='raw', coord='uvw', /noclean, trange=data_time_range
            the_var = prefix+'efw_esvy'
            get_data, the_var, times, data
            data = float(data)
            data[*,2] = !values.f_nan
            store_data, the_var, times, data
            options, the_var, 'colors', constant('rgb')
            for ii=0,1 do begin
                plot_time_range = section_time_range[ii]+[-1,1]*30
                tpos = poss[*,ii]
                tplot, the_var, trange=plot_time_range, position=tpos, /noerase
                timebar, section_time_range[ii], color=sgcolor('black')
                msg = (ii eq 0)? 'a. Beginning': 'b. End'
                msg = msg+' of the section, L1 Esvy raw'
                tx = tpos[0]
                ty = tpos[3]+ychsz*0.5
                xyouts, tx,ty,/normal, msg
            endfor
            
            
            msg = 'RBSP-'+strupcase(probe)+', '+$
                strjoin(time_string(section_time_range,tformat='YYYY-MM-DD/hh:mm:ss'), ' to ')+$
                '!CCorrection to be added (sec): '+string(corrections[section_id],format='(F10.7)')
            tx = (tpos[0]+tpos[2])*0.5
            ty = 1-ychsz*2
            xyouts, tx,ty,/normal, msg, alignment=0.5
;            
;            ; Load E MGSE wrong.
;            rbsp_read_efield, data_time_range, probe=probe, resolution='survey'
;            tpos = poss[*,3]
;            the_var = prefix+'e_mgse'
;            get_data, the_var, times, data
;            data[*,0] = !values.f_nan
;            store_data, the_var, times, data
;            tplot, the_var, trange=data_time_range, position=tpos, /noerase

            if keyword_set(test) then stop
            sgclose
        endfor
    endforeach

end
