;+
;PROCEDURE: 
;	MVN_SWIA_MAKE_SWIHSK_STR
;PURPOSE: 
;	Routine to produce an array of structures containing SWIA Housekeeping
;AUTHOR: 
;	Jasper Halekas
;CALLING SEQUENCE:
;	MVN_SWIA_MAKE_SWIHSK_STR, Packets, Info, SwiHSK_Str_Array
;INPUTS:
;	Packets: An array of structures containing individual packets packets
;OUTPUTS
;	SwiHSK_Str_Array: An array of structures containing SWIA Housekeeping
;
; $LastChangedBy: jhalekas $
; $LastChangedDate: 2013-06-18 21:19:24 -0700 (Tue, 18 Jun 2013) $
; $LastChangedRevision: 12551 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swia/mvn_swia_make_swihsk_str.pro $
;
;-

pro mvn_swia_make_swihsk_str, packets, swihsk_str_array

compile_opt idl2

met = packets.clock1*65536.d + packets.clock2 

unixt = mvn_spc_met_to_unixtime(met)

swihsk_str = {time_met: 0.d, $
time_unix: 0.d, $
lvpst: 0., $
digt: 0., $
imon_mcp: 0., $
vmon_mcp: 0., $
imon_raw: 0., $
vmon_raw_def: 0., $
vmon_raw_swp: 0., $
vmon_swp: 0., $
vmon_def1: 0., $
vmon_def2: 0., $
v25d: 0., $
v5d: 0., $
v33d: 0., $
v5a: 0., $
vn5a: 0., $
v28: 0., $
v12: 0., $
modeid: 0, $
options: 0, $
coarse_options: [0, 0], $
fine_options: [0, 0], $
mom_options: 0, $
spec_options: 0, $
periods: [0, 0], $
modexy: [0L, 0L], $
att_thresh: [0L,0L], $
CTRL: [0L, 0L], $
DAC: [0L, 0L], $
LUT: [0, 0], $
cmdcnt: 0L, $
dighsk: 0L, $
diagdata: 0L} 

n_packet = n_elements(met)
swihsk_str_array = replicate(swihsk_str,n_packet)

swihsk_str_array.time_met = met
swihsk_str_array.time_unix = unixt

sk = packets.lpvst*1.0
swihsk_str_array.lvpst = 165+sk*3.94e-2+sk*sk*5.68e-6+sk^3*4.43e-10+sk^4*1.67e-14+sk^5*2.42e-19
sk = packets.digt*1.0
swihsk_str_array.digt = 165+sk*3.94e-2+sk*sk*5.68e-6+sk^3*4.43e-10+sk^4*1.67e-14+sk^5*2.42e-19

swihsk_str_array.imon_mcp = packets.mcphvi*(-5.0/32678/.051)
swihsk_str_array.vmon_mcp = packets.mcphv*(-5.0/32678/.00133)
swihsk_str_array.imon_raw = packets.defrawi*(-5.0/32678/.2)
swihsk_str_array.vmon_raw_def = packets.defrawv*(-5.0/32678/.000805)
swihsk_str_array.vmon_raw_swp = packets.swprawv*(-5.0/32678/.000805)
swihsk_str_array.vmon_swp = packets.analhv*(-5.0/32678/(-0.001))
swihsk_str_array.vmon_def1 = packets.def1hv*(-5.0/32678/0.001)
swihsk_str_array.vmon_def2 = packets.def2hv*(-5.0/32678/0.001)
swihsk_str_array.v25d = packets.p2p5dv*(-5.0/32678/0.901)
swihsk_str_array.v5d = packets.p5dv*(-5.0/32678/0.801)
swihsk_str_array.v33d = packets.p3p3dv*(-5.0/32678/0.901)
swihsk_str_array.v5a = packets.p5av*(-5.0/32678/0.801)
swihsk_str_array.vn5a = packets.n5av*(-5.0/32678/0.801)
swihsk_str_array.v28 = packets.p28v*(-5.0/32678/0.145)
swihsk_str_array.v12 = packets.p12v*(-5.0/32678/0.332)
swihsk_str_array.modeid = packets.modeid
swihsk_str_array.options = packets.options
swihsk_str_array.coarse_options[0] = packets.csvy
swihsk_str_array.coarse_options[1] = packets.carc
swihsk_str_array.fine_options[0] = packets.fsvy
swihsk_str_array.fine_options[1] = packets.farc
swihsk_str_array.mom_options = packets.msvy
swihsk_str_array.spec_options = packets.ssvy
swihsk_str_array.periods[0] = packets.modeper
swihsk_str_array.periods[1] = packets.attper
swihsk_str_array.modexy[0] = packets.modex
swihsk_str_array.modexy[1] = packets.modey
swihsk_str_array.att_thresh[0] = packets.attt1
swihsk_str_array.att_thresh[1] = packets.attt2
swihsk_str_array.CTRL[0] = packets.ssctl
swihsk_str_array.CTRL[1] = packets.sifctl
swihsk_str_array.DAC[0] = packets.mcpdac
swihsk_str_array.DAC[1] = packets.rawdac
swihsk_str_array.LUT[0] = packets.lut0
swihsk_str_array.LUT[1] = packets.lut1
swihsk_str_array.cmdcnt = packets.cmdcnt
swihsk_str_array.diagdata = packets.diagdata
swihsk_str_array.dighsk = packets.dighsk

s = sort(swihsk_str_array.time_met)
swihsk_str_array = swihsk_str_array[s]

;trim obviously bad data
swihsk_str_array = swihsk_str_array[where(swihsk_str_array.time_unix ge time_double('2010-01-01'))]

end
