;+
;NAME:
;  spd_ui_data_group
;
;
;Purpose:
;  This object represents a group of data objects, as a means of 
;  simplifying the logic of the loaded data object 
;
;METHODS:
;  addDataObject:  This method takes a dataObject, extracts the name & active flag
;              Then passes those into the add method
;              
;  add: This is the generic add method, takes a name, an object, and an optional active 
;              flag
; 
;  remove: This method removes an object with a particular name from the data structure
;          It returns 1 on success and 0 upon failure.  Optional keyword nodelete, stops 
;          data from being deleted when data Object removed.
;
;  removeall: this method removes all objects from the group.
;          It returns 1 on success and 0 upon failure.  Optional keyword nodelete, stops 
;          data from being deleted when data Object removed.
;          
;  hasChild: this method determines if the group has a child with a particular name
;            returns 1 for yes and 0 for no
;            
;  hasActive: this method returns 1 if the group has an active object with a 
;            particular name and 0 otherwise
; 
;  setActive: this method sets an object with a particular name to active
;             If the name provided is the groupname, the whole group will
;             become active
;
;  clearActive: this method will deactivate the object with the provided name
;             If the name provided is the groupname, the whole group will
;             become inactive
;
;  clearAllActive: this method will deactive the group and all its members
;  
;  getActiveChildren: this method returns the names of all active members or 0 if there
;             are no active members(or no members at all)
;             
;  getChildren: this method returns the names of all members
;  
;  getTimeObject: this method returns the timeobject in the group
;  
;  getDataObjects: this method returns the dataobjects in the group
;  
;  getObject: this method returns an object with a particular name or 0 if it
;             is not stored in this object
;  
;  getObjects: this method returns all objects stored in the group or 0 if
;             it contains no objects
;  
;  getActive: this method returns the active flag for the group
;  
;  getName: this method returns the group name
;  
;  setName: this method sets the group name
;  
;  getDataNames: returns the names of children BUT time
;  
;  setTimeName: set the name of the time object in this group
;  
;  getTimeName: get the name of the time object in this group
;  
;  setYaxisName: set the name of the yaxis group for this group
;  
;  getYaxisName: get the name of the yaxis group for this group
;  
;  setIndepName:set the name of the independent variable data name for this group
;  
;  getIndepName: get the name of the independent variable data name for this group
;  
;  getSize: this method returns the number of objects stored in the group
;  
;  getTimeRange: this method returns the start and stop time strings the
;                time object of this group
;
;  init: has two optional keywords.  name,active
;  
;  NOTES: As the data_group object is part of loaded data and data management,
;         destroying this object or removing from this object will result in
;         the contained objects being destroyed and their memory being freed
;        
;  
;  
;$LastChangedBy: jimm $
;$LastChangedDate: 2014-02-11 10:54:32 -0800 (Tue, 11 Feb 2014) $
;$LastChangedRevision: 14326 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas_gui/objects/spd_ui_data_group__define.pro $
;-


pro spd_ui_data_group::addDataObject,object

  compile_opt idl2

  name = object->getname()
  active = object->getactive()
  
  self->add,name,object,active=isActive

end

pro spd_ui_data_group::add,name,object,active=active

  compile_opt idl2

  if ~keyword_set(active) then active = 0
  
  if ~ptr_valid(self.dataObjs) then begin
    oarr = objarr(1)
    oarr[0] = object
    narr = strarr(1)
    narr[0] = name
    aarr = bytarr(1)
    aarr[0] = active
    self.size = 1
  endif else begin
    oarr = *self.dataObjs
    narr = *self.dataNames
    aarr = *self.dataActive
    ptr_free,self.dataObjs,self.dataNames,self.dataActive
    oarr = [oarr,object]
    narr = [narr,name]
    aarr = [aarr,active]
    self.size+=1
  endelse

  self.dataObjs = ptr_new(oarr)
  self.dataNames = ptr_new(narr)
  self.dataActive = ptr_new(aarr)

end

function spd_ui_data_group::remove,name,nodelete=nodelete

  compile_opt idl2

  if ~ptr_valid(self.dataObjs) then return,0
  
  if ~self->hasChild(name) then return,0
  
  names = *self.dataNames
  actives = *self.dataActive
  objs = *self.dataObjs
  
  ptr_free,self.dataNames,self.dataActive,self.dataObjs
  
  idx = where(names eq name,c)
  
  if c eq 0 then return,0
  
  for i = 0,n_elements(idx)-1 do begin
  
    obj = objs[idx[i]]
    
    if ~keyword_set(nodelete) then begin
      obj->getProperty,dataPtr=dataPtr,limitPtr=limitPtr,dlimitPtr=dlimitPtr
      ptr_free,dataPtr,limitPtr,dlimitPtr
      obj_destroy,obj
    endif
  
  endfor
  
  idx = where(names ne name,c)
  
  if c eq 0 then begin
    self.size = 0
  endif else begin
    names = names[idx]
    actives = actives[idx]
    objs = objs[idx]
    self.dataNames = ptr_new(names)
    self.dataActive = ptr_new(actives)
    self.dataObjs = ptr_new(objs)
    self.size = n_elements(names)
  endelse

  return,1

end

function spd_ui_data_group::removeAll,nodelete=nodelete

  compile_opt idl2
  
  if ~ptr_valid(self.dataObjs) then return,0
     
  data = *self.dataObjs
  ptr_free,self.dataNames,self.dataActive,self.dataObjs
 
  if ~keyword_set(nodelete) then begin
    for i = 0,n_elements(data)-1 do begin
      ptr = data[i]->getDataPtr()
      ptr_free,ptr
    endfor
  endif
  
  obj_destroy,data
 
end

function spd_ui_data_group::hasChild,name

  compile_opt idl2

  if ~ptr_valid(self.dataNames) then return,0
  
  children = *self.dataNames
  
  return,in_set(name,children)

end



function spd_ui_data_group::hasActive,name

  compile_opt idl2

  active = self->getActiveChildren()
  
  if active[0] ne -1 then $
    return,in_set(name,active) $
  else $
    return,0

end

pro spd_ui_data_group::setActive,name,clear=clear

  compile_opt idl2

  if keyword_set(clear) then val = 0 else val = 1

  if name eq self.name then begin
    self.active = val
    return
  endif
  
  if ~ptr_valid(self.dataNames) || ~ptr_valid(self.dataActive) then return
  
  names = *self.dataNames
  actives = *self.dataactive
  
  idx = where(name eq names,c)
  
  if c ne 0 then actives[idx] = val
  
  ptr_free,self.dataactive
  self.dataactive=ptr_new(actives)

end

pro spd_ui_data_group::clearActive,name

  compile_opt idl2

 self->setActive,name,/clear
  
end

pro spd_ui_data_group::clearAllActive

  compile_opt idl2

  self.active = 0
  
  if ptr_valid(self.dataActive) then begin
    (*self.dataActive)[*] = 0
  endif

end

function spd_ui_data_group::getActiveChildren

  compile_opt idl2

  if self.active then return,self->getChildren()
  
  if ptr_valid(self.dataNames) && ptr_valid(self.dataActive) then begin
    children = *self.dataNames
    active = *self.dataActive
    
    idx = where(active eq 1,c)
    
    if c eq 0 then return,0
    
    return,children[idx]
  endif
  
  return,0

end

function spd_ui_data_group::getChildren

  compile_opt idl2

  if ptr_valid(self.dataNames) then $
    return,[*self.dataNames] $
  else $
    return, 0

end

function spd_ui_data_group::getTimeObject

  compile_opt idl2

  if ~ptr_valid(self.dataObjs) || $
     ~ptr_valid(self.dataNames) then return,0
     
  idx = where(*self.dataNames eq self.timename,c)
  
  if c eq 0 || c gt 1 then return,0
  
  return,(*self.dataObjs)[idx]  

end

function spd_ui_data_group::getDataObjects

  compile_opt idl2

  if ~ptr_valid(self.dataObjs) || $
     ~ptr_valid(self.dataNames) then return,0

  idx = where(*self.dataNames ne self.timename,c)
  
  if c eq 0 then return,0
  
  return,(*self.dataObjs)[idx]  

end

function spd_ui_data_group::getObject,name

  compile_opt idl2 

  if ~ptr_valid(self.dataObjs) then return,0
  
  names = *self.dataNames
  
  idx = where(names eq name,c)
  
  if c eq 0 then return,0
  
  return,(*self.dataObjs)[idx]

end

function spd_ui_data_group::getAllObjects

  compile_opt idl2

  if ~ptr_valid(self.dataObjs) then $
    return,0 $
  else $
    return,*self.dataObjs
  
end

function spd_ui_data_group::getActive

  compile_opt idl2

  return,self.active
  
end

function spd_ui_data_group::getName

  compile_opt idl2

  return,self.name
  
end

pro spd_ui_data_group::setName,name

  compile_opt idl2

  self.name = name
  
end

function spd_ui_data_group::getDataNames

  children = self->getChildren()
  timeName = self->getTimeName()
  
  idx = where(children ne timeName,c)
  
  if c eq 0 then begin
    return,['']
  endif else begin
    return,children[idx]
  endelse

end

pro spd_ui_data_group::setDataNames,names

  if ptr_valid(self.dataNames) && n_elements(*self.dataNames) eq n_elements(names) then begin
    *self.dataNames = names
  endif
  
end
    

pro spd_ui_data_group::setTimeName,name

  compile_opt idl2 

  self.timename = name
  
  if ptr_valid(self.dataObjs) then begin
  
    dataObjs = *self.dataObjs
    
    for i = 0,n_elements(dataObjs)-1 do begin
      dataObjs[i]->setProperty,timeName=name
    endfor
  
  endif
  
end

function spd_ui_data_Group::getTimeName

  compile_opt idl2

  return,self.timename

end

pro spd_ui_data_Group::setCadence,cadence

  compile_opt idl2
  
  self.cadence = cadence
  
end

function spd_ui_data_Group::getCadence

  compile_opt idl2
  
  return,self.cadence
  
end

function spd_ui_data_group::getYAxisParent

  compile_opt idl2

  return,self.yaxisparent

end

pro spd_ui_data_group::setYAxisParent,name
 
  compile_opt idl2

  self.yaxisparent=name
  
end

function spd_ui_data_group::getYaxisName

  compile_opt idl2

  return,self.yaxisName
  
end

pro spd_ui_data_group::setYAxisName,name

  compile_opt idl2

  self.yaxisname = name
  
  if ptr_valid(self.dataObjs) then begin
  
    dataObjs = *self.dataObjs
    
    for i = 0,n_elements(dataObjs)-1 do begin
      dataObjs[i]->setProperty,yaxisName=name
    endfor
  
  endif
  
end

pro spd_ui_data_group::setisYaxis

  self.isyaxis = 1

end

pro spd_ui_data_group::setnotYaxis

  self.isyaxis = 0
  
end

function spd_ui_data_group::getIsYaxis

  return,self.isyaxis

end

function spd_ui_data_group::getIndepName

  compile_opt idl2

  return,self.indepName
  
end

pro spd_ui_data_group::setIndepName,name

  compile_opt idl2

  self.indepname = name
  
  if ptr_valid(self.dataObjs) then begin
  
    dataObjs = *self.dataObjs
    
    for i = 0,n_elements(dataObjs)-1 do begin
      dataObjs[i]->setProperty,indepName=name
    endfor
  
  endif
  
end

function spd_ui_data_group::getSize

  compile_opt idl2

  return,self.size

end

function spd_ui_data_group::getNdims

  compile_opt idl2
  
  return,self.ndims

end

function spd_ui_data_group::getDim1

  tm = self->getTimeObject()
  
  if ~obj_valid(tm) then return,0
  
  tm->getProperty,dataPtr=dp
  
  if ~ptr_valid(dp) then return,0
  
  return,n_elements(*dp)

end

function spd_ui_data_group::getTimeRange

  if ~keyword_set(self.timeName) then return,0
  
  timeObj = self->getObject(self.timeName)
  
  tr = timeObj[0]->getRange()
  
  if n_elements(tr) eq 1 then return,0
  
  return,time_string(tr)

end

function spd_ui_data_group::init,name=name,active=active

  compile_opt idl2

  if keyword_set(name) then self.name = name
  if keyword_set(active) then self.active=active
  
  self.nDims = 2

  return,1

end

pro spd_ui_data_Group::cleanup

  compile_opt idl2

  if ptr_valid(self.dataObjs) then obj_destroy,*self.dataObjs

  ptr_free,self.dataNames,self.dataActive,self.dataObjs

end


pro spd_ui_data_group__define

  struct = { SPD_UI_DATA_GROUP, $
               dataNames: ptr_new(),$
               dataActive: ptr_new(),$
               dataObjs: ptr_new(),$
               active:0, $
               name:'', $
               timeName:'',$
               cadence:0.,$
               yAxisName:'',$
               yAxisParent:'',$
               indepName:'',$
               size:0, $
               ndims:2, $
               isYaxis:0 $
             }
               


end
