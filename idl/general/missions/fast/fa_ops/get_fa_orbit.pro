;+
; PROCEDURE: get_fa_orbit
;
; PURPOSE:  
;    Computes orbit vectors for a set of times extending over a given timespan.
;
; POSITIONAL PARAMETERS:
;    arg1:
;        if keyword parameter 'time_array' is not set, then this parameter is the
;        start time of the timespan over which orbit vectors are to be computed,
;        else it is the array of times for which orbit vectors are to be computed.
;    arg2:
;        if keyword parameter 'time_array' is not set, then this parameter is the
;        end time of the timespan over which orbit vectors are to be computed,
;        else it is not used.
;    
; KEYWORDS:
;    time_array:
;        If not set, then interpret the two positional parameters as the start
;        time and end time of the timespan over which orbit vectors are to be
;        computed.  If set, interpret the first positional parameter as an array
;        of times for which orbit vectors are to be computed, and the second
;        positional parameter as the number of elements in the array of times.
;    gse:
;        If set, get_fa_orbit will execute a store_data on the following:
;	     {x:time,y:pos,ytitle:'fa_pos'}
;	     {x:time,y:pos,ytitle:'fa_vel'}
;	 All overides this keyword.
;    all:
;        If not set, and gse is not set, get_fa_orbit will execute a 
;	 store_data on the following:
;	     {x:time,y:orbit,ytitle:'ORBIT'}
;	     {x:time,y:pos,ytitle:'fa_pos'}
;	     {x:time,y:alt,ytitle:'ALT'}
;	     {x:time,y:ilat,ytitle:'ILAT'}
;	     {x:time,y:ilng,ytitle:'ILNG'}
;	     {x:time,y:mlt,ytitle:'MLT'}
;	     {x:time,y:vel,ytitle:'fa_vel'}
;        If set, get_fa_orbit will execute store_data on the above and also on:
;	     {x:time,y:lat,ytitle:'LAT'}
;	     {x:time,y:lng,ytitle:'LNG'}
;	     {x:time,y:flat,ytitle:'FLAT'}
;	     {x:time,y:flng,ytitle:'FLNG'}
;	     {x:time,y:b,ytitle:'B_model'}
;            {x:time,y:bfoot,ytitle:'BFOOT'}
;        where orbit, pos, alt, etc are arrays of values as defined in the orbitio
;        library documentation (see orbitlib(3)), and bfoot is the magnetic
;        field at the position of the footprint, in GEI coords, in nTesla.
;        Note that the position, velocity, magnetic field, and magnetic field
;        at the footprint are given in GEI coordinates.
;    status:
;        The long integer return value of the OrbGetVectors() call in the orbitio
;        library.  There are about a dozen different status codes indicating the
;        various possible error conditions.  These status codes are shown in the
;        include file $(workspace)/include/orbitlib.h (ORB_OK, ORB_EOF, etc).
;        The user should generally call get_fa_orbit with the status keyword set,
;        and should explicitly test that status equals 0 (ORB_OK = 0 signifies
;        success) before using the returned data.
;    delta_t:
;        spacing in seconds of the computed orbit vectors (default = 20 sec)
;        this keyword parameter is ignored if keyword parameter time_array is set
;    definitive:
;        if set, uses the definitive orbit file, else uses the predicted orbit
;        file.  (see keyword 'orbit_file' below)
;    drag_prop:
;        if set, the call to the orbitprop library will use an orbit propagator
;        that includes the effects of atmospheric drag (which is somewhat slower,
;        but more accurate).  If not set, uses an orbit propagator which ignores
;        atmospheric drag.
;    orbit_file:
;        if set to a pathname of an orbit file, this named orbit file will be used
;        instead of the default orbit file, which is found by reading the file
;        $FASTCONFIG/fast_archive.conf for the variable FAST_ALMANAC, and then
;        setting orbit_file = value(FAST_ALMANAC)/orbit/predicted, unless the
;        keyword definitive is set, in which case 
;        orbit_file = value(FAST_ALMANAC)/orbit/definitive.
;    verbose:
;        Should not be used by users.  For debugging use only.  Functionality 
;        changes unexpectedly and without notice.
;    addfp:
;        Should not be used by users.  For debugging use only.  Functionality 
;        changes unexpectedly and without notice.
;    no_store:
;        If set, inhibits tplot-storage of orbit quantities. This is
;         useful to avoid the overwriting of previously stored orbit data.
;    struc:
;        A named variable in which a strucure containing the requested
;          orbit quantities can be returned.
;
; VERSION: @(#)get_fa_orbit.pro	1.21 02/18/02 UCB SSL
;-



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; procedure to read a given config file and locate a single parameter value
pro get_fa_orbit_rd_conf_file, filename, param_name, param_value, status
status = 0
openr, unit, /get_lun, filename, error=err
if (err ne 0) then print, 'Could not open config file "', filename, '"'
line=''
while (not eof(unit)) do begin
    readf, unit, line
    line = str_sep(line, ';')
    line = line(0)
    line = strcompress(line)
    line = strtrim(line, 2)
    if line ne '' then begin
        fields = str_sep(line, ' ')
        size_info = size(fields)
	if size_info(0) ne 1 then goto, error
	if fields(0) eq param_name then begin
	    if size_info(1) lt 2 then goto, error
	    param_value = fields(1)
	    free_lun, unit
	    status = 1
	    return
	endif
    endif
endwhile
error:
free_lun, unit
msg = 'rcf: could not get value for variable ' + param_name + ' from config file.'
message, msg, /info
param_value = ''
return
end


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
pro get_fa_orbit,                $
    arg1,                        $
    arg2,                        $
    time_array=time_array,       $
    all=all,                     $
    gse=gse,                     $
    delta_t=delta_t,             $
    definitive=definitive,       $
    drag_prop=drag_prop,         $
    orbit_file=orbit_file,       $
    status=status,               $
    verbose=verbose,             $
    addfp=addfp,                 $
    no_store=no_store,           $                             
    struc=struc                                 

; this is 'EPOCH' from orbconsts.h in orbitprop directory
; epoch year of the earth magnetic field representation used
epoch_year = 1995

; this is 'EPOCH_JAN_1_JULIAN' from orbconsts.h in orbitprop directory
; mjd of the epoch_year above
epoch_mjd = 49718

; this is MEAN_RAD from orbconsts.h in orbitprop directory
; mean radius in km of the earth
mean_earth_radius = 6371.2

; req is equatorial radius of earth, in km
req = 6378.14

; rpo is polar radius of earth, in km
rpo = 6356.76

; earth_flat_const = 1 / (1 - f)^2, where f = 1/298.257 is the earth flattening factor
earth_flat_const = 1.006740D

; mjd_1970 is the MJD of 1970-01-01/00:00:00
mjd_1970 = 40587.0D

status = -1

if keyword_set(verbose) then verbose = fix(verbose) else verbose = fix(0)

; generate the array of times and the size of the array of times
if keyword_set(time_array) then begin
    times = double(arg1)
    n_times = n_elements(times)
    
    if (n_times eq 1) then begin
        time_increments = 0.d
    endif else begin
        time_increments = times[1:*] - times
    endelse
    
    time_goes_backward = where(time_increments lt 0.d, ntgb)
    if ntgb gt 0 then begin
        message,'The input time array is not monotonic. However, the ' + $
          'orbit data will be in time order. Therefore the Nth element ' + $
          'of returned orbit data may not correspond to the Nth input ' + $
          'time.',/continue
    endif 

    if verbose then begin
        print, ' n_times = ', n_times
    endif
    if n_times le 0 then begin
	print, 'number of times requested must be > 0'
    endif
endif else begin
    if data_type(arg1) eq 7 then begin
	tstart = str_to_time(arg1)
    endif else begin
	tstart = double(arg1)
    endelse
    if data_type(arg2) eq 7 then begin
	tend = str_to_time(arg2)
    endif else begin
	tend = double(arg2)
    endelse

    ; default value of time step is 20 seconds
    if not keyword_set(delta_t) then delta_t = 20.0d0
    delta_t = double(delta_t)

    if verbose then begin
        print, ' tstart  = ', tstart
        print, ' tend    = ', tend
        print, ' tend - tstart = ', tend - tstart
        print, ' delta_t = ', delta_t
    endif
    n_times = long((tend - tstart) / delta_t) + 1
    if verbose then begin
        print, ' n_times = ', n_times
    endif
    if n_times le 0 then begin
	print, 'number of times requested must be > 0'
    endif
    times = tstart + delta_t * dindgen(n_times)
endelse

; default is to use the quick orbit propagator
if keyword_set(drag_prop) then drag_prop = fix(1) else drag_prop = fix(0)

; create structure to receive the orbHeader from OrbGetVectors() in liborbitio.so
; use dummy place-holders for the string components of the orb_header structure
orb_time   = {year:0L,DOY:0L,month:0L,mday:0L,wday:0L,  $
    hour:0L,minute:0L,second:0.0d0,MJD:0.0d0}
;print,' size of orb_time is ' , long(n_tags(orb_time,/length))
orb_header = {dummy_version:replicate(0B,8),dummy_satellite:replicate(0B,40),  $
    orbit:0L,epoch:orb_time,axis:0.0d0,ecc:0.0d0,inc:0.0d0,node:0.0d0,  $
    aperigee:0.0d0,manomaly:0.0d0}
;print,' size of orb_header is ' , long(n_tags(orb_header,/length))

; create an array to receive the orbExVector array from the OrbGetVectors routine.
orb_vector = {time:0.0d0,r:[0.0d0,0.0d0,0.0d0],v:[0.0d0,0.0d0,0.0d0], $
    lat:0.0d0,lng:0.0d0,alt:0.0d0,flat:0.0d0,flng:0.0d0,mlt:0.0d0,  $
    ilat:0.0d0,ilng:0.0d0,b:[0.0d0,0.0d0,0.0d0]}
orb_ex_vector  = {vector:orb_vector, orbit:0L, absTime:orb_time}
orb_ex_vectors = replicate(orb_ex_vector, n_times)

; get the orbit file
if keyword_set(orbit_file) then orbit_file = orbit_file else begin
    fast_config = getenv('FASTCONFIG')
    if fast_config eq '' then begin
        print, "get_fa_orb: FASTCONFIG not defined--can't find orbit file."
	exit
    endif
    conf_file = fast_config + '/' + 'fast_archive.conf'
    ;print, 'config file: ', conf_file
    get_fa_orbit_rd_conf_file, conf_file, 'FAST_ALMANAC', almanac_dir, status
    if keyword_set(definitive) then begin
        orbit_file = almanac_dir + '/' + 'orbit' + '/' + 'definitive'
    endif else begin
        orbit_file = almanac_dir + '/' + 'orbit' + '/' + 'predicted'
    endelse
endelse

size_orb_header = long(n_tags(orb_header,/length))
size_orb_ex_vectors = long(n_tags(orb_ex_vectors,/length))

; get the pathname of the shared object 'idl_orb_get_vectors.so'.
libdir = getenv('FASTLIB')
if keyword_set(libdir) then libdir = libdir + '/'  $
else begin
    message, "Environment variable FASTLIB not set--can't find idl_orb_get_vectors.so"
    return
endelse

if verbose then print, 'shared object is ', libdir + 'idl_orb_get_vectors.so'

; NOTE that selection must match #defines in the C routine: idl_orb_get_vectors
if keyword_set(all) then selection = 1		$
else if keyword_set(gse) then selection = 2	$
else selection = 0

status = call_external(libdir + 'idl_orb_get_vectors.so', 'idl_orb_get_vectors', $
    verbose, orbit_file, times, n_times, size_orb_header,  $
    orb_header, size_orb_ex_vectors, orb_ex_vectors, drag_prop, selection)
if status ne 0 then return

if verbose then begin
    print, 'epochMJD in header is ', orb_header.epoch.MJD
    print, 'times in orb_vectors follow :'
    print, orb_ex_vectors.vector.time
endif

; result_epoch is epoch used for result times, (seconds since 1970-1-1/00:00:00.0)
result_epoch = (orb_header.epoch.MJD - mjd_1970) * 86400.0

if verbose then print, format = '(a, g22.15, a, a, a)', $
    'result_epoch: ', result_epoch, ' (', time_to_str(result_epoch), ')'

time  = orb_ex_vectors.vector.time + result_epoch
orbit = orb_ex_vectors.orbit
pos   = transpose(orb_ex_vectors.vector.r)
alt   = orb_ex_vectors.vector.alt
ilat  = orb_ex_vectors.vector.ilat
ilng  = orb_ex_vectors.vector.ilng
mlt   = orb_ex_vectors.vector.mlt
vel   = transpose(orb_ex_vectors.vector.v)


if keyword_set(all) then begin
    lat   = orb_ex_vectors.vector.lat
    lng   = orb_ex_vectors.vector.lng
    flat  = orb_ex_vectors.vector.flat
    flng  = orb_ex_vectors.vector.flng
    b     = transpose(orb_ex_vectors.vector.b)

    ; The following is about the computation of the magnetic footprint.
    ; The call to the C routine idl_orb_get_vectors() in the local library
    ; idl_orb_get_vectors.so uses a call to the C routine OrbGetVectors()
    ; (or the C routine OrbQuickVectors()) in the orbitprop library.
    ; The orbitprop library computes the latitude and longitude of the magnetic
    ; footprint in geographic coordinates.  For details of how the field line
    ; trace is done by the orbitprop library, see the file lines.f in the
    ; directory src/orbitlib/orbitprop.
    ; After the orbitprop library returns the geographic latitude and longitude
    ; of the magnetic footprint, what we need to do here is convert these
    ; coords to geocentric coordinates so we can construct the 3-vector in
    ; GEO coords of the magnetic footprint.
    ; First compute geocentric latitude and longitude, in radians.
    gclat = atan(tan(!dtor * flat) / earth_flat_const)
    gclng = !dtor * flng
    cosgclat = cos(gclat)
    cos2gclat = cosgclat * cosgclat
    sin2gclat = 1.0 - cos2gclat
    rearth = sqrt(1.0 / (cos2gclat/(req*req) + sin2gclat/(rpo*rpo)))
    r = rearth + 100.0
    n_positions = n_elements(gclat)
    rfootprint = dblarr(n_positions,3)
    rfootprint(*,0) = r * (cosgclat * cos(gclng))
    rfootprint(*,1) = r * (cosgclat * sin(gclng))
    rfootprint(*,2) = r * sin(gclat)
    if keyword_set(addfp) then begin
        store_data, 'rfootprint', data={x:time, y:rfootprint, ytitle:'rfootprint'}
    endif

    ; compute the array of MJD's for all the orbit vectors
    mjd   = orb_ex_vectors.absTime.MJD

    ; compute the epoch MJD in the orb_header
    basemjd = orb_header.epoch.MJD

    ; the same 'year' as from orb_vec.c in the orbitprop directory
    ; for adjustment of the magnetic field model to different epoch
    year = double(epoch_year) + (basemjd - double(epoch_mjd)) / 365.25

    if verbose then begin
        print, 'epoch_year = ', epoch_year
        print, 'epoch_mjd  = ', epoch_mjd
        print, 'basemjd    = ', basemjd
        print, 'year       = ', year
    endif

    ; Compute the magnetic field at the position rfootprint(*,*), in GEI coords.
    ; To do this, we call the C routine idlmagarray() in the local library
    ; libidlorbit.so, which is just a wrapper around iterated calls to the
    ; magsat_() routine to compute the magnetic field, which is in the file
    ; magsat.f in the src/orbitlib/orbitprop directory.
    rfootprint_norm = rfootprint/mean_earth_radius
    rfootprint_norm_tr = transpose(rfootprint_norm)
    bfoot_tr = dblarr(3, n_positions)
    status = call_external(libdir + 'libidlorbit.so', 'idlmagarray', $
	verbose, n_positions, rfootprint_norm_tr, year, mjd, bfoot_tr)
    if status ne 0 then return
    bfoot = transpose(bfoot_tr)

    if not keyword_set(no_store) then begin
        store_data, 'BFOOT', data={x:time, y:bfoot,ytitle:'BFOOT'}
        store_data,'LAT',data={x:time,y:lat,ytitle:'LAT'}
        store_data,'LNG',data={x:time,y:lng,ytitle:'LNG'}
        store_data,'FLAT',data={x:time,y:flat,ytitle:'FLAT'}
        store_data,'FLNG',data={x:time,y:flng,ytitle:'FLNG'}
        store_data,'B_model',data={x:time,y:b,ytitle:'B_model'}
        store_data,'ORBIT',data={x:time,y:orbit,ytitle:'ORBIT'}
        store_data,'fa_pos',data={x:time,y:pos,ytitle:'fa_pos'}
        store_data,'ALT',data={x:time,y:alt,ytitle:'ALT'}
        store_data,'ILAT',data={x:time,y:ilat,ytitle:'ILAT'}
        store_data,'ILNG',data={x:time,y:ilng,ytitle:'ILNG'}
        store_data,'MLT',data={x:time,y:mlt,ytitle:'MLT'}
        store_data,'fa_vel',data={x:time,y:vel,ytitle:'fa_vel'}
    endif 
    all_orb = $
      {bfoot:bfoot,lat:lat,lng:lng,flat:flat,flng:flng,b_model:b}
    basic_orb = {time:time,orbit:orbit,fa_pos:pos,alt:alt, $
                 ilat:ilat,ilng:ilng,mlt:mlt,fa_vel:vel}
endif  else if keyword_set (gse) then begin
    if not keyword_set(no_store) then begin
        store_data,'ORBIT',data={x:time,y:orbit,ytitle:'ORBIT'}
        store_data,'fa_pos',data={x:time,y:pos,ytitle:'fa_pos'}
        store_data,'fa_vel',data={x:time,y:vel,ytitle:'fa_vel'}
    endif 
    gse_orb = {time:time,orbit:orbit,fa_pos:pos,fa_vel:vel}
endif else begin
    if not keyword_set(no_store) then begin
        store_data,'ORBIT',data={x:time,y:orbit,ytitle:'ORBIT'}
        store_data,'fa_pos',data={x:time,y:pos,ytitle:'fa_pos'}
        store_data,'ALT',data={x:time,y:alt,ytitle:'ALT'}
        store_data,'ILAT',data={x:time,y:ilat,ytitle:'ILAT'}
        store_data,'ILNG',data={x:time,y:ilng,ytitle:'ILNG'}
        store_data,'MLT',data={x:time,y:mlt,ytitle:'MLT'}
        store_data,'fa_vel',data={x:time,y:vel,ytitle:'fa_vel'}
    endif         
    basic_orb = {time:time,orbit:orbit,fa_pos:pos,alt:alt, $
                 ilat:ilat,ilng:ilng,mlt:mlt,fa_vel:vel}
endelse
    
if keyword_set(all) then struc = create_struct(basic_orb,all_orb)	$
else if keyword_set(gse) then struc = gse_orb 			$
else struc = temporary(basic_orb)

return
end

