DEBUG ?= 0
STATIC ?= 0

# Submodules
PWD = $(shell pwd)
SDSL_ROOT ?= ${PWD}/src/sdslLite/
EBROOTHTSLIB ?= ${PWD}/src/htslib/
JLIB ?= ${PWD}/src/jlib/

# Install dir
prefix = ${PWD}
exec_prefix = $(prefix)
bindir ?= $(exec_prefix)/bin

# Flags
CXX=g++
CXXFLAGS += -std=c++11 -isystem ${JLIB} -isystem ${EBROOTHTSLIB} -isystem ${SDSL_ROOT}/include -pedantic -W -Wall -fvisibility=hidden
LDFLAGS += -L${SDSL_ROOT}/lib -lboost_iostreams -lboost_filesystem -lboost_system -lboost_program_options -lboost_date_time -lsdsl -ldivsufsort -ldivsufsort64 -ldl -L${EBROOTHTSLIB} -L${EBROOTHTSLIB}/lib -lpthread

ifeq (${STATIC}, 1)
	LDFLAGS += -static -static-libgcc -pthread -lhts -lz -llzma -lbz2
else
	LDFLAGS += -lhts -lz -llzma -lbz2 -Wl,-rpath,${EBROOTHTSLIB}
endif
ifeq (${DEBUG}, 1)
	CXXFLAGS += -g -O0 -fno-inline -DDEBUG
else ifeq (${DEBUG}, 2)
	CXXFLAGS += -g -O0 -fno-inline -DPROFILE
	LDFLAGS += -lprofiler -ltcmalloc
else
	CXXFLAGS += -O3 -fno-tree-vectorize -DNDEBUG
endif
ifeq (${EBROOTHTSLIB}, ${PWD}/src/htslib/)
	SUBMODULES += .htslib
endif
ifeq (${SDSL_ROOT}, ${PWD}/src/sdslLite/)
	SUBMODULES += .sdsl
endif


# External sources
SDSLSOURCES = $(wildcard src/sdsl/lib/*.cpp)
TRACYSOURCES = $(wildcard src/*.cpp) $(wildcard src/*.h)
HTSLIBSOURCES = $(wildcard src/htslib/*.c) $(wildcard src/htslib/*.h)
PBASE=$(shell pwd)

# Targets
BUILT_PROGRAMS = src/tracy
TARGETS = ${SUBMODULES} ${BUILT_PROGRAMS}

all:   	$(TARGETS)

.sdsl: $(SDSLSOURCES)
	if [ -r src/sdsl/install.sh ]; then cd src/sdsl/ && ./install.sh ${PBASE}/src/sdslLite && cd ../../ && touch .sdsl; fi

.htslib: $(HTSLIBSOURCES)
	if [ -r src/htslib/Makefile ]; then cd src/htslib && make && make lib-static && cd ../../ && touch .htslib; fi

src/tracy: ${SUBMODULES} ${TRACYSOURCES}
	$(CXX) $(CXXFLAGS) $@.cpp -o $@ $(LDFLAGS)

install: ${BUILT_PROGRAMS}
	mkdir -p ${bindir}
	install -p ${BUILT_PROGRAMS} ${bindir}

clean:
	if [ -r src/htslib/Makefile ]; then cd src/htslib && make clean; fi
	if [ -r src/sdsl/install.sh ]; then cd src/sdsl/ && ./uninstall.sh && cd ../../ && rm -rf src/sdslLite/; fi
	rm -f $(TARGETS) $(TARGETS:=.o) ${SUBMODULES}

distclean: clean
	rm -f ${BUILT_PROGRAMS}

.PHONY: clean distclean install all
