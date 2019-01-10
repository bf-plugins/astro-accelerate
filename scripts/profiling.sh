################################################################################
# profiling.sh
#
# Description: A brute force optimiser for astro-accelerate.
# Usage:       Please run the script from the top-level directory.
# Usage:       The first parameter is the input file to optimise over.
# Usage:       The second parameter is the path to the repository.
# Notice:      Please do not commit the optimiser output to the repository.
################################################################################

#!/usr/bin/env bash

# Path to the input file that will be used to optimise over
inFile="$1"

# Path to the top-level folder of the repository.
repository_directory="$2"
echo "Repository directory is " ${repository_directory}

# Project include folder
include=${repository_directory}/include

# Project location of template params header file
template_params=${repository_directory}/lib/header

# Path to script/astro-accelerate.sh script
astroaccelerate_sh_script=${repository_directory}scripts/astro-accelerate.sh

rm -rf profile_results

mkdir profile_results

for unroll in {4,8,16,32}
do
    for acc in {6,8,10,12,14,16}
    do
	for divint in {8,10,12,14,16,18}
	do
	    for divindm in {20,25,32,40,50,60}
	    do
		echo ${unroll} ${acc} ${divint} ${divindm}
		pwd
		cat ${template_params} > ./params.txt
		rm ${include}/aa_params.hpp
		echo "#define UNROLLS $unroll" >> ./params.txt
		echo "#define SNUMREG $acc" >> ./params.txt
		echo "#define SDIVINT $divint" >> ./params.txt
		echo "#define SDIVINDM $divindm" >> ./params.txt
		echo "#define SFDIVINDM $divindm.0f" >> ./params.txt
		echo "} // namespace astroaccelerate" >> ./params.txt
		echo "#endif // ASTRO_ACCELERATE_AA_PARAMS_HPP" >> ./params.txt
		mv params.txt ${include}/aa_params.hpp
		
		make clean
		
		regcount=$(make -j 16 2>&1 | grep -A2 shared_dedisperse_kernel | tail -1 | awk -F" " '{print $5}')
		
		cp ${include}/aa_params.hpp profile_results/u"$unroll"_a"$acc"_t"$divint"_dm"$divindm"_r"$regcount".h
		
		${astroaccelerate_sh_script} $inFile > profile_results/u"$unroll"_a"$acc"_t"$divint"_dm"$divindm"_r"$regcount".dat
		
		echo "unrolls: $unroll	acc: $acc    divint: $divint    divindm: $divindm    reg: $regcount"
	    done
	done
    done
done

optimum=$(grep "Real" profile_results/* | awk -F" " '{print $4" "$1}' | sort -n | tail -1 | awk -F" " '{print $2}' | awk -F"." '{print $1".h"}')

cp $optimum ${include}/aa_params.hpp
pwd
make clean
regcount=$(make -j 16 2>&1 | grep -A2 shared_dedisperse_kernel | tail -1 | awk -F" " '{print $5}')
cd scripts/

echo "FINISED OPTIMISATION"
