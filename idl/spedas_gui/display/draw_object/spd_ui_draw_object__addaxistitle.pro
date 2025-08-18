;+
;
;spd_ui_draw_object method: addAxisTitle
;
;This routine works out where to add the axis title (x and y axes)
;
;model: the output model
;titleobj: the spd_ui_text object containing title info
;subtitleobj: subtitle obj
;titlemargin: margin between axis & title
;placeTitle: whether to place title on top/bottom left/right
;dir: x/y axis flag (x=0,y=1)
;titleorientation: horizontal/vertical text flag (h=0,v=1)
;pt1: multiplicand to change pt into view normalized coords(perp axis)
;pt2: multiplicand to change pt into view normalized coords(par axis)
; lazytitles: like lazy labels, determines if underscores should be treated as carriage returns.
;
;$LastChangedBy: aaflores $
;$LastChangedDate: 2014-05-16 17:51:22 -0700 (Fri, 16 May 2014) $
;$LastChangedRevision: 15160 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/spedas_gui/display/draw_object/spd_ui_draw_object__addaxistitle.pro $
;-
pro spd_ui_draw_object::addAxisTitle, model, titleobj, subtitleobj, titlemargin, placetitle, dir, titleorientation, showtitle, pt1, pt2, lazytitles

  compile_opt idl2,hidden
  
  ; Logic is largely based on addAxisLabels, some sections are the same
  
  zstack = .1
  
  ; Check title and subtitle (could have either one of these, both, or neither, text could be '' in either)
  if ~obj_valid(titleobj) && ~obj_valid(subtitleobj) then return
  showtitle = obj_valid(titleobj) && showtitle
  showsubtitle = obj_valid(subtitleobj) && showtitle
  
  ;This switch simplifies the code significantly by
  ;making the x/y axis code symmetrical.
  ;Think of orient as indicating whether the text is
  ;oriented parallel (0) or perpendicular (1) to the axis
  if dir eq 1 then begin
    orient = ~titleorientation
  endif else begin
    orient = titleorientation
  endelse
  
    ;the baseline & updir options are used by
  ;IDL to determine text orientation in 3-d space
  ;(although we are only looking at a planar subset
  if titleorientation eq 0 then begin
    baseline = [1,0,0]
    updir = [0,1,0]
  endif else begin
    baseline = [0,1,0]
    updir = [-1,0,0]
  endelse
  
  ;logic to control label alignment
  ;ie top/bottom or /left/right justify
  if orient eq 0 then begin
    halign = 0.5
    valign = ~(placetitle xor dir)
  endif else begin
    valign = 1.0
    halign = ~placetitle
  endelse
  
    ; first work out how much space title, subtitle will take up so that labels can be offset where necessary
  ; how many lines is each? (we are allowing lazy labels and internal formatting)
  if showtitle then begin
    titleobj->getproperty, value=titletext, size=titlesize
    if keyword_set(lazytitles) then begin
      titletext = strjoin(strsplit(titletext,'_',/extract),'!c')
    endif
    titlesplit = strsplit(titletext,'!c|!C',/extract,/regex,count=numlines)
    ;titlespace = (titlesize+1)*numlines
  endif else numlines = 0
  if showsubtitle then begin
    subtitleobj->getproperty, value=subtitletext, size=subtitlesize
    if keyword_set(lazytitles) then begin
      subtitletext = strjoin(strsplit(subtitletext,'_',/extract),'!c')
    endif
    subtitlesplit = strsplit(subtitletext,'!c|!C',/extract,/regex,count=numsublines)
    ;subtitlespace = (subtitlesize+1)*numsublines
  endif else numsublines=0
  
  
  if showtitle then begin
    titleobj->getProperty, size=titlesize, value=titletext, color=titlecolor
    
    ;this is checked elsewhere, but just in case...
    titlesize = titlesize > 1
    
    titleFont = titleobj->getGrFont()
    titleFont->setProperty,size=titlesize*self->getZoom()
    if showsubtitle then begin
      subtitleobj->getProperty, size=subtitlesize
    endif else subtitlesize=titlesize
    subtitlesize +=1
    ; label code adds 1 to size
    titlesize += 1 

    offset1 = (dir xor placetitle)*subtitlesize*numsublines*pt1
    offset2 = (dir eq 1) ? titlesize*numlines*pt2 : -titlesize*numlines*pt2
    if orient eq 0 then begin ; parallel
      loc1 = .5D
      loc2 = -(titlemargin*pt1+offset1);this leaves space for one line for subtitle
    endif else begin ; perpendicular
      loc1 = .5D + offset2
      loc2 = -(titlemargin*pt1)
    endelse


    ; if placing on right/top then reverse loc2
    if placetitle eq 1 then begin
      loc2 = 1 - loc2
    endif
 
    if dir eq 1 then begin;YAXIS
      loc = [loc2,loc1,zstack]
    endif else begin;xaxis
      loc = [loc1,loc2,zstack]
    endelse

    if keyword_set(lazytitles) then begin
        titletext = strjoin(strsplit(titletext,'_',/extract),'!c')
    endif
    
    titlegrText = obj_new('IDLgrText', titletext,$
      font=titleFont,$
      color=self->convertColor(titlecolor),$
      location=loc,$
      alignment=hAlign,$
      vertical_alignment=valign,$
      baseline=baseline,$
      recompute_dimensions=0,$
      enable_formatting=1, $
      updir=updir)
      
    model->add,titlegrText
  endif
  
  if showsubtitle then begin
    subtitleobj->getProperty, size=subtitlesize, value=subtitletext, color=subtitlecolor
    if showtitle then begin
      titleobj->getProperty, size=titlesize
    endif else titlesize=subtitlesize
    
    ;this is checked elsewhere, but just in case...
    titlesize = titlesize > 1
    subtitlesize = subtitlesize > 1
    
    titlesize+=1
    subtitleFont = subtitleobj->getGrFont()
    subtitleFont->setProperty, size=subtitlesize*self->getZoom()
    subtitlesize +=1
    
    offset1 = (~(dir xor placetitle))*titlesize*numlines*pt1 ; allow the space for the title to fit
    offset2 = (dir eq 1) ? subtitlesize*numsublines*pt2 : -subtitlesize*numsublines*pt2
    if orient eq 0 then begin ; parallel
      loc1 = .5D
      loc2 = -(titlemargin*pt1+offset1)
    endif else begin ; perpendicular
      loc1 = .5D; - offset2
      loc2 = -(titlemargin*pt1)
    endelse


    ; if placing on right/top then reverse loc2
    if placetitle eq 1 then begin
      loc2 = 1 - loc2
    endif
 
    if dir eq 1 then begin;YAXIS
      loc = [loc2,loc1,zstack]
    endif else begin;xaxis
      loc = [loc1,loc2,zstack]
    endelse
    
;    ; subtitle alignment
;    if orient eq 0 then begin
;      halign = 0.5
;      valign = (placetitle xor dir)
;    endif else begin
;      valign = 1.0
;      halign = ~placetitle
;    endelse
    
    ; convert underscores to carriage returns
    if keyword_set(lazytitles) then begin
        subtitletext = strjoin(strsplit(subtitletext,'_',/extract),'!c')
    endif
  
    subtitlegrText = obj_new('IDLgrText', subtitletext,$
      font=subtitleFont,$
      color=self->convertColor(subtitlecolor),$
      location=loc,$
      alignment=hAlign,$
      vertical_alignment=valign,$
      baseline=baseline,$
      recompute_dimensions=0,$
      enable_formatting=1, $
      updir=updir)
      
    model->add,subtitlegrText
  endif

  
end
