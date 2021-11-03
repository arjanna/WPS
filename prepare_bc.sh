#!/bin/bash
c=0

#for filein in $(ls /scratch/ms/de/dfy/Share/june_exp_bc/boundary_data/*/iefff00000000)
#do
for filein in  $(ls /scratch/ms/de/dfy/Share/june_exp_bc/boundary_data/*/iefff00000000) 
do
    rm -rf tmp${c}0000 wlev* tmp${c}0000_w tmp${c}0000_pm pmsl pmsl_ok testwso.grb new*.grb wso.grb tmpc${c}0000 tmp${c}0000 pmsl tmp${c}0000_pm pmsl_ok  
    grib_copy -w typeOfLevel!=isobaricInhPa $filein tmpc${c}0000
    cdo -aexpr,'relhum_2m=100-5*(T_2M-TD_2M)' -aexpr,'relhum_2m=100-5*(T_2M-TD_2M)'  -aexpr,'RELHUM=QV/(0.622*6.112*exp(17.65*(T-273.15)/(T-29.65))/(P - 6.112*exp(17.65*(T-273.15)/(T-29.65))   )    )' -aexpr,'FI=HHL/9.81' -aexpr,'PMSL=PS*(1- (0.0065*HSURF/ ( T_2M + 0.0065*HSURF  )  )  )^(-5.257)' tmpc${c}0000 tmp${c}0000
    cdo selvar,PMSL tmp${c}0000 pmsl
    cdo delvar,PMSL tmp${c}0000 tmp${c}0000_pm
    grib_set -s typeOfFirstFixedSurface=101 pmsl pmsl_ok
    cat pmsl_ok >> tmp${c}0000_pm
#    cdo splitlevel -selvar,W_SO  tmp${c}0000_pm wlev${c}
#    cdo delvar,W_SO  tmp${c}0000_pm tmp${c}0000_w
#    for slevs in 1 3 9 27 81 243 729
#    do
#      ( export multi=$(((slevs*2)*10))
#       lev=$(printf %.2f "$((1 * $slevs ))e-2" | sed -e s:,:.:g)
#       echo $multi
#       cdo -s -aexpr,"W_SO=(W_SO/"${multi}")/0.5"  wlev${c}00${lev}.grb tm${c}l${lev}.grb
#       grib_set -s typeOfFirstFixedSurface=111 tm${c}l${lev}.grb new${c}l${lev}.grb
# ) &
#    done
#    wait
#    rm -rf wso.grb && cdo merge new*.grb wso.grb && rm -rf new*.grb
#    cdo merge tmp${c}0000_w wso.grb testwso.grb
    sed -e "s:%FILEIN%:tmp${c}0000_pm:g" -e "s:%FILEOUT%:tests.grb:g" NAMELIST_ICONREMAP_template > NAMELIST_ICONREMAP
    PIDjob=$(qsub LL_det)
    check=1
    while [ $check -eq 1 ]
    do
      check=$(qstat -u deav | grep "$PIDjob" | wc -l)
      sleep 30;
      echo "Checking job: " $PIDjob
      qstat -u deav | grep "$PIDjob"
    done
    [[ ! -f READY ]] && echo "READY file does not exists." && exit 1
    rm -rf tmp${c}0000 wlev*.grb wso.grb testwso.grb tmp${c}0000_w tmpc${c}0000 &
    f=$(printf "%05d" $c)
    mv tests.grb bc_${f}.grb
    c=$(( c+1 ))
done
wait

