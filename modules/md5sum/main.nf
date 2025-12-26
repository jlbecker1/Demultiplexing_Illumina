#!/usr/bin/env nextflow

nextflow.enable.dsl = 2

process MD5SUM {
    tag "$meta.id"
   
    input:
    tuple val(meta), path(files)

    output:
    tuple val(meta), path("*.md5"), emit: checksum
    path "versions.yml", emit: versions

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    
    """
    find -L * -type f \\
        ! -name '*.md5' \\
        -exec md5sum ${args} "{}" + \\
         > ${prefix}.md5

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        md5sum: \$( md5sum --version | sed '1!d; s/.* //' )
    END_VERSIONS
    """

    // stub block can be set for the purpose of testing, debugging, or validating a workflow structure
    stub:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}.md5

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        md5sum: \$( md5sum --version | sed '1!d; s/.* //' )
    END_VERSIONS
    """
}