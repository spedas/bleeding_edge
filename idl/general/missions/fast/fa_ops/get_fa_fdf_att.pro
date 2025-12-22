;+
;FUNCTION: get_fa_fdf_att(time)
;NAME:
;  get_fa_fdf_att
;PURPOSE:
; Get the spin attidude vector for the given time from
; the FDF attitude files.
;
;INPUT:  time input must be of a type which is valid as
;        an input to time_double, array's exceptable.
;  
;OUTPUT: att_struc structure:
;         elements: x, y, z, zsun, lambda, phi
;        all elements are double.
;
;KEYWORDS:
;  FILE: if set, use given FDF attitude file name.
;  FDF_DIR:  if set, use given string as directory in which to find
;    FDF files.
;
;ENVIRONMENT VARIABLES:
;  FAST_FDFATT_DIR  if set, provides the default directory to
;    consult when looking for FDF attitude files.  Is overridden by 
;    the keyword FDF_DIR.
;
;SEE ALSO:  "time_double"
;
;CREATED BY:	KRB 1997-09-11
;FILE:  %M%
;VERSION:  %I%
;LAST MODIFICATION:  %E%
;  added FDF_DIR keyword for use outside of the ``Ivory Tower''.
;  also changed SPAWN calls to allow for noisy shell startup scripts.
;  JWB, LANL, 04-29-98
;  added examination of environment variable FAST_FDFATT_DIR to
;  allow for more transparent changing of default directory for
;  FDF attitude files.  JWB, LANL, 05-08-98.
;  fixed y2k bug in FDF file sorting.  JWB, UCBSSL, 02-01-2000.
;
;-
function get_fa_fdf_att, intime, file=files, fdf_dir=fdf_dir

time = time_double(intime)

; sort times now.  We will need this for all our trickery

sort_indices = sort(time)
time = time[sort_indices]

; determine what directory to consult for FDF attitude files.
if not keyword_set( fdf_dir) then begin
  dir = getenv('FAST_FDFATT_DIR')
  if (dir eq '') then begin
      dir = '/disks/juneau/www/att'
  endif
endif else begin
  dir = fdf_dir
endelse

if not keyword_set(files) then BEGIN
; find the appropriate attitude file(s)

    ts = time_struct(time)

    spawn, [ 'ls', dir], attfiles, /noshell

    attfyr = float(strmid(attfiles, 1, 2))
    attfdoy = float(strmid(attfiles, 3, 3))

    
    thisc = where(attfyr GT 90, nthis)
    thatc = where(attfyr LT 90, nthat)

    if nthis GT 0 then attfyr(thisc) = attfyr(thisc) + 1900
    if nthat GT 0 then attfyr(thatc) = attfyr(thatc) + 2000

    attfdv = attfyr*400. + attfdoy
    tdv = ts.year*400. + ts.doy
    
; time-order attfdv via sort.
    ss = sort( attfdv)
    attfdv = attfdv[ ss]
    
    minfindex = max(where(attfdv LT tdv[0]))
    maxfindex = min(where(attfdv GT (tdv[n_elements(tdv)-1])))

    if (minfindex LT 0) and (maxfindex LT 0) then begin
        print, "No attitude files for given times"
        return, -1
    endif else  begin
        if minfindex LT 0 then minfindex = 0
        if maxfindex LT 0 then maxfindex = n_elements(attfiles) - 1
        if minfindex EQ maxfindex then maxfindex = minfindex + 1
    endelse
    
; create a time-sorted list of desired FDF files.
    files = attfiles[ ss[ indgen(maxfindex - minfindex) + minfindex]]

ENDIF

; build up an array of predict values sucked out of fdf files.  Make sure
; to truncate each file when the next one is read to get the updated values.

files = dir + '/' + files

; /nospawn modification to allow for folks with .cshrc's that talk.
command = [ 'wc', '-l', files ]
spawn, command, count, /noshell

if n_elements(count) gt 1 then 					$
  count = long(strmid(count[0:n_elements(count)-2],0,12)) 	$
else   count = long(strmid(count,0,12))

dims = count-7

for f = 0, n_elements(files)-1 do begin
    
    ar = dblarr(7,dims[f])

    openr, unit, files[f], /get_lun

    s = 'dummy'
    readf,unit, s
    readf,unit, s
    readf,unit, s
    readf,unit, s
    readf,unit, s
    readf,unit, s
    readf,unit, s
      
    readf,unit, ar
    free_lun,unit
    
    ; cat on next file here
    if n_elements(a) EQ 0 then a = ar else begin
        a = a[*,where(a[0,*] lt ar[0,0])]
        ; (We must reform the array to concatenate to it)
        a=reform(a,n_elements(a))
        ar=reform(ar,n_elements(ar))
        a = [ a , ar ]
        a=reform(a,7,n_elements(a)/7)
    endelse
endfor

a = transpose(a)

; convert each file time to time_struct format

tsts = make_array(value=time_struct(time[0]),dim=dimen1(a))

t = string(format='(F15.6)',a(*,0))
tsts.year = strmid(t, 0, 4)
tsts.month = strmid(t, 4, 2)
tsts.date = strmid(t, 6, 2)
tsts.hour = strmid(t, 9, 2)
tsts.min = strmid(t, 11, 2)
tsts.sec = strmid(t, 13, 2)
t = time_double(tsts)

; get att values from apporprate columns

x = a(*,1)
y = a(*,2)
z = a(*,3)
zsun = a(*,4)
lambda = a(*,5)
phi = a(*,6)

; and interpolate 

vec = replicate (   							$
                  {att_struct,x:0.d,y:0.d,z:0.d,zsun:0.d,lambda:0.d,phi:0.d}, $
                  n_elements(time))

; (Note that the if statement here shouldn't be necessary, but idl
;  doesn't handle setting scalers to 1-elements arrays gracefully.)
if n_elements(time) EQ 1 then begin
    vec.x = (ff_interp(time, t, x, delt_t=36000))(0)
    vec.y = (ff_interp(time, t, y, delt_t=36000))(0)
    vec.z = (ff_interp(time, t, z, delt_t=36000))(0)
    vec.zsun = (ff_interp(time, t, zsun, delt_t=36000))(0)
    vec.lambda = (ff_interp(time, t, lambda, delt_t=36000))(0)
    vec.phi = (ff_interp(time, t, phi, delt_t=36000))(0)
endif else begin
    vec.x = ff_interp(time, t, x, delt_t=36000)
    vec.y = ff_interp(time, t, y, delt_t=36000)
    vec.z = ff_interp(time, t, z, delt_t=36000)
    vec.zsun = ff_interp(time, t, zsun, delt_t=36000)
    vec.lambda = ff_interp(time, t, lambda, delt_t=36000)
    vec.phi = ff_interp(time, t, phi, delt_t=36000)
endelse

; unsort as was input times

vecret = vec
vecret(sort_indices) = vec

return, vecret

END
