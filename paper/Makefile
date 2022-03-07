PAPERPDF=sc22-mem.pdf
all: $(PAPERPDF)

PDFLATEX=pdflatex -halt-on-error

$(PAPERPDF): sc22-mem.tex futhark.tex Makefile
	$(PDFLATEX) sc22-mem.tex
	bibtex sc22-mem
	$(PDFLATEX) sc22-mem.tex
	$(PDFLATEX) sc22-mem.tex
	rm -f *~ *.bbl *.log *.blg *.aux *.out

clean:
	rm -f *~ *.bbl *.log *.blg *.aux *.out $(PAPERPDF)
