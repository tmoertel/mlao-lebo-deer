pdfs := $(wildcard *.pdf)
txts := $(pdfs:.pdf=.txt)

accidents.csv : $(txts) ./blotter_to_accident_summary.py
	./blotter_to_accident_summary.py $(txts) | tr -d \\015 | sort -r > $@

%.txt : %.pdf
	pdftotext -layout $< $@

clean:
	rm -f $(txts) accidents.csv
