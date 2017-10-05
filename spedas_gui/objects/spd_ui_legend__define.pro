;+
; NAME:
;  spd_ui_legend__define
;
; PURPOSE:
;  Basic legend settings object
;
; CALLING SEQUENCE:
;  legend = Obj_New('SPD_UI_LEGEND')
; 
; INPUT:
;  none
;  
; KEYWORDS:
;  enabled:         flag for disable/enabling the legend
;  font:            index of legend font type - font types are from the getFonts method in spd_ui_text
;  size:            size of legend text
;  format:          legend font formats ('bold', 'italic', etc..)
;  color:           color of legend text
;  vspacing:        vertical spacing between lines in legend
;  bgcolor:         background color of legend
;  framethickness:  thickness of frame around legend
;  bordercolor:     color of frame around legend
;  bottom:          flag indicating whether explicit positioning is used
;  bValue:          numerical value of the explicit position (bottom)
;  bUnit:           bottom units - 0=pt, 1=in, 2=cm, 3=mm, units of numerical value
;  left:            flag indicating whether explicit positioning is used
;  lValue:          numerical value of the explicit position (left)
;  lUnit:           'left' units
;  width:           flag indicating whether explicit positioning is used
;  wValue:          numerical value of the explicit position (width)
;  wUnit:           'width' units
;  height:          flag indicating whether explicit positioning is used
;  hValue:          numerical value of the explicit position (height)
;  hUnit:           'height' units
;  xAxisValue:      X-axis value
;  xAxisValEnabled: enable/disable showing x-axis value on legend
;  yAxisValue:      Y-axis value
;  yAxisValEnabled: enable/disable showing y-axis value on legend
;  traces:          pointer to traces
;  customTracesset: 0=no custom traces set for this panel, 1=custom traces are set
;  xIsTime:         flag indicating whether X-axis is time
;  yIsTime:         flag indicating whether Y-axis is time
;  zIsTime:         flag indicating whether Z-axis is time
;  notationSet:     0 = auto-notation, 1=decimal notation, 2=scientific notation, 4=hexadecimal notation
;  timeFormat:      index of format for dates/times in legend, default is h:m:s.ms
;  numformat:       index of format for numerical values shown in legend
; 
; 
; 
;$LastChangedBy: egrimes $
;$LastChangedDate: 2014-06-12 08:22:12 -0700 (Thu, 12 Jun 2014) $
;$LastChangedRevision: 15354 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas_gui/objects/spd_ui_legend__define.pro $
;-
PRO SPD_UI_LEGEND::Cleanup
    obj_destroy, self
    if double(!version.release) lt 8.0d then heap_gc
END
PRO SPD_UI_LEGEND::Disable
  self.enabled=0
END
FUNCTION SPD_UI_LEGEND::Copy
    out = obj_new('SPD_UI_LEGEND')
    struct_assign, self, out
    RETURN, out
END
PRO SPD_UI_LEGEND::axisIsTime, axis
  if (axis eq 'X') then self.xIsTime=1
  if (axis eq 'Y') then self.yIsTime=1
  if (axis eq 'Z') then self.zIsTime=1
END

; the following procedure copies the properties from one SPD_UI_LEGEND object to another
; this method is required by 'Apply to All', since IDL holds onto the assignment that struct_assign makes
; e.g., if I were to use Copy() for this, every 'Apply' after the first 'Apply to All' would update
; every legend, instead of just the one selected in the 'Panels' dropdown
PRO SPD_UI_LEGEND::CopyContents,toLegendSettings
    self->getProperty, size=textsize, font=textfont, format=textformat, color=textcolor, $
          vspacing=spacing, bgcolor=legendbgcolor, framethickness=framethickness, bordercolor=bordercolor, $
          enabled=enabled, bottom=lbottom, left=lleft, width=lwidth, height=lheight, bValue=bValue, $
          lValue=lValue, wValue=wValue, hValue=hValue, bUnit=bUnit, lUnit=lUnit, wUnit=wUnit, hUnit=hUnut, $
          xAxisValue=xAxisValue, xAxisValEnabled=xAxisValEnabled, yAxisValue=yAxisValue, yAxisValEnabled=yAxisValEnabled, $
          xIsTime=xIsTime, yIsTime=yIsTime, zIsTime=zIsTime, notationSet=notationSet, timeFormat=timeFormat, numFormat=numFormat
    toLegendSettings->setProperty, size=textsize, font=textfont, format=textformat, color=textcolor, $
          vspacing=spacing, bgcolor=legendbgcolor, framethickness=framethickness, bordercolor=bordercolor, $
          enabled=enabled, bottom=lbottom, left=lleft, width=lwidth, height=lheight, bValue=bValue, $
          lValue=lValue, wValue=wValue, hValue=hValue, bUnit=bUnit, lUnit=lUnit, wUnit=wUnit, hUnit=hUnut, $
          xAxisValue=xAxisValue, xAxisValEnabled=xAxisValEnabled, yAxisValue=yAxisValue, yAxisValEnabled=yAxisValEnabled, $
          xIsTime=xIsTime, yIsTime=yIsTime, zIsTime=zIsTime, notationSet=notationSet, timeFormat=timeFormat, numFormat=numFormat
END
FUNCTION SPD_UI_LEGEND::BackupSettings, origlegendSettings
    if obj_valid(origlegendSettings) then begin
        struct_assign, self, origlegendSettings
    endif
    return, origlegendSettings
END

FUNCTION SPD_UI_LEGEND::RestoreBackup, origlegendSettings
    if obj_valid(origlegendSettings) then begin
        struct_assign, origlegendSettings, self
    endif
    return, self
END

;handles special cases for setProperty, the rest are handled by parent class: spd_ui_getset
PRO SPD_UI_LEGEND::setProperty,$
                             bunit=bunit,$
                             lunit=lunit,$
                             wunit=wunit,$
                             hunit=hunit,$
                             traces=traces,$
                             _extra=ex

  if n_elements(bunit) gt 0 then self.bvalue = self->convertunit(self.bvalue,self.bunit,bunit)
  if n_elements(lunit) gt 0 then self.lvalue = self->convertunit(self.lvalue,self.lunit,lunit)
  if n_elements(wunit) gt 0 then self.wvalue = self->convertunit(self.wvalue,self.wunit,wunit)
  if n_elements(hunit) gt 0 then self.hvalue = self->convertunit(self.hvalue,self.hunit,hunit)
  if ~undefined(traces) then begin
      self.customTracesset = 1
      self.traces = traces
  endif
  ;Do all general purpose setPropery with parent class
  self->spd_ui_getset::setProperty,bunit=bunit,lunit=lunit,wunit=wunit,hunit=hunit,traces=traces,_extra=ex
END

PRO SPD_UI_LEGEND::ResetPlacement, bunit=bunit, lunit=lunit, wunit=wunit, hunit=hunit
    if keyword_set(bunit) then self->setProperty, bunit = 0
    if keyword_set(lunit) then self->setProperty, lunit = 0
    if keyword_set(wunit) then self->setProperty, wunit = 0
    if keyword_set(hunit) then self->setProperty, hunit = 0
    
END
; procedure for updating traces structure
PRO SPD_UI_LEGEND::UpdateTraces, newStruct
    if ~undefined(newStruct) then begin
        ptr_free, self.traces
        self.traces = ptr_new(newStruct)
        self.customTracesset = 1
    endif
END         
            
FUNCTION SPD_UI_LEGEND::GetUnitNames
    return, ['pt', 'in', 'cm', 'mm']  
END

FUNCTION SPD_UI_LEGEND::GetUnitName, index
    names = self->GetUnitNames()
    return, names[index]
END 

FUNCTION SPD_UI_LEGEND::ConvertUnit,value,oldunit,newunit
  in2cm = 2.54D
  cm2mm = 10D
  mm2pt = 360D/127D
 
  ;turn value into points
  case oldunit of
    0: pts=value
    1: pts=value*(in2cm*cm2mm*mm2pt)
    2: pts=value*(cm2mm*mm2pt)
    3: pts=value*(mm2pt)
  end
  
  ;turn points into new value
  case newunit of
    0: new=pts
    1: new=pts/(in2cm*cm2mm*mm2pt)
    2: new=pts/(cm2mm*mm2pt)
    3: new=pts/(mm2pt)
  end
  
  return,new
END 

FUNCTION SPD_UI_LEGEND::Init,       $
    enabled=enabled,                $
    font=font,                      $
    size=size,                      $
    format=format,                  $
    color=color,                    $
    vspacing=vspacing,              $
    bgcolor=bgcolor,                $
    framethickness=framethickness,  $
    bordercolor=bordercolor,        $
    bottom=bottom,                  $
    left=left,                      $
    width=width,                    $
    height=height,                  $
    bValue=bValue,                  $
    lValue=lValue,                  $
    wValue=wValue,                  $
    hValue=hValue,                  $
    bUnit=bUnit,                    $
    lUnit=lUnit,                    $
    wUnit=wUnit,                    $
    hUnit=hUnit,                    $
    xAxisValue=xAxisValue,          $
    xAxisValEnabled=xAxisValEnabled,$
    yAxisValue=yAxisValue,          $
    yAxisValEnabled=yAxisValEnabled,$
    xIsTime=xIsTime,                $
    yIsTime=yIstime,                $
    zIsTime=zIsTime,                $
    timeFormat=timeFormat,          $
    numFormat=numFormat
    
    if undefined(enabled) then enabled = 1 ; show the legend by default
    if undefined(font) then font = 2 ; default is Helvetica
    if undefined(size) then size = 12
    if undefined(format) then format = 3 ; no default formatting
    if undefined(color) then color = [0,0,0] ; black text
    if undefined(vspacing) then vspacing = 2 
    if undefined(bgcolor) then bgcolor = [255,255,255] ; white background
    if undefined(framethickness) then framethickness = 1 
    if undefined(bordercolor) then bordercolor = [0,0,0] ; black border
    if undefined(bottom) then bottom = 0.
    if undefined(left) then left = 0.
    if undefined(width) then width = 0.
    if undefined(height) then height = 0.
    if undefined(bValue) then bValue = 0d
    if undefined(lValue) then lValue = 0d
    if undefined(wValue) then wValue = 0d
    if undefined(hValue) then hValue = 0d
    if undefined(bUnit) then bUnit = 0
    if undefined(lUnit) then lUnit = 0
    if undefined(wUnit) then wUnit = 0
    if undefined(hUnit) then hUnit = 0
    if undefined(xAxisValue) then xAxisValue = 'X Axis Time'
    if undefined(xAxisValEnabled) then xAxisValEnabled = 1 ; this label is enabled by default
    if undefined(yAxisValue) then yAxisValue = 'Y Axis Value'
    if undefined(yAxisValEnabled) then yAxisValEnabled = 1 ; this label is enabled by default
    if undefined(xIsTime) then xIsTime = 0
    if undefined(yIsTime) then yIsTime = 0
    if undefined(zIsTime) then zIsTime = 0
    if undefined(notationSet) then notationSet = 0
    if undefined(timeFormat) then timeFormat = 6 ; default is h:m:s.ms
    if undefined(numFormat) then numFormat = 5 ; format for regular numbers, default is 5 significant figures
    
    self.enabled = enabled
    self.font = font
    self.size = size
    self.format = format
    self.color = color
    self.vspacing = vspacing
    self.bgcolor = bgcolor
    self.framethickness = framethickness
    self.bordercolor = bordercolor
    self.bottom = bottom
    self.left = left
    self.width = width
    self.height = height
    self.bValue = bValue
    self.lValue = lValue
    self.wValue = wValue
    self.hValue = hValue
    self.bUnit = bUnit
    self.lUnit = lUnit
    self.wUnit = wUnit
    self.hUnit = hUnit
    self.xAxisValue = xAxisValue
    self.xAxisValEnabled = xAxisValEnabled
    self.yAxisValue = yAxisValue
    self.yAxisValEnabled = yAxisValEnabled
    self.xIsTime = xIsTime
    self.yIsTime = yIsTime
    self.zIsTime = zIsTime
    self.notationSet = notationSet
    self.timeFormat = timeFormat
    self.numFormat = numFormat

    return, 1
END

PRO SPD_UI_LEGEND__DEFINE
  
  ; legend class structure
  struct = { SPD_UI_LEGEND,             $
            enabled:1,                  $ ; flag for showing the legend -- 0=no legend, 1=show legend
            font:2,                     $ ; index of legend font type
            size:12,                    $ ; size of legend text
            format:3,                   $ ; legend font formats ('bold', 'italic', 'bold-italic')
            color:[0,0,0],              $ ; color of legend text
            vspacing:2,                 $ ; vertical spacing between lines in legend
            bgcolor:[255,255,255],      $ ; background color of legend
            framethickness:1,           $ ; thickness of frame around legend
            bordercolor:[0,0,0],        $ ; color of frame around legend
            bottom:0.,                  $ ; flag indicating whether explicit positioning is used
            bValue:0D,                  $ ; numerical value of the explicit position (bottom)
            bUnit:0,                    $ ; 0=pt, 1=in, 2=cm, 3=mm, units of numerical value
            left:0.,                    $ ; flag indicating whether explicit positioning is used
            lValue:0D,                  $ ; numerical value of the explicit position (left)
            lUnit:0,                    $ ; 'left' units
            width:0.,                   $ ; flag indicating whether explicit positioning is used
            wValue:0D,                  $ ; numerical value of the explicit position (width)
            wUnit:0,                    $ ; 'width' units
            height:0.,                  $ ; flag indicating whether explicit positioning is used
            hValue:0D,                  $ ; numerical value of the explicit position (height)
            hUnit:0,                    $ ; 'height' units
            xAxisValue:'X Axis Time',   $ ; X-axis value
            xAxisValEnabled:1,          $ ; enable/disable showing x-axis value on legend
            yAxisValue:'Y Axis Value',  $ ; Y-axis value
            yAxisValEnabled:1,          $ ; enable/disable showing y-axis value on legend
            traces:ptr_new(),           $ ; pointer to traces
            customTracesset:0,          $ ; 0=no custom traces set for this panel, 1=custom traces are set
            xIsTime:0,                  $ ; flag indicating whether X-axis is time
            yIsTime:0,                  $ ; flag indicating whether Y-axis is time
            zIsTime:0,                  $ ; flag indicating whether Z-axis is time
            notationSet:0,              $ ; 0 = auto-notation, 1=decimal notation, 2=scientific notation, 4=hexadecimal notation
            timeFormat:6,               $ ; index of format for dates/times in legend, default is h:m:s.ms
            numformat:5,                $ ; index of format for numerical values shown in legend, default is 5 sigificant figures
            inherits spd_ui_readwrite,  $ ; for saving templates
            inherits spd_ui_getset      $ ; inherit "GetAll","SetAll","GetProperty","SetProperty" methods
            }
END
