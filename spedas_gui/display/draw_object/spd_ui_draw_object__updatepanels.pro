;+
;spd_ui_draw_object method: updatePanels
;
;draws the panels for this window.
;This routine is the workhorse of the draw object,
;
;Inputs:
;  Layout Dims(2-elements long):  The number of rows and columns in the layout(from the spd_ui_window)
;  Margins(6-elements double):  The size of the margins for the panel in points. Elements are as follows
;                               [left,right,top,bottom,horizontal_internal,vertical_internal]
;  PanelObjs(array of objects):  Array of references to the spd_ui_panel objects being drawn
;  LoadedData(object): Reference to the spd_ui_loaded_data object in which the data to be plotted is stored
;  Backgroundcolor(3-element Byte array):  The color of the background, needed to emulate some transparency effects.
;  Locked(long index):  The locked value from the window object.  -1 is unlocked, otherwise it is the index
;                       of the panel to which others are locked.  Index in terms of the list of panelObjs
;  Window(object):  The active window from which the drawn panels originate. Needed to query layout information.
;  
;  
;Outputs:
;  returns 1 on success, 0 on failure
;  errmsg: a struct describing an error that has occurred, to be passed up to calling routine. 
;    The existance of errmsg does not guarantee updatePanels returns 0 and vice versa.
;    Currently updatepanels itself does not set errmsg, it is simply passed on through here to other routines
;    (presently only getRange and makeView).
;    See spd_ui_draw_object_update for more details.
;  
;Mutates:
;  self.panelViews,self.staticViews,self.dynamicViews,self.panelInfo
;  
;NOTE:  The order in which various elements of the panel are added to the display is IMPORTANT
;If you change the ordering be sure to check that this change hasn't oscured some
;important feature.
;
;$LastChangedBy: aaflores $
;$LastChangedDate: 2014-06-11 15:56:35 -0700 (Wed, 11 Jun 2014) $
;$LastChangedRevision: 15353 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas_gui/display/draw_object/spd_ui_draw_object__updatepanels.pro $
;-


function spd_ui_draw_object::updatePanels,layoutDims,margins,panelObjs,loadedData,backgroundcolor,locked,window, errmsg=errmsg

  compile_opt idl2,hidden

  systm = systime(/seconds)
  
  ;This factor determines the distance the panel title is placed from the panel proper
  panelTitleVposFactor = .1
  
  dataXptr = ptr_new()
  dataYptr = ptr_new()
  dataZptr = ptr_new()
  
  ;Normalize the margin values to draw area
  marginsNorm = [self->pt2norm(margins[0],0),$ ;left
    self->pt2norm(margins[1],0),$ ;right
    self->pt2norm(margins[2],1),$ ;top
    self->pt2norm(margins[3],1),$ ;bottom
    self->pt2norm(margins[4],0),$ ;internal margin x
    self->pt2norm(margins[5],1)]  ;internal margin y
    
  
  ;these structures serve as a quick reference for performing fast graphical operations
  legendInfoStruct = { $
    notationSet:0, $
    timeFormat:6, $
    numFormat:5, $
    xIsTime:0, $
    yIsTime:0, $
    zIsTime:0 $
  }
  
  panelInfoStruct = {xplotpos:[0D,1D],$ ;position of the plot
    yplotpos:[0D,1D],$
    margins:dblarr(5),$ ; size of edge components.  Used for identifying location of click in panel [left,right,top,bottom,vars]
    locked:0,$
    lockedRange:[0D,1D],$ ; alternative range to use for plot scaling, in the event of locked panels
    lockedScale:0,$; alternative scaling to use
    xrange:[0D,1D],$  ;data range of the plot
    yrange:[0D,1D],$
    zrange:[0D,1D],$
    xmajorSize:0D,$ ;size of a major tick in converted data space(log applied if logarithimic)
    ymajorSize:0D,$
    xscale:0,$ ;indicates log or normal scaling
    yscale:0,$
    xcenter:0d, $
    ycenter:0d, $
    lockedcenter:0d, $
    xmajorNum:0,$ ; the number of major ticks on the x-axis
    ymajorNum:0,$ ; the number of major ticks on the y-axis
    zmajorNum:0,$ ; the number of major ticks on the z-axis
    xminorNum:0,$ ; the number of minor ticks on the x-axis
    yminorNum:0,$ ; the number of minor ticks on the y-axis
    zminorNum:0,$ ; the number of minor ticks on the z-axis
    xisTime:0,$ ;indicates whether the axis is time
    yisTime:0,$
    hasSpec:0,$ ;boolean, indicates whether a spectrogram is present
    hasLine:0,$ ;boolean, indicates whether a line is present
    zscale:0,$ ;indicates log/lin scaling for z axis
    zisTime:0,$ ;indicates whether the z axis is a time(I'm not sure a z time axis is possible)
    zplacement:4,$ ;0:top,1:bottom,2:left,3:right,4:no zaxis
    markerIdx:-1,$ ; indicates the index the highlighted marker(if any) on this panel
    traceInfo:ptr_new(),$ ;ptr to array of info for each trace
    varInfo:ptr_new(),$ ; ptr to array of variable info
    markerInfo:ptr_new(),$ ; ptr to array of marker info
    vBar:obj_new(),$ ;ptr to vertical bar model
    hBar:obj_new(),$ ;ptr to horizontal bar model
    marker:obj_new(),$ ;ptr to currently drawing marker model
    annotation:obj_new(),$ ;ptr to annotation view
    view:obj_new(),$ ;ptr to main view
    xobj:obj_new(),$ ;ptr to independent variable 1 legend text object
    yobj:obj_new(),$ ;ptr to independent variable 2 legend text object
    legendModel:obj_new(), $ ;the model in which the legend is stored
    legendAnnoModel:obj_new(), $ ; the model in which the legend annotations are stored
    dxptr:[ptr_new(0),ptr_new(0)],$ ; storing the valid data x-range
    legendInfo:ptr_new(legendInfoStruct) $ ; pointer to the legend structure defined above
    }
    
  traceInfoStruct = { $
    isSpec:0,$
    ;                     dataX:ptr_new(),$
    ;                     dataY:ptr_new(),$
    ;                     dataZ:ptr_new(),$
    refData:ptr_new(),$
    abcissa:ptr_new(),$
    plotData:ptr_new(), $ ;pointer to a struct in which some information is passed internally. 
    dataName:'',$
    color:[0,0,0],$
    textObj:obj_new() $   ;text object that displays dependent variable text output
    }
    
  varInfoStruct = { $
    dataX:ptr_new(),$ ;ptr to the x data quantity(note that this is normalized data, not real data)
    dataY:ptr_new(),$ ; ptr to the y data quantity
    textObj:obj_new(),$ ; ptr to the text object to be updated during tracking
    isTime:0B, $ ; indicates whether the data y is a time
    annotateStyle:0, $ ; the annotation style for the output
    scaling:0, $ ;0=linear,1=log10,2=log
    range:[0D,1D] $
    }
    
  markerInfoStruct = { $
    pos:[0D,1D], $ ;the x-start & x-stop of the marker in normalized panel coordinates
    color:[0B,0B,0B], $ ; the original color of the frame
    frames:[obj_new(),obj_new()], $ ;the IDLgrPolyline objects for the left and right sides of the marker frame
    selected:0, $  ;indicates whether marker is selected
    displayed:0 $  ;indicates whether the marker is displayed at this level of zoom
    }
   
  
  lockedIsTime = -1
    
  panelInfoArray = replicate(panelInfoStruct,n_elements(panelObjs))
  
  ;Gets the variable size of all the variables in the layout
  ;Note this has a problem, because it doesn't account for panels in separate columns
  ;It should get the height of all the variables in a column.
  self->getRowTextSizes, panelObjs, top_sizes=top_sizes, bottom_sizes=bottom_sizes
  bottom_sizes = self->pt2norm(bottom_sizes,1)
  top_sizes = self->pt2norm(top_sizes,1)
  
  ;Do not alter panel layout to account for panel titles unless panels are locked.
  ;  -This is partly for consistency as no other annotations are accounted for
  ;   (sans variables), but also to prioritize data space over annotation space.
  if locked eq -1 then top_sizes[*] = 0.
  
  ;calculate the range of the locked panel
  ;so that we can use it on other panels
  if locked ne -1 then begin
  
    if locked ge n_elements(panelObjs) then begin
      self.historyWin->update,'Warning: Locked value requests locking to nonexistent panel'
      self.statusBar->update,'Warning: Locked value requests locking to nonexistent panel'
    endif else begin
      currentPanel = panelObjs[locked]
      currentPanel->getProperty,traceSettings=traceSettings,xAxis=xAxis,yAxis=yAxis,zAxis=zAxis
  
      ;reverse the order of trace processing so that spectrograms layer correctly
      traces = reverse(traceSettings->get(/all))
      
      ;extract and process data
      if obj_valid(traces[0]) then begin
      
        yaxis->getProperty,scaling=yscale
        
        ;Removes copies of data from draw object,
        ;Performs some basic formatting.
        ;Generate mirror data if needed
        self->collatedata,traces,loadedData,yscale=yscale,outXptrs=dataXptr,outYptrs=dataYptr,outZptrs=dataZptr,mirror=mirrorptr,fail=fail,dataNames=dataNames,dataidx=dataidx
        
        if fail then begin
          self.historyWin->update,'Failed to read data for locking master panel'
          return,0
        endif
        
        if dataidx[0] ne -1 then begin
        
          ;some data quantities may turn out invalid, so we remove those
          traces = traces[dataidx]
          dataXptr = dataXptr[dataidx]
          dataYptr = dataYptr[dataidx]
          dataZptr = dataZptr[dataidx]
          mirrorptr = mirrorptr[dataidx]
          datanames = datanames[dataidx]
          
          ;get plot range       
          self->getRange,dataXptr,xAxis,range=lockedRange,scaling=lockedScale,istime=lockedIsTime,fail=fail,center=lockedcenter, errmsg=errmsg,isspec=obj_valid(zAxis)
          
          if fail then begin
            self.historyWin->update,'No range on locking master panel.'
            return,0
          endif else begin
            ptr_free,dataXptr,dataYptr,dataZptr,mirrorPtr
          endelse
          
         endif else begin
           self.historyWin->update,'No valid data on locking master panel.'
           lockedRange = [0D,1D]
           lockedScale = 0
           lockedcenter = 0.5
         endelse
       endif else begin
         self.historyWin->update,'No valid traces on locking master panel'
         lockedRange = [0D,1D]
         lockedScale = 0
         lockedcenter = 0.5
       endelse
    endelse
  endif
  

  ;This is the big loop in this function,
  ;It loops over all the panelObjects
  for i = 0,n_elements(panelObjs) - 1 do begin
    
    ;print,"panel:",i,systime(/seconds)-systm
    
    currentPanel = panelObjs[i]
   
    ;Modify settings to reflect locked expectations.
    ;This will override some user settings
    if locked ne -1 then begin
    
      ;The window tells us where the panel is within the layout
      ;I suspect this can be fooled by irregular layouts
      panelLayoutPos = window->getPanelPos(currentPanel)
      
      if panelLayoutPos eq -1 then begin
        self.historyWin->update,'Problem evaluating locked panel layout'
        self.statusBar->update,'Problem evaluating locked panel layout'
        return,0
      endif else if panelLayoutPos eq 1 then begin
        self->lockBottom,currentPanel
      endif else if panelLayoutPos eq 2 then begin
        self->lockMiddle,currentPanel
      endif else if panelLayoutPos eq 3 then begin
        self->lockTop,currentPanel
      endif ;doesn't modify a panel that is only in column
    
    end
  
    currentPanel->getProperty,settings=settings,markers=markerContainer, $
      variables=variableContainer,showvariables=showvariables,legendSettings=legendSettings
    
     panelInfoArray[i].legendInfo = ptr_new(legendSettings)

    
    settings->getProperty,row=row,col=col,rSpan=rSpan,cSpan=cSpan, $
      backgroundcolor=color,titleobj=titleobj,framecolor=framecolor, $
      framethick=framethick,titleMargin=titleMargin
      
    layoutPos = [row,col,rSpan,cSpan]
    
    ;Coordinates of the panel in points.
    pcoord = currentPanel->getPanelCoordinates()
    
    ;normalize coordinates
    pcoord = [(pcoord[0] ne -1)?self->pt2norm(pcoord[0],0):-1,$
      (pcoord[1] ne -1)?self->pt2norm(pcoord[1],1):-1,$
      (pcoord[2] ne -1)?self->pt2norm(pcoord[2],0):-1,$
      (pcoord[3] ne -1)?self->pt2norm(pcoord[3],1):-1]
      
    ;Pull any markers out of IDL_Container
    markerNum = 0
    if obj_valid(markerContainer) && obj_isa(markerContainer,'IDL_Container') then begin
      markerList = markerContainer->get(/all)
      
      if obj_valid(markerList[0]) then begin
        markerNum = n_elements(markerList)
        markerInfo = replicate(markerInfoStruct,markerNum)
      endif
    endif
    
    varNum = 0
    ;showvariables = 1
    
    ;Pull any variables out of IDL_Container
    if obj_valid(variableContainer) && $
      obj_isa(variableContainer,'IDL_Container') && $
      showvariables then begin
      varList = variableContainer->get(/all)
      
      if obj_valid(varList[0]) then begin
        varNum = n_elements(varList)
        varInfo = replicate(varInfoStruct,varNum)
        panelInfoArray[i].varInfo = ptr_new(varInfo)
      endif
    endif
        
    ;The next call returns all the different views used for different parts of the panels
    ;I'd very much like to create the returned views by calling this routine each time I need a view,(rather than returning multiple identical items from 1 call)
    ;but for some reason the transparency doesn't work if I do that.  It seems very odd, although maybe I'm missing something obvious.
    ;(like mutating an input so that the second call produces differing results)
    self->makeView,$
      layoutDims,$
      marginsNorm,$
      layoutPos,$
      pcoord,$
      markernum,$
      bottom_sizes,$
      top_sizes,$
      view=view,$
      annotation=annotation,$
      markers=markerviews,$
      xplotPos=xplotPos,$
      yplotpos=yplotpos,$
      outmargins=outmargins,$
      fail=fail,$
      errmsg=errmsg
             
    if fail then return,0
     
    panelInfoArray[i].annotation=annotation
    panelInfoArray[i].view=view
    panelInfoArray[i].margins=outmargins
    
    ;This should be fixed, mutation will not have any outward effect. 
    ;It should
    newsize = self->getpanelsize(xplotpos,yplotpos)
    currentPanel->setPanelCoordinates,newsize
    
    ;add views to graphics tree
    self.panelViews->add,view
    self.panelViews->add,annotation
    
    ;add static components to the list of static views
    self.staticViews->add,view
    ;add animated components to the list of dynamic views
    self.dynamicViews->add,annotation
    
    ;title
    
    if obj_valid(titleobj) then begin
    
      grTitleObj = self->getTextObject(titleobj,[.5,self->pt2norm(titleMargin,1)/(yplotpos[1]-yplotPos[0])+1.,.5],1,0)
      
      grTitle = obj_new('IDLgrModel')
      
      grTitle->add,grTitleObj
      
      view->add,grTitle
      
    endif
    
    ;get data quantities
    
    currentPanel->getProperty,traceSettings=traceSettings,xAxis=xAxis,yAxis=yAxis,zAxis=zAxis
    
    ;reverse the order of trace processing so that spectrograms layer correctly
    traces = reverse(traceSettings->get(/all))
    
    ;extract and process data
    if obj_valid(traces[0]) then begin
    
      yaxis->getProperty,scaling=yscale
      
      self->collateData,traces,loadedData,yscale=yscale,outXptrs=dataXptr,outYptrs=dataYptr,outZptrs=dataZptr,mirror=mirrorptr,fail=fail,dataNames=dataNames,dataidx=dataidx
      
      if fail then return,0
      
      if dataidx[0] ne -1 then begin
      
        ;some data quantities may turn out invalid, so we remove those
;        traces = traces[dataidx]
;        dataXptr = dataXptr[dataidx]
;        dataYptr = dataYptr[dataidx]
;        dataZptr = dataZptr[dataidx]
;        mirrorptr = mirrorptr[dataidx]
;        datanames = datanames[dataidx]
        
        ;get plot x range
        
        self->getRange,dataXptr,xAxis,scaling=xscaling,range=xrange,fail=fail,center=lockedCenter,errmsg=errmsg,isSpec=obj_valid(zAxis)
        
        dataRange = *dataXptr[0]

        ;translate the range into the scaling used by this trace
        if size(lockedRange,/type) then begin
        
          panelInfoArray[i].locked = 1
          panelInfoArray[i].lockedRange = lockedRange
          panelInfoArray[i].lockedScale = lockedScale
          if ~undefined(lockedCenter) then panelInfoArray[i].xcenter= lockedCenter
        
          currentRange = lockedRange
          currentScale = lockedScale
        
        endif else begin
          currentRange = xrange
          currentScale = xscaling
        endelse
        
        
        ;The large block of nested if-statements below
        ;performs all the data processing tasks to prepare
        ;the data for plotting and in the event of a failure,
        ;to properly set the remaining values in such a way
        ;that it fails gracefully 
        
        if fail then begin
        
          traceInfoArray = 0
          xrange = [0D,1D]
          if size(lockedRange,/type) then begin
            currentRange=lockedRange
            currentScale = lockedScale
          endif else begin
            currentRange = [0D,1D]
            currentScale = 0
          endelse
          yrange = [0D,1D]
          yscale = 0
          zrange = [0D,1D]
          traces = 0
          zscaling = 0
          
        endif else begin
        
          panelInfoArray[i].xrange=xrange
          panelInfoArray[i].xscale=xscaling
          if ~undefined(lockedCenter) then panelinfoarray[i].xcenter=lockedCenter
          
          ;clip the data with respect to x-axis
          self->xclip,dataXptr,dataYptr,dataZptr,currentRange,currentScale,fail=fail,mirrorptr=mirrorptr
          
          ;   spd_ui_xyclip,dataXptr,dataYptr,dataZptr,xrange,xscaling,fail=fail,transposez=0,mirrorptr=mirrorptr
          
          if fail then begin
          
            traceInfoArray = 0
            yrange = [0D,1D]
            yscale = 0
            zrange = [0D,1D]
            traces = 0
            zscaling  = 0
            
          endif else begin
          
            ;get plot y range

            self->getRange,dataYptr,yAxis,scaling=yscaling,mirror=mirrorptr,range=yrange,fail=fail,center=ycenter, errmsg=errmsg,isspec=obj_valid(zAxis)

            
            if fail then begin
            
              traceInfoArray = 0
              traces = 0
              yrange = [0D,1D]
              zrange = [0D,1D]
              zscaling = 0
              
            endif else begin
            
              panelInfoArray[i].yrange=yrange
              panelInfoArray[i].yscale=yscaling
              if ~undefined(yCenter) then panelinfoarray[i].ycenter=ycenter
              
              ;clip with respect to y axis
              self->yclip,dataXptr,dataYptr,dataZptr,yrange,yscaling,fail=fail,mirrorptr=mirrorptr
          
              
              ; spd_ui_xyclip,dataYptr,dataXptr,dataZptr,yrange,yscaling,fail=fail,transposez=1,yaxis=1,mirrorptr=mirrorptr
              ;spd_ui_xyclip,mirrorptr,dataXptr,dataZptr,yrange,yscaling,fail=fail,transposez=1,keepnans=1
              
              if fail then begin
                traceInfoArray = 0
                traces = 0
                zrange = [0D,1D]
                zscaling = 0
              endif else begin
              
                ;print,"gotxy range",systime(/seconds)-systm
              
                if obj_valid(zAxis) then begin
                
                  ; panelInfoArray[i].hasSpec = 1
                
                  ;get plot z range
                  self->getZRange,dataZptr,zAxis,range=zrange,scaling=zscaling,fixed=zFixed,fail=fail
                 
                  if fail then begin
                    traceInfoArray = 0
                    traces = 0
                    zrange = [0D,1D]
                    zscaling = 0
                  endif else begin
                  
                    panelInfoArray[i].zscale=zscaling
                    panelInfoArray[i].zrange=zrange
                    
                  ;  self->zclip
                    
                    ;clip with respect to z-axis
                    spd_ui_xyzclip,dataZptr,zrange,zscaling,fail=fail
                    
                    if fail then begin
                      traceInfoArray = 0
                      traces = 0
                    endif
                  endelse
                  
                  traceInfoArray = replicate(traceInfoStruct,n_elements(traces))
                  
                  ; traceInfoArray[*].isSpec = 1
                  ;        traceInfoArray[*].dataX = dataXptr
                  ;        traceInfoArray[*].dataY = dataYptr
                  ;        traceInfoArray[*].dataZ = dataZptr
                  if obj_valid(traces[0]) then begin
                    ;set the list of names on each trace
                    traceInfoArray[*].dataName = dataNames
                  endif
                  
                endif else begin
                
                  zrange = [0D,1D]
                  zscaling = 0
                
                  traceInfoArray = replicate(traceInfoStruct,n_elements(traces))
                  
                  ; traceInfoArray[*].isSpec = 0
                  ;        traceInfoArray[*].dataX = dataXptr
                  ;        traceInfoArray[*].dataY = dataYptr
                  ;        traceInfoArray[*].dataZ = dataZptr
                  if obj_valid(traces[0]) then begin
                    traceInfoArray[*].dataName = dataNames
                  endif
                endelse
              endelse
            endelse
          endelse
        endelse
        
      endif else begin
        traceInfoArray = 0
        if size(lockedRange,/type) then begin
          currentRange=lockedRange
          currentScale = lockedScale
        endif else begin
          currentRange = [0D,1D]
          currentScale = 0
        endelse
        yrange = [0D,1D]
        yscale = 0
        zrange = [0D,1D]
        traces = 0
        zscaling = 0
      endelse
      
    ;print,"got zrange",systime(/seconds)-systm
      
    endif else begin
      traceInfoArray = 0
      if size(lockedRange,/type) then begin
        currentRange=lockedRange
        currentScale = lockedScale
      endif else begin
        currentRange = [0D,1D]
        currentScale = 0
      endelse
      yrange = [0D,1D]
      yscale = 0
      zrange = [0D,1D]
    endelse
    
    ;draw permanent markers
    if markerNum gt 0 then begin
      zstack = .21 + .0001
      for j = 0,n_elements(markerList)-1 do begin
      
        self->addMarker,markerviews[j],markerList[j],currentrange,zstack,fail=fail,markerpos=markerpos,markerframes=markerframes,markercolor=markercolor,markerSelected=markerSelected
        
        if ~fail then begin
        
          ;set all the information needed for operations that occur between updates
          zstack += .0001
          self.panelViews->add,markerviews[j]
          markerInfo[j].pos = markerpos
          markerInfo[j].frames = markerFrames
          markerInfo[j].color = markercolor
          markerInfo[j].displayed = 1
          markerInfo[j].selected = markerSelected
          ;adding marker view to dynamic view list
          self.dynamicViews->add,markerViews[j]
          
        endif else begin
          markerInfo[j].displayed = 0
          obj_destroy,markerviews[j]
        endelse
        
      endfor
      panelInfoArray[i].markerInfo = ptr_new(markerInfo)
      
    endif
    
    ;make axes
    
    ;DEFSYSV,'!VIEW',view
    
    ;This creates all models associated with the x axis
    self->makeXYaxisModel, $
                      0,$
                      currentrange,$
                      yrange,$
                      currentScale,$
                      xAxis,$
                      yplotpos,$
                      xplotpos,$
                      framecolor,$
                      framethick,$
                      backgroundcolor,$
                      useIsTime=lockedIsTime,$                 
                      model=xAxisModel,$
                      gridmodel=gridmodelx,$
                      majors=xAxisMajors,$
                      minorNum=xMinorNum,$
                      isTimeAxis=xistime,$
                      labelpos=labelpos,$
                      fail=fail
    
    if fail then return,0
    
    ;This creates all models associated with the y axis
    self->makeXYaxisModel, $
                      1,$
                      currentrange,$
                      yrange,$
                      yscale,$
                      yAxis,$
                      xplotpos,$
                      yplotpos,$
                      framecolor,$
                      framethick,$
                      backgroundcolor,$      
                      model=yAxisModel,$
                      gridmodel=gridmodely,$
                      majors=yAxisMajors,$
                      minorNum=yMinorNum,$
                      isTimeAxis=yistime,$
                      fail=fail
    
    if fail then return,0
    
    ;Some processing on these major variables.
    ;They will be stored for return to the
    ;calling routine via getPanelInfo
    
    if n_elements(xAxisMajors) lt 2 then begin
      ;if x axis majors are not set, use the x-range
      xMajorSize = currentrange[1]-currentrange[0]
      xMajorNum = 0
    endif else begin
      ;this rescales the x-majors into data space.  
      xMajorSize = (currentRange[1]-currentRange[0])*median(xAxisMajors[1:n_elements(xAxisMajors)-1]-xAxisMajors[0:n_elements(xAxisMajors)-2])
      xMajorNum = n_elements(xAxisMajors)-2
    endelse
    
    if n_elements(yAxisMajors) lt 2 then begin
      ;if y axis majors are not set, use the y-range
      yMajorSize = yrange[1]-yrange[0]
      yMajorNum = 0
    endif else begin
      ;this rescales the y-majors into data space.  
      yMajorSize = (yrange[1]-yrange[0])*median(yAxisMajors[1:n_elements(yAxisMajors)-1]-yAxisMajors[0:n_elements(yAxisMajors)-2])
      yMajorNum = n_elements(yAxisMajors)-2
    endelse
    
    
    ;Storing information about major ticks for output
    panelInfoArray[i].xmajorsize=xmajorsize
    panelInfoArray[i].ymajorsize=ymajorsize
    
    panelInfoArray[i].xmajornum=xmajornum
    panelInfoArray[i].ymajornum=ymajornum
    
    panelInfoArray[i].xminornum=xminornum
    panelInfoArray[i].yminornum=yminornum
    
    panelInfoArray[i].xistime=xistime
    panelInfoArray[i].yistime=yistime
    
    ;If we have a z-axis object
    if obj_valid(zAxis) then begin
    
      ;Get the z-axis color palette number( number corresponds to rainbow, hot-cold, spedas, etc...not in that order)
      zaxis->getProperty,colorTable=paletteNum
  
      ;The actual z-range of autoscaled data may actually decrease during the clipping that occurs during rendering
      ;This variable is used as part of a fix that rescales at the last minute to increase dynamic range.  In other words,
      ;if the plot is zoomed, data that is not on screen could make the z-range wider than it would be if not for this fix. 
      if ~keyword_set(zfixed) then begin
        zRangeRecalc = [!VALUES.D_NAN,!VALUES.D_NAN]
      endif
    endif
    
    ;If we have any valid traces
    ;this block will generate models representing the 
    ;data itself
    if obj_valid(traces[0]) then begin
    
      ;Calculate the size of the panel for the purpose of generating spec plots
      ;This will be a 2-element array, with the values being some multiple/fraction of the 
      ;number of pixels on each axis respectively.
      panel_sz_pt = self->getPlotSize(xplotpos,yplotpos,self.specres)
      
      ;If we're generating a postscript,
      ;All the spectral plots in a panel will be turned
      ;into a single composite image.  Prior to this
      ;They will be stored in this container
      if self.postscript then begin
        spec_list = obj_new('IDL_Container')
      endif
      
      ;Loop over traces in the panel
      for j = 0,n_elements(traces)-1 do begin
      
        ;Create line model
        if obj_isa(traces[j],'spd_ui_line_settings') && $
          ptr_valid(dataXptr[j]) && $
          ptr_valid(dataYptr[j]) then begin
          
          panelInfoArray[i].hasLine = 1
          
          ;Generate a line plot model, and the reference data associated with it.
          linePlot = self->getLinePlot(traces[j],currentRange,yrange,xplotpos,yplotpos,currentScale,yscaling,xAxisMajors,dataXptr[j],datayPtr[j],panelInfoArray[i].xistime,linecolor=linecolor,mirrorptr=mirrorptr[j],refvar=refvar,abcissa=abcissa)
          if ~obj_valid(linePlot) then begin
            self.statusbar->update,'Error: Could not generate the plot due to internal error'
            self.historyWin->update,'Error: Could not generate the plot due to internal error'
            ;ok = error_message('Invalid line plot, indicates plot generation error',/traceback)
            return,0
          endif
          
          ;Store the parameters that are generated during line plot creation 
          traceInfoArray[j].color = linecolor
          
          ;The dependent variable lookup table for the legend
          if size(refVar,/type) then begin
            traceInfoArray[j].refData = ptr_new(refVar)
          endif
          
          traceInfoArray[j].isSpec = 0
          
           
          ;The independent variable lookup table for the legend
          ;This is not needed in the current schema because lookup
          ; can be done by the pixel index
          if size(abcissa,/type) then begin
          ;if keyword_set(abcissa) && ~xistime then begin
            traceInfoArray[j].abcissa = ptr_new(abcissa)
          endif
          
          ;Add the line model to the view
          view->add,linePlot
          
        ;Create Spectral Reference Data
        endif else if obj_isa(traces[j],'spd_ui_spectra_settings') && $
          ptr_valid(dataXptr[j]) && $
          ptr_valid(dataYptr[j]) && $
          ptr_valid(dataZptr[j]) && $
          obj_valid(zAxis) then begin
          
          panelInfoArray[i].hasSpec = 1
          
          ;This routine grids spectral data and performs any additional clipping that can be done after gridding.
          ;This also finds a new range after gridding and clipping, which is necessary to prevent loss of dynamic range on z.
          ;Because of dependency issues with the rescaling, the complete model cannot be generated at this step.  
          self->getSpecRef,currentRange,yrange,panel_sz_pt[0],panel_sz_pt[1],currentScale,yscaling,zscaling,dataXptr[j],datayptr[j],datazptr[j],refvar=refvar,plotdata=plotdata
          
          ;These store the results of getSpecRef in the info struct
          
          if size(refvar,/type) ne 0 then begin
            traceInfoArray[j].refData = ptr_new(refVar)
        
            traceInfoArray[j].isSpec = 1
            
          endif
          
          if size(plotData,/type) ne 0 then begin
            traceInfoArray[j].plotData = ptr_new(plotData)
            
            if ~keyword_set(zfixed) then begin
              zRangeRecalc[0] = min([zrangeRecalc[0],min(plotdata.data,/nan)],/nan)
              zRangeRecalc[1] = max([zrangeRecalc[1],max(plotdata.data,/nan)],/nan)
            endif
            
          endif
          
        endif
        
      endfor
      
      ;Now that we've definitively clipped and gridded the z-data
      ;We loop over the data again and create the true model.  The z-data
      ;Will be appropriately scaled to ensure we bound the data tightly.
      if panelInfoArray[i].hasSpec then begin
      
        if ~keyword_set(zFixed) && finite(zRangeRecalc[0]) && finite(zRangeRecalc[1]) then begin
      
          zRange = zRangeRecalc
      
        endif    
      
        for j = 0,n_elements(traces)-1 do begin
          if traceInfoArray[j].isSpec && ptr_valid(traceInfoArray[j].plotData) then begin
            
            ;This routine actually generates the model
            self->getSpecModel,traceInfoArray[j].plotData,zrange,paletteNum,model=specModel
          
            ;Either add to the view, or add to the list
            ;for creation of composite image
            if obj_valid(specModel) then begin
              if ~self.postscript then begin
                view->add,specModel
              endif else begin
                spec_list->add,specModel
              endelse
            endif
          
          endif
        endfor
      
      endif
      
      if self.postscript && spec_list->count() then begin
      
        ;This takes all the individual images and generates a single composite image,
        ;Which it puts in a model.
        model = self->aggregateSpecplots(spec_list,panel_sz_pt,color)
        ;and the model goes on the main view
        view->add,model
        
      endif
      
    endif
    
    ;Now that the z-range has been definitely locked down, we create the z-axis
    if obj_valid(zAxis) then begin
      self->makeZAxisModel,zrange,zAxis,xplotpos,yplotpos,framecolor,framethick,model=zAxisModel,majorNum=zMajorNum,minorNum=zMinorNum
      zaxis->getProperty,placement=placement
      ;This stores any information from axis creation process
      panelInfoArray[i].zplacement=placement   
      panelInfoArray[i].zmajornum=zmajornum
      panelInfoArray[i].zminornum=zminornum  
    endif
    
    ;  print,"made plot",systime(/seconds)-systm
    
    
    ;Now we generate models for dynamic content
    vBarModel = obj_new('IDLgrModel')
    hBarModel = obj_new('IDLgrModel')
    markerModel = obj_new('IDLgrModel') ;This is the model for markers in the process of being drawn, not completed markers
    
    ;And store any other parameters identified
    panelInfoArray[i].xplotpos=xplotpos
    panelInfoArray[i].yplotpos=yplotpos
    panelInfoArray[i].vBar=vBarModel
    panelInfoArray[i].hBar=hBarModel
    panelInfoArray[i].marker = markerModel
    
    currentPanel->getProperty,labelMargin=labelMargin
    
    ;This adds the variables to the current panel
    if varNum gt 0 then begin
      self->addVariables,view,annotation,varList,panelInfoArray[i],loadedData,xAxisMajors,xAxis,labelpos,labelMargin,varptr=varptr
      ptr_free,panelInfoArray[i].varInfo
      panelInfoArray[i].varInfo=varptr
    endif
    
    ; print,"added info",systime(/seconds)-systm
    
    ;annotation->add,vBarModel
    annotation->add,vBarModel
    annotation->add,hBarModel
    annotation->add,markerModel
    
    ;This adds the panel background
    self->addBackGround,view,color
    
    ;This adds the 2-line date string that normally rests in the bottom left or top left
    self->addDateString,view,xAxis,currentRange,currentScale,xplotpos[1]-xplotpos[0],yplotpos[1]-yplotpos[0],labelMargin
    
    if keyword_set(traceInfoArray) then begin
      ; store the valid data range for loaded data in this panel
      ; note: this is the full range, not the range shown in the panel
      ;     this is used to check bounds for 'out of range' versus 'NaN'
      panelInfoArray[i].dxptr = [ptr_new(dataRange[0]), ptr_new(max(dataRange))]
      paTmp = panelInfoArray[i] ;error occurs if you edit the array in place
      
      ;This generates the initial rendering of the legend.  The final appearance will be controlled
      ;Largely by turning the hide flags for the model on and off dynamically
      self->addLegend,view,annotation,paTmp,traceInfoArray
      panelInfoArray[i] = paTmp
      ;print,"added other fun stuff",systime(/seconds)-systm
      panelInfoArray[i].traceInfo = ptr_new(traceInfoArray)
    endif else begin
      panelInfoArray[i].traceInfo = ptr_new()
    endelse
    
    ;add models to the view
    ;The order in which they were added matters because this changes layering,
    ;even though it shouldn't
    
    ;Currently prior to axes, so that they will be below them in the layering
    view->add,gridmodelx
    view->add,gridmodely
    view->add,xAxisModel
    view->add,yAxisModel
  
    
    if obj_valid(zAxis) then begin
      view->add,zAxisModel
    endif
    
    ;  ptr_free,dataXptr,dataYptr,dataZptr
    
    dataXptr = ptr_new()
    dataYptr = ptr_new()
    dataZptr = ptr_new()
    
    ;Garbage collect any memory sitting around from this last iteration.
    ;Most languages would do this automatically, but IDL seems pretty 
    ;bad about it.
    if double(!version.release) lt 8.0d then heap_gc
  ;print,"did everything",systime(/seconds)-systm
    
  endfor
  
  self.panelInfo = ptr_new(panelInfoArray)
  
  return,1
  
end
