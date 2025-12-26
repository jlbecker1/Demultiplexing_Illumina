nextflow.enable.dsl = 2

include { MD5SUM } from '../main.nf'

workflow {

    test_input = Channel.of([
        [ id: 'test' ],
        [ file('Test_R1.fastq.gz') , file('Test_R2.fastq.gz') ] 
    ])
    
    MD5SUM(test_input)    

    MD5SUM.out.checksum.view { "CHECKSUM: $it" }
    MD5SUM.out.versions.view { "VERSIONS: $it" }
}
