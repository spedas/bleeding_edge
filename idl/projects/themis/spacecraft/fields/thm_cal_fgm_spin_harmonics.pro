;+
;procedure: thm_cal_fgm_spin_harmonics
;
;Purpose:
;  Uses spin harmonic corrections from calibration files to fix spin harmonic errors in fgm data.
;  The correction values are subtracted from the fgm data.  These values are downloaded from files
;  in the data/themis/th?/l1/fgm/0000/spin_cal/ directory.
;  
;
;Inputs:
;
;  times: An N-length array of times matching the spinphase data and the fgmdata, in double precision seconds since 1970.
;  spinphase: An N-length array of spinphase data in degrees.
;  fgmdata: An Nx3 length array of fgm data in nT.  fgmdata[*,0] = x,fgmdata[*,1] = y,fgmdata[*,2] = z
;  probe: The probe letter, as a string.
;  shadows:A struct with shadow start and stop times retrieved from the new spinmodel.  
;              {start:shadow_starts,stop:shadow_stops}
;  
;Outputs:
;  Mutates fgmdata in place.
;  error: Set to 1 if error occurs, 0 otherwise
;  
;Notes:
;  1.  Specifically, this corrects errors due to the solar array current.  Thus it is only applied when the spacecraft is
;        not in shadow.  
;  
;  2.  The correction should largely remove the 1 Hz and .66 Hz harmonics from the X & Y components of the data and
;  it should remove the .66 Hz and .33 Hz harmonics from the Z component of the data.(in DSL coordinates)
;  
;  3.  The .33 Hz harmonic of the X & Y components should remain.  There should be no 1 Hz Harmonic in the Z-component
;  
;  4.  If a calibration file is not found it will use a default calibration file.  This file will be the calibration file
;        for the probe that corresponds to the latest month.  This could be an issue for dates very early in the mission,
;        as there are no calibration files for these dates, but they are not temporally close to the default calibration values.
;
;
;$LastChangedBy: aaflores $
;$LastChangedDate: 2015-04-27 11:26:29 -0700 (Mon, 27 Apr 2015) $
;$LastChangedRevision: 17433 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/themis/spacecraft/fields/thm_cal_fgm_spin_harmonics.pro $
;-

pro thm_cal_fgm_spin_harmonics,times,spinphase,fgmdata,probe,error=error,shadows=shadow_struct

  compile_opt idl2

  error = 1

  dprint, dlevel=4,'Using spin harmonic correction.'
  
  mintm = min(times,max=maxtm)
  trange = [mintm,maxtm]

  ts = time_struct(trange)
  temp_struct = time_struct('2007-03-01/00:00:00')

  ;loop or year and month of data range
  for i = ts[0].year,ts[1].year do begin
   
    ;bounds of month may vary depending upon year
    startmonth = (i eq ts[0].year)?ts[0].month:1
    endmonth = (i eq ts[1].year)?ts[1].month:12
    
    for j = startmonth,endmonth do begin
    
      temp_struct.year = i
      temp_struct.month = j
    
      stime = time_double(temp_struct)
      
      if j eq 12 then begin
        temp_struct.month = 1
        temp_struct.year = i+1
      endif else begin
        temp_struct.month=j+1
      endelse
  
      etime = time_double(temp_struct)
      
      idx = where(times ge stime and times lt etime,c)
      if c eq 0 then continue
      
      roi_name = tnames('th'+probe+'_state_roi*')
      
      if keyword_set(shadow_struct) && is_struct(shadow_struct) then begin
      
        for k = 0,n_elements(shadow_struct.start)-1 do begin
          idx = ssl_set_intersection([idx],where(times lt shadow_struct.start[k] or times ge shadow_struct.stop[k]))
        endfor
      
            
        if idx[0] eq -1 then begin
          dprint, dlevel=4,'Spacecraft is shadowed for : ' + strjoin(time_string(minmax(times)),' to ') + ' No spin harmonic calibration will be applied.'
          continue
        endif
      
      endif else if keyword_set(roi_name) then begin
      
        get_data,roi_name[0],data=d
        
        roi_idx = where(d.x ge stime and d.x lt etime,c)
        
        if c gt 0 then begin
          dprint, dlevel=4,'Using: ' + roi_name[0] + ' to determine when spacecraft is in shadow'
                    
          ;This expression:
          ; #1 bitmasks out the sun & moon shadow flags,
          ; #2 identifies the locations where they are off
          ; #3 Interpolates results to match data times and rounds to create a nearest neighbor resampling.
          ; #4 Uses where to turn this 0-1 array into indices representing non-shadow times
          shadow_idx = where(round(interpol(long(~((d.y[roi_idx] and 1) or (d.y[roi_idx] and 2))),d.x[roi_idx],times[idx])))
          if shadow_idx[0] eq -1l then continue
                 
          idx = idx[shadow_idx]
        endif else begin
          dprint, dlevel=2,'WARNING: ' + roi_name[0] + ' does not overlap with state data.  Spin Harmonic Correction may be applied during shadow'
        endelse
      
      
      endif else begin
      
        dprint, dlevel=2,'WARNING: th?_state_roi not present, spin harmonic correction will be applied during shadow.' 
      
      endelse
    
      stime_struct = time_struct(stime)
      ;use this trick to roll over to the last day of the previous month
      ;so that filenames can be correctly constructed
      etime_struct = time_struct(etime-(60*60)) 
     
      relpathname = 'th'+probe+'/l1/fgm/0000/spin_cal/th'+probe+'_'+$
                    num_to_str_pad(stime_struct.year,4)+$
                    num_to_str_pad(stime_struct.month,2)+$
                    num_to_str_pad(stime_struct.date,2)+'_'+$
                    num_to_str_pad(etime_struct.year,4)+$
                    num_to_str_pad(etime_struct.month,2)+$
                    num_to_str_pad(etime_struct.date,2)+$
                    '_avgdist.txt'
                    
      month_file = spd_download(remote_file=relpathname, _extra=!themis)
      
      if ~file_test(month_file,/read) then begin
        dprint, dlevel=2,'WARNING: Could not find spin harmonic calibration for month starting at: ' + $
               num_to_str_pad(stime_struct.year,4)+'/'+$
               num_to_str_pad(stime_struct.month,2)+'/01, no readable spin_cal file.'

        dprint, dlevel=4,'Searching for Default Calibration File...'
        
        relpathname = 'th'+probe+'/l1/fgm/0000/spin_cal/th'+probe+'_default_avgdist.txt'
         
        month_file = spd_download(remote_file=relpathname, _extra=!themis)
        
        if ~file_test(month_file,/read) then begin
          dprint,'ERROR: Could not find spin harmonic calibration file for month, or default calibration file.  No spin harmonic calibration will be performed.'
          return
        endif
      endif 
      
      dprint, dlevel=4,'Using spin harmonic offsets from calibration file: ' + month_file  
                  
      get_rt_path,path
      
      ;reads variable spin_harmonic_template into memory
      restore,path+'/spin_harmonic_template.dat'
      ;reads calibration data into memory     
      spin_harmonic_dat = read_ascii(month_file,template=spin_harmonic_template)
      
      fgmdata[idx,0] = fgmdata[idx,0]-interpol(spin_harmonic_dat.(1),spin_harmonic_dat.(0),spinphase[idx])
      fgmdata[idx,1] = fgmdata[idx,1]-interpol(spin_harmonic_dat.(2),spin_harmonic_dat.(0),spinphase[idx])
      fgmdata[idx,2] = fgmdata[idx,2]-interpol(spin_harmonic_dat.(3),spin_harmonic_dat.(0),spinphase[idx]) 
      
    endfor
    
  endfor

  error = 0

end