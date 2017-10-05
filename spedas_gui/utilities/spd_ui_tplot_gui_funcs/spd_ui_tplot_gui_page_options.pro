;+ 
;NAME:  
;  spd_ui_tplot_gui_page_options
;  
;PURPOSE:
;  Integrates information from various sources to properly set page options in a tplot-like fashion
;  
;CALLING SEQUENCE:
; spd_ui_tplot_gui_page_options,pagesettings
;  
;INPUT:
;  pagesettings: settings for current window 
;            
;KEYWORDS:

;OUTPUT:
;  mutates pagesettings object
;  
;$LastChangedBy: jimm $
;$LastChangedDate: 2014-02-11 10:54:32 -0800 (Tue, 11 Feb 2014) $
;$LastChangedRevision: 14326 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas_gui/utilities/spd_ui_tplot_gui_funcs/spd_ui_tplot_gui_page_options.pro $
;--------------------------------------------------------------------------------

pro spd_ui_tplot_gui_page_options,pagesettings,activewindow

  tplot_options,get_options=opts

  str_element,opts,'xmargin',v,success=s

  ;many tplot options are implemented as scaling factors for a default rather than absolutes.
  ;these are constants to be scaled, although there is a risk that
  ;they will get out of date if main defaults are changed
  default_title_size = 12
  default_variable_size = 8
  default_ygap_size = 10
  
  if s then begin
    if n_elements(v) eq 2 && is_num(v) && v[0] gt 0 && v[1] gt 0 then begin
      leftmargin = !D.x_ch_size * v[0] / 72.
      rightmargin = !D.x_ch_size * v[1] / 72.
      pagesettings->setProperty,leftprintmargin=leftmargin,rightprintmargin=rightmargin
    endif else begin
      dprint,'xmargin has incorrect type.  Ignoring Setting.'
    endelse
  
  endif
  
  str_element,opts,'ymargin',v,success=s
  
  if s then begin
    if n_elements(v) eq 2 && is_num(v) && v[0] gt 0 && v[1] gt 0 then begin
      bottommargin = !D.y_ch_size * v[0] / 72.
      topmargin = !D.y_ch_size * v[1] / 72.
      pagesettings->setProperty,bottomprintmargin=bottommargin,topprintmargin=topmargin
    endif else begin
      dprint,'ymargin has incorrect type.  Ignoring Setting.'
    endelse
  
  endif
  
  str_element,opts,'title',v,success=s
  
  if s then begin
    if is_string(v) then begin
      pagesettings->getProperty,title=t
      t->setProperty,value=v
    endif else begin
      dprint,'title has incorrect type.  Ignoring Setting.'
    endelse
  
  endif
  
  str_element,opts,'footer',v,success=s
  
  if s then begin
    if is_string(v) then begin
      pagesettings->getProperty,footer=f
      f->setProperty,value=v
    endif else begin
      dprint,'footer has incorrect type.  Ignoring Setting.'
    endelse
  
  endif
  
  ;indicates which panel the plot will be locked to, or -1 if none
  str_element,opts,'locked',v,success=s
  
  if s then begin
    if v lt 0 then begin
      default_ygap_size = 120
    endif
    activewindow->setProperty,locked=v  
  endif
  
  str_element,opts,'charsize',v,success=s
  
  if s then begin
    if is_num(v) && v gt 0 then begin
      pagesettings->getProperty,title=t,footer=f,variables=var
      t->setProperty,size=v*default_title_size
      f->setProperty,size=v*default_title_size
      var->setProperty,size=v*default_variable_size
    endif else begin
      dprint,'charsize has incorrect type.  Ignoring Setting.'
    endelse
  
  endif
  
  str_element,opts,'ygap',v,success=s
  
  if s then begin
    if is_num(v) && v ge 0 then begin
      pagesettings->setProperty,ypanelspacing=v*default_ygap_size
    endif else begin
      dprint,'ygap has incorrect type.  Ignoring Setting.'
    endelse
  
  endif
  
  bgcolor = !P.background
  tvlct,r,g,b,/get ;load current color table
  pagesettings->setProperty,backgroundcolor=[r[bgcolor],g[bgcolor],b[bgcolor]]
 
end
