;Ali: March 2020
;+
; $LastChangedBy: ali $
; $LastChangedDate: 2023-02-12 19:59:32 -0800 (Sun, 12 Feb 2023) $
; $LastChangedRevision: 31493 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/sweap/SPAN/spp_swp_qf.pro $
;-

pro spp_swp_qf,prefix=prefix,verbose=verbose

  if n_elements(verbose) eq 0 then verbose=0
  if n_elements(prefix) eq 0 then prefix='*'
  qf_labels=['Counter Overflow','Survey Snapshot ON','Alt. Energy Table','Spoiler Test','Attenuator Engaged','Highest Archive Rate','No Targeted Sweep','Ion New Mass Table','Over-deflection','Archive Snapshot ON','Bad Energy Table','MCP Test','Survey Available','Archive Available','Threshold Test','Commanding']
  nqf=n_elements(qf_labels)
  options,/default,verbose=verbose,prefix+'QUALITY_FLAG',tplot_routine='bitplot',labels=qf_labels,psyms=1,colors=[0,1,2,6],numbits=nqf,yticks=nqf+1,yticklen=1,ygridstyle=1,yminor=1,panel_size=nqf/7.
  options,/default,verbose=verbose,prefix+['LTCSNNNN','ARCH']+'_BITS',tplot_routine='bitplot',labels=reverse(['L=Log compressed','T=Targeted OFF','C=Compressed TOF','S=Summing','N3','N2','N1','N0']),psyms=1,colors=[0,1,2,6]
  options,/default,verbose=verbose,prefix+'STATUS_BITS',tplot_routine='bitplot',labels=reverse(['Attenuator IN','Attenuator OUT','Test Pulser','High Voltage Enabled','HV3','HV2','HV1 (Spoiler Test)','HV0']),psyms=1,colors=[0,1,2,6]
  options,/default,verbose=verbose,prefix+'PRODUCT_BITS',tplot_routine='bitplot',labels=reverse(['Ion','SPAN-B','Survey','Targeted','P3','P2','P1','P0']),psyms=1,colors=[0,1,2,6]
  options,/default,verbose=verbose,prefix+'MODE2*',tplot_routine='bitplot',labels=reverse(['M1   E7','M0   E6','P3   E5','P2   E4','P1   E3','P0   E2','E5   E1','E4   E0','E3   P7','E2   P6','E1   P5','E0   P4','T3   P3','T2   P2','T1   P1','T0   P0']),psyms=1,colors=[0,1,2,6]
  options,/default,verbose=verbose,prefix+'DATA',zlog=1,spec=1
  options,/default,verbose=verbose,prefix+'CNTS',ylog=1
  options,/default,verbose=verbose,prefix+'???_SPEC',zlog=1,spec=1
  ylim,/default,verbose=verbose,prefix+'NRG_SPEC',32,0
end
