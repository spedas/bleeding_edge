pro get_wi_sumvar,trange
  magname='wi_B3'
  densname='Np'
  velname='Vp'
  posname='wi_pos'

   timespan,trange
   load_3dp_data
   get_pmom2
   load_wi_sp_mfi,/pol
   load_wi_swe,/pol
   alfven_pow,trange=trange,res=8
   options,'*(*)',panel_size=.7
   get_sospec  & ylim,'sospec*',1e-8,1
   get_sfspec  & ylim,'sfspec*',1e-6,1
   load_wi_or,/var
   get_bsn2,bname=magname,pname=posname,vname=velname
   get_plasma_param,b_name=magname,n_name=densname,v_name=velname, $
       tp_name='Tp',te_name=te_name
   load_wi_elpd2
   normpad
   fixpad
   elpd_lim
  
   options,'C_alf',colors='c'
   options,'C_s',colors='g'
   options,'C_fms',colors='m'
   options,'*swe*',colors='y'
   ylim,'Beta',.01,10,1
   
   store_data,'B',data='wi_B3_mag'
   store_data,'Bth',data='wi_B3_th'
   store_data,'Bph',data='wi_B3_phi'
   
   store_data,'V',data='wi_swe_Vp_mag wi_swe_VTHp C_alf C_s C_fms Vp_mag VTHp'
   ylim,'V',0,1000,0
   options,'V',panel_size=1.5
   
   store_data,'N',data='wi_swe_Np Np'
   ylim,'N',.2,100,1
   options,'N',panel_size=1.5

   store_data,'T',data='el_mom.AVGTEMP wi_swe_Tp Tp'
   ylim,'T',.2,100,1
   options,'T',panel_size=1.5


end







pro sumplot

date=''
read,date,prompt='start date? '
ndays=1
read,ndays,prompt='Number of days? '

t1=round(time_double(date)/86400d)*86400d
tplot_options,title=''

no_tplot=0
svar1 = 'B Bth Bph N V T elpd-1-5:5_norm Beta'
svar2 = 'B Bth Bph Np V sospec* sfspec* pow(A+) pow(A-) pol(A+) pol(A-) bsn.TH_BN dir(A) elpd-1-5:5*'
svar3 = 'elpd-1-?:? elpd-2-0:0 elpd-2-7:7 bsn.TH_BN dir(A)'
svard = 'elpd-1-?:?_norm elpd-2-0:0 elpd-2-7:7 bsn.TH_BN dir(A)'
dir = '~/archive/wavelet/'

if not keyword_set(no_tplot) then window,0,xsize=800,ysize=900
for day=0,ndays-1 do begin
   t = t1 + day * 86400d
   dstring = time_string(format=2,/date,t)
   trange = t+[-.06,1.06]*86400d
   get_wi_sumvar,trange
tround = round(trange/86400.d)*86400d
tplot_to_cdf,'pow(A+) pol(A+) pow(A-) pol(A-) pow(Ac) pol(Ac) abs(V/B) phs(V/B)',trange=tround,file='~davin/archive/wavelet/wi_alfv_'
   tplot,svar1
   makegif,dir+'D_'+dstring+'_A'
   tplot,svar2
   makegif,dir+'D_'+dstring+'_B'
   tplot,svar3
   makegif,dir+'D_'+dstring+'_C'
   tplot,svard
   makegif,dir+'D_'+dstring+'_D'
endfor





end
