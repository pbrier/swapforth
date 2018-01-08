j1a-reference.pdf: j1a-reference.tex olimex_io.png 
	-pdflatex j1a-reference.tex
	-makeindex j1a-reference
	-pdflatex j1a-reference.tex
clean:
	-rm *.log *.out *.idx *.aux *.pdf
