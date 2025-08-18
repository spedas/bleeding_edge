; Program to get and print a single Cassini Waveforms

pro ex01_cassini_rpws_wfrm
	compile_opt idl2
	
	; Generate the URL for the desired subset, we'll use a low-level
	; function for now, as catalog lookup is not yet implemented.

	sServer = 'http://planet.physics.uiowa.edu/das/das2Server'
	sDataSet = 'Cassini/RPWS/HiRes_MidFreq_Waveform'
	sBeg = '2004-11-15T00:40:50.400'
	sEnd = '2004-11-15T00:40:50.500'
	sParams = '10khz Ew=false'
	sFmt = '(%"%s?server=dataset&dataset=%s&start_time=%s&end_time=%s&params=%s")'
	sUrl = string(sServer, sDataset, sBeg, sEnd, sParams, format=sFmt)

	; Get the dataset
	lDs = das2_readhttp(sUrl, messages=sMsg)

	if lDs.length eq 0 then begin
		printf, -2, sMsg
		stop
	endif
	
	ds = lDs[0]
	print, n_elements(lDs), format='(%"%d datesets read, first dataset contains:")'
	print, ds
	
	xSampleTimes = ds['time','offset'].array
	xUnits = ds['time','offset'].units
	
	yWaveform = ds['WBR','center', *, 0]  ; Just get the first waveform
	yUnits = ds['WBR','center'].units
	
	xStartTime = ds['time','reference', 0] ; And the first reference time
	
	sTime = cdf_encode_tt2000(xStartTime, epoch=3)
	
	sXlabel = string(xUnits, sTime, format='(%"Time [%s] from %s")')
	sYlabel = ds['WBR'].props['label'].strval
	sTitle = ds.props['title'].strval
	
	p = plot($
		xSampleTimes, yWaveform, xtit=sXlabel, ytit=sYlabel, $
	   tit=sTitle, dimensions=[1200, 400], /buffer, xst=1 $
	)
	p.xthick = 2.
	p.ythick = 2.
	p.thick = 1.4
	p.font_size = 12
	p.tit.font_size = 12
	
	sFile = 'ex01_cassini_rpws_wfrm.png'
	p.save, sFile, width=1200, height=400, resolution=300
	
	print, 'Plot ', sFile, ' printed to the current directory'

end
