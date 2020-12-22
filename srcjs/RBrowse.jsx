import { reactWidget } from "reactR";
import {
  createViewState,
  createJBrowseTheme,
  JBrowseLinearGenomeView,
  ThemeProvider,
} from "@jbrowse/react-linear-genome-view";

const theme = createJBrowseTheme();

const assembly = {
  name: "GRCh38",
  sequence: {
    type: "ReferenceSequenceTrack",
    trackId: "GRCh38-ReferenceSequenceTrack",
    adapter: {
      type: "BgzipFastaAdapter",
      fastaLocation: {
        uri:
          "http://ftp.ensembl.org/pub/release-100/fasta/homo_sapiens/dna_index/Homo_sapiens.GRCh38.dna.toplevel.fa.gz",
      },
      faiLocation: {
        uri:
          "http://ftp.ensembl.org/pub/release-100/fasta/homo_sapiens/dna_index/Homo_sapiens.GRCh38.dna.toplevel.fa.gz.fai",
      },
      gziLocation: {
        uri:
          "http://ftp.ensembl.org/pub/release-100/fasta/homo_sapiens/dna_index/Homo_sapiens.GRCh38.dna.toplevel.fa.gz.gzi",
      },
    },
  },
  aliases: ["hg38"],
  refNameAliases: {
    adapter: {
      type: "RefNameAliasAdapter",
      location: {
        uri:
          "https://s3.amazonaws.com/jbrowse.org/genomes/GRCh38/hg38_aliases.txt",
      },
    },
  },
};

const tracks = [
  {
    type: "FeatureTrack",
    trackId: "ncbi_refseq_109_hg38",
    name: "NCBI RefSeq (GFF3Tabix)",
    assemblyNames: ["GRCh38"],
    category: ["Annotation"],
    adapter: {
      type: "Gff3TabixAdapter",
      gffGzLocation: {
        uri:
          "https://s3.amazonaws.com/jbrowse.org/genomes/GRCh38/ncbi_refseq/GCA_000001405.15_GRCh38_full_analysis_set.refseq_annotation.sorted.gff.gz",
      },
      index: {
        location: {
          uri:
            "https://s3.amazonaws.com/jbrowse.org/genomes/GRCh38/ncbi_refseq/GCA_000001405.15_GRCh38_full_analysis_set.refseq_annotation.sorted.gff.gz.tbi",
        },
      },
    },
  },
];

const defaultSession = {
  name: "My session",
  view: {
    id: "linearGenomeView",
    type: "LinearGenomeView",
    tracks: [
      {
        type: "ReferenceSequenceTrack",
        configuration: "GRCh38-ReferenceSequenceTrack",
        displays: [
          {
            type: "LinearReferenceSequenceDisplay",
            configuration:
              "GRCh38-ReferenceSequenceTrack-LinearReferenceSequenceDisplay",
          },
        ],
      },
      {
        type: "FeatureTrack",
        configuration: "ncbi_refseq_109_hg38",
        displays: [
          {
            type: "LinearBasicDisplay",
            configuration: "ncbi_refseq_109_hg38-LinearBasicDisplay",
          },
        ],
      },
    ],
  },
};

function ViewHg38(props) {
  console.log({ props });
  const state = createViewState({
    assembly,
    tracks,
    location: props.location,
    defaultSession,
  });
  return (
    <ThemeProvider theme={theme}>
      <JBrowseLinearGenomeView viewState={state} />
    </ThemeProvider>
  );
}

reactWidget("RBrowse", "output", { ViewHg38: ViewHg38 });
