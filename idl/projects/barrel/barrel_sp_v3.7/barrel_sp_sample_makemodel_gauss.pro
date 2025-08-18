pro barrel_sp_sample_makemodel_gauss,center,sigma,norm,outf

e=findgen(500)*10.+30.
edge_products,e,mean=mean,width=width
o=fltarr(n_elements(e))

y=norm*exp(-(mean-center)^2./2./sigma^2.)

openw,1,outf
for i=0,n_elements(mean)-1 do printf,1,e[i],e[i+1],y[i]
close,1

end

;barrel_sp_makemodel_gauss,600.,200.,1.,'spec_gau.txt'
;barrel_sp_makemodel_gauss,2000.,1000.,1.,'spec_gau2.txt'

