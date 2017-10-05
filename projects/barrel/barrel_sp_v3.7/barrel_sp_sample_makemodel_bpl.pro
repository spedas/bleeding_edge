pro makemodel_bpl,indx1,indx2,ebreak,normatbreak,outf

e=findgen(500)*10.+30.
edge_products,e,mean=mean,width=width
o=fltarr(n_elements(e))

yleft = normatbreak*(mean/ebreak)^(indx1)
yright = normatbreak*(mean/ebreak)^(indx2)

w=where(mean LT ebreak,nw)
if nw GE 1 then o[w] = yleft[w]
w=where(mean GE ebreak,nw)
if nw GE 1 then o[w] = yright[w]

openw,1,outf
for i=0,n_elements(mean)-1 do printf,1,e[i],e[i+1],o[i]
close,1

end

;makemodel_bpl,-1.,-5.,500.,1.,'spec_bpl.txt'
