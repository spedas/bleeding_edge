;	@(#)get_fa_2d_fields.pro	1.49	
function get_fa_2d_fields, dqd, time1, time2, NPTS=npts, START=st, EN=en, $
                           PANF=pf, PANB=pb, ALL = all, CALIBRATE = $
                           calibrate, STORE = store, SPIN = spin, $
                           YBINS = ybins, BACKGROUND = background, $
                           STRUCTURE = struct
;+
;
; Please look at documentation for get_fa_fields...you shouldn't call
; GET_FA_2D_FIELDS directly...
;
;-

max_t_jmp = 10.0                ; seconds. if dsp times change by more
                                ; than this, it's a gap

fnan = !values.f_nan

satellite_name = 'FAST'
satellite_code = 2001

if keyword_set(store) then crap = '' else crap = $
  {data_name:dqd,valid:0L}

catch,err_stat
if (err_stat ne 0) then begin
    message,!err_string,/continue
    return,crap
endif
catch,/cancel

if defined(time1) then begin
    if idl_type(time1) eq 'string' then begin
        time1 = str_to_time(time1)
    endif
    time1 = double(time1)
endif

if defined(time2) then begin
    if idl_type(time2) eq 'string' then begin
        time2 = str_to_time(time2)
    endif
    time2 = double(time2)
endif

dqd2d = ['sfa','dsp','wpc','hfq']
ldqd = strlowcase(dqd)

pick = (where(strmid(ldqd,0,3) eq dqd2d,npick))(0)
if pick(0) ge 0 then begin
    which = (dqd2d(pick))(0)
endif else begin
    message,' hard to believe you got here...did you call ' + $
      'GET_FA_2D_FIELDS thru GET_FA_FIELDS? That''s how it''s supposed ' + $
      'to work...',/continue
    catch,/cancel
    return,crap
endelse
;
; define spin times if /SPIN is defined...
;
if defined(spin) or keyword_set(spin) then begin
    if not defined(spin) then spin = 512
    get_data,'spin_times',data=ss,index=index
    if index eq 0 then begin
        good_spin = load_spin_times(spin = spin)
        if not good_spin then begin
            message,' can''t load spin times...quitting...',/continue
            return,crap
        endif
        get_data,'spin_times',data=ss,index=index
    endif
    spin_times = ss.x
    nst = n_elements(spin_times)
endif

tmptime=0.d
;
; get shared memory timespan...
;
firstcol = get_md_from_sdt(dqd,satellite_code,time=tmptime,/start)
if not firstcol.valid then begin
    message,'no '+dqd(0)+' data found in shared memory...',/continue
    return,crap
endif

if defined(time1) then  $
  time1 = firstcol.time > time1  $
else time1 = firstcol.time

yaxis = findgen(n_elements(firstcol.values))
yaxis_units = 'RAW'

lastcol = get_md_from_sdt(dqd,satellite_code,time=tmptime,/en)
if defined(time2) then  $
  time2 = time2 < lastcol.time  $
else time2 = lastcol.time

first_time = firstcol.time
last_time = lastcol.time

if (not lastcol.valid) or (last_time eq first_time) then begin
    message,'only one column of  '+dqd(0)+' data found in shared ' + $
      'memory...must bail out!',/continue
    return,crap
endif

stuff = get_md_ts_from_sdt(dqd,satellite_code, $
                           t1=time1,t2=time2,NPTS=npts, START=st, $
                           EN=en,PANF=pf, PANB=pb, ALL = all) 

if ((not stuff.valid) or  $
    ((where(finite(stuff.values)))(0) lt 0)) then begin
    message,'Unable to get '+dqd,/continue
    catch,/cancel
    return,crap
endif
cal = stuff.calibrated
mat = transpose(stuff.values)
;
; YUK!
;
if not defined(yaxis) then begin
    yaxis = findgen(n_elements(mat(0,*)))
    yaxis_units = 'RAW'
endif
;
; Define the basic structure so that the data can be calibrated
; through FA_FIELDS_UNITS. This structure will be returned to the
; caller or TPLOT-stored, unless bin-averaging is selected thru YBINS. 
;

tstart = min(stuff.times,max=tstop)
dum =  create_struct('data_name',            dqd,                  $
                     'valid',                stuff.valid,          $
                     'project_name',         satellite_name,       $
                     'units_name',           'RAW',                $
                     'calibrated',           stuff.calibrated,     $
                     'units_procedure',      'fa_fields_units',    $
                     'start_time',           tstart,               $
                     'end_time',             tstop,                $
                     'yaxis_units',          yaxis_units,          $
                     'time',                 stuff.times,          $
                     'yaxis',                yaxis,                $
                     'comp1',                 mat,                 $
                     'size',                  size(mat))             

;
;
; At this point, if cal is 1, it means that FAST_CALIBRATE was set,
; i.e. if the user wants raw data, they can't have it, so CALIBRATE
; will be set to 1, just as though the user set it that way.
;
fc_set = cal
if fc_set and  $
  not keyword_set(calibrate) then begin ; user wants raw, but
                                ; FAST_CALIBRATE is
                                ; set... 
    message,'Your data will be calibrated, even though ' + $
      'you did not set the /CALIBRATE keyword when you called ' + $
      'GET_FA_FIELDS, because the environment variable' + $
      ' FAST_CALIBRATE was set when you called SDT.',/continue 
    calibrate = 1
endif
;
; the following is a workaround...the units strings are not returned
; properly by GET_MD_FROM_SDT, even though it reports that the data
; are calibrated. Calling NOISE with the right DQD returns the right
; units. 
;
; check for case where calibration thru IDL was requested and
; FAST_CALIBRATE was set. In this case, GET_MD_TS_FROM_SDT returns
; calibrated data, but a raw frequency axis and incorrect units names.
;
if keyword_set(calibrate) then begin
    if fc_set then begin
        units_fudge = noise(dqd)
        dum.units_name = units_fudge.units_name
        dum.yaxis_units = units_fudge.yaxis_units
        dum.yaxis = units_fudge.yaxis
    endif else begin
        call_procedure,dum.units_procedure,dum
    endelse
endif
;
; now reduce the number of frequency bins if YBINS was set...note that
; this must be done only *after* yaxis is in its final calibrated form.
;
if keyword_set(ybins) then begin
    ny = n_elements(yaxis)
    nx = n_elements(mat(*,0))
    
    ybins = long(round(ybins))
    
    if (ny ne ybins) then begin
        if ((ny gt ybins) and ((ny mod ybins) eq 0)) then begin
            nsum = ny/ybins
            npick = lindgen(ybins)*nsum
            newmat = fltarr(nx,ybins)
            for i=0l,nsum-1l do begin
                newmat = newmat + mat(*,npick+i)
            endfor
            mat = newmat/float(nsum)
            yaxis = dum.yaxis(npick+nsum/2l)
        endif else begin
            mat = congrid(mat,nx,ybins)
            yaxis = interpolate(dum.yaxis, $
                                findgen(ybins)/float(ybins-1l)*float(ny))
        endelse
    endif
    ny = n_elements(yaxis)
;
;   Now build the RET structure...same as DUM, but with new MAT and
;   YAXIS tags. 
;    
    ret = create_struct('data_name',            dum.data_name,        $ 
                        'valid',                stuff.valid,          $ 
                        'project_name',         satellite_name,       $ 
                        'units_name',           dum.units_name,       $ 
                        'calibrated',           dum.calibrated,       $ 
                        'units_procedure',      'fa_fields_units',    $ 
                        'start_time',           tstart,               $ 
                        'end_time',             tstop,                $ 
                        'yaxis_units',          dum.yaxis_units,      $ 
                        'time',                 stuff.times,          $ 
                        'yaxis',                yaxis,                $ 
                        'comp1',                mat,                  $ 
                        'size',                 size(mat))
endif else begin
    ret = temporary(dum)
endelse
;
; RET is defined, now do BACKGROUND subtraction, if requested...
;
if keyword_set(background) then begin
    if ret.calibrated then begin
        floor_str = noise(dqd)
        floor = floor_str.comp1
        if keyword_set(ybins) then begin
            floor = interp(floor,floor_str.yaxis,yaxis)
        endif
        floor_mat = replicate(1.d,n_elements(ret.comp1(*,0))) # floor
        ret.comp1 = ret.comp1 > floor_mat
    endif else begin
        if not keyword_set(calibrate) then begin
            message,'/CALIBRATE was not set, no BACKGROUND will be ' + $
              'removed. ' ,/continue
        endif else begin
            message,'Calibration was not succesful, background can''t ' + $
              'be removed...',/continue 
        endelse
    endelse
endif
;
; reduce to spin resolution, if requested...
;
if defined(spin) then begin
    in_range = select_range(spin_times,ret.start_time,ret.end_time,nn)
    if nn eq 0 then begin
        message,'no overlap with spin_times, returning ' + $
          'full-resolution data...',/continue
    endif else begin
        make5sec,ret,/overwrite,given_times=spin_times
        if nn ne nst then begin
            outside = where((spin_times lt ret.start_time) or  $
                            (spin_times gt ret.end_time))
            ret.comp1(outside,*) = !values.d_nan
        endif
    endelse
endif
;
; perform a store for tplot, if it was requested...
;
if keyword_set(store) then begin
    rtags = strlowcase(tag_names(ret))
    compspots = where(strmid(rtags,0,4) eq 'comp',ncomp)
    if ncomp gt 1 then begin
        for i=0,ncomp-1 do begin
            store_data,ret.data_name+rtags(compspots(i)), $
              data = $
              {x:ret.time,y:ret.(compspots(i)),v:ret.yaxis}, $
              dlimits = {spec:1, $
                         ystyle:1, $
                         ytitle:ret.yaxis_units, $
                         ztitle:ret.data_name+'!C (' $
                         +ret.units_name+')', $
                         zrange:var_range(ret.(compspots(i)))}
            
            chklog = (ret.(compspots(i)))
            chklog = chklog(where(finite(chklog)))
            setlog = ((where(chklog le 0))(0) lt 0)
            if setlog then setlog = $
              (max(chklog,/nan)/min(chklog,/nan) ge 1000.)
            options,ret.data_name+rtags(compspots(i)),'zlog',setlog

            if not defined(return_name) then begin
                return_name = $
                  ret.data_name+rtags(compspots(i))
            endif else begin
                return_name = $
                  [return_name,ret.data_name+rtags(compspots(i))]
            endelse
        endfor
    endif else begin
        return_name = ret.data_name
        store_data,ret.data_name,data = $
          {x:ret.time,y:ret.(compspots(0)),v:ret.yaxis,spec:1}, $
          dlimits = {ytitle:ret.yaxis_units, $
                     ztitle:ret.data_name+'!C (' $
                     +ret.units_name+')', $
                     ystyle:1, $
                     zrange:var_range(ret.(compspots(0)))}
        
        chklog = (ret.(compspots(0)))
        chklog = chklog(where(finite(chklog)))
        setlog = ((where(chklog le 0))(0) lt 0)
        if setlog then setlog = $
          (max(chklog,/nan)/min(chklog,/nan) ge 1000.)
        options,ret.data_name,'zlog',setlog
        
    endelse
;
;   free up space allocated to RET, which the user doesn't want
;   anyway...and define struct, in case STRUCTURE was set. 
;
    struct = temporary(ret)

    catch,/cancel
    return,return_name
endif else begin
    catch,/cancel
    struct = 'The structure you seek is in the return value of ' + $
      'GET_FA_FIELDS, because you did not set the STORE keyword...'

    return,ret
endelse

end
