;+
;NAME: DSC_LOAD_FC
;
;DESCRIPTION:
; Loads DSCOVR Faraday Cup data
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
;                 'h1': 1-minute Isotropic Maxwellian parameters for solar wind protons (default)
; VARFORMAT=:   Specify a subset of variables to store
; VERBOSE=:     Integer indicating the desired verbosity level.  Defaults to !dsc.verbose
;
;KEYWORD OUTPUTS:
; TPLOTNAMES=: Named variable to hold array of TPLOT variable names loaded
;
;EXAMPLE:
;		dsc_load_fc
;		dsc_load_fc,varformat='*THERMAL*',/keep
;		dsc_load_fc,trange=['2016-08-15','2016-08-17'],/downloadonly
;		
;CREATED BY: Ayris Narock (ADNET/GSFC) 2017
;
; $LastChangedBy: nikos $
; $LastChangedDate: 2018-03-12 09:55:28 -0700 (Mon, 12 Mar 2018) $
; $LastChangedRevision: 24869 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/dscovr/load/dsc_load_fc.pro $
;-

PRO DSC_LOAD_FC,TYPE=type,TRANGE=trange,DOWNLOADONLY=downloadonly,VARFORMAT=varformat, $
	NO_DOWNLOAD=no_download,NO_UPDATE=no_update,VERBOSE=verbose,KEEP_BAD=keep_bad,TPLOTNAMES=tn

COMPILE_OPT IDL2

dsc_init

rname = dsc_getrname()
if not isa(verbose,/int) then verbose=!dsc.verbose
if not isa(no_download,/int) then no_download = !dsc.no_download
if not isa(no_update,/int) then no_update = !dsc.no_update

if (isa(type,'undefined') and ~isa(type,/null)) then type = 'h1' $
else if not isa(type,/string,/scalar) then begin
	dprint,dlevel=1,verbose=verbose,rname+": Data type keyword must be a scalar string."
	return
endif

if not keyword_set(varformat) then varformat = '*' $
	else begin
		if ~(varformat.Matches('\*_*DELTA') or varformat.Matches('\*')) then begin ;if you haven't included '*','..*DELTA..' or '..*_DELTA..'
			varsplit = varformat.Split(' ')
			foreach v,varsplit do begin
				if ~v.Matches('DELTA') then begin
					if ~varformat.Matches(v+'_DELTA') then varformat = varformat+' '+v+'_DELTA'
				endif
			endforeach
		endif
		varformat = varformat+' *DQF*'
	endelse
if not keyword_set(keep_bad) then keep_bad = 0

case type of
	'h1': begin
		pathformat = 'dscovr/h1/faraday_cup/YYYY/dscovr_h1_fc_YYYYMMDD_v??.cdf'
	end
	else: begin
		dprint,dlevel=1,verbose=verbose,rname+": Data type '"+type.toString()+"' is not supported."
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

prefix = 'dsc_'+type+'_fc_'
cdf2tplot,file=files,varformat=varformat,verbose=verbose,prefix=prefix ,tplotnames=tn,/load_labels    ; load data into tplot variables
dprint,dlevel=4,verbose=verbose,rname+': tplotnames: ',tn

; Remove bad/unwanted data and set default plot options
del_str = prefix+'*PB5* '+prefix+'*DELTA*'
get_data,prefix+'DQF',data=d
if not keep_bad then begin
	bad = where(d.y ne 0, badcount, complement=good)
	del_str = prefix+'*DQF* '+del_str
endif else begin
	badcount = 0
	good = indgen(n_elements(d.y))
endelse

split_vec,strfilter(tn,'*GSE*'),names_out=vn
tn=[tn,vn]
tn = tn[where(tn ne '')]
tn = strfilter(tn,del_str,delim=' ',/negate)
tnfull = tn
if keep_bad then tn=strfilter(tn,'*DQF*',/negate)	
tndy = []

if badcount gt 0 then dprint,dlevel=2,verbose=verbose, rname+': Removing bad data points'
if ~((tn.length eq 1) and (tn[0] eq '')) then begin
	for i=0,tn.length-1 do begin
		dvar = tn[i].Matches('_[xyz]$') ? tn[i].Substring(0,-2)+'DELTA'+tn[i].Substring(-2) : tn[i]+'_DELTA'
		get_data,tn[i],data=d,dlimits=md
		get_data,dvar,data=dy
		
		options,/def,tn[i],noerrorbars=1,dsc_dy=1
		dsc_set_ytitle,tn[i],metadata=md,verbose=verbose,title=ytitle
		
		d_x = d.x[good]
		d_y = d.y[good,*]
		dy_y = dy.y[good,*]
		str_element,d,'x',d_x,/add_rep
		str_element,d,'y',d_y,/add_rep
		str_element,d,'dy',dy_y,/add_rep
		str_element,dy,'y',dy_y,/add_rep
		store_data,tn[i],data=d,limits=0l
		store_data,dvar,data=dy,limits=0l
	
		;store DY as separate variables for use by gui and dsc_dyplot
		add_data,tn[i],dvar,newname=tn[i]+'+DY',copy=2
		dif_data,tn[i],dvar,newname=tn[i]+'-DY',copy=2
		store_data,tn[i]+'_wCONF',data=[tn[i]+'+DY',tn[i],tn[i]+'-DY']
		options,/def,tn[i]+'*DY','labels'
		options,/def,tn[i]+'+DY',ytitle=ytitle+' +DY',ysubtitle=md.ysubtitle
		options,/def,tn[i]+'-DY',ytitle=ytitle+' -DY',ysubtitle=md.ysubtitle
		options,/def,tn[i]+'_wCONF',ytitle=ytitle+' (w/Conf)',ysubtitle=md.ysubtitle,dsc_dy=1
		tnfull = [tnfull,tn[i]+'+DY',tn[i]+'-DY',tn[i]+'_wCONF']
		tndy   = [tndy,tn[i]+'+DY',tn[i]+'-DY',tn[i]+'_wCONF']
		
		; Create V magnitude if V_GSE loaded
		if tn[i].Matches('_V_GSE$') then begin
			get_data,tn[i],data=d ;grab again to avoid bad data packets
			newdata = sqrt(d.y[*,0]^2. + d.y[*,1]^2. + d.y[*,2]^2.)
			newname = tn[i].Substring(0,-5)
			store_data,newname,data={x:d.x, y:newdata}
			options,/def,newname,colors=40,ytitle='V Magnitude',ysubtitle='[km/s]'
			tnfull = [tnfull,newname]
		endif
	endfor
	if keep_bad then clear = check_math()	;Squash the expected math error messages from calculations with bad data/NaN
	
	; Set variable specific plot options
	options,/def,strfilter(tn,'*GSE'), colors='bgr',dsc_dy=0
	options,/def,strfilter(tn,'*V_GSE_*'),colors=40,dsc_dycolor=3
	options,/def,strfilter(tn,'*_V_GSE_* *GSE',delim=' ',/negate),colors=252,dsc_dycolor=186
	
	options,/def,strfilter(tndy,'*GSE_wCONF'),dsc_dy=0
	options,/def,strfilter(tndy,'*_V_*DY'),colors=[3,3,3]
	options,/def,strfilter(tndy,'*_V_*CONF'),dsc_dycolor=3

	options,/def,strfilter(tndy,'*_V_*DY *CONF',delim=' ',/negate),colors=186
	options,/def,strfilter(strfilter(tndy,'*CONF'),'*_V_*',/negate),dsc_dycolor=186

endif

store_data,delete=del_str
tn = tnfull
options,/def,tn,datagap=-1
END
