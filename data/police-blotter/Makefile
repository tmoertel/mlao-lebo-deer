pdfs := $(wildcard *.pdf)
txts := $(pdfs:.pdf=.txt)

accidents.csv : $(txts)
	./blotter_to_accident_summary.py $(txts) > $@

%.txt : %.pdf
	pdftotext -layout $< $@

clean:
	rm -f $(txts) accidents.csv
