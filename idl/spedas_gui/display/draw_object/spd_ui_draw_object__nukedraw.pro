;+
;
;spd_ui_draw_object method: nukeDraw
;
;
;This routine should blank the current contents of the object
;Generally used in the event of an error
;
;$LastChangedBy: jimm $
;$LastChangedDate: 2014-02-11 10:54:32 -0800 (Tue, 11 Feb 2014) $
;$LastChangedRevision: 14326 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas_gui/display/draw_object/spd_ui_draw_object__nukedraw.pro $
;-
pro spd_ui_draw_object::nukeDraw

  compile_opt idl2,hidden
  
  drawTree = self.scene->get(/all)
  self.scene->remove,/all
  
  obj_destroy,drawTree
  
  ptr_free,self.panelInfo
  
  if double(!version.release) lt 8.0d then heap_gc
  
end
