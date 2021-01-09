import { reactWidget } from "reactR";
import ViewHg38 from "./components/ViewHg38";
import ViewHg19 from "./components/ViewHg19";

reactWidget("RBrowse", "output", { ViewHg38, ViewHg19 });
