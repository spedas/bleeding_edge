;+
;NAME:
;    noaa_load_kp
;
;PURPOSE:
;    Loads local Kp/Ap index data into tplot variables. If data doesn't exist locally, the code
;    downloads the data from the THEMIS mirror of NOAA STP's data
;
;SYNTAX:
;    noaa_load_kp, [, trange = trange]
;                 
;KEYWORDS:
;    trange: time range to load
;    kp_mirror: http server where mirrored Kp/Ap data lives
;    remote_kp_dir: directory where the Kp/Ap data lives on the mirror server
;    local_kp_dir: directory where data lives locally
;    datatype: type of index to load, should be one of the following:
;          'kp', 'ap', 'sol_rot_num', 'sol_rot_day', 'kp_sum', 'ap_mean', 
;          'cp', 'c9', 'sunspot_number', 'solar_radio_flux', 'flux_qualifier'
;
;HISTORY:
;$LastChangedBy: nikos $
;$LastChangedDate: 2014-11-03 12:06:03 -0800 (Mon, 03 Nov 2014) $
;$LastChangedRevision: 16129 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/missions/noaa/noaa_load_kp.pro $
;-

function kp_return_fraction, value
    kp_lhs = floor(value/10.)
    kp_rhs_times_3 = value mod 10
    kp_rhs = floor(kp_rhs_times_3/3.)
    return, kp_lhs + kp_rhs/3.
end
pro noaa_load_kp, trange = trange, kp_mirror = kp_mirror, remote_kp_dir=remote_kp_dir,$
                  local_kp_dir = local_kp_dir, datatype = datatype
    if ~keyword_set(trange) then get_timespan, trange
    if ~keyword_set(kp_mirror) then kp_mirror = 'http://themis-data.igpp.ucla.edu/'
    if STRLEN(kp_mirror) gt 0 then if STRMID(kp_mirror, STRLEN(kp_mirror)-1, 1) ne "/" then kp_mirror = kp_mirror + "/"
    if ~keyword_set(local_kp_dir) then file_prefix = root_data_dir() + 'geom_indices' + path_sep() $
        else file_prefix = local_kp_dir        
    if STRLEN(file_prefix) gt 0 then if STRMID(file_prefix, STRLEN(file_prefix)-1, 1) ne path_sep() then file_prefix = file_prefix + path_sep()    
    if ~keyword_set(remote_kp_dir) then remote_kp_dir = 'thg/mirrors/kp/noaa/'
    
    starttime = time_struct(trange[0])
    endtime = time_struct(trange[1])
    
    years = starttime.year+indgen(endtime.year-starttime.year+1)
    nyears = n_elements(years)

    kpdata = intarr(8.*366.*nyears)
    apdata = kpdata
    kptimes = dblarr(8.*366.*nyears)
    daytimes = dblarr(366.*nyears)
    srndata = intarr(366.*nyears)
    srddata = srndata
    kpsdata = srndata
    apmdata = srndata
    cpdata = fltarr(366.*nyears)
    c9data = srndata
    ssndata = srndata
    srfdata = cpdata
    fqdata = srndata
    j = 0 ; counter
     
    ; loop through years
    for i=0, nyears-1 do begin
        kpfile = file_prefix+strcompress(years[i],/rem)
        
        ; try to open the Kp data file
        get_lun, lun
        openr, lun, kpfile, error=err
       
        ; file doesn't exist locally, download from a mirror
        if (!error_state.name eq 'IDL_M_CNTOPNFIL') then begin
            file = file_retrieve(remote_kp_dir+strcompress(string(years[i]),/rem), remote_data_dir=kp_mirror, local_data_dir=file_prefix, /ascii_mode)
            openr, lun, file
        endif
        
        ; loop through file
        ; see ftp://ftp.ngdc.noaa.gov/STP/GEOMAGNETIC_DATA/INDICES/KP_AP/kp_ap.fmt for a full description of the data files
        while not eof(lun) do begin
            full_line = ''
            readf,lun,full_line
            year = strmid(full_line,0,2)
            month = strmid(full_line,2,2)
            day = strmid(full_line,4,2)
            srndata[j] = fix(strmid(full_line,6,4))
            srddata[j] = fix(strmid(full_line,10,2))
            for k = 0,7 do kpdata[k+j*8] = fix(strmid(full_line,12+2*k,2))
            kpsdata[j] = fix(strmid(full_line,28,3))
            for k = 0,7 do apdata[k+j*8] = fix(strmid(full_line,31+3*k,3))
            apmdata[j] = fix(strmid(full_line,55,3))
            cpdata[j] = float(strmid(full_line,58,3))
            c9data[j] = fix(strmid(full_line,61,1))
            ssndata[j] = fix(strmid(full_line,62,3))
            srfdata[j] = float(strmid(full_line,65,5))
            fqdata[j] = fix(strmid(full_line,70,1))
            kptimes[j*8.:(j+1)*8.-1.] = time_double(year+'-'+month+'-'+$
                day+'/'+string(indgen(8)*3)+':00:00')
            daytimes[j] = time_double(year+'-'+month+'-'+day)
            j = j+1.
        endwhile
        close, lun
        free_lun, lun
    endfor

    if size(datatype, /type) eq 7 then begin
        ndatatype = datatype
    endif else begin
        ndatatype = ['kp', 'ap', 'sol_rot_num', 'sol_rot_day', 'kp_sum', 'ap_mean', 'cp', 'c9', 'sunspot_number', 'f10.7', 'flux_qualifier']
    endelse

    ; store the data as tplot variables and set ytitles
    for i=0, n_elements(ndatatype)-1 do begin
      if size(ndatatype[i],/type) eq 7 then begin
        case ndatatype[i] of
          'kp': begin
            store_data,'Kp',data={x: kptimes[0:j*8-1], y: kp_return_fraction(kpdata[0:j*8-1])}
            options,'Kp','ytitle','NOAA!CKp'
          end
          'ap': begin
            store_data,'ap',data={x: kptimes[0:j*8-1], y: apdata[0:j*8-1]}
            options,'ap','ytitle','NOAA!Cap'
          end
          'sol_rot_num': begin
            store_data,'Sol_Rot_Num',data={x: daytimes[0:j-1], y: srndata[0:j-1]}
            options,'Sol_Rot_Num','ytitle','NOAA!CSol_Rot_Num'
          end
          'sol_rot_day': begin
            store_data,'Sol_Rot_Day',data={x: daytimes[0:j-1], y: srddata[0:j-1]}
            options,'Sol_Rot_Day','ytitle','NOAA!CSol_Rot_Day'
          end
          'kp_sum': begin
            store_data,'Kp_Sum',data={x: daytimes[0:j-1], y: kpsdata[0:j-1]}
            options,'Kp_Sum','ytitle','NOAA!CKp_Sum'
          end
          'ap_mean': begin
            store_data,'ap_Mean',data={x: daytimes[0:j-1], y: apmdata[0:j-1]}
            options,'ap_Mean','ytitle','NOAA!Cap_Mean'
          end
          'cp': begin
            store_data,'Cp',data={x: daytimes[0:j-1], y: cpdata[0:j-1]}
            options,'Cp','ytitle','NOAA!CCp'
          end
          'c9': begin
            store_data,'C9',data={x: daytimes[0:j-1], y: c9data[0:j-1]}
            options,'C9','ytitle','NOAA!CC9'
          end
          'sunspot_number': begin
            store_data,'Sunspot_Number',data={x: daytimes[0:j-1], y: ssndata[0:j-1]}
            options,'Sunspot_Number','ytitle','NOAA!CSunspot_Number'
          end
          'f10.7': begin
            store_data,'F10.7',data={x: daytimes[0:j-1], y: srfdata[0:j-1]}
            options,'F10.7','ytitle','NOAA!CF10.7'
          end
          'flux_qualifier': begin
            store_data,'Flux_Qualifier',data={x: daytimes[0:j-1], y: fqdata[0:j-1]}
            options,'Flux_Qualifier','ytitle','NOAA!CFlux_Qualifier'
          end
          else: print, 'error'
        endcase
      endif
      ; time clip
      if keyword_set(trange)then begin
        tn = ['Kp','ap', 'Sol_Rot_Num', 'Sol_Rot_Day', 'Kp_Sum', 'ap_Mean', 'Cp', 'C9', 'Sunspot_Number', 'F10.7', 'Flux_Qualifier']
        index = where(strlowcase(tn) eq ndatatype[i])
        if index ne -1 then begin
          if (N_ELEMENTS(trange) eq 2) and (tn[index] gt '') then begin    
            time_clip, tn[index], trange[0], trange[1], replace=1, error=error 
          endif
        endif
      endif
    endfor

end