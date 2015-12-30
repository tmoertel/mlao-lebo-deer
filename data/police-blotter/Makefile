pdfs := $(wildcard *.pdf)
txts := $(pdfs:.pdf=.txt)

accidents.csv : $(txts) ./blotter_to_accident_summary.py
	./blotter_to_accident_summary.py $(txts) >> $@.tmp
	< $@.tmp tr -d \\015 | sort -r > $@
	rm -f $@.tmp
	echo "from,to" > police_blotter_date_ranges.csv
	cat $(txts) | perl -C -lne'print "$$1 $$2 $$3,$$4 $$5 $$6" if /^\s*(?:\w+),\s+(\w+)\s+(\d+),\s+(\d+)\s+through\s+(?:\w+),\s+(\w+)\s+(\d+),\s+(\d+)\s*$$/' >> police_blotter_date_ranges.csv

%.txt : %.pdf
	pdftotext -layout $< $@

clean:
	rm -f $(txts) accidents.csv
