;+
;
;spd_ui_draw_object method: getTextModel
;
;returns a text model by digesting the settings on a spd_ui_text object.
;This is basically just a wrapper for getTextObject
;text: a spd_ui_text object
;loc: the normalized location of the text, relative to the view [xpos,ypos,zpos]
;offsetDirFlag: 0=centered,1=abovelocation,-1=belowlocation
;justify, -1 = left, 1=right, 0 = middle
;
;Output:
;  an IDLgrModel containing an IDLgrText object
;
;$LastChangedBy: jimm $
;$LastChangedDate: 2014-02-11 10:54:32 -0800 (Tue, 11 Feb 2014) $
;$LastChangedRevision: 14326 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas_gui/display/draw_object/spd_ui_draw_object__gettextmodel.pro $
;-

function spd_ui_draw_object::getTextModel,text,loc,offsetDirFlag,orientation,justify=justify,enable_formatting=enable_formatting

  compile_opt idl2,hidden
  
  grText = self->getTextObject(text,loc,offsetDirFlag,orientation,justify=justify,enable_formatting=enable_formatting)
  
  model = obj_new('IDLgrModel')
  
  model->add,grText
  
  return,model
  
end
