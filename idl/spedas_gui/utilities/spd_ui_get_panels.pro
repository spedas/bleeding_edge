;+
;NAME:
;  spd_ui_get_panels
;
;PURPOSE:
;  Generic GUI function for returning the panel names and panel objects given a window
;
;CALLING SEQUENCE:
;  panel_names = spd_ui_get_panels(window, panelObjs = panelObjs)
;
;INPUT:
;  window: current active window, see the following example:
;  
;EXAMPLE:
;  window = windowStorage->getActive()
;  panel_names = spd_ui_get_panels(window, panelObjs=panelObjs)
;
;OUTPUT:
;  names of the panels on the current page, or a single element array 
;  with 'No Panels' if there aren't any panels on the current page
;
;$LastChangedBy: egrimes $
;$LastChangedDate: 2014-07-24 12:19:29 -0700 (Thu, 24 Jul 2014) $
;$LastChangedRevision: 15603 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas_gui/utilities/spd_ui_get_panels.pro $
;-

function spd_ui_get_panels, window, panelObjs=panelObjs
   ; Query panel list and coordinates
   if ~obj_valid(window) then begin
        panelNames = ['No Panels']
   endif else begin
        window->getProperty, Panels=panels
        if obj_valid(panels) then begin
            panelObjs = panels->Get(/all)
            if obj_valid(panelObjs[0]) then begin
                for i=0, n_elements(panelObjs)-1 do begin
                    name=panelObjs[i]->constructPanelName()
                    if (i eq 0) then panelNames=[name] else panelNames=[panelNames, name]
                endfor
            endif else begin
                panelNames=['No Panels']
            endelse
        endif else begin
            panelNames = ['No Panels']
        endelse
   endelse
   return, panelNames
end