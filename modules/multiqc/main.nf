#!/usr/bin/env nextflow

nextflow.enable.dsl = 2

process MULTIQC {
    
    // Software dependencies
    container "oras://community.wave.seqera.io/library/multiqc:1.31--e111a2e953475c51"

    input:
    path multiqc_files, stageAs: "?/*"
    path(multiqc_config)
    path(multiqc_logo)
  //  path(replace_names)
  //  path(sample_names)

    output:
    path "*multiqc_report.html", emit: report
    path "*_data"              , emit: data
    path "*_plots"             , optional:true, emit: plots
    path "versions.yml"        , emit: versions

    when:
    task.ext.when == null || task.ext.when // clause for conditional execution | can set up conditional behavior in config file OR directly set in nf script 

    script:
    // here we set the arguments and prefixes to be used in the on script
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ? "--filename ${task.ext.prefix}_multiqc_report.html" : ''
    def config = multiqc_config ? "--config $multiqc_config" : ''
    def logo = multiqc_logo ? "--cl-config 'custom_logo: \"${multiqc_logo}\"'" : ''
    // def replace = replace_names ? "--replace-names ${replace_names}" : ''
    // def samples = sample_names ? "--sample-names ${sample_names}" : ''

    """
     multiqc \\
        --force \\
        $args \\
        $config \\
        $prefix \\
        $logo \\
        .

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        multiqc: \$( multiqc --version | sed -e "s/multiqc, version //g" )
    END_VERSIONS
    """

  // stub block can be set for the purpose of testing, debugging, or validating a workflow structure
  stub:
    """
    mkdir multiqc_data
    mkdir multiqc_plots
    touch multiqc_report.html

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        multiqc: \$( multiqc --version | sed -e "s/multiqc, version //g" )
    END_VERSIONS
    """
}