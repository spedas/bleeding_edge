;+ 
;NAME: 
; spd_ui_template
;
;PURPOSE:  
;  Top level object to manage the spedas gui settings template.  Mainly provides a root for serialization a la, spd_ui_document
;
;CALLING SEQUENCE:
; template = Obj_New("spd_ui_template")
;
;
;METHODS:
;  GetProperty
;  SetProperty
;
;
;HISTORY:
;
;NOTES:
;  This object differs from other gui objects with respect to its getProperty,setProperty,getAll,setAll methods.  These methods are now provided dynamically
;  by spd_ui_getset, so you only need to modify the class definition and the init method to if you want to add or remove a property from the object. 
;  
;
;$LastChangedBy: jimm $
;$LastChangedDate: 2014-02-11 10:54:32 -0800 (Tue, 11 Feb 2014) $
;$LastChangedRevision: 14326 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas_gui/objects/spd_ui_template__define.pro $
;-----------------------------------------------------------------------------------

function spd_ui_template::init

;  self.page =     obj_new('spd_ui_page_settings')
;  self.panel =    obj_new('spd_ui_panel_settings')
;  self.x_axis =   obj_new('spd_ui_axis_settings')
;  self.y_axis =   obj_new('spd_ui_axis_settings')
;  self.z_axis =   obj_new('spd_ui_zaxis_settings')
;  self.line =     obj_new('spd_ui_line_settings')
;  self.variable = obj_new('spd_ui_variable')

  return,1

end

PRO spd_ui_template__define

   struct = { SPD_UI_TEMPLATE,    $
              page:obj_new('spd_ui_page_settings'),$
              legend:obj_new('spd_ui_legend'),$
              panel:obj_new('spd_ui_panel_settings'),$
              x_axis:obj_new('spd_ui_axis_settings'),$
              y_axis:obj_new('spd_ui_axis_settings'),$
              z_axis:obj_new('spd_ui_zaxis_settings'),$
              line:obj_new('spd_ui_line_settings'),$
              variable:obj_new('spd_ui_variable'),$
              INHERITS spd_ui_readwrite, $
              INHERITS spd_ui_getset $ 
}

END
