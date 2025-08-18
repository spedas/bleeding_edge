;+
;spd_ui_draw_object method: GetPanelInfo
;
;Return a bunch of information about a panel with a particular index
;returns 0 on fail
;
;$LastChangedBy: jimm $
;$LastChangedDate: 2014-02-11 10:54:32 -0800 (Tue, 11 Feb 2014) $
;$LastChangedRevision: 14326 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas_gui/display/draw_object/spd_ui_draw_object__getpanelinfo.pro $
;-
function spd_ui_draw_object::GetPanelInfo,index

  compile_opt idl2,hidden
  
  info = {$
    xpos:[0D,1D],$  ;the normalized x position of the plot within the panel
    ypos:[0D,1D],$  ;the normalized y position of the plot within the panel
    xrange:[0D,1D],$ ;the x data range of the panel(If xscale= 1 or 2 it will be the log of the range)
    yrange:[0D,1D],$ ;the y data range of the panel(If yscale= 1 or 2 it will be the log of the range)
    zrange:[0D,1D],$ ;the z data range of the panel(If zscale= 1 or 2 it will be the log of the range)
    xmajorSize:0D,$  ;the size of a major tick on the x axis(If xscale= 1 or 2 it will be in logarithmic space)
    ymajorSize:0D,$  ;the size of a major tick on the y axis(If yscale= 1 or 2 it will be in logarithmic space)
    xmajorNum:0,$ ; the number of major ticks on the x-axis
    ymajorNum:0,$ ; the number of major ticks on the y-axis
    zmajorNum:0,$ ; the number of major ticks on the z-axis
    xminorNum:0,$ ; the number of minor ticks on the x-axis
    yminorNum:0,$ ; the number of minor ticks on the y-axis
    zminorNum:0,$ ; the number of minor ticks on the z-axis
    xscale:0D,$  ;indicates scaling option for the x axis 0:linear,1:log10,2:logN
    yscale:0D,$  ;indicates scaling option for the y axis 0:linear,1:log10,2:logN
    zscale:0D,$  ;indicates scaling option for the z axis 0:linear,1:log10,2:logN
    xcenter:0D,$  ;The center for floating center.
    ycenter:0D,$  ;The center for floating center.
    lockedcenter:0D,$  ;The center for floating center.
    hasspec:0B,$ ;boolean indicates whether the panel has at least one spectrogram, if yes Z info will apply
    hasLine:0B } ;boolean indicates whether the panel has at least one line, if yes Z info will apply
    
  if ~ptr_valid(self.panelInfo) || $
    n_elements(index) ne 1 || $
    index ge n_elements(*self.panelInfo) then begin
    return,0
  endif
  
  panel = (*self.panelInfo)[index]
  
  info.xpos = panel.xplotpos
  info.ypos = panel.yplotpos
  info.xrange = panel.xrange
  info.yrange = panel.yrange
  info.zrange = panel.zrange
  info.xmajorsize = panel.xmajorsize
  info.ymajorsize = panel.ymajorsize
  info.xmajornum = panel.xmajornum
  info.ymajornum = panel.ymajornum
  info.zmajornum = panel.zmajornum
  info.xminornum = panel.xminornum
  info.yminornum = panel.yminornum
  info.zminornum = panel.zminornum
  info.xscale = panel.xscale
  info.yscale = panel.yscale
  info.zscale = panel.zscale
  info.xcenter = panel.xcenter
  info.ycenter = panel.ycenter
  info.lockedcenter = panel.lockedcenter
  info.hasSpec = panel.hasSpec
  info.hasLine = panel.hasLine
  
  return,info
  
end
