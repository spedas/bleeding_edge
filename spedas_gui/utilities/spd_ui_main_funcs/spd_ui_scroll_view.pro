;+
;
;  Name: spd_ui_scroll_view
;  
;  Purpose: Moves the area viewport of the draw area if the entire viewing area is not displayed
;  
;  Inputs: draw_widget: The draw widget for the visible drawing area
;          dir: 0=down, 1=up 
;
;
;$LastChangedBy: jimm $
;$LastChangedDate: 2014-02-11 10:54:32 -0800 (Tue, 11 Feb 2014) $
;$LastChangedRevision: 14326 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas_gui/utilities/spd_ui_main_funcs/spd_ui_scroll_view.pro $
;-
pro spd_ui_scroll_view,draw_widget,dir

  widget_control,draw_widget,get_draw_view=draw_view_pos

  geom=widget_info(draw_widget,/geometry)
  
  shift_factor = .3 ;what fraction of the visible area should be shifted for each click
  
  if dir eq 0 then begin
    draw_view_pos[1] = (draw_view_pos[1]-geom.scr_ysize*shift_factor)>0
  endif else if dir eq 1 then begin
    draw_view_pos[1] = (draw_view_pos[1]+geom.scr_ysize*shift_factor)
  endif
  
  widget_control,draw_widget,set_draw_view=draw_view_pos
  
  ;print,'View Pos',draw_view_pos
  ;print,'Xsize',geom.xsize
  ;print,'scrXsize',geom.scr_xsize
  ;print,'drawXsize',geom.draw_xsize
  
  ;print,'Ysize',geom.ysize
  ;print,'scrYsize',geom.scr_ysize
  ;print,'drawYsize',geom.draw_ysize

end
