import {
  createViewState,
  createJBrowseTheme,
  JBrowseLinearGenomeView,
  ThemeProvider,
} from "@jbrowse/react-linear-genome-view";

import { messageShiny } from "../utils";

const theme = createJBrowseTheme();

const assembly = {
  name: "hg19",
  sequence: {
    type: "ReferenceSequenceTrack",
    trackId: "GRCh37-ReferenceSequenceTrack",
    adapter: {
      type: "BgzipFastaAdapter",
      fastaLocation: {
        uri: "https://jbrowse.org/genomes/hg19/fasta/hg19.fa.gz",
      },
      faiLocation: {
        uri: "https://jbrowse.org/genomes/hg19/fasta/hg19.fa.gz.fai",
      },
      gziLocation: {
        uri: "https://jbrowse.org/genomes/hg19/fasta/hg19.fa.gz.gzi",
      },
    },
  },
  aliases: ["GRCh37"],
  refNameAliases: {
    adapter: {
      type: "RefNameAliasAdapter",
      location: {
        uri:
          "https://s3.amazonaws.com/jbrowse.org/genomes/hg19/hg19_aliases.txt",
      },
    },
  },
};

const tracks = [
  {
    type: "FeatureTrack",
    trackId: "ncbi_gff_hg19",
    name: "NCBI RefSeq (GFF3Tabix)",
    assemblyNames: ["hg19"],
    category: ["Annotation"],
    adapter: {
      type: "Gff3TabixAdapter",
      gffGzLocation: {
        uri:
          "https://s3.amazonaws.com/jbrowse.org/genomes/hg19/GRCh37_latest_genomic.sort.gff.gz",
      },
      index: {
        location: {
          uri:
            "https://s3.amazonaws.com/jbrowse.org/genomes/hg19/GRCh37_latest_genomic.sort.gff.gz.tbi",
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
        configuration: "GRCh37-ReferenceSequenceTrack",
        displays: [
          {
            type: "LinearReferenceSequenceDisplay",
            configuration:
              "GRCh37-ReferenceSequenceTrack-LinearReferenceSequenceDisplay",
          },
        ],
      },
      {
        type: "FeatureTrack",
        configuration: "ncbi_gff_hg19",
        displays: [
          {
            type: "LinearBasicDisplay",
            configuration: "ncbi_gff_hg19-LinearBasicDisplay",
          },
        ],
      },
    ],
  },
};

export default function Hg19View(props) {
  const state = createViewState({
    assembly,
    tracks,
    location: props.location,
    defaultSession,
    onChange: messageShiny,
  });

  return (
    <ThemeProvider theme={theme}>
      <JBrowseLinearGenomeView viewState={state} />
    </ThemeProvider>
  );
}
