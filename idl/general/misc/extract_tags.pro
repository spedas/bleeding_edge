;+
;PROCEDURE:  extract_tags, newstruct, oldstruct
;PURPOSE: takes the named tag elements from oldstruct and puts them into
;   newstruct.  This procedure is very useful for creating a structure that
;   can be passed onto the PLOT or OPLOT subroutines using the _EXTRA keyword.
;   If no tag keywords are included then all tag elements of oldstruct are
;   added to newstruct.  The mode keyword PRESERVE is used to prevent the
;   overwritting of an existing keyword.
;INPUTS:
;  newstruct:  new structure to be created or added to.
;  oldstruct:  old structure from which elements are extracted.
;KEYWORDS:  Only one of the following should be given:;
; (TAG KEYWORDS)
;  TAGS:  array of strings.  (tag names) to be taken from oldstruct and put in
;      newstruct
;  EXCEPT: array of strings.  Tag names not to be copied from old to new.
;  OPLOT:  (flag)  If set, then TAGS is set to an array of valid keywords
;     for the OPLOT subroutine.
;  PLOT:   (flag)  If set, then TAGS is set to an array of valid keywords
;     for the PLOT subroutine.
;  CONTOUR: (flag) If set, then TAGS is set to an array of valid keywords
;     for the CONTOUR procedure.   (might not be complete)
;If no KEYWORDS are set then all elements of oldstruct are put into newstruct
;  (MODE KEYWORDS)
;  PRESERVE: (flag) Prevents the overwritting of an existing, non-null keyword.
;     Adds tags to newstruct that were not already there, or if they were there
;     and their values were either "" or 0.
;CREATED BY:	Davin Larson
;FILE:  extract_tags.pro
;VERSION  1.21
;LAST MODIFICATION: 02/04/17
;-
pro extract_tags,newstruct,oldstruct, $
   OPLOT=oplot,  $
   PLOT=plot,    $
   CONTOUR=contr,$
   AXIS=axis,    $
   XYOUTS=xyouts, $
   TAGS=tags,    $
   NTAGS=ntags,  $
   REPLACE=replace,  $
   EXCEPT_TAGS=except_tags,  $
   PRESERVE=preserve

;note:  ytype is a version 3. keyword and not found in the version 4 docs

if size(/type,oldstruct) ne 8 then return

if keyword_set(oplot) then $
  tags = ['clip','color','linestyle','max_value','min_value','noclip',$
          'nsum','polar','psym','subtitle','symsize','t3d','thick','zvalue']

if keyword_set(plot) then $
  tags = ['background','charsize','charthick','clip','color','data','device',$
          'font','linestyle','max_value','min_value','noclip','nodata',      $
          'noerase','normal','nsum','polar','position','psym','subtitle',    $
          'symsize','t3d','thick','ticklen','title','xcharsize','xgridstyle',$
          'xlog','xmargin','xminor','xrange','xstyle','xthick','xtickformat',$
          'xticklen','xtickname','xticks','xtickv','xtick_get','xtitle',     $
          'xtype','ycharsize','ygridstyle','ylog','ymargin','yminor',        $
          'ynozero','yrange','ystyle','ythick','ytickformat','yticklen','ytickinterval',     $
          'ytickname','yticks','ytickv','ytick_get','ytitle','ytype','ytickunits',        $
          'zcharsize','zgridstyle','zlog','zmargin','zminor','zrange',       $
          'zstyle','zthick','ztickformat','zticklen','ztickname','zticks',   $
          'ztickv','ztick_get','ztitle','zvalue','isotropic']

if keyword_set(contr) then $
  tags = ['background','c_annotation','c_charsize','c_colors','c_labels',    $
          'c_linestyle','c_orientation','c_spacing','c_thick','cell_fill',   $
          'closed','charsize','charthick','clip','color','data','device',    $
          'downhill','fill','follow','font','levels','max_value','min_value',$
          'nlevels','noclip','nodata','noerase','normal','overplot',         $
          'path_filename','path_info','path_xy','position','subtitle',       $
          't3d','thick','ticklen','title','triangulation','xcharsize',       $
          'xgridstyle','xlog','xmargin','xminor','xrange','xstyle','xthick', $
          'xtickformat','xticklen','xtickname','xticks','xtickv','xtick_get',$
          'xtitle','xtype','ycharsize','ygridstyle','ylog','ymargin',        $
          'yminor','ynozero','yrange','ystyle','ythick','ytickformat',       $
          'yticklen','ytickname','yticks','ytickv','ytick_get','ytitle',     $
          'ytype','zcharsize','zgridstyle','zaxis','zmargin','zminor',       $
          'zrange','zstyle','zthick','ztickformat','zticklen','ztickname',   $
          'zticks','ztickv','ztick_get','ztitle','zvalue','isotropic']

if keyword_set(axis) then $
  tags = ['charsize','charthick','color','data','device','font','nodata',    $
          'noerase','normal','save','subtitle','t3d','ticklen','zaxis',      $
          'xcharsize','xgridstyle','xlog','xmargin','xminor','xrange',       $
          'xstyle','xthick','xtickformat','xticklen','xtickname','xticks',   $
          'xtickv','xtick_get','xtitle','xtype','yaxis','ycharsize',         $
          'ygridstyle','ylog','ymargin','yminor','ynozero','yrange',         $
          'ystyle','ythick','ytickformat','yticklen','ytickname','yticks',   $
          'ytickv','ytick_get','ytitle','ytype','zaxis','zcharsize',         $
          'zgridstyle','zmargin','zminor','zrange','zstyle','zthick',        $
          'ztickformat','zticklen','ztickname','zticks','ztickv',            $
          'ztick_get','ztitle','zvalue']

if keyword_set(xyouts) then $
   tags = ['alignment','charsize','charthick','text_axes','width','clip',    $
          'color','data','device','font','noclip','normal','orientation',    $
          't3d','z']

if keyword_set(except_tags) then begin
   tags = tag_names(oldstruct)
   ind = array_union(tags,strupcase(except_tags))
   w = where(ind lt 0,count)
   if count ne 0 then tags = tags[w] else tags = 0
endif

if n_elements(tags) eq 0 then tags = tag_names(oldstruct)
n = dimen1(tags)

if not keyword_set(ntags) then ntags=tags

if keyword_set(preserve) eq 0 then begin
for i=0,n-1 do begin
   str_element,oldstruct,tags[i],value,success=ok
   if ok then str_element,/add,newstruct,ntags[i],value
endfor
return
endif


for i=0,n-1 do begin
   index = find_str_element(oldstruct,tags[i])
   if index ge 0 then begin
       if find_str_element(newstruct,tags[i]) lt 0 then $     ;if not duplicate
         str_element,/add,newstruct,tags[i],oldstruct.(index) $ ;then add tag
       else begin                                             ;if duplicate tag
         if (size(/type,newstruct.(index)) eq 7) then $ ;if element is a string,
           if newstruct.(index) eq "" then $           ;then replace if null
             str_element,/add,newstruct,tags[i],oldstruct.(index) $
         else if total(newstruct.(index)) eq 0 then $  ;if element numerical,
           str_element,/add,newstruct,tags[i],oldstruct.(index) ;replace if null
       endelse
   endif
endfor
return
end



