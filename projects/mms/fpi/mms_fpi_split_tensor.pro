;+
;
; PROCEDURE:
;       mms_fpi_split_tensor
; 
; PURPOSE:
;       Splits FPI tensor variables (pressure, temperature) into their components
;
;
; $LastChangedBy: egrimes $
; $LastChangedDate: 2017-01-05 18:04:40 -0800 (Thu, 05 Jan 2017) $
; $LastChangedRevision: 22516 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/fpi/mms_fpi_split_tensor.pro $
;-
pro mms_fpi_split_tensor, tensor_variable
  get_data, tensor_variable, data=d
  if ~is_struct(d) then return 
  
  xx = d.Y[*, 0, 0]
  xy = d.Y[*, 0, 1]
  xz = d.Y[*, 0, 2]
  yx = d.Y[*, 1, 0]
  yy = d.Y[*, 1, 1]
  yz = d.Y[*, 1, 2]
  zx = d.Y[*, 2, 0]
  zy = d.Y[*, 2, 1]
  zz = d.Y[*, 2, 2]
  
  store_data, tensor_variable+'_xx', data={x: d.x, y: xx}
  store_data, tensor_variable+'_xy', data={x: d.x, y: xy}
  store_data, tensor_variable+'_xz', data={x: d.x, y: xz}
  store_data, tensor_variable+'_yx', data={x: d.x, y: yx}
  store_data, tensor_variable+'_yy', data={x: d.x, y: yy}
  store_data, tensor_variable+'_yz', data={x: d.x, y: yz}
  store_data, tensor_variable+'_zx', data={x: d.x, y: zx}
  store_data, tensor_variable+'_zy', data={x: d.x, y: zy}
  store_data, tensor_variable+'_zz', data={x: d.x, y: zz}

end
