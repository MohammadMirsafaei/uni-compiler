while getopts "s:" arg; do
  case $arg in
    s) sample=$OPTARG;;
  esac
done
if [ -z ${sample+x} ]; then sample="../samples/sample1.sc"; fi

rm -rf ./bin/*
cd ./bin
bison -d ../Parser.y -v
mv Parser.tab.h Parser.h
mv Parser.tab.c Parser.y.c
flex ../Parser.l
mv lex.yy.c Parser.lex.c
g++ -g -c Parser.lex.c -o Parser.lex.o
g++ -g -c Parser.y.c -o Parser.y.o
g++ -g -o comp Parser.lex.o Parser.y.o -lfl
./comp $sample