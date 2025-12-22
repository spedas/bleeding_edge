;+
; PROCEDURE: make_quality
;
; PURPOSE: create a quality flag for use in a CDF from a
;          representation of a set of variables
;
; DETAILS:
;     When dealing with a set of variables that are all time-based
;     arrays, based on the same time array, one simple notion of data
;     quality is that quality = 0 for those times for which all data
;     variables have defined values, and quality = 255 for any time
;     for which one or more variables have a value for which 1 or more
;     components are missing or invalid.  This routine is used to
;     generate such a simple form of quality flag.
;
; INPUTS:     
;     data:
;         a structure of the following form:
;     
;         data = {dummy1: {name:'time', value:time}, $
;                 dummy2: {name:'var1', value:var1}, $
;                 dummy3: {name:'var2', value:var2}, $
;                 dummy4: {name:'var3', value:var3}}
;
;         that is used to represent the data to be written to a CDF file.
;         The values of the 'name' fields are the names of the
;         variables, and the values of the 'value' fields are the
;         values of the variables.  The first field of 'data' is an
;         array of times, and the other variables are all arrays based
;         on this time array.  See makecdf2.pro for more details.
;         Some of the values may contain missing or invalid values.
;         Missing or invalid values are signified either by NaN, or by
;         the following special values that are used by CHDF CDF files
;         as FILLVAL's.
;
;                 type            FILLVAL
;                 ----            -------
;                 BYTE            -128
;                 INT2            -32768
;                 INT4            -2147483648
;                 REAL4           -1.0e31
;                 REAL8           -1.0d31
;
;         Any value containing either NaN or the appropriate above
;         FILLVAL for the type is considered either missing or otherwise 
;         invalid.
;
; OUTPUT:
;     return value: the return value (which we will call 'quality'
;     here), is an byte array of the same size as the time array from
;     'data'.  That is, n_elements(quality) =
;     n_elements(data.(0).value).  Also, quality(i) = 0 if all the
;     variables are defined and present for the ith time value, and
;     quality(i) = 255 if any of the variables contain a NaN or
;     FILLVAL for the ith time value.
;
; VERSION: @(#)make_quality.pro	1.3 05/03/99
;-


function make_quality, data

n_vars = n_tags(data) - 1
if n_vars lt 1 then begin
    print, "make_quality: struct 'data' must have at least two tags."
    return,0
endif

if ndimen(data.(0).value) ne 1 then begin
    print, "make_quality: first field of 'data' must have 'value' field of dimension 1."
    return,0
endif
n_times = dimen1(data.(0).value)

for i = 1, n_vars do begin
    if dimen1(data.(i).value) ne n_times and (data.(i).recvary eq 1) then begin
        print, "make_quality: field ", i, " of 'data' has 'value' field of dimen1 = ", $
          dimen1(data.(i).value)
        return,0
    endif
endfor

; define bad_var_vals(i,j) = 1 if for time i, var j has a bad value, else 0
bad_var_vals = make_array(n_times, n_vars, /long, value=1)
for j = 0, n_vars - 1 do begin
    if data.(j+1).recvary eq 1 then begin
        value = data.(j + 1).value
        case data_type(value) of
            1: begin
                bad_var_vals(*,j) = total_trailing_dims(long(value eq byte(-128)))
            end
            2: begin
                bad_var_vals(*,j) = total_trailing_dims(long(value eq fix(-32768)))
            end
            3: begin
                bad_var_vals(*,j) = total_trailing_dims(long(value eq long(-2147483648)))
            end
            4: begin
                bad_var_vals(*,j) = total_trailing_dims(long(value eq -1.0e31 or (finite(value) eq 0)))
            end
            5: begin
                bad_var_vals(*,j) = total_trailing_dims(long(value eq -1.0d31 or (finite(value) eq 0)))
            end
            else: return,0
        endcase
    endif else begin
        bad_var_vals(*,j) = 0
    endelse
endfor
badness = total(bad_var_vals, 2) gt 0

; wherever badness is 0, set quality to 0, wherever badness is 1, set quality to 255
quality = long(badness)
index = where(quality eq 1, count)
if count gt 0 then quality(index) = 255

return, quality
end

