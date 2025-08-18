;+
;NAME: DSC_DYPLOT
;
;DESCRIPTION:
; Plot a shaded area showing confidence range where avaialable.
; Will look for tplot variable options tags 
;   dsc_dy: 0 - do not show dy interval
;           1 - show dy interval if available
;   dsc_dycolor: (int) Colortable reference for dy fill color
;
;INPUT:
;
;KEYWORDS: (Optional)   
; COLOR=:  TEMPORARILY DISABLED. CURRENTLY COLOR IS IGNORED AND ALL PLOTS USE THE DEFAULT GRAY.
;          Set to desired fill color. (int or int array)  Will override any options set in the dlimits/limits
;             structures.  If not set will reference the 'dsc_dycolor' variable option or
;             choose a reasonable default.
; FORCE:    Set to ignore the 'dsc_dy' tag setting and show the DY for all requested panels if DY available		
; NEW_DYINFO=: (output) Named variable to hold the keyword settings passed to this call of the routine
; OLD_DYINFO=: Set to a structure containing keywords to this routine. Will supercede any other keywords set.
; PANEL=:   Array of indices describing which panels for which to draw confidence. (1 indexed like TPLOT)
;             If this is not set the routine will attempt to draw confidence for all panels.
; POS=:     4xn array describing the positions of each of the n panels in the plot of interest.
;             Defaults to the positions found in the 'tplot_vars' structure.										
; TVINFO=:  Structure containing TPLOT variables information - as returned
;             from the 'new_tvar' keyword to tplot. 
;             If not set uses that found in common 'tplot_vars'
; VERBOSE=: Integer indicating the desired verbosity level.  Defaults to !dsc.verbose
; WINDOW=:  Which direct graphics window to target for this polyfill. (int)
;             This is gererally not needed if plotting on an existing tplot window. Will default
;             to whatever is set by the TVINFO structure being used.
;					
;CREATED BY: Ayris Narock (ADNET/GSFC) 2017
;
; $LastChangedBy: nikos $
; $LastChangedDate: 2018-03-12 09:55:28 -0700 (Mon, 12 Mar 2018) $
; $LastChangedRevision: 24869 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/dscovr/plot/dsc_dyplot.pro $
;-

PRO DSC_DYSINGLE,d,meta,tvinfo,pos,pidx,color
	compile_opt idl2
	if isa(d,'STRUCT') && tag_exist(d,'dy') then begin
		if tag_exist(meta,'datagap') then begin
			x = d.x
			y = d.y
			dy = d.dy
			makegap,meta.datagap,x,y,dy=dy
			dg = where(~finite(y[*,0]),dgcount)
			if dgcount gt 0 then d = {x:x, y:y, dy:dy}
		endif else dgcount = 0

		device,get_decomposed = decomp
		device,/decomposed
		color = 'c8c8c8'x
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
				polyfill,nx,ny,color=color[0],/normal,clip=pos,noclip=0

				if (dims.length gt 1) then begin
					ncolors = color.length
					for j=1,dims[1]-1 do begin
						ny = data_to_normal([dpc.y[idx,j]+dpc.dy[idx,j],reverse(dpc.y[idx,j]-dpc.dy[idx,j])],tvinfo.settings.y[pidx])
						polyfill,nx,ny,color=color[(j mod ncolors)],/normal,clip=pos,noclip=0
					endfor
				endif
			endif
		endfor
		device,decomposed=decomp
	endif
END


PRO DSC_DYCMPND,d,meta,tvinfo,pos,pidx,color
	compile_opt IDL2
	
	get_data,d[0],data=d1_all  ;+DY
	get_data,d[-1],data=d2_all ;-DY

	if tag_exist(meta,'datagap') then begin
		x1 = d1_all.x
		y1 = d1_all.y
		x2 = d2_all.x
		y2 = d2_all.y
		makegap,meta.datagap,x1,y1
		makegap,meta.datagap,x2,y2
		dg = where(~finite(y1[*,0]),dgcount)
		if dgcount gt 0 then begin
			d1_all = {x:x1, y:y1}
			d2_all = {x:x2, y:y2}
		endif
	endif else dgcount = 0

	device,get_decomposed = decomp
	device,/decomposed
	color = 'c8c8c8'x
	for pc = 0,dgcount do begin
		if dgcount eq 0 then begin
			d1 = d1_all
			d2 = d2_all
		endif else begin
			ix0 = (pc eq 0) ? 0 : dg[pc-1]+1
			ix1 = (pc eq dgcount) ? n_elements(x)-1 : dg[pc]-1
			d1 = {x:d1_all.x[ix0:ix1], y:d1_all.y[ix0:ix1,*]}
			d2 = {x:d2_all.x[ix0:ix1], y:d2_all.y[ix0:ix1,*]}
		endelse

		xrange = tvinfo.settings.x.crange + tvinfo.settings.time_offset
		idx = where(d1.x ge xrange[0] and d1.x le xrange[1], count)
		if count gt 1 then begin
			dims = size(d1.y,/dim)
			t_scale = ([d1.x[idx],reverse(d2.x[idx])]-tvinfo.settings.time_offset)/tvinfo.settings.time_scale
			nx = data_to_normal(t_scale,tvinfo.settings.x)
			ny = data_to_normal([d1.y[idx,0],reverse(d2.y[idx,0])],tvinfo.settings.y[pidx])
			polyfill,nx,ny,color=color[0],/normal,clip=pos,noclip=0

			if (dims.length gt 1) then begin
				ncolors = color.length
				for j=1,dims[1]-1 do begin
					ny = data_to_normal([d1.y[idx,j],reverse(d2.y[idx,j])],tvinfo.settings.y[pidx])
					polyfill,nx,ny,color=color[(j mod ncolors)],/normal,clip=pos,noclip=0
				endfor
			endif
		endif
	endfor
	device,decomposed=decomp
END


PRO DSC_DYPLOT,NEW_DYINFO=new_dyinfo,TVINFO=tvinfo,POS=pos,PANEL=panel,WINDOW=w,COLOR=cf,FORCE=force, $
	VERBOSE=verbose,OLD_DYINFO=old_dyinfo

	COMPILE_OPT IDL2
	
	@tplot_com.pro
	
	if (isa(old_dyinfo) && ~tag_exist(old_dyinfo,'empty')) then begin
		if tag_exist(old_dyinfo,'tvinfo') then  tvinfo  = old_dyinfo.tvinfo
		if tag_exist(old_dyinfo,'pos') then     pos     = old_dyinfo.pos
		if tag_exist(old_dyinfo,'panel') then   panel   = old_dyinfo.panel
		if tag_exist(old_dyinfo,'window') then  w       = old_dyinfo.window
		if tag_exist(old_dyinfo,'color') then   cf      = old_dyinfo.color
		if tag_exist(old_dyinfo,'force') then   force   = old_dyinfo.force
		if tag_exist(old_dyinfo,'verbose') then verbose = old_dyinfo.verbose
	endif
	
	new_dyinfo = {}
	if isa(tvinfo) then str_element,new_dyinfo,'tvinfo',tvinfo,/add_rep
	if isa(pos) then str_element,new_dyinfo,'pos',pos,/add_rep
	if isa(panel) then str_element,new_dyinfo,'panel',panel,/add_rep
	if isa(w) then str_element,new_dyinfo,'window',w,/add_rep
	if isa(cf) then str_element,new_dyinfo,'color',cf,/add_rep
	if isa(verbose) then str_element,new_dyinfo,'verbose',verbose,/add_rep
	if isa(force) then str_element,new_dyinfo,'force',force,/add_rep
	if ~isa(new_dyinfo) then str_element,new_dyinfo,'empty',1,/add_rep

	dsc_init
	rname = dsc_getrname()
	if not isa(verbose,/int) then verbose=!dsc.verbose

	catch, err
	if err ne 0 then begin
		if err eq -539 then begin
			dprint,dlevel=1,verbose=verbose,rname+': Invalid TPLOT Window reference. A TPLOT window must be open before calling this procedure.'
		endif else dprint,dlevel=1,verbose=verbose,rname+': Error in dsc_dyplot. Exiting.'
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

	if (cf ne !null) then begin
		color=cf 
		cf = 1
	endif else cf=0
	
	for i=0,n_elements(panel)-1 do begin
		meta = {init:0}
		get_data,tvinfo.options.varnames[panel[i]],data=d,alimit=alimit
		extract_tags,meta,alimit,tags=['dsc_dy','dsc_dycolor','datagap']
		if isa(d,/STRING,/ARRAY) then begin
			if d[0].Matches('\+DY') then begin  ; string => DY combo variable of 2 or 3 elements
				drawpanel = keyword_set(force) ? 1 : (tag_exist(meta,'dsc_dy')) ? meta.dsc_dy : 0
				if drawpanel then begin
					if ~cf then color = (tag_exist(meta,'dsc_dycolor')) ? meta.dsc_dycolor : 3
					dsc_dycmpnd,d,meta,tvinfo,pos[*,panel[i]],panel[i],color
				endif
			endif else begin
				foreach varname,d do begin
					localtags = {}
					get_data,varname,data=vardata,alimit=varlimit
					extract_tags,localtags,varlimit,tags=['dsc_dy','dsc_dycolor','datagap']
					extract_tags,localtags,meta
					drawpanel = keyword_set(force) ? 1 : (tag_exist(localtags,'dsc_dy')) ? localtags.dsc_dy : 0
					if drawpanel then begin
						if ~cf then color = (tag_exist(localtags,'dsc_dycolor')) ? localtags.dsc_dycolor : 3
						dsc_dysingle,vardata,localtags,tvinfo,pos[*,panel[i]],panel[i],color
					endif
				endforeach
			endelse
		endif else if isa(d,'STRUCT') then begin
			drawpanel = keyword_set(force) ? 1 : (tag_exist(meta,'dsc_dy')) ? meta.dsc_dy : 0
			if drawpanel then begin
				if ~cf then color = (tag_exist(meta,'dsc_dycolor')) ? meta.dsc_dycolor : 3
				dsc_dysingle,d,meta,tvinfo,pos[*,panel[i]],panel[i],color
			endif
		endif
	endfor
	tplot,/oplot,old_tvars=tvinfo
END
