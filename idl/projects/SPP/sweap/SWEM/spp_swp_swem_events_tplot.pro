;Ali: Feb 2021
; $LastChangedBy: ali $
; $LastChangedDate: 2021-10-11 14:41:07 -0700 (Mon, 11 Oct 2021) $
; $LastChangedRevision: 30349 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/sweap/SWEM/spp_swp_swem_events_tplot.pro $

pro spp_swp_swem_events_tplot_labels,limits=lims,data=data
  nlab=n_elements(lims.labels)
  plot,data.x,data.y,_extra=lims
  xyouts,replicate(!x.crange[1],nlab),indgen(nlab),' '+lims.labels
end

pro spp_swp_swem_events_tplot,prefix=prefix,event=event,ptp=ptp,reset=reset,bad_blocks=bad_blocks

  common spp_swp_swem_events_apdat_com,event_str
  if keyword_set(ptp) then prefix='spp_swem_event_log_'
  if ~keyword_set(prefix) then prefix='psp_swp_swem_event_log_L1_'
  get_data,prefix+'CODE',eventt,eventcode
  get_data,prefix+'ID',eventt,eventid
  nt=n_elements(eventt)
  if ~keyword_set(eventt) then begin
    dprint,'No SWEM events tplot variable found, returning...'
    return
  endif
  id32=long(eventid)
  id123=id32[*,3]+id32[*,2]*0x100+id32[*,1]*0x10000
  ;codeuniq=eventcode[UNIQ(eventcode, SORT(eventcode))]
  if keyword_set(reset) || n_elements(event_str) eq 0 then event_str=(strtrim(spp_swp_swem_events_strings(),2))
  nstring=n_elements(event_str)
  wstring=indgen(nstring)
  event_str2=string(wstring,format='0x%03Z_')+event_str.substring(0,-2)
  if keyword_set(event) then wstring=where(event_str.contains(event,/fold_case),/null,nstring)
  eventcode2=intarr(nt)-1
  eventid123=lonarr(nt)-1
  eventid0=intarr(nt)-1
  labels=event_str
  c=0
  for i=0,nstring-1 do begin
    w=where(eventcode eq wstring[i],/null,nw)
    if nw gt 0 then begin
      eventcode2[w]=c
      eventid123[w]=id123[w]
      eventid0[w]=eventid[w,0]
      labels[c]=event_str2[wstring[i]]
      c++
    endif
  endfor
  if c eq 0 then message,'no known code found!'
  if ~keyword_set(event) then begin
    w=where(eventcode ge nstring,/null,nw)
    if nw gt 0 then message,'unknown code!'
  endif
  labels=labels[0:c-1]
  ytickinterval=1+c/59 ;idl direct graphics does not handle more than 59 major ytick marks!
  store_data,prefix+'CODE2',eventt,eventcode2,dlim={labels:labels,ytickinterval:ytickinterval,yrange:[-1,c],psym:1,yticklen:1,ygridstyle:1,$
    ystyle:3,yminor:1,panel_size:c/7.,tplot_routine:'spp_swp_swem_events_tplot_labels'}
  wnem1=where(eventid0 ne -1,/null)
  store_data,prefix+'ID123',eventt[wnem1],eventid123[wnem1],dlim={psym:1,ystyle:3}
  store_data,prefix+'ID0',eventt[wnem1],eventid0[wnem1],dlim={psym:1,ystyle:3}

  if keyword_set(bad_blocks) then begin
    block=replicate(0b,[0xFFFFFF,nstring])
    for it=0,nt-1 do begin
      for is=0,nstring-1 do begin
        if eventcode[it] eq wstring[is] then block[id3[it],is]+=1
      endfor
    endfor
    stop
  endif

end