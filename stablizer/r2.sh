#!/bin/bash
c=1
while [ $c -le $2 ]
do
    qsub << EOJ

#!/bin/bash

#PBS -A drh20_collab
#PBS -m abe
#PBS -N $1$c
#PBS -l nodes=1
#PBS -l walltime=240:00:00
#PBS -j oe
#PBS -o $PWD/combined.log

cd $PWD
julia $1.jl $c

EOJ

((c++))
done
