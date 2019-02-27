#!/bin/sh
#
# Script para calcular wp y pv segun paper CLIMIX (Jerez et al 2015)
#
###################################################
#sfa 
# El script espera encontrar tres ficheros, uno de radiacion (rsds), otro de temperatura (tas)  en superficie y otro de viento en superficie vwd
# Las unidades son importantes, temperatura en grados celsius, radicion en W/m2 y velocidad del viento a 10m en m/s
# También es importante que los ficheros tengan los mismos nombres de variables,
# Los ficheros finales ya van comprimidos. Es importantante la version de CDO. Algunos comandos pueden no funcionar
##### queda añadir los atributos generales al fichero..... tendremos que definirlos más adelante
# by JP
set -ex
############  #########################################################################33
filerad=rad.nc
filetas=tas.nc
filevwd=vwd.nc
cdo merge $filerad $filetas $filevwd todos.nc
#Otra opción que podemos barajar es utilizar un solo fichero con todas las variables juntas. Esto puede simplificar bastante si ponemos los atributos generales del tiron 
#################################################################
#
#calculo de la potencia fotovoltaica
#
filepv=pvpot.nc
cdo -f nc4 -z zip_1 expr,'pvpot=(1-0.005*((4.3+0.943*tas+0.028*rsds-1.528*vwd)-25))*rsds/1000;' todos.nc  $filepv

#
#calculo del viento en altura 
#
href=80  # Altura de referencia
filehub=wind-$href.nc
cdo  -P 4 expr,'winhb=vwd*('${href}'/10)^(1/7);' $filevwd  $filehub
#
# Calculamos la potencia a partir de la curva de potencia
#
va=3.5; va3=$(echo ${va}^3|bc -l)       #Velocidad de arranque
vn=13;vn3=$(echo ${vn}^3|bc -l)         #velocidad nominal
vc=24                                   #velocidad de corte
filewp=wp-$href.nc
cdo -P 4 -f nc4 -z zip_1 -setattribute,wp@units="GW" -expr,'wp=((( (winhb < '$va') || (winhb > '$vc'))) ? 0 : ((winhb>'$vn') ? 1: ((winhb^3-'$va3')/('$vn3-$va3' ))    ))'  $filehub $filewp 


