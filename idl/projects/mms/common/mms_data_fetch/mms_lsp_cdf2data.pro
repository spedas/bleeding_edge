function mms_lsp_cdf2data, cdfi, varname=varname, var_type=var_type, coord=coord, index=index, status=status 
status = 0
nv = cdfi.nv
vars = cdfi.vars
ind = 0

for i=0, nv -1 do begin
  if vars[i].dataptr ne !NULL then ind = [ind, i]
endfor
if total(ind) eq 0 then begin
status = 1
message, 'MMS_LSP_CDF2DATA: COULD NOT FIND DATA FROM CDF'
return, 0
endif else begin
ind = ind[1:-1]
endelse
vars = vars[ind] 

var = 0.
att = 0
flag = 0
i = 0

while flag eq 0 and i lt n_elements(vars) do begin 
  name = vars[i].name
  datatype = vars[i].datatype
  dataptr = vars[i].dataptr
  
  attptr = vars[i].attrptr
  if keyword_set(varname) then flag = strcmp(name, varname, /fold_case)
  if keyword_set(vartype) then flag = total(strcmp(strsplit(datatype, '_', /extract), vartype, /fold_case)) 
  if keyword_set(coord) then flag = total(strcmp(strsplit(name, '_', /extract), coord, /fold_case))
  if keyword_set(index) and flag eq 1 then index = i 
  if flag eq 1 then begin
    var = *dataptr
    att = attptr
  endif
  i += 1
endwhile

result = {t:*vars[0].dataptr, x: var, tatt:vars[0].attrptr, xatt: attptr }
var_size = n_elements(var)
if var_size gt 1 then status = 0 else status = 1
if status eq 1 then begin
  message, 'MMS_LSP_CDF2DATA: COULD NOT FIND DATA FROM CDF', /continue
  return, 0
endif else begin
return, result
endelse
end