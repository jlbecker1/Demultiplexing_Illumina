#!/usr/bin/env nextflow

nextflow.enable.dsl = 2

process BCLCONVERT {
    tag "$meta.id"
    
    // Software dependencies
    container "quay.io/nf-core/bclconvert:4.3.13"

    input:
    tuple val(meta), path(run_dir), path(samplesheet), val(output_dir)
    
    output:
    tuple val(meta), path("${output_dir}/**_S[1-9]*_R?_00?.fastq.gz")        , emit: fastq
    tuple val(meta), path("${output_dir}/**_S[1-9]*_I?_00?.fastq.gz")        , emit: fastq_idx       , optional:true
    tuple val(meta), path("${output_dir}/**Undetermined_S0*_R?_00?.fastq.gz"), emit: undetermined    , optional:true
    tuple val(meta), path("${output_dir}/**Undetermined_S0*_I?_00?.fastq.gz"), emit: undetermined_idx, optional:true
    tuple val(meta), path("${output_dir}/Reports")                           , emit: reports
    tuple val(meta), path("${output_dir}/Logs")                              , emit: logs
    tuple val(meta), path("${output_dir}/InterOp/*.bin")                     , emit: interop         , optional:true
    path("versions.yml")                                                     , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    // here we set the arguments and prefixes to be used in the on script
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    
    """
    bcl-convert ${args} --bcl-input-directory ${run_dir} --sample-sheet ${samplesheet} --output-directory ${output_dir}


    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bcl_convert: \$(bcl_convert --version 2>&1 | sed 's/^.*bcl_convert //; s/ .*\$//')
    END_VERSIONS
    """

    // stub block can be set for the purpose of testing, debugging, or validating a workflow structure
    stub:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def output_dir = task.ext.output_dir ?: "output"
    """
    # Create output directory structure
    mkdir -p ${output_dir}/Reports
    mkdir -p ${output_dir}/Logs
    mkdir -p ${output_dir}/InterOp

    # Create main FASTQ files (R1/R2)
    touch ${output_dir}/${prefix}_S1_R1_001.fastq.gz
    touch ${output_dir}/${prefix}_S1_R2_001.fastq.gz
    touch ${output_dir}/${prefix}_S2_R1_001.fastq.gz
    touch ${output_dir}/${prefix}_S2_R2_001.fastq.gz

    # Create index FASTQ files (optional)
    touch ${output_dir}/${prefix}_S1_I1_001.fastq.gz
    touch ${output_dir}/${prefix}_S1_I2_001.fastq.gz

    # Create undetermined FASTQ files (optional)
    touch ${output_dir}/Undetermined_S0_R1_001.fastq.gz
    touch ${output_dir}/Undetermined_S0_R2_001.fastq.gz

    # Create undetermined index FASTQ files (optional)
    touch ${output_dir}/Undetermined_S0_I1_001.fastq.gz
    touch ${output_dir}/Undetermined_S0_I2_001.fastq.gz

    # Create report files
    touch ${output_dir}/Reports/Demultiplex_Stats.csv
    touch ${output_dir}/Reports/Top_Unknown_Barcodes.csv
    touch ${output_dir}/Reports/Adapter_Metrics.csv

    # Create log files
    touch ${output_dir}/Logs/Info.log
    touch ${output_dir}/Logs/Warnings.log
    touch ${output_dir}/Logs/Errors.log

    # Create InterOp files (optional)
    touch ${output_dir}/InterOp/QMetricsOut.bin
    touch ${output_dir}/InterOp/TileMetricsOut.bin
    touch ${output_dir}/InterOp/IndexMetricsOut.bin

   cat <<-END_VERSIONS > versions.yml
   "${task.process}":
     bcl_convert: \$(bcl-convert --version 2>&1 | sed 's/^.*bcl-convert //; s/ .*\$//' || echo "4.3.13")
  END_VERSIONS
  """
}
