; $LastChangedBy: davin-mac $
; $LastChangedDate: 2016-02-15 15:33:11 -0800 (Mon, 15 Feb 2016) $
; $LastChangedRevision: 20002 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu:36867/repos/spdsoft/trunk/projects/SPP/sweap/SWEM/spp_swp_swem_unwrapper.pro $

function spp_swp_spc_decom,ccsds,ptp_header=ptp_header,apdat=apdat
 ; if debug(3,msg='SPC') then begin
 ;   dprint,dlevel=4,'SPC',ccsds.pkt_size, n_elements(ccsds.pdata), ccsds.apid
 ;   hexprint,ccsds.data[0:31]
 ; endif
  return,0
  str = create_struct(ptp_header,ccsds)
  return,str

end


