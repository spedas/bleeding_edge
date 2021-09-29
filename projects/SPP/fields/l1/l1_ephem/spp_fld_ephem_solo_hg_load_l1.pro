;
;  $LastChangedBy: pulupalap $
;  $LastChangedDate: 2020-06-16 16:53:56 -0700 (Tue, 16 Jun 2020) $
;  $LastChangedRevision: 28780 $
;  $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/fields/l1/l1_ephem/spp_fld_ephem_solo_hg_load_l1.pro $
;

pro spp_fld_ephem_solo_hg_load_l1, file, prefix = prefix, varformat = varformat

  if not keyword_set(prefix) then prefix = 'spp_fld_ephem_SOLO_HG_'

  spp_fld_ephem_load_l1, file, prefix = prefix, varformat = varformat

end