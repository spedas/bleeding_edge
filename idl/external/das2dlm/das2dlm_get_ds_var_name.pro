;+
; PRO: das2dlm_get_ds_var_name, ...
;
; Description:
;    Return the name of the data variable in the dataset. 
;
; Keywords:
;    ds: Dataset returned by das2c_datasets(query)
;    vnames: list of names of the data variable
;    exclude (optional): array of variables to exclude from the list  
;
; CREATED BY:
;    Alexander Drozdov (adrozdov@ucla.edu)
;    
; NOTE:
;   This function is under active development. Its behavior can change in the future.
;
; $LastChangedBy: adrozdov $
; $Date: 2021-01-25 20:24:16 -0800 (Mon, 25 Jan 2021) $
; $Revision: 29620 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/external/das2dlm/das2dlm_get_ds_var_name.pro $
;-

pro das2dlm_get_ds_var_name, ds, vnames=vnames, exclude=exclude

  pdims = das2c_pdims(ds) ; get all pdims
  nd = size(pdims, /n_elem)
  ; Get all variables
  vnames = []
  for i=0,nd-1 do begin
    name = pdims[i].pdim
    ; exlude variables that we don't want (e.g 'time')
    if array_contains(exclude, name) then continue    
    vnames = [vnames, name]    
  endfor
end