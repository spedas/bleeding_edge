
; Plot direction away from the planet in spacecraft coordinates

pro ex04_juno_attitude
	compile_opt idl2
	
	; Generate a URL for the desired subset, we'll use a low-level
	; function for now, as catalog lookup is not yet implemented.
	
	sServer = 'http://jupiter.physics.uiowa.edu/das/server'
	sDataSet='Juno/Ephemeris/Jupiter_Radial_SC'
	sBeg = '2017-02-02T12:58'
	sEnd = '2017-02-02T12:59'
	sInt = '0.5'
	sFmt = '(%"%s?server=dataset&dataset=%s&start_time=%s&end_time=%s&interval=%s")'
	sUrl = string(sServer, sDataset, sBeg, sEnd, sInt, format=sFmt)

	; Get the dataset
	lDs = das2_readhttp(sUrl, messages=sMsg)
	if lDs.length eq 0 then message, sMsg
	
	ds = lDs[0]
	print, n_elements(lDs), format='(%"%d datesets read, first dataset contains:")'
	print, ds
	
	; make one plot for each data dimension
	aKeys = ds.keys(/D)
	nPlots = n_elements(aKeys)
	rYSz = 0.9 / nPlots
	
	aPlots = make_array(nPlots, /OBJ)
	
	; das2pro autoconverts any time values to CDF TT2000, but we need 
	; julian days for the plot function
	aCoords = cdf_epoch_tojuldays( ds[ 'time','center'].array )
	
	void = label_date(date_format=['%Y-%N-%D']) ; Setup date labeler
	
	aColors = ['red','orange','green','cyan', 'blue','purple']
	
	for i = 0, nPlots - 1 do begin
		
		y0 = 0.96 - (rYSz * (i + 1))
		y1 = 0.96 - (rYSz * i  + rYSz*0.2)
				
		aData = ds[ aKeys[i], 'center'].array
		sYLbl = ds[ aKeys[i] ].props['label'].strval
	
		aPlots[i] = plot( /current, $ ;/buffer, $
			aCoords, aData, position=[0.11, y0, 0.91, y1], ytit=sYLbl, $
			xshowtext=0, color=aColors[i], thick=2, xtickunits='time', $
			xtickformat='label_date', xtickdir=1, ytickdir=1 $
		)
				
		if i eq 0 then aPlots[i].title = sDataSet + '!C' ; Title on top plot
		
		if i eq (nPlots - 1) then (aPlots[i])['axis0'].showtext = 1 ;label X				
	endfor
	
	;sFile = 'ex04_juno_attitude.png'
	;aPlots[0].save, sFile, width=800, height=800, resolution=300
	
	;print, 'Plot ', sFile, ' printed to the current directory'
	
end
	
