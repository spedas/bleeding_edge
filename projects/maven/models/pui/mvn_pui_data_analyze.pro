;20160404 Ali
;MAVEN data analysis:
;SWEA/SWIA solar wind moments, ionization frequencies, etc.
;to be called by mvn_pui_model

pro mvn_pui_data_analyze

@mvn_pui_commonblock.pro ;common mvn_pui_common

mp=1.67e-24; %proton mass (g)
me=9.1e-28; %electron mass (g)
qe=1.602e-12; %electron charge (erg/eV)
hpc=6.626e-34; %Planck's constant (J.s) or (m2 kg/s)
csl=2.998e8; %speed of light (m/s)

stack = scope_traceback(/structure)
;printdat,stack,nstr=3
dirname = file_dirname(stack[scope_level()-1].filename) + '/'
;printdat,dirname
;euvcs = read_asc(dirname+'mvn_euv_nm_h_o_pi_sig_mb.txt',format={wavelength:0.,Hphoto_cs:0.,Ox_photo_cs:0.})

;read cross-section files
openr,lun,dirname+'mvn_euv_nm_h_o_pi_sig_mb.txt',/get_lun
xsec_pi=replicate(0.,3,pui0.euvwb) ;fism bins (nm), H, O photo-ionization cross sections (Mb)  
readf,lun,xsec_pi
free_lun,lun

openr,lun,dirname+'mvn_swe_ev_h_o_ei_sig_mb.txt',/get_lun
xsec_ei=replicate(0.,3,pui0.sweeb) ;swea bins (eV), H, O electron impact cross sections (Mb)
readf,lun,xsec_ei
free_lun,lun

xsec_pi=transpose(xsec_pi)
xsec_ei=transpose(xsec_ei)
onesnt=replicate(1.,pui0.nt)

;FISM daily irradiance (W/m2/nm)
fismir=pui.data.euv.l3 ;FISM irradiances (W/cm2/nm)
fismen=hpc*csl/xsec_pi[*,0]*1e9; %FISM energy (J)
fismfl=fismir/(fismen#onesnt)/1e4; %FISM flux (/[cm2 s nm])
ifreq_pi_h=1e-18*(xsec_pi[*,1]#onesnt)*fismfl; differential photo-ionization frequency (s-1 nm-1)
ifreq_pi_o=1e-18*(xsec_pi[*,2]#onesnt)*fismfl;
i_pi_h=total(ifreq_pi_h,1) ;total photo-ionization frequency (s-1)
i_pi_o=total(ifreq_pi_o,1)
i_pi_h[where(~finite(i_pi_h),/null)]=1.2e-7 ;in case FISM data is not available, use default ionization frequency.
i_pi_o[where(~finite(i_pi_o),/null)]=2.1e-7
pui.model[0].ifreq.pi.nm=ifreq_pi_h
pui.model[1].ifreq.pi.nm=ifreq_pi_o
pui.model[0].ifreq.pi.tot=i_pi_h
pui.model[1].ifreq.pi.tot=i_pi_o

;%%%%%%SWIA data analysis
;%swiaef: solar wind ion energy flux (eV/[cm2 s sr eV])
cxsig=[2e-15,8e-16]; H, O solar wind proton charge exchange cross sections (cm2)
nsw=pui.data.swi.swim.density ;solar wind density (cm-3)
pui.data.swi.swim2.usw=sqrt(total(pui.data.swi.swim.velocity_mso^2,1)) ; solar wind speed (km/s)
usw=1e5*pui.data.swi.swim2.usw ; solar wind speed (cm/s)
fsw=nsw*usw; %solar wind number flux (cm-2 s-1)
pui.data.swi.swim2.fsw=fsw
mv=mp*usw ;solar wind proton momentum (g cm/s)
pui.data.swi.swim2.mfsw=mv*fsw ;solar wind proton momentum flux (g cm-1 s-2)
esw=.5*mp/qe*usw^2 ;solar wind proton energy (eV)
pui.data.swi.swim2.esw=esw
pui.data.swi.swim2.efsw=esw*fsw ;solar wind proton energy flux (eV cm-2 s-1)
ifreq_cx=fsw#cxsig; %charge exchange ionization frequency (s-1)

i_cx_h=ifreq_cx[*,0]
i_cx_o=ifreq_cx[*,1]
pui.model[0].ifreq.cx=i_cx_h
pui.model[1].ifreq.cx=i_cx_o
;ivel=sqrt(2*swiet*qe/mp); %ion velocity (cm/s)
;swiaefai=swiaef.*(ones(inn,1)*2*16*(swiasa1+swiasa2)); %angle integrated differential energy flux (eV/[cm2 s eV])
;swiadf=swiaefai./(ones(inn,1)*swiet'); %SWIA differential flux (/[cm2 s eV])
;swiadn=swiadf./(ones(inn,1)*ivel'); %SWIA differential density (/[cm3 eV])
;swian=swidee*swiaefai*(1./ivel); %SWIA density (cm-3)
;swiaf=swidee*sum(swiaefai,2); %SWIA flux (cm-2 s-1)
;swiae=sum(swiaefai,2)./sum(swiadf,2); %SWIA temperature (eV)
;swiav=sqrt(2*swiae*qe/mp); %SWIA velocity (cm/s)
;swiaf2=swian.*swiav;
;%%%%

;%%%%%%SWEA data analysis
sweaef=pui.data.swe.eflux ;solar wind electron energy flux (eV/[cm2 s sr eV])
sweaefpot=pui.data.swe.efpot
sweaenpot=pui.data.swe.enpot
evel=sqrt(2.*pui1.sweet*qe/me); %electron velocity in swea energy bins (cm/s)
evelpot=sqrt(2.*sweaenpot*qe/me); %electron velocity in s/c potential corrected swea energy bins (cm/s)
;sweadf=sweaef./(ones(inn,1)*sweaet(:,1)'); %SWEA differential flux (cm-2 s-1 sr-1 eV-1)
;sweadn=sweadf./(ones(inn,1)*evel'); %SWEA differential density (cm-3 sr-1 eV-1)

dvswea=0; %SWEA energy correction due to S/C potential
pui.data.swe.eden=4.*!pi*pui0.swedee*transpose(sweaef[0:63-dvswea,*])#(1./evel[0:63-dvswea]); %SWEA electron density (cm-3)
pui.data.swe.edenpot=total(4.*!pi*pui0.swedee*sweaefpot*(1./evelpot),1,/nan); %SWEA s/c potential corrected electron density (cm-3)
;sweae=sum(sweaef,2)./sum(sweadf,2); %SWEA temperature (eV)
ifreq_ei_h=4.*!pi*pui0.swedee*sweaef*(xsec_ei[*,1]#onesnt)*1e-18; %H electron impact ionization frequency (s-1 per energy bin)
ifreq_ei_o=4.*!pi*pui0.swedee*sweaef*(xsec_ei[*,2]#onesnt)*1e-18; %O electron impact ionization frequency (s-1 per energy bin)

xsec_ei_h=24000.*(sweaenpot-13.4)/(sweaenpot+40)^2.1 ;H electron impact cross sections (Mb) at s/c potential corrected SWEA energies
xsec_ei_o=12000.*(sweaenpot-13.4)/(sweaenpot+40)^1.8 ;O electron impact cross sections (Mb) at s/c potential corrected SWEA energies
xsec_ei_h[where(sweaenpot lt 13.6,/null)]=0. ;ioniztion energy threshold (eV)
xsec_ei_o[where(sweaenpot lt 13.6,/null)]=0. ;ioniztion energy threshold (eV)
ifreq_ei_h_pot=4*!pi*pui0.swedee*sweaefpot*xsec_ei_h*1e-18
ifreq_ei_o_pot=4*!pi*pui0.swedee*sweaefpot*xsec_ei_o*1e-18
i_ei_h_pot=total(ifreq_ei_h_pot,1,/nan); %H electron impact ionization frequency (s-1)
i_ei_o_pot=total(ifreq_ei_o_pot,1,/nan); %H electron impact ionization frequency (s-1)

i_ei_h=total(ifreq_ei_h,1); %H electron impact ionization frequency (s-1)
i_ei_o=total(ifreq_ei_o,1); %O electron impact ionization frequency (s-1)
i_ei_h[where(~finite(i_ei_h),/null)]=1.2e-8 ;in case SWEA data is not available, use default ionization frequency.
i_ei_o[where(~finite(i_ei_o),/null)]=2.1e-8
pui.model[0].ifreq.ei.en=ifreq_ei_h_pot
pui.model[1].ifreq.ei.en=ifreq_ei_o_pot
pui.model[0].ifreq.ei.tot=i_ei_h_pot
pui.model[1].ifreq.ei.tot=i_ei_o_pot
;%%%%

;ifreq=4.5e-7; O total ionization frequency (s-1) per Rahmati et al., 2014
ifreq_h=i_pi_h+i_cx_h+i_ei_h_pot; %H total ionization frequency (s-1)
ifreq_o=i_pi_o+i_cx_o+i_ei_o_pot; %O total ionization frequency (s-1)
pui.model[0].ifreq.tot=ifreq_h
pui.model[1].ifreq.tot=ifreq_o
if pui0.ns eq 3 then pui.model[2].ifreq.tot=ifreq_h ;other species are equal to H

store_data,'Ionization_Frequencies_(s-1)',pui.centertime,[[ifreq_o],[ifreq_h],[i_pi_o],[i_pi_h],[i_cx_o],[i_cx_h],[i_ei_o],[i_ei_h],[i_ei_o_pot],[i_ei_h_pot]]
options,'Ionization_Frequencies_(s-1)',yrange=[1e-9,1e-5],ylog=1,labels=['Otot','Htot','PIO','PIH','CXO','CXH','EIO','EIH','EIOpot','EIHpot'],labflag=-1

end