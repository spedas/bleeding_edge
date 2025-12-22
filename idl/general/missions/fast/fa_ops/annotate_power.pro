pro annotate_power,SDT = sdt

if keyword_set(sdt) then begin
    pqs = ['VLF PWR','HF PWR','ELF PWR']
endif else begin
    pqs = ['VLF_PWR','HF_PWR','ELF_PWR']
endelse

i=-1
repeat begin
    i = i+1
    pq = pqs(i)
endrep until ((i eq 2) or (find_handle(pq) ne 0)) 

if i eq 2 then return

get_data,pq,dlim=pwrlim
tplot_panel,variable=pq,deltatime=dt

x0 = 1.12
x1 = 1.16
xlegend = [x0,x1]*(!x.crange(1)-!x.crange(0))+!x.crange(0)
ylegend = 10^fa_mean(!y.crange)

xyouts,xlegend,ylegend,pwrlim.labels,/data,color=pwrlim.colors, $
  orientation=90,align=0.5


return
end
        
