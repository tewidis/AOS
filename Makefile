MD=markdown
PDF=pdf

all: review intro_to_aos os_structure virtualization shared_memory distributed_systems

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

virtualization: $(MD)/virtualization.md
	pandoc -V geometry:margin=1in -o $(PDF)/virtualization.pdf $(MD)/virtualization.md

shared_memory: $(MD)/shared_memory.md
	pandoc -V geometry:margin=1in -o $(PDF)/shared_memory.pdf $(MD)/shared_memory.md

distributed_systems: $(MD)/distributed_systems.md
	pandoc -V geometry:margin=1in -o $(PDF)/distributed_systems.pdf $(MD)/distributed_systems.md
