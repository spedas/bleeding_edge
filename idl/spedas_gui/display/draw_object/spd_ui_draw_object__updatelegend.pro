;+
;spd_ui_draw_object method: updateLegend
;
;this code performs an update on the legend text values for the provided panel
;it fills them in with the normalized data values provided as arguments
;
;panelLocation(2-element double): The position of the cursor in coordinates normalized to the panel
;panel(struct):  The draw object struct representing the panel
;blank(boolean keyword):  Set this keyword to make the legend blank
;noyvalue(boolean keyword): If this keyword is set, the yvalue will be set to an empty string and other values will be updated as normal
;
;$LastChangedBy: jimm $
;$LastChangedDate: 2014-02-11 10:54:32 -0800 (Tue, 11 Feb 2014) $
;$LastChangedRevision: 14326 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas_gui/display/draw_object/spd_ui_draw_object__updatelegend.pro $
;-
pro spd_ui_draw_object::updateLegend,panelLocation,panel,blank=blank,noyvalue=noyvalue

  compile_opt idl2,hidden
  
  if ptr_valid(panel.legendInfo) then begin
    legendobj = *panel.legendInfo
  
    notationSet = legendobj.notationSet
    timeFormat = legendobj.timeFormat
    numFormat = legendobj.numFormat
    xIsTime = legendobj.xIsTime
    yIsTime = legendobj.yIsTime
    zIsTime = legendobj.zIsTime
    
    ;blank panel, empty legend
    if keyword_set(blank) && ptr_valid(panel.traceInfo) then begin
      if obj_valid(panel.xobj) then panel.xobj->setProperty,strings=''
      
    ;  if panel.hasSpec then begin
      if obj_valid(panel.yobj) then panel.yobj->setProperty,strings=''
    ;  endif
      
      traces = *panel.traceInfo
      
      for j = 0,n_elements(traces)-1 do begin
        if obj_valid(traces[j].textObj) then begin
          traces[j].textObj->setProperty,strings=''
        endif
      endfor
      
    ;inside panel range, update with data
    endif else if ptr_valid(panel.traceinfo) then begin
      
      ;if we're locked, override the defaults with the locked values
      if panel.locked then begin
        xrange = panel.lockedRange
        xscale = panel.lockedScale
      endif else begin
        xrange = panel.xrange
        xscale = panel.xscale
      endelse
      
      if panel.xistime then begin
        if xrange[1]-xrange[0] lt 60*60*24 then begin
          xformat = 6
        endif else begin
          xformat = 15
        endelse
      endif else begin
        xformat = 5
      endelse
      
      if panel.yistime then begin
        if panel.yrange[1]-panel.yrange[0] lt 60*60*24 then begin
          yformat = 6
        endif else begin
          yformat = 15
        endelse
      endif else begin
        yformat = 5
      endelse
      
      if panel.zistime then begin
        if panel.zrange[1]-panel.zrange[0] lt 60*60*24 then begin
          zformat = 6
        endif else begin
          zformat = 15
        endelse
      endif else begin
        zformat = 5
      endelse
          
      
      ;calculate the x-position in data coordinates and update the string value for that point 
      xdatapos = xrange[0]+(xrange[1]-xrange[0])*panelLocation[0]
  ;    formatdata={timeAxis:panel.xIsTime,formatid:xformat,scaling:xscale,exponent:~xscale?0:2}
      formatdata={timeAxis:panel.xIsTime,formatid:xIsTime?timeFormat:numFormat,scaling:xscale,exponent:notationSet}
      if obj_valid(panel.xobj) then panel.xobj->setProperty,strings=formatannotation(0,0,xdatapos,data=formatdata)
      
      if ~keyword_set(noyvalue) then begin
        ;calculate the y-position in data coordinates and update the string value for that point 
        ydatapos = panel.yrange[0]+(panel.yrange[1]-panel.yrange[0])*panelLocation[1]
        formatdatay={timeAxis:panel.yIsTime,formatid:yIsTime?timeFormat:numFormat,scaling:panel.yscale,exponent:notationSet}
       ; if panel.hasSpec then begin
        if obj_valid(panel.yobj) then panel.yobj->setProperty,strings=formatannotation(0,0,ydatapos,data=formatdatay)
        ;endif
      endif else begin
        if obj_valid(panel.yobj) then panel.yobj->setProperty,strings=''
      endelse
      
      ;annotation struct for z-annotations
      formatdataz={timeAxis:panel.zIsTime,formatid:zIsTime?timeFormat:numFormat,scaling:panel.zscale,exponent:notationSet}
      
      traces = *panel.traceInfo
      
      ;loop through and update dependent variables
      for  i= 0,n_elements(traces)-1 do begin
      
        if ~ptr_valid(traces[i].refData) then begin
          dataString = 'NaN'
        endif else begin
        
          ;lookup 2-input dependent for specplot
          if traces[i].isSpec then begin
          
            refdim = dimen(*traces[i].refData)
            ;guarantee that IDL doesnt' make a dimension disappear(I hate it when IDL does this SOOOOO much)
            if n_elements(refDim) eq 1 then begin
              refDim = [refDim,1]
            endif
            
            ;The x/y indexes into the lookup table, bounded on the interval [0,1]
            refxidx = (round(panelLocation[0]*refdim[0]) < (refdim[0]-1)) > 0
            refyidx = (round(panelLocation[1]*refdim[1]) < (refdim[1]-1)) > 0
            
         ;   if finite((*traces[i].refData)[refxidx,refyidx],/inf) then stop
            
            dataString = formatannotation(0,0,(*traces[i].refData)[refxidx,refyidx],data=formatdataz)
         ;   print,dataString,refdim[0],refxidx,(*traces[i].refData)[refxidx,refyidx]
          endif else begin
          
            ;loopkup 1-input dependent for lineplot
          
            ;If there is no valid independent, use a proportionally scaled dependent
            if ~ptr_valid(traces[i].abcissa) then begin
            
              refdim = dimen(*traces[i].refData)
              refxidx = (round(panelLocation[0]*refdim[0]-1) < (refdim[0]-1)) > 0
              formatdatay={timeAxis:panel.yIsTime,formatid:yIsTime?timeFormat:numFormat,scaling:panel.yscale,exponent:notationSet}
            endif else begin
            ;valid indepenent, find the point closest to the input, abcissa values are normalized so comparison can be done directly
            
              tmp = min(abs(*traces[i].abcissa - panelLocation[0]),refxidx)
              formatdatay={timeAxis:panel.yIsTime,formatid:yIsTime?timeFormat:numFormat,scaling:panel.yscale,range:panel.yrange,exponent:notationSet}
            endelse
                     
            dataString = formatannotation(0,0,(*traces[i].refData)[refxidx],data=formatdatay)

          endelse
          
        endelse
        if (dataString eq string(!VALUES.D_NAN)) then begin
            ; no data here, check whether we're out of range or in a range with NaN's
            if (xdatapos lt *panel.dxptr[0] || xdatapos gt *panel.dxptr[1]) then begin
                dataString = 'Out of range'
            endif else begin
                dataString = 'NaN'
            endelse
        endif
        ;finally update the text object
        if obj_valid(traces[i].textObj) then begin
          traces[i].textObj->setProperty,strings=dataString
        endif
        
     ;   print,dataString,(dimen(*traces[i].refdata))[0],refxidx,(*traces[i].refData)[refxidx]
        
      endfor
      
    endif
    
    ;now update variables using the same logic
    
    ;If blank is requested blank all the variables
    if keyword_set(blank) && ptr_valid(panel.varInfo) then begin
   
      vars = *panel.varInfo
      
      for i = 0,n_elements(vars)-1 do begin
        vars[i].textObj->setProperty,strings=''
      endfor
      
    endif else if ptr_valid(panel.varInfo) then begin
    ;If not blanking do the update
    
      vars = *panel.varInfo
      
      for i = 0,n_elements(vars)-1 do begin
      
        ;update is done proportionally, because a lookup value has been generated
        ;for every possible cursor position.  This is possible because aliasing
        ;Is not as issue for variable quantities
        nx  = n_elements(*vars[i].dataY)
      
        ; calculate pixel-proportional index on interval [0,nx-1]
        idx = (round(panelLocation[0]*(nx-1)) > 0) < (nx-1)  
      
        ;identify value
        value = (*vars[i].dataY)[idx]
        
        ;format output string
        formatdata={timeAxis:vars[i].isTime,formatid:vars[i].isTime?timeFormat:numFormat,scaling:0,exponent:notationSet}
        str = formatannotation(0,0,value,data=formatdata)
        
        if value ge 0 then begin
          str = ' ' + str
        endif
        
        ;update text object
        vars[i].textObj->setProperty,strings=str
        
      endfor
      
    endif

  endif
end
