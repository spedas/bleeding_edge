;+
;NAME: DSC_LOAD_MAG
;
;DESCRIPTION:
; Loads DSCOVR Fluxgate Magnetometer data
;
;KEYWORDS: (Optional)
; DOWNLOADONLY: Set to download files but *not* store data in TPLOT. 
; KEEP_BAD:     Set to keep quality flag variable and flagged data in the data arrays
; NO_DOWNLOAD:  Set to use only locally available files. Default is !dsc config.
; NO_UPDATE:    Set to only download new filenames. Default is !dsc config.
; TRANGE=:      Time range of interest stored as a 2 element array of
;                 doubles (as output by timerange()) or strings (as accepted by timerange()).
;                 Defaults to the range set in tplot or prompts for date if not yet set.
; TYPE=:        Data type (string)
;                 Valid options:
;                 'h0': 1-sec Definitive Data (default)
; VARFORMAT=:   Specify a subset of variables to store
; VERBOSE=:     Integer indicating the desired verbosity level.  Defaults to !dsc.verbose
; 
;KEYWORD OUTPUTS:
; TPLOTNAMES=: Named variable to hold array of TPLOT variable names loaded 
;   
;EXAMPLES:
;		dsc_load_mag
;		dsc_load_mag,varformat='*GSE*',/keep
;		dsc_load_mag,trange=['2016-08-15','2016-08-17'],/downloadonly
;		
;CREATED BY: Ayris Narock (ADNET/GSFC) 2017
;
; $LastChangedBy: nikos $
; $LastChangedDate: 2018-03-12 09:55:28 -0700 (Mon, 12 Mar 2018) $
; $LastChangedRevision: 24869 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/dscovr/load/dsc_load_mag.pro $
;-

PRO DSC_LOAD_MAG,TYPE=type,TRANGE=trange,DOWNLOADONLY=downloadonly,VARFORMAT=varformat, $
	NO_DOWNLOAD=no_download,NO_UPDATE=no_update,VERBOSE=verbose,KEEP_BAD=keep_bad,TPLOTNAMES=tn

COMPILE_OPT IDL2

dsc_init

rname = dsc_getrname()
if not isa(verbose,/int) then verbose=!dsc.verbose
if not isa(no_download,/int) then no_download = !dsc.no_download
if not isa(no_update,/int) then no_update = !dsc.no_update

if (isa(type,'undefined') and ~isa(type,/null)) then type = 'h0' $
	else if not isa(type,/string,/scalar) then begin
		dprint,dlevel=1,verbose=verbose,rname+": Data type keyword must be a scalar string."
		return
	endif
if not keyword_set(type) then type = 'h0'
if not keyword_set(varformat) then varformat = '*' $
	else varformat = varformat+' *FLAG1'
if not keyword_set(keep_bad) then keep_bad = 0


case type of
	'h0': pathformat = 'dscovr/h0/mag/YYYY/dscovr_h0_mag_YYYYMMDD_v??.cdf'
	else: begin
		dprint,dlevel=1,verbose=verbose,rname+": Data type '"+type.toString()+"' is not supported.'
		return
	end
endcase

relpathnames = file_dailynames(file_format=pathformat,trange=trange)
files = spd_download( $
	remote_file=relpathnames, remote_path=!dsc.remote_data_dir, local_path = !dsc.local_data_dir, $
	no_download = no_download, no_update = no_update, /last_version, /valid_only, $
	file_mode = '666'o, dir_mode = '777'o)

if files[0] eq '' then begin
	dprint,dlevel=2,verbose=verbose,rname+': No DSCOVR files found'
	return
endif

if keyword_set(downloadonly) then return


prefix = 'dsc_'+type+'_mag_'
cdf2tplot,file=files,varformat=varformat,verbose=verbose,prefix=prefix ,tplotnames=tn,/load_labels    ; load data into tplot variables
dprint,dlevel=4,verbose=verbose,rname+': tplotnames: ',tn

; Remove bad/unwanted data and set default plot options
if not keep_bad then begin
	get_data,prefix+'FLAG1',data=d
	bad = where(d.y ne 0, badcount, complement=good)
	del_str = '*PB5* '+prefix+'FLAG1'
endif else begin
	badcount = 0
	del_str = '*PB5*
endelse
store_data,delete=del_str
tn = strfilter(tn,del_str,delim=' ',/negate)

split_vec,strfilter(tn,'*B*GSE *B*RTN',delim=' '),names_out=vn
tn = [tn,vn]
tn = tn[where(tn ne '')]
tn_add = []
if badcount gt 0 then dprint,dlevel=2,verbose=verbose,rname+': Removing bad data points'

if ~((tn.length eq 1) and (tn[0] eq '')) then begin
	for i=0,tn.length-1 do begin
		get_data,tn[i],data=d,dlimits=md
		options,/def,tn[i],colors='g'
		dsc_set_ytitle,tn[i],metadata=md,verbose=verbose
		if badcount gt 0 then store_data,tn[i],data={x:d.x[good], y:d.y[good,*]}	;Remove bad data
		
		;Create Bphi and Btheta variables
		if (tn[i].Matches('_B1GSE$')) then begin
			get_data,tn[i],data=d ;grab again to avoid bad packets
			f2 = sqrt(d.y[*,0]^2d + d.y[*,1]^2d + d.y[*,2]^2d)
			btheta	=	!radeg * asin(d.y[*,2]/f2)
			bphi	=	!radeg * atan(d.y[*,1], d.y[*,0])
			ix = where(bphi lt 0., count)
			if (count ne 0) then bphi[ix] = 360. + bphi[ix]
			phiname = tn[i]+'_PHI'
			thetaname = tn[i]+'_THETA'
			store_data,phiname,data={x:d.x, y:bphi}
			options,/def,phiname,colors='g',ytitle='Bphi (GSE)',ysubtitle='[deg]', $
							yticks=4,ytickv=[0,90,180,270,360],yrange=[-15,375],ystyle=1,yminor=9
			store_data,thetaname,data={x:d.x, y:btheta}
			options,/def,thetaname,colors='g',ytitle='Btheta (GSE)',ysubtitle='[deg]', $
							yticks=4,ytickv=[-90,-45,0,45,90],yrange=[-100,100],ystyle=1,yminor=9
			tn_add = [phiname,thetaname]
			
		endif
	endfor
	if keep_bad then clear = check_math()	;Squash the expected math error messages from calculations with bad data/NaN
	tn = [tn,tn_add]
	
	; Set variable specific plot options
	options,/def,strfilter(tn,'*B*GSE *B*RTN',delim=' '), colors='bgr'
	options,/def,strfilter(tn,'*NUM*_PTS'),ysubtitle='[#]'
	options,/def,strfilter(tn,'*RANGE*'),'ysubtitle'
	options,/def,tn,datagap=-1
endif
end
