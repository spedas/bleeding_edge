pro pl_mcp_eff,time,deadt=dt,mcpeff=eff,reset=reset
common pl_mcp_eff_com,efftime,effval,dtval
if keyword_set(reset) then effval =0
if not keyword_set(effval) then begin
   message,"Using Modified Pesa Low channel plate efficiency. (reset)",/info
   d = { time:0.d,eff:0.,dt:0.}
   file=file_source_dirname(/mark)+'pl_mcp_eff.dat'
   dprint,dlevel=2,file
   dat=read_asc(file,format=d,/conv_time)
   efftime = dat.time
   effval = dat.eff
   dtval  = dat.dt
endif

t = time_double(time)
eff = interp(effval,efftime,t,index=i)
;dt  = interp(dtval,efftime,t)
eff = effval[i]
dt  = dtval[i]
return
end
