/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
DEMULTIPLEXING WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

// Import modules

include { BCLCONVERT } from '../modules/bclconvert/main'
include { MD5SUM } from '../modules/md5sum/main'
include { FASTQC } from '../modules/fastqc/main'
include { MULTIQC } from '../modules/multiqc/main'

workflow DEMULTIPLEXING {
    
    take:
    ch_input

    main:
    
    // Initialize = channels 
    ch_versions = Channel.empty()

    ch_multiqc_files = Channel.empty()
    ch_multiqc_config= Channel.fromPath('demultiplexing/conf/multiQC_1.31.yaml')
    ch_multiqc_logo= Channel.fromPath('demultiplexing/assets/URochester_Logo_Black.png')

    // Run BCLCONVERT 
    BCLCONVERT(ch_input)
    ch_versions = ch_versions.mix(BCLCONVERT.out.versions)
    
    BCLCONVERT.out.fastq
    //.view { meta, fastq -> "Before Parsing: ${meta} ${fastq}" }
    .flatMap { meta, files ->
        // use arrow operator to define to enteries
        // we next create an empty map (dictionary)
        def sample_map = [:]
        // loop over our list of files using each 
        files.each { file ->
            // since 'file' is a path we want to get the file name 
            def filename = file.getName()
            // here we crete a matcher object. This give us access to 'groups' based on the regex pattern. 
            def matcher = filename =~ /^(.+?)_S\d+_L\d+_(R[12])_\d+\.fastq\.gz$/
            if (matcher) {
                def sample_key = matcher[0][1]  // excess our first group (.+?) which is the sample name 
                def read = matcher[0][2]         // "R1" or "R2"

                // verify our sample key exists in our map 
                if (!sample_map[sample_key]) {
                    sample_map[sample_key] = [:]
                }

                // add read to sample key in map (i.e dictionary) 
                sample_map[sample_key][read] = file
            }
        }
        // Create paired entries
        // we use collect method to tranform our "mapped" items into a list 
        sample_map.collect { sample_key, reads ->
            def new_meta = meta.clone()
            new_meta.id = sample_key
            [new_meta, [reads.R1, reads.R2]]
        }
    }
    //.view {meta, files -> "After Parsing: ${meta.id}, ${files}"}
    .set { fastq_paired }

    // Run FASTQC 
    FASTQC(fastq_paired)
    ch_versions = ch_versions.mix(FASTQC.out.versions)
    ch_multiqc_files = ch_multiqc_files.mix(FASTQC.out.zip
                                        .map { meta, zip -> zip } )


    // Run MD5SUM 
    MD5SUM(BCLCONVERT.out.fastq)

    // Run MULTIQC
    MULTIQC(ch_multiqc_files.collect(), ch_multiqc_config, ch_multiqc_logo)
    
   // emit:
   multiqc_report  = MULTIQC.out.report 
   versions = ch_versions
}