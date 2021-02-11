test_that("creating a default session returns the correct string", {
  # create the assembly configuration
  assembly <- assembly("https://jbrowse.org/genomes/hg19/fasta/hg19.fa.gz", bgzip = TRUE)

  # create variant and wiggle tracks
  variant <- track_variant(
    "https://ftp.ncbi.nlm.nih.gov/pub/clinvar/vcf_GRCh37/clinvar.vcf.gz",
    assembly
  )
  wiggle <- track_wiggle(
    "https://s3.amazonaws.com/jbrowse.org/genomes/hg19/reads_lr_skbr3.fa_ngmlr-0.2.3_mapped.bam.regions.bw",
    assembly
  )

  alignments <- track_alignments(
    "https://s3.amazonaws.com/jbrowse.org/genomes/hg19/ultra-long-ont_hs37d5_phased.cram",
    assembly
  )

  feature <- track_feature(
    "https://s3.amazonaws.com/jbrowse.org/genomes/hg19/ncbi_refseq/GRCh37_latest_genomic.sort.gff.gz",
    assembly
  )

  expect_type(
    default_session(
      assembly,
      c(variant, wiggle)
    ),
    "character"
  )

  # test against valid config
  expect_equal(
    default_session(
      assembly,
      c(variant, wiggle)
    ),
    "{ \"name\": \"My Session\", \"view\": { \"id\": \"LinearGenomeView\", \"type\": \"LinearGenomeView\", \"tracks\": [ { \"type\": \"ReferenceSequenceTrack\", \"configuration\": \"hg19-ReferenceSequenceTrack\", \"displays\": [ { \"type\": \"LinearReferenceSequenceDisplay\", \"configuration\": \"hg19-ReferenceSequenceTrack-LinearReferenceSequenceDisplay\"} ]} , { \"type\": \"VariantTrack\", \"configuration\": \"hg19_clinvar\", \"displays\": [ {\"type\": \"LinearVariantDisplay\", \"configuration\": \"hg19_clinvar-LinearVariantDisplay\" }]}, { \"type\": \"QuantitativeTrack\", \"configuration\": \"hg19_reads_lr_skbr3\", \"displays\": [ {\"type\": \"LinearWiggleDisplay\", \"configuration\": \"hg19_reads_lr_skbr3-LinearWiggleDisplay\" }]} ] } }"
  )

  # test alignments and not displaying reference
  expect_equal(
    default_session(
      assembly,
      c(alignments),
      display_assembly = FALSE
    ),
    "{ \"name\": \"My Session\", \"view\": { \"id\": \"LinearGenomeView\", \"type\": \"LinearGenomeView\", \"tracks\": [  { \"type\": \"AlignmentsTrack\", \"configuration\": \"hg19_ultra-long-ont_hs37d5_phased\", \"displays\": [ {\"type\": \"LinearAlignmentsDisplay\", \"configuration\": \"hg19_ultra-long-ont_hs37d5_phased-LinearAlignmentsDisplay\" }]} ] } }"
  )

  # test feature track
  expect_equal(
    default_session(
      assembly,
      c(feature),
      display_assembly = FALSE
    ),
    "{ \"name\": \"My Session\", \"view\": { \"id\": \"LinearGenomeView\", \"type\": \"LinearGenomeView\", \"tracks\": [  { \"type\": \"FeatureTrack\", \"configuration\": \"hg19_GRCh37_latest_genomic\", \"displays\": [ {\"type\": \"LinearBasicDisplay\", \"configuration\": \"hg19_GRCh37_latest_genomic-LinearBasicDisplay\" }]} ] } }"
  )
})
