;retdat.deadtime = 1e-6 * 4
;retdat.geomfactor = retdat.geomfactor * .7
pl_mcp_eff,retdat.time,deadt=dt,mcpeff=mcpeff
retdat.deadtime = dt
retdat.geomfactor= retdat.geomfactor * mcpeff
