;+
;
;spd_ui_draw_object method: addAxisLabels
;
;This routine performs some of the tricky logic 
;necessary to figure out how to place the axis labels
;
;model: the output model
;labels: IDL_Container storing labels
;margin: margin between axis & labels
;placeLabel: whether to place label on top/bottom left/right (changed from placeAnnotation to allow axis numbering on different side to labels)
;dir: x/y axis flag (x=0,y=1)
;orientation: horizontal/vertical text flag (h=0,v=1)
;stackLabels: stacklabels or rowlabels flag
;lazyLabels: convert underscores to carriage returns and override stacking
;pt1: multiplicand to change pt into view normalized coords(perp axis)
;pt2: multiplicand to change pt into view normalized coords(par axis)
;labelpos: returns the position of the most distant label from the axis
;blacklabels: indicates that default settings should be over-ridden to make all labels black
;
;$LastChangedBy: egrimes $
;$LastChangedDate: 2014-06-02 14:46:56 -0700 (Mon, 02 Jun 2014) $
;$LastChangedRevision: 15286 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas_gui/display/draw_object/spd_ui_draw_object__addaxislabels.pro $
;-
pro spd_ui_draw_object::addAxisLabels,model,labels,margin,placeLabel,dir,orientation,stacklabels,showlabels,pt1,pt2,lazylabels,blacklabels,labelPos=labelPos

  compile_opt idl2,hidden
  
  ;not completely sure about what z-values
  ;each component will need, so I set it at
  ;the top
  zstack = .1
  
  labelpos = 0
  
  ;validate input
  if ~showlabels || ~obj_valid(labels) || ~obj_isa(labels,'IDL_Container') then return
  
  objs = labels->get(/all)
  
  if ~obj_valid(objs[0]) then return
  
  ;This switch simplifies the code significantly by
  ;making the x/y axis code symmetrical.
  ;Think of orient as indicating whether the text is
  ;oriented parallel (0) or perpedicular (1) to the axis
  if dir eq 1 then begin
    orient = ~orientation
  endif else begin
    orient = orientation
  endelse
  
  ;the baseline & updir options are used by
  ;IDL to determine text orientation in 3-d space
  ;(although we are only looking at a planar subset
  if orientation eq 0 then begin
    baseline = [1,0,0]
    updir = [0,1,0]
  endif else begin
    baseline = [0,1,0]
    updir = [-1,0,0]
  endelse
  
  ;logic to control label alignment
  ;ie top/bottom/left/right justify
  ; orientation = 0 --> vertical
  ; orientation = 1 --> horizontal
  if orient eq 0 then begin
    if stacklabels eq 0 then begin
      halign = .5
      valign = dir eq 1 ? placeLabel:~placeLabel
    endif else begin
      halign = 0.5
      valign = ~placeLabel
    endelse
  endif else begin
    if stacklabels eq 0 then begin
      valign = .5
      halign = ~placelabel
    endif else begin
      valign = 1.0
      halign = ~placelabel
    endelse
  endelse

  len = 0D
  
  n = n_elements(objs)
  
  ;get the length of the labels as a block so that the
  ;labels can be positioned properly
  ;we loop over labels and sum their sizes or lengths. Which depends on stacking & orientation.
  for i = 0,n-1 do begin
  
    objs[i]->getProperty,value=value,size=size,show=show
    
    if ~show then continue
    
    ;account for underscores being converted to carriage returns
    if keyword_set(lazylabels) and stregex(value,'[_]', /bool) then begin
      value = strsplit(value,'_',/extract)
    endif
    
    size += 1
    
    ;get length depending on orientation
    if orient eq 0 then begin ;parallel to axis
      if stacklabels eq 0 then begin
        len += max(strlen(value))*pt2*size
      endif else begin
        len += pt1*size*n_elements(value)
      endelse
    endif else begin ;perpendicular
      if stacklabels eq 0 then begin
        len += max(strlen(value))*pt1*size
      endif else begin
        len += max(strlen(value))*pt2*size
      endelse
    endelse
  ;need to correct to account for varying orientations/pt1/pt2
    
  endfor
  
  pos = 0D
  
  ;Now loop over label objects and actually generate the output IDLgrText
  ;for each label in the block
  for i = 0, n-1 do begin
  
    tFont = objs[i]->getGrFont()
    
    objs[i]->getProperty,color=color,value=value,show=show,size=size
    
    if size le 0 then begin
      self.statusBar->update,'Label "' + value + '" had illegal size. Skipping...'
      self.historyWin->update,'Label "' + value + '" had illegal size. Skipping...'
      continue
    endif
    
    if ~show then continue
    
    ;account for underscores being converted to carriage returns
    if keyword_set(lazylabels) and stregex(value,'[_]', /bool) then begin
      value = strsplit(value,'_',/extract)
    endif
    
    tFont->setProperty,size=size*self->getZoom()
    
    size +=1
    
    ;this code calculates position for labels of different locations/orientations
    ;It allows for the fonts of labels to be different
    if stackLabels eq 0 then begin
      if orient eq 0 then begin
        loc1 = (size*max(strlen(value)))/(len/pt2*2D) + pos
        loc2 = -(margin*pt1+size*pt1/2D)
        pos += double(size*max(strlen(value)))/double(len/pt2)
      endif else begin
        loc1 = .5D
        loc2 = -(margin*pt1+pos)
        pos += size*max(strlen(value))*pt1
      endelse
    endif else begin
    
      if orient eq 0 then begin
        loc1 = .5D
        loc2 = -(margin*pt1+pos);-(margin*pt1+pos+size*pt1/2D)
        pos += pt1*(size)*n_elements(value)
      endif else begin
        loc1 = (size*max(strlen(value)))/(len/pt1*2D) + pos
        loc2 = -(margin*pt1+size*pt1/2D)
        pos += double(size*max(strlen(value)))/double(len/pt2)
      endelse
      
      if dir eq 1 then begin
        if orient eq 1 then begin
          loc1 = 1. - loc1
        endif else begin
          loc2 = -loc2 - len - 2*(pt1*margin)
        endelse
      endif
    endelse

    if placelabel eq 1 then begin
      loc2 = 1 - loc2
    endif
    
    if dir eq 1 then begin
      loc = [loc2,loc1,zstack]
      labelPos = loc1
    endif else begin
      loc = [loc1,loc2,zstack]
      labelPos = loc2
    endelse

    if keyword_set(blacklabels) then begin
      color = [0,0,0]
    endif 
   
    grText = obj_new('IDLgrText', $
      ;add carriage returns if necessary
      keyword_set(lazylabels) ? strjoin(value,'!c'):value, $ 
      font=tFont,$
      color=self->convertColor(color),$
      hide=~show,$
      location=loc,$
      alignment=hAlign,$
      vertical_alignment=valign,$
      baseline=baseline,$
      recompute_dimensions=0,$
      enable_formatting=1, $
      updir=updir)
      
    model->add,grText
    
  end
  
end
