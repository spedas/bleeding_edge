;+
; PROCEDURE:
;         mms_team_kibana
;
; PURPOSE:
;         Opens the MMS Kibana page using your web browser; allows you to see which
;         data files are available at the SDC, and when they're available
; 
; KEYWORDS:
;         only one keyword allowed specifying the instrument you're interested in, e.g., 
;         /fgm for FGM data, /fpi for FPI data, etc.
;         
;     
; NOTES:
;         The webpage is restricted to MMS team-members only
; 
; EXAMPLE:
;         to open the Kibana page for FPI CDF files:
;         MMS> mms_team_kibana, /fpi
;         
;         
; $LastChangedBy: egrimes $
; $LastChangedDate: 2018-02-21 09:06:31 -0800 (Wed, 21 Feb 2018) $
; $LastChangedRevision: 24755 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/common/util/mms_team_kibana.pro $
;-

pro mms_team_kibana, fgm=fgm, fpi=fpi, hpca=hpca, mec=mec, scm=scm, eis=eis, feeps=feeps, edi=edi, dsp=dsp, edp=edp, aspoc=aspoc
  instrument = 'volume'
  if keyword_set(fgm) then instrument='fgm'
  if keyword_set(fpi) then instrument='fpi'
  if keyword_set(hpca) then instrument='hpca'
  if keyword_set(mec) then instrument='mec'
  if keyword_set(scm) then instrument='scm'
  if keyword_set(feeps) then instrument='feeps'
  if keyword_set(eis) then instrument='eis'
  if keyword_set(edi) then instrument='edi'
  if keyword_set(dsp) then instrument='dsp'
  if keyword_set(edp) then instrument='edp'
  if keyword_set(aspoc) then instrument='asp'
  
  spd_ui_open_url, 'https://lasp.colorado.edu/mms/sdc/team/visualizations/app/kibana#/dashboard/mms_'+instrument
end