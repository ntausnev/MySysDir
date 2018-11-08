#!/usr/bin/ksh

. /etc/profile.d/modules.sh

module purge
module load comp/intel-15.0.3.187
#module load mpi/impi-4.1.3.048     # works
module load mpi/impi-5.1.1.109      # special for GR
export MODULEPATH=/discover/nobackup/projects/giss/local/modulefiles:$MODULEPATH
module load netcdf-4.5.0_impi-4.1.3.048_intel-15.0.3.187

module list


NUM_PROC=13
NUM_PROC=11

f_src="simple_xy_par_wr2.f90"
f_src="wr_rd_pnetcdf.f90"
#f_src="simple_xy_par_rd.f90"

f_obj="${f_src%.*}.o"    # abc.f90 --->  abc.o
f_exe="${f_src%.*}.exe"  # abc.f90 --->  abc.exe

rm -rf ${f_exe}
rm -rf ${f_obj}
rm -rf simple_xy_par.nc

ifort -c ${f_src} -o ${f_obj} -g -traceback -fpp -O2 -ftz \
    -convert big_endian -assume protect_parens -fp-model strict -warn nousage \
    -I/usr/local/other/pnetcdf/intel12.0.1.107_impi3.2.2.006/include \
    -I/discover/nobackup/projects/giss/local/netcdf/4.5.0_Intel-15.0.3.187/include

ifort -g -ftz  ${f_obj}   \
    -L/usr/local/other/pnetcdf/intel12.0.1.107_impi3.2.2.006/lib -lpnetcdf \
    -L/discover/nobackup/projects/giss/local/netcdf/4.5.0_Intel-15.0.3.187/lib -lnetcdf \
    -L/opt/local/lib -lnetcdff -lnetcdf -lmpigf -lmpi -lmpigi -ldl -lrt -lpthread \
    -o ${f_exe}

mpirun -np ${NUM_PROC} ./${f_exe}

echo " \nThe format of netCDF file: "
/usr/local/other/SLES11/netcdf4/4.1.3/intel-12.1.0.233/bin/ncdump -k simple_xy_par.nc


echo "\nCheck ncdump version 4:"
/usr/local/other/SLES11/netcdf4/4.1.3/intel-12.1.0.233/bin/ncdump -h simple_xy_par.nc

echo "\nCheck ncdump version 4:"
/usr/local/other/netcdf/4.1.2_intel-14.0.3/bin/ncdump -h simple_xy_par.nc

echo "\nCheck ncdump version 3:"
/usr/local/other/netcdf/3.6.2_intel-10.1.013/bin/ncdump -h simple_xy_par.nc

