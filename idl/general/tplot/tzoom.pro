pro tzoom,trange,vnames=names,window = wind

tplot,new=ts1,/help
if ~keyword_set(wind) then wind=ts1.options.window+1
if n_elements(trange) eq 0 then ctime,trange,vals,vname=vnames
tplot,names,trange=minmax(trange)+[-1,1],old=ts1,wi=wind,new=ts2
;tlimit,old=ts1,wi=ts1.options.window+1,new=ts2
tplot,old=ts1,/help

end

