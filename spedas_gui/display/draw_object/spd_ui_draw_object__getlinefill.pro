;+
; spd_ui_draw_object method: getLineFill
; 
; This method generates a shaded area between 2 lines and returns an IDLgrModel
; containing the associated ILDgrPolygon objects.  It is called during a panel
; update if the panel has valid spd_ui_linefill_settings objects in its 
; lineFillSettings container.
; 
; At this time it only returns a non-empty IDLgrModel if the requested lines
; match in number of data points and location of data gaps.  This is only tested
; to function properly when both data are functional (as in a time series) and 
; do not cross (for example: data+error and data-error for a measurment.) Once this is
; extended to generalize between any traces within a panel it could be elevated
; to the panel options widget.
;
;Inputs:
;  traces(2-element array of object reference): The spd_ui_line_settings of the 2 traces bounding the area
;  xrange(2-element double array):              The xrange of the panel being draw on
;  yrange(2-element double array):              The yrange of the panel being draw on
;  dataX(2-element array of ptrs):              The x axis data of the boundary lines for area being shaded
;  dataY(ptr to array):                         The y axis data of the boundary lines for area being shaded
;  color(3 element bytarr):                     The shading color
;  alpha(float):                                Opacity of shaded area.  Between 0(fully transparent) and 1(opaque)
;  
;Returns:
;  IDLgrModel containing IDLgrPolygon(s). May have multiple polygon objects in the case of data
;  with gaps.
;
;CREATED BY: Ayris Narock (ADNET/GSFC) 2017
;
; $LastChangedBy: nikos $
; $LastChangedDate: 2017-11-20 12:50:10 -0800 (Mon, 20 Nov 2017) $
; $LastChangedRevision: 24322 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas_gui/display/draw_object/spd_ui_draw_object__getlinefill.pro $
;-

function spd_ui_draw_object::getLineFill,traces,xrange,yrange,dataX,dataY,color=color,alpha=alpha
  compile_opt idl2,hidden
  
  if ~keyword_set(color) then color = [100,100,100]
  if ~keyword_set(alpha) then alpha = .6
  num = n_elements(*dataX[0])
  num1 = n_elements(*dataX[1])
  model = obj_new('IDLgrModel')

	if (num ne num1) then return,model	;TODO- consider resampling to handle this case

  ;need at least two points to draw the polygon 
  if num gt 1 then begin
  	traces[0]->getProperty,drawBetweenPts=drawBetweenPts0
  	traces[1]->getProperty,drawBetweenPts=drawBetweenPts1
  	sepcount = 0
  	idx = [num-1]
  	
  	;will respect gaps if either trace has the setting. Both traces must have same gaps. 
		if keyword_set(drawBetweenPts0)||keyword_set(drawBetweenPts1) then begin
			;determine the minimum amount of space that is allowed between points before we draw a gap.
			separation0 = traces[0]->getPtSpacing()
			separation1 = traces[1]->getPtSpacing()
			separation = max([separation0,separation1])

			idx0 = where(abs((*dataX[0])[1:num-1]-(*dataX[0])[0:num-2]) gt separation, sepcount)
			idx1 = where(abs((*dataX[1])[1:num-1]-(*dataX[1])[0:num-2]) gt separation, sepcount1)
			if (sepcount ne sepcount1) || ((sepcount ne 0)&&(total(idx0 eq idx1) ne sepcount)) then return,model ;gaps are not the same
			idx = (sepcount ne 0) ? idx0 : [num-1]
		endif
		
		xconv = [-xrange[0]/(xrange[1]-xrange[0]), 1/(xrange[1]-xrange[0])]
		yconv = [-yrange[0]/(yrange[1]-yrange[0]),1/(yrange[1]-yrange[0])]
		tessObj = replicate(obj_new('IDLgrTessellator'),sepcount+1)
		polyObj = replicate(obj_new(''),sepcount+1)
		for j=0,sepcount do begin
			i0 = (j eq 0) ? 0 : idx[j-1]+1
			i1 = (j eq sepcount) ? num-1 : idx[j]

			;check that each segment has at least 2 data points
			if i1-i0 gt 0 then begin
				tessObj[j]->AddPolygon,[(*dataX[0])[i0:i1],reverse((*dataX[1])[i0:i1])],[(*dataY[0])[i0:i1],reverse((*dataY[1])[i0:i1])]
				result = tessObj[j]->Tessellate(v,c)
				polyObj[j] = obj_new('IDLgrPolygon',v, polygons=c, xcoord_conv=xconv, ycoord_conv=yconv, color=color, alpha_channel=alpha)
				model->add,polyObj[j]
			endif
		endfor
  endif
  
  return,model
  
end
