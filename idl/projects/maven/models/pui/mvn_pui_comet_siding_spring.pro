;20161230 Ali
;routine to model comet siding spring pickup ions

pro mvn_pui_comet_siding_spring

;kernels=mvn_spice_kernels('css',/load)

hourmins=60d*dindgen(60) ;minutes in one hour
time=time_double('14-10-19/18')+hourmins ;one hour sandwiching closest approach

csspos=spice_body_pos('CSS','MARS',frame='MSO',utc=time) ;CSS position MSO (km)
marscssdist=sqrt(total(csspos^2,1))

p=plot(marscssdist)
stop
end