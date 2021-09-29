;+
;NAME: PSP_DYPLOT
;
;DESCRIPTION:
; Plot a shaded area showing confidence range where avaialable.
; Expects the tplot variable structure to have either the 
; DY field (for symmetric confidence intervals) or the 
; DYL and DYH fields for deltalow and deltahigh values, respectively
;  
; Will look for tplot variable options tags 
;   psp_dy: 0 - do not show dy interval
;           1 - show dy interval if available
;
; TPLOT needs to be called first
; 
;INPUT:
;
;KEYWORDS: (Optional)   
; FORCE:    Set to ignore the 'psp_dy' tag setting and show the DY for all requested panels if DY available		
; NEW_DYINFO=: (output) Named variable to hold the keyword settings passed to this call of the routine
; OLD_DYINFO=: Set to a structure containing keywords to this routine. Will supercede any other keywords set.
; PANEL=:   Array of indices describing which panels for which to draw confidence. (1 indexed like TPLOT)
;             If this is not set the routine will attempt to draw confidence for all panels.
; POS=:     4xn array describing the positions of each of the n panels in the plot of interest.
;             Defaults to the positions found in the 'tplot_vars' structure.										
; TVINFO=:  Structure containing TPLOT variables information - as returned
;             from the 'new_tvar' keyword to tplot. 
;             If not set uses that found in common 'tplot_vars'
; VERBOSE=: Integer indicating the desired verbosity level.  Defaults to !psp_sweap.verbose
; WINDOW=:  Which direct graphics window to target for this polyfill. (int)
;             This is gererally not needed if plotting on an existing tplot window. Will default
;             to whatever is set by the TVINFO structure being used.
;					
;EXAMPLES:
;   ;Try to plot confidence on all panels if psp_dy flag is set
;   tplot,['np_fit','vp_fit','wa_fit']
;   psp_dyplot
;   
;   ;Plot confidence on panel 1 and 3 even if psp_dy flag is not set
;   tplot,['np_fit','vp_fit','wp_moment']
;   psp_dyplot,panel=[1,3],/force
;   
;CREATED BY: Ayris Narock (ADNET/GSFC) 2020
;
; $LastChangedBy: anarock $
; $LastChangedDate: 2020-10-27 12:50:05 -0700 (Tue, 27 Oct 2020) $
; $LastChangedRevision: 29302 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/sweap/SPC/L3i/plot/psp_dyplot.pro $
;-

PRO PSP_DYSINGLE,d,meta,tvinfo,pos,pidx
	compile_opt idl2
	
	device,get_decomposed = decomp
	device,/decomposed
	color = 'c8c8c8'x
	
	; Handle case with mirrored DY
	if isa(d,'STRUCT') && tag_exist(d,'dy') then begin
	  ; Make gaps only have 1 NaN between points
	  ; I do not know why there are sometimes additional gaps in the DY data
    x = d.x
    y = d.y
    dy = d.dy
    keep = simple_gaps(y[*,0])  ; Simplify on main data gaps
    x = x[keep]
    y = y[keep,*]
    dy = dy[keep,*]
    
    keep = simple_gaps(dy[*,0])  ; Simplify on DY data gaps
    x = x[keep]
    y = y[keep,*]
    dy = dy[keep,*]
    d = {x:x, y:y, dy:dy}
    dg = where(~finite(dy[*,0]),dgcount)
    
    ; Plot a shaded polygon for each separate segment 
		for pc = 0,dgcount do begin
			if dgcount eq 0 then begin
				dpc = d
			endif else begin
				ix0 = (pc eq 0) ? 0 : dg[pc-1]+1
				ix1 = (pc eq dgcount) ? n_elements(d.x)-1 : dg[pc]-1
				dpc = {x:d.x[ix0:ix1], y:d.y[ix0:ix1,*], dy:d.dy[ix0:ix1,*]}
			endelse

			xrange = tvinfo.settings.x.crange + tvinfo.settings.time_offset
			idx = where(dpc.x ge xrange[0] and dpc.x le xrange[1], count)
			if count gt 1 then begin
				dims = size(dpc.y,/dim)
				t_scale = ([dpc.x[idx],reverse(dpc.x[idx])]-tvinfo.settings.time_offset)/tvinfo.settings.time_scale
				nx = data_to_normal(t_scale,tvinfo.settings.x)
				ny = data_to_normal([dpc.y[idx,0]+dpc.dy[idx,0],reverse(dpc.y[idx,0]-dpc.dy[idx,0])],tvinfo.settings.y[pidx])
				polyfill,nx,ny,color=color,/normal,clip=pos,noclip=0

        ; For vector variables
				if (dims.length gt 1) then begin
					for j=1,dims[1]-1 do begin
						ny = data_to_normal([dpc.y[idx,j]+dpc.dy[idx,j],reverse(dpc.y[idx,j]-dpc.dy[idx,j])],tvinfo.settings.y[pidx])
						polyfill,nx,ny,color=color,/normal,clip=pos,noclip=0
					endfor
				endif
			endif
		endfor
		
	; Handle cases with separate High and Low DY
	endif else if isa(d,'STRUCT') && tag_exist(d,'dyL') && tag_exist(d,'dyH') then begin
    ; Make gaps only have 1 NaN between points
    ;TODO - could the 2 sided DY data be mis-matched? I hope not - why would that be?
    ;If so, another round of simple_gap will need to be added.
	  x = d.x
	  y = d.y
	  dyL = d.dyL
	  dyH = d.dyH
	  keep = simple_gaps(y[*,0])  ; Simplify on main data gaps
	  x = x[keep]
	  y = y[keep,*]
	  dyL = dyL[keep,*]
	  dyH = dyH[keep,*]

	  keep = simple_gaps(dyL[*,0])  ; Simplify on DY data gaps
	  x = x[keep]
	  y = y[keep,*]
    dyL = dyL[keep,*]
    dyH = dyH[keep,*]
	  d = {x:x, y:y, dyL:dyL, dyH:dyH}
	  dg = where(~finite(dyL[*,0]),dgcount)

    ; Plot a shaded polygon for each separate segment
	  for pc = 0,dgcount do begin
	    if dgcount eq 0 then begin
	      dpc = d
	    endif else begin
	      ix0 = (pc eq 0) ? 0 : dg[pc-1]+1
	      ix1 = (pc eq dgcount) ? n_elements(d.x)-1 : dg[pc]-1
	      dpc = {x:d.x[ix0:ix1], y:d.y[ix0:ix1,*], dyL:d.dyL[ix0:ix1,*], dyH:d.dyH[ix0:ix1,*]}
	    endelse

	    xrange = tvinfo.settings.x.crange + tvinfo.settings.time_offset
	    idx = where(dpc.x ge xrange[0] and dpc.x le xrange[1], count)
	    if count gt 1 then begin
	      dims = size(dpc.y,/dim)
	      t_scale = ([dpc.x[idx],reverse(dpc.x[idx])]-tvinfo.settings.time_offset)/tvinfo.settings.time_scale
	      nx = data_to_normal(t_scale,tvinfo.settings.x)
	      ny = data_to_normal([dpc.y[idx,0]+dpc.dyH[idx,0],reverse(dpc.y[idx,0]-dpc.dyL[idx,0])],tvinfo.settings.y[pidx])
	      polyfill,nx,ny,color=color,/normal,clip=pos,noclip=0

	      ; For vector variables
	      if (dims.length gt 1) then begin
	        for j=1,dims[1]-1 do begin
	          ny = data_to_normal([dpc.y[idx,j]+dpc.dyH[idx,j],reverse(dpc.y[idx,j]-dpc.dyL[idx,j])],tvinfo.settings.y[pidx])
	          polyfill,nx,ny,color=color,/normal,clip=pos,noclip=0
	        endfor
	      endif
	    endif
	  endfor
	endif
  device,decomposed=decomp
END


PRO PSP_DYPLOT,NEW_DYINFO=new_dyinfo,TVINFO=tvinfo,POS=pos,PANEL=panel,WINDOW=w,FORCE=force, $
	VERBOSE=verbose,OLD_DYINFO=old_dyinfo

	COMPILE_OPT IDL2
	
	@tplot_com.pro
	
	if (isa(old_dyinfo) && ~tag_exist(old_dyinfo,'empty')) then begin
		if tag_exist(old_dyinfo,'tvinfo') then  tvinfo  = old_dyinfo.tvinfo
		if tag_exist(old_dyinfo,'pos') then     pos     = old_dyinfo.pos
		if tag_exist(old_dyinfo,'panel') then   panel   = old_dyinfo.panel
		if tag_exist(old_dyinfo,'window') then  w       = old_dyinfo.window
		if tag_exist(old_dyinfo,'force') then   force   = old_dyinfo.force
		if tag_exist(old_dyinfo,'verbose') then verbose = old_dyinfo.verbose
	endif
	
	new_dyinfo = {}
	if isa(tvinfo) then str_element,new_dyinfo,'tvinfo',tvinfo,/add_rep
	if isa(pos) then str_element,new_dyinfo,'pos',pos,/add_rep
	if isa(panel) then str_element,new_dyinfo,'panel',panel,/add_rep
	if isa(w) then str_element,new_dyinfo,'window',w,/add_rep
	if isa(verbose) then str_element,new_dyinfo,'verbose',verbose,/add_rep
	if isa(force) then str_element,new_dyinfo,'force',force,/add_rep
	if ~isa(new_dyinfo) then str_element,new_dyinfo,'empty',1,/add_rep

	psp_swp_init
	rname = (scope_traceback(/structure))[1].routine
	if not isa(verbose,/int) then verbose=!psp_sweap.verbose

	catch, err
	if err ne 0 then begin
		if err eq -539 then begin
			dprint,dlevel=1,verbose=verbose,rname+': Invalid TPLOT Window reference. A TPLOT window must be open before calling this procedure.'
		endif else dprint,dlevel=1,verbose=verbose,rname+': Error in psp_dyplot. Exiting.'
		catch,/cancel
		return
	endif
	
	if ~keyword_set(tvinfo) then tvinfo=tplot_vars
	np = n_elements(tvinfo.options.varnames)

	if (w ne !null) then wset,w $
		else if tag_exist(tvinfo.options,'window') then wset,tvinfo.options.window
	if ~keyword_set(pos) then begin
		pos = fltarr(4,np)
		xw = tvinfo.settings.x.window
		yw = tvinfo.settings.y.window
		pos[0,*] = tvinfo.settings.x.window[0]
		pos[1,*] = tvinfo.settings.y.window[0,*]
		pos[2,*] = tvinfo.settings.x.window[1]
		pos[3,*] = tvinfo.settings.y.window[1,*]
	endif

	if (panel eq !null) then panel=indgen(np) else panel = panel-1
	if max(panel) ge np then begin
		dprint,dlevel=1,verbose=verbose,rname+': bad panel number'
		return
	endif

	for i=0,n_elements(panel)-1 do begin
		meta = {init:0}
		get_data,tvinfo.options.varnames[panel[i]],data=d,alimit=alimit
		extract_tags,meta,alimit,tags=['psp_dy','datagap']
		if isa(d,/STRING,/ARRAY) then begin
			foreach varname,d do begin
				localtags = {}
				get_data,varname,data=vardata,alimit=varlimit
				extract_tags,localtags,varlimit,tags=['psp_dy','datagap']
				extract_tags,localtags,meta
				drawpanel = keyword_set(force) ? 1 : (tag_exist(localtags,'psp_dy')) ? localtags.psp_dy : 0
				if drawpanel then psp_dysingle,vardata,localtags,tvinfo,pos[*,panel[i]],panel[i]
			endforeach
		endif else if isa(d,'STRUCT') then begin
			drawpanel = keyword_set(force) ? 1 : (tag_exist(meta,'psp_dy')) ? meta.psp_dy : 0
			if drawpanel then psp_dysingle,d,meta,tvinfo,pos[*,panel[i]],panel[i]
		endif
	endfor
	tplot,/oplot,old_tvars=tvinfo
END
