nextflow.enable.dsl=2

process coloc {

    cpus { lbf2_file.size() < 250.MB ? 1 : lbf2_file.size() < 500.MB ? 2 : lbf2_file.size() < 1.GB ? 4 : lbf2_file.size() < 2.GB ? 8 : 16 }
    memory { lbf2_file.size() < 250.MB ? 2.GB : lbf2_file.size() < 500.MB ? 4.GB : lbf2_file.size() < 1.GB ? 8.GB : lbf2_file.size() < 2.GB ? 16.GB : 32.GB }
    disk 50.GB
    publishDir "$params.outdir/coloc/"

    input:
      tuple path(lbf1_file), path(lbf1_file_tbi)
      tuple path(lbf2_file), path(lbf2_file_tbi)
      val region_col
      val trait1_col
      val variant1_col
      val dataset2_col
      val trait2_col
      val variant2_col
      val chr_prefix1
      val chr_prefix2
    output:
      path '*.coloc.tsv.gz', emit: tsv
    shell:
      template 'coloc.sh'
}

process clp {

    cpus 1
    memory 2.GB
    disk 50.GB
    publishDir "$params.outdir/clp/"

    input:
      path(cs1_file)
      path(cs2_file)
    output:
      path '*.clp.tsv.gz', emit: tsv
    shell:
      template 'clp.sh'
}

process gather_coloc {

    cpus 2
    memory 4.GB
    disk 1000.GB
    publishDir "$params.outdir"

    input:
      path '*'
      val outfile
    output:
      path '*.gz'
    shell:
      template 'gather_coloc.sh'
}

process merge_clp {

    cpus 2
    memory 4.GB
    disk 200.GB
    publishDir "$params.outdir"

    input:
      path '*'
      val outfile
    output:
      path '*.gz'
    shell:
      template 'merge_clp.sh'
}

workflow {

    clp(channel.value(params.cs1_file) | map { it -> file(it) }, channel.fromPath(params.cs2_files_loc))
    merge_clp(clp.out.tsv | collect, channel.value(params.clp_outfile))
    coloc(channel.value(params.lbf1_file) | map { it -> [ file(it), file(it + ".tbi") ] },
          channel.fromPath(params.lbf2_files_loc) | map { it -> [ it, it + ".tbi" ] },
          //channel.fromPath(params.lbf2_files_loc).splitText { it.strip() } | map { it -> [ file(it), file(it + ".tbi") ] }, // if params.lbf2_files_loc is a path to a file containing a file list
          channel.value(params.region_col),
          channel.value(params.trait1_col),
          channel.value(params.variant1_col),
          channel.value(params.dataset2_col),
          channel.value(params.trait2_col),
          channel.value(params.variant2_col),
          channel.value(params.chr_prefix1),
          channel.value(params.chr_prefix2))
    gather_coloc(coloc.out.tsv | collect, channel.value(params.coloc_outfile))
}
