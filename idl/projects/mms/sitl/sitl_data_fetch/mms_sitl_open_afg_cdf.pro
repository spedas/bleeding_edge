; This opens a CDF file containing AFG data
; It also returns the ephemeris. NOTE it returns PREDICTED ephemeris.

function mms_sitl_open_afg_cdf, filename

var_type = ['data']
CDF_str = cdf_load_vars(filename, varformat=varformat, var_type=var_type, $
  /spdf_depend, varnames=varnames2, verbose=verbose, record=record, $
  convert_int1_to_int2=convert_int1_to_int2)
    
; Get time data

times_TT_nanosec = *cdf_str.vars[0].dataptr
times_unix = time_double(times_TT_nanosec, /tt2000)

dmpa_vector_data = *cdf_str.vars[1].dataptr
dmpa_varname = cdf_str.vars[1].name
  
pgsm_vector_data = *cdf_str.vars[2].dataptr
pgsm_varname = cdf_str.vars(2).name

if ptr_valid(cdf_str.vars[10].dataptr) then begin
  ephem_data = *cdf_str.vars[10].dataptr
  ephem_name = cdf_str.vars[10].name
  ephem_times_TT_nanosec = *cdf_str.vars[5].dataptr
  ephem_times_unix = time_double(ephem_times_TT_nanosec, /tt2000)

  ; Grab epehem data
  posx = ephem_data(*,0)
  posy = ephem_data(*,1)
  posz = ephem_data(*,2)
  posr = ephem_data(*,3)

  posvector = [[posx],[posy],[posz],[posr]]

endif else begin
  ephem_name = ''
  ephem_times_unix = 0
  posvector = [[0],[0],[0],[0]]
endelse

; Says data is in orthogonalized boom coordinates.
bx_p = pgsm_vector_data(*,0)
by_p = pgsm_vector_data(*,1)
bz_p = pgsm_vector_data(*,2)

bx_d = dmpa_vector_data(*,0)
by_d = dmpa_vector_data(*,1)
bz_d = dmpa_vector_data(*,2)


pgsm_bvector = [[bx_p], [by_p], [bz_p]]
dmpa_bvector = [[bx_d], [by_d], [bz_d]]

outstruct = {x: times_unix, y_dmpa:dmpa_bvector, y_pgsm: pgsm_bvector, pgsm_varname: pgsm_varname, dmpa_varname:dmpa_varname, ephemx:ephem_times_unix, ephemy: posvector, ephem_varname: ephem_name}

return, outstruct

end