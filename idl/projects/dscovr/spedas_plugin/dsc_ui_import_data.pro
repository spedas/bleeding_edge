;+
;NAME:
;  dsc_ui_import_data
;
;PURPOSE:
;  Modularized gui DSCOVR data loader
;
;
;CREATED BY: Ayris Narock (ADNET/GSFC) 2017
;
; $LastChangedBy: nikos $
; $LastChangedDate: 2018-03-12 09:55:28 -0700 (Mon, 12 Mar 2018) $
; $LastChangedRevision: 24869 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/dscovr/spedas_plugin/dsc_ui_import_data.pro $
;--------------------------------------------------------------------------------
pro dsc_ui_import_data,$
 loadStruc,$
 loadedData,$
 statusBar,$
 historyWin,$
 parent_widget_id,$  ;needed for appropriate layering and modality of popups
 replay=replay,$
 overwrite_selections=overwrite_selections ;allows replay of user overwrite selections from spedas 
												 

	compile_opt hidden,idl2

	dsc_init
	rname = dsc_getrname()
	instrument=loadStruc.instrument[0]
	datatype=loadStruc.datatype[0]
	parameters=loadStruc.parameters
	timeRange=loadStruc.timeRange
	loaded = 0

	new_vars = ''

	overwrite_selection=''
	overwrite_count =0

	if ~keyword_set(replay) then begin
		overwrite_selections = ''
	endif

	tn_before = [tnames('*',create_time=cn_before)]

	;select the appropriate dsc load routine
	par_names = []
	case instrument of
		'or':		begin
			dsc_load_or,trange=timeRange
			par_names = 'dsc_orbit_'+parameters
			end
		'att':	begin
			dsc_load_att,trange=timeRange
			ext = ['_Yaw','_Pitch','_Roll']
			parameters = parameters.Replace('Yaw/Pitch/Roll from ','')
			par_names = []
			foreach p,parameters do par_names = [par_names,'dsc_att_'+p+ext]
			end
		'mag':	begin
			dsc_load_mag,trange=timeRange
			par_names = 'dsc_'+datatype+'_mag_'+parameters
			end
		'fc':		begin
			dsc_load_fc,trange=timeRange
			par_names = $
				['dsc_'+datatype+'_fc_'+parameters, $
				 'dsc_'+datatype+'_fc_'+parameters+'+DY', $
				 'dsc_'+datatype+'_fc_'+parameters+'-DY']
			end
		else:  dprint,dlevel=1,verbose=!dsc.verbose,rname+': Error loading instrument: ',instrument
	endcase
		
	spd_ui_cleanup_tplot,tn_before,create_time_before=cn_before,del_vars=to_delete,new_vars=new_vars
	
	if new_vars[0] ne '' then begin
		;only add the requested new parameters
		new_vars = ssl_set_intersection([par_names],[new_vars])
		if instrument eq 'fc' then new_vars = reverse(new_vars) ;For easier select and plot value with +-DY
		loaded = 1
		;loop over loaded data
		for i = 0,n_elements(new_vars)-1 do begin
			
			if stregex(new_vars[i],'gse',/fold_case,/boolean) then begin
				coordSys = 'gse'
			endif else if stregex(new_vars[i],'gsm',/fold_case,/boolean) then begin
				coordSys = 'gsm'
			endif else if stregex(new_vars[i],'GCI',/fold_case,/boolean) then begin
				coordSys = 'gci'
			endif else if stregex(new_vars[i],'J2000',/fold_case,/boolean) then begin
				coordSys = 'j2000'
			endif else begin
				coordSys = ''
			endelse
		 
			;Check if data is already loaded, so that it can query user on whether they want to overwrite data
			dsc_ui_check_overwrite_data,new_vars[i],loadedData,parent_widget_id,statusBar,historyWin,overwrite_selection,overwrite_count,$
																 replay=replay,overwrite_selections=overwrite_selections,isnew=isnew
			if (strmid(overwrite_selection, 0, 2) eq 'no') and (~isnew) then continue

			result = loadedData->add(new_vars[i],mission='DSCOVR',observatory='DSCOVR',instrument=instrument,coordSys=coordSys,added_name=added_name,component_names=component_names)

			; Add deltas where available
;			iplus = where(to_delete eq new_vars[i]+'+DY',countplus)
;			iminus = where(to_delete eq new_vars[i]+'-DY',countminus)
;			if (countplus eq 1) and (countminus eq 1) then begin
;				deltaname = [to_delete[iplus],to_delete[iminus]]
;				dprint,dlevel=2, verbose=!dsc.verbose, format='((A),": Adding ", (A), " and ", (A), " to data group")',rname,deltaname[0],deltaname[1]
;				if (n_elements(component_names) gt 1) then begin		;Vector quantity loaded - load as separate group for clarity
;					foreach delname,deltaname do begin
;						res = loadedData->add(delname,mission='DSCOVR',observatory='DSCOVR',instrument=instrument,coordSys=coordSys)
;					endforeach
;				endif else begin		; Scalar quantity loaded
;					group = loadedData.getGroup(added_name)
;					referenceObj = loadedData.getObjects(name=added_name+'_data')
;					referenceObj->getProperty,yaxisName = yaxisName
;					referenceObj->getProperty,timeName = timeName
;					referenceObj->getProperty,yaxisUnits = yaxisUnits
;
;					foreach delname,deltaname do begin
;						get_data, delname, data=d,limits=l,dlimits=dl
;						deltaObj = obj_new('spd_ui_data',delname) ;;?does this get a dataID in loadedData?
;						dsettings = obj_new('spd_ui_data_settings',delname,0)
;						dsettings->fromLimits,l,dl
;
;						dataPtr = ptr_new(d.y)
;						limitPtr = ptr_new(l)
;						dlimitPtr = ptr_new(dl)
;
;						deltaObj->setProperty, $
;							dataPtr=dataPtr, $
;							dlimitPtr=dlimitPtr, $
;							limitPtr=limitPtr,$
;							yaxisName = yaxisName, $ ;added_name+'_yaxis', $
;							mission='DSCOVR',$
;							observatory='DSCOVR',$
;							coordSys=coordSys,$
;							instrument=instrument,$
;							timeName=timeName, $
;							yaxisUnits=yaxisUnits,$
;							settings=dsettings
;
;						group->add,delname,deltaObj
;					endforeach
;				endelse
;			endif   
			
			if ~result then begin
				statusBar->update,'Error loading: ' + new_vars[i]
				historyWin->update,'DSCOVR: Error loading: ' + new_vars[i]
				return
			endif
		endfor
	endif
		
	if n_elements(to_delete) gt 0 && is_string(to_delete) then begin
		store_data,to_delete,/delete
	endif
		 
	if loaded eq 1 then begin
		statusBar->update,'DSCOVR Data Loaded Successfully'
		historyWin->update,'DSCOVR Data Loaded Successfully'
	endif else begin
		statusBar->update,'No DSCOVR Data Loaded.  Data may not be available during this time interval.'
		historyWin->update,'No DSCOVR Data Loaded.  Data may not be available during this time interval.'    
	endelse

end
