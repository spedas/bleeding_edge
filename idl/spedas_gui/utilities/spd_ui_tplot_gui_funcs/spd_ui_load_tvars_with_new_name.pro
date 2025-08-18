; Helper procedure to load a variable with a new user specified name to avoid conflict with an existing variable
; 'name' should be a valid tplot variable name that is already in use
; 'newname' is the name to load the variable under instead
; fail = 0 if variable is successfully loaded under new name

pro spd_ui_load_tvars_with_new_name, name, newname=newname, fail=fail

  compile_opt idl2, hidden
  fail = 1
  guiNames = !spedas.loadedData->GetAll(/Parent)
  tempint = 0
  tempname = name+'_temp_'+strtrim(systime(/julian),1)+'_'+strtrim(tempint,1)
  while in_set(tempname, guiNames) do begin
    tempint ++
    tempname = name +'_temp_'+strtrim(systime(/julian),1)+'_'+strtrim(tempint,1)
  endwhile
  ; Rename existing variable with temp name
  !spedas.loadedData->SetDataInfo,name,newname=tempname,fail=fail
  if fail then return
  ; Load new variable
  if  ~!spedas.loadedData->add(name) then begin
    dprint,"Problem adding: " + name + " to GUI"
    ; Rename original variable with its original name
    !spedas.loadedData->SetDataInfo,tempname, newname=name, fail=fail
    fail=1 ;unable to add variable so always a fail 
    return
  endif
  ; Rename new variable with user specified name
  !spedas.loadedData->SetDataInfo,name,newname=newname,fail=fail
  if fail then return
  ; Rename original variable with its original name
  !spedas.loadedData->SetDataInfo,tempname, newname=name, fail=fail
  
end
