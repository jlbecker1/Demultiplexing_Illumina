nextflow.enable.dsl = 2

include { MULTIQC } from '../main.nf'

workflow {
    
    // Create test input channels
    multiqc_files = Channel.fromPath("data/*", checkIfExists: false)
        .collect()

    multiqc_config = Channel.fromPath("multiQC.yaml", checkIfExists: false)
        .ifEmpty([])
    
    multiqc_logo = Channel.fromPath("logo.png", checkIfExists: false)
        .ifEmpty([])
    
    replace_names = Channel.fromPath("replace_names.txt", checkIfExists: false)
        .ifEmpty([])
    
    sample_names = Channel.fromPath("sample_names.txt", checkIfExists: false)
        .ifEmpty([])

    MULTIQC(
        multiqc_files,
        multiqc_config,
        multiqc_logo,
        replace_names,
        sample_names
    )


    // Print outputs for verification
    MULTIQC.out.report.view { "MultiQC report: $it" }
    MULTIQC.out.data.view { "MultiQC data: $it" }
    MULTIQC.out.plots.view { "MultiQC plots: $it" }
    MULTIQC.out.versions.view { "Versions: $it" }
} 