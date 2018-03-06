;+ 
;NAME: 
; spd_ui_loaded_data__define
;
;PURPOSE:
; This is an array of data objects and represents all the data that has been loaded
; for this session.
;
;CALLING SEQUENCE:
;
;OUTPUT:
; reference to data object array
;
;ATTRIBUTES:
; array of data objects
;
;METHODS:
; Add             adds a new tplot variable to the loaded data object by tplot variable name
; Remove          removes an object from the array by name or group name
; GetAll          returns an array of all data names
; GetActive       returns a list of all data that is currently displayed
; GetChildren     returns a list of the children for a particular variable name
; SetActive       makes a data object active given a tplot name
; IsActive        Checks if a variable with a given name is active
; IsParent        Checks if a variable with a given name is a parent
; IsChild         Checks if a variable with a given name is a child
; ClearActive     makes a data object inactive
; ClearAllActive  clears all active data objects
; GetVarData      gets the data component from a variable.  For a group variable, the routine
;                 will need to compose the data first
; GetTvarData     gets a tplot variable,  For a group data structure it will construct
;                 a new tplot variable.  
; GetObjects      returns an array of all data objects, can also take a name or group name
;
;  NOTE: 
;  
;  1. You should use 'getTvarData' to generate a
;  tplot variable that has all the dimensions of the variable composed
;  as a single entity.  After you have modified the variable you
;  should you 'add', to add the data back in to the data structure. 
;  
;  2. Note also, that you don't need to have separate rules to data process parents and children, if you use
;  the same getTvarData/add workflow above for children variables, it
;  will work fine.
;
;  3. INIT takes an argument, /autoload. If that is set, the load routine will load all the tplot variables in
;  memory, but not all the metadata for the variables will be set correctly.
;
;
;HISTORY:
;
;$LastChangedBy: jimmpc1 $
;$LastChangedDate: 2018-03-05 14:00:03 -0800 (Mon, 05 Mar 2018) $
;$LastChangedRevision: 24830 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas_gui/objects/spd_ui_loaded_data__define.pro $
;-----------------------------------------------------------------------------------


;component_names: returns the names of the data variables added(but not yaxis or time), it is mainly used internally to implement a recursive call, but if it is useful, please use it.
FUNCTION SPD_UI_LOADED_DATA::Add, name, file=file, mission=mission,observatory=observatory,coordSys=coordSys,instrument=instrument,timerange=timerange,isSpect=isSpect,groupname=groupname,component_names=component_names,added_name=added_name,units=units,yaxisunits=yaxisunits,isYaxis=isYaxis,suffix=suffix,indepName=indepName,yaxisparent=yaxisparent

  compile_opt idl2
  
  if ~tnames(name) then begin
    ok = error_message('Add called without a tplot variable',/traceback,/center,title='Data Load Error')
    return,0
  endif
      
  get_data, name, data=d,limits=l,dlimits=dl
  
  if ~is_struct(d) then begin
  
    ok = error_message('Problem Loading: ' + name + '.  Quantity does not have valid data.',/center,traceback=0,title='Data Load Problem')
    return,0
  
  endif
  if size(d.x,/type) ne 5 then begin
    ok = error_message('Cannot load "'+name+'". The x-axis must contain double precision floating point data.',/noname,/center, title='Data Load Error', traceback=0)
    return, 0
  endif
  
  return,self->addData(name,d,limit=l,dlimit=dl,file=file, mission=mission,observatory=observatory,instrument=instrument,timerange=timerange,isSpect=isSpect,groupname=groupname,component_names=component_names,added_name=added_name,units=units,yaxisunits=yaxisunits,isYaxis=isYaxis,suffix=suffix,indepName=indepName,yaxisparent=yaxisparent)
    
end

;operates directly on data structs not tplot variables
FUNCTION spd_ui_loaded_data::addData,in_name,d,limit=l,dlimit=dl,file=file, mission=mission,observatory=observatory,coordSys=coordSys,instrument=instrument,timerange=timerange,isSpect=isSpect,groupname=groupname,component_names=component_names,added_name=added_name,units=units,yaxisunits=yaxisunits,isYaxis=isYaxis,suffix=suffix,indepName=indepName,yaxisparent=yaxisparent

  compile_opt idl2

  ;if ~keyword_set(mission) then mission = 'none'
  ;if ~keyword_set(observatory) then observatory = 'none'
  ;if ~keyword_set(instrument) then instrument = 'none'
  if n_elements(in_name) gt 1 then begin
    ok = error_message('Problem Loading: ' + in_name + '.  Can only load one name at a time.',/center,traceback=0,title='Data Load Problem')
    return,0
  endif 
  
  name = in_name[0]
  
  if ~keyword_set(suffix) then suffix = ''
  
  if ~is_struct(d) then begin
  
    ok = error_message('Problem Loading: ' + name + '.  Quantity does not have valid data.',/center,traceback=0,title='Data Load Problem')
    return,0
  
  endif
  
  if ~in_set(tag_names(d),'X') then begin
  
    ok = error_message('Problem Loading: ' + name + '.  Quantity does not have valid X component.',/center,traceback=0,title='Data Load Problem')
    return,0
  
  endif
  
  if ~is_num(d.x) then begin
  
    ok = error_message('Problem Loading: ' + name + '.  X component is not a numeric type',/center,traceback=0,title='Data Load Problem')
    return,0
  
  endif
  
  if ~in_set(tag_names(d),'Y') then begin
  
    ok = error_message('Problem Loading: ' + name + '.  Quantity does not have valid Y component.',/center,traceback=0,title='Data Load Problem')
    return,0
  
  endif
  
  
  if ~is_num(d.y) then begin
  
    ok = error_message('Problem Loading: ' + name + '.  Y component is not a numeric type',/center,traceback=0,title='Data Load Problem')
    return,0
  
  endif
  dSize = dimen(d.y)
  dxSize = dimen(d.x)
  
  if n_elements(dSize) gt 2 then begin
    ok = error_message('Problem Loading: ' + name + '.  GUI data model does not currently support data with dimensions greater than 2.',/center,traceback=0,title='Data Load Problem')
    return,0
  endif
  
  if n_elements(dxSize) gt 1 then begin
    ok = error_message('Problem Loading: ' + name + '.  GUI data model does not currently support data times with dimensions greater than 1.',/center,traceback=0,title='Data Load Problem')
    return,0
  endif
  
  if dsize[0] ne n_elements(d.x) then begin
    ok = error_message('Problem Loading: ' + name + '.  X and Y components contain a different number of elements.',/center,traceback=0,title='Data Load Problem')
    return,0
  endif
  
  ;ensure metadata variables are not empty
  if undefined(l) then l = 0
  if undefined(dl) then dl = 0
  
  ;merge settings from dl & l into one structure
  extract_tags,dl,l,except_tags='data_att'
  if is_struct(l) && in_set(strlowcase(tag_names(l)),'data_att') then begin
    if is_struct(l) && in_set(strlowcase(tag_names(l)),'data_att') then begin
      data_att_dl = dl.data_att
      extract_tags,data_att_dl,l.data_att
      str_element,dl,'data_att',data_att_dl,/add
    endif else begin
      str_element,dl,'data_att',l.data_att,/add
    endelse
  endif
  self->detectDlimits,name,dl,mission=mission,observatory=observatory,instrument=instrument,coordsys=coordsys,units=units,file=file,st_type=st_type

  if size(isSpect,/type) eq 0 then begin  ;autodetect spectrographic flag
    if ~(size(dl, /type) eq 8) then begin
      isSpect = 0
    endif else begin
      if in_set('spec',strlowcase(tag_names(dl))) then begin
        isSpect = dl.spec
      endif else begin
        isSpect = 0
      endelse
    endelse
  endif
  
  if keyword_set(isyaxis) then begin
    isSpect = 0
  endif
  
  ;create timerange object
  if n_elements(timerange) eq 0 then begin
    tr = OBJ_NEW('spd_ui_time_range',startTime=d.x[0],endTime=d.x[n_elements(d.x)-1])
  endif else begin
    tr = OBJ_NEW('spd_ui_time_range',startTime=timerange[0],endTime=timerange[1])
  endelse 
  
  
  if self->ischild(name) && ~self->isParent(name) then begin ;preexisting replace relevant fields
  
    dataObj = self->getObjects(name=name)

    if ~obj_valid(dataObj) then begin
      ok = error_message('Invalid data object found where valid expected',/traceback,/center,title='Data Load Error')
      return,0
    endif
    
    if ndimen(d.y) gt 1 then begin
      ok = error_message('Cannot replace child of existing object with multi-dimensional quantity',/traceback,/center,title='Data Load Error')
      return,0
    endif
    
    component_names = [name]
    
    dataObj->getProperty,$
      dataPtr=dataPtr,$
      limitPtr=limitPtr,$
      dlimitPtr=dlimitPtr
      
    ptr_free,dataPtr,limitPtr,dlimitPtr
    
    dataPtr = ptr_new(d.y)
    dlimitPtr = ptr_new(dl)
    limitPtr = ptr_new(l)
    
    dataObj->setProperty, $
      dataPtr=dataPtr, $
      dlimitPtr=dlimitPtr, $
      limitPtr=limitPtr,$
      mission=mission,$
      observatory=observatory,$
      coordsys=coordSys,$
      instrument=instrument,$
      filename=file,$
      units=units,$
      st_type=st_type,$
      yaxisunits=yaxisunits,$
      isSpect=isSpect,$
      timeRange=tr,$
      isYaxis=isYaxis

    added_name=name
  endif else begin ;doesn't already exist, create new
  
 ;   prefix = strtrim(string(self.groupID),2) + ':'
    if self->isparent(name) then begin  ;preexisting group, replace each element in group
  
      if ~self->remove(name) then begin
       ok = dialog_message('Error removing value, when replacing variable')
       return,0
      endif
  
    endif
  
  
    prefix = ''
    
    self.groupID++
  
    groupname = prefix+name
    
    group = obj_new('spd_ui_data_group',name=groupname)
  
    timename = groupname+'_time'
    
    timeObj = obj_new('spd_ui_data',timename,self.dataId)
    
    dsettings = obj_new('spd_ui_data_settings',timename,0)
    dsettings->fromLimits,l,dl
    ; if ytitle isn't set in limits, set it manually
    ytitle = dsettings->getytitle()
    if ytitle eq '' then dsettings->setytitle, groupname
    
    self.dataID++
    
    timePtr = ptr_new(d.x)
    limitPtr = ptr_new(l)
    dlimitPtr = ptr_new(dl)
    
    timeObj->setProperty, $
      dataPtr=timePtr, $
      dlimitPtr=dlimitPtr, $
      limitPtr=limitPtr,$
      mission=mission,$
      observatory=observatory,$
      coordsys=coordSys,$
      groupname=groupname,$
      instrument=instrument,$
      filename=file,$
      units='seconds',$
      isSpect=isSpect,$
      timeRange=tr,$
      suffix=suffix+'_time',$
      /isTime,$
      settings=dsettings
    
    group->add,timename,timeObj
    group->setTimeName,timename
    
    if n_elements(d.x) le 1 then begin
      cadence = 0.
    endif else if n_elements(d.x) eq 2 then begin
      cadence = d.x[1]-d.x[0]
    endif else begin
      cadence = median(deriv(d.x))
    endelse
    group->setCadence,cadence
    
    if keyword_set(isYaxis) then begin
      group->setIsYaxis
    endif else begin
      group->setnotYaxis
    endelse
    
    if keyword_set(yaxisparent) then begin
      group->setYAxisParent,yaxisparent
    endif
    
   ;if we need to create a yaxis quantity this code does it
    if in_set('v',strlowcase(tag_names(d))) && is_num(d.v) then begin
  
      if ndimen(d.v) eq 2 then begin 
        dyaxis = {x:d.x,y:d.v}
      endif else if ndimen(d.v) eq 1 || ndimen(d.v) eq 0 then begin
        if ndimen(d.y) eq 1 then begin
          if n_elements(d.v) eq 1 then begin
            dyaxis = {x:d.x,y:rebin([d.v],n_elements(d.x))}
          endif else if n_elements(d.v) eq n_elements(d.x) then begin
            dyaxis = {x:d.x,y:d.v}
          endif else begin
            ok = error_message('Malformed tplot variable, d.v has ambiguous number of elements',/traceback,/center,title='Data Load Error')
            return,0
          endelse
        endif else begin
          dyaxis = {x:d.x,y:transpose(rebin([d.v],n_elements(d.v),n_elements(d.x)))}
        endelse
      endif
   
    endif else if ~keyword_set(isYaxis) then begin ;this code replaces commented code below
    
      dim = dimen(d.y)
  
      if ndimen(d.y) ge 2 then begin
        dyaxis = {x:d.x,y:transpose(dindgen(dim[1],dim[0]) mod dim[1])}
      endif else begin
        dyaxis = {x:d.x,y:dindgen(n_elements(d.y))}
      endelse
    
    endif
   
;    endif else if isSpect then begin
;    
;      dim = dimen(d.y)
;  
;      if ndimen(d.y) ge 2 then begin
;        dyaxis = {x:d.x,y:transpose(dindgen(dim[1],dim[0]) mod dim[1])}
;      endif else begin
;        dyaxis = {x:d.x,y:dindgen(n_elements(d.y))}
;      endelse
;    
;    endif else begin
;      dyaxis = 0
;    endelse
      
    if is_struct(dyaxis) then begin
  
      if ~keyword_set(yAxisName) then yAxisName = name+'_yaxis'
      
    ;  yaxis_prefix = strtrim(string(self.groupid),2)+':'
      yaxis_prefix = ''
      
      if ~self->addData(yaxisname, dyaxis, $
        component_names=yaxis_components,$
        limit=l, dlimit=dl,$
        file=file,$
        mission=mission,$
        observatory=observatory,$
        coordSys=coordSys,$
        instrument=instrument,$
        timerange=timerange,$
        isSpect=0,$
        units=yaxisunits,$
        suffix='_yaxis',$
        yaxisparent=groupname,$
        /isYaxis) then begin
          
          return,0
          
      endif
          
      group->setyaxisname,yaxis_prefix+yaxisname
      
      yaxisadded=1
      
      if ~keyword_set(yaxisunits) then begin
        yaxisgroup=self->getGroup(yaxisname)
        yaxischildren=yaxisgroup->getdataobjects()
        yaxischildren[0]->getproperty,units=yaxisunits
      endif
        
    endif
    
    if keyword_set(indepName) then group->setIndepName, indepName
    
    self->splitVecPtr,name,d,outnames=component_names,outptrs=outptrs,suffixes=suffixes
 
    component_names = prefix+component_names
    
    ;first check if they already exist
    for i = 0,n_elements(component_names)-1 do begin
      if self->isParent(component_names[i]) || $
        self->isChild(component_names[i]) then begin
        ok = error_message('Adding this quantity creates a conflict with the name of an already existing quantity.',/traceback,/center) 
         
        if keyword_set(yaxisname) then begin
          tmp = self->remove(yaxisname)
        endif
        return,0
      endif
    endfor
 
    for i = 0,n_elements(component_names)-1 do begin
    
      dataObj = obj_new('spd_ui_data',component_names[i],self.dataId)    
      dsettings = obj_new('spd_ui_data_settings',isSpect?name:component_names[i],i)
      dsettings->fromLimits,l,dl
          ; if ytitle isn't set in limits, set it manually
    ytitle = dsettings->getytitle()
    if ytitle eq '' then dsettings->setytitle, groupname
      
      self.dataID++
      
      dataPtr = outptrs[i]
      limitPtr = ptr_new(l)
      dlimitPtr = ptr_new(dl)
      
      dataObj->setProperty, $
        dataPtr=dataPtr, $
        dlimitPtr=dlimitPtr, $
        limitPtr=limitPtr,$
        yaxisName = keyword_set(yaxis_components)?yaxis_components[i]:'',$
        fileName=file,$
        mission=mission,$
        observatory=observatory,$
        coordSys=coordSys,$
        instrument=instrument,$
        groupname=groupname,$
        timeRange=tr,$
        isSpect=isSpect,$
        timename=timename,$
        units=units,$
        st_type=st_type,$
        yaxisunits=yaxisunits,$
        isYaxis=isYaxis,$
        suffix=suffix+suffixes[i],$
        settings=dsettings
      
      group->add,component_names[i],dataObj
    
    endfor
    
    if ~ptr_valid(self.groupObjs) || $
       ~ptr_valid(self.groupNames) || $
       ~ptr_valid(self.insNames) || $
       ~ptr_valid(self.obsNames) || $
       ~ptr_valid(self.misNames) then begin
      
      self.groupObjs = ptr_new([group])
      self.groupNames = ptr_new([groupname])
      self.insNames = ptr_new([instrument])
      self.obsNames = ptr_new([observatory])
      self.misNames = ptr_new([mission])
   
    endif else begin
      gObjList = *self.groupObjs
      gNameList = *self.groupNames
      gInsList = *self.insNames
      gObsList = *self.obsNames
      gMisList = *self.misNames
      
      ptr_free,self.groupObjs,self.groupNames,self.insNames,self.obsNames,self.misNames
      
      olist = [gObjList,group]
      nlist = [gNameList,groupname]
      ilist = [gInsList,instrument]
      oblist = [gObsList,observatory]
      mlist = [gMisList,mission]
      
      if keyword_set(yaxisadded) then begin ;switch the order if yaxis was added, so names print in order
      
        olist[n_elements(olist)-1] = olist[n_elements(olist)-2]
        olist[n_elements(olist)-2] = group
        
        nlist[n_elements(nlist)-1] = nlist[n_elements(nlist)-2]
        nlist[n_elements(nlist)-2] = groupname
        
        ilist[n_elements(ilist)-1] = ilist[n_elements(ilist)-2]
        ilist[n_elements(ilist)-2] = instrument
        
        oblist[n_elements(oblist)-1] = oblist[n_elements(oblist)-2]
        oblist[n_elements(oblist)-2] = observatory
        
        mlist[n_elements(mlist)-1] = mlist[n_elements(mlist)-2]
        mlist[n_elements(mlist)-2] = mission
        
      endif
      
      self.groupObjs = ptr_new(olist)
      self.groupNames = ptr_new(nlist)
      self.insNames = ptr_new(ilist)
      self.obsNames = ptr_new(oblist)
      self.misNames = ptr_new(mlist)
    endelse
    
    added_name = groupname
  
  endelse
    
  return,1
END ;--------------------------------------------------------------------------------

pro spd_ui_loaded_data::detectDlimits,name,dl,mission=mission,observatory=observatory,instrument=instrument,file=file,coordsys=coordsys,units=units,st_type=st_type

  compile_opt idl2, hidden

  ;**************************
  ; Set mission/project name
  if ~keyword_set(mission) then mission = self->detectMission(name, dl)
  
  ;**************************
  ; Set st_type
  if ~keyword_set(st_type) then st_type = self->detectSttype(name, dl)
  
  ;**************************
  ; Set observatory
  if ~keyword_set(observatory) then observatory = self->detectObservatory(name, dl, mission)

  ;**************************
  ; Set instrument
  if ~keyword_set(instrument) then instrument = self->detectInstrument(name, dl,mission)

  ;**************************
  ; Set filename
  if ~keyword_set(file) then file = self->detectFilename(name, dl)

  ;**************************
  ; Set coordinate system
  if ~keyword_set(coordsys) then coordsys = self->detectCoordsys(name,dl)
  
  ;**************************
  ; Set units
  if ~keyword_set(units) then units = self->detectunits(name, dl)
  
end

function SPD_UI_LOADED_DATA::detectSttype, name, dl
    compile_opt idl2, hidden
    
    st_type = 'none'
    ; check that the dlimits struct exists
    if ~is_struct(dl) then begin
        dprint, 'Unable to determine st_type for ' + name, dlevel = 4
        st_type = 'none'
        return, st_type
    endif
    
    ; assume we failed
    success = 0
    
    ; check for st_type in the data_att struct
    if in_set('data_att', strlowcase(tag_names(dl))) && is_struct(dl.data_att) then begin
        if in_set('st_type', strlowcase(tag_names(dl.data_att))) then begin
            st_type = dl.data_att.st_type
            success = 1
        endif else success = 0
    endif else success = 0
    
    return, st_type
end

function SPD_UI_LOADED_DATA::detectMission, name, dl

  compile_opt idl2, hidden
  
  ; check if dlimits exists
  if ~(size(dl, /type) eq 8) then begin
    dprint, 'Unable to determine mission/project for ' + name, dlevel=4
    mission='unknown'
    return, strupcase(mission)
  endif

  success=0
  
  ; check DATA_ATT
  if in_set('data_att', strlowcase(tag_names(dl))) && is_struct(dl.data_att) then begin
  
    if in_set('project', strlowcase(tag_names(dl.data_att))) then begin
      
      mission = dl.data_att.project
      success = 1
    endif else success = 0
  endif else success = 0
  
  if ~success then begin
  
    ; check CDF.GATT.PROJECT
    if in_set('cdf', strlowcase(tag_names(dl))) && is_struct(dl.cdf) then begin
    
      if in_set('gatt', strlowcase(tag_names(dl.cdf))) && is_struct(dl.cdf.gatt) then begin

        if in_set('project', strlowcase(tag_names(dl.cdf.gatt))) then begin
          
          mission = dl.cdf.gatt.project
          success = 1
        endif
      endif
    endif
  endif
  
  if ~success then begin
  
    ; guess project based on tplot var name
    name_pre = strmid(name,0,2)

    case name_pre of
      'th': mission='THEMIS'
      else: begin
        dprint, 'Unable to determine mission/project for ' + name, dlevel=4
        mission='unknown'
      endelse
    endcase
  endif
  
  return, strupcase(mission)

end ;--------------------------------------------------------------------------------


function SPD_UI_LOADED_DATA::detectObservatory, name, dl, mission

  compile_opt idl2, hidden

  ; check if dlimits exists
  if ~(size(dl, /type) eq 8) then begin
    dprint, 'Unable to determine observatory for ' + name, dlevel=4
    observatory = 'unknown'
    return, observatory
  endif

  success = 0
  
  ; check DATA_ATT
  if in_set('data_att', strlowcase(tag_names(dl))) && is_struct(dl.data_att) then begin
  
    if in_set('observatory', strlowcase(tag_names(dl.data_att))) && $
         is_string(dl.data_att.observatory) then begin
      
      observatory = dl.data_att.observatory
      success = 1
    endif
  endif
  
  if ~success then begin
  
    ; check CDF.GATT.SOURCE_NAME
    if in_set('cdf', strlowcase(tag_names(dl))) && is_struct(dl.cdf) then begin
    
      if in_set('gatt', strlowcase(tag_names(dl.cdf))) && is_struct(dl.cdf.gatt) then begin
      
        if in_set('source_name', strlowcase(tag_names(dl.cdf.gatt))) && $
             is_string(dl.cdf.gatt.source_name) then begin

          case mission of
            'THEMIS': begin
            
              if strmid(dl.cdf.gatt.source_name,3,13) eq '>THEMIS Probe' then begin
              
                observatory=strlowcase(strmid(dl.cdf.gatt.source_name,2,1))
                success = 1
              endif else begin
              
                ; use varname as last resort
                if stregex(name,'^th[abcdefg].*',/boolean, /fold_case) then begin
                  observatory = strmid(name,2,1)
                  success = 1
                endif else dprint, 'Unknown observatory.  Checking variable name for clues...', dlevel=4
              endelse
            end
            'GOES': begin
              if strmid(dl.cdf.gatt.source_name,3,50) eq '>Geostationary Operational Environmental Satellite' then begin     
                observatory=strlowcase(strmid(dl.cdf.gatt.source_name,0,3))
                success = 1
              endif else begin
              
                ; use varname as last resort
                if stregex(name,'^g\d\d.*',/boolean, /fold_case) then begin
                  observatory = strmid(name,0,3)
                  success = 1
                endif else dprint, 'Unknown observatory.  Checking variable name for clues...'
              endelse
            end 
            else: begin
              observatory = dl.cdf.gatt.source_name
              success=1
            end
          endcase          
        endif
      endif
    endif
  endif
  
  if ~success then begin
    dprint, 'Unknown observatory.  Checking variable name for clues...'
    ; use varname as last resort
    case mission of
      'THEMIS': begin
        if stregex(name,'^th[abcdefg].*',/boolean, /fold_case) then begin
          observatory = strmid(name,2,1)
        endif else begin
          dprint, 'Unable to determine observatory for ' + name, dlevel=4
          observatory = 'unknown'
        endelse
      end
      else: begin
        dprint, 'Unable to determine observatory for ' + name, dlevel=4
        observatory = 'unknown'
      end
    endcase
  endif
  
  return, observatory

end ;--------------------------------------------------------------------------------


function SPD_UI_LOADED_DATA::detectInstrument, name, dl,mission

  compile_opt idl2, hidden

  instrument = 'unknown'

  ; check if dlimits exists
  if ~(size(dl, /type) eq 8) then begin
    dprint, 'Unable to determine instrument type for ' + name, dlevel=4
    return, instrument
  endif

  success=0
  
  ; check DATA_ATT
  if in_set('data_att', strlowcase(tag_names(dl))) && is_struct(dl.data_att) then begin
    
    if in_set('instrument', strlowcase(tag_names(dl.data_att))) then begin
      instrument = dl.data_att.instrument
      success = 1
    endif
  endif
  
  if ~success then begin
  
    if in_set('cdf', strlowcase(tag_names(dl))) && is_struct(dl.cdf) then begin
    
      if in_set('gatt', strlowcase(tag_names(dl.cdf))) && is_struct(dl.cdf.gatt) then begin
      
      
      ; 'data_type' field is not ISTP compatable. This option is left for THEMIS 
      ; and GOES missions only for backward capability
      ; Instead, we use Descriptor as a correct instument attribute       
        if in_set('data_type', strlowcase(tag_names(dl.cdf.gatt))) and in_set(strlowcase(mission),['themis','goes']) then begin
        
          inst_string = strupcase(strmid(dl.cdf.gatt.data_type,0,3))
          
          case inst_string of
            
            'AST': begin
              instrument = 'asi'
              success = 1
            end
            'ASF': begin
              instrument = 'asi'
              success = 1
            end
            'ASK': begin
              instrument = 'ask'
              success = 1
            end
            'ESA': begin
              instrument = 'esa'
              success = 1
            end
            'FBK': begin
              instrument = 'fbk'
              success = 1
            end
            'FGM': begin
              instrument = 'fgm'
              success = 1
            end
            'FIT': begin
              instrument = 'fit'
              success = 1
            end
            'MAG': begin
              if mission eq 'THEMIS' then begin
                instrument = 'gmag'
                success = 1
              endif else if mission eq 'GOES' then begin
                instrument = 'fgm' 
                success = 1
              endif
            end
            'MOM': begin
              instrument = 'mom'
              success = 1
            end
            'SST': begin
              instrument = 'sst'
              success = 1
            end
            'STA': begin
              instrument = 'state'
              success = 1
            end
            'IDX': begin
              instrument = 'idx'
              success = 1
            end
            else: begin ;some THEMIS data, has data_type, descriptor switched
              ; If mission is themis or goes, the instrument will be obtained
              ; later in the function. This is the case for all other missions
              if ~in_set(strlowcase(mission),['themis','goes']) and in_set('descriptor', strlowcase(tag_names(dl.cdf.gatt))) then begin
                instrument = dl.cdf.gatt.descriptor
                success=1
              endif
            end
            ;;;;; 4/9/2015, egrimes, commented out calls to thm_ui_valid_datatype 
              ;;;;;           because it lives in projects/themis. The regex that follows
              ;;;;;           should pick up these variables, and more.
;              ; check for matches with efi data names
;              efi_names = thm_ui_valid_datatype('efi')
;              efi_ind = where(strlowcase(inst_string) eq efi_names, n_efi)
;              if n_efi gt 0 then begin
;                instrument='efi'
;                success = 1
;              endif
;  
;              ; check for matches with fft data names
;              fft_names = thm_ui_valid_datatype('fft')
;              fft_ind = where(strlowcase(inst_string) eq fft_names, n_fft)
;              if n_fft gt 0 then begin
;                instrument='fft'
;                success = 1
;              endif
;  
;              ; check for matches with scm data names
;              scm_names = thm_ui_valid_datatype('scm')
;              scm_ind = where(strlowcase(inst_string) eq scm_names, n_scm)
;              if n_scm gt 0 then begin
;                instrument='scm'
;                success = 1
;              endif
          endcase  
          
            endif else begin ; 'data_type'
              ; If mission is themis or goes, the instrument will be obtained 
              ; later in the function. This is the case for all other missions
              if ~in_set(strlowcase(mission),['themis','goes']) and in_set('descriptor', strlowcase(tag_names(dl.cdf.gatt))) then begin                
                  instrument = dl.cdf.gatt.descriptor
                  success=1
              endif 
            endelse

      endif ; 'gatt'
    endif ; 'cdf'
  endif ; ~success 
  
  if ~success then begin
    if mission eq 'THEMIS' then begin
      if stregex(name,'^thg_ask_.*',/boolean,/fold_case) then begin
        instrument = 'ask'
      end else if stregex(name,'^th[abcde]_pe[ie][frb]_.*',/boolean,/fold_case) then begin
        instrument = 'esa'
      end else if stregex(name,'^th[abcde]_efs.*',/boolean,/fold_case) || $
                  stregex(name,'^th[abcde]_fgs.*',/boolean,/fold_case) || $
                  stregex(name,'^th[abcde]_fit.*',/boolean,/fold_case) then begin
        instrument = 'fit'
      end else if stregex(name,'^th[abcde]_ef[fpw].*',/boolean,/fold_case) || $
                  stregex(name,'^th[abcde]_v[ab][fpw].*',/boolean,/fold_case) then begin 
        instrument = 'efi'
      end else if stregex(name,'^th[abcde]_fb[12h_].*',/boolean,/fold_case) then begin
        instrument = 'fbk'
        success = 1

      ;
      ; 2011-01-01 JWL  FFF is a valid data type for instrument='fft'.
      ; Without this patch, an 'unknown instrument' error message
      ; would appear when importing thx_fff_* tplot variables.
      ;
      endif else if stregex(name,'^th[abcde]_ff[fpw]_16.*',/boolean,/fold_case) || $
                    stregex(name,'^th[abcde]_ff[fpw]_32.*',/boolean,/fold_case) || $
                    stregex(name,'^th[abcde]_ff[fpw]_64.*',/boolean,/fold_case) then begin
        instrument = 'fft'
      endif else if stregex(name,'^th[abcde]_fg[elh].*',/boolean,/fold_case) then begin
        instrument = 'fgm'
      endif else if stregex(name,'^thg_mag_.*',/boolean,/fold_case) then begin 
        instrument = 'gmag'
      endif else if stregex(name,'^th[abcde]_pe[ie]m_.*',/boolean,/fold_case) || $
                    stregex(name,'^th[abcde]_pxxm_.*',/boolean,/fold_case) then begin
        instrument = 'mom'
      endif else if stregex(name,'^th[abcde]_sc[fpw].*',/boolean,/fold_case) then begin
        instrument = 'scm'
      endif else if stregex(name,'^th[abcde]_ps[ei][frb]_.*',/boolean,/fold_case) then begin
        instrument = 'sst'
      endif else if stregex(name,'^th[abcde]_state_.*',/boolean,/fold_case) then begin
        instrument='state'
      endif else begin
        dprint, 'Unable to determine instrument type for ' + name, dlevel=4
      endelse
    endif else if mission eq 'GOES' then begin
      if stregex(name,'^g1[012]_dataqual.*',/boolean,/fold_case) || $
        stregex(name,'^g1[012]_t[12]_counts.*',/boolean,/fold_case) then begin
        instrument = 'support'
      endif else if stregex(name,'^g1[012]_longitude.*',/boolean,/fold_case) || $
                   stregex(name,'^g1[012]_mlt.*',/boolean,/fold_case) || $
                   stregex(name,'^g1[012]_pos.*',/boolean,/fold_case) || $
                   stregex(name,'^g1[012]_vel.*',/boolean,/fold_case) then begin
        instrument = 'ephem'
      endif else if stregex(name,'^g1[012]_b_.*',/boolean,/fold_case) then begin
        instrument = 'fgm'
      endif else begin
        dprint, 'Unable to determine instrument type for ' + name, dlevel=4
      endelse
    endif
  endif
  
  return, instrument

end ;--------------------------------------------------------------------------------


function SPD_UI_LOADED_DATA::detectFilename, name, dl

  compile_opt idl2, hidden

  ; check if dlimits exists
  if ~(size(dl, /type) eq 8) then begin
    dprint, 'Unable to determine source file for ' + name, dlevel=4
    file = 'unknown'
    return, file
  endif

  success = 0
  
  ; check DATA_ATT
  if in_set('data_att', strlowcase(tag_names(dl))) && is_struct(dl.data_att) then begin
  
    if in_set('filename', strlowcase(tag_names(dl.data_att))) then begin
      file = dl.data_att.filename
      success = 1
    endif
  endif
  
  if ~success then begin
  
    ; check CDF.FILENAME
    if in_set('cdf', strlowcase(tag_names(dl))) && is_struct(dl.cdf) then begin

      if in_set('filename', strlowcase(tag_names(dl.cdf))) then begin

        file = dl.cdf.filename
        success = 1
      endif
    endif
  endif
  
  if ~success then begin

    file = 'unknown'
    dprint, 'Unable to determine source file for ' + name, dlevel=4
  endif
  
  return, file

end ;--------------------------------------------------------------------------------


function SPD_UI_LOADED_DATA::detectCoordsys, name, dl

  compile_opt idl2, hidden

  ; check if dlimits exists
  if ~(size(dl, /type) eq 8) then begin
    dprint, 'Unable to determine coordinate system for ' + name, dlevel=4
    coordsys = 'unknown'
    return, coordsys
  endif

  success = 0
  
  ; check DATA_ATT
  if in_set('data_att', strlowcase(tag_names(dl))) && is_struct(dl.data_att) then begin
  
    if in_set('coord_sys', strlowcase(tag_names(dl.data_att))) then begin
      coordsys = dl.data_att.coord_sys
      success = 1
    endif
  endif
  
  if ~success then begin
  
    ; check CDF.VATT.COORDINATE_SYSTEM
    if in_set('cdf', strlowcase(tag_names(dl))) && is_struct(dl.cdf) then begin

      if in_set('vatt', strlowcase(tag_names(dl.cdf))) && is_struct(dl.cdf.vatt) then begin
      
        if in_set('coordinate_system', strlowcase(tag_names(dl.cdf.vatt))) then begin
          coordsys = dl.cdf.vatt.coordinate_system
          success = 1
        endif     
      endif
    endif
  endif
  
  if ~success then begin

    ; guess coordinate system from variable name later
    ;vcoord = ['spg', 'ssl', 'dsl', 'gse', 'gsm','sm', 'gei','geo']
    coordsys = 'unknown'
    dprint, 'Unable to determine coordinate system for ' + name, dlevel=4
  endif
  
  return, coordsys

end ;--------------------------------------------------------------------------------


function SPD_UI_LOADED_DATA::detectunits, name, dl

  compile_opt idl2, hidden

  ; check if dlimits exists
  if ~(size(dl, /type) eq 8) then begin
 ;   dprint, 'Unable to determine units for ' + name
    units = 'unknown'
    return, units
  endif

  success = 0
  
  ; check DATA_ATT
  if in_set('data_att', strlowcase(tag_names(dl))) && is_struct(dl.data_att) then begin
    
    if in_set('units', strlowcase(tag_names(dl.data_att))) && dl.data_att.units ne 'unknown' then begin
      units = strcompress(dl.data_att.units,/remove_all)
      success = 1
    endif
  endif
  
  if ~success && in_set('ysubtitle',strlowcase(tag_names(dl))) then begin
    units = strcompress(dl.ysubtitle,/remove_all)
    if strpos(units,'[') eq 0 then begin
      units = strmid(units,1)
    endif
    
    if strpos(units,']') eq strlen(units) - 1 then begin
      units = strmid(units,0,strlen(units)-1)
    endif 
    success = 1
  endif
  
  if ~success then begin
  
    ; check CDF.VATT.UNITS
    if in_set('cdf', strlowcase(tag_names(dl))) && is_struct(dl.cdf) then begin
    
      if in_set('vatt', strlowcase(tag_names(dl.cdf))) && is_struct(dl.cdf.vatt) then begin
 
        if in_set('units', strlowcase(tag_names(dl.cdf.vatt))) then begin
        
          units = strcompress(dl.cdf.vatt.units,/remove_all)
          success = 1
        endif
      endif
    endif
  endif
  
  if ~success then begin
    units = 'unknown'
    dprint, 'Unable to determine units for ' + name, dlevel=4
  endif
  
  return, units
  
end ;--------------------------------------------------------------------------------



FUNCTION SPD_UI_LOADED_DATA::Remove, name,nodelete=nodelete

   compile_opt idl2
 
  if ~keyword_set(name) then return,0
  
  if ~ptr_valid(self.groupNames) || $
     ~ptr_valid(self.groupObjs)  || $
     ~ptr_valid(self.insNames) || $
     ~ptr_valid(self.obsNames) || $
     ~ptr_valid(self.misNames) then return,1
     
  yaxisname = ''
     
  names  = *self.groupNames
  groups = *self.groupObjs
  instruments = *self.insNames
  observatories = *self.obsNames
  missions = *self.misNames
  
  idx = where(name eq names,c)
  
  if c ne 0 then begin ;name matches group
  
    ptr_free,self.groupNames,self.groupObjs,self.insNames,self.obsNames,self.misNames
   
    obj = groups[idx]
    
    ;remove yaxis if present
    yaxisname = obj->getYaxisName()
    
    tmp = obj->removeAll(nodelete=nodelete)
   
    if ~keyword_set(nodelete) then obj_destroy,obj
    
    idx = where(name ne names,c)
    
    if c ne 0 then begin
      self.groupNames = ptr_new(names[idx])
      self.groupObjs = ptr_new(groups[idx])
      self.insNames = ptr_new(instruments[idx])
      self.obsNames = ptr_new(observatories[idx])
      self.misNames = ptr_new(missions[idx])
    endif
    
  endif else begin
  
    for i = 0,n_elements(groups)-1 do begin
   
      tmp = groups[i]->remove(name,nodelete=nodelete)    
    
    endfor
  
  endelse
   
  if yaxisname then begin
    if ~self->remove(yaxisname) then return,0
  endif
   
  return,1
   
END ;--------------------------------------------------------------------------------

;Get all the names
;Times returns the start and stop times as well.
;If times is set the return value will be a Nx3 array
FUNCTION SPD_UI_LOADED_DATA::GetAll, Parent=parent,Child=Child,Times=times

  compile_opt idl2

  if ~ptr_valid(self.groupObjs) then return,0
     
  groups = *self.groupObjs
      
  for i=0,n_elements(groups)-1 do begin
  
    if keyword_set(parent) || $
      ~keyword_set(child) then begin
       if keyword_set(times) then begin
         time = groups[i]->getTimeRange()
         if n_elements(time) ne 2 then time = ['','']
         name = reform([groups[i]->getName(),time],1,3)
       endif else begin
         name = [groups[i]->getName()]
       endelse
       
       if n_elements(names) eq 0 then $
         names = [name] $
       else $
         names = [names,name]
    endif
    
   
     
    if keyword_set(child) || $
      ~keyword_set(parent) then begin
      name = groups[i]->getChildren()
      if keyword_set(times) then begin   
        time = groups[i]->getTimeRange()
        n = n_elements(name)
        if n_elements(time) ne 2 then time = ['','']       
        name = [[name],[replicate(time[0],n)],[replicate(time[1],n)]]
      endif
      if n_elements(names) eq 0 then $
         names = [name] $
       else $
         names = [names,name]
    endif
     
  endfor
  
  if keyword_set(times) then names = transpose(names)
  
  RETURN, names  
                  
END ;--------------------------------------------------------------------------------

FUNCTION SPD_UI_LOADED_DATA::GetActive, Parent=parent,Child=child

   compile_opt idl2

   if ~ptr_valid(self.groupObjs) || $
      ~ptr_valid(self.groupNames) then return,0
   
   groups = *self.groupObjs
   names = *self.groupnames
   
   for i = 0,n_elements(groups)-1 do begin
   
     if (keyword_set(parent) || ~keyword_set(child)) && $
       groups[i]->getActive() then begin
       
       if n_elements(list) eq 0 then begin
         list = [names[i]]
       endif else begin
         list = [list,names[i]]
       endelse
     endif
     
     if (keyword_set(child) || ~keyword_set(parent)) then begin
       activeChildren = groups[i]->getActiveChildren()
       
       if is_string(activeChildren) then begin
         
         if n_elements(list) eq 0 then begin
           list = [activeChildren]
         endif else begin
           list = [list,activeChildren]
         endelse
         
       endif
     endif
          
   endfor
   
   if n_elements(list) eq 0 then $
     return,0  $
   else $
     return,list
                  
END ;--------------------------------------------------------------------------------

function SPD_UI_LOADED_DATA::getChildren,name

  compile_opt idl2
  
  if ptr_valid(self.groupNames) && $
     ptr_valid(self.groupObjs) then begin
     
     names = *self.groupNames
     objs  = *self.groupObjs
     
     idx = where(name eq names,c)
     
     if c eq 0 then begin
       for i = 0,n_elements(objs)-1 do begin
       
         if objs[i]->hasChild(name) then return,name
       
       endfor
     endif else begin
       return,objs[idx[0]]->getChildren()
     endelse
     
  endif
  
  return,0
  
end  ;--------------------------------------------------------------------------------

PRO SPD_UI_LOADED_DATA::SetActive, name

  compile_opt idl2

  if ~keyword_set(name) then return
  
  if ~ptr_valid(self.groupObjs)  then return

  groups = *self.groupObjs

  for i = 0,n_elements(groups)-1 do begin
  
    groups[i]->setActive,name 
  
  endfor
  
  return
                     
END ;--------------------------------------------------------------------------------

FUNCTION SPD_UI_LOADED_DATA::IsActive,name

  compile_opt idl2

  if ~keyword_set(name) then return,0
  
  if ~ptr_valid(self.groupNames) || $
     ~ptr_valid(self.groupObjs)   then return,0

  groups = *self.groupNames

  for i = 0,n_elements(groups)-1 do begin
  
    if groups[i]->getActive() || $
       groups[i]->hasActive(name) then return,1
  
  endfor
  
  return,0

END ;--------------------------------------------------------------------------------

FUNCTION SPD_UI_LOADED_DATA::IsChild,name

  compile_opt idl2
  
  if ~keyword_set(name) then return,0
  
  if ~ptr_valid(self.groupObjs) then return,0
  
  groups = *self.groupObjs
  
  for i = 0,n_elements(groups)-1 do begin
  
    if groups[i]->hasChild(name) then return,1
  
  endfor
 
  return,0

END ;--------------------------------------------------------------------------------


FUNCTION SPD_UI_LOADED_DATA::IsParent,name

  compile_opt idl2
  
  if ~keyword_set(name) then return,0

  if ~ptr_valid(self.groupNames) then return,0
  
  names = *self.groupNames
  
  return,in_set(name,names)

end
   
PRO SPD_UI_LOADED_DATA::ClearActive, thisName

   compile_opt idl2

   if ~ptr_valid(self.groupObjs) then return
   
   groupObjs = *self.groupObjs
   
   for i=0,n_elements(groupObjs)-1 do begin
   
     groupObjs[i]->clearActive,thisName
   
   endfor
                     
END ;--------------------------------------------------------------------------------

PRO SPD_UI_LOADED_DATA::ClearAllActive

   compile_opt idl2

   if ~ptr_valid(self.groupObjs) then return
   
   groupObjs = *self.groupObjs
   
   for i=0,n_elements(groupObjs)-1 do begin
   
     groupObjs[i]->clearAllActive
   
   endfor
                     
END ;--------------------------------------------------------------------------------

;option duplicate
;allows the user to guarantee they get copies of the data
;less memory efficient, but allows you to free the memory without worry of corrupting loaded data object
Pro SPD_UI_LOADED_DATA::GetVarData,name=name,time=t,data=d,yaxis=y,limits=l,dlimits=dl,mission=mission,observatory=observatory,coordsys=coordsys,instrument=instrument,trange=trange,units=units,isTime=isTime,tmName=timeName,duplicate=duplicate

  compile_opt idl2

  d = ptr_new()
  y = ptr_new()
  t = ptr_new()
  l = ptr_new()
  dl = ptr_new()

  if ~keyword_set(name) then begin
    return
  endif
  
  if ~ptr_valid(self.groupObjs) || $
     ~ptr_valid(self.groupNames) then return
  
  ;if the name is a group
  if self->isParent(name) then begin
    groupObj = self->getGroup(name)
    dataObjs = groupObj->getDataObjects()
    timeObj = groupObj->getTimeObject()
    yaxisName = groupObj->getYaxisName()
    timeName = groupObj->getTimeName()
    
    ;get the yaxis for the group
    if yaxisName ne '' then self->getVarData,name=yaxisName,data=y
    
    if ~obj_valid(dataObjs[0]) || ~obj_valid(timeObj) then return
        
    if keyword_set(duplicate) && arg_present(t) then begin
      t = ptr_new(*(timeObj->getDataPtr()))
    endif else begin
      t = timeObj->getDataPtr()
    endelse
    
    dataObjs[0]->updateDlimits
    
    dataObjs[0]->getProperty,limitPtr=l,dlimitPtr=dl,mission=mission,observatory=observatory,coordsys=coordsys,instrument=intrument,timerange=timerange,units=units,isTime=isTime
    
    d1_num = n_elements(*t)
    d2_num = n_elements(dataObjs)
    
    out_data = dblarr(d1_num,d2_num)
    
    for i = 0,d2_num-1 do begin
      out_data[*,i] = *(dataObjs[i]->getDataPtr())
    endfor
  
    if arg_present(d) then begin
      d = ptr_new(out_data)
    endif
    
    if arg_present(l) && keyword_set(duplicate) then begin
      l = ptr_new(*l)
    endif
    
    if arg_present(dl) && keyword_set(duplicate) then begin
      dl = ptr_new(*dl)
    endif
    
    if arg_present(trange) && obj_valid(timerange) then begin
      trange = [timerange->getstarttime(),timerange->getendtime()]
    endif

  endif else if self->isChild(name) then begin
  
    groups = *self.groupObjs
  
    for i = 0,n_elements(groups)-1 do begin
   
      dataObj = groups[i]->getObject(name)
    
      if obj_valid(dataObj) then begin
      
        dataObj[0]->updateDlimits
        dataObj[0]->getProperty,name=name,mission=mission,observatory=observatory,coordSys=coordSys,instrument=instrument,timerange=timerange,isTime=isTime,dataPtr=dataPtr,timeName=timeName,yaxisname=yaxisname,limitPtr=l,dlimitPtr=dl,units=units
      
        if arg_present(d) && keyword_set(duplicate) then begin
          d = ptr_new(*dataPtr)
        endif else begin
          d = dataPtr
        endelse
        
        if arg_present(l) && keyword_set(duplicate) then begin
          l = ptr_new(*l)
        endif
    
        if arg_present(dl) && keyword_set(duplicate) then begin
          dl = ptr_new(*dl)
        endif
      
        if isTime then begin
          if arg_present(t) && keyword_set(duplicate) then begin
            t = ptr_new(*dataPtr)
          endif else begin
            t = dataPtr
          endelse
        endif else begin
      
          timeObj = groups[i]->getObject(timeName)
        
          if ~obj_valid(timeObj) then begin
            ok = error_message("Invalid time object",/traceback)
            return
          endif
          
          if arg_present(t) && keyword_set(duplicate) then begin
            t = ptr_new(*(timeObj->getDataPtr()))
          endif else begin
            t = timeObj->getDataPtr()
          endelse
          
        endelse
        
        if arg_present(trange) && obj_valid(timerange) then begin
          trange = [timerange->getstarttime(),timerange->getendtime()]
        endif
      
        return
      
      endif
    
    endfor
  endif
 
end
  

function SPD_UI_LOADED_DATA::GetTvarData,name

  compile_opt idl2

  self->getvardata,name=name,data=d,time=t,yaxis=y,limit=l,dlimit=dl

  if ptr_valid(d) && ptr_valid(t) && ptr_valid(y) then begin
     dat = {x:*t,y:*d,v:*y}
  endif else if ptr_valid(d) && ptr_valid(t) then begin
     dat = {x:*t,y:*d}
  endif else begin
     return,''
  endelse
  
  if ptr_valid(l) then l = *l else l = 0
  if ptr_valid(dl) then dl = *dl else dl = 0
  
  store_data,name,data=dat,limit=l,dlimit=dl,error=error
  
  if error eq 1 then begin
    return,''
  endif else begin
    return,name
  endelse
  
end


;Call this method to read the metadata associated with a quantity, without the need for costly data operations
;Note that this operation can fail, if the quantity in question does not exist.
;Set fail to a named variable, which will be 0 on success and 1 on failure, after this method returns
pro spd_ui_loaded_data::getdatainfo,name,mission=mission,observatory=observatory,instrument=instrument,units=units,coordinate_system=coordinate_system,trange=trange,filename=filename,limit=limit,dlimit=dlimit,fail=fail,st_type=st_type

  compile_opt idl2

  fail = 1

  if self->isParent(name) then begin
    group = self->getGroup(name)
    children = group->getDataObjects()
    reference=children[0]  ;note.  In the future these metadata quantities should probably just be stored on the group....
    
  endif else if self->isChild(name) then begin
    
    groups = *self.groupObjs
    
    for i = 0,n_elements(groups)-1 do begin
      group = groups[i]
      reference = group->getObject(name)
      if obj_valid(reference) then break
    endfor
    
  endif
  
  if ~obj_valid(reference) || ~obj_valid(group) then return
      
  reference->getProperty,mission=mission,observatory=observatory,instrument=instrument,units=units,coordSys=coordinate_system,timerange=timerange,filename=filename,limitptr=limitptr,dlimitptr=dlimitptr,st_type=st_type

  if arg_present(trange) && obj_valid(timerange) then begin
    trange = [timerange->getstarttime(),timerange->getendtime()]
  endif

  limit = *limitptr
  dlimit =  *dlimitptr

  fail = 0

end

;Call set method to read the metadata associated with a quantity, without the need for costly data operations
;Note that rename operations can fail because names may conflict.
;Set fail to a named variable, which will be 0 on success and 1 on failure, after this method returns
;Also, note that these operations can only be performed on groups. If an element is selected, the change will propagate out to the entire group.
;For example 'tha_state_pos_x', and 'tha_state_pos_y' cannot be in different coordinate systems, if you change 'tha_state_pos_x' to 'gsm', 'tha_state_pos_y'
;will also become 'gsm' 
pro spd_ui_loaded_data::setDataInfo,name,newname=newname,mission=mission,observatory=observatory,instrument=instrument,units=units,coordinate_system=coordinate_system,windowstorage=windowstorage,fail=fail,st_type=st_type

  compile_opt idl2
  
  fail = 1

  if self->isParent(name) then begin
    group = self->getGroup(name)
    children = group->getDataObjects()
    reference=children[0]  ;note.  In the future these metadata quantities should probably just be stored on the group....
    
  endif else if self->isChild(name) then begin
    
    groups = *self.groupObjs
    
    for i = 0,n_elements(groups)-1 do begin
      group = groups[i]
      reference = group->getObject(name)
      if obj_valid(reference) then break
    endfor
    
  endif
  
  if ~obj_valid(reference) || ~obj_valid(group) then return
  
  yaxisname = group->getyaxisname()
  
  if keyword_set(yaxisname) then begin
    self->setdatainfo,yaxisname,mission=mission,observatory=observatory,instrument=instrument,units=units,coordinate_system=coordinate_system,fail=yaxisfail,st_type=st_type
    if yaxisfail then return
  endif
  
  idx = where(group[0] eq *self.groupobjs)
  
  if keyword_set(newname) && name ne newname then begin
  
    ;names cannot already exist. Unique names enforced
    if self->isParent(newname) && ~group->getIsYAxis() then return
  
    nm_idx = where(name eq *self.groupNames,c)
    
    ;names should be unique
    if c gt 1 then return
    
    ;now change groupname
    (*self.groupNames)[nm_idx] = newname
    group->setName,newname
    
    oldnamelist = [name]
    newnamelist = [newname]
    
    ;then change any children 
    children = group->getAllObjects()
    
    for i = 0,n_elements(children)-1 do begin
      children[i]->getProperty,suffix=suffix,name=oldname
      children[i]->setProperty,name = newname+suffix
      children[i]->updatelabels,oldname,newname
      if ~keyword_set(childnames) then begin
        childnames = [newname+suffix]
      endif else begin
        childnames = [childnames,newname+suffix]
      endelse
      
      if oldname eq group->getTimeName() then begin
        group->setTimeName,newname+suffix
      endif
      
      oldnamelist = [oldnamelist,oldname]
      newnamelist = [newnamelist,newname+suffix]
      
    endfor
    
    group->setDataNames,childnames

    ;now change corresponding yaxisnames
    yaxisname = group->getYaxisName()
    if yaxisname ne '' then begin

      yidx = where(yaxisname eq *self.groupNames,c)
      if c eq 0 then return
      
      group->setYaxisName,newname+'_yaxis'
      ygroup = self->getGroup(yaxisname)
      ygroup->setname,newname+'_yaxis'
      (*self.groupNames)[yidx] = newname+'_yaxis'
      
      oldnamelist = [oldnamelist,yaxisname]
      newnamelist = [newnamelist,newname+'_yaxis']
      
      ;now update yaxis children
      ychildren = ygroup->getAllObjects()
      
      for i = 0,n_elements(ychildren)-1 do begin
        ychildren[i]->getProperty,suffix=suffix,name=oldname
        ychildren[i]->setProperty,name = newname+suffix
        if ~keyword_set(ychildnames) then begin
          ychildnames = [newname+suffix]
        endif else begin
          ychildnames = [ychildnames,newname+suffix]
        endelse
        
        if oldname eq ygroup->getTimeName() then begin
          ygroup->setTimeName,newname+suffix
        endif
        
        oldnamelist = [oldnamelist,oldname]
        newnamelist = [newnamelist,newname+suffix]
        
      endfor
      
      ygroup->setDataNames,ychildnames
    
    endif
    
    if keyword_set(windowStorage) then begin
      windowStorage->updatedatareference,oldnamelist,newnamelist
    endif
 
  endif
  
  if keyword_set(mission) then begin
  
    (*self.misNames)[idx] = mission
    
  endif
  
  if keyword_set(observatory) then begin
  
    (*self.obsNames)[idx] = observatory
    
  endif
  
  if keyword_set(instrument) then begin
  
    (*self.insNames)[idx] = instrument
    
  endif
    
  children = group->getAllObjects()
    
  for i = 0,n_elements(children)-1 do begin
    
    children[i]->setProperty,mission=mission,observatory=observatory,instrument=instrument,units=units,coordSys=coordinate_system,st_type=st_type
  
  endfor
  
  fail = 0
  
  return
  
end

PRO SPD_UI_LOADED_DATA::Cleanup

  if ptr_valid(self.groupObjs) then begin
    obj_destroy,*self.groupObjs
  endif
  
  ptr_free,self.groupObjs
  ptr_free,self.groupNames
  ptr_free,self.insNames
  ptr_free,self.misNames
  ptr_free,self.obsNames
  
END ;--------------------------------------------------------------------------------



FUNCTION SPD_UI_LOADED_DATA::GetObjects,name=name

  compile_opt idl2
  
  if ~ptr_valid(self.groupObjs) || $
     ~ptr_valid(self.groupNames) then return,0

  groups = *self.groupObjs
  names = *self.groupNames

  IF ~keyword_Set(name) then begin
  
    for i = 0,n_elements(groups)-1 do begin
    
      if groups[i]->getSize() ne 0 then begin
        if n_elements(objlist) eq 0 then begin
          objlist = [groups[i]->getAllObjects()]
        endif else begin
          objlist = [objlist,groups[i]->getAllObjects()]
        endelse
      endif
    
    endfor
    return, objlist
  endif else begin
  
   group = self->getGroup(name)
   
   if obj_valid(group) then return,group->getAllObjects()
   
   for i = 0,n_elements(groups)-1 do begin
      if groups[i]->hasChild(name) then begin
        return,[groups[i]->getObject(name)]
      endif
   endfor
    
 endelse
 
 return,0
    
END ;--------------------------------------------------------------------------------

;-------------------FUNCTIONS BELOW SUBJECT TO CHANGE-----------------
;---------------------------------------------------------------------
;---------------------------------------------------------------------

function spd_ui_loaded_data::getGroup,name

  compile_opt idl2

  if ~ptr_valid(self.groupNames) || $
     ~ptr_valid(self.groupObjs) then return,0
  
  groupNames = *self.groupNames
  
  idx = where(groupNames eq name,c)
  
  if c eq 0 then return,0
  if c gt 1 then return,0 ;error on duplicate names
  
  return,(*self.groupObjs)[idx]

end

function spd_ui_loaded_data::getGroupNames

  compile_opt idl2

  if ~ptr_valid(self.groupNames) then $
    return,0 $
  else $
    return,*self.groupNames

end

;only works on array dimensional quantities at the moment(no 3+-d quantities)
;pro spd_ui_loaded_data::SplitVecPtr,name,outnames=outnames,outptrs=outptrs,suffixes=suffixes
pro spd_ui_loaded_data::SplitVecPtr,name,d,outnames=outnames,outptrs=outptrs,suffixes=suffixes

  compile_opt idl2

;  get_data, name, data = d
  
  dim = dimen(d.y)
  
  ndim =  n_elements(dim)       ;jmm, 20-nov-2008
  If(ndim Gt 1) Then Begin
    if dim[1] eq 3 then begin
      suffixes =  ['x', 'y', 'z']
    endif else begin
      suffixes =  strtrim(string(indgen(dim[1])), 2)
    endelse
    
    suffixes = '_' + suffixes
    
    outnames =  name + suffixes
    outptrs =  ptrarr(dim[1])
    for i =  0, dim[1]-1 do outptrs[i] =  ptr_new(reform(d.y[*, i]))
  Endif Else Begin
    suffixes = ['']
    outnames =  name+'_data'
    outptrs =  ptrarr(1)
    outptrs[0] =  ptr_new(d.y)
  Endelse
 
end

;function designed to return data relevant to populating the widget tree
;Should only be used by the widget_tree object
function spd_ui_loaded_data::getTreeData

  if ~ptr_valid(self.groupObjs) || $
     ~ptr_valid(self.groupNames) || $
     ~ptr_valid(self.insNames) || $
     ~ptr_valid(self.obsNames) || $
     ~ptr_valid(self.misNames) then begin
       return,0
  endif else begin
  
    names = [[*self.misNames],[*self.obsNames],[*self.insNames],[*self.groupNames]]
    
    return,{names:names,objs:*self.groupObjs}
    
  endelse

end

pro spd_ui_loaded_data::reset

  compile_opt idl2

  self.dataID=1
  self.groupID=1
  
  if ptr_valid(self.groupObjs) then begin
    
    obj_destroy,*self.groupObjs
    ptr_free,self.groupObjs
    ptr_free,self.groupNames
    ptr_free,self.insNames
    ptr_free,self.misNames
    ptr_free,self.obsNames
    
  endif
  
end

FUNCTION SPD_UI_LOADED_DATA::Init

  compile_opt idl2

   Catch, theError
   IF theError NE 0 THEN BEGIN
      Catch, /Cancel
      ok = Error_Message(Traceback=Keyword_Set(debug))
      RETURN, 0
   ENDIF

   self.dataID = 1
   self.groupID = 1
   
RETURN, 1

END ;--------------------------------------------------------------------------------



PRO SPD_UI_LOADED_DATA__DEFINE

   struct = { SPD_UI_LOADED_DATA,    $

              groupObjs: Ptr_New(),   $ ; array of group objects for loaded data
              groupNames:ptr_new(),   $ ; array of names of groups
              insNames:ptr_new(),     $ ; array of names of instruments
              obsNames:ptr_new(),     $ ; array of names of observatories for each group
              misNames:ptr_new(),     $ ; array of names of missions for each group
              groupid:1L,             $ ; Next groupid value
              dataID: 1L             $ ; This is the value that will be assigned to the next dataID to be created
                                        ; values start counting at 1 not 0   
}

END
