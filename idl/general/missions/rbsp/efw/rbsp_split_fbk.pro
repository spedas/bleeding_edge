;+
; NAME:	rbsp_split_fbk
;
;
; PURPOSE:	Split the filterbank data into separate tplot variables for 
;			each channel. Can also combine peak and average on a single panel         
;
; KEYWORDS:
;	probe = 'a' or 'b'  NOTE: single spacecraft only, does not accept ['a b']
;	combine -> set to combine peak and average onto a single plot
;	meansz -> number of data points over which to calculate the number of values
;			  the local mean is away from the local standard deviation. This is used
;			  to set y-scaling. If not done then the yscale of the FBK plots
;			  is often dominated by single large amplitude spikes, masking the majority
;			  of the data.  Default is 100.
;;	meansz -> number of data points over which to calculate the mean. This is used
;;			  to set y-scaling. If not done then the yscale of the FBK plots
;;			  is often dominated by single large amplitude spikes, masking the majority
;;			  of the data.  Default is 20.
;;	ysc -> Scale factor for y-scaling. Default is 1.  This should be set to
;;			values greater than 1 for meansz larger than the default.  For
;;			example, ysc=3. works well for meansz=1000.
;
; CREATED: Aaron Breneman 11/07/2012
;
; MODIFIED: changed y-scaling based on a running average rather than the max value
;			for each FBK channel. This avoids having a ridiculous yscaling based on a few 
;			very large amplitude spiky events. 
;
; VERSION:
;$LastChangedBy: aaronbreneman $
;$LastChangedDate: 2014-04-21 13:19:06 -0700 (Mon, 21 Apr 2014) $
;$LastChangedRevision: 14901 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/missions/rbsp/efw/rbsp_split_fbk.pro $
;
;-



pro rbsp_split_fbk,probe,combine=combine,meansz=sz,verbose=verbose,ysc=ysc


	vb = keyword_set(verbose) ? verbose : 0
	vb = vb > !rbsp_efw.verbose
	start_time=systime(1)
	
	fbk13_bins=['0.8-1.5', '1.5-3', '3-6', '6-12', '12-25', '25-50', $
				'50-100', '100-200', '200-400', '400-800', $
				'0.8-1.6', '1.6-3.2', '3.2-6.5']
	fbk7_bins=fbk13_bins[lindgen(7)*2]
	



	;Determine ylim based on the mean value. Doing this avoids large y-scalings
	;based on very spiky FBK data
	if ~keyword_set(sz) then sz = 100.
;	if ~keyword_set(ysc) then ysc=1.

	;the ratio of the local value of the peak FBK value divided by the standard deviation
	if ~keyword_set(maxrat) then maxrat = 30


;grab dlimits structure for each of the channels to determine the source
	get_data,'rbsp'+probe+'_efw_fbk_7_fb1_pk',dlimits=fb7_fb1
	get_data,'rbsp'+probe+'_efw_fbk_7_fb2_pk',dlimits=fb7_fb2
	get_data,'rbsp'+probe+'_efw_fbk_13_fb1_pk',dlimits=fb13_fb1
	get_data,'rbsp'+probe+'_efw_fbk_13_fb2_pk',dlimits=fb13_fb2
	
	

	get_data,'rbsp'+probe +'_efw_fbk_13_fb1_pk',data=goo,dlimits=dlim
	tst = size(goo,/dimensions)
	if tst ne 0 then begin
		store_data,'rbsp'+probe +'_fbk1_13pk_0',data={x:goo.x,y:goo.y[*,0]}
		store_data,'rbsp'+probe +'_fbk1_13pk_1',data={x:goo.x,y:goo.y[*,1]}
		store_data,'rbsp'+probe +'_fbk1_13pk_2',data={x:goo.x,y:goo.y[*,2]}
		store_data,'rbsp'+probe +'_fbk1_13pk_3',data={x:goo.x,y:goo.y[*,3]}
		store_data,'rbsp'+probe +'_fbk1_13pk_4',data={x:goo.x,y:goo.y[*,4]}
		store_data,'rbsp'+probe +'_fbk1_13pk_5',data={x:goo.x,y:goo.y[*,5]}
		store_data,'rbsp'+probe +'_fbk1_13pk_6',data={x:goo.x,y:goo.y[*,6]}
		store_data,'rbsp'+probe +'_fbk1_13pk_7',data={x:goo.x,y:goo.y[*,7]}
		store_data,'rbsp'+probe +'_fbk1_13pk_8',data={x:goo.x,y:goo.y[*,8]}
		store_data,'rbsp'+probe +'_fbk1_13pk_9',data={x:goo.x,y:goo.y[*,9]}
		store_data,'rbsp'+probe +'_fbk1_13pk_10',data={x:goo.x,y:goo.y[*,10]}
		store_data,'rbsp'+probe +'_fbk1_13pk_11',data={x:goo.x,y:goo.y[*,11]}
		store_data,'rbsp'+probe +'_fbk1_13pk_12',data={x:goo.x,y:goo.y[*,12]}

		units = dlim.data_att.units		

		options,'rbsp'+probe +'_fbk1_13pk_0','ytitle','pk!C'+fbk13_bins[0]+'!CHz!C['+units+']'
		options,'rbsp'+probe +'_fbk1_13pk_1','ytitle','pk!C'+fbk13_bins[1]+'!CHz!C['+units+']'
		options,'rbsp'+probe +'_fbk1_13pk_2','ytitle','pk!C'+fbk13_bins[2]+'!CHz!C['+units+']'
		options,'rbsp'+probe +'_fbk1_13pk_3','ytitle','pk!C'+fbk13_bins[3]+'!CHz!C['+units+']'
		options,'rbsp'+probe +'_fbk1_13pk_4','ytitle','pk!C'+fbk13_bins[4]+'!CHz!C['+units+']'
		options,'rbsp'+probe +'_fbk1_13pk_5','ytitle','pk!C'+fbk13_bins[5]+'!CHz!C['+units+']'
		options,'rbsp'+probe +'_fbk1_13pk_6','ytitle','pk!C'+fbk13_bins[6]+'!CHz!C['+units+']'
		options,'rbsp'+probe +'_fbk1_13pk_7','ytitle','pk!C'+fbk13_bins[7]+'!CHz!C['+units+']'
		options,'rbsp'+probe +'_fbk1_13pk_8','ytitle','pk!C'+fbk13_bins[8]+'!CHz!C['+units+']'
		options,'rbsp'+probe +'_fbk1_13pk_9','ytitle','pk!C'+fbk13_bins[9]+'!CHz!C['+units+']'
		options,'rbsp'+probe +'_fbk1_13pk_10','ytitle','pk!C'+fbk13_bins[10]+'!CkHz!C['+units+']'
		options,'rbsp'+probe +'_fbk1_13pk_11','ytitle','pk!C'+fbk13_bins[11]+'!CkHz!C['+units+']'
		options,'rbsp'+probe +'_fbk1_13pk_12','ytitle','pk!C'+fbk13_bins[12]+'!CkHz!C['+units+']'

		options,'rbsp'+probe +'_fbk1_13??_*','labels','RBSP'+probe+'!C  '+fb13_fb1.data_att.channel
		
	
	endif
	
	get_data,'rbsp'+probe +'_efw_fbk_13_fb2_pk',data=goo,dlimits=dlim
	tst = size(goo,/dimensions)
	if tst ne 0 then begin
		store_data,'rbsp'+probe +'_fbk2_13pk_0',data={x:goo.x,y:goo.y[*,0]}
		store_data,'rbsp'+probe +'_fbk2_13pk_1',data={x:goo.x,y:goo.y[*,1]}
		store_data,'rbsp'+probe +'_fbk2_13pk_2',data={x:goo.x,y:goo.y[*,2]}
		store_data,'rbsp'+probe +'_fbk2_13pk_3',data={x:goo.x,y:goo.y[*,3]}
		store_data,'rbsp'+probe +'_fbk2_13pk_4',data={x:goo.x,y:goo.y[*,4]}
		store_data,'rbsp'+probe +'_fbk2_13pk_5',data={x:goo.x,y:goo.y[*,5]}
		store_data,'rbsp'+probe +'_fbk2_13pk_6',data={x:goo.x,y:goo.y[*,6]}
		store_data,'rbsp'+probe +'_fbk2_13pk_7',data={x:goo.x,y:goo.y[*,7]}
		store_data,'rbsp'+probe +'_fbk2_13pk_8',data={x:goo.x,y:goo.y[*,8]}
		store_data,'rbsp'+probe +'_fbk2_13pk_9',data={x:goo.x,y:goo.y[*,9]}
		store_data,'rbsp'+probe +'_fbk2_13pk_10',data={x:goo.x,y:goo.y[*,10]}
		store_data,'rbsp'+probe +'_fbk2_13pk_11',data={x:goo.x,y:goo.y[*,11]}
		store_data,'rbsp'+probe +'_fbk2_13pk_12',data={x:goo.x,y:goo.y[*,12]}
		

		units = dlim.data_att.units


		options,'rbsp'+probe +'_fbk2_13pk_0','ytitle','pk!C'+fbk13_bins[0]+'!CHz!C['+units+']'
		options,'rbsp'+probe +'_fbk2_13pk_1','ytitle','pk!C'+fbk13_bins[1]+'!CHz!C['+units+']'
		options,'rbsp'+probe +'_fbk2_13pk_2','ytitle','pk!C'+fbk13_bins[2]+'!CHz!C['+units+']'
		options,'rbsp'+probe +'_fbk2_13pk_3','ytitle','pk!C'+fbk13_bins[3]+'!CHz!C['+units+']'
		options,'rbsp'+probe +'_fbk2_13pk_4','ytitle','pk!C'+fbk13_bins[4]+'!CHz!C['+units+']'
		options,'rbsp'+probe +'_fbk2_13pk_5','ytitle','pk!C'+fbk13_bins[5]+'!CHz!C['+units+']'
		options,'rbsp'+probe +'_fbk2_13pk_6','ytitle','pk!C'+fbk13_bins[6]+'!CHz!C['+units+']'
		options,'rbsp'+probe +'_fbk2_13pk_7','ytitle','pk!C'+fbk13_bins[7]+'!CHz!C['+units+']'
		options,'rbsp'+probe +'_fbk2_13pk_8','ytitle','pk!C'+fbk13_bins[8]+'!CHz!C['+units+']'
		options,'rbsp'+probe +'_fbk2_13pk_9','ytitle','pk!C'+fbk13_bins[9]+'!CHz!C['+units+']'
		options,'rbsp'+probe +'_fbk2_13pk_10','ytitle','pk!C'+fbk13_bins[10]+'!CkHz!C['+units+']'
		options,'rbsp'+probe +'_fbk2_13pk_11','ytitle','pk!C'+fbk13_bins[11]+'!CkHz!C['+units+']'
		options,'rbsp'+probe +'_fbk2_13pk_12','ytitle','pk!C'+fbk13_bins[12]+'!CkHz!C['+units+']'


		options,'rbsp'+probe +'_fbk2_13??_*','labels','RBSP'+probe+'!C  '+fb13_fb2.data_att.channel

	
	
	endif
	
	get_data,'rbsp'+probe +'_efw_fbk_7_fb1_pk',data=goo,dlimits=dlim
	tst = size(goo,/dimensions)
	if tst ne 0 then begin
		store_data,'rbsp'+probe +'_fbk1_7pk_0',data={x:goo.x,y:goo.y[*,0]}
		store_data,'rbsp'+probe +'_fbk1_7pk_1',data={x:goo.x,y:goo.y[*,1]}
		store_data,'rbsp'+probe +'_fbk1_7pk_2',data={x:goo.x,y:goo.y[*,2]}
		store_data,'rbsp'+probe +'_fbk1_7pk_3',data={x:goo.x,y:goo.y[*,3]}
		store_data,'rbsp'+probe +'_fbk1_7pk_4',data={x:goo.x,y:goo.y[*,4]}
		store_data,'rbsp'+probe +'_fbk1_7pk_5',data={x:goo.x,y:goo.y[*,5]}
		store_data,'rbsp'+probe +'_fbk1_7pk_6',data={x:goo.x,y:goo.y[*,6]}
		
		units = dlim.data_att.units

	
		options,'rbsp'+probe +'_fbk1_7pk_0','ytitle','pk!C'+fbk7_bins[0]+'!CHz!C['+units+']'
		options,'rbsp'+probe +'_fbk1_7pk_1','ytitle','pk!C'+fbk7_bins[1]+'!CHz!C['+units+']'
		options,'rbsp'+probe +'_fbk1_7pk_2','ytitle','pk!C'+fbk7_bins[2]+'!CHz!C['+units+']'
		options,'rbsp'+probe +'_fbk1_7pk_3','ytitle','pk!C'+fbk7_bins[3]+'!CHz!C['+units+']'
		options,'rbsp'+probe +'_fbk1_7pk_4','ytitle','pk!C'+fbk7_bins[4]+'!CHz!C['+units+']'
		options,'rbsp'+probe +'_fbk1_7pk_5','ytitle','pk!C'+fbk7_bins[5]+'!CkHz!C['+units+']'
		options,'rbsp'+probe +'_fbk1_7pk_6','ytitle','pk!C'+fbk7_bins[6]+'!CkHz!C['+units+']'

	
		options,'rbsp'+probe +'_fbk1_7??_*','labels','RBSP'+probe+'!C  '+fb7_fb1.data_att.channel


	
	endif
	
	get_data,'rbsp'+probe +'_efw_fbk_7_fb2_pk',data=goo,dlimits=dlim
	tst = size(goo,/dimensions)
	if tst ne 0 then begin
		store_data,'rbsp'+probe +'_fbk2_7pk_0',data={x:goo.x,y:goo.y[*,0]}
		store_data,'rbsp'+probe +'_fbk2_7pk_1',data={x:goo.x,y:goo.y[*,1]}
		store_data,'rbsp'+probe +'_fbk2_7pk_2',data={x:goo.x,y:goo.y[*,2]}
		store_data,'rbsp'+probe +'_fbk2_7pk_3',data={x:goo.x,y:goo.y[*,3]}
		store_data,'rbsp'+probe +'_fbk2_7pk_4',data={x:goo.x,y:goo.y[*,4]}
		store_data,'rbsp'+probe +'_fbk2_7pk_5',data={x:goo.x,y:goo.y[*,5]}
		store_data,'rbsp'+probe +'_fbk2_7pk_6',data={x:goo.x,y:goo.y[*,6]}

		units = dlim.data_att.units
		
		options,'rbsp'+probe +'_fbk2_7pk_0','ytitle','pk!C'+fbk7_bins[0]+'!CHz!C['+units+']'
		options,'rbsp'+probe +'_fbk2_7pk_1','ytitle','pk!C'+fbk7_bins[1]+'!CHz!C['+units+']'
		options,'rbsp'+probe +'_fbk2_7pk_2','ytitle','pk!C'+fbk7_bins[2]+'!CHz!C['+units+']'
		options,'rbsp'+probe +'_fbk2_7pk_3','ytitle','pk!C'+fbk7_bins[3]+'!CHz!C['+units+']'
		options,'rbsp'+probe +'_fbk2_7pk_4','ytitle','pk!C'+fbk7_bins[4]+'!CHz!C['+units+']'
		options,'rbsp'+probe +'_fbk2_7pk_5','ytitle','pk!C'+fbk7_bins[5]+'!CkHz!C['+units+']'
		options,'rbsp'+probe +'_fbk2_7pk_6','ytitle','pk!C'+fbk7_bins[6]+'!CkHz!C['+units+']'


		options,'rbsp'+probe +'_fbk2_7??_*','labels','RBSP'+probe+'!C  '+fb7_fb2.data_att.channel

	
	endif
	
	get_data,'rbsp'+probe +'_efw_fbk_13_fb1_av',data=goo,dlimits=dlim
	tst = size(goo,/dimensions)
	if tst ne 0 then begin
		store_data,'rbsp'+probe +'_fbk1_13av_0',data={x:goo.x,y:goo.y[*,0]}
		store_data,'rbsp'+probe +'_fbk1_13av_1',data={x:goo.x,y:goo.y[*,1]}
		store_data,'rbsp'+probe +'_fbk1_13av_2',data={x:goo.x,y:goo.y[*,2]}
		store_data,'rbsp'+probe +'_fbk1_13av_3',data={x:goo.x,y:goo.y[*,3]}
		store_data,'rbsp'+probe +'_fbk1_13av_4',data={x:goo.x,y:goo.y[*,4]}
		store_data,'rbsp'+probe +'_fbk1_13av_5',data={x:goo.x,y:goo.y[*,5]}
		store_data,'rbsp'+probe +'_fbk1_13av_6',data={x:goo.x,y:goo.y[*,6]}
		store_data,'rbsp'+probe +'_fbk1_13av_7',data={x:goo.x,y:goo.y[*,7]}
		store_data,'rbsp'+probe +'_fbk1_13av_8',data={x:goo.x,y:goo.y[*,8]}
		store_data,'rbsp'+probe +'_fbk1_13av_9',data={x:goo.x,y:goo.y[*,9]}
		store_data,'rbsp'+probe +'_fbk1_13av_10',data={x:goo.x,y:goo.y[*,10]}
		store_data,'rbsp'+probe +'_fbk1_13av_11',data={x:goo.x,y:goo.y[*,11]}
		store_data,'rbsp'+probe +'_fbk1_13av_12',data={x:goo.x,y:goo.y[*,12]}
		
		units = dlim.data_att.units


		options,'rbsp'+probe +'_fbk1_13av_0','ytitle','av!C'+fbk13_bins[0]+'!CHz!C['+units+']'
		options,'rbsp'+probe +'_fbk1_13av_1','ytitle','av!C'+fbk13_bins[1]+'!CHz!C['+units+']'
		options,'rbsp'+probe +'_fbk1_13av_2','ytitle','av!C'+fbk13_bins[2]+'!CHz!C['+units+']'
		options,'rbsp'+probe +'_fbk1_13av_3','ytitle','av!C'+fbk13_bins[3]+'!CHz!C['+units+']'
		options,'rbsp'+probe +'_fbk1_13av_4','ytitle','av!C'+fbk13_bins[4]+'!CHz!C['+units+']'
		options,'rbsp'+probe +'_fbk1_13av_5','ytitle','av!C'+fbk13_bins[5]+'!CHz!C['+units+']'
		options,'rbsp'+probe +'_fbk1_13av_6','ytitle','av!C'+fbk13_bins[6]+'!CHz!C['+units+']'
		options,'rbsp'+probe +'_fbk1_13av_7','ytitle','av!C'+fbk13_bins[7]+'!CHz!C['+units+']'
		options,'rbsp'+probe +'_fbk1_13av_8','ytitle','av!C'+fbk13_bins[8]+'!CHz!C['+units+']'
		options,'rbsp'+probe +'_fbk1_13av_9','ytitle','av!C'+fbk13_bins[9]+'!CHz!C['+units+']'
		options,'rbsp'+probe +'_fbk1_13av_10','ytitle','av!C'+fbk13_bins[10]+'!CHkz!C['+units+']'
		options,'rbsp'+probe +'_fbk1_13av_11','ytitle','av!C'+fbk13_bins[11]+'!CkHz!C['+units+']'
		options,'rbsp'+probe +'_fbk1_13av_12','ytitle','av!C'+fbk13_bins[12]+'!CkHz!C['+units+']'


		options,'rbsp'+probe +'_fbk1_13??_*','labels','RBSP'+probe+'!C  '+fb13_fb1.data_att.channel
	
	endif
	
	get_data,'rbsp'+probe +'_efw_fbk_13_fb2_av',data=goo,dlimits=dlim
	tst = size(goo,/dimensions)
	if tst ne 0 then begin
		store_data,'rbsp'+probe +'_fbk2_13av_0',data={x:goo.x,y:goo.y[*,0]}
		store_data,'rbsp'+probe +'_fbk2_13av_1',data={x:goo.x,y:goo.y[*,1]}
		store_data,'rbsp'+probe +'_fbk2_13av_2',data={x:goo.x,y:goo.y[*,2]}
		store_data,'rbsp'+probe +'_fbk2_13av_3',data={x:goo.x,y:goo.y[*,3]}
		store_data,'rbsp'+probe +'_fbk2_13av_4',data={x:goo.x,y:goo.y[*,4]}
		store_data,'rbsp'+probe +'_fbk2_13av_5',data={x:goo.x,y:goo.y[*,5]}
		store_data,'rbsp'+probe +'_fbk2_13av_6',data={x:goo.x,y:goo.y[*,6]}
		store_data,'rbsp'+probe +'_fbk2_13av_7',data={x:goo.x,y:goo.y[*,7]}
		store_data,'rbsp'+probe +'_fbk2_13av_8',data={x:goo.x,y:goo.y[*,8]}
		store_data,'rbsp'+probe +'_fbk2_13av_9',data={x:goo.x,y:goo.y[*,9]}
		store_data,'rbsp'+probe +'_fbk2_13av_10',data={x:goo.x,y:goo.y[*,10]}
		store_data,'rbsp'+probe +'_fbk2_13av_11',data={x:goo.x,y:goo.y[*,11]}
		store_data,'rbsp'+probe +'_fbk2_13av_12',data={x:goo.x,y:goo.y[*,12]}
		
		units = dlim.data_att.units

		options,'rbsp'+probe +'_fbk2_13av_0','ytitle','av!C'+fbk13_bins[0]+'!CHz!C['+units+']'
		options,'rbsp'+probe +'_fbk2_13av_1','ytitle','av!C'+fbk13_bins[1]+'!CHz!C['+units+']'
		options,'rbsp'+probe +'_fbk2_13av_2','ytitle','av!C'+fbk13_bins[2]+'!CHz!C['+units+']'
		options,'rbsp'+probe +'_fbk2_13av_3','ytitle','av!C'+fbk13_bins[3]+'!CHz!C['+units+']'
		options,'rbsp'+probe +'_fbk2_13av_4','ytitle','av!C'+fbk13_bins[4]+'!CHz!C['+units+']'
		options,'rbsp'+probe +'_fbk2_13av_5','ytitle','av!C'+fbk13_bins[5]+'!CHz!C['+units+']'
		options,'rbsp'+probe +'_fbk2_13av_6','ytitle','av!C'+fbk13_bins[6]+'!CHz!C['+units+']'
		options,'rbsp'+probe +'_fbk2_13av_7','ytitle','av!C'+fbk13_bins[7]+'!CHz!C['+units+']'
		options,'rbsp'+probe +'_fbk2_13av_8','ytitle','av!C'+fbk13_bins[8]+'!CHz!C['+units+']'
		options,'rbsp'+probe +'_fbk2_13av_9','ytitle','av!C'+fbk13_bins[9]+'!CHz!C['+units+']'
		options,'rbsp'+probe +'_fbk2_13av_10','ytitle','av!C'+fbk13_bins[10]+'!CkHz!C['+units+']'
		options,'rbsp'+probe +'_fbk2_13av_11','ytitle','av!C'+fbk13_bins[11]+'!CkHz!C['+units+']'
		options,'rbsp'+probe +'_fbk2_13av_12','ytitle','av!C'+fbk13_bins[12]+'!CkHz!C['+units+']'

		options,'rbsp'+probe +'_fbk2_13??_*','labels','RBSP'+probe+'!C  '+fb13_fb2.data_att.channel

		
	endif
	
	get_data,'rbsp'+probe +'_efw_fbk_7_fb1_av',data=goo,dlimits=dlim
	tst = size(goo,/dimensions)
	if tst ne 0 then begin
		store_data,'rbsp'+probe +'_fbk1_7av_0',data={x:goo.x,y:goo.y[*,0]}
		store_data,'rbsp'+probe +'_fbk1_7av_1',data={x:goo.x,y:goo.y[*,1]}
		store_data,'rbsp'+probe +'_fbk1_7av_2',data={x:goo.x,y:goo.y[*,2]}
		store_data,'rbsp'+probe +'_fbk1_7av_3',data={x:goo.x,y:goo.y[*,3]}
		store_data,'rbsp'+probe +'_fbk1_7av_4',data={x:goo.x,y:goo.y[*,4]}
		store_data,'rbsp'+probe +'_fbk1_7av_5',data={x:goo.x,y:goo.y[*,5]}
		store_data,'rbsp'+probe +'_fbk1_7av_6',data={x:goo.x,y:goo.y[*,6]}
		
		units = dlim.data_att.units

		options,'rbsp'+probe +'_fbk1_7av_0','ytitle','av!C'+fbk7_bins[0]+'!CHz!C['+units+']'
		options,'rbsp'+probe +'_fbk1_7av_1','ytitle','av!C'+fbk7_bins[1]+'!CHz!C['+units+']'
		options,'rbsp'+probe +'_fbk1_7av_2','ytitle','av!C'+fbk7_bins[2]+'!CHz!C['+units+']'
		options,'rbsp'+probe +'_fbk1_7av_3','ytitle','av!C'+fbk7_bins[3]+'!CHz!C['+units+']'
		options,'rbsp'+probe +'_fbk1_7av_4','ytitle','av!C'+fbk7_bins[4]+'!CHz!C['+units+']'
		options,'rbsp'+probe +'_fbk1_7av_5','ytitle','av!C'+fbk7_bins[5]+'!CkHz!C['+units+']'
		options,'rbsp'+probe +'_fbk1_7av_6','ytitle','av!C'+fbk7_bins[6]+'!CkHz!C['+units+']'

		options,'rbsp'+probe +'_fbk1_7??_*','labels','RBSP'+probe+'!C  '+fb7_fb1.data_att.channel

	
	endif
	
	get_data,'rbsp'+probe +'_efw_fbk_7_fb2_av',data=goo,dlimits=dlim
	tst = size(goo,/dimensions)
	if tst ne 0 then begin
		store_data,'rbsp'+probe +'_fbk2_7av_0',data={x:goo.x,y:goo.y[*,0]}
		store_data,'rbsp'+probe +'_fbk2_7av_1',data={x:goo.x,y:goo.y[*,1]}
		store_data,'rbsp'+probe +'_fbk2_7av_2',data={x:goo.x,y:goo.y[*,2]}
		store_data,'rbsp'+probe +'_fbk2_7av_3',data={x:goo.x,y:goo.y[*,3]}
		store_data,'rbsp'+probe +'_fbk2_7av_4',data={x:goo.x,y:goo.y[*,4]}
		store_data,'rbsp'+probe +'_fbk2_7av_5',data={x:goo.x,y:goo.y[*,5]}
		store_data,'rbsp'+probe +'_fbk2_7av_6',data={x:goo.x,y:goo.y[*,6]}
		
		units = dlim.data_att.units

		options,'rbsp'+probe +'_fbk2_7av_0','ytitle','av!C'+fbk7_bins[0]+'!CHz!C['+units+']'
		options,'rbsp'+probe +'_fbk2_7av_1','ytitle','av!C'+fbk7_bins[1]+'!CHz!C['+units+']'
		options,'rbsp'+probe +'_fbk2_7av_2','ytitle','av!C'+fbk7_bins[2]+'!CHz!C['+units+']'
		options,'rbsp'+probe +'_fbk2_7av_3','ytitle','av!C'+fbk7_bins[3]+'!CHz!C['+units+']'
		options,'rbsp'+probe +'_fbk2_7av_4','ytitle','av!C'+fbk7_bins[4]+'!CHz!C['+units+']'
		options,'rbsp'+probe +'_fbk2_7av_5','ytitle','av!C'+fbk7_bins[5]+'!CkHz!C['+units+']'
		options,'rbsp'+probe +'_fbk2_7av_6','ytitle','av!C'+fbk7_bins[6]+'!CkHz!C['+units+']'


		options,'rbsp'+probe +'_fbk2_7??_*','labels','RBSP'+probe+'!C  '+fb7_fb2.data_att.channel


		
	endif
	
	
	
	if keyword_set(combine) then begin
	
		;Combine FBK pk and av quantities onto a single plot
	
	
		tst = tnames('rbsp'+probe +'_fbk1_13pk_0')
		if tst ne '' then begin
		
			store_data,'rbsp'+probe +'_fbk1_13comb_0',data=['rbsp'+probe +'_fbk1_13pk_0','rbsp'+probe +'_fbk1_13av_0']
			store_data,'rbsp'+probe +'_fbk1_13comb_1',data=['rbsp'+probe +'_fbk1_13pk_1','rbsp'+probe +'_fbk1_13av_1']
			store_data,'rbsp'+probe +'_fbk1_13comb_2',data=['rbsp'+probe +'_fbk1_13pk_2','rbsp'+probe +'_fbk1_13av_2']
			store_data,'rbsp'+probe +'_fbk1_13comb_3',data=['rbsp'+probe +'_fbk1_13pk_3','rbsp'+probe +'_fbk1_13av_3']
			store_data,'rbsp'+probe +'_fbk1_13comb_4',data=['rbsp'+probe +'_fbk1_13pk_4','rbsp'+probe +'_fbk1_13av_4']
			store_data,'rbsp'+probe +'_fbk1_13comb_5',data=['rbsp'+probe +'_fbk1_13pk_5','rbsp'+probe +'_fbk1_13av_5']
			store_data,'rbsp'+probe +'_fbk1_13comb_6',data=['rbsp'+probe +'_fbk1_13pk_6','rbsp'+probe +'_fbk1_13av_6']
			store_data,'rbsp'+probe +'_fbk1_13comb_7',data=['rbsp'+probe +'_fbk1_13pk_7','rbsp'+probe +'_fbk1_13av_7']
			store_data,'rbsp'+probe +'_fbk1_13comb_8',data=['rbsp'+probe +'_fbk1_13pk_8','rbsp'+probe +'_fbk1_13av_8']
			store_data,'rbsp'+probe +'_fbk1_13comb_9',data=['rbsp'+probe +'_fbk1_13pk_9','rbsp'+probe +'_fbk1_13av_9']
			store_data,'rbsp'+probe +'_fbk1_13comb_10',data=['rbsp'+probe +'_fbk1_13pk_10','rbsp'+probe +'_fbk1_13av_10']
			store_data,'rbsp'+probe +'_fbk1_13comb_11',data=['rbsp'+probe +'_fbk1_13pk_11','rbsp'+probe +'_fbk1_13av_11']
			store_data,'rbsp'+probe +'_fbk1_13comb_12',data=['rbsp'+probe +'_fbk1_13pk_12','rbsp'+probe +'_fbk1_13av_12']

			options,'rbsp'+probe +'_fbk1_13comb_*','labels','RBSP'+probe+'!C  '+fb13_fb1.data_att.channel


		endif		
		

		tst = tnames('rbsp'+probe +'_fbk2_13pk_0')
		if tst ne '' then begin
		
			store_data,'rbsp'+probe +'_fbk2_13comb_0',data=['rbsp'+probe +'_fbk2_13pk_0','rbsp'+probe +'_fbk2_13av_0']
			store_data,'rbsp'+probe +'_fbk2_13comb_1',data=['rbsp'+probe +'_fbk2_13pk_1','rbsp'+probe +'_fbk2_13av_1']
			store_data,'rbsp'+probe +'_fbk2_13comb_2',data=['rbsp'+probe +'_fbk2_13pk_2','rbsp'+probe +'_fbk2_13av_2']
			store_data,'rbsp'+probe +'_fbk2_13comb_3',data=['rbsp'+probe +'_fbk2_13pk_3','rbsp'+probe +'_fbk2_13av_3']
			store_data,'rbsp'+probe +'_fbk2_13comb_4',data=['rbsp'+probe +'_fbk2_13pk_4','rbsp'+probe +'_fbk2_13av_4']
			store_data,'rbsp'+probe +'_fbk2_13comb_5',data=['rbsp'+probe +'_fbk2_13pk_5','rbsp'+probe +'_fbk2_13av_5']
			store_data,'rbsp'+probe +'_fbk2_13comb_6',data=['rbsp'+probe +'_fbk2_13pk_6','rbsp'+probe +'_fbk2_13av_6']
			store_data,'rbsp'+probe +'_fbk2_13comb_7',data=['rbsp'+probe +'_fbk2_13pk_7','rbsp'+probe +'_fbk2_13av_7']
			store_data,'rbsp'+probe +'_fbk2_13comb_8',data=['rbsp'+probe +'_fbk2_13pk_8','rbsp'+probe +'_fbk2_13av_8']
			store_data,'rbsp'+probe +'_fbk2_13comb_9',data=['rbsp'+probe +'_fbk2_13pk_9','rbsp'+probe +'_fbk2_13av_9']
			store_data,'rbsp'+probe +'_fbk2_13comb_10',data=['rbsp'+probe +'_fbk2_13pk_10','rbsp'+probe +'_fbk2_13av_10']
			store_data,'rbsp'+probe +'_fbk2_13comb_11',data=['rbsp'+probe +'_fbk2_13pk_11','rbsp'+probe +'_fbk2_13av_11']
			store_data,'rbsp'+probe +'_fbk2_13comb_12',data=['rbsp'+probe +'_fbk2_13pk_12','rbsp'+probe +'_fbk2_13av_12']

			options,'rbsp'+probe +'_fbk2_13comb_*','labels','RBSP'+probe+'!C  '+fb13_fb2.data_att.channel

		
		endif		
		
		tst = tnames('rbsp'+probe +'_fbk1_7pk_0')
		if tst ne '' then begin
				
			store_data,'rbsp'+probe +'_fbk1_7comb_0',data=['rbsp'+probe +'_fbk1_7pk_0','rbsp'+probe +'_fbk1_7av_0']
			store_data,'rbsp'+probe +'_fbk1_7comb_1',data=['rbsp'+probe +'_fbk1_7pk_1','rbsp'+probe +'_fbk1_7av_1']
			store_data,'rbsp'+probe +'_fbk1_7comb_2',data=['rbsp'+probe +'_fbk1_7pk_2','rbsp'+probe +'_fbk1_7av_2']
			store_data,'rbsp'+probe +'_fbk1_7comb_3',data=['rbsp'+probe +'_fbk1_7pk_3','rbsp'+probe +'_fbk1_7av_3']
			store_data,'rbsp'+probe +'_fbk1_7comb_4',data=['rbsp'+probe +'_fbk1_7pk_4','rbsp'+probe +'_fbk1_7av_4']
			store_data,'rbsp'+probe +'_fbk1_7comb_5',data=['rbsp'+probe +'_fbk1_7pk_5','rbsp'+probe +'_fbk1_7av_5']
			store_data,'rbsp'+probe +'_fbk1_7comb_6',data=['rbsp'+probe +'_fbk1_7pk_6','rbsp'+probe +'_fbk1_7av_6']

			options,'rbsp'+probe +'_fbk1_7comb_*','labels','RBSP'+probe+'!C  '+fb7_fb1.data_att.channel



		endif
		
		tst = tnames('rbsp'+probe +'_fbk2_7pk_0')
		if tst ne '' then begin
		
			store_data,'rbsp'+probe +'_fbk2_7comb_0',data=['rbsp'+probe +'_fbk2_7pk_0','rbsp'+probe +'_fbk2_7av_0']
			store_data,'rbsp'+probe +'_fbk2_7comb_1',data=['rbsp'+probe +'_fbk2_7pk_1','rbsp'+probe +'_fbk2_7av_1']
			store_data,'rbsp'+probe +'_fbk2_7comb_2',data=['rbsp'+probe +'_fbk2_7pk_2','rbsp'+probe +'_fbk2_7av_2']
			store_data,'rbsp'+probe +'_fbk2_7comb_3',data=['rbsp'+probe +'_fbk2_7pk_3','rbsp'+probe +'_fbk2_7av_3']
			store_data,'rbsp'+probe +'_fbk2_7comb_4',data=['rbsp'+probe +'_fbk2_7pk_4','rbsp'+probe +'_fbk2_7av_4']
			store_data,'rbsp'+probe +'_fbk2_7comb_5',data=['rbsp'+probe +'_fbk2_7pk_5','rbsp'+probe +'_fbk2_7av_5']
			store_data,'rbsp'+probe +'_fbk2_7comb_6',data=['rbsp'+probe +'_fbk2_7pk_6','rbsp'+probe +'_fbk2_7av_6']
		
			options,'rbsp'+probe +'_fbk2_7comb_*','labels','RBSP'+probe+'!C  '+fb7_fb2.data_att.channel

		endif


		;Change colors to black and red

		tst = tnames('rbsp'+probe +'_fbk1_13comb_0')
		if tst ne '' then begin
			options,['rbsp'+probe+'_fbk1_13comb_0',$
					 'rbsp'+probe+'_fbk1_13comb_1',$
					 'rbsp'+probe+'_fbk1_13comb_2',$
					 'rbsp'+probe+'_fbk1_13comb_3',$
					 'rbsp'+probe+'_fbk1_13comb_4',$
					 'rbsp'+probe+'_fbk1_13comb_5',$
					 'rbsp'+probe+'_fbk1_13comb_6',$
					 'rbsp'+probe+'_fbk1_13comb_7',$
					 'rbsp'+probe+'_fbk1_13comb_8',$
					 'rbsp'+probe+'_fbk1_13comb_9',$
					 'rbsp'+probe+'_fbk1_13comb_10',$
					 'rbsp'+probe+'_fbk1_13comb_11',$
					 'rbsp'+probe+'_fbk1_13comb_12'],colors=[0,6]
		endif		

		tst = tnames('rbsp'+probe +'_fbk2_13comb_0')
		if tst ne '' then begin
		
			options,['rbsp'+probe+'_fbk2_13comb_0',$
					 'rbsp'+probe+'_fbk2_13comb_1',$
					 'rbsp'+probe+'_fbk2_13comb_2',$
					 'rbsp'+probe+'_fbk2_13comb_3',$
					 'rbsp'+probe+'_fbk2_13comb_4',$
					 'rbsp'+probe+'_fbk2_13comb_5',$
					 'rbsp'+probe+'_fbk2_13comb_6',$
					 'rbsp'+probe+'_fbk2_13comb_7',$
					 'rbsp'+probe+'_fbk2_13comb_8',$
					 'rbsp'+probe+'_fbk2_13comb_9',$
					 'rbsp'+probe+'_fbk2_13comb_10',$
					 'rbsp'+probe+'_fbk2_13comb_11',$
					 'rbsp'+probe+'_fbk2_13comb_12'],colors=[0,6]
		endif		
		
		tst = tnames('rbsp'+probe +'_fbk1_7comb_0')
		if tst ne '' then begin

			options,['rbsp'+probe+'_fbk1_7comb_0',$
					 'rbsp'+probe+'_fbk1_7comb_1',$
					 'rbsp'+probe+'_fbk1_7comb_2',$
					 'rbsp'+probe+'_fbk1_7comb_3',$
					 'rbsp'+probe+'_fbk1_7comb_4',$
					 'rbsp'+probe+'_fbk1_7comb_5',$
					 'rbsp'+probe+'_fbk1_7comb_6'],colors=[0,6]
		endif
		
		
		tst = tnames('rbsp'+probe +'_fbk2_7comb_0')
		if tst ne '' then begin

			options,['rbsp'+probe+'_fbk2_7comb_0',$
					 'rbsp'+probe+'_fbk2_7comb_1',$
					 'rbsp'+probe+'_fbk2_7comb_2',$
					 'rbsp'+probe+'_fbk2_7comb_3',$
					 'rbsp'+probe+'_fbk2_7comb_4',$
					 'rbsp'+probe+'_fbk2_7comb_5',$
					 'rbsp'+probe+'_fbk2_7comb_6'],colors=[0,6]
		endif		
				

	
		tst = tnames('rbsp'+probe +'_fbk1_13comb_0')
		get_data,'rbsp'+probe+'_efw_fbk_13_fb1_pk',dlimits=dlim,data=goo

		if tst ne '' then begin
			units = dlim.data_att.units

			options,'rbsp'+probe +'_fbk1_13comb_0','ytitle',fbk13_bins[0]+'!CHz!C['+units+']'
			options,'rbsp'+probe +'_fbk1_13comb_1','ytitle',fbk13_bins[1]+'!CHz!C['+units+']'
			options,'rbsp'+probe +'_fbk1_13comb_2','ytitle',fbk13_bins[2]+'!CHz!C['+units+']'
			options,'rbsp'+probe +'_fbk1_13comb_3','ytitle',fbk13_bins[3]+'!CHz!C['+units+']'
			options,'rbsp'+probe +'_fbk1_13comb_4','ytitle',fbk13_bins[4]+'!CHz!C['+units+']'
			options,'rbsp'+probe +'_fbk1_13comb_5','ytitle',fbk13_bins[5]+'!CHz!C['+units+']'
			options,'rbsp'+probe +'_fbk1_13comb_6','ytitle',fbk13_bins[6]+'!CHz!C['+units+']'
			options,'rbsp'+probe +'_fbk1_13comb_7','ytitle',fbk13_bins[7]+'!CHz!C['+units+']'
			options,'rbsp'+probe +'_fbk1_13comb_8','ytitle',fbk13_bins[8]+'!CHz!C['+units+']'
			options,'rbsp'+probe +'_fbk1_13comb_9','ytitle',fbk13_bins[9]+'!CHz!C['+units+']'
			options,'rbsp'+probe +'_fbk1_13comb_10','ytitle',fbk13_bins[10]+'!CkHz!C['+units+']'
			options,'rbsp'+probe +'_fbk1_13comb_11','ytitle',fbk13_bins[11]+'!CkHz!C['+units+']'
			options,'rbsp'+probe +'_fbk1_13comb_12','ytitle',fbk13_bins[12]+'!CkHz!C['+units+']'
		endif

	
		tst = tnames('rbsp'+probe +'_fbk2_13comb_0')
		get_data,'rbsp'+probe+'_efw_fbk_13_fb2_pk',dlimits=dlim,data=goo

		if tst ne '' then begin

			units = dlim.data_att.units

			options,'rbsp'+probe +'_fbk2_13comb_0','ytitle',fbk13_bins[0]+'!CHz!C['+units+']'
			options,'rbsp'+probe +'_fbk2_13comb_1','ytitle',fbk13_bins[1]+'!CHz!C['+units+']'
			options,'rbsp'+probe +'_fbk2_13comb_2','ytitle',fbk13_bins[2]+'!CHz!C['+units+']'
			options,'rbsp'+probe +'_fbk2_13comb_3','ytitle',fbk13_bins[3]+'!CHz!C['+units+']'
			options,'rbsp'+probe +'_fbk2_13comb_4','ytitle',fbk13_bins[4]+'!CHz!C['+units+']'
			options,'rbsp'+probe +'_fbk2_13comb_5','ytitle',fbk13_bins[5]+'!CHz!C['+units+']'
			options,'rbsp'+probe +'_fbk2_13comb_6','ytitle',fbk13_bins[6]+'!CHz!C['+units+']'
			options,'rbsp'+probe +'_fbk2_13comb_7','ytitle',fbk13_bins[7]+'!CHz!C['+units+']'
			options,'rbsp'+probe +'_fbk2_13comb_8','ytitle',fbk13_bins[8]+'!CHz!C['+units+']'
			options,'rbsp'+probe +'_fbk2_13comb_9','ytitle',fbk13_bins[9]+'!CHz!C['+units+']'
			options,'rbsp'+probe +'_fbk2_13comb_10','ytitle',fbk13_bins[10]+'!CkHz!C['+units+']'
			options,'rbsp'+probe +'_fbk2_13comb_11','ytitle',fbk13_bins[11]+'!CkHz!C['+units+']'
			options,'rbsp'+probe +'_fbk2_13comb_12','ytitle',fbk13_bins[12]+'!CkHz!C['+units+']'
		endif

	
		tst = tnames('rbsp'+probe +'_fbk1_7comb_0')
		get_data,'rbsp'+probe+'_efw_fbk_7_fb1_pk',dlimits=dlim,data=goo

		if tst ne '' then begin

			units = dlim.data_att.units

			options,'rbsp'+probe +'_fbk1_7comb_0','ytitle',fbk7_bins[0]+'!CHz!C['+units+']'
			options,'rbsp'+probe +'_fbk1_7comb_1','ytitle',fbk7_bins[1]+'!CHz!C['+units+']'
			options,'rbsp'+probe +'_fbk1_7comb_2','ytitle',fbk7_bins[2]+'!CHz!C['+units+']'
			options,'rbsp'+probe +'_fbk1_7comb_3','ytitle',fbk7_bins[3]+'!CHz!C['+units+']'
			options,'rbsp'+probe +'_fbk1_7comb_4','ytitle',fbk7_bins[4]+'!CHz!C['+units+']'
			options,'rbsp'+probe +'_fbk1_7comb_5','ytitle',fbk7_bins[5]+'!CkHz!C['+units+']'
			options,'rbsp'+probe +'_fbk1_7comb_6','ytitle',fbk7_bins[6]+'!CkHz!C['+units+']'
		endif
	
	
		tst = tnames('rbsp'+probe +'_fbk2_7comb_0')
		get_data,'rbsp'+probe+'_efw_fbk_7_fb2_pk',dlimits=dlim,data=goo

		if tst ne '' then begin

			units = dlim.data_att.units

			options,'rbsp'+probe +'_fbk2_7comb_0','ytitle',fbk7_bins[0]+'!CHz!C['+units+']'
			options,'rbsp'+probe +'_fbk2_7comb_1','ytitle',fbk7_bins[1]+'!CHz!C['+units+']'
			options,'rbsp'+probe +'_fbk2_7comb_2','ytitle',fbk7_bins[2]+'!CHz!C['+units+']'
			options,'rbsp'+probe +'_fbk2_7comb_3','ytitle',fbk7_bins[3]+'!CHz!C['+units+']'
			options,'rbsp'+probe +'_fbk2_7comb_4','ytitle',fbk7_bins[4]+'!CHz!C['+units+']'
			options,'rbsp'+probe +'_fbk2_7comb_5','ytitle',fbk7_bins[5]+'!CkHz!C['+units+']'
			options,'rbsp'+probe +'_fbk2_7comb_6','ytitle',fbk7_bins[6]+'!CkHz!C['+units+']'
		endif	
	
		
		

	endif	


;The number of y-ticks is usually too large when 7 or 13 plots are displayed at once. 
;Unfortunately reducing the tick numbers means that negative numbers show up. So, I have
;to manually set the yrange
options,'rbsp'+probe+'_fbk?_13pk_*','yticks',2
options,'rbsp'+probe+'_fbk?_7pk_*','yticks',2

;If yticks are manually set, yrange isn't set or is set to a range of zero (max=min),
;ystyle is set to 1, and the data is a horizontal line (max(y)=min(y)), then the IDL
;PLOT routine crashes. This next bit checks to see if any of the pk vars are horizontal
;lines, and if so, sets yticks to 0 (automatic) for that variable.
;--------------
pk13vars=tnames('rbsp'+probe+'_fbk1_13pk_*',cnt)
if cnt gt 0 then begin
	for i=0, n_elements(pk13vars)-1 do begin
		var=pk13vars[i]
		get_data,var,data=vardat
		if min(vardat.y) eq max(vardat.y) then $
		options,var,'yticks',0
	endfor
endif
pk13vars=tnames('rbsp'+probe+'_fbk2_13pk_*',cnt)
if cnt gt 0 then begin
	for i=0, n_elements(pk13vars)-1 do begin
		var=pk13vars[i]
		get_data,var,data=vardat
		if min(vardat.y) eq max(vardat.y) then $
		options,var,'yticks',0
	endfor
endif
pk7vars=tnames('rbsp'+probe+'_fbk1_7pk_*',cnt)
if cnt gt 0 then begin
	for i=0, n_elements(pk7vars)-1 do begin
		var=pk7vars[i]
		get_data,var,data=vardat
		if min(vardat.y) eq max(vardat.y) then $
		options,var,'yticks',0
	endfor
endif
pk7vars=tnames('rbsp'+probe+'_fbk2_7pk_*',cnt)
if cnt gt 0 then begin
	for i=0, n_elements(pk7vars)-1 do begin
		var=pk7vars[i]
		get_data,var,data=vardat
		if min(vardat.y) eq max(vardat.y) then $
		options,var,'yticks',0
	endfor
endif


;-----------------------------------------------
;Set ylimit and tick format based on keeping peak values within a certain number
;of standard deviations. Avoids having the scaling set by spiky noise
;-----------------------------------------------


;---------
;FBK1 - 13
;---------



tst = tnames('rbsp'+probe +'_fbk1_13pk_0')
if tst ne '' then begin
	get_data,'rbsp'+probe +'_fbk1_13pk_0',data=goo0
	get_data,'rbsp'+probe +'_fbk1_13pk_1',data=goo1
	get_data,'rbsp'+probe +'_fbk1_13pk_2',data=goo2
	get_data,'rbsp'+probe +'_fbk1_13pk_3',data=goo3
	get_data,'rbsp'+probe +'_fbk1_13pk_4',data=goo4
	get_data,'rbsp'+probe +'_fbk1_13pk_5',data=goo5
	get_data,'rbsp'+probe +'_fbk1_13pk_6',data=goo6
	get_data,'rbsp'+probe +'_fbk1_13pk_7',data=goo7
	get_data,'rbsp'+probe +'_fbk1_13pk_8',data=goo8
	get_data,'rbsp'+probe +'_fbk1_13pk_9',data=goo9
	get_data,'rbsp'+probe +'_fbk1_13pk_10',data=goo10
	get_data,'rbsp'+probe +'_fbk1_13pk_11',data=goo11
	get_data,'rbsp'+probe +'_fbk1_13pk_12',data=goo12


	nchunks = floor(n_elements(goo0.y)/sz)
	mom = fltarr(nchunks,13)
	maxv = fltarr(nchunks,13) ;peak values
	varv = fltarr(nchunks,13) ;variances

	ylim_start_time=systime(1)
	dmessage="using nchunks in fbk1_13pk: "+string(nchunks)
	dprint,verbose=verbose,dlevel=2,dmessage

	for i=0L,nchunks-1*sz do begin
	
		maxv[i,0] = max(goo0.y[i*sz:i*sz+sz])
		maxv[i,1] = max(goo1.y[i*sz:i*sz+sz])
		maxv[i,2] = max(goo2.y[i*sz:i*sz+sz])
		maxv[i,3] = max(goo3.y[i*sz:i*sz+sz])
		maxv[i,4] = max(goo4.y[i*sz:i*sz+sz])
		maxv[i,5] = max(goo5.y[i*sz:i*sz+sz])
		maxv[i,6] = max(goo6.y[i*sz:i*sz+sz])
		maxv[i,7] = max(goo7.y[i*sz:i*sz+sz])
		maxv[i,8] = max(goo8.y[i*sz:i*sz+sz])
		maxv[i,9] = max(goo9.y[i*sz:i*sz+sz])
		maxv[i,10] = max(goo10.y[i*sz:i*sz+sz])
		maxv[i,11] = max(goo11.y[i*sz:i*sz+sz])
		maxv[i,12] = max(goo12.y[i*sz:i*sz+sz])
	
		tst = moment(goo0.y[i*sz:i*sz+sz])
		varv[i,0] = sqrt(tst[1])
		tst = moment(goo1.y[i*sz:i*sz+sz])
		varv[i,1] = sqrt(tst[1])
		tst = moment(goo2.y[i*sz:i*sz+sz])
		varv[i,2] = sqrt(tst[1])
		tst = moment(goo3.y[i*sz:i*sz+sz])
		varv[i,3] = sqrt(tst[1])
		tst = moment(goo4.y[i*sz:i*sz+sz])
		varv[i,4] = sqrt(tst[1])
		tst = moment(goo5.y[i*sz:i*sz+sz])
		varv[i,5] = sqrt(tst[1])
		tst = moment(goo6.y[i*sz:i*sz+sz])
		varv[i,6] = sqrt(tst[1])
		tst = moment(goo7.y[i*sz:i*sz+sz])
		varv[i,7] = sqrt(tst[1])
		tst = moment(goo8.y[i*sz:i*sz+sz])
		varv[i,8] = sqrt(tst[1])
		tst = moment(goo9.y[i*sz:i*sz+sz])
		varv[i,9] = sqrt(tst[1])
		tst = moment(goo10.y[i*sz:i*sz+sz])
		varv[i,10] = sqrt(tst[1])
		tst = moment(goo11.y[i*sz:i*sz+sz])
		varv[i,11] = sqrt(tst[1])
		tst = moment(goo12.y[i*sz:i*sz+sz])
		varv[i,12] = sqrt(tst[1])
	
	
		mom[i,0]=total(goo0.y[i*sz:i*sz+sz])/sz
		mom[i,1]=total(goo1.y[i*sz:i*sz+sz])/sz
		mom[i,2]=total(goo2.y[i*sz:i*sz+sz])/sz
		mom[i,3]=total(goo3.y[i*sz:i*sz+sz])/sz
		mom[i,4]=total(goo4.y[i*sz:i*sz+sz])/sz
		mom[i,5]=total(goo5.y[i*sz:i*sz+sz])/sz
		mom[i,6]=total(goo6.y[i*sz:i*sz+sz])/sz
		mom[i,7]=total(goo7.y[i*sz:i*sz+sz])/sz
		mom[i,8]=total(goo8.y[i*sz:i*sz+sz])/sz
		mom[i,9]=total(goo9.y[i*sz:i*sz+sz])/sz
		mom[i,10]=total(goo10.y[i*sz:i*sz+sz])/sz
		mom[i,11]=total(goo11.y[i*sz:i*sz+sz])/sz
		mom[i,12]=total(goo12.y[i*sz:i*sz+sz])/sz
	endfor

	stdevv = sqrt(varv)
	
	ratio = maxv/stdevv

;q=11
;!p.multi = [0,0,4]
;plot,maxv[*,q]
;plot,mom[*,q]
;plot,stdevv[*,q]
;plot,maxv[*,q]/stdevv[*,q]


	;Reject values (for the y-scaling) where the max value is >> than the standard deviation
	good = bytarr(nchunks,13)
	good[*] = 1b

	goo = where(ratio[*,0] ge maxrat)
	if goo[0] ne -1 then good[goo,0] = 0b
	goo = where(ratio[*,1] ge maxrat)
	if goo[0] ne -1 then good[goo,1] = 0b
	goo = where(ratio[*,2] ge maxrat)
	if goo[0] ne -1 then good[goo,2] = 0b
	goo = where(ratio[*,3] ge maxrat)
	if goo[0] ne -1 then good[goo,3] = 0b
	goo = where(ratio[*,4] ge maxrat)
	if goo[0] ne -1 then good[goo,4] = 0b
	goo = where(ratio[*,5] ge maxrat)
	if goo[0] ne -1 then good[goo,5] = 0b
	goo = where(ratio[*,6] ge maxrat)
	if goo[0] ne -1 then good[goo,6] = 0b
	goo = where(ratio[*,7] ge maxrat)
	if goo[0] ne -1 then good[goo,7] = 0b
	goo = where(ratio[*,8] ge maxrat)
	if goo[0] ne -1 then good[goo,8] = 0b
	goo = where(ratio[*,9] ge maxrat)
	if goo[0] ne -1 then good[goo,9] = 0b
	goo = where(ratio[*,10] ge maxrat)
	if goo[0] ne -1 then good[goo,10] = 0b
	goo = where(ratio[*,11] ge maxrat)
	if goo[0] ne -1 then good[goo,11] = 0b
	goo = where(ratio[*,12] ge maxrat)
	if goo[0] ne -1 then good[goo,12] = 0b

	good = float(good)

	ylim,'rbsp'+probe +'_fbk1_13pk_0',0.,max(maxv[*,0]*good[*,0]),0
	ylim,'rbsp'+probe +'_fbk1_13pk_1',0.,max(maxv[*,1]*good[*,1]),0
	ylim,'rbsp'+probe +'_fbk1_13pk_2',0.,max(maxv[*,2]*good[*,2]),0
	ylim,'rbsp'+probe +'_fbk1_13pk_3',0.,max(maxv[*,3]*good[*,3]),0
	ylim,'rbsp'+probe +'_fbk1_13pk_4',0.,max(maxv[*,4]*good[*,4]),0
	ylim,'rbsp'+probe +'_fbk1_13pk_5',0.,max(maxv[*,5]*good[*,5]),0
	ylim,'rbsp'+probe +'_fbk1_13pk_6',0.,max(maxv[*,6]*good[*,6]),0
	ylim,'rbsp'+probe +'_fbk1_13pk_7',0.,max(maxv[*,7]*good[*,7]),0
	ylim,'rbsp'+probe +'_fbk1_13pk_8',0.,max(maxv[*,8]*good[*,8]),0
	ylim,'rbsp'+probe +'_fbk1_13pk_9',0.,max(maxv[*,9]*good[*,9]),0
	ylim,'rbsp'+probe +'_fbk1_13pk_10',0.,max(maxv[*,10]*good[*,10]),0
	ylim,'rbsp'+probe +'_fbk1_13pk_11',0.,max(maxv[*,11]*good[*,11]),0
	ylim,'rbsp'+probe +'_fbk1_13pk_12',0.,max(maxv[*,12]*good[*,12]),0

	
;	ylim,'rbsp'+probe +'_fbk1_13pk_0',0,ysc*max(mom[*,0])
;	ylim,'rbsp'+probe +'_fbk1_13pk_1',0,ysc*max(mom[*,1])
;	ylim,'rbsp'+probe +'_fbk1_13pk_2',0,ysc*max(mom[*,2])
;	ylim,'rbsp'+probe +'_fbk1_13pk_3',0,ysc*max(mom[*,3])
;	ylim,'rbsp'+probe +'_fbk1_13pk_4',0,ysc*max(mom[*,4])
;	ylim,'rbsp'+probe +'_fbk1_13pk_5',0,ysc*max(mom[*,5])
;	ylim,'rbsp'+probe +'_fbk1_13pk_6',0,ysc*max(mom[*,6])
;	ylim,'rbsp'+probe +'_fbk1_13pk_7',0,ysc*max(mom[*,7])
;	ylim,'rbsp'+probe +'_fbk1_13pk_8',0,ysc*max(mom[*,8])
;	ylim,'rbsp'+probe +'_fbk1_13pk_9',0,ysc*max(mom[*,9])
;	ylim,'rbsp'+probe +'_fbk1_13pk_10',0,ysc*max(mom[*,10])
;	ylim,'rbsp'+probe +'_fbk1_13pk_11',0,ysc*max(mom[*,11])
;	ylim,'rbsp'+probe +'_fbk1_13pk_12',0,ysc*max(mom[*,12])
	
	if keyword_set(combine) then begin
	
	
		ylim,'rbsp'+probe +'_fbk1_13comb_0',0,max(maxv[*,0]*good[*,0]),0
		ylim,'rbsp'+probe +'_fbk1_13comb_1',0,max(maxv[*,1]*good[*,1]),0
		ylim,'rbsp'+probe +'_fbk1_13comb_2',0,max(maxv[*,2]*good[*,2]),0
		ylim,'rbsp'+probe +'_fbk1_13comb_3',0,max(maxv[*,3]*good[*,3]),0
		ylim,'rbsp'+probe +'_fbk1_13comb_4',0,max(maxv[*,4]*good[*,4]),0
		ylim,'rbsp'+probe +'_fbk1_13comb_5',0,max(maxv[*,5]*good[*,5]),0
		ylim,'rbsp'+probe +'_fbk1_13comb_6',0,max(maxv[*,6]*good[*,6]),0
		ylim,'rbsp'+probe +'_fbk1_13comb_7',0,max(maxv[*,7]*good[*,7]),0
		ylim,'rbsp'+probe +'_fbk1_13comb_8',0,max(maxv[*,8]*good[*,8]),0
		ylim,'rbsp'+probe +'_fbk1_13comb_9',0,max(maxv[*,9]*good[*,9]),0
		ylim,'rbsp'+probe +'_fbk1_13comb_10',0,max(maxv[*,10]*good[*,10]),0
		ylim,'rbsp'+probe +'_fbk1_13comb_11',0,max(maxv[*,11]*good[*,11]),0
		ylim,'rbsp'+probe +'_fbk1_13comb_12',0,max(maxv[*,12]*good[*,12]),0
	
	
;		ylim,'rbsp'+probe +'_fbk1_13comb_0',0,ysc*max(mom[*,0])
;		ylim,'rbsp'+probe +'_fbk1_13comb_1',0,ysc*max(mom[*,1])
;		ylim,'rbsp'+probe +'_fbk1_13comb_2',0,ysc*max(mom[*,2])
;		ylim,'rbsp'+probe +'_fbk1_13comb_3',0,ysc*max(mom[*,3])
;		ylim,'rbsp'+probe +'_fbk1_13comb_4',0,ysc*max(mom[*,4])
;		ylim,'rbsp'+probe +'_fbk1_13comb_5',0,ysc*max(mom[*,5])
;		ylim,'rbsp'+probe +'_fbk1_13comb_6',0,ysc*max(mom[*,6])
;		ylim,'rbsp'+probe +'_fbk1_13comb_7',0,ysc*max(mom[*,7])
;		ylim,'rbsp'+probe +'_fbk1_13comb_8',0,ysc*max(mom[*,8])
;		ylim,'rbsp'+probe +'_fbk1_13comb_9',0,ysc*max(mom[*,9])
;		ylim,'rbsp'+probe +'_fbk1_13comb_10',0,ysc*max(mom[*,10])
;		ylim,'rbsp'+probe +'_fbk1_13comb_11',0,ysc*max(mom[*,11])
;		ylim,'rbsp'+probe +'_fbk1_13comb_12',0,ysc*max(mom[*,12])
	endif

	dmessage='ylim fbk1_13pk runtime (s): '+string(systime(1)-ylim_start_time)
	dprint,verbose=verbose,dlevel=2,dmessage


	;Keep only 1 number after decimal place. More just clutters up plot
	options,'rbsp'+probe +'_fbk1_13pk_0','ytickformat','(f6.1)'
	options,'rbsp'+probe +'_fbk1_13pk_1','ytickformat','(f6.1)'
	options,'rbsp'+probe +'_fbk1_13pk_2','ytickformat','(f6.1)'
	options,'rbsp'+probe +'_fbk1_13pk_3','ytickformat','(f6.1)'
	options,'rbsp'+probe +'_fbk1_13pk_4','ytickformat','(f6.1)'
	options,'rbsp'+probe +'_fbk1_13pk_5','ytickformat','(f6.1)'
	options,'rbsp'+probe +'_fbk1_13pk_6','ytickformat','(f6.1)'
	options,'rbsp'+probe +'_fbk1_13pk_7','ytickformat','(f6.1)'
	options,'rbsp'+probe +'_fbk1_13pk_8','ytickformat','(f6.1)'
	options,'rbsp'+probe +'_fbk1_13pk_9','ytickformat','(f6.1)'
	options,'rbsp'+probe +'_fbk1_13pk_10','ytickformat','(f6.1)'
	options,'rbsp'+probe +'_fbk1_13pk_11','ytickformat','(f6.1)'
	options,'rbsp'+probe +'_fbk1_13pk_12','ytickformat','(f6.1)'

endif

;---------
;FBK2 - 13
;---------


tst = tnames('rbsp'+probe +'_fbk2_13pk_0')
if tst ne '' then begin
	get_data,'rbsp'+probe +'_fbk2_13pk_0',data=goo0
	get_data,'rbsp'+probe +'_fbk2_13pk_1',data=goo1
	get_data,'rbsp'+probe +'_fbk2_13pk_2',data=goo2
	get_data,'rbsp'+probe +'_fbk2_13pk_3',data=goo3
	get_data,'rbsp'+probe +'_fbk2_13pk_4',data=goo4
	get_data,'rbsp'+probe +'_fbk2_13pk_5',data=goo5
	get_data,'rbsp'+probe +'_fbk2_13pk_6',data=goo6
	get_data,'rbsp'+probe +'_fbk2_13pk_7',data=goo7
	get_data,'rbsp'+probe +'_fbk2_13pk_8',data=goo8
	get_data,'rbsp'+probe +'_fbk2_13pk_9',data=goo9
	get_data,'rbsp'+probe +'_fbk2_13pk_10',data=goo10
	get_data,'rbsp'+probe +'_fbk2_13pk_11',data=goo11
	get_data,'rbsp'+probe +'_fbk2_13pk_12',data=goo12



	nchunks = floor(n_elements(goo0.y)/sz)
	mom = fltarr(nchunks,13)
	maxv = fltarr(nchunks,13) ;peak values
	varv = fltarr(nchunks,13) ;variances

	ylim_start_time=systime(1)
	dmessage="using nchunks in fbk1_13pk: "+string(nchunks)
	dprint,verbose=verbose,dlevel=2,dmessage

	for i=0L,nchunks-1*sz do begin
	
		maxv[i,0] = max(goo0.y[i*sz:i*sz+sz])
		maxv[i,1] = max(goo1.y[i*sz:i*sz+sz])
		maxv[i,2] = max(goo2.y[i*sz:i*sz+sz])
		maxv[i,3] = max(goo3.y[i*sz:i*sz+sz])
		maxv[i,4] = max(goo4.y[i*sz:i*sz+sz])
		maxv[i,5] = max(goo5.y[i*sz:i*sz+sz])
		maxv[i,6] = max(goo6.y[i*sz:i*sz+sz])
		maxv[i,7] = max(goo7.y[i*sz:i*sz+sz])
		maxv[i,8] = max(goo8.y[i*sz:i*sz+sz])
		maxv[i,9] = max(goo9.y[i*sz:i*sz+sz])
		maxv[i,10] = max(goo10.y[i*sz:i*sz+sz])
		maxv[i,11] = max(goo11.y[i*sz:i*sz+sz])
		maxv[i,12] = max(goo12.y[i*sz:i*sz+sz])
	
		tst = moment(goo0.y[i*sz:i*sz+sz])
		varv[i,0] = sqrt(tst[1])
		tst = moment(goo1.y[i*sz:i*sz+sz])
		varv[i,1] = sqrt(tst[1])
		tst = moment(goo2.y[i*sz:i*sz+sz])
		varv[i,2] = sqrt(tst[1])
		tst = moment(goo3.y[i*sz:i*sz+sz])
		varv[i,3] = sqrt(tst[1])
		tst = moment(goo4.y[i*sz:i*sz+sz])
		varv[i,4] = sqrt(tst[1])
		tst = moment(goo5.y[i*sz:i*sz+sz])
		varv[i,5] = sqrt(tst[1])
		tst = moment(goo6.y[i*sz:i*sz+sz])
		varv[i,6] = sqrt(tst[1])
		tst = moment(goo7.y[i*sz:i*sz+sz])
		varv[i,7] = sqrt(tst[1])
		tst = moment(goo8.y[i*sz:i*sz+sz])
		varv[i,8] = sqrt(tst[1])
		tst = moment(goo9.y[i*sz:i*sz+sz])
		varv[i,9] = sqrt(tst[1])
		tst = moment(goo10.y[i*sz:i*sz+sz])
		varv[i,10] = sqrt(tst[1])
		tst = moment(goo11.y[i*sz:i*sz+sz])
		varv[i,11] = sqrt(tst[1])
		tst = moment(goo12.y[i*sz:i*sz+sz])
		varv[i,12] = sqrt(tst[1])
	
	
		mom[i,0]=total(goo0.y[i*sz:i*sz+sz])/sz
		mom[i,1]=total(goo1.y[i*sz:i*sz+sz])/sz
		mom[i,2]=total(goo2.y[i*sz:i*sz+sz])/sz
		mom[i,3]=total(goo3.y[i*sz:i*sz+sz])/sz
		mom[i,4]=total(goo4.y[i*sz:i*sz+sz])/sz
		mom[i,5]=total(goo5.y[i*sz:i*sz+sz])/sz
		mom[i,6]=total(goo6.y[i*sz:i*sz+sz])/sz
		mom[i,7]=total(goo7.y[i*sz:i*sz+sz])/sz
		mom[i,8]=total(goo8.y[i*sz:i*sz+sz])/sz
		mom[i,9]=total(goo9.y[i*sz:i*sz+sz])/sz
		mom[i,10]=total(goo10.y[i*sz:i*sz+sz])/sz
		mom[i,11]=total(goo11.y[i*sz:i*sz+sz])/sz
		mom[i,12]=total(goo12.y[i*sz:i*sz+sz])/sz
	endfor

	stdevv = sqrt(varv)
	
	ratio = maxv/stdevv


	;Reject values (for the y-scaling) where the max value is >> than the standard deviation
	good = bytarr(nchunks,13)
	good[*] = 1b

	goo = where(ratio[*,0] ge maxrat)
	if goo[0] ne -1 then good[goo,0] = 0b
	goo = where(ratio[*,1] ge maxrat)
	if goo[0] ne -1 then good[goo,1] = 0b
	goo = where(ratio[*,2] ge maxrat)
	if goo[0] ne -1 then good[goo,2] = 0b
	goo = where(ratio[*,3] ge maxrat)
	if goo[0] ne -1 then good[goo,3] = 0b
	goo = where(ratio[*,4] ge maxrat)
	if goo[0] ne -1 then good[goo,4] = 0b
	goo = where(ratio[*,5] ge maxrat)
	if goo[0] ne -1 then good[goo,5] = 0b
	goo = where(ratio[*,6] ge maxrat)
	if goo[0] ne -1 then good[goo,6] = 0b
	goo = where(ratio[*,7] ge maxrat)
	if goo[0] ne -1 then good[goo,7] = 0b
	goo = where(ratio[*,8] ge maxrat)
	if goo[0] ne -1 then good[goo,8] = 0b
	goo = where(ratio[*,9] ge maxrat)
	if goo[0] ne -1 then good[goo,9] = 0b
	goo = where(ratio[*,10] ge maxrat)
	if goo[0] ne -1 then good[goo,10] = 0b
	goo = where(ratio[*,11] ge maxrat)
	if goo[0] ne -1 then good[goo,11] = 0b
	goo = where(ratio[*,12] ge maxrat)
	if goo[0] ne -1 then good[goo,12] = 0b

	good = float(good)

	ylim,'rbsp'+probe +'_fbk2_13pk_0',0.,max(maxv[*,0]*good[*,0]),0
	ylim,'rbsp'+probe +'_fbk2_13pk_1',0.,max(maxv[*,1]*good[*,1]),0
	ylim,'rbsp'+probe +'_fbk2_13pk_2',0.,max(maxv[*,2]*good[*,2]),0
	ylim,'rbsp'+probe +'_fbk2_13pk_3',0.,max(maxv[*,3]*good[*,3]),0
	ylim,'rbsp'+probe +'_fbk2_13pk_4',0.,max(maxv[*,4]*good[*,4]),0
	ylim,'rbsp'+probe +'_fbk2_13pk_5',0.,max(maxv[*,5]*good[*,5]),0
	ylim,'rbsp'+probe +'_fbk2_13pk_6',0.,max(maxv[*,6]*good[*,6]),0
	ylim,'rbsp'+probe +'_fbk2_13pk_7',0.,max(maxv[*,7]*good[*,7]),0
	ylim,'rbsp'+probe +'_fbk2_13pk_8',0.,max(maxv[*,8]*good[*,8]),0
	ylim,'rbsp'+probe +'_fbk2_13pk_9',0.,max(maxv[*,9]*good[*,9]),0
	ylim,'rbsp'+probe +'_fbk2_13pk_10',0.,max(maxv[*,10]*good[*,10]),0
	ylim,'rbsp'+probe +'_fbk2_13pk_11',0.,max(maxv[*,11]*good[*,11]),0
	ylim,'rbsp'+probe +'_fbk2_13pk_12',0.,max(maxv[*,12]*good[*,12]),0


	if keyword_set(combine) then begin	
	
		ylim,'rbsp'+probe +'_fbk2_13comb_0',0,max(maxv[*,0]*good[*,0]),0
		ylim,'rbsp'+probe +'_fbk2_13comb_1',0,max(maxv[*,1]*good[*,1]),0
		ylim,'rbsp'+probe +'_fbk2_13comb_2',0,max(maxv[*,2]*good[*,2]),0
		ylim,'rbsp'+probe +'_fbk2_13comb_3',0,max(maxv[*,3]*good[*,3]),0
		ylim,'rbsp'+probe +'_fbk2_13comb_4',0,max(maxv[*,4]*good[*,4]),0
		ylim,'rbsp'+probe +'_fbk2_13comb_5',0,max(maxv[*,5]*good[*,5]),0
		ylim,'rbsp'+probe +'_fbk2_13comb_6',0,max(maxv[*,6]*good[*,6]),0
		ylim,'rbsp'+probe +'_fbk2_13comb_7',0,max(maxv[*,7]*good[*,7]),0
		ylim,'rbsp'+probe +'_fbk2_13comb_8',0,max(maxv[*,8]*good[*,8]),0
		ylim,'rbsp'+probe +'_fbk2_13comb_9',0,max(maxv[*,9]*good[*,9]),0
		ylim,'rbsp'+probe +'_fbk2_13comb_10',0,max(maxv[*,10]*good[*,10]),0
		ylim,'rbsp'+probe +'_fbk2_13comb_11',0,max(maxv[*,11]*good[*,11]),0
		ylim,'rbsp'+probe +'_fbk2_13comb_12',0,max(maxv[*,12]*good[*,12]),0
	
	endif

	dmessage='ylim fbk2_13pk runtime (s): '+string(systime(1)-ylim_start_time)
	dprint,verbose=verbose,dlevel=2,dmessage



	;Keep only 1 number after decimal place. More just clutters up plot
	options,'rbsp'+probe +'_fbk2_13pk_0','ytickformat','(f6.1)'
	options,'rbsp'+probe +'_fbk2_13pk_1','ytickformat','(f6.1)'
	options,'rbsp'+probe +'_fbk2_13pk_2','ytickformat','(f6.1)'
	options,'rbsp'+probe +'_fbk2_13pk_3','ytickformat','(f6.1)'
	options,'rbsp'+probe +'_fbk2_13pk_4','ytickformat','(f6.1)'
	options,'rbsp'+probe +'_fbk2_13pk_5','ytickformat','(f6.1)'
	options,'rbsp'+probe +'_fbk2_13pk_6','ytickformat','(f6.1)'
	options,'rbsp'+probe +'_fbk2_13pk_7','ytickformat','(f6.1)'
	options,'rbsp'+probe +'_fbk2_13pk_8','ytickformat','(f6.1)'
	options,'rbsp'+probe +'_fbk2_13pk_9','ytickformat','(f6.1)'
	options,'rbsp'+probe +'_fbk2_13pk_10','ytickformat','(f6.1)'
	options,'rbsp'+probe +'_fbk2_13pk_11','ytickformat','(f6.1)'
	options,'rbsp'+probe +'_fbk2_13pk_12','ytickformat','(f6.1)'

endif



;---------
;FBK1 - 7
;---------


tst = tnames('rbsp'+probe +'_fbk1_7pk_0')
if tst ne '' then begin
	get_data,'rbsp'+probe +'_fbk1_7pk_0',data=goo0
	get_data,'rbsp'+probe +'_fbk1_7pk_1',data=goo1
	get_data,'rbsp'+probe +'_fbk1_7pk_2',data=goo2
	get_data,'rbsp'+probe +'_fbk1_7pk_3',data=goo3
	get_data,'rbsp'+probe +'_fbk1_7pk_4',data=goo4
	get_data,'rbsp'+probe +'_fbk1_7pk_5',data=goo5
	get_data,'rbsp'+probe +'_fbk1_7pk_6',data=goo6


	nchunks = floor(n_elements(goo0.y)/sz)
	mom = fltarr(nchunks,7)
	maxv = fltarr(nchunks,7) ;peak values
	varv = fltarr(nchunks,7) ;variances

	ylim_start_time=systime(1)
	dmessage="using nchunks in fbk1_13pk: "+string(nchunks)
	dprint,verbose=verbose,dlevel=2,dmessage

	for i=0L,nchunks-1*sz do begin
	
		maxv[i,0] = max(goo0.y[i*sz:i*sz+sz])
		maxv[i,1] = max(goo1.y[i*sz:i*sz+sz])
		maxv[i,2] = max(goo2.y[i*sz:i*sz+sz])
		maxv[i,3] = max(goo3.y[i*sz:i*sz+sz])
		maxv[i,4] = max(goo4.y[i*sz:i*sz+sz])
		maxv[i,5] = max(goo5.y[i*sz:i*sz+sz])
		maxv[i,6] = max(goo6.y[i*sz:i*sz+sz])
	
		tst = moment(goo0.y[i*sz:i*sz+sz])
		varv[i,0] = sqrt(tst[1])
		tst = moment(goo1.y[i*sz:i*sz+sz])
		varv[i,1] = sqrt(tst[1])
		tst = moment(goo2.y[i*sz:i*sz+sz])
		varv[i,2] = sqrt(tst[1])
		tst = moment(goo3.y[i*sz:i*sz+sz])
		varv[i,3] = sqrt(tst[1])
		tst = moment(goo4.y[i*sz:i*sz+sz])
		varv[i,4] = sqrt(tst[1])
		tst = moment(goo5.y[i*sz:i*sz+sz])
		varv[i,5] = sqrt(tst[1])
		tst = moment(goo6.y[i*sz:i*sz+sz])
		varv[i,6] = sqrt(tst[1])

	
		mom[i,0]=total(goo0.y[i*sz:i*sz+sz])/sz
		mom[i,1]=total(goo1.y[i*sz:i*sz+sz])/sz
		mom[i,2]=total(goo2.y[i*sz:i*sz+sz])/sz
		mom[i,3]=total(goo3.y[i*sz:i*sz+sz])/sz
		mom[i,4]=total(goo4.y[i*sz:i*sz+sz])/sz
		mom[i,5]=total(goo5.y[i*sz:i*sz+sz])/sz
		mom[i,6]=total(goo6.y[i*sz:i*sz+sz])/sz
	endfor

	stdevv = sqrt(varv)
	
	ratio = maxv/stdevv


	;Reject values (for the y-scaling) where the max value is >> than the standard deviation
	good = bytarr(nchunks,7)
	good[*] = 1b

	goo = where(ratio[*,0] ge maxrat)
	if goo[0] ne -1 then good[goo,0] = 0b
	goo = where(ratio[*,1] ge maxrat)
	if goo[0] ne -1 then good[goo,1] = 0b
	goo = where(ratio[*,2] ge maxrat)
	if goo[0] ne -1 then good[goo,2] = 0b
	goo = where(ratio[*,3] ge maxrat)
	if goo[0] ne -1 then good[goo,3] = 0b
	goo = where(ratio[*,4] ge maxrat)
	if goo[0] ne -1 then good[goo,4] = 0b
	goo = where(ratio[*,5] ge maxrat)
	if goo[0] ne -1 then good[goo,5] = 0b
	goo = where(ratio[*,6] ge maxrat)
	if goo[0] ne -1 then good[goo,6] = 0b

	good = float(good)

	ylim,'rbsp'+probe +'_fbk1_7pk_0',0.,max(maxv[*,0]*good[*,0]),0
	ylim,'rbsp'+probe +'_fbk1_7pk_1',0.,max(maxv[*,1]*good[*,1]),0
	ylim,'rbsp'+probe +'_fbk1_7pk_2',0.,max(maxv[*,2]*good[*,2]),0
	ylim,'rbsp'+probe +'_fbk1_7pk_3',0.,max(maxv[*,3]*good[*,3]),0
	ylim,'rbsp'+probe +'_fbk1_7pk_4',0.,max(maxv[*,4]*good[*,4]),0
	ylim,'rbsp'+probe +'_fbk1_7pk_5',0.,max(maxv[*,5]*good[*,5]),0
	ylim,'rbsp'+probe +'_fbk1_7pk_6',0.,max(maxv[*,6]*good[*,6]),0


	if keyword_set(combine) then begin
	
		ylim,'rbsp'+probe +'_fbk1_7comb_0',0,max(maxv[*,0]*good[*,0]),0
		ylim,'rbsp'+probe +'_fbk1_7comb_1',0,max(maxv[*,1]*good[*,1]),0
		ylim,'rbsp'+probe +'_fbk1_7comb_2',0,max(maxv[*,2]*good[*,2]),0
		ylim,'rbsp'+probe +'_fbk1_7comb_3',0,max(maxv[*,3]*good[*,3]),0
		ylim,'rbsp'+probe +'_fbk1_7comb_4',0,max(maxv[*,4]*good[*,4]),0
		ylim,'rbsp'+probe +'_fbk1_7comb_5',0,max(maxv[*,5]*good[*,5]),0
		ylim,'rbsp'+probe +'_fbk1_7comb_6',0,max(maxv[*,6]*good[*,6]),0
	
	endif

	dmessage='ylim fbk1_7pk runtime (s): '+string(systime(1)-ylim_start_time)
	dprint,verbose=verbose,dlevel=2,dmessage



	;Keep only 1 number after decimal place. More just clutters up plot
	options,'rbsp'+probe +'_fbk1_7pk_0','ytickformat','(f6.1)'
	options,'rbsp'+probe +'_fbk1_7pk_1','ytickformat','(f6.1)'
	options,'rbsp'+probe +'_fbk1_7pk_2','ytickformat','(f6.1)'
	options,'rbsp'+probe +'_fbk1_7pk_3','ytickformat','(f6.1)'
	options,'rbsp'+probe +'_fbk1_7pk_4','ytickformat','(f6.1)'
	options,'rbsp'+probe +'_fbk1_7pk_5','ytickformat','(f6.1)'
	options,'rbsp'+probe +'_fbk1_7pk_6','ytickformat','(f6.1)'

endif



;---------
;FBK2 - 7
;---------

tst = tnames('rbsp'+probe +'_fbk2_7pk_0')
if tst ne '' then begin
	get_data,'rbsp'+probe +'_fbk2_7pk_0',data=goo0
	get_data,'rbsp'+probe +'_fbk2_7pk_1',data=goo1
	get_data,'rbsp'+probe +'_fbk2_7pk_2',data=goo2
	get_data,'rbsp'+probe +'_fbk2_7pk_3',data=goo3
	get_data,'rbsp'+probe +'_fbk2_7pk_4',data=goo4
	get_data,'rbsp'+probe +'_fbk2_7pk_5',data=goo5
	get_data,'rbsp'+probe +'_fbk2_7pk_6',data=goo6


	nchunks = floor(n_elements(goo0.y)/sz)
	mom = fltarr(nchunks,7)
	maxv = fltarr(nchunks,7) ;peak values
	varv = fltarr(nchunks,7) ;variances

	ylim_start_time=systime(1)
	dmessage="using nchunks in fbk2_13pk: "+string(nchunks)
	dprint,verbose=verbose,dlevel=2,dmessage

	for i=0L,nchunks-1*sz do begin
	
		maxv[i,0] = max(goo0.y[i*sz:i*sz+sz])
		maxv[i,1] = max(goo1.y[i*sz:i*sz+sz])
		maxv[i,2] = max(goo2.y[i*sz:i*sz+sz])
		maxv[i,3] = max(goo3.y[i*sz:i*sz+sz])
		maxv[i,4] = max(goo4.y[i*sz:i*sz+sz])
		maxv[i,5] = max(goo5.y[i*sz:i*sz+sz])
		maxv[i,6] = max(goo6.y[i*sz:i*sz+sz])
	
		tst = moment(goo0.y[i*sz:i*sz+sz])
		varv[i,0] = sqrt(tst[1])
		tst = moment(goo1.y[i*sz:i*sz+sz])
		varv[i,1] = sqrt(tst[1])
		tst = moment(goo2.y[i*sz:i*sz+sz])
		varv[i,2] = sqrt(tst[1])
		tst = moment(goo3.y[i*sz:i*sz+sz])
		varv[i,3] = sqrt(tst[1])
		tst = moment(goo4.y[i*sz:i*sz+sz])
		varv[i,4] = sqrt(tst[1])
		tst = moment(goo5.y[i*sz:i*sz+sz])
		varv[i,5] = sqrt(tst[1])
		tst = moment(goo6.y[i*sz:i*sz+sz])
		varv[i,6] = sqrt(tst[1])

	
		mom[i,0]=total(goo0.y[i*sz:i*sz+sz])/sz
		mom[i,1]=total(goo1.y[i*sz:i*sz+sz])/sz
		mom[i,2]=total(goo2.y[i*sz:i*sz+sz])/sz
		mom[i,3]=total(goo3.y[i*sz:i*sz+sz])/sz
		mom[i,4]=total(goo4.y[i*sz:i*sz+sz])/sz
		mom[i,5]=total(goo5.y[i*sz:i*sz+sz])/sz
		mom[i,6]=total(goo6.y[i*sz:i*sz+sz])/sz
	endfor

	stdevv = sqrt(varv)
	
	ratio = maxv/stdevv


	;Reject values (for the y-scaling) where the max value is >> than the standard deviation
	good = bytarr(nchunks,7)
	good[*] = 1b

	goo = where(ratio[*,0] ge maxrat)
	if goo[0] ne -1 then good[goo,0] = 0b
	goo = where(ratio[*,1] ge maxrat)
	if goo[0] ne -1 then good[goo,1] = 0b
	goo = where(ratio[*,2] ge maxrat)
	if goo[0] ne -1 then good[goo,2] = 0b
	goo = where(ratio[*,3] ge maxrat)
	if goo[0] ne -1 then good[goo,3] = 0b
	goo = where(ratio[*,4] ge maxrat)
	if goo[0] ne -1 then good[goo,4] = 0b
	goo = where(ratio[*,5] ge maxrat)
	if goo[0] ne -1 then good[goo,5] = 0b
	goo = where(ratio[*,6] ge maxrat)
	if goo[0] ne -1 then good[goo,6] = 0b

	good = float(good)

	ylim,'rbsp'+probe +'_fbk2_7pk_0',0.,max(maxv[*,0]*good[*,0]),0
	ylim,'rbsp'+probe +'_fbk2_7pk_1',0.,max(maxv[*,1]*good[*,1]),0
	ylim,'rbsp'+probe +'_fbk2_7pk_2',0.,max(maxv[*,2]*good[*,2]),0
	ylim,'rbsp'+probe +'_fbk2_7pk_3',0.,max(maxv[*,3]*good[*,3]),0
	ylim,'rbsp'+probe +'_fbk2_7pk_4',0.,max(maxv[*,4]*good[*,4]),0
	ylim,'rbsp'+probe +'_fbk2_7pk_5',0.,max(maxv[*,5]*good[*,5]),0
	ylim,'rbsp'+probe +'_fbk2_7pk_6',0.,max(maxv[*,6]*good[*,6]),0


	if keyword_set(combine) then begin
	
		ylim,'rbsp'+probe +'_fbk2_7comb_0',0,max(maxv[*,0]*good[*,0]),0
		ylim,'rbsp'+probe +'_fbk2_7comb_1',0,max(maxv[*,1]*good[*,1]),0
		ylim,'rbsp'+probe +'_fbk2_7comb_2',0,max(maxv[*,2]*good[*,2]),0
		ylim,'rbsp'+probe +'_fbk2_7comb_3',0,max(maxv[*,3]*good[*,3]),0
		ylim,'rbsp'+probe +'_fbk2_7comb_4',0,max(maxv[*,4]*good[*,4]),0
		ylim,'rbsp'+probe +'_fbk2_7comb_5',0,max(maxv[*,5]*good[*,5]),0
		ylim,'rbsp'+probe +'_fbk2_7comb_6',0,max(maxv[*,6]*good[*,6]),0
	
	endif

	dmessage='ylim fbk2_7pk runtime (s): '+string(systime(1)-ylim_start_time)
	dprint,verbose=verbose,dlevel=2,dmessage


	;Keep only 1 number after decimal place. More just clutters up plot
	options,'rbsp'+probe +'_fbk2_7pk_0','ytickformat','(f6.1)'
	options,'rbsp'+probe +'_fbk2_7pk_1','ytickformat','(f6.1)'
	options,'rbsp'+probe +'_fbk2_7pk_2','ytickformat','(f6.1)'
	options,'rbsp'+probe +'_fbk2_7pk_3','ytickformat','(f6.1)'
	options,'rbsp'+probe +'_fbk2_7pk_4','ytickformat','(f6.1)'
	options,'rbsp'+probe +'_fbk2_7pk_5','ytickformat','(f6.1)'
	options,'rbsp'+probe +'_fbk2_7pk_6','ytickformat','(f6.1)'

endif



dmessage='runtime (s): '+string(systime(1)-start_time)
dprint,verbose=verbose,dlevel=2,dmessage

end