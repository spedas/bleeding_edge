;+
;NAME:
; spd_ui_widget_tree__define.pro
;
;PURPOSE:
;  Object representing the loaded data tree compound widget.
;
;CALLING SEQUENCE:
;  wt = obj_new('spd_ui_widget_tree',parentid,uvalue,loadedData,xsize=200,ysize=200,mode=1)
;
;Examples:
; 1.
;   widget_control,event.id,get_value=val
;   print, val->getvalue()
;
; 2. obj = obj_new('spd_ui_widget_tree,tlb,'TREE',loadedData,uname='TREE_NAME')
;    id = widget_info(find_by_uname='TREE_NAME')
;    widget_control,id,get_value=val
;    print,val->getvalue()
;    val->setProperty,multi=0
;
; Attributes:
;
;  uvalue: the user value that will be returned by event handler
;  uname: the user name that can be used to identify the widget
;  xsize: the x axis length of the tree viewing area(scrollbars will be added automatically)
;  ysize: the y axis length of the tree viewing area(scrollbars will be added automatically)
;  mode: the visualization/selection mode(see NOTES below)
;  multi: whether multiple selections with ctrl/shift click are allowed
;  leafonly: 1: indicates selection may be only made at the lowest level of the tree
;            0: indicates selections may be done at any point in the tree
;
;NOTES:
;
;  There are 4-different selection modes for this widget.  Each selection
;  mode will be appropriate for different panels.
;  Mode 0: tplot-layout selection,
;          data-processing selection,
;          loaded-data-selection
;
;  Mode 1 : variable-selection,
;           x-layout selection,
;           y-lineplot-layout selection
;           line-trace selection.
;           save-data-as
;
;  Mode 2 : y-spectra-layout selection
;           z-spectra-layout selection
;           (possibly data-processing)
;
;  Mode 3 : Calculate Panel
;           Possibly future versions of data analysis
;
;  Mode Descriptions
;  Mode 0 is a tplot-like selection.  It provides access to
;  only the groupname and doesn't let the user drill down into internal
;  quantities.
;
;  When values are returned from mode 0, an array of pointers to
;  structs that store that names of the contained variables will be returned.
;  (or 0 on fail)
;
;  Mode 1 is a 1-D component selection.  It allows the user to
;  look at and select internal 1-d quantities,
;
;  When values are returned from mode 1, an array of strings will be
;  returned. (or 0 on fail)
;
;  Mode 2 is a 2-D component selection.  It allows the user to look at
;  and select any 2-d quantities.  In mode 2 yaxis-values will
;  not be grouped inside their containing group, instead they will be grouped
;  side-by-side with their containing group.
;
;  Values returned from mode 2 will be an array of strings of groupnames.
;  (or 0 on fail)
;
;  Mode 3 allows selection of either group quantities('tha_state_pos') or
;  components('tha_state_pos_x'), but does not allow branch selection.
;  (ie Cannot grab spedas and get all quantities.)
;
;  Public Methods:
;  update: Call this routine after loaded data has been changed by
;          some other process
;  getProperty: Use this to get the current widget_tree settings
;  setProperty: Use this to change the current widget_tree settings
;  getValue(): Use this to return a list of the current selections.
;
;  The other methods should NOT be called by external code.  Making code
;  that uses them will make this code very difficult to maintain. So if
;  you need a feature, just request that it be added instead.
;
;
;HISTORY:
;$LastChangedBy: egrimes $
;$LastChangedDate: 2015-08-18 12:18:04 -0700 (Tue, 18 Aug 2015) $
;$LastChangedRevision: 18516 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas_gui/objects/spd_ui_widget_tree__define.pro $
;
;--------------------------------------------------------------------------------


;Public Method
;call this routine to update tree after changes have been made in:
;(1) The data objects(particularly: name,mission,instrument,observatory fields)
;(2) The loadeddata object
pro spd_ui_widget_tree::update,selected=selected,from_copy=copy
  compile_opt idl2

  widget_control,self.parent,update=0

  if keyword_set(copy) && widget_valid(copy) then begin
    copy_root = widget_info(copy,/child)
    oldtree = widget_info(copy_root,/child)
  endif else begin
    oldtree = self.root
  endelse

  destroytree = self.root

  self->populateTree,oldtree

  self->copyexpansion,oldtree,self.root

  if keyword_set(selected) && is_string(selected[0]) then begin
    self->setSelected,selected
  endif

  widget_control,destroytree,/destroy

  widget_control,self.parent,update=1

end

;Public Method
;  uvalue: the user value that will be returned by event handler
;  uname: the user name that can be used to identify the widget
;  xsize: the x axis length of the tree viewing area
;  ysize: the y axis length of the tree viewing area
;  mode: the visualization/selection mode(see top documentation)
;  multi: whether multiple selections are allowed within the tree or not
;  leafonly: Set this flag to 1 if you want selections to be allowed
;            only on the leaf of the tree
;  showdatetime: If this boolean is 1 the date time of a variable will
;             be printed with its name
pro spd_ui_widget_tree::getProperty,$
                                uvalue=uvalue,$
                                uname=uname,$
                                xsize=xsize,$
                                ysize=ysize,$
                                mode=mode,$
                                multi=multi,$
                                leafonly=leafonly,$
                                showdatatime=showdatetime

  compile_opt idl2

  uvalue = self.uvalue
  uname = self.uname
  xsize = self.xsize
  ysize = self.ysize
  mode = self.mode
  multi = self.multi
  leafonly = self.leafonly
  showdatatime = self.showdatetime

end

;Public Method
;  uvalue: the user value that will be returned by event handler
;  uname: the user name that can be used to identify the widget
;  xsize: the x axis length of the tree viewing area
;  ysize: the y axis length of the tree viewing area
;  mode: the visualization/selection mode(see top documentation)
;  multi: whether multiple selections are allowed within the tree or not
;  leafonly: Set this flag to 1 if you want selections to be allowed
;            only on the leaf of the tree
;  showdatetime: If this boolean is 1 the date time of a variable will
;             be printed with its name
pro spd_ui_widget_tree::setProperty,$
                                uvalue=uvalue,$
                                uname=uname,$
                                xsize=xsize,$
                                ysize=ysize,$
                                mode=mode,$
                                multi=multi,$
                                leafonly=leafonly,$
                                showdatetime=showdatetime
  compile_opt idl2

  if keyword_set(uvalue) then begin
    self.uvalue = uvalue
    widget_control,self.id,set_uvalue=uvalue
  endif

  if keyword_set(uname) then begin
    self.uname = uname
    widget_control,self.id,set_uname=uname
  endif

  ;the x/y changes are done simultaneously, if possible
  ;this should prevent screen flicker when resizing
  if keyword_set(xsize) && keyword_set(ysize) then begin
    self.xsize=xsize
    self.ysize=ysize
    widget_control,self.root,xsize=xsize,ysize=ysize
  endif else if keyword_set(xsize) then begin
    self.xsize=xsize
    widget_control,self.root,xsize=xsize
  endif else if keyword_set(ysize) then begin
    self.ysize=ysize
    widget_control,self.root,ysize=ysize
  endif

  if is_num(mode) then begin
    self.mode = mode
  endif

  if is_num(multi) then begin
    self.multi = multi
  endif

  if is_num(leafonly) then begin
    self.leafonly = leafonly
  endif

  if is_num(showdatetime) then begin
    self.showdatetime = showdatetime
  endif

  if is_num(multi) || is_num(mode) || $
     is_num(leafonly) || is_num(showdatetime) then begin
    self->update
  endif


end

;copy the tree
function spd_ui_widget_tree::getCopy

  compile_opt idl2

  new_base = widget_base()

  new_root = widget_tree(new_base)

  widget_tree_move,self.root,new_root,/copy

  return,new_base

end

;Public method
;returns a list of the current selections in the tree
;returns 0 if no selection exists.
function spd_ui_widget_tree::getValue

  compile_opt idl2

  return,self->getValueRecursive(self.root,0)

end

;Private Method: Not to be called by external code
;method for internal use by object.  Used to traverse tree in the
;getValue method
function spd_ui_widget_tree::getValueRecursive,widget,selected

  compile_opt idl2

  widget_control,widget,get_uvalue=state

  if ~is_struct(state) then return,0

  if widget eq self.root then begin
    sel = 0
  endif else begin
    sel = selected || widget_info(widget,/tree_select)
  endelse

  val = 0

  ;if we are at an interior node that will never have a value that is returned
  ;then we just aggregate any values from recursive calls to any children
  if state.value eq 'INTERIOR' then begin

    children = widget_info(widget,/all_children)

    ;no valid children....
    if (~widget_valid(children[0]) || self->hasDummy(widget)) && self.mode ne 3 then begin
      if sel && ~self.leafonly then begin ;if no valid children is because tree not expanded, then identify children
        tmp = self->getDataChildren(widget,names=names)
        return,self->formatValueGroup(names)
      endif
      
      return,val
    endif
    ; check again for valid children (if self.mode eq 3 (calculate panel) above code won't have run)
    if widget_valid(children[0]) then begin
      for i = 0,n_elements(children)-1 do begin

        res = self->getValueRecursive(children[i],sel)

        if ~is_num(res) then begin
          if ~is_num(val) then begin
            val = [val,res]
          endif else begin
            val = [res]
          endelse
        endif

      endfor
    endif

  ;if we are at a group, we call the routine that handles the messiness
  ;of figuring out which values should be returned, given the set of options
  endif else if state.value eq 'GROUP' then begin

   return, self->getValueGroup(widget,sel)

  endif

  return,val

end

;Private Method: Not to be called by external code
;gets the value after the value routine has recursed down to a group
function spd_ui_widget_tree::getValueGroup,widget,selected

  sel = widget_info(widget,/tree_select)

  if self.mode eq 0 then begin

    if sel || (~self.leafonly && selected) then begin
      widget_control,widget,get_uvalue=state

      return,ptr_new({groupname:state.name,timename:state.timename,datanames:state.datanames,yaxisname:state.yaxisname})

    endif

  endif else if self.mode eq 1 then begin

    return,self->getGroupValueRecursive(widget,selected || sel)

  endif else if self.mode eq 2 then begin

    if sel || (~self.leafonly && selected) then begin

      widget_control,widget,get_uvalue=state

      return,state.name

    endif

  endif else if self.mode eq 3 then begin

     return,[self->getGroupValueRecursive(widget,0)]

  endif

  return,0

end

;Private Method: Not to be called by external code
;used to walk through a group and return a list of leaf names
function spd_ui_widget_tree::getGroupValueRecursive,widget,selected

  compile_opt idl2

  if widget_info(widget,/tree_folder) then begin

    widget_control,widget,get_uvalue=state

    if self.mode eq 3 && widget_info(widget,/tree_select) then begin
      out = [state.name]
    endif else begin
      out = 0
    endelse

    children = widget_info(widget,/all_children)

    sel = selected || widget_info(widget,/tree_select)

    if self.mode eq 3 then sel = 0

    if children[0] ne 0 && ~self->hasDummy(widget) then begin

      for i = 0,n_elements(children)-1 do begin

        res = self->getGroupValueRecursive(children[i],sel)

        if ~is_num(res) then begin
          if ~is_num(out) then begin
            out = [out,res]
          endif else begin
            out = [res]
          endelse
        endif

      endfor

    endif else if sel && ~self.leafonly then begin
      out = self->formatValueGroup(state.name)
    endif
    
    return,out
    
    
  endif else if widget_info(widget,/tree_select) || (selected && ~self.leafonly) then begin

    widget_control,widget,get_uvalue=state

    return,state.name

  endif

  return,0

end

;helper function to format return values for different modes
function spd_ui_widget_tree::formatValueGroup,names
  
  compile_opt idl2
  
  if ~keyword_set(names[0]) then return,0
  
  out = 0
  
  for i = 0,n_elements(names)-1 do begin
  
    group = self.ld->getGroup(names[i])
    tmp = 0
    
    if obj_valid(group) then begin
    
      if self.mode eq 0 && ~group->getIsYAxis() then begin
        tmp = ptr_new({groupname:group->getName(),timename:group->getTimeName(),datanames:group->getDataNames(),yaxisname:group->getYaxisName()})
      endif else if self.mode eq 1 then begin
        tmp = [group->getTimeName(),group->getDatanames()]
        if keyword_set(group->getYaxisName()) then begin
          yaxisgroup = self.ld->getGroup(group->getYaxisName())
          if obj_valid(yaxisgroup) then begin
            tmp = [tmp,yaxisgroup->getTimeName(),yaxisgroup->getDataNames()]
          endif
        endif
      endif else if self.mode eq 2 then begin
        tmp = names[i]
      endif else if ~group->getIsYAxis() then begin
        tmp = names[i]
      endif
      
      if keyword_set(tmp) then begin
        if ~keyword_set(out) then begin  
          out = [tmp]
        endif else begin
          out = [out,tmp]
        endelse
      endif
    endif
  endfor
  
  return,out
  
end

;Private Method: Not to be called by external code
;method walks down the tree and unexpands nodes
;Used in event handler after an expand event is
;returned
pro spd_ui_widget_tree::collapseNode,node

  children = widget_info(node,/all_children)

  if children[0] eq 0 then return

  for i = 0,n_elements(children)-1 do begin

    if widget_info(children[i],/tree_expanded) then begin

      widget_control,children[i],set_tree_expanded=0

      ;unselect?

      self->collapseNode,children[i]

    endif

  endfor

end

;Private Method: not to be called by external code
;This walks down the trees and expands all the nodes
;in the current tree that were expanded in the old tree
pro spd_ui_widget_tree::copyexpansion,oldnode,newnode

  compile_opt idl2

  oldchildren = widget_info(oldnode,/all_children)
  newchildren = widget_info(newnode,/all_children)

  if oldchildren[0] eq 0 then return
  if newchildren[0] eq 0 then return

  for i = 0,n_elements(newChildren)-1 do begin

    widget_control,newChildren[i],get_value=newname

    if ~keyword_set(newnames) then begin
      newnames = [newname]
    endif else begin
      newnames = [newnames,newname]
    endelse

  endfor

  for i = 0,n_elements(oldchildren)-1 do begin

    widget_control,oldchildren[i],get_value=oldname

    idx = where(oldname eq newnames,c)

    if c eq 1 then begin

      ;For some reason, windows sometimes like to activate the selection on
      ;this node when we expand it.
      tree_select = widget_info(newchildren[idx],/tree_select)

      widget_control,newchildren[idx],set_tree_expanded=widget_info(oldchildren[i],/tree_expanded)

      if widget_info(newchildren[idx],/tree_select) ne tree_select then begin
        widget_control,newchildren[idx],set_tree_select=tree_select
      endif

      self->copyexpansion,oldchildren[i],newchildren[idx]

    endif

  endfor

end

;Private Method: Not to be called by external code
;This routine constructs the assembles the idl tree widgets
;from the contents of the loadedData object
pro spd_ui_widget_tree::populateTree,oldtree

  compile_opt idl2

  self.root = widget_tree(self.stash,xsize=self.xsize,ysize=self.ysize,UVALUE={value:'INTERIOR',children:'',name:''},multiple=self.multi,bitmap=self.nodemap,/mask,/context_events)

  ldTreeData = self.ld->getTreeData()

  if is_struct(ldTreeData) then begin

    dim = dimen(ldTreeData.names)

    ;this loops overall names, adding a branch for each one
    for i = 0,dim[0]-1 do begin

      self->addBranch,ldTreeData.names[i,*],ldTreeData.objs[i],oldtree,/force

    endfor

  endif
  
  ;guarantee that at least the top level is expanded
  children = widget_info(self.root,/all_children)
  
  for i = 0,n_elements(children)-1 do begin
    if widget_valid(children[i]) then begin
      self->expandNode,children[i]
    endif
  endfor

end

;Private Method: Not to be called by external code
;walks down to a particular leaf, adding widgets as needed
;Keyword force, will add widgets down to group even if branch is not expanded.
;Keyword addyaxis, will add widgets down to yaxis even if branch is not expanded.
;Keyword addchild, will add widgets down to children even if branch is not expanded.
;If addyaxis & addchild are set, widgets will go to children of yaxis.
pro spd_ui_widget_tree::addBranch,names,obj,oldtree,force=force,addchild=addchild,addyaxis=addyaxis

  compile_opt idl2

  current = self.root
  old_node = oldtree
  
  if keyword_set(addyaxis) || keyword_set(addchild) then begin
    force = 1
  endif

  ;this block walks down the tree, adding interior nodes if necessary
  ;on its way to a leaf
  if n_elements(names) gt 1 then begin
    for i = 0,n_elements(names)-2 do begin

      name = names[i]

      self->expandInterior,current,name,next_node=next_node
      old_node=self->getChild(old_node,name)
      current=next_node
      
      ;Stop expansion
      if ~widget_valid(current) || ~widget_valid(old_node) then begin
        return
      endif
      
      ;Stop expansion because branch not expanded
      ;Exceptions, force keyword set, top level is always automatically expanded
      if ~widget_info(old_node,/tree_expanded) && ~keyword_set(force) then begin ; && i ne 0 then begin
        return
      endif 
      
      ;automatically expand top level
     ; if i eq 0 then begin
     ;   widget_control,current,/set_tree_expanded
    ;  endif
     
    endfor
  endif
    
  ;At the leaves, the tree organization becomes more heterogenous.
  ;NOTE: the visibility of components in the group dependent on what self.mode is set to

  if ~obj_valid(obj) then begin
    return
  endif
  
  if self.mode ne 2 && obj->getisyaxis() then begin
    return
  endif 
   
  self->addGroup,current,obj,group=group
  
  old_node = self->getChild(old_node,obj->getname())
  
  if ~widget_valid(group) || ~widget_valid(old_node) then begin
    return
  endif
  
  if ~widget_info(old_node,/tree_expand) && ~keyword_set(addyaxis) && ~keyword_set(addchild) then begin
    return
  endif 
    
  self->addChildren,group,obj,ygroup=yaxisgroup,yobject=yaxisobject
  
  if ~obj_valid(yaxisobject) then begin
    return
  endif
  
  old_node = self->getChild(old_node,yaxisobject->getname())
  
  if ~widget_valid(yaxisgroup) || ~widget_valid(old_node) then begin
    return
  endif
  
  if ~widget_info(old_node,/tree_expand) && (~keyword_set(addyaxis) || ~keyword_set(addchild)) then begin
    return
  endif 
  
  self->addChildren,yaxisgroup,yaxisobject
  
end

;Add the children to the group component of the data tree.
;Will also add a y-axis component, if present.
pro spd_ui_widget_tree::addChildren,parent,object,ygroup=ygroup,yobject=yobject

  compile_opt idl2

  ygroup = 0
  ;default to null object
  yobject = obj_new()

  if self.mode ne 1 && self.mode ne 3 then begin
    return
  endif
  
  if ~obj_valid(object) then begin
    return
  endif
  
  childnames = ''
  
  name = object->getname()
  datanames = object->getDataNames()
  timeName = object->getTimeName()
  yaxisname = object->getYaxisName()
  isyaxis = object->getisyaxis()
 
  ts = ''

  if self.showdatetime then begin
    ts = ' [ ' + strjoin(object->getTimeRange(),' to ') + ' ] '
;    self.ld->getVarData,name=timename,data=d
;    if ptr_valid(d) then begin
;      low = min(*d,/nan,max=high)
;      ts = ' [ ' + time_string(low) + ' to ' + time_string(high) + ' ] '
;    endif
  endif
  
  ;turn off updates until operation completes to prevent screen flicker

  self->removeDummy,parent

  if keyword_set(timeName) then begin
    if keyword_set(childnames) then begin
      childnames = [childnames,timename]
    endif else begin
      childnames = [timename]
    endelse
    timeid = widget_tree(parent,value=timeName+ts,uvalue={value:'TIME',name:timename},bitmap=self.leafmap,/mask)
  endif

  if keyword_set(datanames) then begin

    for i = 0,n_elements(datanames)-1 do begin
      data = widget_tree(parent,value=datanames[i]+ts,uvalue={value:'DATA',name:datanames[i]},bitmap=self.leafmap,/mask)
    endfor
        
    if keyword_set(childnames) then begin
      childnames = [childnames,datanames]
    endif else begin
      childnames = [datanames]
    endelse
        
  endif

  if keyword_set(yaxisname) && ~isyaxis then begin
    yobject = self.ld->getGroup(yaxisname)

    if obj_valid(yobject) then begin
      self->addGroup,parent,yobject,group=ygroup
          
      if keyword_set(childnames) then begin
        childnames = [childnames,yaxisname]
      endif else begin
        childnames = [yaxisname]
      endelse
          
    endif
 
  endif
   
  widget_control,parent,get_uvalue=state
  state = {value:state.value,name:state.name,children:childnames}
  widget_control,parent,set_uvalue=state
      
end

;add the group component to the data tree
;group returns the widget id of the new group
pro spd_ui_widget_tree::addGroup,parent,object,group=group

  compile_opt idl2
  
  group = 0
  
  if ~obj_valid(object) then return

  name = object->getname()
  datanames = object->getDataNames()
  timeName = object->getTimeName()
  yaxisname = object->getYaxisName()
  isyaxis = object->getisyaxis()
 
  ts = ''
  
  if self.showdatetime then begin
    ts = ' [ ' + strjoin(object->getTimeRange(),' to ') + ' ] '
;    self.ld->getVarData,name=timename,data=d
;    if ptr_valid(d) then begin
;      low = min(*d,/nan,max=high)
;      ts = ' [ ' + time_string(low) + ' to ' + time_string(high) + ' ] '
;    endif
  endif
  
  widget_control,parent,get_uvalue=parent_state
  
  if ~keyword_set(parent_state.children) then begin
    parent_child_names = [name]
  endif else begin
    idx = where(parent_state.children eq name,c)
    
    if c ne 0 then begin
      ;duplicate data group, skip it
      return
    endif 
    
    parent_child_names = [parent_state.children,name]  
  endelse

  if self.mode eq 0 then begin

    if isyaxis then return

   self->removeDummy,parent

    group = widget_tree(parent,$
                        value=name+ts,$
                        uvalue={value:'GROUP',name:name,timename:timename,datanames:datanames,yaxisname:yaxisname},$
                        bitmap=self.leafmap,$
                        /mask)

  endif else if self.mode eq 1 || self.mode eq 3 then begin

    state = {value:'GROUP',name:name,children:''}

    childnames = ''

    self->removeDummy,parent

    group = widget_tree(parent,$
                      value=name+ts,$
                      uvalue=state,$
                      bitmap=self.nodemap,$
                      /folder,$
                      /mask)
                      
    self->addDummy,group
         
  endif else if self.mode eq 2 then begin

    self->removeDummy,parent

    group = widget_tree(parent,$
                         value=name+ts,$
                         uvalue={value:'GROUP',name:name},$
                         bitmap=self.leafmap,$
                         /mask)
  endif

  parent_state = {value:parent_state.value,children:parent_child_names,name:parent_state.name}
  widget_control,parent,set_uvalue=parent_state


end


function spd_ui_widget_tree::getChild,widget,name

  compile_opt idl2

  if widget_valid(widget) then begin
    widget_control,widget,get_uvalue=state
    
    if is_struct(state) && $
       in_set(strlowcase(tag_names(state)),'children') && $
       keyword_set(state.children) then begin
    
      idx = where(name eq state.children,c)
      if c eq 1 then begin
        children = widget_info(widget,/all_children)
        return,children[idx]
      endif
    
    endif
    
  endif
  
  return,0

end

;Private Method: Not to be called by external code
;adds a widget if widget not present, otherwise returns pre-existing widget
;also walks old_tree to make a determination about whether the widget should be expanded at all
pro spd_ui_widget_tree::expandInterior,node,name,next_node=next_node

  compile_opt idl2

  widget_control,node,get_uvalue=state

  next_node = 0

  if state.value ne 'INTERIOR' then begin
    ok = error_message('Illegal attempt to expand node at leaf',/traceback)
    return
  endif
  
  self->removeDummy,node

  if ~keyword_set(state.children) then begin
    state = {value:'INTERIOR',children:[name],name:state.name}
    next_node = widget_tree(node,value=name,uvalue={value:'INTERIOR',children:[''],name:name},/folder,bitmap=self.nodemap,/mask)
    self->addDummy,next_node
  endif else begin

    idx = where(name eq state.children,c)

    if c eq 0 then begin
      next_node = widget_tree(node,value=name,uvalue={value:'INTERIOR',children:[''],name:name},/folder,bitmap=self.nodemap,/mask)
      self->addDummy,next_node
      state = {value:'INTERIOR',children:[state.children,name],name:state.name}
    endif else if c gt 1 then begin
      ok = error_message('Non-unique child should not exist')
      return
    endif else begin
      children = widget_info(node,/all_children)
      next_node = children[idx]
    endelse

  endelse

  widget_control,node,set_uvalue=state

  return

end

pro spd_ui_widget_tree::expandNode,node

  children = widget_info(node,/all_children)
  if children[0] eq 0 || self->hasDummy(node) then begin ;Add new widgets to the tree if they don't already exist
  
    widget_control,node,get_uvalue=state
    data_children = self->getDataChildren(node)
    
    if state.value eq 'GROUP' then begin
      self->addChildren,node,data_children[0]
    endif else if obj_valid(data_children[0]) then begin      
      for i = 0,n_elements(data_children)-1 do begin
        if ~data_children[i]->getIsYaxis() || self.mode eq 2 then begin ;where y-axis gets added depends upon tree mode
          self->addGroup,node,data_children[i]
        endif
      endfor
    endif else if is_string(data_children) then begin
      for i = 0,n_elements(data_children)-1 do begin
        self->expandInterior,node,data_children[i]
      endfor
    endif
    
  endif
 
  children = widget_info(node,/all_children)
  
  ;recursive call automatically expands to tree if it has a single child
  ;and is not a data element
  if widget_valid(children[0]) && $
    ~self->hasDummy(node) then begin
    ;When node is the top of the tree it seems to get selected sometimes by this expand in Windows
    ; See also another note on this in copyExpansion
    tree_select = widget_info(node,/tree_select)
    widget_control,node,/set_tree_expanded
    if widget_info(node,/tree_select) ne tree_select then begin
        widget_control,node,set_tree_select=tree_select
    endif
    
    widget_control,children[0],get_uvalue=state
    if n_elements(children) eq 1 && $
      ~self.ld->isParent(state.name) && $
      ~self.ld->isChild(state.name) then begin
      
      self->expandNode,children[0]
      
    endif
  endif
        
end

;Windows bug causes folder widgets to display as non-folder widgets
;if there are no children.  This code creates fake children, to
;force windows to display correctly

;If children already exist this routine terminates harmlessly
pro spd_ui_widget_tree::addDummy,node

  compile_opt idl2

  children = widget_info(node,/all_children)
  
  if widget_valid(children[0]) then begin
    return
  endif

  dummy = widget_tree(node,value='', bitmap=self.leafmap,/mask)
  
end

;This code determines if a node has a fake child
;return, 1 if it does, 0 otherwise
function spd_ui_widget_tree::hasDummy,node

  compile_opt idl2

  children = widget_info(node,/all_children)

  if n_elements(children) gt 1 || ~widget_valid(children[0]) then begin
    return,0
  endif
  
  widget_control,children[0],get_value=value
  
  if value ne '' then begin
    return,0
  endif
  
  return,1

end

;This code removes a fake child from a node.
;If no fake child exists, it should terminate harmlessly
pro spd_ui_widget_tree::removeDummy,node

  compile_opt idl2

  children = widget_info(node,/all_children)

  if n_elements(children) gt 1 || ~widget_valid(children[0]) then begin
    return
  endif
  
  widget_control,children[0],get_value=value
  
  if value ne '' then begin
    return
  endif
  
  widget_control,children[0],/destroy

end

pro spd_ui_widget_tree::setSelected,selected

  compile_opt idl2

  if ~keyword_set(selected) || ~is_string(selected) then return
  
  ;first make sure the set of selected values actually exist
  ;because the tree is dynamically generated, the values may
  ;be present in loaded data, but need to be added to the tree
  
  tData = self.ld->getTreeData()
  if size(tData, /type) ne 8 then return ;if tData isn't a structure for some reason, e.g. method called when there is no data, then just return
  dim = dimen(tData.names)
  
  for i = 0,n_elements(selected)-1 do begin
  
    name = selected[i]
    
    if self.ld->isChild(name) && ~self.ld->isParent(name) then begin
      obj = self.ld->getObjects(name=name)
      if obj_valid(obj[0]) then begin
        isChild = 1
        obj[0]->getProperty,groupName=name
      endif
    endif
    
    group = self.ld->getGroup(name)
    
    if ~obj_valid(group) then begin
      continue
    endif
    
    if group->getIsYaxis() then begin
      isYaxis = 1
      name = group->getYAxisParent()
    endif
    
    idx = where(name eq tData.names[*,dim[1]-1],c)
  
    if c eq 1 then begin
       names = tData.names[idx,*]
       obj = tData.objs[idx]
       self->addBranch,names,obj,self.root,addChild=isChild,addYaxis=isYaxis,/force
    endif
  
  endfor
  
  self->setSelectedRecursive,self.root,selected
  
end

;Recursive helper for the setSelected function.
pro spd_ui_widget_tree::setSelectedRecursive,node,selected

  compile_opt idl2
  
  if ~widget_valid(node) then begin
    node = self.root
  endif
    
  if widget_info(node,/tree_root) ne node then begin

    widget_control,node,get_uvalue=state
  
    if is_struct(state) then begin
      idx = where(state.name eq selected,c)
  
      if c gt 0 then begin
        widget_control,node,set_tree_select=1
        widget_control,node,set_tree_visible=1
      endif
    endif

  endif

  children = widget_info(node,/all_children)

  if children[0] ne 0 then begin

    for i = 0,n_elements(children)-1 do begin
      self->setSelectedRecursive,children[i],selected
    endfor

  endif


end

;clears the tree of all selections
pro spd_ui_widget_tree::clearSelected

  compile_opt idl2
  
  widget_control,self.root,set_tree_select=0
  
end

;Gets in child names & data objects(if applicable) for a particular
;widget in the tree by querying loaded data, and widget parents.
;widget: Input widget ID
;returns: 0 on error, list of objects if children are data groups or members, list of names otherwise
;keyword names, returns the names of all the groups below selection if widget is an interior node
function spd_ui_widget_tree::getDataChildren,widget,names=names

  compile_opt idl2

  children = 0
  
  widget_control,widget,get_uvalue=state
  
  if state.value eq 'GROUP' then begin
    names = [state.name]
    return,[self.ld->getGroup(state.name)]
  endif else begin
  
    parent_names = [state.name]
  
    root = widget_info(widget,/tree_root)
    parent = widget
  
    ;work back up the tree to find parent names
    while 1 do begin
     
      parent = widget_info(parent,/parent)
      
      if root ne parent then begin
        widget_control,parent,get_uvalue=parent_state
        parent_names = [parent_state.name,parent_names]
      endif else begin
        break
      endelse 
          
    endwhile
    
    ldTreeData = self.ld->getTreeData() 
    if n_elements(parent_names) eq 1 then begin
      idx = where(parent_names[0] eq ldTreeData.names[*,0])
    endif else if n_elements(parent_names) eq 2 then begin
      idx = where(parent_names[0] eq ldTreeData.names[*,0] and $
                  parent_names[1] eq ldTreeData.names[*,1])
    endif else if n_elements(parent_names) eq 3 then begin
      idx = where(parent_names[0] eq ldTreeData.names[*,0] and $
                  parent_names[1] eq ldTreeData.names[*,1] and $
                  parent_names[2] eq ldTreeData.names[*,2])
    endif else begin
      ok = error_message('Unexpected expansion error, too many parents')
      return,0
    endelse
    
    if idx[0] eq -1 then begin
      ok = error_message('Unexpected expansion error, no name')
      return,0
    endif else begin
      names = ldTreeData.names[idx,3]
      if n_elements(parent_names) eq 3 then begin
        return,ldTreeData.objs[idx]
      endif else begin
        return,ldTreeData.names[idx,n_elements(parent_names)]
      endelse
    endelse
   
  endelse
  
end

pro spd_ui_widget_tree::handleContextMenuEvent,event

  varname_id = widget_info(event.handler,find_by_uname='context_name')
  
  var_info = self->getValue()
  if is_string(var_info) then begin
    varname = var_info[0]
  endif else if ptr_valid(var_info[0]) then begin
    varname = (*var_info[0]).groupname
  endif else begin
    return
  endelse

  ; updated the following logic from self.context_width to self.context_width-1 so that pad_num
  ; can't be set equal to 1, egrimes on 8/18/15
  if strlen(varname) lt self.context_width-1 then begin
    pad_num = self.context_width-strlen(varname)
    var_text = strjoin(replicate(' ',pad_num/2)) + varname + strjoin(replicate(' ',pad_num/2))
  endif else begin
    var_text = varname
  endelse

  widget_control,varname_id,set_value=var_text

  vartype_id = widget_info(event.handler,find_by_uname='context_type')
    
  group = self.ld->getGroup(varname)
   
  if ~obj_valid(group) then begin
    child = (self.ld->getObjects(name=varname))[0]
    if ~obj_valid(child) then return
    groupname = child->getgroupname()
    group = self.ld->getGroup(groupname)
    is_child = 1
    type_str='Component'
  endif else begin
    is_child = 0
    type_str='Group'
  endelse
  
  widget_control,vartype_id,set_value='Type: ' + type_str
  
  dim1 = group->getDim1()
  dim2 = n_elements(group->getDataNames())
  
  vartype_id = widget_info(event.handler,find_by_uname='context_dim')
    
  if is_child || dim2 eq 1 then begin
    dim_str = '[ ' + strtrim(dim1,2) + ' ]'
    byte_size = 8.*dim1
  endif else begin
    dim_str = '[ ' + strtrim(dim1,2) + ' X ' + strtrim(dim2,2) + ' ]'
    byte_size = 8.*dim1*dim2
  endelse
  
  widget_control,vartype_id,set_value='Dimensions: ' + dim_str

  varsize_id = widget_info(event.handler,find_by_uname='context_size')
  
  if byte_size lt 1024. then begin
    byte_str = string(byte_size,format='(D0.2)') + ' bytes'
  endif else if byte_size lt 1024.*1024. then begin
    byte_str = string(byte_size/1024.,format='(D0.2)') + ' kilobytes'
  endif else if byte_size lt 1024.*1024.*1024. then begin
    byte_str = string(byte_size/1024./1024.,format='(D0.2)') + ' megabytes'
  endif else begin
    byte_str = string(byte_size/1024./1024./1024.,format='(D0.2)') + ' gigabytes'
  endelse

  widget_control,varsize_id,set_value='Size: ' + byte_str
  
  varcadence_id = widget_info(event.handler,find_by_uname='context_cadence')
  
  cadence = group->getCadence()
  
  if cadence lt 1e-6 then begin
    cadence_str = string(cadence*1e9,format='(D0.2)') + ' nanoseconds'
  endif else if cadence lt 1e-3 then begin
    cadence_str = string(cadence*1e6,format='(D0.2)') + ' microseconds'
  endif else if cadence lt 1. then begin
    cadence_str = string(cadence*1e3,format='(D0.2)') + ' milliseconds'
  endif else if cadence lt 60. then begin
    cadence_str = string(cadence*1e0,format='(D0.2)') + ' seconds'
  endif else if cadence lt 60.*60. then begin
    cadence_str = string(cadence/60.,format='(D0.2)') + ' minutes'
  endif else if cadence lt 60.*60.*24. then begin
    cadence_str = string(cadence/60./60.,format='(D0.2)') + ' hours'
  endif else if cadence lt 60.*60.*24.*365.25 then begin
    cadence_str = string(cadence/60./60./24.,format='(D0.2)') + ' days'
  endif else begin
    cadence_str = string(cadence/60./60./24./365.25,format='(D0.2)') + ' years'
  endelse
  
  widget_control,varcadence_id,set_value='Cadence(Apx.): ' + cadence_str
  
  self.ld->getDataInfo,varname,units=units,coord=coords
  
  varunits_id = widget_info(event.handler,find_by_uname='context_units')

  widget_control,varunits_id,set_value='Units: ' + units
  
  varcoords_id = widget_info(event.handler,find_by_uname='context_coords')

  widget_control,varcoords_id,set_value='Coordinate System: ' + coords

  widget_displaycontextmenu,event.id,event.x,event.y,self.context

end

;private method initializes the right-click context menu for the tree
pro spd_ui_widget_tree::initContextMenu

  compile_opt idl2

  self.context = widget_base(self.id,/context_menu)
 ; container = widget_base(self.context,/col)
  varname = widget_button(self.context,value=strjoin(replicate(' ',self.context_width)),uname='context_name')
  vartype = widget_button(self.context,value='Type: ',uname='context_type')
  vardim = widget_button(self.context,value='Dimensions: ',uname='context_dim')
  varsize = widget_button(self.context,value='Size: ',uname='context_size')
  varcadence = widget_button(self.context,value='Cadence(Apx.): ',uname='context_cadence')
  varunits = widget_button(self.context,value='Units: ',uname='context_units')
  varcoords = widget_button(self.context,value='Coordinate System: ',uname='context_coords')
end


;Private Method: Not to be called by external code
;This is the true object based event handler
;it handles internal events from the compound
;widgets
function spd_ui_widget_tree::handleEvent,event

  compile_opt idl2

  if self.skip_event then begin
    self.skip_event = 0
  ;  print,'skip_off'
    return,0
  endif
  
  if Tag_Names(event,/Structure_Name) EQ 'WIDGET_CONTEXT' then begin
  
    self->handleContextMenuEvent,event
    return,0
  
  endif else if Tag_Names(event, /Structure_Name) EQ 'WIDGET_TREE_EXPAND' then begin

    widget_control,self.root,update=0

    if ~widget_info(event.id,/tree_expanded) then begin;collapse
      self->collapseNode,event.id
    endif else begin ;expand(operation now done dynamically, rather than generating static tree at the time of population
      self->expandNode,event.id
    endelse
    
    ;An intermittent bug occurs if update isn't run twice.  
    ;Testing without, to see if we can avoid 2x updates
    widget_control,self.root,update=1
  ;  widget_control,self.root,update=1
     
    ;fixes bug where select event occurs always with expand event
    ;On windows this problem is solved in calling code, by ignoring
    ;select events or clearing tree selections.
    ; This bug is supposed to be fixed in 8.0 and later releases (aaflores 2013-02-26)
    if strlowcase(!version.os_family) ne 'windows' and float(!version.release) lt 8. then begin
      self.skip_event = 1
      ;print,'skip_on'
    endif

;    return,{SPD_UI_TREE_EXPAND,ID:self.id,TOP:event.top,HANDLER:0L}
    return,0

  endif else if Tag_Names(event,/Structure_Name) eq 'WIDGET_TREE_SEL' then begin

    widget_control,event.id,get_uvalue=str

    if self.leafonly && $
       (self.mode eq 0 || self.mode eq 2) && $
       str.value eq 'INTERIOR' then begin

      widget_control,event.id,set_tree_select=0

    endif else if self.mode eq 1 && $
                  self.leafonly  && $
                  (str.value eq 'INTERIOR' || $
                   str.value eq 'GROUP') then begin

      widget_control,event.id,set_tree_select=0

    endif

    return,{SPD_UI_TREE_EVENT,ID:self.id,TOP:event.top,HANDLER:0L}

  endif

return,0

end

function spd_ui_widget_tree::cleanup

  compile_opt idl2

  Widget_Control,self.id,/Destroy

end


;Private Method: Not to be called by external code
;intializes the widget tree
;parentid:  the id of the parent base that this is part of
;uvalue:  the value that will be called in parent event handler
;loadedData: the loadedData object, used to populate tree
;xsize=xsize: the size of the tree widget area along the x-axis
;ysize=ysize: the size of the tree widget area along the y-axis
;mode=mode: indicates the viewing/selection mode.  See above for
;a description of the modes
;multi=multi: indicates whether multiple selections can be made in the tree(with shift/control click)
;leafonly=leafonly: Set this flag to 1 if you want selections to be allowed
;only on the leaf of the tree
;showdatetime: If this boolean is 1 the date time of a variable will
;             be printed with its name
;selected=selected: Pass in a list of variable names that you would like selected
;from_copy=from_copy: Pass in an old copy of the tree from which expansion state can be copied
function spd_ui_widget_tree::init,$
                           parentid,$
                           uvalue,$
                           loadedData,$
                           uname=uname,$
                           xsize=xsize,$
                           ysize=ysize,$
                           mode=mode,$
                           multi=multi,$
                           selected=selected,$
                           leafonly=leafonly,$
                           showdatetime=showdatetime,$
                           from_copy=copy

  compile_opt idl2

  if ~keyword_set(parentid) then begin
    ok = error_message('Need required argument: parentID',/traceback)
    return,0
  endif

  if ~keyword_set(uvalue) then begin
    ok = error_message('Need required argument: uvalue',/traceback)
    return,0
  endif

  if ~keyword_set(uvalue) || ~obj_valid(loadedData) then begin
    ok = error_message('Need required argument: loadedData',/traceback)
    return,0
  endif

  if ~keyword_set(uname) then begin
    uname = ''
  endif

  if ~keyword_set(xsize) then begin
    xsize = 300
  endif

  if ~keyword_set(ysize) then begin
    ysize = 300
  endif

  if ~is_num(mode) then begin
    mode = 0
  endif

  if ~is_num(multi) then begin
    multi = 1
  endif

  if ~keyword_set(leafonly) then begin
    leafonly = 0
  endif

  if ~keyword_set(showdatetime) then begin
    showdatetime = 0
  endif

  self.context_width = 40
  self.parent = parentid
  self.uvalue = uvalue
  self.ld = loadedData
  self.uname = uname
  self.xsize = xsize
  self.ysize = ysize
  self.mode = mode
  self.multi = multi
  self.leafonly = leafonly
  self.showdatetime = showdatetime
  self.nodemap = bytarr(16,16,3)
  self.nodemap[*] = 196
  self.nodemap[indgen(8)*2,7,*] = 0
  self.leafmap = self.nodemap
  self.nodemap[7:11,5:9,*] = 0
  self.nodemap[[7,7,11,11],[5,9,5,9],*] = 196
  ;self.bitmap[9,indgen(8)*2,*] = 0

  self.id = widget_base(self.parent, $
                uvalue=uvalue, $
                uname=uname, $
                event_func='spd_ui_widget_tree_event',$
                func_get_value='spd_ui_widget_tree_get_value',/context_events)

  self.stash = widget_base(self.id,uvalue=self)
  
  widget_control,self.id,update=0

  if keyword_set(copy) && widget_valid(copy) then begin
    copy_root = widget_info(copy,/child)
    oldtree = widget_info(copy_root,/child)
  endif else begin
    oldtree = self.root
  endelse

  self->populateTree,oldtree
 
  if oldtree eq 0 then begin
    oldtree = self.root
  endif
 
  self->copyexpansion,oldtree,self.root
  
  if keyword_set(selected) && is_string(selected[0]) then begin

    self->setSelected,self.root,selected

  endif

  self->initContextMenu

  widget_control,self.id,update=1

  return,1

end

;Private Function: Not to be called by external code
;the event handler for the widget tree
;this is not a method of the widget object
;but it works as a means to create object-based compound widgets
;NOTE: this routine should only be called internally,
;it should not be called by the end-user.
function spd_ui_widget_tree_event,event

  compile_opt hidden,idl2

  store = widget_info(event.handler,/child)
  widget_control,store,get_uvalue=obj

  return,obj->handleEvent(event)

end

;Private Function: Not to be called by external code
;the getvalue function for the widget tree
;this is not a method of the widget object
;but it works as a means to create object-based compound widgets
;It is not as important as the event_handler callback,
;but it allows a user to easily query the widget value without
;needing to unpack the state(ie you can use widget_control,id,get_value=gv)
;NOTE: this routine should only be called internally,
;it should not be called by the end-user.
function spd_ui_widget_tree_get_value,id

 COMPILE_OPT hidden,idl2

  ; Recover the state of this compound widget
  stash = WIDGET_INFO(id, /CHILD)
  WIDGET_CONTROL, stash, GET_UVALUE=state

  return,state

end

pro spd_ui_widget_tree__define

  compile_opt idl2

  struct = { SPD_UI_WIDGET_TREE,     $
              parent: 0,             $ ; id for the parent widget (must be a base)
              id: 0,                 $ ; widget id for the tree widget
              stash:0,               $ ; widget id for the tree widget stash widget
              context:0,             $ ; widget id for the context menu widget
              context_width:40,      $ ; width of context menu in characters
              root:0,                $ ; widget id for the tree widget root
              uvalue: '',            $ ; the user value to be called in parent event handler
              uname:'',              $ ; the name of the widget, can be used with find_by_name call to widget_info
              xSize: 0,              $ ; size of tree area in x direction
              ySize: 0,              $ ; size of tree area in y direction
              mode:0,                $ ; Indicates the viewing/selection mode for the data
              multi:0,               $ ; 0 means one selection only, 1 means multiple selections allowed
              leafonly:0,            $ ; 0 means selections can be made anywhere in the tree, 1 means only leaves may be selected
              showdatetime:0B,       $ ; if this boolean is 1 then the start/stop times of variables will be printed out with their names.
              nodemap:bytarr(16,16,3),$ ; the bitmap that is used as the tree icon for interior nodes
              leafmap:bytarr(16,16,3),$ ; the bitmap that is used as the tree icon for interior nodes
              ld:obj_new(),           $ ; the loaded data object
              skip_event:0B           $ ; set this flag to make the handler skip the next event

}

end
