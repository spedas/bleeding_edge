;+
; Split a vb1 file into several files per hour.
;
; This file should be used by EFW to batch process the data over the whole mission.
;-

pro rbsp_efw_phasef_gen_l1_vb1_split, file, split_cadence=split_cadence, $
    in_local_root=in_local_root, out_local_root=out_local_root

    if n_elements(split_cadence) eq 0 then split_cadence = 15*60.

    if file_test(file) eq 0 then return
	print, 'Split file '+file+' ...'
    path = file_dirname(file)
    pos = strpos(path,'vb1')
    path = strmid(path,0,pos)+'vb1_split'+strmid(path,pos+3)

    ; Replace the root dir.
    if n_elements(out_local_root) ne 0 and n_elements(in_local_root) ne 0 then begin
        pos = strpos(path,in_local_root)
        if pos[0] ne -1 then begin
            path = out_local_root+strmid(path,pos+strlen(in_local_root))
        endif
    endif


    base = file_basename(file)
    probe = strmid(base,4,1)
    rbspx = 'rbsp'+probe
    prefix = 'rbsp'+probe+'_'

;---Read global and variable attributes and time range.
    time_var = 'epoch'
    b1_var = 'vb1'
    other_vars = ['vb1_labl','vb1_unit','vb1_compno']

    finfo = file_info(file)
    if finfo.size eq 0 then begin
        errmsg = 'Invalid input file ...'
        return
    endif
    cdf_id = cdf_open(file)
    gatt = cdf_read_setting(filename=cdf_id)
    epoch_att = cdf_read_setting(time_var, filename=cdf_id)
    b1_att = cdf_read_setting(b1_var, filename=cdf_id)
    times = cdf_read_var(time_var, filename=cdf_id)

    other_data = list()
    other_vatt = list()
    foreach var, other_vars do begin
        other_data.add, cdf_read_var(var, filename=cdf_id)
        other_vatt.add, cdf_read_setting(var, filename=cdf_id)
    endforeach
    cdf_close, cdf_id

    ; Read time_range.
    ;cdf_control, cdf_id, variable=time_var, get_var_info=varinfo
    ;maxrec = varinfo.maxrec
    ;epoch_range = [$
    ;    cdf_read_var(time_var, filename=cdf_id, range=[0,0]), $
    ;    cdf_read_var(time_var, filename=cdf_id, range=maxrec+[0,0])]
    ;cdf_close, cdf_id
    if n_elements(times) eq 0 then begin
        errmsg = 'No data ...'
        return
    endif
    times = convert_time(times, from='epoch16', to='unix')
    time_range = minmax(times)
    file_times = break_down_times(time_range, split_cadence)

;---Loop through the file_times, in each loop only read a portion of the data.
    foreach file_time, file_times do begin
        ; Determine the path and filename of the output file.
        the_path = path
        str_year = time_string(file_time,tformat='YYYY')
        pos = strpos(the_path,str_year)
        the_path = strmid(the_path,0,pos)+str_year+strmid(the_path,pos+4)
        split_base = apply_time_to_pattern(prefix+'l1_vb1_%Y%m%d_%H%M_v02.cdf', file_time)
        if file_test(the_path,/directory) eq 0 then file_mkdir, the_path
        split_file = join_path([the_path,split_base])

        ; Read data.
        the_time_range = file_time+[0,split_cadence]
        time_index = lazy_where(times,'[)', the_time_range, count=count)
        if count lt 2 then continue
        rec_range = minmax(time_index)
        cdf_id = cdf_open(file)
        the_epoch = cdf_read_var(time_var, filename=cdf_id, range=rec_range)
        the_data = cdf_read_var(b1_var, filename=cdf_id, range=rec_range)
        cdf_close, cdf_id

        ; Save the data to the output file.
		print, 'Saving split file to '+split_file+' ...'
		if file_test(split_file) eq 1 then begin
		    ; Data from a previous day can extend into the next day.
	        pre_epoch = cdf_read_var(time_var, filename=split_file)
		    pre_data = cdf_read_var(b1_var, filename=split_file)
		endif else begin
		    pre_epoch = []
		    pre_data = []
		endelse

		; Avoid writing the same data twice.
		if n_elements(pre_epoch) eq n_elements(the_epoch) then begin
		    diff = the_epoch-pre_epoch
		    if total(abs(diff)) eq 0 then begin
		        print, 'Data already saved, skip ...'
		        continue
		    endif
		endif

		; Make sure time is mono-increasing.
		epoch = [pre_epoch,the_epoch]
		data = [pre_data,the_data]
		the_times = convert_time(epoch, from='epoch16', to='unix')
		index = uniq(the_times, sort(the_times))
		the_times = the_times[index]
		epoch = epoch[index]
		data = data[index,*]
		print, 'Saving data from '+strjoin(time_string(minmax(the_times)), ' to ')+' ...'
        cdf_save_setting, gatt, filename=split_file
        cdf_save_var, time_var, filename=split_file, value=epoch, cdf_type='CDF_LONG_EPOCH'
        cdf_save_setting, epoch_att, filename=split_file, varname=time_var
        cdf_save_var, b1_var, filename=split_file, value=data, cdf_type='CDF_INT2'
        cdf_save_setting, b1_att, filename=split_file, varname=b1_var

        foreach var, other_vars do begin
            data = cdf_read_var(var, filename=file)
            att = cdf_read_setting(var, filename=file)
            cdf_save_var, var, filename=split_file, value=data, save_as_one=1
            cdf_save_setting, att, filename=split_file, varname=var
        endforeach
    endforeach


end



; Settings on m472e, need to download all B1 data first.
spawn, 'hostname', host
case host of
    'm472e.space.umn.edu': begin
        in_local_root = '/Volumes/data/rbsp'
        out_local_root = in_local_root
        end
    'xwaves7.space.umn.edu': begin
        in_local_root = '/Volumes/DataA/RBSP/data/rbsp'
        out_local_root = '/Volumes/UserA/user_volumes/kersten/data_external/rbsp'
        end
endcase
probes = ['a','b']
years = string(make_bins([2012,2019],1),format='(I04)')


; This program only needs to be run once !!!
stop
foreach probe, probes do begin
    rbspx = 'rbsp'+probe
	; The program often breaks, so use this to skip dates are done.
    ;if probe eq 'a' then start_date = '2014-04-12' else start_date = '2012-01-01'
    if probe eq 'a' then start_date = '2012-01-01' else start_date = '2012-01-01'
	start_date = time_double(start_date)

    foreach year, years do begin
        path = in_local_root+'/'+rbspx+'/l1/vb1/'+year
        files = file_search(path+'/*_v02.cdf')
        foreach file, files do begin
			; Check file date.
			base = file_basename(file)
			file_time = time_double(strmid(base,13,8),tformat='YYYYMMDD')
			if file_time lt start_date then continue

			rbsp_efw_phasef_gen_l1_vb1_split, file, $
				in_local_root=in_local_root, out_local_root=out_local_root
		endforeach
    endforeach
endforeach

stop


; less than 1 hour of data.
file = '/Volumes/data/rbsp/rbspa/l1/vb1/2013/rbspa_l1_vb1_20130110_v02.cdf'
; more than 1 hour of data.
file = '/Volumes/data/rbsp/rbspa/l1/vb1/2013/rbspa_l1_vb1_20130128_v02.cdf'
; Stops here.
;file = '/Volumes/data/rbsp/rbspb/l1/vb1/2019/rbspb_l1_vb1_20190401_v02.cdf'
rbsp_efw_phasef_gen_l1_vb1_split, file
end
