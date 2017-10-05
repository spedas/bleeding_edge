pro mvn_sep_mag_directions

name = 'mvn_B_30sec'


spice_vector_rotate_tplot,name,'MAVEN_SEP1',name=magname
magname=magname[0]
get_data,magname,time,vec
angle = acos(vec[*,0]/sqrt(total(vec^2,2)))*180/!pi
store_data,magname+'_angle',time,angle,dlim={colors:'b',yrange:[0,180],ystyle:1}

spice_vector_rotate_tplot,name,'MAVEN_SEP2',name=magname
magname=magname[0]
get_data,magname,time,vec
angle = acos(vec[*,0]/sqrt(total(vec^2,2)))*180/!pi
store_data,magname+'_angle',time,angle,dlim={colors:'r',yrange:[0,180],ystyle:1}

spice_vector_rotate_tplot,name,'MAVEN_MSO',name=magname,check_obj='MAVEN_SPACECRAFT'
magname=magname[0]
get_data,magname,time,vec
angle = acos(vec[*,0]/sqrt(total(vec^2,2)))*180/!pi
store_data,magname+'_angle',time,angle,dlim={yrange:[0,180],ystyle:1}




get_data,name,time,bvec
sunvec=bvec
sunvec[*,0]=1
sunvec[*,1]=0
sunvec[*,2]=0
store_data,'SunVec',time,sunvec, dlim={spice_frame:'MAVEN_MSO'}


;xyz_to_polar,n
spice_vector_rotate_tplot,'SunVec','MAVEN_SEP1',check_obj='MAVEN_SPACECRAFT',name=sunname
sunname=sunname[0]
get_data,sunname,time,vec
angle = acos(vec[*,0])*180/!pi
store_data,sunname+'_angle',time,angle,dlim={colors:'b'}
;xyz_to_polar,sunname

spice_vector_rotate_tplot,'SunVec','MAVEN_SEP2',check_obj='MAVEN_SPACECRAFT',name=sunname
sunname=sunname[0]
get_data,sunname,time,vec
angle = acos(vec[*,0])*180/!pi
store_data,sunname+'_angle',time,angle,dlim={colors:'r'}

store_data,'SunVec_angle',data='SunVec_MAVEN_SEP?_angle'
end

