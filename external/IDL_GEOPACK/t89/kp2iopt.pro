;+
;Function: kp2iopt
;
;Purpose: Convert a tplot or array Kp index variable to iopt values suitable for passing to the T89 field
;         modeling or tracing routines.
;         
;         Input Kp values will be in the range of 0 to 6, and may have a fractional part indicating an increasing or decreasing index. 
;         For example, 2.33333 represents 2+,  2.66666 represents 3-. iopt output values will be in the range 1 to 7.
;         
;
;Input: Kp values (e.g. from noaa_load_kp)
;
;Return value: IOPT values suitable for passing to the GEOPACK T89 tracing and modeling routines.  Represented as double precision floating
;        point for compatibility with GEOPACK library calling sequences, but may or may not be rounded to integer values depending
;        on whether the kp_plus1 keyword is specified.
;        
;
;Keywords:
;         kp:  (input) A scalar  or array of Kp values, or name of a tplot variable giving the Kp index values
;         
;         varname (Required if kp is a tplot variable): A string specifying a tplot position variable.  Output iopt values will be interpolated to the 'varname' times
;                  using nearest-neighbor interpolation.
;
;         plus1: (optional)  If specified, overrides the default behavior of rounding iopt to the nearest integer, and
;                 instead sets iopt to kp+1, preserving any fractional part.
;
;Example:
;
; $LastChangedBy: jwl $
; $LastChangedDate: 2021-07-28 18:16:15 -0700 (Wed, 28 Jul 2021) $
; $LastChangedRevision: 30156 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/external/IDL_GEOPACK/ta15/tomni2bindex.pro $
;-

function kp2iopt, kp,varname=varname, plus1=plus1

    ;if kp is a string, assume kp is stored in a tplot variable
    if size(kp,/type) eq 7 then begin
      if tnames(kp) eq '' then begin
        message,'kp is of type string but no tplot variable exists with name='+kp
      endif

      ;make sure there are an appropriate number of kp values in the array
      tinterpol_mxn,kp,varname,newname='kp_int_temp',/nearest_neighbor,/ignore_nans,error=e

      if e ne 0 then begin
        get_data,'kp_int_temp',data=d_kp
        kp_dat = d_kp.y
      endif else begin
        message,'error interpolating kp onto position data '+varname
      endelse

    endif else kp_dat = kp  ; if not a tplot variable
       
    ; Now convert kp_dat to iopt values
    if keyword_set(plus1) then iopt=kp_dat+1.0D else iopt=double(floor(kp_dat+1.5D))
    ; Force to valid iopt range
    iopt=iopt > 1.0D
    iopt=iopt < 7.0D
    return, iopt
end
