pro barrel_sp_brem,x,a,f,pder
e0=a[5] ;frozen
f= a[0] * exp(-(e0/(e0^a[1]-x^a[1])))/x^a[2]*exp(-a[3]/(x-a[4]))
end
