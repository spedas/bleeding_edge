;+
; The B field related quantites are incorrect.
;
; This is now fixed in rbsp_efw_read_l4_gen_file.
; It's too slow to run that, so we only run the code for B field over.
;-

probes = ['a','b']
root_dir = join_path([default_local_root(),'rbsp'])
foreach probe, probes do begin
    prefix = 'rbsp'+probe+'_'
    rbspx = 'rbsp'+probe
    time_range = (probe eq 'a')? time_double(['2012-09-08','2019-10-14']): time_double(['2012-09-08','2019-07-16'])
    days = make_bins(time_range, constant('secofday'))
    foreach day, days do begin
        str_year = time_string(day,tformat='YYYY')
        path = join_path([root_dir,rbspx,'level4',str_year])
        base = prefix+'efw-l4_'+time_string(day,tformat='YYYYMMDD')+'_v02.cdf'
        file = join_path([path,base])
        if file_test(file) eq 0 then rbsp_efw_read_l4_gen_file, day, probe=probe, filename=file

        cdf_load_var, 'bfield_mgse', filename=file, time_var='epoch', time_type='epoch16'
        get_data, 'bfield_mgse', common_times, b_mgse
        ncommon_time = n_elements(common_times)
        ndim = 3

        re1 = 1d/6378
        r_gse = cdf_read_var('position_gse', filename=file)*re1
        rgsm = cotran(r_gse, common_times, 'gse2gsm')
        par = 2

        b_t89_gsm = fltarr(ncommon_time,ndim)
        b_igrf_gsm = fltarr(ncommon_time,ndim)
        foreach time, common_times, time_id do begin
            tilt = geopack_recalc(time)
            rx = rgsm[time_id,0]
            ry = rgsm[time_id,1]
            rz = rgsm[time_id,2]

            geopack_igrf_gsm, rx,ry,rz, bx,by,bz
            geopack_t89, par, rx,ry,rz, dbx,dby,dbz
            b_igrf_gsm[time_id,*] = [bx,by,bz]
            b_t89_gsm[time_id,*] = b_igrf_gsm[time_id,*]+[dbx,dby,dbz]
        endforeach
        b_t89_mgse = cotran(b_t89_gsm, common_times, 'gsm2mgse', probe=probe)
        b_igrf_mgse = cotran(b_igrf_gsm, common_times, 'gsm2mgse', probe=probe)
        db_t89_mgse = b_t89_mgse-b_mgse
        db_igrf_mgse = b_igrf_mgse-b_mgse
        b_mag = snorm(b_mgse)
        db_t89_mag = snorm(b_t89_mgse)-b_mag
        db_igrf_mag = snorm(b_igrf_mgse)-b_mag

        cdfid = cdf_open(file)
        cdf_varput, cdfid, 'bfield_model_mgse_t89', transpose(b_t89_mgse)
        cdf_varput, cdfid, 'bfield_model_mgse_igrf', transpose(b_igrf_mgse)
        cdf_varput, cdfid, 'bfield_minus_model_mgse_t89', transpose(db_t89_mgse)
        cdf_varput, cdfid, 'bfield_minus_model_mgse_igrf', transpose(db_igrf_mgse)
        cdf_varput, cdfid, 'bfield_magnitude_minus_modelmagnitude_t89', transpose(db_t89_mag)
        cdf_varput, cdfid, 'bfield_magnitude_minus_modelmagnitude_igrf', transpose(db_igrf_mag)
        cdf_close, cdfid
    endforeach
endforeach

end
