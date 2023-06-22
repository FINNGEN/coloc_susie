# coloc_susie
Colocalization of fine-mapped signals with coloc.susie

This repo contains workflows to compute coloc.susie and CLPP/CLPA colocalization metrics based on SuSiE fine-mapping results.

## Example run (FinnGen internal)

These are instructions for running the colocalization workflow assuming you have a fresh Ubuntu 22 install on a GCP VM.

### Prerequisites

Clone this repo and cd into it:

```
git clone https://github.com/FINNGEN/coloc_susie
cd coloc_susie
```

Install Java (required by nextflow) and nextflow:
```bash
sudo apt update && sudo apt install openjdk-19-jre-headless -y
curl -s https://get.nextflow.io | bash
sudo mv nextflow /usr/local/bin/
```

Install Docker (nextflow tasks run in Docker containers) following the instructions [here](https://docs.docker.com/engine/install/ubuntu/).

[Add yourself to the docker group](https://docs.docker.com/engine/install/linux-postinstall/) (restarting the VM should not be necessary if you run `newgrp docker` after adding your user to the group) and [authenticate with container registry](https://cloud.google.com/container-registry/docs/advanced-authentication#gcloud-helper)

### Download data

Here we run the workflow locally on the VM. We run all FinnGen fine-mapped phenotypes against two eQTL Catalogue R6 datasets.

First download the data:

```bash
# get lbfs and credible sets of all FinnGen phenos
gsutil -m cp gs://finngen-commons/coloc/finngen_r11_lbf_all.tsv.gz* .
gsutil -m cp gs://finngen-commons/credible_sets/FinnGen_R11_credible_sets.tsv.gz* .

# get lbfs and credible sets of the two smallest eQTL Cat datasets
gsutil -m cp gs://finngen-commons/eqtl_catalogue/r6/lbf_variable_munged/QTD000488.lbf_variable.munged.tsv.gz* .
gsutil -m cp gs://finngen-commons/eqtl_catalogue/r6/lbf_variable_munged/QTD000498.lbf_variable.munged.tsv.gz* .
gsutil -m cp gs://finngen-commons/eqtl_catalogue/r6/credible_sets/QTD000488.credible_sets.tsv.gz .
gsutil -m cp gs://finngen-commons/eqtl_catalogue/r6/credible_sets/QTD000498.credible_sets.tsv.gz .
```

As per [coloc.config](coloc.config) the local workflow profile will now use the downloaded files with the pipeline.

### Run the workflow

Launch the workflow:

```bash
nextflow run coloc.nf -c coloc.config -profile local -resume
```

All goes well and the output is initally something like:

```log
N E X T F L O W  ~  version 23.04.2
Launching `coloc.nf` [disturbed_faraday] DSL2 - revision: 150da03f98
executor >  local (4)
[ae/9fd923] process > clp (1)      [  0%] 0 of 2
[-        ] process > merge_clp    -
[88/83a6c7] process > coloc (2)    [  0%] 0 of 2
[-        ] process > gather_coloc -
```

After the tasks are finished (maybe 7 or 30 minutes depending on the number of CPUs on the VM), you'll find the combined CLPP/CLPA and coloc.susie results in the current directory. Data about the run is in the `pipeline_info` directory under the current directory.

To run the workflow with more data in the cloud instead of locally, modify [coloc.config](coloc.config) according to the data you want to run. Set these env variables (see [nextflow.config](nextflow.config)):

```
export GOOGLE_WORKDIR="gs://[BUCKET_TO_KEEP_TASK_LOGS_AND_OUTPUTS_IN]"
export GOOGLE_PROJECT="[YOUR_GOOGLE_PROJECT]"
```

```bash
nextflow run coloc.nf -c coloc.config -profile gls -resume
```
