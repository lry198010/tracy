/*
============================================================================
Tracy: Trace File Handling
============================================================================
This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
============================================================================
Contact: Tobias Rausch (rausch@embl.de)
============================================================================
*/

#ifndef FASTA_H
#define FASTA_H

#include <boost/progress.hpp>
#include "abif.h"
#include "fmindex.h"

namespace tracy
{

  inline bool
  loadSingleFasta(std::string const& filename, std::string& faname, std::string& seq) {
    faname = "";
    std::string tmpfasta = "";
    std::ifstream fafile(filename.c_str());
    if (fafile.good()) {
      std::string line;
      while(std::getline(fafile, line)) {
	if (!line.empty()) {
	  if (line[0] == '>') {
	    if (!faname.empty()) {
	      std::cerr << "Only single-chromosome FASTA files are supported." << std::endl;
	      return false;
	    }
	    if (line.at(line.length() - 1) == '\r' ){
	      faname = line.substr(1, line.length() - 2);
	    } else {
	      faname = line.substr(1);
	    }
	  } else {
	    if (line.at(line.length() - 1) == '\r' ){
	      tmpfasta += boost::to_upper_copy(line.substr(0, line.length() - 1));
	    } else {
	      tmpfasta += boost::to_upper_copy(line);
	    }
	  }
	}
      }
      fafile.close();
    }
    // Check FASTA
    for(uint32_t k = 0; k < tmpfasta.size(); ++k)
      if ((tmpfasta[k] == 'A') || (tmpfasta[k] == 'C') || (tmpfasta[k] == 'G') || (tmpfasta[k] == 'T') || (tmpfasta[k] == 'N')) seq += tmpfasta[k];
    if (seq.size() != tmpfasta.size()) {
      std::cerr << "FASTA file contains nucleotides != [ACGTN]." << std::endl;
      return false;
    }

    return true;
  }

  
  inline void
  traceFastaOut(std::string const& outfile, BaseCalls& bc, Trace const&) {
    // Output trace
    std::ofstream rfile(outfile.c_str());
    rfile << ">primary" << std::endl;
    for(uint32_t i = 0; i < bc.primary.size(); ++i) rfile << bc.primary[i];
    rfile << std::endl;
    rfile.close();  
  }

  inline void
  traceFastqOut(std::string const& outfile, BaseCalls& bc, Trace const& tr) {
    // Output trace
    std::ofstream rfile(outfile.c_str());
    rfile << "@primary" << std::endl;
    for(uint32_t i = 0; i < bc.primary.size(); ++i) rfile << bc.primary[i];
    rfile << std::endl;
    rfile << "+" << std::endl;
    
    typedef Trace::TValue TValue;
    uint32_t bcpos = 0;
    TValue idx = bc.bcPos[bcpos];
    for(int32_t i = 0; i < (int32_t) tr.traceACGT[0].size(); ++i) {
      if (idx == i) {
	rfile << (char) (tr.qual[bcpos] + 33);
	if (bcpos < bc.bcPos.size() - 1) idx = bc.bcPos[++bcpos];
      }
    }
    rfile << std::endl;
    rfile.close();
  }

}

#endif
