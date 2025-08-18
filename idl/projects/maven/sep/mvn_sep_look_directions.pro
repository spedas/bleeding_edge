; the purpose of this procedure is to calculate the 4 look directions of the MAVEN SEP sensors

; if the 'utc' keyword is set, 

function mvn_sep_look_directions, trange=trange, coordinate_frame = coordinate_frame, load_kernels = load_kernels, $
  delta_t = delta_t, utc = utc, clear = clear
  
  if not keyword_set (trange) and ~keyword_set (utc) then message, 'must specify either a time range or an array  of utc times'
  if keyword_set (trange) then trange = time_double (trange)
  if keyword_set (utc)  then utc = time_double (utc)
  
  
  
  if not keyword_set (utc) then begin
    if not keyword_set (delta_t) then delta_t = 32
    total_time = trange [1] - trange [0]
    times = trange[0] + delta_t*dindgen(ceil(total_time/delta_t))
  endif else times = utc
  et = time_ephemeris(times)  

  if not keyword_set (coordinate_frame) then coordinate_frame = 'MAVEN_SSO'
  
  if keyword_set (load_kernels) then begin
; clear away all other kernels
     cspice_kclear; this clears away and unloads all kernels.
     maven_kernels = mvn_spice_kernels(tr = [min(times,/nan),max(times,/nan)],/load)
   endif

; The following are the unit vectors in each coordinate system of the centers of the FOVs of each SEP sensor


ntimes = n_elements (times)
SEP_FOV_front = [1.0, 0, 0]#replicate (1.0,ntimes)
SEP_FOV_back = [-1.0, 0, 0]# replicate (1.0,ntimes)

SEP_look_directions = fltarr(4, 3,ntimes)
SEP_look_directions [0,*,*] = $
  spice_vector_rotate(SEP_FOV_front,times,et=et,'MAVEN_SEP1',coordinate_frame,check_objects='MAVEN_SC_BUS')
SEP_look_directions [1,*,*] = $
  spice_vector_rotate(SEP_FOV_back,times,et=et,'MAVEN_SEP1',coordinate_frame,check_objects='MAVEN_SC_BUS')
SEP_look_directions [2,*,*] = $
  spice_vector_rotate(SEP_FOV_front,times,et=et,'MAVEN_SEP2',coordinate_frame,check_objects='MAVEN_SC_BUS')
SEP_look_directions [3,*,*] = $
  spice_vector_rotate(SEP_FOV_back,times,et=et,'MAVEN_SEP2',coordinate_frame,check_objects='MAVEN_SC_BUS')

  if keyword_set (clear) then cspice_kclear; this clears away and unloads all kernels.
return, {time: times, SEP_look_directions:SEP_look_directions}
end
 