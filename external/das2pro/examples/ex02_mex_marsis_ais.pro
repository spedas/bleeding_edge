; program to get and print a few Mars Express Ionograms


pro ex02_mex_marsis_ais
	compile_opt idl2

	; Generate the URL for the desired subset, we'll use a low-level
	; function for now, as catalog lookup is not yet implemented.
	sServer = 'http://planet.physics.uiowa.edu/das/das2Server'
	sDataset = 'Mars_Express/MARSIS/Spectrogram'
	sMin = '2005-08-06T00:52:09'
	sMax = '2005-08-06T00:52:17'
	sFmt = '(%"%s?server=dataset&dataset=%s&start_time=%s&end_time=%s")'
	sUrl = string(sServer, sDataset, sMin, sMax, format=sFmt)
	
	; Get datasets from a web server.  The sMsg varible will hold any
	; error or message data returned from the server.  Typically this
	; is empty unless an error occurs.
	sMsg = !null
	lDs = das2_readhttp(sUrl, messages=sMsg)
	
	if lDs.length eq 0 then begin
		printf, -2, sMsg
		stop
	endif

	print, n_elements(lDs), format="%d datesets read"

	; There is typically only one dataset for homogeneous streams
	ds = lDs[0]
		
	; Let's see what it contains
	print, ds
	
	;print, ' '
	;print, 'time', ds['time', 'center'].dshape()
	;print, 'frequency', ds['frequency','center'].dshape()
	;print, 'spectrum', ds['spectrum', 'center'].dshape()
	;print, ' '
	;print, (*(ds['spectrum','center'].values))[0,0]
	;print, (*(ds['spectrum','center'].values))[1,0]
	
	;print, ((ds['spectrum'])['center'])[0, 40]
	;print, (ds['spectrum', 'center'])[1, 40]
	
	; Test indexing, move this code to das2pro_ut.pro after das2_readfile() is
	; implemented.
	;print, (*(ds['spectrum','center'].values))[0:4,0]
	
	var = ds['spectrum','center']
	
	;print, var[0:4, 0]
	
	print, ds['spectrum','center', 0:4, 0]
	
	
	
end

