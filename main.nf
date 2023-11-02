#!/usr/bin/env nextflow

nextflow.enable.dsl = 2

if ( params.readDIR == null ) {
  exit 0, log.error("`--readDIR` must be specified.")
}

if ( params.target == null ) {
  exit 0, log.error("`--target` must be specified.")
}

// Expand user directory if exists
outDIR = "${params.outDIR}".replaceFirst("^~", System.getProperty("user.home"))
readDIR = "${params.readDIR}".replaceFirst("^~", System.getProperty("user.home"))

// Set boilerplate parameters
params.QC_only         = false
params.reads           = "${readDIR}/*_R{1,2}*.fastq.gz"
params.amplicon_info   = "$projectDir/resources/${params.target}/${params.target}_amplicon_info.tsv"
params.resmarkers_amplicon    = "$projectDir/resources/${params.target}/resistance_markers_amplicon_${params.target}.txt"

// Files
cutadapt_minlen = params.cutadapt_minlen

/*
Create 'read_pairs' channel that emits for each read pair a
tuple containing 3 elements: pair_id, R1, R2
*/

// workflows
include { DEMULTIPLEX_AMPLICONS } from './workflows/demultiplex_amplicons.nf'
include { DENOISE_AMPLICONS_1 } from './workflows/denoise_amplicons_1.nf'
include { POSTPROCESSING } from './workflows/postprocessing.nf'
include { RESISTANCE_MARKER_MODULE } from './workflows/resistance_marker_module.nf'
include { QUALITY_CONTROL} from './workflows/quality_control.nf'
include { QC_ONLY } from './workflows/qc_only.nf'


// modules
include { BUILD_ALLELETABLE } from './modules/local/build_alleletable.nf'

// main workflow
workflow {

  if (params.QC_only) {
    
    // Run QC Only Workflow
    QC_ONLY(params.reads)

  } else if (params.postproc_only) {

    // Read in denoised asv file provided by the user 
    File denoised_asvs_file = new File(params.denoised_asvs).absoluteFile
    if(!denoised_asvs_file.exists()) {
        exit 1, "The specified denoised_asvs file '${params.denoised_asvs}' does not exist."
    }

    // Add debugging steps as this is user input
    log.debug("Denoised ASVs path: ${params.denoised_asvs}")
    log.debug("Absolute path: ${denoised_asvs_file.absolutePath}")
    log.debug("Does it exist? ${denoised_asvs_file.exists()}")

    // Create the Nextflow Channel
    denoise_ch = Channel.fromPath(denoised_asvs_file)
    
    // Run postprocessing only workflow
    POSTPROCESSING(denoise_ch)

    // Allele table creation
    BUILD_ALLELETABLE(
      denoise_ch,
      POSTPROCESSING.out.results_ch
    )

  } else {

    // Create read pairs channel from fastq data
    read_pairs = channel.fromFilePairs( params.reads, checkIfExists: true )

    // Trim and demultiplex amplicons by amplicon
    DEMULTIPLEX_AMPLICONS(read_pairs)

    // Denoising (DADA specific)
    DENOISE_AMPLICONS_1(
      DEMULTIPLEX_AMPLICONS.out.demux_fastqs_ch
    )

    // Masking, collapsing ASVs
    POSTPROCESSING(
      DENOISE_AMPLICONS_1.out.denoise_ch
    )

    // Finally create the final allele table
    BUILD_ALLELETABLE(
      DENOISE_AMPLICONS_1.out.denoise_ch,
      POSTPROCESSING.out.results_ch
    )

    // Create the quality report now
    QUALITY_CONTROL(
      DEMULTIPLEX_AMPLICONS.out.sample_summary_ch,
      DEMULTIPLEX_AMPLICONS.out.amplicon_summary_ch,
      BUILD_ALLELETABLE.out.alleledata,
      DENOISE_AMPLICONS_1.out.denoise_ch
    )

    // By default, run the resistance marker module in the main workflow
    RESISTANCE_MARKER_MODULE(
      BUILD_ALLELETABLE.out.alleledata,
      POSTPROCESSING.out.reference_ch
    )
  }
}


workflow.onComplete {
  def outputDir = new File("${params.outDIR}/run")
  if (!outputDir.exists()) {
      outputDir.mkdirs()
  }

  record_params()
  record_runtime()
}


/* Record parmameters
 *
 * Records set parameters for the run
 *
 */
def record_params() {
    
    def output = new File("${params.outDIR}/run/parameters.tsv")

    params.each{ k, v -> 
        output.append("${k}\t${v}\n")
    }
}


/* Record runtime information
 *
 * Records runtime and environment information and writes summary to a tabulated (tsv) file
 *
 */
def record_runtime() {

    def output = new File("${params.outDIR}/run/runtime.tsv")

    // Append ContainerEngine first as shown in your example
    output.append("PipelineVersion\t${workflow.manifest.version}\n")
    output.append("ContainerEngine\t${workflow.containerEngine}\n")
    output.append("Duration\t${workflow.duration}\n")
    output.append("CommandLine\t${workflow.commandLine}\n")
    output.append("CommitId\t${workflow.commitId}\n")
    output.append("Complete\t${workflow.complete}\n")
    output.append("ConfigFiles\t${workflow.configFiles.join(', ')}\n")
    output.append("Container\t${workflow.container}\n")
    output.append("ErrorMessage\t${workflow.errorMessage}\n")
    output.append("ErrorReport\t${workflow.errorReport}\n")
    output.append("ExitStatus\t${workflow.exitStatus}\n")
    output.append("HomeDir\t${workflow.homeDir}\n")
    output.append("LaunchDir\t${workflow.launchDir}\n")
    output.append("Manifest\t${workflow.manifest}\n")
    output.append("Profile\t${workflow.profile}\n")
    output.append("ProjectDir\t${workflow.projectDir}\n")
    output.append("Repository\t${workflow.repository}\n")
    output.append("Resume\t${workflow.resume}\n")
    output.append("Revision\t${workflow.revision}\n")
    output.append("RunName\t${workflow.runName}\n")
    output.append("ScriptFile\t${workflow.scriptFile}\n")
    output.append("ScriptId\t${workflow.scriptId}\n")
    output.append("ScriptName\t${workflow.scriptName}\n")
    output.append("SessionId\t${workflow.sessionId}\n")
    output.append("Start\t${workflow.start}\n")
    output.append("StubRun\t${workflow.stubRun}\n")
    output.append("Success\t${workflow.success}\n")
    output.append("UserName\t${workflow.userName}\n")
    output.append("WorkDir\t${workflow.workDir}\n")
    output.append("NextflowBuild\t${nextflow.build}\n")
    output.append("NextflowTimestamp\t${nextflow.timestamp}\n")
    output.append("NextflowVersion\t${nextflow.version}\n")
}
