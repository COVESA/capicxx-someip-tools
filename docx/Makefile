# Creating CommonAPI D-Bus documentation
docgendir=../doc
htmldocgendir=$(docgendir)/html
pdfdocgendir=$(docgendir)/pdf
iconsdir=../images/icons
imagedir=../images
datestring=$(shell date "+%d.\ %b\ %Y")
commonapi_version=$(PROJECT_VERSION)

all: doc

doc: ug_html ug_pdf

ug_html: docgendir
	mkdir -p $(htmldocgendir)
	asciidoc -a revdate=$(datestring) \
				-a icons \
				-a iconsdir=$(iconsdir) \
				-a imagedir=$(imagedir) \
				-a version=$(commonapi_version) \
				-a cppstr=cpp \
				-a tabsize=4 \
				-b html \
				-o $(htmldocgendir)/CommonAPISomeIPCppUserGuide.html \
				CommonAPISomeIPCppUserGuide

ug_pdf: docgendir
	mkdir -p $(pdfdocgendir)
	a2x \
		-a revdate=$(datestring) \
		-a icons \
		-a iconsdir=$(iconsdir) \
		-a imagedir=$(imagedir) \
		-a version=$(commonapi_version) \
		-a tabsize=4 \
		-f pdf \
		--dblatex-opts "-P latex.output.revhistory=0 -P imagedata.default.scale=maxwidth=10cm,maxheight=8cm" \
		--icons \
		-D $(pdfdocgendir) \
		CommonAPISomeIPCppUserGuide

docgendir:
	mkdir -p $(docgendir)
	cp -rf images $(docgendir)/images
	cp index.html $(docgendir)

clean:
	rm -rf $(docgendir)
