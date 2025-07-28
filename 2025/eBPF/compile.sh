echo "rule typst_compile" > build.ninja
echo "  command = typst compile \$in \$out" >> build.ninja
echo "  description = Compiling \$in to \$out" >> build.ninja
echo >> build.ninja

for f in *.typ; do
    base="${f%.typ}"
    echo "build $base.pdf: typst_compile $f" >> build.ninja
done

echo -n "build all: phony" >> build.ninja
for f in *.typ; do
    base="${f%.typ}"
    echo -n " $base.pdf" >> build.ninja
done
echo >> build.ninja

echo >> build.ninja

echo "rule clean_pdfs" >> build.ninja
echo "  command = rm -f *.pdf" >> build.ninja
echo "  description = Cleaning all PDF in this folder" >> build.ninja
echo "build clean: clean_pdfs" >> build.ninja
