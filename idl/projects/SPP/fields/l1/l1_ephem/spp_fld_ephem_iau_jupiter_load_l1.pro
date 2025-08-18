;
;  $LastChangedBy: pulupalap $
;  $LastChangedDate: 2022-03-31 15:13:11 -0700 (Thu, 31 Mar 2022) $
;  $LastChangedRevision: 30739 $
;  $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/fields/l1/l1_ephem/spp_fld_ephem_iau_jupiter_load_l1.pro $
;

pro spp_fld_ephem_iau_jupiter_load_l1, file, prefix = prefix, varformat = varformat

  if not keyword_set(prefix) then prefix = 'spp_fld_ephem_iau_jupiter_'

  spp_fld_ephem_load_l1, file, prefix = prefix, varformat = varformat

end