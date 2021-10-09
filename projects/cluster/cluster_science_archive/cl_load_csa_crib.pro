;+
; PROCEDURE:
;         cl_load_csa_crib
;
; PURPOSE:
;         Demonstrate use of cl_load_csa routine by getting lists of valid probes and datatypes, then
;         loading each datatype individually for probe C1 on a default test time range.
;
; KEYWORDS:
;        get_support_data: If set, loads support data from downloaded CDFs
;        
;        use_tap:          If set, use newer TAP interface rather than default CAIO interface
;
;
;
; OUTPUT
;
;
; EXAMPLE:
;
;
; NOTES:
;
;
;$LastChangedBy: jwl $
;$LastChangedDate: 2021-10-08 16:03:55 -0700 (Fri, 08 Oct 2021) $
;$LastChangedRevision: 30344 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/cluster/cluster_science_archive/cl_load_csa_crib.pro $
;-

pro cl_load_csa_crib,get_support_data=get_support_data
;  Get lists of valid probes and datatypes

cl_load_csa,probes=valid_probes,datatypes=valid_datatypes,/valid_names

trange=['2001-02-01T00:00:00Z','2001-02-04T00:00:00Z']

; Load CP_FGM_FULL data for C1
;cl_load_csa,trange=trange,probes='C1',datatypes='CP_FGM_FULL'
; Load first 10 datatypes from valid datatypes list for probe C1
;cl_load_csa,trange=trange,probes=valid_probes[0], datatypes=valid_datatypes[0:9]

; Try to load all valid datatypes for C1
del_data,'*C1*'
tp_counts=intarr(n_elements(valid_datatypes))
a=tnames('*',before_count)
for i=0,n_elements(valid_datatypes)-1 do begin
  print,"Loading "+valid_datatypes[i]
  cl_load_csa,trange=trange,probes='C1', datatypes=valid_datatypes[i], verbose=1, get_support_data=get_support_data
  a=tnames('*',after_count)
  tp_counts[i]=after_count-before_count
  print,string(tp_counts[i])+' tplot variables created'
  before_count=after_count
endfor

print,'Data types with no variables loaded:'
print,valid_datatypes[where(tp_counts eq 0)]

end
