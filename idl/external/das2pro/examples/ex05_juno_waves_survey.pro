; Plot four section Juno Waves electric Survey data

pro ex05_juno_waves_survey
	compile_opt idl2
	
	; Generate a URL for the desired subset, we'll use a low-level
	; function for now, as catalog lookup is not yet implemented.
	sServer = 'http://jupiter.physics.uiowa.edu/das/server'
	sDataSet='Juno/WAV/Survey'
	sBeg = '2017-02-02'
	sEnd = '2017-02-03'
	
	; ask for 60 second time bins ... or see below
	sRes = '60.0'  
	sFmt = '(%"%s?server=dataset&dataset=%s&start_time=%s&end_time=%s&resolution=%s")'
	sUrl = string(sServer, sDataset, sBeg, sEnd, sRes, format=sFmt)
	
	; ...alternate version to get intrinsic resolution
	; sFmt = '%s?server=dataset&dataset=%s&start_time=%s&end_time=%s'
	; sUrl = string(sServer, sDataset, sBeg, sEnd, format=sFmt)
	
	; Get a list of datasets
	lDs = das2_readhttp(sUrl, messages=sMsg)
	if lDs.length eq 0 then message, sMsg
		
	ct = colortable(72, /reverse)	
	void = label_date(date_format=['%H:%M']) ; Setup the IDL date labeler
	
	for i = 0, lDs.length - 1 do begin
		dataset = lDs[3 - i]
		
		print, dataset  ; print info about each dataset in the request
		
		nOverPlot = 0
		if i gt 0 then nOverPlot = 1
		
		aX = cdf_epoch_tojuldays( dataset['time','center'].array )
		aY = dataset['frequency', 'center'].array
				
		aZ = alog10(dataset['spec_dens', 'center'].array)
	
		cont = contour( buffer=1 $
			, transpose(aZ), aX, aY, /fill, rgb_table=ct $
			, position=[0.11,0.1,0.8,0.9], n_levels=20, overplot=nOverPlot $
			, xstyle=1, ystyle=1, xtickdir=1, ytickdir=1, axis_style=2 $
			, xthick=2, ythick=2, xticklen=0.01, yticklen=0.01 $
			, font_size=10 $
		)
		
	endfor
	
	; add a color bar	
	cb = colorbar(target=cont, $
		orientation=1, position=[0.82, 0.1, 0.85, 0.9], $
		taper=0, /border, textpos=1, font_size=9, tickformat='(F5.1)' $
	)
	
	; fix up the plot a bit
	cont.title = string( sServer, sDataSet $
		, format='Juno Waves Electric Survey, Perijove 4!c!d %s, %s' $
	)
	ax = cont.axes
	ax[1].log = 1
	ax[0].tickunits='Hours'
	ax[0].title = string(sBeg, sEnd, format="SCET %s to %s")
	ax[1].title = dataset['frequency'].props['label'].value
	sZlbl = dataset['spec_dens'].props['label'].value
	cb.title = string(sZLbl, format="Electric Spectral Density log!b10!n (%s)")
	
	sFile = 'ex05_juno_waves_survey.png'
	cont.save, sFile, width=1024, height=720, resolution=300
	
	print, 'Plot ', sFile, ' printed to the current directory'
	
end
