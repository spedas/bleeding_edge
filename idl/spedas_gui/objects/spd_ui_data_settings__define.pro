;+ 
;NAME: 
; spd_ui_data_settings
;
;PURPOSE:  
; represents the default plot settings for a trace, and digests the original tplot settings
;
;CALLING SEQUENCE:
; dsettings = obj_new('spd_ui_data_settings',limit,dlimit,element)
;
;HISTORY:
;
;NOTES:
;  1. We need to update defaults in the instance of a rename
;
;$LastChangedBy: jimm $
;$LastChangedDate: 2014-02-11 10:54:32 -0800 (Tue, 11 Feb 2014) $
;$LastChangedRevision: 14326 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas_gui/objects/spd_ui_data_settings__define.pro $
;-----------------------------------------------------------------------------------

function spd_ui_data_settings::getColor
  return,self.color
end

function spd_ui_data_settings::getDatagap
  return,self.datagap
end

function spd_ui_data_settings::getSpec
  return,self.spec
end

function spd_ui_data_settings::getxFixedRange
  return,self.xfixedRange
end

function spd_ui_data_settings::getxLabel
  return,self.xlabel
end

function spd_ui_data_settings::getxTitle
  return,self.xtitle
end

function spd_ui_data_settings::getxSubtitle
  return,self.xsubtitle
end

function spd_ui_data_settings::getxRangeOption
  return,self.xrangeOption
end

function spd_ui_data_settings::getxScaling
  return,self.xscaling
end

function spd_ui_data_settings::getyFixedRange
  return,self.yfixedRange
end

function spd_ui_data_settings::getyLabel
  return,self.ylabel
end

function spd_ui_data_settings::getyTitle
  return,self.ytitle
end

pro spd_ui_data_settings::setyTitle, input
  self.ytitle = input
end

function spd_ui_data_settings::getySubtitle
  return,self.ysubtitle
end

function spd_ui_data_settings::getyRangeOption
  return,self.yrangeOption
end

function spd_ui_data_settings::getyScaling
  return,self.yscaling
end

function spd_ui_data_settings::getzFixed
  return,self.zfixed
end

function spd_ui_data_settings::getzLabel
  return,self.zlabel
end

function spd_ui_data_settings::getzSubtitle
  return, self.zsubtitle
end

function spd_ui_data_settings::getzRange
  return,self.zrange
end

function spd_ui_data_settings::getzScaling
  return,self.zscaling
end

function spd_ui_data_settings::getUseColor
  return,self.usecolor
end

function spd_ui_data_settings::copy
  
  out = Obj_New("SPD_UI_DATA_SETTINGS",self.name, self.element)
  
  selfClass = Obj_Class(self)
  outClass = Obj_Class(out)
  
  IF selfClass NE outClass THEN BEGIN
    dprint,  'Object classes not identical'
    RETURN, -1
  END
  
  Struct_Assign, self, out
  
  return,out
end

pro spd_ui_data_settings::updateLabels,oldname,newname

  subIdx = stregex(self.xlabel,oldname,length=subLen)  
  if subIdx ne -1 then begin      
    self.xlabel = strmid(self.xlabel,0,subIdx) + newname + strmid(self.xlabel,subIdx+subLen)
  endif 
  
  subIdx = stregex(self.ylabel,oldname,length=subLen)  
  if subIdx ne -1 then begin      
    self.ylabel = strmid(self.ylabel,0,subIdx) + newname + strmid(self.ylabel,subIdx+subLen)
  endif 
  
  subIdx = stregex(self.zlabel,oldname,length=subLen)  
  if subIdx ne -1 then begin      
    self.zlabel = strmid(self.zlabel,0,subIdx) + newname + strmid(self.zlabel,subIdx+subLen)
  endif 
  
end

;if you don't want both arguments, just pass in 0, rather
;than a limit struct
pro spd_ui_data_settings::fromLimits,limit,dlimit

   usecolor = 0

   name = self.name
   element = self.element

   ;self.ylabel = name ;changing to using titles rather than labels by default
   index_color = element lt 3?([2,4,6])[element]:0
   
   dl = dlimit
   l = limit
   
   ;merges the settings                            
   extract_tags,dl,l
   
   ;if not struct leave defaults
   if size(dl,/type) eq 8 then begin 

     str_element,dl,'datagap',datagap,success=s
     if s then begin
       self.datagap = float(datagap)
     endif
     
     str_element,dl,'ytitle',ytitle,success=s  
     if s then begin
       self.ytitle = ytitle;this will probably only have a value if the user is loading a tplot var where they have set this themselves
     endif
     
     
     str_element,dl,'labels',labels,success=s  
     if s then begin
       pr = stregex(self.ylabel, '^th[abcde]_', /extract,/fold_case);since ylabel isn't set to name above this no longer should add 'th?' to the front
       if n_elements(labels) eq 1 then begin
         self.ylabel = pr + labels[0]
       endif else if element lt n_elements(labels) then begin
         self.ylabel = pr + labels[element]
       endif
     endif 

     str_element,dl,'spec',spec,success=s
     if s then begin
       self.spec = spec
     endif
     
     str_element,dl,'xlog',xlog,success=s
     if s && xlog gt 0 then begin
       self.xscaling = 1
     endif
          
     str_element,dl,'xrange',xrange,success=s
     if s then begin ;self.xFixedRange = xrange
       if (n_elements(xrange) eq 2) && (xrange[0] ne xrange[1]) then begin
         self.xfixedRange = xrange
       endif
     endif
     
     str_element,dl,'xstyle',xstyle,success=s
     if (self.xfixedrange[0] ne self.xfixedrange[1]) && ~(s && xstyle eq 0) then begin
       self.xrangeoption = 2
     endif
     
     str_element,dl,'xsubtitle',xsubtitle,success=s
     if s then begin
;       if keyword_set(self.xlabel) then begin
;         self.xlabel += ' ' + xsubtitle
;       endif else begin
;         self.xlabel = xsubtitle
;       endelse
        self.xsubtitle = xsubtitle
     endif  

     str_element,dl,'xtitle',xtitle,success=s  
     if s then begin
       self.xtitle = xtitle; moving xtitle from x label to x title field
     endif
     
     str_element,dl,'ylog',ylog,success=s
     if s && ylog gt 0 then begin
       self.yscaling = 1
     endif
     
     str_element,dl,'yrange',yrange,success=s
     if s then self.yfixedrange = yrange

     str_element,dl,'ystyle',ystyle,success=s
     if (self.yfixedrange[0] ne self.yfixedrange[1]) && ~(s && ystyle eq 0) then begin
       self.yrangeoption = 2
     endif
     
     str_element,dl,'ysubtitle',ysubtitle,success=s  
     if s then begin
;       if keyword_set(self.ylabel) then begin
;         self.ylabel += '_' + ysubtitle
;       endif else begin
;         self.ylabel = ysubtitle
;       endelse
        self.ysubtitle=ysubtitle
     endif

     str_element,dl,'zlog',zlog,success=s
     if s && zlog gt 0 then begin
       self.zscaling = 1
     endif

     str_element,dl,'zrange',zrange,success=s
     if s then begin
       self.zrange = zrange
     endif

     str_element,dl,'zstyle',zstyle,success=s
     if (self.zrange[0] ne self.zrange[1]) && ~(s && zstyle eq 0) then begin
       self.zfixed = 1
     endif

     str_element,dl,'zsubtitle',zsubtitle,success=s
     if s then begin
;       if keyword_set(self.zlabel) then begin
;         self.zlabel += ' ' + zsubtitle
;       endif else begin
;         self.zlabel = zsubtitle
;       endelse
       self.zsubtitle = zsubtitle
     endif               

     str_element,dl,'ztitle',ztitle,success=s  
     if s then begin
       self.zlabel = ztitle
     endif

     str_element,dl,'colors',colors,success=s
     if s then begin
       colors = self->get_colors(colors)
       usecolor = 1
     endif else begin
       if self.spec then begin
         colors = 0
       endif else begin
         colors = [2,4,6]
       endelse
     endelse
     
     if element lt n_elements(colors) then begin
       index_color = colors[element]
     endif else begin
       index_color = colors[0]
       usecolor = 0  
     endelse
     
     str_element,dl,'color',color,success=s
     if s then begin
       index_color = self->get_colors(color)
       usecolor = 1
     endif
   
   endif
    
   palette = get_thm_palette()
   
;   
   self.color = palette->getRGB(index_color)
   self.usecolor = usecolor
   
end

;converts colors that may be specified as letters 
;into numerical indices
;This is largely based on ssl_general/get_colors
;but it does not rely on direct graphics color tables
;it *may* be useful to remove the !p dependencies in the future,as well.
function spd_ui_data_settings::get_colors,input

  colors = [0,1,2,3,4,5,6,255]

  if is_string(input) then begin
    map = bytarr(256)+!p.color
    map[byte('xmbcgyrw')] = colors
    map[byte('XMBCGYRW')] = colors
    map[byte('0123456789')] = bindgen(10)
    map[byte('Dd')] = !p.color
    map[byte('Zz')] = !p.background
    cb = reform(byte(input))
    return,map[cb]
  endif
  
  return,input

end

FUNCTION SPD_UI_DATA_SETTINGS::init,$
                               name,$ 
                               element
                               
  self.name = name
  self.element = element
  
  return,1
end

PRO SPD_UI_DATA_SETTINGS__DEFINE

   struct = { SPD_UI_DATA_SETTINGS,            $
              color:[0b,0b,0b],$
              datagap:0.,$
              element:0,$
              name:'',$
              spec:0,$                  ; spectra, default no
              usecolor:0,$
              xfixedrange:[0D,0D],$     ; x-axis limits, default auto
              xlabel:'',$
              xtitle:'',$
              xsubtitle:'',$
              xrangeOption:-1,$          ; x-axis limits mode, default auto
              xscaling:-1,$              ; x-axis scaling, default linear
              yfixedrange:[0D,0D],$     ; y-axis limits, default auto
              ylabel:'',$
              ytitle:'',$
              ysubtitle:'',$
              yrangeOption:-1,$          ; y-axis limits mode, default auto
              yscaling:-1,$              ; y-axis scaling, default linear
              zfixed:-1,$                ; flag to use fixed min/max values, default auto
              zlabel:'',$
              zsubtitle:'',$
              zrange:[0D,0D],$          ; z-axis limits, default auto
              zscaling:-1$              ; z-axis scaling, default linear
              }        ; # of major ticks, default auto                             
END
