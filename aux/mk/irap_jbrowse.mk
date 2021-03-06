#; -*- mode: Makefile;-*-
# =========================================================
# Copyright 2012-2018,  Nuno A. Fonseca (nuno dot fonseca at gmail dot com)
#
# This file is part of iRAP.
#
# This is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with iRAP.  If not, see <http://www.gnu.org/licenses/>.
#
#
# =========================================================
# Include Jbrowse in the report for visualizing data in the genome

######################
# Jbrowse
JBROWSE_RDIR=$(report_toplevel_folder)/jbrowse
JBROWSE_DATA=$(JBROWSE_RDIR)/data

# also used to keep BED and BEDGraph files
# TODO: http://gmod.org/wiki/JBrowse_Configuration_Guide#Wiggle_Tracks (use the new wiggle track definition procedure)
JBROWSE_WIG_DIR=$(JBROWSE_RDIR)/raw/wig
JBROWSE_BAM_DIR=$(JBROWSE_RDIR)/raw/bam
#JBROWSE_RAW_DATA=$(report_toplevel_folder)/jbrowse/raw

# alias
ifdef browser
browsing=$(browser)
endif

def_browsing=n
ifndef browsing
browsing=$(def_browsing)
endif

#ex. $(call rep_browse,dep1 ...) 
define rep_browse=
$(if $(subst y,,$(browsing)),,$(1))
endef

phony_targets+=report_browser report_browser_setup report_browser_stage1 report_browser_stage2 report_browser_stage3 report_browser_stage4

report_browser: report_browser_setup report_browser_stage1 report_browser_stage2 report_browser_stage3 report_browser_stage4 upload_tracks

jbrowser_stage1_targets:
	echo report_browser_setup

# Initialize dir. structure
# Add reference and annotation track
report_browser_setup: $(report_toplevel_folder)/jbrowse.setup.ok \
		      $(report_toplevel_folder)/jbrowse/refs.ok $(report_toplevel_folder)/jbrowse/annot.ok \
	               $(report_toplevel_folder)/menu.html $(gff3_file_abspath).csv

# irap_report_main generates the menu
$(report_toplevel_folder)/menu.html:
	$(call p_error,"please run irap with the report option")

# 
# NOTE: stage?_tracks should be defined elsewhere

# Adds the BAM files 
report_browser_stage2: stage2_upload_tracks report_browser_setup

# Adds the raw and norm. counts if available
report_browser_stage3: stage3_upload_tracks report_browser_setup

# Adds a track that highlights the DE by condition
report_browser_stage4: stage4_upload_tracks report_browser_setup


upload_tracks: stage2_upload_tracks stage3_upload_tracks stage4_upload_tracks report_browser_setup

####################################################
# Initialization
$(report_toplevel_folder)/jbrowse.setup.ok $(report_toplevel_folder)/jbrowse/ $(report_toplevel_folder)/jbrowse/data $(report_toplevel_folder)/jbrowse/index.html: $(IRAP_DIR)/aux/jbrowse.zip
	irap_setup_jbrowser.sh $(JBROWSE_RDIR) $(name) &&
	touch $(report_toplevel_folder)/jbrowse.setup.ok

# Track: reference
$(report_toplevel_folder)/jbrowse/refs.ok: $(reference_abspath)  $(report_toplevel_folder)/jbrowse.setup.ok
	prepare-refseqs.pl --fasta $(reference_abspath) -out $(JBROWSE_DATA) && touch $@

# Track: annotation
#        mRNA
#        gene
# Add more data?
$(report_toplevel_folder)/jbrowse/annot.ok: $(gff3_file_abspath) $(report_toplevel_folder)/jbrowse.setup.ok
	track_add.sh -d gff3  -l mRNA -o  $(JBROWSE_DATA) -t mRNA -i $< &&\
	track_add.sh -d gff3  -l gene -o  $(JBROWSE_DATA) -t gene -i $< &&\
	touch $@

#########################################################
# Track: BAM
#phony_targets+= $()/%.bam.tracks 

jbrowser_bam_targets=
jbrowser_stage2_targets: 
	echo $(subst .bam,.bam.tracks,$(bam_files))

%.bam.tracks: %.bam.bw
	$(call p_info,"BAM tracks for $(notdir $*).bam generated.")

%.bam.tracks.uploaded: %.bam.track %.bam.cov.track %.bam.covd.track
	touch $@
#	$(call p_info,"BAM tracks for $(notdir $*).bam in browser ")

# note: the bam files + index need to be copied/moved to the raw/bam/ directory under the jbrowser tree
#       a symbolic link will be created in the original location
%.se.hits.bam.track: %.se.hits.bam %.se.hits.bam.bai
	track_add.sh -d bam  -l "$(notdir $*)-$(mapper)-BAM" -o $(JBROWSE_DATA) -i $< \
	-m $(call get_metadata,Mapping,$(mapper),,,,Alignment (Reads) Track,"Lib" : "$(notdir $*)";) &&\
	touch $@

%.pe.hits.bam.track: %.pe.hits.bam  %.pe.hits.bam.bai
	track_add.sh -d bam -l "$(notdir $*)-$(mapper)-BAM" -o $(JBROWSE_DATA) -i $< \
	-m $(call get_metadata,Mapping,$(mapper),,,,Alignment (Reads) Track,"Lib" : "$(notdir $*)";) &&\
	touch $@



%.se.hits.bam.cov.track: %.se.hits.bam.bw %.se.hits.bam  %.se.hits.bam.bai
	track_add.sh -d cov -l "$(notdir $*)-$(mapper)-Cov" -o $(JBROWSE_DATA) -i $< \
	-m $(call get_metadata,Mapping,$(mapper),,,,Alignment Coverage Track,"Lib" : "$(notdir $*)";) &&\
	touch $@

%.pe.hits.bam.cov.track: %.pe.hits.bam.bw %.pe.hits.bam  %.pe.hits.bam.bai
	track_add.sh -d cov -l "$(notdir $*)-$(mapper)-Cov" -o $(JBROWSE_DATA) -i $< \
	-m $(call get_metadata,Mapping,$(mapper),,,,Alignment Coverage Track,"Lib" : "$(notdir $*)";) &&
	touch $@

# Density Coverage Wig from BAM
%.se.hits.bam.covd.track: %.se.hits.bam.bw %.se.hits.bam  %.se.hits.bam.bai
	track_add.sh -d covd -l "$(notdir $*)-$(mapper)-D" -o $(JBROWSE_DATA) -i $< \
	-m $(call get_metadata,Mapping,$(mapper),,,,Alignment Density Coverage Track,"Lib" : "$(notdir $*)";) &&\
	touch $@

%.pe.hits.bam.covd.track: %.pe.hits.bam.bw %.pe.hits.bam %.pe.hits.bam.bai
	track_add.sh -d covd -l "$(notdir $*)-$(mapper)-D" -o $(JBROWSE_DATA) -i $< \
	-m $(call get_metadata,Mapping,$(mapper),,,,Alignment Density Coverage Track,"Lib" : "$(notdir $*)";) &&
	touch $@

#1-Stage
#2-Mapper
#3-Quant
#4-Norm
#5-DE
#6-obs
#7-extra
define get_metadata=
'$(call metadata_pv,Stage,$(1)) $(call metadata_pv,Mapping,$(2)) $(call metadata_pv,Quantification,$(3)) $(call metadata_pv,Normalization,$(4)) $(call metadata_pv,DE,$(5)) $(call metadata_pv,Observation,$(6)) $(7)'
endef

define metadata_pv=
$(if $(2),"$(1)" : "$(2)";,)
endef

############################################################
#
# Track: quantification
# exon|gene|transcripts-raw|fpkm|rpkm|tpm|nlib-$(Quant)-$(mapper)-GE
phony_targets+= $(quant_toplevel_folder)/%.tsv.tracks

# remove .se and .pe from the prefix of the file to obtain the libname
define pprint_libname=
$(subst .pe,,$(subst .se,,$(1)))
endef


jbrowser_stage3_targets: 
	echo $(stage3_tracks_targets)

### TODO fix
%.tsv.tracks.uploaded: %.tsv.covd.track
	$(call p_info,Quantification tracks $@ to browser)

%.tsv.tracks.uploaded: %.tsv.tracks
	$(call p_info,Quantification tracks $@ to browser)

# TODO
%.exons.raw.$(quant_method).tsv.covd.track: 
	$(call p_info, TODO/WIP - tsv2bedGraph support for exon level quant)
# track_add.sh -d covd  -l "$*-raw-$(quant_method)-$(mapper)-EE" -o $(JBROWSE_DATA) \
# -m $(call get_metadata,Quantification,$(mapper),$(quant_method),,,Reads per exon,"Lib" : "$(call pprint_libname,$*)") &&
	touch $@


%.transcripts.raw.$(quant_method).tsv.covd.track: %.transcripts.raw.$(quant_method).bw $(gff3_file_abspath).csv
	track_add.sh -d covd  -l "$(call pprint_libname,$(basename $*))-raw-$(quant_method)-$(mapper)-TE" -o $(JBROWSE_DATA) \
	-i $< \
	-m $(call get_metadata,Quantification,$(mapper),$(quant_method),,,Reads per transcript,"Lib" : "$(call pprint_libname,$(basename $*))") &&\
	touch $@


%.genes.raw.$(quant_method).tsv.covd.track: %.genes.raw.$(quant_method).bw $(gff3_file_abspath).csv
	track_add.sh -d covd  -l "$(call pprint_libname,$(basename $*))-raw-$(quant_method)-$(mapper)-GE" -o $(JBROWSE_DATA) \
	-i $< \
	-m $(call get_metadata,Quantification,$(mapper),$(quant_method),,,Reads per gene,"Lib" : "$(call pprint_libname,$(basename $*))") &&\
	touch $@

# TODO: WIP
#rpkms
%.exons.fpkms.$(quant_norm_method).tsv.covd.track: 
	$(call p_info, TODO/WIP - tsv2bedGraph support for exon level quant)
#$(quant_method_toplevel)/%.exons.fpkms.$(quant_norm_method).tsv.bedGraph $(gff3_file_abspath).csv
#	track_add.sh -d rna_bedgraph  -l "$*-fpkms-$(quant_method)-$(mapper)-EE" -o $(JBROWSE_DATA) -i $< && touch $@
	track_add.sh -d covd  -l "$(basename $*)-fpkms-$(quant_method)-$(mapper)-EE" -o $(JBROWSE_DATA) -i $< && touch $@

%.transcripts.fpkms.$(quant_norm_method).tsv.covd.track: $(quant_toplevel_folder)/%.transcripts.fpkms.$(quant_norm_method).bedGraph $(gff3_file_abspath).csv
#	track_add.sh -d rna_bedgraph  -l "$*-fpkms-$(quant_method)-$(mapper)-TE" -o $(JBROWSE_DATA) -i $< && touch $@
	track_add.sh -d covd -l "$(basename $*)-fpkms-$(quant_method)-$(mapper)-TE" -o $(JBROWSE_DATA) -i $< && touch $@

%.genes.fpkms.$(quant_norm_method).tsv.covd.track: %.genes.fpkms.$(quant_norm_method).bw $(gff3_file_abspath).csv
	track_add.sh -d covd  -l "$(basename $*)-fpkms-$(quant_method)-$(mapper)-GE" -o $(JBROWSE_DATA) -i $< \
	-m $(call get_metadata,Quantification,$(mapper),$(quant_method),,,FPKMs per gene (GE),"Lib" : "$(call pprint_libname,$(basename $*)") &&\
	touch $@

######
# TODO: combine multiple values in a single track?
$(quant_toplevel_folder)/exons.%.tsv.tracks:
	$(call p_info,exon tracks WIP)

$(quant_toplevel_folder)/transcripts.%.tsv.tracks:
	$(call p_info,transcripts WIP)

$(quant_toplevel_folder)/genes.%.tsv.tracks:
	$(call p_info,WIP - all libs in a single track)

###########################################################
# Track: DE
# Contrast (fold|pvalue)-de_method-quant_method-mapper-DE
# rules to generate the bedfiles are specific to each method 
phony_targets+= 

jbrowser_stage4_targets: 
	echo $(stage4_tracks_targets)

# generic rule
# works only for gene level visualization
# TODO: add support for transcript and exon level visualization (change track name accordingly)
$(de_toplevel_folder)/%.genes_de.tsv.tracks: $(de_toplevel_folder)/%.genes_de.fold.bw $(de_toplevel_folder)/%.genes_de.pval.bw $(de_toplevel_folder)/%.genes_de.fold.bedGraph $(de_toplevel_folder)/%.genes_de.pval.bedGraph
	$(call p_info,DE tracks $@ generated)	

$(de_toplevel_folder)/%.genes_de.tsv.tracks.uploaded: $(de_toplevel_folder)/%.genes_de.tsv.fold.track  $(de_toplevel_folder)/%.genes_de.tsv.pval.track
	touch $@

$(de_toplevel_folder)/%.genes_de.tsv.fold.track: $(de_toplevel_folder)/%.genes_de.fold.bw  $(gff3_file_abspath).csv 
	mv $< $(de_toplevel_folder)/$*.$(mapper).$(quant_method).$(de_method).genes_de.fold.bw &&\
	track_add.sh -d foldchange  -l "$*-$(quant_method)-$(mapper)-$(de_method)-DE-fold" -o $(JBROWSE_DATA) \
	-i $(de_toplevel_folder)/$*.$(mapper).$(quant_method).$(de_method).genes_de.fold.bw  \
	-m $(call get_metadata,DE,$(mapper),$(quant_method),$(quant_norm_method),$(de_method),DE at gene level (fold change),"Contrast" : "$*") &&\
	touch $@

$(de_toplevel_folder)/%.genes_de.tsv.pval.track: $(de_toplevel_folder)/%.genes_de.pval.bw  $(gff3_file_abspath).csv 
	mv $< $(de_toplevel_folder)/$*.$(mapper).$(quant_method).$(de_method).genes_de.pval.bw &&\
	track_add.sh -d covd  -l "$*-$(quant_method)-$(mapper)-$(de_method)-DE-pval" -o $(JBROWSE_DATA) \
	-i $(de_toplevel_folder)/$*.$(mapper).$(quant_method).$(de_method).genes_de.pval.bw  \
	-m $(call get_metadata,DE,$(mapper),$(quant_method),$(quant_norm_method),$(de_method),DE at gene level (pval),"Contrast" : "$*") &&\
	touch $@

####################
# DESEQ
# fold change+pvalue
$(de_toplevel_folder1)/deseq/%.genes_de.fold.bedGraph: $(de_toplevel_folder1)/deseq/%.genes_de.tsv $(gff3_file_abspath).csv
	$(call deseq_bed,$<,$@,fold,gene) 

# pvalue (adj)
$(de_toplevel_folder1)/deseq/%.genes_de.pval.bedGraph: $(de_toplevel_folder1)/deseq/%.genes_de.tsv $(gff3_file_abspath).csv
	$(call deseq_bed,$<,$@,adjpvalue,gene)

# log2foldchange
DESEQ_FIELD_fold=6
DESEQ_FIELD_pvalue=7
DESEQ_FIELD_adjpvalue=8
# 1 - deseq tsv file
# 2 - bed (output)
# 3 - field
# 4 - gene|transcripts|exon
define deseq_bed=
	tail -n +2 $(1) | cut -f 1,$(DESEQ_FIELD_$(3)) > $(1).tmp &&\
	tsv2bed.R $(1).tmp  $(4) $(gff3_file_abspath).csv $(auxdata_toplevel_folder)/$(reference_basename).chr_sizes.txt | sed "s/Inf/0/" |\
	sort -k1,1 -k2,2n | \
	bedtools merge -scores mean -i - > $(2).tmp &&\
	rm -f $(1).tmp &&\
	mv $(2).tmp $(2) 
endef

#####################
# Cuffdiff*
# fold change+pvalue
CUFFDIFF_FIELD_fold=6
CUFFDIFF_FIELD_fold=10
CUFFDIFF_FIELD_pvalue=12
#q
CUFFDIFF_FIELD_adjpvalue=13 

# 1 - cuffdiff tsv file
# 2 - bed
# 3 - field
# 4 - gene|transcripts|exon
define cuffdiff_bed=
	tail -n +2 $(1) | cut -f 2,$(CUFFDIFF_FIELD_$(3)) > $(1).tmp &&\
	Rscript -e  "a<-read.table('$(1).tmp',sep='\t');a$$V2[a$$V2==1.79769e+308]=0;a$$V2[a$$V2==-1.79769e+308]=0;options(scipen=100000);write.table(a,row.names=F,col.names=F,quote=F,sep='\t');q(status=0);"  > $(1).tmp2 &&\
	tsv2bedGraph.R $(1).tmp2  $(4) $(gff3_file_abspath).csv | sed "s/Inf/0/" > $(2).tmp && \
	rm -f $(1).tmp* &&\
	mv $(2).tmp $(2) 
endef
# R code fixes the number in scientific notation and change +-inf to 0...
$(de_toplevel_folder1)/cuffdiff2/%.genes_de.fold.bedGraph: $(de_toplevel_folder1)/cuffdiff2/%.genes_de.tsv $(gff3_file_abspath).csv
	$(call cuffdiff_bed,$<,$@,fold,gene)
$(de_toplevel_folder1)/cuffdiff1/%.genes_de.fold.bedGraph: $(de_toplevel_folder1)/cuffdiff1/%.genes_de.tsv $(gff3_file_abspath).csv
	$(call cuffdiff_bed,$<,$@,fold,gene)
$(de_toplevel_folder1)/cuffdiff1_nd/%.genes_de.fold.bedGraph: $(de_toplevel_folder1)/cuffdiff1_nd/%.genes_de.tsv.bedGraph  $(gff3_file_abspath).csv
	$(call cuffdiff_bed,$<,$@,fold,gene)
$(de_toplevel_folder1)/cuffdiff2_nd/%.genes_de.fold.bedGraph: $(de_toplevel_folder1)/cuffdiff2_nd/%.genes_de.tsv.bedGraph $(gff3_file_abspath).csv
	$(call cuffdiff_bed,$<,$@,fold,gene)

#
$(de_toplevel_folder1)/cuffdiff1/%.genes_de.pval.bedGraph: $(de_toplevel_folder1)/cuffdiff1/%.genes_de.tsv.bedGraph $(gff3_file_abspath).csv
	$(call cuffdiff_bed,$<,$@,padj,gene)
$(de_toplevel_folder1)/cuffdiff1_nd/%.genes_de.pval.bedGraph: $(de_toplevel_folder1)/cuffdiff1_nd/%.genes_de.tsv.bedGraph
	$(call cuffdiff_bed,$<,$@,padj,gene)
$(de_toplevel_folder1)/cuffdiff2/%.genes_de.pval.bedGraph: $(de_toplevel_folder1)/cuffdiff2/%.genes_de.tsv.bedGraph $(gff3_file_abspath).csv
	$(call cuffdiff_bed,$<,$@,padj,gene)
$(de_toplevel_folder1)/cuffdiff2_nd/%.genes_de.pval.bedGraph: $(de_toplevel_folder1)/cuffdiff2_nd/%.genes_de.tsv.bedGraph $(gff3_file_abspath).csv
	$(call cuffdiff_bed,$<,$@,padj,gene)

#test_id gene_id gene    locus   sample_1        sample_2        status  value_1 value_2 log2(fold_change)       test_stat       p_value q_value significant?(y|n)

##############################################################

deseq.fold.bedGraph: deseq_de_examples/B37vs42_de.tsv
	$(call deseq_bed,$<,$@,fold,gene)
deseq.padj.bedGraph: deseq_de_examples/B37vs42_de.tsv
	$(call deseq_bed,$<,$@,adjpvalue,gene)

jbrowse_qtests: test.deseq.track

test.deseq.track: deseq.fold.bedGraph deseq.padj.bedGraph
#	track_add.sh -d wig  -l "$* fold-$(de_method)-$(quant_method)-$(mapper)-DE" -o $(JBROWSE_DATA) -i $< &&
	track_add.sh -d wig  -l "$* pvalue-$(de_method)-$(quant_method)-$(mapper)-DE" -o $(JBROWSE_DATA) -i deseq.padj.bedGraph &&\
	touch $@

cuff.fold.bedGraph: cuffdiff_de_examples/cuffdiff.genes_de.tsv
	$(call cuffdiff_bed,$<,$@,fold,gene)
cuff.padj.bedGraph: cuffdiff_de_examples/cuffdiff.genes_de.tsv
	$(call cuffdiff_bed,$<,$@,adjpvalue,gene)


test.cuff.track: cuff.fold.bedGraph cuff.padj.bedGraph
	track_add.sh -d wig  -l "$* fold-$(de_method)-$(quant_method)-$(mapper)-DE" -o $(JBROWSE_DATA) -i $< &&\
	track_add.sh -d wig  -l "$* pvalue-$(de_method)-$(quant_method)-$(mapper)-DE" -o $(JBROWSE_DATA) -i cuff.padj.bedGraph &&\
	touch $@
