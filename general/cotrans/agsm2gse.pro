;+
; Procedure: agsm2gse
;
; Purpose: 
;      Converts between aberrated GSM coordinates and GSE coordinates
;
; Inputs:
;      in_data: structure containing data to be transformed in AGSM coordinates
;   
; Output: 
;      out_data: structure containing the transformed data in GSE coordinates
;   
; Keywords:
;      sw_velocity (optional): vector containing solar wind velocity data, [Vx, Vy, Vz] in GSE coordinates
;      rotation_angle (optional): angle to rotate about the Z axis to point into the solar wind (degrees)
;
; Notes:
;     Either the solar wind velocity (/sw_velocity) or rotation angle (/rotation_angle) keyword
;     needs to be defined to do the transformation
;      
; Examples:
;    In the following example, the data to be transformed into GSE coordinates 
;      is in a standard tplot variable named 'position_agsm'. 
;    
;    get_data, 'position_agsm', data=position_agsm
;     
;    ; load solar wind velocity data using OMNI (GSE coordinates, km/s)
;    omni_hro_load, varformat=['Vx', 'Vy', 'Vz']
;    
;    ; remove NaNs from the solar wind velocity
;    tdeflag, ['OMNI_HRO_1min_Vx', 'OMNI_HRO_1min_Vy', 'OMNI_HRO_1min_Vz'], 'remove_nan'
;
;    ; get the IDL structures containing the velocity components
;    get_data, 'OMNI_HRO_1min_Vx_deflag', data=Vx_data
;    get_data, 'OMNI_HRO_1min_Vy_deflag', data=Vy_data
;    get_data, 'OMNI_HRO_1min_Vz_deflag', data=Vz_data
;    
;    option 1:
;        ; do the transformation to aberrated GSM (aGSM) using a rotation angle
;        agsm2gse, position_agsm, gse_pos_from_angle, rotation_angle=4.0
;    
;    option 2:
;        ; do the transformation to aberrated GSM (aGSM) using solar wind velocity loaded from OMNI
;        agsm2gse, position_agsm, gse_pos_from_vel, sw_velocity = [[Vx_data.Y], [Vy_data.Y], [Vz_data.Y]]
;    
;
; $LastChangedBy: egrimes $
; $LastChangedDate: 2015-05-19 15:55:02 -0700 (Tue, 19 May 2015) $
; $LastChangedRevision: 17652 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/cotrans/agsm2gse.pro $
;-
pro agsm2gse, data_in, data_out, sw_velocity = sw_velocity, rotation_angle = rotation_angle
    cotrans_lib
    ; check the input
    if is_string(data_in) then begin
        ; received a tplot variable as input
        
        if n_elements(tnames(data_in)) gt 1 then begin
            dprint, dlevel = 1, 'agsm2gse only supports one input at a time'
            return
        endif
        if ~tnames(data_in) then begin
            dprint, dlevel = 1, 'string input is not a valid tplot variable'
            return
        endif
        
        get_data, data_in, data=in_data_struct, dlimits=in_dlimits_struct, limits=in_limits_struct
    endif else if is_struct(data_in) then begin
        ; received a structure as input
        in_data_struct = data_in
    endif else begin
        dprint, dlevel = 1, 'Error in agsm2gse, input data must be a structure'
        return
    endelse

    dprint, 'aGSM -> GSE'
    
    ; rotate to aGSE coordinates
    sub_GSE2aGSM,in_data_struct,agse_out,/aGSM2GSE

    ; now do the abberation
    ; rotate about the z-GSE axis by an angle, rotation_angle
    if ~undefined(rotation_angle) then begin
        ; user provided the rotation angle
        rot_y = rotation_angle*!dtor
    endif else if ~undefined(sw_velocity) then begin
        ; user provided the solar wind velocity
        ; rotation angle about Z-GSE axis
        ; assumes Earth's orbital velocity relative to the sun is ~30km/s
        avg_sw_y = average(sw_velocity[*,1])
        avg_sw_x = average(sw_velocity[*,0])
        rot_y = atan((float(avg_sw_y)+30.)/abs(float(avg_sw_x)))
    endif else begin
        ; the user did not provide a rotation angle or solar wind velocity
        dprint, dlevel = 1, 'Error converting between aGSE and GSE coordinates - no rotation angle provided'
        return
    endelse 
    ; rotating from GSE to aGSE is ~+4 deg, from aGSE to GSE is ~-4 deg
    rot_y = -rot_y

    sin_rot = sin(rot_y)
    cos_rot = cos(rot_y)

    thematrix = [[cos_rot, -sin_rot, 0.0],[sin_rot, cos_rot, 0.0], [0.0, 0.0, 1.0]]

    in_data = [[agse_out.Y[*,0]], [agse_out.Y[*,1]], [agse_out.Y[*,2]]]

    ; now do the aberration in GSE
    the_arr = thematrix#transpose(in_data)

    x_out = transpose(the_arr[0,*])
    y_out = transpose(the_arr[1,*])
    z_out = transpose(the_arr[2,*])

    if is_struct(in_dlimits_struct) && is_struct(data_att) then begin
        str_element, data_att, 'coord_sys', 'gse', /add_replace
        str_element, in_dlimits_struct, 'data_att', data_att, /add_replace
    endif
    
    if is_string(data_out) then begin
        store_data, data_out, data={x: in_data_struct.X, y: [[x_out], [y_out], [z_out]]}, dlimits=in_dlimits_struct
    endif else begin
        data_out = {x: data_in.X, y: [[x_out], [y_out], [z_out]]}
    endelse
    
end