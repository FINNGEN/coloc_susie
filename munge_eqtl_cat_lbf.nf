nextflow.enable.dsl=2

process munge_lbf {

    cpus 1
    memory 2.GB
    disk 50.GB
    publishDir "$params.outdir"

    input:
      path(fname)
    output:
      path '*.munged.tsv.gz', emit: tsv
      path '*.munged.tsv.gz.tbi', emit: tbi
    shell:
      template 'munge_lbf_eqtl_cat.sh'
}

workflow {

    munge_lbf(channel.fromPath(params.lbf_files_loc))
}
