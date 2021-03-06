#--------------------------------------------------------------------------#
# LICENSE INFO:                                                            #
#--------------------------------------------------------------------------#
#    This file is part of CAMPARI.                                         #
#                                                                          #
#    Version 3.0                                                           #
#                                                                          #
#    Copyright (C) 2017, The CAMPARI development team (current and former  #
#                        contributors)                                     #
#                        Andreas Vitalis, Adam Steffen, Rohit Pappu, Hoang #
#                        Tran, Albert Mao, Xiaoling Wang, Jose Pulido,     #
#                        Nicholas Lyle, Nicolas Bloechliger, Marco Bacci,  #
#                        Davide Garolini, Jiri Vymetal                     #
#                                                                          #
#    Website: http://sourceforge.net/projects/campari/                     #
#                                                                          #
#    CAMPARI is free software: you can redistribute it and/or modify       #
#    it under the terms of the GNU General Public License as published by  #
#    the Free Software Foundation, either version 3 of the License, or     #
#    (at your option) any later version.                                   #
#                                                                          #
#    CAMPARI is distributed in the hope that it will be useful,            #
#    but WITHOUT ANY WARRANTY; without even the implied warranty of        #
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the         #
#    GNU General Public License for more details.                          #
#                                                                          #
#    You should have received a copy of the GNU General Public License     #
#    along with CAMPARI.  If not, see <http://www.gnu.org/licenses/>.      #
#--------------------------------------------------------------------------#
# AUTHORSHIP INFO:                                                         #
#--------------------------------------------------------------------------#
#                                                                          #
# MAIN AUTHOR:   Andreas Vitalis                                           #
# CONTRIBUTIONS: Adam Steffen, Albert Mao, Davide Garolini                 #
#                                                                          #
#--------------------------------------------------------------------------#

CAMPARI_HOME=/packages/campari
                                                                                                                                  
# x86_64 locale (Default)
ARCH=x86_64
ARCHXDR=lnx
BIN_DIR=${CAMPARI_HOME}/bin
LIB_DIR=${CAMPARI_HOME}/lib
SRC_DIR=${CAMPARI_HOME}/source
FF=gfortran
CC=gcc
LLFLAGS=-O3
EXTRA_LIBS=
MPIFF=mpif90
MPILFLAGS=-O3
MPIEXTRA_LIBS=
MV=/bin/mv
RM=/bin/rm
CP=/bin/cp -p
USE_INTERNAL_XDR=1
USE_INTERNAL_HSL=1
INTELDEFAULTS=-O3 -real-size 64 -override-limits -stand f03 -fpp
INTELDEBUG=-check bounds -check uninit -check arg_temp_created -check pointers -traceback #-g -debug extended -debug-parameters all
SUNDEFAULTS=-r8const -fpp -xO4 -ftrap=common,no%overflow
SUNDEBUG=-xcheck=init_local -g
GNUDEFAULTS=-cpp -O3 -fall-intrinsics -ffpe-trap=invalid,zero -std=f2008 -fdefault-real-8 -fdefault-double-8
GNUDEBUG=-fbacktrace -fbounds-check -fcheck-array-temporaries -g
CRAYDEFAULTS=-K trap=inv,divz -emfF -dp -sreal64 -J '.'
CRAYDEBUG=-emfFD
PGIDEFAULTS=-Mallocatable=03 -Mfree -Mextend -Mpreprocess -Mbackslash -DPGI_FORTRAN
PGIDEBUG=-g
COMPDEFAULTS=${GNUDEFAULTS} # ${GNUDEBUG}

# Please define any local settings in the file Makefile.local and avoid certain strings in pathnames, as they
# are run through patsubst (see below)
include Makefile.local
#
# rewrite compilation options for NetCDF-mandatory mode
NC_FFLAGS=$(patsubst -DLINK_NETCDF,,$(FFLAGS)) -DLINK_NETCDF
NC_MPIFFLAGS=$(patsubst -DLINK_NETCDF,,$(MPIFFLAGS)) -DLINK_NETCDF

# Include the script-generated module dependencies: note this uses LIB_DIR, SRC_DIR and ARCH
include DEPENDENCIES

# to add a module, add the module here, add the module in make_dependencies.sh, re-run make_dependencies, and compile
PREPREMODS=accept aminos atoms clusters commline contacts cutoffs diffrac dipolavg distrest dssps ems energies ewalds forces fos fyoc grandensembles grids inter interfaces ionize iounit keys math mcgrid mcsums mini molecule movesets mpistuff ncdm paircorr params pdb polyavg polypep sequen shakeetal system tabpot threads torsn ujglobals units wl zmatrix

PREMODS=$(addsuffix .f90,$(PREPREMODS))
MODULES=$(patsubst %.f90,$(SRC_DIR)/mod_%.f90,$(PREMODS)) 
MODOBJS=$(patsubst %.f90,${LIB_DIR}/${ARCH}/%.o,$(PREMODS))
MPIMODOBJS=$(patsubst %.f90,${LIB_DIR}/${ARCH}/mpi/%.o,$(PREMODS))
THREADMODOBJS=$(patsubst %.f90,${LIB_DIR}/${ARCH}/threads/%.o,$(PREMODS))
MPITHREADMODOBJS=$(patsubst %.f90,${LIB_DIR}/${ARCH}/mpi_threads/%.o,$(PREMODS))

print:
	echo "${MODOBJS}"

CHECKTARGETS=$(findstring camp_ncminer,$(MAKECMDGOALS)) $(findstring campari,$(MAKECMDGOALS))
ifeq ($(CHECKTARGETS),camp_ncminer campari)
$(error Please do not use mixed targets in invocation of Makefile)
endif

ifeq ($(strip $(CHECKTARGETS)),camp_ncminer)
FFLAGS2=$(NC_FFLAGS)
MPIFFLAGS2=$(NC_MPIFFLAGS)
else
FFLAGS2=$(FFLAGS)
MPIFFLAGS2=$(MPIFFLAGS)
endif

# figure out whether we need to compile XDR
LINKDEPS1=library
LINKDEPS2=library_threads
LINKDEPS3=library_mpi
LINKDEPS4=library_mpi_threads

ifeq ($(USE_INTERNAL_XDR),1)
ifeq ($(findstring  -DLINK_XDR ,$(FFLAGS2)), -DLINK_XDR )
LINKDEPS1+=${LIB_DIR}/${ARCH}/libxdrf.a
LINKDEPS2+=${LIB_DIR}/${ARCH}/libxdrf.a
LINKDEPS3+=${LIB_DIR}/${ARCH}/libxdrf.a
LINKDEPS4+=${LIB_DIR}/${ARCH}/libxdrf.a
EXTRA_LIBS+=${LIB_DIR}/${ARCH}/libxdrf.a
MPIEXTRA_LIBS+=${LIB_DIR}/${ARCH}/libxdrf.a
endif
endif

# same for HSL
HSLMODS=hsl_ma48_single hsl_ma48_double hsl_zd11_single hsl_zd11_double
ifeq ($(USE_INTERNAL_HSL),1)
ifeq ($(findstring  -DLINK_HSL ,$(FFLAGS2)), -DLINK_HSL )
LINKDEPS1+=${LIB_DIR}/${ARCH}/libhsl.a
LINKDEPS2+=${LIB_DIR}/${ARCH}/libhsl.a
LINKDEPS3+=${LIB_DIR}/${ARCH}/libhsl.a
LINKDEPS4+=${LIB_DIR}/${ARCH}/libhsl.a
EXTRA_LIBS+=${LIB_DIR}/${ARCH}/libhsl.a ${HSLEXTRALIBS}
MPIEXTRA_LIBS+=${LIB_DIR}/${ARCH}/libhsl.a ${HSLEXTRALIBS}
# module requirements mandate explicit dependency
${LIB_DIR}/${ARCH}/graph_algorithms.o: $^ ${LIB_DIR}/${ARCH}/libhsl.a
${LIB_DIR}/${ARCH}/mpi/graph_algorithms.o: $^ ${LIB_DIR}/${ARCH}/libhsl.a $(patsubst %,${LIB_DIR}/${ARCH}/mpi/%.mod,$(HSLMODS))
${LIB_DIR}/${ARCH}/threads/graph_algorithms.o: $^ ${LIB_DIR}/${ARCH}/libhsl.a $(patsubst %,${LIB_DIR}/${ARCH}/threads/%.mod,$(HSLMODS))
${LIB_DIR}/${ARCH}/mpi_threads/graph_algorithms.o: $^ ${LIB_DIR}/${ARCH}/libhsl.a $(patsubst %,${LIB_DIR}/${ARCH}/mpi_threads/%.mod,$(HSLMODS))
endif
endif

# to add a source, add the source here, add the source in make_dependencies.sh, re-run make_dependencies, and compile
PREPRESRCS=accsim allocate assignprm backup boundary cartld cartmd clustering clustering_utils conrot constraint_solvers dssp emicroscopy energy energy_wrap ensemble ewald flow fmcscgrid fmsmcmpi force force_wrap fyczmat getkey graph_algorithms hacking holes initial inner_loops inner_loops_en inner_loops_imp intmd intld makeio makepept math_utils mcmove mcstat minimize ncdm_proc nucconrot parsefiles parsekey particlefluctuation polar polymer proteus prtpdb readfyc readgrid readpdb readprm restart rigidmoves sanity_checks sav sav_auxil setconf sidechain string_utils structure summary thread_utils titrate topology torconrot torsion ujconrot ujsugar_pucker unbond utilities wanglandau

PRESRCS=$(addsuffix .f90,$(PREPRESRCS))
SOURCES=$(patsubst %.f90,${SRC_DIR}/%.f90,$(PRESRCS))
OBJECTS=$(patsubst %.f90,${LIB_DIR}/${ARCH}/%.o,$(PRESRCS))
MPIOBJS=$(patsubst %.f90,${LIB_DIR}/${ARCH}/mpi/%.o,$(PRESRCS))
THREADOBJS=$(patsubst %.f90,${LIB_DIR}/${ARCH}/threads/%.o,$(PRESRCS))
MPITHREADOBJS=$(patsubst %.f90,${LIB_DIR}/${ARCH}/mpi_threads/%.o,$(PRESRCS))

# our strategy is to keep objects completely out of the SRC-directory (not even temporary) and to use a sub-directory for the MPI-version
# that means all the targets are only defined in that target directory, which is necessary in order to be able to address, maintain, and
# remove them independently.
# note that this includes the module interface definitions (.mod), which are unfortunately not compiler-independent. but this way it at least
# allows us to do preprocessing in modules without defining separate modules
# also note that dependencies are and should be exclusively handled through DEPENDENCIES
${OBJECTS} ${LIB_DIR}/${ARCH}/chainsaw.o ${LIB_DIR}/${ARCH}/datasaw.o :
	${FF} ${FFLAGS2} -c ${COMPDEFAULTS} -I${LIB_DIR}/${ARCH} $(patsubst ${LIB_DIR}/${ARCH}/%.o,${SRC_DIR}/%.f90,$@) -o $@

${MPIOBJS} ${LIB_DIR}/${ARCH}/mpi/chainsaw.o ${LIB_DIR}/${ARCH}/mpi/datasaw.o :
	${MPIFF} ${MPIFFLAGS2} -c ${COMPDEFAULTS} -DENABLE_MPI -I${LIB_DIR}/${ARCH}/mpi $(patsubst ${LIB_DIR}/${ARCH}/mpi/%.o,${SRC_DIR}/%.f90,$@) -o $@

${THREADOBJS} ${LIB_DIR}/${ARCH}/threads/chainsaw.o ${LIB_DIR}/${ARCH}/threads/datasaw.o :
	${FF} ${FFLAGS2} -c ${COMPDEFAULTS} ${THREADFLAGS} -DENABLE_THREADS -I${LIB_DIR}/${ARCH}/threads $(patsubst ${LIB_DIR}/${ARCH}/threads/%.o,${SRC_DIR}/%.f90,$@) -o $@

${MPITHREADOBJS} ${LIB_DIR}/${ARCH}/mpi_threads/chainsaw.o ${LIB_DIR}/${ARCH}/mpi_threads/datasaw.o :
	${MPIFF} ${MPIFFLAGS2} -c ${COMPDEFAULTS} ${THREADFLAGS} -DENABLE_MPI -DENABLE_THREADS -I${LIB_DIR}/${ARCH}/mpi_threads $(patsubst ${LIB_DIR}/${ARCH}/mpi_threads/%.o,${SRC_DIR}/%.f90,$@) -o $@


${MODOBJS} :
	${FF} ${FFLAGS2} -c ${COMPDEFAULTS} -I${LIB_DIR}/${ARCH} $(patsubst ${LIB_DIR}/${ARCH}/%.o,${SRC_DIR}/mod_%.f90,$@) -o $@
	${MV} $(patsubst ${LIB_DIR}/${ARCH}/%.o,${SRC_DIR}/%.mod,$@) $(patsubst %.o,%.mod,$@)

${MPIMODOBJS} :
	${MPIFF} ${MPIFFLAGS2} -c ${COMPDEFAULTS} -I${LIB_DIR}/${ARCH}/mpi -DENABLE_MPI $(patsubst ${LIB_DIR}/${ARCH}/mpi/%.o,${SRC_DIR}/mod_%.f90,$@) -o $@
	${MV} $(patsubst ${LIB_DIR}/${ARCH}/mpi/%.o,${SRC_DIR}/%.mod,$@) $(patsubst %.o,%.mod,$@)

${THREADMODOBJS} :
	${FF} ${FFLAGS2} -c ${COMPDEFAULTS} ${THREADFLAGS} -I${LIB_DIR}/${ARCH}/threads -DENABLE_THREADS $(patsubst ${LIB_DIR}/${ARCH}/threads/%.o,${SRC_DIR}/mod_%.f90,$@) -o $@
	${MV} $(patsubst ${LIB_DIR}/${ARCH}/threads/%.o,${SRC_DIR}/%.mod,$@) $(patsubst %.o,%.mod,$@)

${MPITHREADMODOBJS} :
	${MPIFF} ${MPIFFLAGS2} -c ${COMPDEFAULTS} ${THREADFLAGS} -I${LIB_DIR}/${ARCH}/mpi_threads -DENABLE_MPI -DENABLE_THREADS $(patsubst ${LIB_DIR}/${ARCH}/mpi_threads/%.o,${SRC_DIR}/mod_%.f90,$@) -o $@
	${MV} $(patsubst ${LIB_DIR}/${ARCH}/mpi_threads/%.o,${SRC_DIR}/%.mod,$@) $(patsubst %.o,%.mod,$@)


# targets for enclosed external libraries
export
${LIB_DIR}/${ARCH}/libxdrf.a: ${SRC_DIR}/xdr/xdrf.h ${SRC_DIR}/xdr/libxdrf.m4 ${SRC_DIR}/xdr/ftocstr.c ${SRC_DIR}/xdr/ftest.f ${SRC_DIR}/xdr/ctest.c
	$(MAKE) -C xdr ${LIB_DIR}/${ARCH}/libxdrf.a

${LIB_DIR}/${ARCH}/libhsl.a: ${SRC_DIR}/hsl/eb13d.f ${SRC_DIR}/hsl/eb13s.f ${SRC_DIR}/hsl/eb13_sdeps.f ${SRC_DIR}/hsl/eb13_ddeps.f ${SRC_DIR}/hsl/common90.f90 \
		${SRC_DIR}/hsl/hsl_ma48d.f90 ${SRC_DIR}/hsl/hsl_ma48s.f90 ${SRC_DIR}/hsl/ma48_ddeps90.f90 ${SRC_DIR}/hsl/ma48_sdeps90.f90 \
		${SRC_DIR}/hsl/ma48_ddeps.f ${SRC_DIR}/hsl/ma48_sdeps.f ${SRC_DIR}/hsl/hsl_ma48d_ciface.f90 ${SRC_DIR}/hsl/hsl_ma48s_ciface.f90
	$(MAKE) -C hsl ${LIB_DIR}/${ARCH}/libhsl.a

# targets for spreading HSL module files
$(patsubst %,${LIB_DIR}/${ARCH}/mpi/%.mod,$(HSLMODS)): ${LIB_DIR}/${ARCH}/libhsl.a
	${CP} $(patsubst ${LIB_DIR}/${ARCH}/mpi/%.mod,${LIB_DIR}/${ARCH}/%.mod,$@) $@
$(patsubst %,${LIB_DIR}/${ARCH}/threads/%.mod,$(HSLMODS)): ${LIB_DIR}/${ARCH}/libhsl.a
	${CP} $(patsubst ${LIB_DIR}/${ARCH}/threads/%.mod,${LIB_DIR}/${ARCH}/%.mod,$@) $@
$(patsubst %,${LIB_DIR}/${ARCH}/mpi_threads/%.mod,$(HSLMODS)): ${LIB_DIR}/${ARCH}/libhsl.a
	${CP} $(patsubst ${LIB_DIR}/${ARCH}/mpi_threads/%.mod,${LIB_DIR}/${ARCH}/%.mod,$@) $@

# library assembly is trivial (note that the name of the target doesn't match the target -> forced execution every time!)
library: $(OBJECTS) ${LIB_DIR}/${ARCH}/datasaw.o ${LIB_DIR}/${ARCH}/chainsaw.o
	ar -rclvs ${LIB_DIR}/${ARCH}/lcampari.a ${MODOBJS} ${OBJECTS}

library_mpi: $(MPIOBJS) ${LIB_DIR}/${ARCH}/mpi/datasaw.o ${LIB_DIR}/${ARCH}/mpi/chainsaw.o
	ar -rclvs ${LIB_DIR}/${ARCH}/mpi/lcampari_mpi.a ${MPIMODOBJS} ${MPIOBJS}

library_threads: $(THREADOBJS) ${LIB_DIR}/${ARCH}/threads/datasaw.o ${LIB_DIR}/${ARCH}/threads/chainsaw.o
	ar -rclvs ${LIB_DIR}/${ARCH}/threads/lcampari_threads.a ${THREADMODOBJS} ${THREADOBJS}

library_mpi_threads: $(MPITHREADOBJS) ${LIB_DIR}/${ARCH}/mpi_threads/datasaw.o ${LIB_DIR}/${ARCH}/mpi_threads/chainsaw.o
	ar -rclvs ${LIB_DIR}/${ARCH}/mpi_threads/lcampari_mpi_threads.a ${MPITHREADMODOBJS} ${MPITHREADOBJS}


# linking hopefully as well (see above note, true here due to target location!)
campari: ${LINKDEPS1}
	${FF} $(LFLAGS) -o ${BIN_DIR}/${ARCH}/campari ${LIB_DIR}/${ARCH}/chainsaw.o ${LIB_DIR}/${ARCH}/lcampari.a ${EXTRA_LIBS}

campari_mpi: ${LINKDEPS3}
	${MPIFF} $(MPILFLAGS) -DENABLE_MPI -o ${BIN_DIR}/${ARCH}/campari_mpi ${LIB_DIR}/${ARCH}/mpi/chainsaw.o ${LIB_DIR}/${ARCH}/mpi/lcampari_mpi.a ${MPIEXTRA_LIBS}

campari_threads: ${LINKDEPS2}
	${FF} $(LFLAGS) ${THREADFLAGS} -DENABLE_THREADS -o ${BIN_DIR}/${ARCH}/campari_threads ${LIB_DIR}/${ARCH}/threads/chainsaw.o ${LIB_DIR}/${ARCH}/threads/lcampari_threads.a ${EXTRA_LIBS}

campari_mpi_threads: ${LINKDEPS4}
	${MPIFF} $(MPILFLAGS) ${THREADFLAGS} -DENABLE_MPI -DENABLE_THREADS -o ${BIN_DIR}/${ARCH}/campari_mpi_threads ${LIB_DIR}/${ARCH}/mpi_threads/chainsaw.o ${LIB_DIR}/${ARCH}/mpi_threads/lcampari_mpi_threads.a ${MPIEXTRA_LIBS}

camp_ncminer: ${LINKDEPS1}
	${FF} $(LFLAGS) -o ${BIN_DIR}/${ARCH}/camp_ncminer ${LIB_DIR}/${ARCH}/datasaw.o ${LIB_DIR}/${ARCH}/lcampari.a ${EXTRA_LIBS}

camp_ncminer_mpi: ${LINKDEPS3}
	${MPIFF} $(MPILFLAGS) -DENABLE_MPI -o ${BIN_DIR}/${ARCH}/camp_ncminer_mpi ${LIB_DIR}/${ARCH}/mpi/datasaw.o ${LIB_DIR}/${ARCH}/mpi/lcampari.a ${MPIEXTRA_LIBS}

camp_ncminer_threads: ${LINKDEPS2}
	${FF} $(LFLAGS) ${THREADFLAGS} -DENABLE_THREADS -o ${BIN_DIR}/${ARCH}/camp_ncminer_threads ${LIB_DIR}/${ARCH}/threads/datasaw.o ${LIB_DIR}/${ARCH}/threads/lcampari_threads.a ${EXTRA_LIBS}
	
camp_ncminer_mpi_threads: ${LINKDEPS4}
	${MPIFF} $(MPILFLAGS) ${THREADFLAGS} -DENABLE_MPI -DENABLE_THREADS -o ${BIN_DIR}/${ARCH}/camp_ncminer_mpi_threads ${LIB_DIR}/${ARCH}/mpi_threads/datasaw.o ${LIB_DIR}/${ARCH}/mpi_threads/lcampar_mpi_threads.a ${MPIEXTRA_LIBS}


# some fake targets, which are really clean-up commands
objclean:
	for i in ${LIB_DIR}/${ARCH}/*.o; do if [ -e $${i} ]; then ${RM} $${i}; fi; done
	for i in ${LIB_DIR}/${ARCH}/mpi/*.o; do if [ -e $${i} ]; then ${RM} $${i}; fi; done
	for i in ${LIB_DIR}/${ARCH}/threads/*.o; do if [ -e $${i} ]; then ${RM} $${i}; fi; done
	for i in ${LIB_DIR}/${ARCH}/mpi_threads/*.o; do if [ -e $${i} ]; then ${RM} $${i}; fi; done
	for i in ${LIB_DIR}/${ARCH}/*.mod; do if [ -e $${i} ]; then ${RM} $${i}; fi; done
	for i in ${LIB_DIR}/${ARCH}/mpi/*.mod; do if [ -e $${i} ]; then ${RM} $${i}; fi; done
	for i in ${LIB_DIR}/${ARCH}/threads/*.mod; do if [ -e $${i} ]; then ${RM} $${i}; fi; done
	for i in ${LIB_DIR}/${ARCH}/mpi_threads/*.mod; do if [ -e $${i} ]; then ${RM} $${i}; fi; done
	for i in ${LIB_DIR}/${ARCH}/mpi_threads/lcampari_mpi_threads.a ${LIB_DIR}/${ARCH}/mpi/lcampari_mpi.a ${LIB_DIR}/${ARCH}/threads/lcampari_threads.a ${LIB_DIR}/${ARCH}/l*.a; do if [ -e $${i} ]; then ${RM} $${i}; fi; done
	$(MAKE) -C hsl clean_hsl
	$(MAKE) -C xdr clean
	for i in ${SRC_DIR}/xdr/*.o; do if [ -e $${i} ]; then ${RM} $${i}; fi; done
	for i in ${SRC_DIR}/hsl/*.o; do if [ -e $${i} ]; then ${RM} $${i}; fi; done
	for i in ${LIB_DIR}/${ARCH}/lib*.a; do if [ -e $${i} ]; then ${RM} $${i}; fi; done
	if [ -e ${SRC_DIR}/xdr/libxdrf.c ]; then ${RM} ${SRC_DIR}/xdr/libxdrf.c; fi

extclean:
	$(MAKE) -C hsl clean_hsl
	$(MAKE) -C xdr clean
	for i in ${SRC_DIR}/xdr/*.o; do if [ -e $${i} ]; then ${RM} $${i}; fi; done
	for i in ${SRC_DIR}/hsl/*.o; do if [ -e $${i} ]; then ${RM} $${i}; fi; done
	for i in ${LIB_DIR}/${ARCH}/lib*.a; do if [ -e $${i} ]; then ${RM} $${i}; fi; done
	if [ -e ${SRC_DIR}/xdr/libxdrf.c ]; then ${RM} ${SRC_DIR}/xdr/libxdrf.c; fi

clean: objclean
	for i in ${BIN_DIR}/${ARCH}/campari* ${BIN_DIR}/${ARCH}/camp_ncminer*; do if [ -e $$i ]; then ${RM} $$i; fi; done

