;Procedure: RBSP_EFW_B1_CMD
;
;Purpose:  Creates a RBSP EFW Burst 1 Selection Command
;
;keywords:
;  probe = Probe name. Valid inputs are 'a' and 'b'
;  TRANGE= Time range of interest  (2 element array)
;  CMD_STRING = (output) Command string for burst selection
;  /VERBOSE  set to output some useful info
;Example:
;   rbsp_efw_b1_cmd,probe='a',trange=[starttime,endtime]
;Notes:
; 1. Written by Peter Schroeder, February 2012
;
; $LastChangedBy: peters $
; $LastChangedDate: 2012-08-01 10:18:57 -0700 (Wed, 01 Aug 2012) $
; $LastChangedRevision: 10759 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/missions/rbsp/efw/rbsp_efw_b1_cmd.pro $
;-

pro rbsp_efw_b1_cmd,probe=probe, trange=trange, verbose=verbose, cmd_string=cmd_string

rbsp_efw_init
dprint,verbose=verbose,dlevel=4,'$Id: rbsp_efw_b1_cmd.pro 10759 2012-08-01 17:18:57Z peters $'

if not keyword_set(probe) then begin
  print,'No probe selected. Returning....'
  return
endif

p_var = probe
if n_elements(p_var) gt 1 then begin
  print,'Must choose only 1 probe. Returning....'
  return
endif

p_var = p_var[0]
if p_var ne 'a' and p_var ne 'b' then begin
  print,'Probe must be either a or b. Returning....'
  return
endif

if not keyword_set(trange) then begin
  print,'Must enter a trange. Returning....'
  return
endif

if n_elements(trange) ne 2 then begin
  print,'trange must have 2 elements. Returning....'
  return
endif

vb = keyword_set(verbose) ? verbose : 0
vb = vb > !rbsp_efw.verbose

rbspx = 'rbsp'+ p_var

prefix=rbspx+'_efw_b1_fmt_'
    
get_data, prefix+'block_index', data=blockdata

sbindex = where(trange[0] lt blockdata.x, sbcnt)
if sbcnt eq 0 then begin
  print,'No valid data found for this start time (trange[0])'
  return
endif

startindex = min(sbindex)

ebindex = where(trange[1] lt blockdata.x, ebcnt)
if ebcnt eq 0 then begin
  print,'End time is beyond current B1 time range. Using last valid block.'
  lasttime = max(blockdata.x, ebindex)
endif

endindex = min(ebindex)

startblock = blockdata.y[startindex]
endblock = blockdata.y[endindex]

if endblock lt startblock then $
  endblock = endblock + 262144

numblocks = endblock - startblock + 1

cmd_string = 'util.QUEUE_B1PLAYBACK( ' + strcompress(startblock,/rem) + ', ' + strcompress(numblocks,/rem) + ')'

end
