;Creates a .txt file that has all the EFW burst 1 start/stop times
;and data rates.


;Block rate vs data rate chart
;Note that after 2013-10-14 EB1 was dropped from B1 collection
;so that the usual 12 channels (6xVb, 3xEb, 3xMSCb) become
;9 channels (data rates reduced by factor 9/12)

;For 16K burst rate:
;Pre  2013-10-14 rate is 4096 Samples/block
;Post 2014-10-14 rate is 5461 Samples/block



pro create_rbsp_burst_times_rate_list,probe,date


  ;Output file with burst times and rates
  fn = '~/Desktop/burst1_times_rates_RBSP'+probe+'.txt'
  ;Create file with header if it doesn't already exist
  ftst = file_test(fn)
  if not ftst then begin
    openw,lun,fn,/get_lun
    printf,lun,'Burst 1 times,                          duration (sec), rates (Samples/sec) for RBSP'+probe
;    printf,lun,'Burst 1 times, duration (sec), and rates (Samples/sec) for RBSP'+probe
    close,lun & free_lun,lun
  endif


  timespan,date
  tr = timerange()


  ;Date that Eb channels were dropped
  tswitch = time_double('2013-10-14')
  tdiff = tr[0] - tswitch
  if tdiff ge 0 then samples_block = 5461d else samples_block = 4096d


  ;Get burst start/stop times
  rbsp_load_efw_burst_times,probe=probe,/force_download,$
	  b1_times=b1t,b2_times=b2t


  rbsp_load_efw_hsk,probe=probe,/get_support_data




  if KEYWORD_SET(b1t) then begin

    ;Remove bursts that are too short. Not sure why these <1sec ones exist
    dbtime = b1t[*,1] - b1t[*,0]
    goo = where(dbtime gt 1)
    if goo[0] ne -1 then b1t = b1t[goo,*]


    get_data,'rbsp'+probe+'_efw_hsk_idpu_fast_B1_RECPTR',data=d

    ;Smooth the RECPTR values. This is required b/c RECPTR has only
    ;integer values. Thus 512 Samples/sec would be represented by
    ;0 0 0 0 1, 0 0 0 0 1...or something like that.
    smoovb = smooth(d.y,20)

    ddelta = smoovb - shift(smoovb,1)
    dx = abs(d.x - shift(d.x,1))
    ;store_data,'ddelta',d.x,ddelta


    block_rate = ddelta/dx

    sample_rate = block_rate*samples_block

    avgrate = fltarr(n_elements(b1t[*,0]))

    ;Reduce data to only times that were actually telemetered
    sample_rate_fin = fltarr(n_elements(sample_rate))
    for i=0,n_elements(b1t[*,0])-1 do begin $
      goo = where((d.x ge b1t[i,0]) and (d.x le b1t[i,1])) & $
      if goo[0] ne -1 then begin
        sample_rate_fin[goo] = sample_rate[goo]


      ;Determine the average rate for each chunk
      ;Save values to a file

        tmp = median(sample_rate_fin[goo])

        avgrate[i] = median(sample_rate_fin[goo])
        ;snap to discrete values if possible
        if tmp lt 800 then avgrate[i] = 512
        if ((tmp ge 1024-200) and (tmp le 1024+200)) then avgrate[i] = 1024.
        if ((tmp ge 2048-400) and (tmp le 2048+400)) then avgrate[i] = 2048.
        if ((tmp ge 4096-800) and (tmp le 4096+800)) then avgrate[i] = 4096.
        if ((tmp ge 8192-2000) and (tmp le 8192+2000)) then avgrate[i] = 8192.
        if tmp gt 12000 then avgrate[i] = 16384.

        avgrate_str = strtrim(floor(avgrate[i]),1)
        burst_duration = strtrim(floor(b1t[i,1] - b1t[i,0]),1)

        ;specific formatting so that columns align
        avgrate_str = string(avgrate_str,format='(A7)')
        burst_duration = string(burst_duration,format='(A9)')


        s1 = time_string(b1t[i,0])
        s2 = time_string(b1t[i,1])
        s3 = burst_duration
        s4 = avgrate_str


        openw,lun,fn,/get_lun,/append
        printf,lun,s1+' - '+s2+'  '+s3+'  '+s4
  ;      printf,lun,time_string(b1t[i,0])+' - '+time_string(b1t[i,1])+ '  '+burst_duration+'  '+ avgrate_str; + ' Samples/sec'
        close,lun & free_lun,lun

      endif
    endfor


;    store_data,'block_rateB1',d.x,block_rate
;    store_data,'sample_rateB1',d.x,sample_rate
;    store_data,'sample_rate_finB1',d.x,sample_rate_fin
;    ylim,'block_rateB1',-6,6
;    ylim,'sample_rateB1',100,20000,1
;    ylim,'sample_rate_finB1',100,20000,1
;
;    options,['sample_rate_finB1','sample_rateB1'],'psym',-2

;    tplot,['sample_rate_finB1','sample_rateB1','block_rateB1','rbspa_efw_hsk_idpu_fast_B1_RECPTR','rbspa_efw_hsk_idpu_fast_B1_RECPTR_smoothed']
;
;    ylim,['rbspa_efw_hsk_idpu_fast_B1_PLAYPTR','rbspa_efw_hsk_idpu_fast_B1_RECPTR'],2.4d5,2.6d5
;    tplot,['rbspa_efw_hsk_idpu_fast_B1_PLAYPTR','rbspa_efw_hsk_idpu_fast_B1_RECPTR']
;stop


  endif


  store_data,tnames(),/del
end


;    sample_rate = dblarr(n_elements(block_rate))


    ;Determine if sampling is 16K or not.
;    sample_rate_rough = block_rate*samples_block
;    sample_rate_rough = block_rate*5461d


;    ;For 16K samples the conversion to sample rate changes after 2013-10-14
;    boo = where(sample_rate_rough gt 12000.)
;    if boo[0] ne -1 then begin
;      if tdiff ge 0 then sample_rate[boo] = block_rate[boo]*5461d else $
;                         sample_rate[boo] = block_rate[boo]*samples_block
;    endif

;    ;For anything less than 16K sample rate use the standard samples_block value
;    boo = where(sample_rate_rough le 12000.)
;    if boo[0] ne -1 then sample_rate[boo] = block_rate[boo]*samples_block
