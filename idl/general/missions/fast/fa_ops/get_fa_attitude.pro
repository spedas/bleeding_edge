;+
; PROCEDURE: get_fa_attitude
;
; PURPOSE: get the FAST attitude information for a given set of times
;
; POSITIONAL PARAMETERS:     
;     arg1:
;         if keyword parameter 'time_array' is set, then this parameter is the
;         array of times for which the attitude is to be returned, else it is the
;         start time of the timespan over which the attitude is to be returned.
;     arg2:
;         if keyword parameter 'time_array' is set, then this parameter is not used,
;         else it is the end time of the timespan over which the attitude is to be returned.
;     
; KEYWORD PARAMETERS:
;     delta_t:
;         spacing in seconds of the set of times from start time to end time, over which
;         the attitude info is returned (default = 20 seconds).
;         This parameter is ignored if the keyword parameter 'time_array' is set.
;     attlevel:
;         flag to specify what level of attitude info is desired:
;             -1 : return the best attitude info available (the default)
;              0 : return initial level attitude data only. this level has not
;                      been verified in any way
;              1 : return level one attitude data only. this level has had a first
;                      attempt at correcting errors, mostly smoothed to remove jitter.
;              2 : return definitive attitude only.  this level has been compared
;                      with B-field model data, and sun pulse spin frequency corrected.
;         if attlevel is set to either 0, 1, or 2, and the requested level of attitude
;         data is not found, get_fa_attitude will mark that data point as invalid and
;         will return no data for that time point.
;     coord:
;         a string specifying the coordinate system desired for the output rotation matrix.
;         see the OUTPUTS section below.
;         possible values for coord are (case doesn't matter, 'gse' = 'gSe' = 'GSE'):
;             'FASTSPIN' : Spinning Spacecraft
;             'DESPUN'   : Despun
;             'GEI'      : Geocentric Equatorial Inertial
;             'GEO'      : Geographic
;             'GSE'      : Geocentric Solar Ecliptic
;             'GSM'      : Geocentric Solar Magnetospheric
;             'MAG'      : Geomagnetic
;             'GECI'     : Ecliptic Inertial
;             'GSEQ'     : Geocentric Solar Equatorial
;             'SM'       : Solar Magnetic
;     status:
;         status of get_fa_attitude on return (0 means successful return, nonzero means
;         some error has occurred).
;         In general, the user should call get_fa_attitude with this status keyword set,
;         and should explicitly test that status equal 0 for success.
;
; OUTPUTS:
;     performs a 'store_data' operation on the following variables:
;         fa_spin_ra:
;             right ascension of the spin axis, in GEI coords, in degrees
;         fa_spin_dec:
;             declination of the spin axis, in GEI coords, in degrees
;         fa_spin_freq:
;             spin rate in degrees/second
;         fa_spin_phase:
;             spin phase about the spin axis, in degrees.  zero phase means
;             spacecraft x axis is in the sun.
;         fa_attlevel:
;             the attitude level of the data found.
;         fa_rotmat_xxx:
;             the rotation matrix from the FASTSPIN coordinate system to the coord
;             system that was selected by the input keyword parameter 'coord',
;             and where 'xxx' is the coord system specified by the keyword param 'coord'.
;
; ERRORS:
;     If attlevel 0, 1, or 2 has been selected and if this level of attitude data is not
;     found, or if any other error occurs, the given time point will be marked as invalid,
;     returned attitude data will have value NaN.
;
; CREATED BY: Vince Saba,  Oct, 1996.
;
; VERSION: @(#)get_fa_attitude.pro	1.5 06/05/97
;-

pro get_fa_attitude, $
    arg1, $
    arg2, $
    time_array=time_array, $
    delta_t=delta_t, $
    attlevel=attlevel, $
    coord=coord, $
    status=status, $
    show_inputs=show_inputs, $
    show_good_att=show_good_att, $
    show_ext_att=show_ext_att, $
    show_bad_att=show_bad_att, $
    show_valid=show_valid

; on return, status will be 0 on success, non-zero on failure
status = -1

; generate the array of times and the size of the array of times
if keyword_set(time_array) then begin
    times = double(arg1)
    n_times = n_elements(times)
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
    if not keyword_set(delta_t) then delta_t = 20.0D
    delta_t = double(delta_t)
    n_times = long((tend - tstart) / delta_t + 1)
    times = tstart + delta_t * dindgen(n_times)
endelse

if n_elements(attlevel) eq 0 then attlevel=32767 $
else begin
    if attlevel eq -1 then attlevel=32767 $
    else if attlevel lt 0 or attlevel gt 2 then begin
	message, 'attlevel must be -1(best), 0(raw), 1(smoothed), or 2(definitive)'
    endif
endelse
attlevel = replicate(long(attlevel), n_times)

if not keyword_set(coord) then coord = 'GEI'
if data_type(coord) ne 7 then begin
    message, 'keyword parameter "coord" must be of string type only.'
endif
coord = strupcase(coord)

if not keyword_set(show_inputs)   then show_inputs   = 0
if not keyword_set(show_good_att) then show_good_att = 0
if not keyword_set(show_ext_att)  then show_ext_att  = 0
if not keyword_set(show_bad_att)  then show_bad_att  = 0
if not keyword_set(show_valid)    then show_valid    = 0
show_inputs   = long(show_inputs)
show_good_att = long(show_good_att)
show_ext_att  = long(show_ext_att)
show_bad_att  = long(show_bad_att)
show_valid    = long(show_valid)

; get the pathname of the shared object for attitude
libdir = getenv('FASTLIB')
if keyword_set(libdir) then libdir = libdir + '/' $
else begin
    print, 'Environment variable FASTLIB is not set--can not find idl_get_attitide.so'
    return
endelse
libname = libdir + 'idl_get_attitude.so'
routinename = 'idl_get_attitude'

matrix = dblarr(3,3,n_times)
angles = replicate({spin_struct, spin_ra:0.0D, spin_dec:0.0D, spin_phase:0.D, spin_freq:0.0D}, n_times)
valid = replicate(0L, n_times)

if keyword_set(show_inputs) then begin
    print, 'libname       : ', libname
    print, 'routinename   : ', routinename
    print, 'n_times       : ', n_times
    print, 'coord         : ', coord
    help, times
    help, attlevel
    print, 'show_inputs   : ', show_inputs
    print, 'show_good_att : ', show_good_att
    print, 'show_ext_att  : ', show_ext_att
    print, 'show_bad_att  : ', show_bad_att
endif

print, 'get_fa_attitude: Number attitude points requested = ', n_times 
n_found = 0L;
status = call_external(libname, routinename, $
    show_inputs, show_good_att, show_ext_att, show_bad_att, $
    times, n_times, attlevel, coord, matrix, angles, valid, n_found)
print, 'get_fa_attitude: Number attitude points found     = ', n_found 
matrix = transpose(matrix)

; compute the gap_marks array, which is the array specifying the NaN gap markers
bad_valid_indices = where(valid ne 0 and valid ne 1, bad_valid_count)
if bad_valid_count ne 0 then begin
    print, 'get_fa_attitude: internal programming error: valid array is badly formed.'
endif
valid_indices = where(valid, valid_count)
if (valid_count eq 0) then begin
    message, 'ERROR: no attitude data was found'
endif
extent = replicate(1,n_elements(valid))
first_index = valid_indices(0)
last_index  = valid_indices(n_elements(valid_indices) - 1)
if first_index gt 0 then $
    extent(0:first_index - 1) = 0
if last_index lt (n_elements(valid) - 1) then $
    extent(last_index + 1:n_elements(valid) - 1) = 0
valid1r = shift(valid,1)
valid1r(0) = 0
valid1l = shift(valid,-1)
valid1l(n_elements(valid) - 1) = 0
gap_marks = ((valid1r and not valid) or (valid1l and not valid)) and extent

if keyword_set(show_valid) then begin
    print,'valid'
    print, valid
    print,'gap_marks'
    print, gap_marks
    print,'valid or gap_marks'
    print, valid or gap_marks
    print,'where(valid or gap_marks)'
    print, where(valid or gap_marks)
endif

dNaN = !values.d_nan

not_valid_indices = where(valid ne 1, not_valid_count)
if not_valid_count ne 0 then begin
    angles(not_valid_indices) = {spin_struct, dNaN, dNaN, dNaN, dNaN}
    matrix(not_valid_indices,*,*) = dNaN
endif

; store the data
store_data, 'fa_spin_ra'   , data={x:times, y:angles.spin_ra,    ytitle:'fa_spin_ra'}
store_data, 'fa_spin_dec'  , data={x:times, y:angles.spin_dec,   ytitle:'fa_spin_dec'}
store_data, 'fa_spin_phase', data={x:times, y:angles.spin_phase, ytitle:'fa_spin_phase'}
store_data, 'fa_spin_freq' , data={x:times, y:angles.spin_freq,  ytitle:'fa_spin_freq'}
store_data, 'fa_attlevel'  , data={x:times, y:attlevel,          ytitle:'fa_attlevel'}
matname = 'fa_rotmat_' + strlowcase(coord)
store_data, matname,      data={x:times, y:matrix, ytitle:matname}

return
end

