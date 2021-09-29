;+
; PRO: das2dlm_get_ds_var, ...
;
; Description:
;    Loads physical dimensions, variables, methadata and data from das2dlm dataset
;    Works only with 1D variables 
;
; Keywords:
;    ds: Dataset returned by das2c_datasets(query)
;    name: dimension name (e.g. 'time')
;    role: variable role (e.g. 'center');    
;    p: Physical dimension, das2c_pdims
;    v: Variable, das2c_vars
;    m: Properties, das2c_props
;    d: Data, das2c_data
;
; CREATED BY:
;    Alexander Drozdov (adrozdov@ucla.edu)
;    
; NOTE:
;   This function is under active development. Its behavior can change in the future.
;
; $LastChangedBy: adrozdov $
; $Date: 2020-08-03 20:45:11 -0700 (Mon, 03 Aug 2020) $
; $Revision: 28983 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/external/das2dlm/das2dlm_get_ds_var.pro $
;-

pro das2dlm_get_ds_var, ds, name, role, p=p, v=v, m=m, d=d

  p = das2c_pdims(ds, name) ; physical dimension
  v = das2c_vars(p, role) ; variable
  m = das2c_props(p) ; properties (metadata)  
  d = das2c_data(v) ; data

end