while getopts "s:" arg; do
  case $arg in
    s) sample=$OPTARG;;
  esac
done
if [ -z ${sample+x} ]; then sample="sample"; fi

cd bin/
flex ../Parser.l
g++ lex.yy.c
./a.out ../$sample