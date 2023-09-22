process QUALITY_REPORT {
  
  label 'process_low'

  publishDir(
      path: "${params.outDIR}",
      mode: 'copy'
  )

  input:
  path (sample_coverage) 
  path (amplicon_coverage)
  path (amplicon_info)
  path (spikein_json) 
  
  output:
  file ('sample_coverage.txt')
  file ('amplicon_coverage.txt')
  file ('quality_report')

  script:
  if (spikein_json) {
      """
      # Rename input files to published versions
      mv $sample_coverage sample_coverage.txt
      mv $amplicon_coverage amplicon_coverage.txt

      test -d quality_report || mkdir quality_report
      Rscript ${projectDir}/bin/cutadapt_summaryplots.R \
        --summaryFILE amplicon_coverage.txt \
        --samplestatFILE sample_coverage.txt \
        --ampliconFILE $amplicon_info \
        --outDIR quality_report  \
        --spikein-cutadapt-json ${spikein_json.join(" ")}
      """
  } else {
      """
      # Rename input files to published versions
      mv $sample_coverage sample_coverage.txt
      mv $amplicon_coverage amplicon_coverage.txt

      test -d quality_report || mkdir quality_report
      Rscript ${projectDir}/bin/cutadapt_summaryplots.R \
        --summaryFILE amplicon_coverage.txt \
        --samplestatFILE sample_coverage.txt \
        --ampliconFILE $amplicon_info \
        --outDIR quality_report 
      """
  }
}