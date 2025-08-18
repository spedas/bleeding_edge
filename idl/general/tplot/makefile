
# makefile for subdirectories in the Wind idl software distribution

SOURCE:sh = ls SCCS/s.*.pro | sed 's/SCCS\/s\.//'

all: $(SOURCE)

install: all

clean:
	sccs clean
	rm -f *%
	rm -f core
