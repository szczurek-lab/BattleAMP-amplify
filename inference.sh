inputpath="$1"
outputpath="$2"

python src/AMPlify.py -s "$inputpath" -on "$outputpath" &&

python convertoutputs.py "$outputpath" "$outputpath"
