nextflow.enable.dsl = 2

include { BCLCONVERT } from '../main.nf'

workflow {

    test_input = Channel.of([
        [ id: 'test_run' ],
        file('/scratch/grc_group/test_data_for_pipelines/demultiplexing/20250411_LH00497_0076_A22YJV5LT3/', checkIfExists: true),
        file('/scratch/grc_group/test_data_for_pipelines/demultiplexing/20250411_LH00497_0076_A22YJV5LT3/SampleSheetPractice.csv', checkIfExists: true),
        'test_output'
    ])
    
    BCLCONVERT(test_input)    

 
    BCLCONVERT.out.fastq.view { "FASTQ: $it" }
    BCLCONVERT.out.fastq_idx.view { "FASTQ_IDX: $it" }
    BCLCONVERT.out.undetermined.view { "UNDETERMINED: $it" }
    BCLCONVERT.out.undetermined_idx.view { "UNDETERMINED_IDX: $it" }
    BCLCONVERT.out.reports.view { "REPORTS: $it" }
    BCLCONVERT.out.logs.view { "LOGS: $it" }
    BCLCONVERT.out.interop.view { "INTEROP: $it" }
    BCLCONVERT.out.versions.view { "VERSIONS: $it" }
}
