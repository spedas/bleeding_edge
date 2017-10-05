;+ 
;NAME:  
;  spd_ui_tplot_gui_panel_options
;  
;PURPOSE:
;  Integrates information from various sources to properly set panel options in a tplot-like fashion
;  
;CALLING SEQUENCE:
; spd_ui_tplot_gui_var_labels,panel,page,varnames,allnames=allnames,newnames=newnames
;  
;INPUT:
;  panel: curent panel in the label     
;            
;KEYWORDS:
;  varnames: varnames added to panel
;  allnames: list of names as added
;  newnames: names of variables in allnames after potential user rename
;  trange: trange keyword from parent
;
;OUTPUT:
;  mutates panel object
;  
;$LastChangedBy: egrimes $
;$LastChangedDate: 2015-04-28 13:17:10 -0700 (Tue, 28 Apr 2015) $
;$LastChangedRevision: 17440 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas_gui/utilities/spd_ui_tplot_gui_funcs/spd_ui_tplot_gui_panel_options.pro $
;-------------------------------------------------------------------------------

;note var labels must be string type and cannot be pseudo variables
pro spd_ui_tplot_gui_panel_options,panel,varnames=varnames,allnames=allnames,newnames=newnames,trange=trange

  compile_opt idl2
  
  ;direct graphics values are generally scaling factors not exact measurements
  ;these establish the values being scaled
  default_font_size = 11.
  default_major_length = 7.
  default_minor_length = 3.
  default_panel_height = 216.
  default_panel_width = 432.
  
  if n_elements(varnames) eq 0 then begin
    return
  endif
  
  if ~obj_valid(panel) then begin
    return
  endif
  
  for i = 0,n_elements(varnames)-1 do begin
    ;this corrects for potential name change that occurred during verification
    idx = where(varnames[i] eq allnames,c)
    if c ne 1 then begin
      dprint,"Unexpected error detected"
      return
    endif
  
    !spedas.loadedData->getdatainfo,newnames[idx[0]],dlimit=dl_var,limit=l_var
    
    ;this ensures that all the settings are stored in dl for the purposes of this function.
    ;while maintaining precedence between different sources of limits/dlimits
    if n_elements(l_var) gt 0 then begin
      if n_elements(l) eq 0 then begin
        l = l_var
      endif else begin
        extract_tags,l,l_var
      endelse
    endif
    
    if n_elements(dl_var) gt 0 then begin
      if n_elements(dl) eq 0 then begin
        dl = dl_var
      endif else begin
        extract_tags,dl,dl_var
      endelse
    endif
    
    if n_elements(l) gt 0 then begin
      extract_tags,dl,l
    endif
    
   endfor
    
   panel->getProperty,settings=panelsettings,xaxis=xaxis,yaxis=yaxis,zaxis=zaxis,traceSettings=traces
   
   bgcolor = !P.background
   color = !P.color
   tvlct,r,g,b,/get ;load current color table
   
   if bgcolor le 255 then begin
     panelsettings->setProperty,backgroundcolor=[r[bgcolor],g[bgcolor],b[bgcolor]]
   endif else begin
     dprint,"WARNING: Value of !P.background greater than 255.  GUI only accepts indexed colors (0-255) from !P.background"
   ;  panelsettings->setProperty,backgroundcolor=[bgcolor and '0000ff'x,ishft(bgcolor and '00ff00'x,-8),ishft(bgcolor and 'ff0000'x,-16)]
   endelse
   
   if color le 255 then begin
     panelsettings->setProperty,framecolor=[r[color],g[color],b[color]]
   endif else begin
     dprint,"WARNING: Value of !P.color greater than 255.  GUI only accepts indexed colors (0-255) from !P.color" 
   ;  panelsettings->setProperty,framecolor=[color and '0000ff'x,ishft(color and '00ff00'x,-8),ishft(color and 'ff0000'x,-16)]
   endelse
   
;   if obj_valid(traces) then begin
;     n = traces->count()
;     if n gt 0 then begin
;       traceObs = traces->get(/all)
;        for i = 0,n-1 do begin
;          if obj_isa(traceObs[i],'spd_ui_line_settings') then begin
;            traceObs->getProperty,linestyle=linestyle
;            linestyle->setProperty,color=[r[color],g[color],b[color]]
;          endif
;        endfor
;     endif
;   endif
   
   if ~is_struct(dl) then return
   
   xistime = 1
   
   str_element,dl,'xistime',v,success=s
   if s && obj_valid(xaxis) then begin
     xaxis->setProperty,isTimeAxis=v
     xistime=v
   endif 
   
   str_element,dl,'yistime',v,success=s
   if s && obj_valid(yaxis) then begin
     yaxis->setProperty,isTimeAxis=v
   endif
    
   str_element,dl,'title',v,success=s
   if s then begin
     panelsettings->getProperty,titleObj=paneltitle
     paneltitle->setProperty,value=v
   endif
   
   str_element,dl,'charsize',v,success=s
   if s then begin
     panelsettings->getProperty,titleObj=paneltitle
     paneltitle->setProperty,size=default_font_size*v
   endif
   
   str_element,dl,'xcharsize',v,success=s
   
   if s && obj_valid(xaxis) then begin
     xaxis->getProperty,annotateTextObject=annOb,labels=labelContainer
     annOb->setProperty,size=default_font_size*v
     if obj_valid(labelContainer) then begin
       n = labelContainer->count()
       if n gt 0 then begin
          labelText = labelContainer->get(/all)
          for i = 0,n-1 do begin
            labelText[i]->setProperty,size=default_font_size*v
          endfor
       endif
     endif
   endif
   
   if n_elements(trange) eq 2 then begin
     ctrange = trange
   endif else if n_elements(trange) gt 0 then begin
     dprint,"WARNING: Incorrectly formatted trange option being ignored."
   endif
   
   str_element,dl,'xrange',v,success=s
   if s && obj_valid(xaxis) && n_elements(v) eq 2 then begin
     ctrange = v
   endif else if s && obj_valid(xaxis) && n_elements(v) gt 0 then begin
     dprint,"WARNING: Incorrectly formatted xrange option being ignored."
   endif
   
   if xistime && n_elements(ctrange) ne 2 then begin
     ctrange=spd_tplot_trange(/current) 
   endif
  
   if n_elements(ctrange) eq 2 then begin
     if is_string(ctrange) then begin
       ctrange = time_double(ctrange)
     endif
     if ctrange[1] gt ctrange[0] then begin
       xaxis->setProperty,minfixedrange=ctrange[0],maxfixedrange=ctrange[1],rangeoption=2,rangemargin=0
     endif
   endif
   
   str_element,dl,'ycharsize',v,success=s
   
   if s && obj_valid(yaxis) then begin
     yaxis->getProperty,annotateTextObject=annOb,labels=labelContainer
     annOb->setProperty,size=default_font_size*v
     if obj_valid(labelContainer) then begin
       n = labelContainer->count()
       if n gt 0 then begin
          labelText = labelContainer->get(/all)
          for i = 0,n-1 do begin
            labelText[i]->setProperty,size=default_font_size*v
          endfor
       endif
     endif
   endif
   
   str_element,dl,'zcharsize',v,success=s
   
   if s && obj_valid(zaxis) then begin
     zaxis->getProperty,annotateTextObject=annOb,labelTextObj=labelText
     annOb->setProperty,size=default_font_size*v
     if obj_valid(labelText) then begin
       labelText->setProperty,size=default_font_size*v
     endif
   endif
   
   str_element,dl,'xticklen',v,success=s
   if s && obj_valid(xaxis) then begin
     xaxis->setProperty,majorlength=v*default_major_length,minorlength=v*default_minor_length
   endif
   
   str_element,dl,'yticklen',v,success=s
   if s && obj_valid(yaxis) then begin
     yaxis->setProperty,majorlength=v*default_major_length,minorlength=v*default_minor_length
   endif
   
   str_element,dl,'xthick',v,success=s
   if s then begin
     panelsettings->setProperty,framethick=v
   endif
   
   str_element,dl,'ythick',v,success=s
   if s then begin
     panelsettings->setProperty,framethick=v
   endif
   
   str_element,dl,'thick',v,success=s
   
   if s then begin
     if obj_valid(traces) then begin
       n = traces->count()
       if n gt 0 then begin
         traceObs = traces->get(/all)
          for i = 0,n-1 do begin
            if obj_isa(traceObs[i],'spd_ui_line_settings') then begin
              traceObs[i]->getProperty,linestyle=linestyle
              linestyle->setProperty,thickness=v
            endif
          endfor
       endif
     endif
   endif
      
   str_element,dl,'xticks',v,success=s
   if s && obj_valid(xaxis) then begin
     if v ge 1 then begin
       xaxis->setProperty,numMajorTicks=v-1,autoticks=0,majortickauto=1,/notouched
     endif else begin
       xaxis->setProperty,autoticks=1,majortickauto=1,/notouched
     endelse
   endif 
      
   str_element,dl,'xminor',v,success=s
   if s && obj_valid(xaxis) then begin
     if v ge 1 then begin
       xaxis->setProperty,numMinorTicks=v-1,autoticks=0,majortickauto=1,/notouched
     endif else begin ;low minor tick value indicates auto minors
       xAxis->getProperty,scaling=xscale,istime=xistime
       if xistime then begin
         xAxis->setProperty,numminorticks = 5,/notouched
       endif else if xscale eq 1 then begin
         xAxis->setProperty,numMinorTicks = 8,/notouched
       endif else if xScale eq 2 then begin
         xAxis->setProperty,numMinorTicks = 1,/notouched
       endif else begin
         xAxis->setProperty,numMinorTicks = 4,/notouched
       endelse
     endelse
   endif 
   
   str_element,dl,'yticks',v,success=s
   if s && obj_valid(yaxis) then begin
     if v ge 1 then begin
       yaxis->setProperty,numMajorTicks=v-1,autoticks=0,majortickauto=1,/notouched
     endif else begin
       yaxis->setProperty,autoticks=1,majortickauto=1,/notouched
     endelse
   endif 
      
   str_element,dl,'yminor',v,success=s
   if s && obj_valid(yaxis) then begin
     if v ge 1 then begin
       yaxis->setProperty,numMinorTicks=v-1,autoticks=0,/notouched
     endif else begin
       yAxis->getProperty,scaling=yscale,istime=yistime
       if yistime then begin
         yAxis->setProperty,numMinorTicks = 5,/notouched
       endif else if yscale eq 1 then begin
         yAxis->setProperty,numMinorTicks = 8,/notouched
       endif else if yScale eq 2 then begin
         yAxis->setProperty,numMinorTicks = 1,/notouched
       endif else begin
         yAxis->setProperty,numMinorTicks = 4,/notouched
       endelse
     endelse
   endif 
   
   str_element,dl,'zticks',v,success=s
   if s && obj_valid(zaxis) then begin
     if v ge 1 then begin
       zaxis->setProperty,tickNum=v-1,autoticks=0,/notouched
     endif else begin
       zaxis->setProperty,autoticks=1,/notouched
     endelse
   endif 
      
   str_element,dl,'zminor',v,success=s
   if s && obj_valid(zaxis) then begin
     if v ge 1 then begin
       zaxis->setProperty,minortickNum=v-1,autoticks=0,/notouched
     endif else begin
       zaxis->getProperty,scaling=zscale
       if zscale eq 1 then begin
         zAxis->setProperty,minorTickNum = 8,/notouched
       endif else if zScale eq 2 then begin
         zAxis->setProperty,minorTickNum = 0,/notouched
       endif else begin
         zAxis->setProperty,minorTickNum = 4,/notouched
       endelse
     endelse
   endif 
 
   ;panel_size,panelsize,ypanel_size, and ypanelsize are treated as aliases for the same setting
   str_element,dl,'panel_size',v,success=s
   if s && is_num(v) then begin
     panelsettings->setProperty,height=1,hvalue=v*default_panel_height,hUnit=0
   endif
 
   str_element,dl,'panelsize',v,success=s 
   if s && is_num(v) then begin
     panelsettings->setProperty,height=1,hvalue=v*default_panel_height,hUnit=0
   endif
     
   str_element,dl,'ypanel_size',v,success=s
   if s && is_num(v) then begin
     panelsettings->setProperty,height=1,hvalue=v*default_panel_height,hUnit=0
   endif  
   
   str_element,dl,'ypanelsize',v,success=s
   if s && is_num(v) then begin
     panelsettings->setProperty,height=1,hvalue=v*default_panel_height,hUnit=0
   endif
   
   ;xpanel_size,xpanelsize are treated as aliases for the same setting  
   str_element,dl,'xpanel_size',v,success=s
   if s && is_num(v) then begin
     panelsettings->setProperty,width=1,wvalue=v*default_panel_width,wUnit=0
   endif  
   
   str_element,dl,'xpanelsize',v,success=s
   if s && is_num(v) then begin
     panelsettings->setProperty,width=1,wvalue=v*default_panel_width,wUnit=0
   endif
   
   str_element,dl,'xstacklabels',v,success=s
   if s && is_num(v) && obj_valid(xaxis) then begin
     xaxis->setProperty,stacklabels=v
   endif
     
   str_element,dl,'ystacklabels',v,success=s
   if s && is_num(v) && obj_valid(yaxis) then begin
     yaxis->setProperty,stacklabels=v
   endif
   
   str_element,dl,'stacklabels',v,success=s
   if s && is_num(v) && obj_valid(yaxis) then begin
     yaxis->setProperty,stacklabels=v
   endif 
   
end
