;+
; NAME: MAKE5SEC
;
; PURPOSE: To obtain data with 5 second time resolution from
;          tplot-like structures. 2-nearest-neighbor linear interpolation is
;          performed to obtain the data. 
;
;
; CALLING SEQUENCE: make5sec,data
; 
; INPUTS: DATA: a tplot-like structure, which must contain a TIME tag
;         and one or more COMP* tags. 
;
;
; KEYWORD PARAMETERS: DATA_TAGS: used to pass in an array of tag names
;                     containing data for conversion to 5 second
;                     resolution. If not set, then COMP* tags will be
;                     used. 
;
;                     OVERWRITE: if set, causes in-place conversion
;                                 of the original data. This is
;                                 probably much faster for large
;                                 structures. 
;
;                     TAG_TYPE: used to pass in an alternate tag type,
;                               for example DATA instead of COMP. 
;
;                     TIME_BIN: used to pass in an alternate time
;                               resolution, instead of the default 5.0
;                               seconds.
;
;                     TZERO: if non-zero, then the first time in the
;                            reduced resolution timetags will be
;                            DATA.START_TIME + TZERO, instead of just
;                            DATA.START_TIME. 
;
;                     GAPS:  used to pass in an array of indices which
;                           refer to the beginning of time gaps in the
;                           original data. If set and of the correct
;                           type, 5-second times which fall in the
;                           gaps will be set to NAN. 
;
;                     IGNORE_GAPS: if set, causes find_gaps to be
;                                  called, and 5 second times in the
;                                  gaps will be set to NAN. 
;
;                     TIMES_ONLY: if set, prevents interpolation of
;                                 the data, and merely returns a
;                                 reduced resolution time
;                                 column. Believe it or not, this can
;                                 be useful. 
;
;                     SPIN_PHASE: if defined, then this value is used
;                                 to generate the time column, rather
;                                 than TZERO or TIME_BIN. The times
;                                 where phase is equal to SPIN_PHASE
;                                 (in degrees) will be selected. 
;
;                     RAW_PHASE:  if set, and SPIN_PHASE is defined,
;                                causes SPIN_PHASE to be interpreted
;                                in units of (degrees * 360/1024). 
;
;                     GIVEN_TIMES: an array of times to use, probably
;                                  generated from a spin phase quantity.
;
; OUTPUTS: The DATA structure is returned, with the 5 second data in
;          either the COMP* tags, the DATA_TAGS tags, or some new
;          *_5 tags. 
;
; SIDE EFFECTS: Addition of *_5 tags, *OR* overwriting of COMP*
;               tags. Also a tag (FIVE_SEC) indicating success of the
;               conversion is added.
;
; MODIFICATION HISTORY: Written 26-July-1996 by Bill Peria
;
;-
pro make5sec,data,data_tags = data_tags, overwrite = overwrite, $
             tag_type = tag_type, time_bin = time_bin, gaps = gaps, $
             ignore_gaps = ignore_gaps, times_only = times_only, $
             spin_phase = spin_phase, raw_phase = raw_phase, $
             given_times = given_times

if idl_type(data) ne 'structure' then begin
    message,'Input structure is not a structure!',/continue
endif

if not (missing_tags(data,'five_sec',/quiet) gt 0) then begin
    if (data.five_sec eq 1) then begin
        message,'structure is already at reduced resolution...',/continue
        return
    endif
endif

if (missing_tags(data,'time') gt 0) then begin
    message,'Input structure must have a TIME tag...',/continue
    return
endif

case idl_type(data.time) of
    'float':begin
        nan = !values.f_nan
    end
    'double':begin
        nan = !values.d_nan
    end
    else:begin
        message,'improper type '+idl_type(ww)+' for input.',/continue
    end
endcase

default_data_tag = 'comp'
dumb = 0
overwrite = keyword_set(overwrite)
times_only = keyword_set(times_only)

if not keyword_set(time_bin) then begin
    time_bin = 5.0d
endif else begin
    if not defined(time_bin) then begin
        message,'undefined value for TIME_BIN...using default 5.0 ' + $
          'seconds...',/continue
        time_bin = 5.0d
    endif else begin
        if time_bin le 0. then begin
            message,'nonsense value for ' + $
              'TIME_BIN...'+time_bin,/continue
            return
        endif
    endelse
endelse

if not keyword_set(tzero) then begin
    tzero = 0.0d
endif

if keyword_set(tag_type) then begin
    if (idl_type(tag_type) ne 'string') or (n_elements(tag_type) ne 1) $
      then begin
        message,' TAG_TYPE keyword must be a single string!',/continue
        return
    endif
endif else begin
    tag_type = default_data_tag
endelse

if not (keyword_set(data_tags)) then begin
    tags = strlowcase(tag_names(data))
    data_tag_spots = where(strmid(tags,0,strlen(tag_type)) eq $
                           tag_type,ndts)
    nondata_tag_spots = where((strmid(tags,0,strlen(tag_type)) ne $
                               tag_type) and (strmid(tags,0,4) ne 'time'),nndts)
    if ndts le 0 then begin
        message,'TAG_TYPE '+tag_type+' was not found in DATA ' + $
          'structure...',/continue
        return
    endif
endif else begin
    if idl_type(data_tags) ne 'string' then begin
        message,'DATA_TAGS keyword must be of string ' + $
          'type...',/continue
        return
    endif
    if (missing_tags(data,data_tags) ne 0) then begin
        message,' missing some requested tags...',/continue
    endif
    
    ndt = n_elements(data_tags)
    ndts = ndt
    
    for i=0,ndt-1 do begin
        tmp = where(strmid(tags,0,strlen(data_tags)) eq tags,ntmp)
        tmpnot = where((strmid(tags,0,strlen(data_tags)) ne tags) and $
                       (strmid(tags,0,4) ne 'time'),nntmp)
        if ntmp gt 0 then begin
            if defined(data_tag_spots) then begin
                data_tag_spots = [data_tag_spots,tmp]
            endif else begin
                data_tag_spots = tmp
            endelse
            if defined(nondata_tag_spots) then begin
                nondata_tag_spots = [nondata_tag_spots,tmp]
            endif else begin
                nondata_tag_spots = tmp
            endelse
        endif
    endfor
    nondata_tag_spots = $
      nondata_tag_spots(uniq(nondata_tag_spots,sort(non_data_tag_spots))) 
    ndts = n_elements(data_tag_spots)
    nndts = n_elements(nondata_tag_spots)
endelse

if missing_tags(data,'start_time') eq 0 then begin
    time = data.time - data.start_time + tzero
endif else begin
    time = data.time - data.time(0) + tzero
endelse

nt = n_elements(time)
last_time = time(nt-1)
first_time = time(0)
tau = last_time - first_time

use_phase = defined(spin_phase)
picked_times = keyword_set(given_times)

if (not use_phase) and (not picked_times) then begin
    nt5 = long(tau/double(time_bin))+1L
    t5 = dindgen(nt5)/double(nt5-1l)*tau
endif else begin
    if use_phase then begin
        message,' SPIN_PHASE keyword is not yet ' + $
          'implemented...',/continue
        return
    endif else begin
        t5 = given_times - data.time(0)
        if idl_type(given_times) ne 'double' then t5 = double(t5)
        nt5 = n_elements(t5)
    endelse
endelse
;
; scale t5 indices with respect to TIME...
;
t5if = frac_indices(t5,time)
t5i = long(t5if)                ; previous near-neighbor indices

if not times_only then begin
    if overwrite then begin
        for i=0,nndts-1 do begin
            if defined(newdata) then begin
                newdata = $
                  create_struct(newdata,tags(nondata_tag_spots(i)), $
                                data.(nondata_tag_spots(i)))
            endif else begin
                newdata = $
                  create_struct(tags(nondata_tag_spots(i)),data.(nondata_tag_spots(i)))
            endelse
        endfor
    endif
    
    for i=0,ndts-1 do begin
        tmpdat = data.(data_tag_spots(i))
        sd = size(tmpdat)
        ndims = sd(0)
        dims = sd(1:ndims)
        maybe_tagged = where(dims eq nt,nmt)
        if nmt eq 0 then begin
            message,tags(data_tag_spots(i))+' data is not compatible with ' + $
              'time tags...',/continue
        endif else begin
            if maybe_tagged(0) ne 0 then begin
                message,'time axis must correspond ' + $
                  'to first array dimension...not that smart yet...',/continue
                dumb = 1
            endif
            
            if (ndims eq 1) then begin ; simple time series
                tmpint = interpolate(data.(data_tag_spots(i)),t5if, $
                                    missing=!values.d_nan)
            endif else begin 
                tmpint = $
                  make_array(nt5,n_elements(tmpdat(0,*)), $
                             type=data_type(data.comp1))
                tmpint = interpolate(tmpdat, $
                                     t5i,lindgen(n_elements(tmpdat(0,*))), $
                                     /grid,missing=!values.d_nan)
            endelse
            
            if (overwrite and not dumb) then begin
                newdata = create_struct(newdata,tags(data_tag_spots(i)),tmpint)
            endif else begin
                data = create_struct(data, $
                                     tags(data_tag_spots(i))+'_5', $
                                     tmpint) 
            endelse
        endelse
        dumb = 0
    endfor
endif

if keyword_set(gaps) then begin
    gtype = idl_type(gaps)
    if ((gtype eq 'long') or (gtype eq 'integer')) then begin
        ignore_gaps = 1
    endif else begin
        message,'incorrect type for gap indices...',/continue
        ignore_gaps = 0
    endelse
endif else begin
    if keyword_set(ignore_gaps) then begin
        ignore_gaps = 1
    endif else begin
        ignore_gaps = 0
    endelse
endelse

if overwrite then begin
    if times_only then newdata = data
    newdata = create_struct(newdata,'FIVE_SEC',1,'TIME',t5+data.start_time)
    data = newdata
    if missing_tags(data,'npts',/quiet) eq 0 then data.npts = n_elements(t5)
    if ignore_gaps then begin
        if keyword_set(gaps) then begin
            ng = n_elements(gaps)
            for i=0,ng-1 do begin
                for j=0,ndts-1 do begin
                    gi = where(t5i eq gaps(i),nn)
                    if (nn gt 0) then begin
                        data.(data_tag_spots(j))(gi) = nan
                    endif
                endfor
            endfor
        endif else begin
            gaps = where((t5if(1:nt5-1)-t5if(0:nt5-2)) lt 1.0d,ngaps)
            for j=0,ndts-1 do begin
                if (ngaps gt 0) then data.(data_tag_spots(j))(gaps) = nan
            endfor
        endelse
    endif
endif else begin
    itag5 = where(strpos(strlowcase(tag_names(data)),'_5') ge 0)
    data = create_struct(data,'FIVE_SEC',1,'T5',t5+data.start_time)
    if ignore_gaps then begin
        if keyword_set(gaps) then begin
            ng = n_elements(gaps)
            for i=0,ng-1 do begin
                gi = where(t5i eq gaps(i),nn)
                if (nn gt 0) then begin
                    for j=0,ndts-1 do begin
                        data.((itag5(j)))(gi) = nan
                    endfor
                endif
            endfor
        endif else begin
            gaps = where((t5if(1:nt5-1)-t5if(0:nt5-2)) lt 1.0d,ngaps)
            if (ngaps gt 0) then begin
                for j=0,ndts-1 do begin
                    data.((itag5(j)))(gaps) = nan
                endfor
            endif
        endelse
    endif
endelse

return
end


