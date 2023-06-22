nextflow.enable.dsl=2

process munge_lbf {

    cpus 1
    memory 2.GB
    disk 50.GB

    input:
      path(fname)
    output:
      path '*.munged.tsv.gz', emit: tsv
    shell:
      template 'munge_lbf_finngen.sh'
}

process merge_lbf {

    cpus 4
    memory 8.GB
    disk 1000.GB
    publishDir "$params.outdir"

    input:
      path('*')
    output:
      path '*.gz'
      path '*.gz.tbi'
    shell:
      template 'merge_lbf_finngen.sh'
}

workflow {

    munge_lbf(channel.fromPath(params.lbf_files_loc))
    merge_lbf(munge_lbf.out.tsv | collect)
}
