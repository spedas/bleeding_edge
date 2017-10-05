pro     mav_apid_30_handler,ccsds,decom=decom

if not keyword_set(ccsds) then return ; cleanup


if ccsds.apid ne '30'x then return
mav_inst_msg_handler,ccsds


end