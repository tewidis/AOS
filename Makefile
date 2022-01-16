MD=markdown
PDF=pdf

all: review

clean:
	rm -f *~
	rm -f $(PDF)/*
	rm -f $(MD)/*~

review: $(MD)/review.md
	pandoc -V geometry:margin=1in -o $(PDF)/review.pdf $(MD)/review.md
