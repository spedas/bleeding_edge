;+
;FUNCTION: geomag(time [, time2])
;NAME:
;  geomag
;PURPOSE:
;  Gets geomag data kp, ap, and dsp for given times.
;
;INPUT:  input(s) can be scalers or arrays of any dimension of type:
;  double(s)      seconds since 1970
;  string(s)      format:  YYYY-MM-DD/hh:mm:ss
;  structure(s)   format:  given in "time_struct"
;                 values outside normal range will be corrected.
;
;  If optional parameter time2 is passed, geomag data returned are
;  averaged over the time interval from time to time2.
;
;OUTPUT:
;  structure: {geomag, kp:0.d, ap:0.d, dst:0.d}
;
;NOTE:
;  This routine works on vectors.
;  Output will have the same dimensions as the input.
;
;CREATED BY:	Ken Bromund  Dec 1997
;FILE:  geomag.pro
;VERSION:  1.5
;LAST MODIFICATION:  98/01/06
;-
function geomag, time, time2

start_t = time_string(time, /sql)

if n_params() eq 1 then begin
    finish_t = start_t
end else begin
    if n_elements(time2) ne n_elements(time) then begin
        print, "time and time2 must have same number of elements"
        return, -1
    end
    finish_t = time_string(time2, /sql)
end

con = obj_new('sybcon')

; get the first row, which will define the structure format for us.
query = 'select kp=avg(kp), ap=avg(ap), dst=avg(dst) from geomag where ' + $
  'start <= ' + finish_t(0) + ' and finish > ' + start_t(0)
ret = con->send(query, 'geomag')
data = make_array(value={geomag}, dim=dimen(time))
ret = con->fetch(row)
data(0) = row

for j = 1, n_elements(time)-1 do begin
    query = 'select kp=avg(kp), ap=avg(ap), dst=avg(dst) from geomag where ' +$
      'start <= ' + finish_t(j) + ' and finish > ' + start_t(j)
    ret = con->send(query, 'geomag')
    ret = con->fetch(row)
    data(j) = row
end
obj_destroy, con
return, data
end


