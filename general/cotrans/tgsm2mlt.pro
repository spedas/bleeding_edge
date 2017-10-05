;+
; PROCEDURE:
;    tgsm2mlt
;
; PURPOSE:
;     Allows a user to convert position data in a tplot variable
;     into a tplot variable containing MLT data
;
; INPUT:
;     in_varname: tplot name of position variable in GSM coordinates
;     out_varname: name of the tplot variable to store the MLT data in
; 
; KEYWORDS:
;     mlat: name of the tplot variable to store the magnetic latitude data in
;
; NOTES:
;     Works on MMS position variables loaded from FGM files (which
;        include the magnitude of the vector as the 4-th component)
;     
;     
; $LastChangedBy: egrimes $
; $LastChangedDate: 2016-01-21 14:59:30 -0800 (Thu, 21 Jan 2016) $
; $LastChangedRevision: 19772 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/cotrans/tgsm2mlt.pro $
;-

pro tgsm2mlt, in_varname, out_varname, mlat = mlat
    ; special case for MMS position variables that contain 
    ; the magnitude in the tplot variable
    get_data, in_varname, data=in_data
    if ~is_struct(in_data) then begin
      dprint, dlevel = 0, 'Error, not a valid tplot variable'
      return
    endif
    store_data, in_varname+'temp', data={x: in_data.X, y: [[in_data.Y[*,0]], [in_data.Y[*,1]], [in_data.Y[*,2]]]}
    
    ; cotrans to SM coordinates
    cotrans, in_varname+'temp', in_varname+'_sm', /gsm2sm
    
    get_data, in_varname+'_sm', data=in_data
    
    mlt_vals = sm2mlt(in_data.Y[*,0], in_data.Y[*,1], in_data.Y[*,2])
    
    store_data, out_varname, data={x: in_data.X, y: mlt_vals}
    options, out_varname, ytitle='MLT (hr)'
    
    if keyword_set(mlat) then begin
        mlat_vals  = atan(in_data.Y[*,2],sqrt(in_data.Y[*,0]^2+in_data.Y[*,1]^2))/!DTOR
        store_data, mlat, data={x: in_data.X, y: mlat_vals}
        options, mlat, ytitle='MLAT (deg)'
    endif
end