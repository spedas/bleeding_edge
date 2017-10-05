;+
;; %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
;; % 
;; % USE: Reads NOAA-POES CDF files from:
;; %      http://www.ngdc.noaa.gov/stp/satellite/poes/index.html
;; %
;; %
;; -----written by Wen Li based on Drew Turner's matlab code-----
;; %
;; % DATE: January 2011
;; %
;; % INPUTS: filename  :   CDF file of data available on website above
;; %         
;; % 
;; % OUTPUT: D         :   Data structure containing file info and Matlab time
;; %                       array
;; %
;; % NOTES: The majority of this script is devoted to correcting for the
;; %        proton contamination in the electron fluxes.  The method uses that
;; %        of Lam et al. [2010] and Horne et al. [2009] and is the accepted
;; %        method used by NOAA and ViRBO.  I have converted it directly from
;; %        the original Fortran correction codes available at ViRBO.
;; %
;; %        Output is converted to appropriate flux units for either integral 
;; %        flux [#/s/sr/cm^2] or differential flux [#/s/sr/cm^2/keV] depending
;; %        on type of each instrument channel
;; %        Original data (i.e. raw data from files) units of Counts [#/sec]
;; %
;; %
;; %
;; %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
;; % THIS SNIPPET SHOWS HOW TO DECONTAMINATE POES DATA USING THE LAM ET AL. METHOD:
;; % Correct for contaminated electron channels based on Lam et al. method,
;; % which is available on ViRBO in Fortran files:
;; % http://virbo.org/svn/virbo/poes/noaa15+/unpack_sem2.f
;
;$LastChangedBy: egrimes $
;$LastChangedDate: 2015-04-15 15:06:00 -0700 (Wed, 15 Apr 2015) $
;$LastChangedRevision: 17331 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/poes/poes_contamination_removal.pro $
;-

pro poes_contamination_removal,tname_mep0P=tname_mep0P,tname_mep90P=tname_mep90P,tname_mep0E=tname_mep0E,tname_mep90E=tname_mep90E,sci=sci

get_data,tname_mep0P,data=d0P
get_data,tname_mep90P,data=d90P
get_data,tname_mep0E,data=d0E
get_data,tname_mep90E,data=d90E

;; % Bowtie energies for proton channels
Ebt = [52.0, 138.0, 346.0, 926.0, 2628.0];
;; % Energy channel boundaries
Echannel = [30.0, 80.0, 240.0, 800.0, 2500.0];
;; % Delta E initial values
dE1 = 0.0;
dE2 = 0.0;

ProtCal=[49.3, 147.9, 345.5, 461.8, 474.7]
E30keV0=dblarr(n_elements(d0P.x))
E100keV0=E30keV0
E300keV0=E30keV0
E30keV90=E30keV0
E100keV90=E30keV0
E300keV90=E30keV0

;; % Electron correction: use exponential fits to the corrected proton data
;; % and use it to correct the eletron channels
for i = 0,n_elements(d0P.x)-1 do begin
E0fin=dblarr(2)
corr0=dblarr(3)
corr90=dblarr(3)


;; change counts (#/sec) to differential flux (#/s-str-cm^2-keV).  Note that counts/sec * 100 = flux in units of #/cm2/sec/ster
    ptemp0 = [d0P.y[i,0]/ProtCal[0], d0P.y[i,1]/ProtCal[1], d0P.y[i,2]/ProtCal[2], d0P.y[i,3]/ProtCal[3], d0P.y[i,4]/ProtCal[4]]*100.
    ptemp90 = [d90P.y[i,0]/ProtCal[0], d90P.y[i,1]/ProtCal[1], d90P.y[i,2]/ProtCal[2],d90P.y[i,3]/ProtCal[3], d90P.y[i,4]/ProtCal[4]]*100.

    ;; % 0 degree data: 
    ;; % First check that there is proton data in two adjacent channels
    for ind = 1, 2 do begin
        if (ptemp0[ind] gt 0.0 and ptemp0[ind+1] gt 0.0) then begin
            ;; % Calculate E0 assuming that flux = exp(E0*energy)
            E0 = (alog(ptemp0[ind])-alog(ptemp0[ind+1])) / (Ebt[ind] - Ebt[ind+1]);
            E0init = 0.0;
            n = 0;
            ;; % Now calculate a new dE based on this E0 and the bowtie
            ;; % approximation
            while (abs((E0-E0init)/E0init) gt 0.01 and n lt 500) do begin
                E0init = E0;
                ;; % Calculate new dE for the first energy channel using E0
                dE1 = ((exp(-1.0*Ebt[ind]*E0init)) / E0init) * (exp(Echannel[ind+1]*E0init) - exp(Echannel[ind]*E0init));
                ;; % Calculate new dE for the second energy channel using E0
                dE2 = ((exp(-1.0*Ebt[ind+1]*E0init)) / E0init) * (exp(Echannel[ind+2]*E0init) - exp(Echannel[ind+1]*E0init));
                ;; % Calculate a new flux for the first energy channel
                protemp1 = ptemp0[ind]*ProtCal[ind]/dE1;
                ;; % Calculate a new flux for the second energy channel
                protemp2 = ptemp0[ind+1]*ProtCal[ind+1]/dE2;
                ;; % Calculate a new E0
                E0 = (alog(protemp1)-alog(protemp2)) / (Ebt[ind] - Ebt[ind+1]);
                n = n + 1;
            endwhile
            E0fin[ind-1] = E0;
         endif else begin
            E0fin[ind-1] = -9999.0;
        endelse
    endfor

    ;; % Now calculate the appropriate corrections using E0fin

    if E0fin[0] gt -9999.0 then begin
        corr0[0] = ptemp0[1]*ProtCal[1]*(exp(E0fin[0]*Echannel[2])-exp(E0fin[0]*210))/(exp(E0fin[0]*Echannel[2])-exp(E0fin[0]*Echannel[1]))$
            + ptemp0[2]*ProtCal[2] + ptemp0[3]*ProtCal[3];
    endif else begin
        corr0[0] = ptemp0[1]*ProtCal[1]*(Echannel[2]-210)/(Echannel[2]-Echannel[1]) + ptemp0[2]*ProtCal[2] + ptemp0[3]*ProtCal[3];
    endelse
    
    if E0fin[1] gt -9999.0 then begin
        corr0[1] = ptemp0[2]*ProtCal[2]*(exp(E0fin[1]*Echannel[3])-exp(E0fin[1]*280))/(exp(E0fin[1]*Echannel[3])-exp(E0fin[1]*Echannel[2]))$
            + ptemp0[3]*ProtCal[3];
     
        corr0[2] = ptemp0[2]*ProtCal[2]*(exp(E0fin[1]*Echannel[3])-exp(E0fin[1]*440))/(exp(E0fin[1]*Echannel[3])-exp(E0fin[1]*Echannel[2]))$
            + ptemp0[3]*ProtCal[3];
    endif else begin
        corr0[1] = ptemp0[2]*ProtCal[2]*(Echannel[3]-280)/(Echannel[3]-Echannel[2]) + ptemp0[3]*ProtCal[3];
     
        corr0[2] = ptemp0[2]*ProtCal[2]*(Echannel[3]-440)/(Echannel[3]-Echannel[2]) + ptemp0[3]*ProtCal[3];
    endelse
    
    ;; % Correct appropriate channels: corr0 is in integra flux, so
    ;; devided by 100 to get counts

    E30keV0[i]=d0E.y[i,0]-corr0[0]/100.
    E100keV0[i]=d0E.y[i,1]-corr0[1]/100.
    E300keV0[i]=d0E.y[i,2]-corr0[2]/100.

    ;; E30keV0[i]=E30keV0[i]-E100keV0[i]
    ;; E100keV0[i]=E100keV0[i]-E300keV0[i]
  
   
    ;; % 90 degree data: 
    ;; % First check that there is proton data in two adjacent channels
    for ind = 1, 2 do begin
        if (ptemp90[ind] gt 0.0 and ptemp90[ind+1] gt 0.0) then begin
            ;; % Calculate E0 assuming that flux = exp(E0*energy)
            E0 = (alog(ptemp90[ind])-alog(ptemp90[ind+1])) / (Ebt[ind] - Ebt[ind+1]);
            E0init = 0.0;
            n = 0;
            ;; % Now calculate a new dE based on this E0 and the bowtie
            ;; % approximation
            while (abs((E0-E0init)/E0init) gt 0.01 and n lt 500) do begin
                E0init = E0;
                ;; % Calculate new dE for the first energy channel using E0
                dE1 = ((exp(-1.0*Ebt[ind]*E0init)) / E0init) * (exp(Echannel[ind+1]*E0init) - exp(Echannel[ind]*E0init));
                ;; % Calculate new dE for the second energy channel using E0
                dE2 = ((exp(-1.0*Ebt[ind+1]*E0init)) / E0init) * (exp(Echannel[ind+2]*E0init) - exp(Echannel[ind+1]*E0init));
                ;; % Calculate a new flux for the first energy channel
                protemp1 = ptemp90[ind]*ProtCal[ind]/dE1;
                ;; % Calculate a new flux for the second energy channel
                protemp2 = ptemp90[ind+1]*ProtCal[ind+1]/dE2;
                ;; % Calculate a new E0
                E0 = (alog(protemp1)-alog(protemp2)) / (Ebt[ind] - Ebt[ind+1]);
                n = n + 1;
            endwhile
            E0fin[ind-1] = E0;
        endif else begin
            E0fin[ind-1] = -9999.0;
        endelse
    endfor
    ;; % Now calculate the appropriate corrections using E0fin

    if E0fin[0] gt -9999.0 then begin
        corr90[0] = ptemp90[1]*ProtCal[1]*(exp(E0fin[0]*Echannel[2])-exp(E0fin[0]*210))/(exp(E0fin[0]*Echannel[2])-exp(E0fin[0]*Echannel[1]))$
            + ptemp90[2]*ProtCal[2] + ptemp90[3]*ProtCal[3];
    endif else begin
        corr90[0] = ptemp90[1]*ProtCal[1]*(Echannel[2]-210)/(Echannel[2]-Echannel[1]) + ptemp90[2]*ProtCal[2] + ptemp90[3]*ProtCal[3];
    endelse
    
    if E0fin[1] gt -9999.0 then begin
        corr90[1] = ptemp90[2]*ProtCal[2]*(exp(E0fin[1]*Echannel[3])-exp(E0fin[1]*280))/(exp(E0fin[1]*Echannel[3])-exp(E0fin[1]*Echannel[2]))$
            + ptemp90[3]*ProtCal[3];
     
        corr90[2] = ptemp90[2]*ProtCal[2]*(exp(E0fin[1]*Echannel[3])-exp(E0fin[1]*440))/(exp(E0fin[1]*Echannel[3])-exp(E0fin[1]*Echannel[2]))$
            + ptemp90[3]*ProtCal[3];
    endif else begin
        corr90[1] = ptemp90[2]*ProtCal[2]*(Echannel[3]-280)/(Echannel[3]-Echannel[2]) + ptemp90[3]*ProtCal[3];
     
        corr90[2] = ptemp90[2]*ProtCal[2]*(Echannel[3]-440)/(Echannel[3]-Echannel[2]) + ptemp90[3]*ProtCal[3];
    endelse

    ;; % Correct appropriate channels: corr90 are in integral flux
    ;; devided by 100 to get counts

    E30keV90[i]=d90E.y[i,0]-corr90[0]/100.
    E100keV90[i]=d90E.y[i,1]-corr90[1]/100.
    E300keV90[i]=d90E.y[i,2]-corr90[2]/100.

    ;; E30keV90[i]=E30keV90[i]-E100keV90[i]
    ;; E100keV90[i]=E100keV90[i]-E300keV90[i]

 endfor
ind_30keV0=where(E30keV0 lt 0)
ind_100keV0=where(E100keV0 lt 0)
ind_300keV0=where(E300keV0 lt 0)

ind_30keV90=where(E30keV90 lt 0)
ind_100keV90=where(E100keV90 lt 0)
ind_300keV90=where(E300keV90 lt 0)

if ind_30keV0[0] ge 0 then E30keV0[ind_30keV0] = 0.
if ind_100keV0[0] ge 0 then E100keV0[ind_100keV0] = 0.
if ind_300keV0[0] ge 0 then E300keV0[ind_300keV0] = 0.

if ind_30keV90[0] ge 0 then E30keV90[ind_30keV90] = 0.
if ind_100keV90[0] ge 0 then E100keV90[ind_100keV90] = 0.
if ind_300keV90[0] ge 0 then E300keV90[ind_300keV90] = 0.

;;'*mep*E_c' are in counts (#/sec)
store_data,strjoin(sci+'_mep0E_c'),data={x:d0E.x,y:[[E30keV0],[E100keV0],[E300keV0]]},dlim={labels:['30keV0','100keV0','300keV0']}
store_data,strjoin(sci+'_mep90E_c'),data={x:d90E.x,y:[[E30keV90],[E100keV90],[E300keV90]]},dlim={labels:['30keV90','100keV90','300keV90']}

end
