MD=markdown
PDF=pdf

all: review intro_to_aos os_structure

clean:
	rm -f *~
	rm -f $(PDF)/*
	rm -f $(MD)/*~

review: $(MD)/review.md
	pandoc -V geometry:margin=1in -o $(PDF)/review.pdf $(MD)/review.md

intro_to_aos: $(MD)/intro_to_aos.md
	pandoc -V geometry:margin=1in -o $(PDF)/intro_to_aos.pdf $(MD)/intro_to_aos.md

os_structure: $(MD)/os_structure.md
	pandoc -V geometry:margin=1in -o $(PDF)/os_structure.pdf $(MD)/os_structure.md
