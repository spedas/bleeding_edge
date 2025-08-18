;+
;
;spd_ui_draw_object method: makeView
;
;updates the draw object to reflect the page settings
;Inputs:
;  pageSettings(object reference):  the spd_ui_page_settings associated with the window being drawn
;  
;Outputs:
;  returns: 1 on success, 0 on failure.
;  
;Mutates:
;  self.pageview, self.scene,self.currentPageSize,self.staticviews
;           
;$LastChangedBy: jimm $
;$LastChangedDate: 2014-02-11 10:54:32 -0800 (Tue, 11 Feb 2014) $
;$LastChangedRevision: 14326 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas_gui/display/draw_object/spd_ui_draw_object__updatepage.pro $
;-
    
function spd_ui_draw_object::updatePage,pageSettings

  compile_opt idl2,hidden
  
  ;Constants to determine title position
  vertical_offset_top = 20 ; pts
  vertical_offset_bottom = 5 ; pts
  
  pageSettings->getproperty,backgroundcolor=bgcol, orientation=orientation, canvasSize=canvasSize
  
  ;These routines automatically replace any format codes
  ;with actual values
  title = pageSettings->getTitleString()
  
  footer = pageSettings->getFooterString()

  self.currentPageSize = canvasSize
  ; dim = self->getDim()
  
  ; dim /= self->getZoom()
  
  ;Create the pageview if it doesn't already exist
  if ~obj_valid(self.pageview) then begin
    pageview = obj_new('IDLgrView')
    self.pageview = pageview
    pageview->setProperty,units=3,viewplane_rect=[0.,0.,1.,1.],location=[0.,0.],dimensions=[1.,1.],zclip=[1.,-1.],eye=5,name="pageview",/transparent,/double
    self.scene->add,pageview
  endif
  
  ;add pageview to the group of static views
  ;used for instancing
  self.staticViews->add,self.pageView
  
  ;set the background color
  self.scene->setProperty,color=self->convertColor(bgcol)
  
  ;remove old page info
  self.pageview->remove,/all
  
  ;Create the title and the footer
  if obj_valid(title) then begin
  
    grTitle = self->getTextModel(title,[.5,1.-self->pt2norm(vertical_offset_top,1),0.],-1,0)
    
    self.pageview->add,grTitle
    
    obj_destroy,title
    
  endif
  
  if obj_valid(footer) then begin
  
    grFooter = self->getTextModel(footer,[.5,self->pt2norm(vertical_offset_bottom,1),0.],1,0)
    
    self.pageview->add,grFooter
    
    obj_destroy,footer
    
  end
  
  return,1
  
end
