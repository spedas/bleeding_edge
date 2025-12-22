;       @(#)get_fa_fields.pro	1.64     
;+
; NAME: GET_FA_FIELDS 
;
; PURPOSE: to get data from the FAST fields instrument
;
; CALLING SEQUENCE: mydata = get_fa_fields(dqd,[ time1, time2,
;                   NPTS=npts, START=st, EN=en, PANF=pf, PANB=pb,
;                   ALL = all, CALIBRATE = calibrate, STORE = store])
;
; INPUTS: 
;        DQD: a string containing a valid Data Quantity Descriptor to
;             pass on to SDT. If SDT doesn't recognize the DQD, an
;             error message is sent to the screen, and an invalid
;             status is returned to IDL. Use the routine HELPFAST to
;             access a list of valid DQD's through Netscape.
;
; NOTE: If GET_FA_FIELDS is called with nothing but a DQD, then the
;       keywords ALL, CALIBRATE, and REPAIR will be automatically
;       set. Furthermore, if GET_FA_FIELDS is called with no
;       *time-selection* keywords or time limits, then the ALL keyword
;       will be set.
;
; OUTPUTS: A structure of the following format is returned to the
;          caller, *UNLESS* the keyword STORE is set, in which case
;          the data are stored tplot-style, and the TPLOT string
;          handle is returned to the caller. The STREAK_* tags are
;          arrays of indices into the COMP* tags. If the REPAIRED tag
;          contains a 1 on return, then the STREAK_* tags mark the
;          starts, lengths, and ends of streaks of contiguous,
;          evenly-sampled data. 
;
; DATA_NAME              STRING                     'V1-V4_S'
; VALID                  INTEGER                           1
; PROJECT_NAME           STRING                        'FAST'
; UNITS_NAME             STRING                        'mV/m'
; CALIBRATED             LONG                              1
; UNITS_PROCEDURE        STRING           'fast_fields_units'
; START_TIME             DOUBLE                8.5194794e+08
; END_TIME               DOUBLE                8.5195604e+08
; NPTS                   LONG                           5000
; NCOMP                  LONG                              1
; DEPTH                  LONARR(NCOMP)                     1
; TIME                   DBLARR(NPTS)   START_TIME->END_TIME
; COMP*                  FLTARR(NPTS,DEPTHS(*))     SCIENCE!
; STREAK_STARTS          LONARR(??)
; STREAK_LENGTHS         LONARR(??)
; STREAK_ENDS            LONARR(??)
; REPAIRED               LONG                              1
;                         
; OPTIONAL INPUTS:
;
;       time1 : This argument gives the start time from which to take
;               data, or, if START or EN keywords are non-zero, the
;               length of time to take data.  It may be either a
;               string with the following possible formats:
;               'YY-MM-DD/HH:MM:SS.MSC' or 'HH:MM:SS' (use reference
;               date) or a number, which will represent seconds since
;               1970 (must be a double > 94608000.D), or hours from a
;               reference time, if set. 
;
;       time2 : The same as time1, except it represents the end
;               time. If the NPTS, START, EN, PANF or PANB keywords
;               are non-zero, then time2 will be ignored as an input
;               parameter.
;       
; KEYWORD PARAMETERS:
;
;       CALIBRATE: If set, causes calibrated data to be returned, if
;                  possible. Otherwise, raw data are returned,
;                  *unless* the environment variable FAST_CALIBRATE is
;                  set to 1, i.e. setenv FAST_CALIBRATE 1 .  Setting
;                  the CALIBRATE keyword causes the procedure name in
;                  DAT.UNITS_PROCEDURE to be called.
;
;       DEFAULT: If set, causes CALIBRATE, ALL, and REPAIR to be set. 
;
;       MIN_BUF_LENGTH: If defined, sets the minimum number of
;                       time-contiguous points in a "good streak" or
;                       "buffer" of data. Default is 10.
;
;       REPAIR: If set, causes a time column patcher to be
;               called. Otherwise, you get what SDT is giving. 
;
;       SPIN: If defined, causes the data to be returned at once per
;             spin resolution, at a phase equal to the value of SPIN
;             in degrees. 
;
;       STORE: If set, the tplot routine STORE_DATA is called, and a
;              rudimentary tplot quantity is stored, to be accessed
;              through GET_DATA. In this case, GET_FA_FIELDS returns
;              the TPLOT string handle to the caller. 
;
;       STRUCTURE: A named variable in which the data structure
;                  described above can be returned, if desired (for
;                  example, if STORE is set). 
;
;       YBINS: If nonzero, two dimensional fields quantities are
;              returned with this many frequency bins. 
;
;       BACKGROUND: If set, causes a background to be removed from 2D
;              fields quantities. The background is that returned
;              from the function NOISE. Note that this all makes sense
;              only for 2D, CALIBRATE'd quantities. 
;  
;       Other keywords determine data time selection as given in the 
;       following truth table (NZ == non-zero):
;
;|ALL|NPTS|START|EN|PANF|PANB|selection             |use time1|use time2|
;|---|----|-----|--|----|----|----------------------|---------|---------|
;| NZ|  0 |  0  | 0|  0 |  0 |start -> end          |  X      |  X      |
;| 0 |  0 |  0  | 0|  0 |  0 |time1 -> time2        |  X      |  X      |
;| 0 |  0 |  NZ | 0|  0 |  0 |start -> time1 secs   |  X      |         |
;| 0 |  0 |  0  |NZ|  0 |  0 |end-time1 secs -> end |  X      |         |
;| 0 |  0 |  0  | 0|  NZ|  0 |pan fwd, time1->time2 |  X      |  X      |
;| 0 |  0 |  0  | 0|  0 |  NZ|pan back,time1->time2 |  X      |  X      |
;| 0 |  NZ|  0  | 0|  0 |  0 |time1 -> time1+npts   |  X      |         |
;| 0 |  NZ|  NZ | 0|  0 |  0 |start -> start+npts   |         |         |
;| 0 |  NZ|  0  |NZ|  0 |  0 |end-npts -> end       |         |         |
;
;       No other combination of keywords is allowed.
;
; RESTRICTIONS: The data corresponding to DQD must already be on
;               screen, having been plotted by SDT.
;
; EXAMPLE: my_data = get_fa_fields('V1-V4_S',/all) *OR*
;          tplot,get_fa_fields('Mag3dc_S',/all,/calibrate,/store,struc=my_data)
;
; MODIFICATION HISTORY: written June 1996 by Bill Peria, UCBerkeley
;                       Space Sciences Laboratory
;       @(#)get_fa_fields.pro	1.64     
;
;-
function repair_time,time,kept,streak_starts,streak_lengths
;
; this function is made obsolete by FF_FIXTIME and FA_FIELDS_BUFS, and
; is no longer called. 
;
tol = 1.d-06      ; allowed fractional error in delta t's 
long_enough = 10  ; number of points required for a good streak


nt = n_elements(time)
kept = lindgen(nt)
dt = time(1:nt-1l)-time(0:nt-2l)
;
; pass thru the time array and build an array of streak starts...
;
starts = 0L
dts = dt(0)
for i=1l,nt-2l do begin
    if (abs(dt(i) - dt(i-1l)) gt tol or (dt(i) lt 0)) then begin
        starts = [starts,i]
        dts = [dts,dt(i)]
    endif
endfor

nstreaks = n_elements(starts)
if nstreaks eq 1 then begin
    return,time
endif

stops = [starts(1:nstreaks-1l)-1l,nt-1l]
streak_lengths = stops-starts+1L

good_streaks = where((streak_lengths gt long_enough) and  $
                     dts gt 0,ngs)

if ngs eq 0 then begin
;
;  This will probably never occur...knock wood!
;    
    message,'time column from SDT is horrible..returning raw...please ' + $
      'diagnose...',/continue
    return,time
endif

starts = starts(good_streaks)
stops = stops(good_streaks)
streak_lengths = streak_lengths(good_streaks)
dts = dts(good_streaks)

for i=0,ngs-2l do begin
    if time(stops(i)) gt time(starts(i+1l)) then begin
        newstop =  max(where(time(starts(i):stops(i)) lt $
                             time(starts(i+1l)))) + starts(i)
        stops(i) = newstop
    endif
endfor

streak_lengths = stops-starts+1L
good_streaks = where((streak_lengths gt long_enough) and  $
                     dts gt 0,ngs)
starts = starts(good_streaks)
stops = stops(good_streaks)
streak_lengths = streak_lengths(good_streaks)

outtime = time(starts(0):stops(0))
streak_starts = 0L
kept = lindgen(streak_lengths(0))+starts(0)
for i=1,ngs-1l do begin
    streak_starts = [streak_starts,streak_starts(i-1l)+streak_lengths(i-1l)]
    outtime = [outtime,time(starts(i):stops(i))]
    kept = [kept,lindgen(streak_lengths(i))+starts(i)]
endfor

return,outtime
end
;
;--------------------------------
;
function get_fa_fields,dqd, time1c, time2c, NPTS=npts, START=st, EN=en,      $
                       PANF=pf, PANB=pb, ALL = all, CALIBRATE = $
                       calibrate, STORE = store, STRUCTURE = struct, $
                       SPIN = spin, YBINS = ybins, BACKGROUND = $
                       background, REPAIR = repair, DEFAULT = default, $
                       QUIET = quiet, MIN_BUF_LENGTH = min_buf_length

bad = 0
satellite_name = 'FAST'
satellite_code = 2001 

if idl_type(dqd) ne 'string' then begin
    message,'You must provide a valid Data Quantity Descriptor (DQD).',/continue
    bad = 1
    dqd = 'NO DQD WAS GIVEN!!!'
endif

if n_elements(dqd) gt 1 then begin
    message,'DQD must be a scalar string...',/continue
    bad = 1
endif

if (missing_dqds(dqd(0),/quiet) ne 0) then begin
    message = 'You must have '+dqd(0)+' loaded into SDT before trying ' + $
      'to call GET_FA_FIELDS! Also check spelling and capitalization ' + $
      'of '+ ''''+dqd(0)+'''...'
    if dqd(0) ne 'NONE' then message,message,/continue
    bad =1 
endif


crap = {data_name:dqd,valid:0L}
if bad then return,crap

catch,err_stat
if (err_stat ne 0) then begin
    message,!err_string,/continue
    struct = crap
    if keyword_set(store) then begin
        catch,/cancel
        return,''
    endif else begin
        catch,/cancel
        return,crap
    endelse
endif

;
; if user set *nothing*, then set default to 1...note that STORE is
; excluded from the list, because we want GET_FA_FLDS (no typo) to be
; able to be called without keywords also. Setting /STORE is therefore
; like setting nothing, in this sense. 
;
if keyword_set(default) or (not(keyword_set(npts) or  $
                                keyword_set(st) or  $
                                keyword_set(en) or  $
                                keyword_set(panf) or  $
                                keyword_set(panb) or  $
                                keyword_set(all) or  $
                                keyword_set(calibrate) or  $
                                keyword_set(default) or  $
                                keyword_set(structure) or  $
                                keyword_set(spin) or  $
                                keyword_set(background) or  $
                                keyword_set(repair) or  $
                                defined(time1c) or $
                                defined(time2c))) then default=1

;
; if user sets no time selection keywords, then set the ALL
; keyword...
;
if keyword_set(all) or not (keyword_set(npts) or  $
                            keyword_set(st) or  $
                            keyword_set(en) or  $
                            keyword_set(panf) or  $
                            keyword_set(panb) or  $
                            keyword_set(all) or $
                            defined(time1c) or $
                            defined(time2c)) then all = 1

if keyword_set(default) and not keyword_set(quiet) then begin
    message,'Setting CALIBRATE, ALL, and REPAIR keywords...',/continue
    calibrate = 1
    all = 1
    repair = 1
endif

if defined(time1c) then time1 = time1c
if defined(time2c) then time2 = time2c

boomB = (strpos(dqd,'V4') gt 0) or (strpos(dqd,'V3') gt 0)
if boomB and not keyword_set(quiet) then begin
    message,'WARNING! Boom B is not fully deployed...'+dqd+' data ' + $
      'may be compromised...',/continue
endif

two_d = detect_2d_fields(dqd)
if two_d then begin
    ret = get_fa_2d_fields(dqd,time1, time2, NPTS=npts, START=st, EN=en, $
                           PANF=pf, PANB=pb, ALL = all, CALIBRATE = $
                           calibrate, STORE = store, SPIN = spin, $
                           YBINS = ybins, BACKGROUND = background,  $
                           STRUCTURE = struct)
    catch,/cancel
    return,ret                  ; go no farther!
endif else begin
    if keyword_set(ybins) then begin
        message,'keyword YBINS set for 1D ' + $
          'fields...nonsense!',/continue
    endif
    
    dat = get_ts_from_sdt(dqd,satellite_code,      $
                          t1 = time1, t2 = time2, NPTS = npts,    $
                          START=st, EN=en, PANF=panf, PANB=panb, $
                          ALL = all)


    if not (dat.valid eq 1) then begin
        struct = crap
        if keyword_set(store) then begin
            catch,/cancel
            return,''
        endif else begin
            catch,/cancel
            return,crap
        endelse
    endif

    if not dat.calibrated then begin
        units_name = 'RAW'
    endif else begin
        units_name = dat.calibrated_units
    endelse

    depthset = where(dat.depth ne 0,nnzd)
    if (nnzd gt 0) then begin
        depths = dat.depth(depthset)
    endif else begin
        depths = dat.depth(0)
    endelse
    
    time = temporary(dat.time)
    kept = lindgen(dat.npts)
    streak_starts = 0L
    streak_lengths = dat.npts
    repaired = 0
    if keyword_set(repair) then begin
        if not defined(min_buf_length) then min_buf_length = 10
        ff_fixtime,time,kept=kept,/fix 
        fa_fields_bufs,time,min_buf_length, $
          buf_starts=streak_starts,buf_ends=streak_ends
        streak_lengths = streak_ends - streak_starts + 1L
        dat.npts = n_elements(kept)
        dat.start_time = min(time,/nan,max=end_time)
        dat.end_time = end_time
        repaired = 1
    endif
    streak_ends = streak_starts + streak_lengths - 1L
    
    ret =  create_struct('data_name',            dat.data_name,        $
                         'valid',                dat.valid,            $
                         'project_name',         satellite_name,       $
                         'units_name',           units_name,           $
                         'calibrated',           dat.calibrated,       $
                         'units_procedure',      'fa_fields_units',    $
                         'start_time',           dat.start_time,       $
                         'end_time',             dat.end_time,         $
                         'npts',                 dat.npts,             $
                         'ncomp',                dat.ncomp,            $
                         'depth',                depths,               $
                         'time',                 time,                 $
                         'streak_starts',        streak_starts,	       $
                         'streak_lengths',	 streak_lengths,       $
                         'streak_ends',          streak_ends,          $
                         'repaired',             repaired,             $
                         'notch',                bytarr(dat.npts)+1b)


    tags = strlowcase(tag_names(dat))
    data_tag_spots = where(strmid(tags,0,4) eq 'comp',ndts)


    for i=0,ndts-1 do begin
;   check if there's anything in each tag...should be n_elements gt 1
;   if there is...
        
        if (n_elements(dat.(data_tag_spots(i))) gt 1) then begin
            if depths(i) eq 1 then begin 
                ret = create_struct(ret,tags(data_tag_spots(i)), $ 
                                    (dat.(data_tag_spots(i)))(kept)) 
            endif else begin 
                ret = create_struct(ret,tags(data_tag_spots(i)), $
                                    (dat.(data_tag_spots(i)))(*,kept)) 
            endelse
        endif
    endfor

    ret = create_struct(ret,'header_bytes',bytarr(1))             

    if keyword_set(calibrate) then begin
        call_procedure,ret.units_procedure,ret
    endif

    if defined(spin) or keyword_set(spin) then begin
        if not defined(spin) then spin = 512
        if find_handle('spin_times') eq 0 then begin
            good_spin = load_spin_times(spin = spin)
            if not good_spin then begin
                message,'WARNING: no spin phase data in SDT, using ' + $
                  'phony spin phase times...',/continue 
                spin_per0 = 5.d
                delta_t = (ret.end_time-ret.start_time) 
                nst = long(delta_t/spin_per0)+1L                
                spin_times = delta_t*dindgen(nst)/double(nst-1L) + $
                  ret.start_time
                store_data,'spin_times',data={x:spin_times}
            endif
        endif else begin
            get_data,'spin_times',data=ss
            spin_times = ss.x
        endelse
        make5sec,ret,/overwrite,/ignore_gaps,given_times = spin_times
    endif 
    
    if keyword_set(store) then begin
        if ret.valid then begin
            rtags = strlowcase(tag_names(ret))
            compspots = where(strmid(rtags,0,4) eq 'comp')
            if ret.ncomp gt 1 then begin
                for i=0,ret.ncomp-1 do begin
                    store_data,ret.data_name+rtags(compspots(i)), $
                      data = {x:ret.time,y:ret.(compspots(i))}, $
                      dlimit={ytitle:ret.data_name+'!C!C ' + $
                              '('+ret.units_name+')'}
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
                  {x:ret.time,y:ret.(compspots(0))}, $
                  dlimit={ytitle:ret.data_name+'  ('+ret.units_name+')'}
            endelse
        endif
        catch,/cancel
        struct = temporary(ret)
        return,return_name
    endif else begin
        struct = 'The structure you seek is in the return value of ' + $
          'GET_FA_FIELDS, because you did not set the STORE keyword...'
        catch,/cancel
        return,ret
    endelse
    
    
endelse 

end
