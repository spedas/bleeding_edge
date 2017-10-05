pro fs_sum,tr


tplot_options,'ygap',0.
tplot_options,var=['wi_pos_mag','wi_pos_phi']
!p.charsize=.6
popen,/port
loadct2,34
pclose,pri=''



timespan,tr
load_wi_or,/pol
load_wi_elpd2
load_wi_pm_3dp,/pol,/vth
load_wi_em_3dp,/pol
load_wi_sp_mfi,/pol
load_wi_wav
load_wi_swe,/pol

get_bsn,pname='wi_pos',bname='wi_B3';,vname='wi_pm_Vp'

pol_suf = ['_mag','_th','_phi']
pmom='wi_pm_'+['Np','Vp'+pol_suf]
ylim,'wi_pm_Np',0,20
ylim,'wi_pm_Vp_mag',200,800,0
ylim,'wi_pm_Vp_phi',160,200
ylim,'wi_pm_Vp_th',-20,20
pads = iton('elpd-1')
pspec = iton('elpd-2')
mfi = 'wi_B'+pol_suf
mag = 'wi_B3'+pol_suf
bsn = ['Bsn','Lsh']
ylim,'Lsh',0,100

ylim,pspec,10.,1e8,1

vars = [bsn,mag,pmom,'wi_wav_Pow',pads([0,2,4,6,8,11]),pspec]

tplot,vars

end


