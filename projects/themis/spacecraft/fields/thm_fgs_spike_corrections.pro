;+
; Name: 
;     thm_fgs_spike_corrections
;     
; Purpose:
;     Routines for searching for and correcting various issues with the FGS data, including:
;             1) off-by-one spin errors where data points have been skipped
;             2) jumps in a packet at range changes
;             3) jumps in a packet at eclipse starts/stops
;             
;     These problems are obvious when plotting FGS dBz/dt when the spacecraft is near perigee,
;     though they can also occur during low fields
;
; Example:
;   thm_fgs_spike_corrections, time_start='2010-09-01/00:00:00', duration=30, probes=['a'], eclipse_tolerance=300, filename="c:\temp\test.txt"
;
; $LastChangedBy: nikos $
; $LastChangedDate: 2015-02-18 16:03:44 -0800 (Wed, 18 Feb 2015) $
; $LastChangedRevision: 17003 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/spacecraft/fields/thm_fgs_spike_corrections.pro $
;-

; Function: thm_fgs_comp_moving_avg
; 
; Purpose: 
;     Find spikes in dBz/dt by comparing each point to a moving average of the points around it. 
;
;
function thm_fgs_comp_moving_avg, fgs_data, fgs_ddt_times, fgs_ddt, header_times, quiet = quiet
    ; total number of points for the moving average; 14 == 7 on each side
    numpts = 14l
    ; threshold to quantify a 'jump' in dBz/dt
    jumpthreshold = 0.25 
    ; minimum field to check for jumps; required to avoid classifying noise as 'jumps'
    fieldthreshold = 200 ; nT
    ; output array for storing packet header times corresponding to jumps
    jump_pnts = ['']
    
    for i = 0l, n_elements(fgs_ddt[*,2])-numpts/2.-2 do begin
        ; make sure we have enough points on the left side to calculate a moving average
        if i ge numpts/2.+1 then begin
            moving_average = (total(fgs_ddt[i-numpts/2:i-1,2]) + total(fgs_ddt[i+1:i+numpts/2,2]))/numpts

            if (abs(fgs_ddt[i,2]-moving_average) ge jumpthreshold && abs(fgs_data[i]) gt fieldthreshold) then begin
                ; find the closest packet header time
                closest_hed_time = find_nearest_neighbor(header_times, fgs_ddt_times[i])
                if jump_pnts[0] eq '' then begin
                    jump_pnts[0] = time_string(closest_hed_time)
                endif else begin
                    ; make sure this header time isn't already stored in the output array
                    findjump = where(jump_pnts eq time_string(closest_hed_time), countjump)
                    if ~countjump then jump_pnts = array_concat(jump_pnts, time_string(closest_hed_time))
                endelse
            endif
        endif
    endfor
    
    if ~keyword_set(quiet) then begin
        ; print the times corresponding to jumps in dBz/dt
        if jump_pnts[0] ne '' then $
            for i=0l, n_elements(jump_pnts)-1 do print, '[=] found a jump in dBz/dt at ' + jump_pnts[i]
    endif 
    
    return,jump_pnts
end
; Function: thm_fgs_find_gaps
; 
; Purpose: 
;     Identify times in the FGS data where there are missing data points, potentially signifying an off-by-one spin error
;
;
function thm_fgs_find_gaps, fgs_times, fgs_data, fgs_header_times, fgs_state_spinperiod
    compile_opt idl2
    gap_count = 0l
    ; threshold is our definition of a 'gap'
    threshold = 5.01 ; seconds
    max_distance_from_header = 8.2 ; seconds
   ; max_distance_from_header = 260 ; seconds
    max_num_spins_to_corr = 4
    
    ; count the gaps first, so we can allocate enough space for the new arrays
    ; start at i=1, so we can compare to the previous point
    findwhere = where(abs(fgs_times-fgs_times[1:n_elements(fgs_times)-1]) gt threshold, gap_count)
    
    print, 'the number of gaps found: ' + strcompress(string(gap_count), /rem)
    ; make the new arrays with enough space for the missing points
    new_fgs_data = dblarr(n_elements(fgs_data[*,0])+gap_count-1,3)
    new_fgs_time = dblarr(n_elements(fgs_times)+gap_count-1)
    
    ; again, starting at i=1 to compare with the previous point
    for i=1l, n_elements(fgs_times)-1 do begin
        if (fgs_times[i] ne 0 && fgs_times[i-1] ne 0) then begin
            if abs(fgs_times[i]-fgs_times[i-1]) gt threshold then begin
                ; check distance to the header boundary
                header_time = find_nearest_neighbor(fgs_header_times, fgs_times[i])

                hed_distance = header_time-fgs_times[i]
                ; get the spin period from the state data
                spinperiod = thm_fgs_ret_spinperiod(fgs_state_spinperiod, fgs_times[i])
                int_num_spins = round(double(fgs_times[i]-fgs_times[i-1])/spinperiod)
                print, 'gap at: ' + time_string(fgs_times[i]) + ' sign to hed boundary: ' + string(sign(hed_distance))
              ;  stop

                if (abs(hed_distance) le max_distance_from_header && int_num_spins le max_num_spins_to_corr) then begin
                    print, '[+] gap of '+ strcompress(string(int_num_spins), /rem) +' spin(s) in the FGS data at ' + $
                    time_string(fgs_times[i]) + ' hed: ' + time_string(header_time) + ' distance: ' + strcompress(string(hed_distance), /rem)

                    ; assuming 168 samples per packet
                    new_fgs_data[i-1:i-1+167,*] = fgs_data[i:i+167,*]
                    new_fgs_time[i-1:i-1+167] = fgs_times[i:i+167]-(abs((fgs_times[i]-fgs_times[i-1])/(float(int_num_spins))[0]))
                    i = i + 167 ; skip the rest of the samples in this packet

                endif else begin
                    ; gap here, but too far from the packet header boundary
                    print, '[x] gap of '+ strcompress(string(int_num_spins), /rem) +' spin(s) in the FGS data at ' + $
                    time_string(fgs_times[i]) + ' hed: ' + time_string(header_time) + ' distance: ' + strcompress(string(hed_distance), /rem)
                    new_fgs_data[i-1,*] = fgs_data[i,*]
                    new_fgs_time[i-1] = fgs_times[i]
                endelse
            endif else begin
                ; no gap here
                new_fgs_data[i-1,*] = fgs_data[i,*]
                new_fgs_time[i-1] = fgs_times[i]
            endelse
        endif
    endfor
    
    ; let's make sure any rogue 0's are NaN'd
    findzeros = where(new_fgs_time eq 0, zeroscount)
    if findzeros[0] ne -1 then begin
        new_fgs_time[findzeros] = !values.d_nan
        new_fgs_data[findzeros,0] = !values.d_nan
        new_fgs_data[findzeros,1] = !values.d_nan
        new_fgs_data[findzeros,2] = !values.d_nan
    endif 
    
    return, {data: new_fgs_data, time: new_fgs_time}
end

; Function: fgs_combine_packets
; 
; Purpose: 
;     Combines samples into an array of FGS packets
;
;
function fgs_combine_packets, fgs_tvar, fgs_header_tvar, correction = correction, quiet = quiet
    compile_opt idl2
    
    if undefined(correction) then correction = 0

    ; grab the data from the tplot variables
    get_data, fgs_tvar, data=fgs_tvar_data
    get_data, fgs_header_tvar, data=fgs_header_tvar_data
    
    ; for now, we're interested in Bz
    fgs_data = fgs_tvar_data.Y[*,2]
    fgs_time = fgs_tvar_data.X
    fgs_header_data = fgs_header_tvar_data.Y
    fgs_header_time = fgs_header_tvar_data.X
    
    ; there are usually 168 samples in a packet
    ; but this could be +-1 in some cases, so 
    ; we use 170 to avoid a potential overflow
    packets = dblarr(170, n_elements(fgs_header_time))
    values = dblarr(170, n_elements(fgs_header_time))

    for header_idx = 0l, n_elements(fgs_header_time)-2 do begin
        ; need the spin period for the corrections
        fgs_spinperiod = thm_fgs_ret_spinperiod('the_state_spinper', fgs_header_time[header_idx], quiet = quiet)
        if fgs_spinperiod eq -1 then fgs_spinperiod = 0
        
        ; pick out the data for this packet
        fgs_pkt = where((fgs_time[0:n_elements(fgs_time)-1] ge (fgs_header_time[header_idx]+fgs_spinperiod[0]*correction)) and (fgs_time[0:n_elements(fgs_time)-1] le (fgs_header_time[header_idx+1]+fgs_spinperiod[0]*correction)), fgs_pkt_count)

        ; set the values
        packets[0:n_elements(fgs_time[fgs_pkt])-1,header_idx] = fgs_time[fgs_pkt]
        values[0:n_elements(fgs_time[fgs_pkt])-1,header_idx] = fgs_data[fgs_pkt]
    endfor

    ret_struct = {time: packets, data: values}
    
    return, ret_struct
end


; Function: thm_fgs_ret_spinperiod
; 
; Purpose: 
;     Return the exact spin period for a specific time from the spin period state variable, typically th*_state_spinper
;     
; time: double
function thm_fgs_ret_spinperiod, spinperiod_tvar, time, quiet = quiet
    get_data, spinperiod_tvar, data=spinperiod_data
    if size(spinperiod_data, /type) ne 8 then begin
        if undefined(quiet) then dprint, dlevel = 1, 'Error getting data from the spin period tplot variable. Make sure state data is loaded'
        return, -1
    endif
    nearest_time = find_nearest_neighbor(spinperiod_data.X, time, quiet = quiet)
    
    wherenearest_time = where(spinperiod_data.X eq nearest_time, nearestcount)
    if nearestcount ne 0 then begin
        return, spinperiod_data.Y[wherenearest_time]
    endif else begin
        if undefined(quiet) then dprint, dlevel = 1, 'Error finding the spin period for this time.'
        return, -1
    endelse
end
; Function: thm_fgs_ret_eclipse
;
; Purpose:
;    Return times corresponding to FGS eclipses from the spin model
;
;
function thm_fgs_ret_eclipse, spinperiod_tvar, probe
    get_data, spinperiod_tvar, data=spinperiod_data
    smodelptr = spinmodel_get_ptr(probe)
    smodelptr->get_info,shadow_start=shadow_start,shadow_end=shadow_end,shadow_count=shadow_count
    if shadow_count ne 0 then $
        return, [shadow_start, shadow_end] $
    else $
        return, -1
end

function thm_fgm_valid_intervals, fgm_times, fgm_data
    fgm_maxgap = 120 ; seconds
    
    ; need to find if we're at the start or end of an interval
    ; right now, we do this by checking how many seconds the first data point is
    ; from the beginning of the day
    
    timestr = time_struct(fgm_times[0])
    currentday = strcompress(string(timestr.year) + '-' + string(timestr.month) + '-' + string(timestr.date), /rem)
    cdaydouble = time_double(currentday)
    

    if (fgm_times[0]-cdaydouble) le 120 then begin
        ; data starts on the previous day
        prevtime = fgm_times[0]
        intervals = ['previous day']
    endif else begin
        ; data doesn't start on the previous day
        prevtime = fgm_times[0]
        intervals = [prevtime]
    endelse
    
    for time_idx = 0l, n_elements(fgm_times)-1 do begin
        if prevtime eq fgm_times[time_idx] && time_idx ne 0l then begin
            prevtime = fgm_times[time_idx-1]
        endif
        if time_idx lt n_elements(fgm_times)-1 then begin
            if (fgm_times[time_idx]-prevtime gt fgm_maxgap) then begin
                ;print, '&&& found a 2 minute gap at ' + time_string(fgm_times[time_idx])
                intervals = array_concat(prevtime, intervals)
                intervals = array_concat(fgm_times[time_idx], intervals)
            endif
            prevtime = fgm_times[time_idx]
        endif
    endfor

    intervals = array_concat(max(fgm_times), intervals)
    for i = 0, n_elements(intervals)-1 do $
        print, ((i mod 2) eq 0) ? '  Start: ' + time_string(intervals[i]) : '  Stop: ' + time_string(intervals[i])

    return, intervals
end

; Function: thm_fgs_cross_correlation
;
; Purpose:
;    
;
;
pro thm_fgs_xcorrelation, fgs_tvar, fit_hed
    pkt_num = 60
    
    fgm_tvars = ['the_fge_dsl', 'the_fgl_dsl', 'the_fgh_dsl']
;    for i=0l,n_elements(fgm_tvars)-1 do begin
;        get_data, fgm_tvars[i], data=fgm_data, dlimits=fgm_dlimits
;        print, '[*] currently on: ' + fgm_tvars[i]
;        valid_interval = thm_fgm_valid_intervals(fgm_data.X, fgm_data.Y)
;    endfor
    
    
    get_data, fgm_tvars[2], data=fgm_data, dlimits=fgm_dlimits
    print, 'FGH intervals: ' 
    fgh_valid_intervals = thm_fgm_valid_intervals(fgm_data.X, fgm_data.Y)
    
    
    get_data, fgm_tvars[1], data=fgm_data, dlimits=fgm_dlimits
    print, 'FGL intervals: ' 
    fgl_valid_intervals = thm_fgm_valid_intervals(fgm_data.X, fgm_data.Y)
    
    get_data, fgm_tvars[0], data=fgm_data, dlimits=fgm_dlimits
    print, 'FGE intervals: '
    fge_valid_intervals = thm_fgm_valid_intervals(fgm_data.X, fgm_data.Y)
    
    stop
    ;get_data, fgm_tvar, data=fgm_data, dlimits=fgm_dlimits
    

    packets_unshifted = fgs_combine_packets('the_fgs', 'the_fit_hed')
    packets_shiftedp1 = fgs_combine_packets('the_fgs', 'the_fit_hed', correction=1)
    packets_shiftedm1 = fgs_combine_packets('the_fgs', 'the_fit_hed', correction=-1)
    print, 'unshifted: ' + time_string(packets_unshifted.time[0,pkt_num])
    print, 'shifted +1: ' + time_string(packets_shiftedp1.time[0,pkt_num])
    print, 'shifted -1: ' + time_string(packets_shiftedm1.time[0,pkt_num])
    
    print, 'the packet we''re looking for is at: ' + time_string(packets_unshifted.time[0,pkt_num])
    
    stop
   ; fgm_packet = thm_fgm_ret_packet(fgm_data.X, fgm_data.Y, packets_unshifted.time[0,pkt_num], packets_unshifted.time[0,pkt_num+1])

    ; FGL specific code:
    ;fgl_start = fgl_valid_intervals[0]
    ;fgl_stop = fgl_valid_intervals[1]
    fge_start = fge_valid_intervals[0]
    fge_stop = fge_valid_intervals[1]
    
;    wherestart =  where(fgm_data.X eq fge_start)
;    wherestop = where(fgm_data.X eq fge_stop)
;    stop
;    fge_times = fgm_data.X[where(fgm_data.X eq fge_start):where(fgm_data.X eq fge_stop)-1]
;    fge_data = fgm_data.Y[where(fgm_data.X eq fge_start):where(fgm_data.X eq fge_stop)-1]
;    fgm_packet = thm_fgm_ret_packet(fge_times, fge_data, packets_unshifted.time[*,pkt_num])
;    stop
   
  ; fgm_packet = thm_fgm_ret_packet(fgm_data.X, fgm_data.Y, packets_unshifted.time[*,pkt_num])

    ; look through FGE data
    if fge_valid_intervals[0] ne 0. then begin
        fge_start = fge_valid_intervals[0]
        fge_stop = fge_valid_intervals[1]
    endif else if n_elements(fge_valid_intervals) ge 3 then begin
        fge_start = fge_valid_intervals[2]
        fge_stop = fge_valid_intervals[3]
    endif
    wherestart =  where(fgm_data.X eq fge_start)
    wherestop = where(fgm_data.X eq fge_stop)

    fge_times = fgm_data.X[where(fgm_data.X eq fge_start):where(fgm_data.X eq fge_stop)-1]
    fge_data = fgm_data.Y[where(fgm_data.X eq fge_start):where(fgm_data.X eq fge_stop)-1]
    for i=0l, n_elements(packets_unshifted.time[0,*])-1 do begin

        if (packets_unshifted.time[0,i] ge fge_start) && (packets_unshifted.time[0,i] le fge_stop) then begin
            fgm_packet = thm_fgm_ret_packet(fge_times, fge_data, packets_unshifted.time[*,i])
            test = thm_fgs_find_offset(packets_unshifted, packets_shiftedp1, packets_shiftedm1, fgm_packet, i)
        endif
    endfor
    test = thm_fgs_find_offset(packets_unshifted, packets_shiftedp1, packets_shiftedm1, fgm_packet, pkt_num)
    stop

end

function thm_fgs_find_offset, packets_unshifted, packets_shiftedp1, packets_shiftedm1, fgm_packet, pkt_num
    
    unshifted_nozeros = where(packets_unshifted.time[*,pkt_num] ne 0.)
    shiftedp1_nozeros = where(packets_shiftedp1.time[*,pkt_num] ne 0.)
    shiftedm1_nozeros = where(packets_shiftedm1.time[*,pkt_num] ne 0.)
    fgm_packet_nozeros = where(fgm_packet.time[*] ne 0.) 

    pkt_unshifted_time = packets_unshifted.time[unshifted_nozeros,pkt_num]
    pkt_shiftedp1_time = packets_shiftedp1.time[shiftedp1_nozeros,pkt_num]
    pkt_shiftedm1_time = packets_shiftedm1.time[shiftedm1_nozeros,pkt_num]
    pkt_fgm_time = fgm_packet.time[fgm_packet_nozeros]
    
    pkt_unshifted_data = packets_unshifted.data[unshifted_nozeros,pkt_num]
    pkt_shiftedp1_data = packets_shiftedp1.data[shiftedp1_nozeros,pkt_num]
    pkt_shiftedm1_data = packets_shiftedm1.data[shiftedm1_nozeros,pkt_num]
    pkt_fgm_data = fgm_packet.data[fgm_packet_nozeros]
    
    ; dot products
    if n_elements(pkt_fgm_data) ne n_elements(pkt_unshifted_data) $
    || n_elements(pkt_fgm_data) ne n_elements(pkt_shiftedp1_data) $
    || n_elements(pkt_fgm_data) ne n_elements(pkt_shiftedm1_data) then return, 9999
    
    xcorr_unshifted = transpose(pkt_unshifted_data)#pkt_fgm_data
    xcorr_shiftedp1 = transpose(pkt_shiftedp1_data)#pkt_fgm_data
    xcorr_shiftedm1 = transpose(pkt_shiftedm1_data)#pkt_fgm_data
    
    max_xcorr = max([xcorr_unshifted, xcorr_shiftedp1, xcorr_shiftedm1])
    
    if max_xcorr eq xcorr_shiftedp1 then correction = 1
    if max_xcorr eq xcorr_shiftedm1 then correction = -1
    if max_xcorr eq xcorr_unshifted then correction = 0
    print, 'Currently looking at the packet starting at: ' + time_string(packets_unshifted.time[0,pkt_num]) + $
        ' -- correction: ' + strcompress(string(correction),/rem) + ' spin'
    return, correction

end

pro test_int_method, pkt_num
   ; pkt_num = 58
    get_data, 'the_fge_dsl', data=the_fge
    print, 'FGE intervals: '
    fge_valid_intervals = thm_fgm_valid_intervals(the_fge.X, the_fge.Y)
    
    wherestart = where(the_fge.X eq fge_valid_intervals[0])
    wherestop = where(the_fge.X eq fge_valid_intervals[1])
    fge_times = the_fge.X[wherestart:wherestop]
    fge_data = the_fge.Y[wherestart:wherestop, 2]

    packets_unshifted = fgs_combine_packets('the_fgs', 'the_fit_hed')
    packets_shiftedp1 = fgs_combine_packets('the_fgs', 'the_fit_hed', correction=1)
    packets_shiftedm1 = fgs_combine_packets('the_fgs', 'the_fit_hed', correction=-1)
    print, 'unshifted: ' + time_string(packets_unshifted.time[0,pkt_num])
    print, 'shifted +1: ' + time_string(packets_shiftedp1.time[0,pkt_num])
    print, 'shifted -1: ' + time_string(packets_shiftedm1.time[0,pkt_num])

    fgm_packet = thm_fgm_ret_packet(fge_times, fge_data, packets_unshifted.time[*,pkt_num])

    print, 'packets_unshifted.time[0,pkt_num]: ' + string(packets_unshifted.time[0,pkt_num])
    print, 'packets_unshifted.time[n_elements(packets_unshifted.time[*,pkt_num]),pkt_num]: ' + string(packets_unshifted.time[n_elements(packets_unshifted.time[*,pkt_num])-1,pkt_num])
    wherefgm = where(fge_times ge packets_unshifted.time[0,pkt_num] and fge_times le packets_unshifted.time[n_elements(packets_unshifted.time[*,pkt_num])])
    
    wherege = where(fge_times ge packets_unshifted.time[0,pkt_num])
    
    wherele = where(fge_times[wherege] le packets_unshifted.time[n_elements(packets_unshifted.time[*,pkt_num])-3, pkt_num])
    full_fgm_pkt_times = fge_times[wherele]
    full_fgm_pkt_data = fge_data[wherele]
   ;p stop
    full_fgm_pkt = {time: full_fgm_pkt_times, data: full_fgm_pkt_data}
    ;get_data, fgm_tvar, data=fgm_data, dlimits=fgm_dlimits

    ;;;;
    test = thm_fgs_int_offset(packets_unshifted, packets_shiftedp1, packets_shiftedm1, full_fgm_pkt, pkt_num)

end

function thm_fgs_int_offset, packets_unshifted, packets_shiftedp1, packets_shiftedm1, fgm_packet, pkt_num
    unshifted_nozeros = where(packets_unshifted.time[*, pkt_num] ne 0.)
    shiftedp1_nozeros = where(packets_shiftedp1.time[*, pkt_num] ne 0.)
    shiftedm1_nozeros = where(packets_shiftedm1.time[*, pkt_num] ne 0.)
    fgm_nozeros = where(fgm_packet.time ne 0.)
    
    print, 'testing: ' + time_string(packets_unshifted.time[0, pkt_num])
    
    unshifted_pkt_time = packets_unshifted.time[unshifted_nozeros, pkt_num]
    shiftedp1_pkt_time = packets_shiftedp1.time[shiftedp1_nozeros, pkt_num]
    shiftedm1_pkt_time = packets_shiftedm1.time[shiftedm1_nozeros, pkt_num]
    
    unshifted_pkt_data = packets_unshifted.data[unshifted_nozeros, pkt_num]
    shiftedp1_pkt_data = packets_shiftedp1.data[shiftedp1_nozeros, pkt_num]
    shiftedm1_pkt_data = packets_shiftedm1.data[shiftedm1_nozeros, pkt_num]
    
    fgm_time = fgm_packet.time[fgm_nozeros]
    fgm_data = fgm_packet.data[fgm_nozeros]


    fgm_int = int_tabulated(fgm_time, fgm_data, /double)
    unshifted_int = int_tabulated(unshifted_pkt_time, unshifted_pkt_data, /double)
    shiftedp1_int = int_tabulated(shiftedp1_pkt_time, shiftedp1_pkt_data, /double)
    shiftedm1_int = int_tabulated(shiftedm1_pkt_time, shiftedm1_pkt_data, /double)
    
    ;print, 'abs(fgm_int-unshifted): ' + string(abs((fgm_int-unshifted_int)))
    ;print, 'abs(fgm_int-shiftedp1): ' + string(abs((fgm_int-shiftedp1_int)))
    ;print, 'abs(fgm_int-shiftedm1): ' + string(abs((fgm_int-shiftedm1_int)))
    mintest = min([abs(fgm_int-unshifted_int), abs(fgm_int-shiftedp1_int), abs(fgm_int-shiftedm1_int)],minval)
    if minval eq 0 then print, time_string(packets_unshifted.time[0, pkt_num]) + ': no shift required'
    if minval eq 1 then print, time_string(packets_unshifted.time[0, pkt_num]) + ': shift of +1 spin required'
    if minval eq 2 then print, time_string(packets_unshifted.time[0, pkt_num]) + ': shift of -1 spin required'
end


function thm_fgm_ret_packet, fgm_times, fgm_data, fgs_times
    ret_fgm_packet_time = dblarr(n_elements(fgs_times))
    ret_fgm_packet_data = fltarr(n_elements(fgs_times))
    for i = 0l, n_elements(fgs_times)-1 do begin
        fnn_fgm = find_nearest_neighbor(fgm_times, fgs_times[i], /quiet)
        if fnn_fgm eq -1 then continue
        ret_fgm_packet_time[i] = fnn_fgm
        ret_fgm_packet_data[i] = fgm_data[where(fgm_times eq fnn_fgm)]
    endfor
    return, {time: ret_fgm_packet_time, data: ret_fgm_packet_data}
    d
end

pro thm_fgs_spike_corrections, time_start=time_start, duration=duration, probes=probes, eclipse_tolerance=eclipse_tolerance, filename=filename
    ; eclipse_tolerance = max distance of a spike in dBz/dt from an eclipse start/stop time 
    ; to be considered due to the eclipse (default 300 sec)
    
    results = ['[*] Results START - ' + SYSTIME()]
    
    if undefined(eclipse_tolerance) then eclipse_tolerance = 300 ; seconds
    if undefined(time_start) then time_start = '2009-09-01/00:00:00' ; seconds
    if undefined(duration) then duration = 30 ; days
    if undefined(probes) then probes = ['e'] 
    
    results = [results, '[*] eclipse_tolerance=' + string(eclipse_tolerance)]
    results = [results, '[*] time_start=' + time_start]
    results = [results, '[*] duration=' + string(duration)]
    results = [results, '[*] probes=' + probes[0]]
    
    timespan, time_start, duration, /days
    prefix = 'th'+probes[0]

    ; load the L1 FGS data
    thm_load_fit, level = 1, probe=probes, datatype=['fgs'], /get_support_data
    
    ; load the FGL data
    thm_load_fgm, level = 2, probe = probes, datatype = ['fgl', 'fgh', 'fge'], /get_support_data
    
    ; get the FGS header times
    get_data, prefix+'_fit_hed', data=fit_header_info

    ; get the FGS packets
    get_data, prefix+'_fgs', data=the_fgs, dlimits=the_fgs_dlimits
    
    ; find the derivative of the FGS data
    deriv_data, prefix+'_fgs', newname=prefix+'_fgs_ddt'
    get_data, prefix+'_fgs_ddt', data=the_fgs_ddt
    
    ; fix the gaps
    the_fgs_corr = thm_fgs_find_gaps(the_fgs.X, the_fgs.Y, fit_header_info.X, prefix+'_state_spinper')
    
    ; find the NaNs
    wherenans = where(finite(the_fgs_corr.time) eq 0, countnans, complement=notnans)
    
    newarrsize = n_elements(the_fgs_corr.time)-countnans
    new_time_corr_arr = dblarr(newarrsize)
    new_data_corr_arr = dblarr(newarrsize, 3)
    new_time_corr_arr = the_fgs_corr.time[notnans]
    new_data_corr_arr[*,0] = the_fgs_corr.data[notnans,0]
    new_data_corr_arr[*,1] = the_fgs_corr.data[notnans,1]
    new_data_corr_arr[*,2] = the_fgs_corr.data[notnans,2]

    ; save the data with gaps fixed
    store_data, prefix+'_fgs_corr', data={x: new_time_corr_arr, y: new_data_corr_arr}, dlimits=the_fgs_dlimits
    deriv_data, prefix+'_fgs_corr', newname=prefix+'_fgs_corr_ddt'
    get_data, prefix+'_fgs_corr_ddt', data=the_fgs_corr_ddt
    
    ; find the header times corresponding to jumps in the uncorrected data
    jumps_in_ddt = thm_fgs_comp_moving_avg(the_fgs.Y, the_fgs.X, the_fgs_ddt.Y, fit_header_info.X, /quiet)
    
    ; find the header times corresponding to jumps in the corrected data
    jumps_in_ddt_corr = thm_fgs_comp_moving_avg(the_fgs_corr.data, the_fgs_corr_ddt.X, the_fgs_corr_ddt.Y, fit_header_info.X, /quiet)

    ; check if any of the jumps in the corrected array correspond to 
    ; times of min/max of the 2nd derivative of the spin period
    ;final_jumps_in_ddt_corr = thm_fgs_find_spikes_at_sp_changes(jumps_in_ddt_corr)
    final_jumps_in_ddt_corr = jumps_in_ddt_corr
    
    ; try to correlate unexplained jumps with eclipse start/stop times
    eclipses = thm_fgs_ret_eclipse(prefix+'_state_spinper', probes[0])
    if eclipses[0] ne -1 then $
        for j=0l, n_elements(jumps_in_ddt_corr)-1 do $
            for k = 0l, n_elements(eclipses)-1 do $
                if abs(eclipses[k]-time_double(jumps_in_ddt_corr[j])) lt eclipse_tolerance then $
                    jumps_due_to_eclipse = array_concat(jumps_in_ddt_corr[j], jumps_due_to_eclipse)
    
    if undefined(jumps_due_to_eclipse) then jumps_due_to_eclipse = ''

    ; for keeping track of the number of spikes in dBz/dt possibly due to eclipse starts/stops
    ecl_removed = 0
   
    if n_elements(final_jumps_in_ddt_corr) eq 1 && (final_jumps_in_ddt_corr eq -1 || final_jumps_in_ddt_corr eq '') then begin
        pct_rmvd = 100.
        jumps_removed = strcompress(string(n_elements(jumps_in_ddt)) + '/0', /rem)
    endif else begin
        results=[results, '[*] ******************** other jumps ********************']
        for i=0l, n_elements(final_jumps_in_ddt_corr)-1 do begin
            whereeclipse = where(jumps_due_to_eclipse eq final_jumps_in_ddt_corr[i], ecl_count)
            if ecl_count ne 0 then begin
                results = [results, time_string(final_jumps_in_ddt_corr[i]) + ' (due to eclipse)']
                ecl_removed++
            endif else begin
                results = [results, time_string(final_jumps_in_ddt_corr[i])]
            endelse
        endfor
        ; calculate the percentage of jumps removed
        pct_rmvd =  100.-double(n_elements(final_jumps_in_ddt_corr)-ecl_removed)/(n_elements(jumps_in_ddt))*100.
        jumps_removed = strcompress(string(n_elements(jumps_in_ddt)) + '/' + string(n_elements(final_jumps_in_ddt_corr)-ecl_removed), /rem)
    endelse
    results = [results, '[*] ' +strcompress(string(pct_rmvd, format='(F6.2)'),/rem) + $
        '% of the spikes in dBz/dt accounted for due to missing points and eclipse issues']
    results = [results, '[*] total number of spikes in dBz/dt before/after making adjustments: ' + jumps_removed]
    results = [results, '[*] Results END - ' + SYSTIME()]
    
    for i = 0, n_elements(results)-1 do begin
      print, results[i]
    endfor
    
    if ~undefined(filename) then begin
      openw,lun,filename,/get_lun
      for i = 0, n_elements(results)-1 do begin
        printf, lun, results[i]
      endfor 
      free_lun,lun      
    endif   
    
end




















