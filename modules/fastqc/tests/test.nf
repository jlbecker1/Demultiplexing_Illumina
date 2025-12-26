nextflow.enable.dsl = 2

include { FASTQC } from '../main.nf'

workflow {

    test_input = Channel.of([
        [ id: 'test' ],
        file('Test_R1.fastq.gz')  
    ])
    
    FASTQC(test_input)    

    FASTQC.out.html.view { "FASTQ: $it" }
    FASTQC.out.zip.view { "FASTQ_IDX: $it" }
    FASTQC.out.versions.view { "VERSIONS: $it" }
}
