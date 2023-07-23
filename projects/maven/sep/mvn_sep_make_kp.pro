; $LastChangedBy: ali $
; $LastChangedDate: 2022-07-06 12:20:39 -0700 (Wed, 06 Jul 2022) $
; $LastChangedRevision: 30901 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/sep/mvn_sep_make_kp.pro $

pro mvn_sep_make_kp,trange=trange,lowres=lowres,download_only=download_only,verbose=verbose

  if n_elements(lowres) eq 0 then lowres=3
  if lowres eq 0 then res='_'
  if lowres eq 1 then res='_5min_'
  if lowres eq 2 then res='_01hr_'
  if lowres eq 3 then res='_32sec_'

  pathname=root_data_dir()+'maven/data/sci/sep/kp/'
  trange=timerange(trange)
  ndays=fix((trange[1]-trange[0])/60/60/24)
  for i=0,ndays do begin
    del_data,verbose=verbose,'mvn*
    tr=trange[0]+i*60.*60*24
    name='mvn_kp_sep_'+time_string(tr,tformat='YYYYMMDD')
    mvn_sep_load,tr=tr,lowres=lowres,/basic,download_only=download_only;,files=files
    ;mvn_sep_anc_load,trange=tr,anc_structure=anc,prefix='mvn_'
    get_data,'mvn'+res+'SEP1F_ion_flux',dat=ion1f
    get_data,'mvn'+res+'SEP1R_ion_flux',dat=ion1r
    get_data,'mvn'+res+'SEP2F_ion_flux',dat=ion2f
    get_data,'mvn'+res+'SEP2R_ion_flux',dat=ion2r
    get_data,'mvn'+res+'SEP1F_ion_flux_unc',dat=uni1f
    get_data,'mvn'+res+'SEP1R_ion_flux_unc',dat=uni1r
    get_data,'mvn'+res+'SEP2F_ion_flux_unc',dat=uni2f
    get_data,'mvn'+res+'SEP2R_ion_flux_unc',dat=uni2r
    get_data,'mvn'+res+'SEP1F_elec_flux',dat=ele1f
    get_data,'mvn'+res+'SEP1R_elec_flux',dat=ele1r
    get_data,'mvn'+res+'SEP2F_elec_flux',dat=ele2f
    get_data,'mvn'+res+'SEP2R_elec_flux',dat=ele2r
    get_data,'mvn'+res+'SEP1F_elec_flux_unc',dat=une1f
    get_data,'mvn'+res+'SEP1R_elec_flux_unc',dat=une1r
    get_data,'mvn'+res+'SEP2F_elec_flux_unc',dat=une2f
    get_data,'mvn'+res+'SEP2R_elec_flux_unc',dat=une2r
    if ~keyword_set(ion1f) then continue
    ion=(ion1f.y+ion1r.y+ion2f.y+ion2r.y)/4.
    uni=(uni1f.y+uni1r.y+uni2f.y+uni2r.y)/4.
    ele=(ele1f.y+ele1r.y+ele2f.y+ele2r.y)/4.
    une=(une1f.y+une1r.y+une2f.y+une2r.y)/4.
    time=ion1f.x
    nt=n_elements(time)
    ion2=rebin(ion[*,7:27],[nt,7])
    uni2=rebin(uni[*,7:27],[nt,7])
    ele2=rebin(ele[*,6:14],[nt,3])
    une2=rebin(une[*,6:14],[nt,3])
    ion2[where(~finite(ion2),/null)]=0
    uni2[where(~finite(uni2),/null)]=0
    ele2[where(~finite(ele2),/null)]=0
    une2[where(~finite(une2),/null)]=0
    mso=data_cut('mvn_mvn_pos_mso',time)
    if ~keyword_set(mso) then continue
    store_data,name,time,[[ion2],[uni2],[ele2],[une2],[mso]]
    dir=pathname+time_string(tr[0],tformat='YYYY')+'/'+time_string(tr[0],tformat='MM')+'/'
    file_mkdir2,dir
    tplot_ascii,name,dir=dir
  endfor

end