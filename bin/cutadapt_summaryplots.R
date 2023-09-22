library(tidyverse)
library(gridExtra)
library(ggbeeswarm)
library(rmarkdown)
library(knitr)
library(argparse)
library(stringr)
library(rjson)
library(foreach)

parser <- ArgumentParser(description='Create the MAD4HATTER quality report')
parser$add_argument('--summaryFILE', type="character", help='Contains amplicon level coverage statistics.', required = TRUE)
parser$add_argument('--samplestatFILE', type="character", help='Contains sample level coverage statistics.', required = TRUE)
parser$add_argument('--spikein-cutadapt-json', type="character", nargs="+", help="Cutadapt spikein statistics (optional).", required = FALSE)
parser$add_argument('--ampliconFILE', type="character", help='Amplicon panel table.', required = TRUE)
parser$add_argument('--outDIR', type="character", help="Output directory for the quality report.", required = TRUE)

args=parser$parse_args()
print(args)

## For debugging
# setwd("/home/bpalmer/Documents/GitHub/mad4hatter/work/74/83d316302e4393f87190bbb2a5a8f4")
# args$summaryFILE="amplicon_coverage.txt"
# args$samplestatFILE="sample_coverage.txt"
# args$ampliconFILE="v4_amplicon_info.tsv"
# args$outDIR="quality_report"
# args$spikein_cutadapt_json=list.files(pattern = ".spikeins.json$")

spikeins=NULL
if (!is.null(args$spikein_cutadapt_json)) {
  spikeins=foreach (ii = 1:length(args$spikein_cutadapt_json), .combine="bind_rows") %do% {
    infile=args$spikein_cutadapt_json[[ii]]
    json=rjson::fromJSON(file=infile)
    if (!json$cutadapt_version %in% c("4.4")) {
      stop(sprintf("Expected cutadapt version is %s but the user provided cutadapt json has version %s", "4.4", json$cutadapt_version))
    }

    sampleID=stringr::str_remove(infile, ".spikeins.cutadapt.json$")
    tibble(
      sampleID=sampleID,
      read1_matches=json$adapters_read1[[1]]$five_prime_end$matches,
      read2_matches=json$adapters_read2[[1]]$five_prime_end$matches
    )
  }

  write.table(spikeins, file=file.path(args$outDIR,"spikeins.txt"), quote=F, sep ="\t", col.names=T, row.names=F)
}

df=read.table(args$summaryFILE,header=T)
df$SampleID=as.factor(df$SampleID)
df$Locus=as.factor(df$Locus)
df = df %>% 
  mutate(SampleNumber=sapply(str_split(SampleID,'_S'),tail,1)) %>% 
  mutate(SampleID=sapply(str_split(SampleID,'_S(\\d+)'),head,1)) %>% 
  mutate(Pool=sapply(str_split(Locus,'-'),tail,1)) %>% 
  arrange(SampleID) %>% 
  data.frame()

samples = df %>% select(SampleID,SampleNumber) %>% distinct() %>% 
  arrange(SampleNumber)

df$SampleID=factor(df$SampleID,levels=unique(samples$SampleID))

amplicon_stats=df %>% select(-Pool) %>% pivot_wider(names_from = Locus, values_from = Reads) %>% data.frame()
write.table(amplicon_stats, file=file.path(args$outDIR,"amplicon_stats.txt"), quote=F, sep ="\t", col.names=T, row.names=F)

sample_amplicon_stats=df %>% group_by(SampleID,Pool) %>% dplyr::summarise(medianReads=median(Reads)) %>% pivot_wider(names_from = Pool, values_from = medianReads) %>% data.frame()
colnames(sample_amplicon_stats)=c("SampleID","Pool_1A","Pool_1AB","Pool_1B","Pool_1B2", "Pool_2")

loci_stats = df %>% group_by(SampleID) %>% group_by(SampleID,Pool) %>% dplyr::summarise(n_loci=sum(Reads >= 100)) %>% pivot_wider(names_from = Pool, values_from = n_loci) %>% data.frame()
colnames(loci_stats)=c("SampleID","Pool_1A","Pool_1AB","Pool_1B","Pool_1B2", "Pool_2")


df1=read.delim(args$samplestatFILE,header=T)
sample_stats=df1 %>% 
  pivot_wider(names_from = Stage, values_from = Reads) %>%
  data.frame() %>%
  mutate(SampleNumber=sapply(str_split(SampleID,'_S'),tail,1)) %>%
  mutate(SampleID=sapply(str_split(SampleID,'_S(\\d+)'),head,1))
sample_stats$SampleID=factor(sample_stats$SampleID,
                              levels=unique(samples$SampleID)) 
sample_stats=sample_stats[,c("SampleNumber","SampleID","Input","No.Dimers", "Amplicons")]%>% 
  arrange(SampleNumber)

colnames(sample_stats) = c("#","Sample","Input","No Dimers","Amplicons")

ampdata=read.delim(args$ampliconFILE,header=T)

#Histogram#
p1=ggplot(data=df, aes(x=Reads+0.1)) +  
  geom_histogram( ) + 
  scale_y_continuous() +
  scale_x_log10()+
  guides(fill=FALSE) + 
  xlab("Read Count") + 
  ylab("Frequency") + 
  ggtitle("\nNumber of Reads/Locus") + 
  theme_bw() + 
  theme(plot.title = element_text(hjust = 0.5)) + 
  facet_wrap(~SampleID,ncol=6) + 
  theme(plot.title = element_text(hjust = 0.5, size=25)) + 
  theme(strip.text.x = element_text(size = 25)) +
  theme(axis.text.x = element_text(size = 25)) + 
  theme(axis.text.y = element_text(size = 25)) + 
  theme(axis.title.x = element_text(size = 25))+
  theme(axis.title.y = element_text(size = 25))+
  scale_y_log10()

ggsave(file=file.path(args$outDIR, "reads_histograms.pdf"), width=40, height=60, dpi=300, limitsize = FALSE)


#Boxplot#
numsamples=length(unique(df$SampleID))
samples_group1=unique(df$SampleID)[1:ceiling(numsamples/2)]
samples_group2=unique(df$SampleID)[(ceiling(numsamples/2)+1):numsamples]

p2a=ggplot( data=df %>% dplyr::filter(SampleID %in% samples_group1),aes(x=SampleID, y=Reads)) +
    geom_boxplot(color="#993333",lwd=0.75) +
    theme_bw() + theme(plot.title = element_text(hjust = 0.5)) +
    theme(legend.position="none",plot.title = element_text(size=11)) +
    theme(axis.text.x = element_text(angle = 90)) +
    ggtitle("Number of Reads/Locus") +
    xlab("") + facet_wrap(~Pool,ncol=1)
    
p2b=ggplot( data=df %>% dplyr::filter(SampleID %in% samples_group2),aes(x=SampleID, y=Reads)) +
    geom_boxplot(color="#993333",lwd=0.75) +
    theme_bw() + theme(plot.title = element_text(hjust = 0.5)) +
    theme(legend.position="none",plot.title = element_text(size=11)) +
    theme(axis.text.x = element_text(angle = 90)) +
    ggtitle("Number of Reads/Locus") +
    xlab("") + facet_wrap(~Pool,ncol=1)  
    
   
df2=df
df2$Reads[which(df$Reads == 0)]=0.1  
p3=ggplot(df2) +   
  ggbeeswarm::geom_quasirandom(aes(x=1,y=Reads,color = Pool),dodge.width = 0.5,size=3)+
  scale_y_log10()+
  facet_wrap(~SampleID,ncol=6)+
  theme_bw() +
  xlab("")+
  theme(axis.text.x = element_blank(),axis.ticks = element_blank())+
  geom_hline(yintercept = 100,linetype="dashed",color = "grey")+
  theme(strip.text.x = element_text(size = 25))+
  theme(axis.text.y = element_text(size = 25)) + 
  theme(axis.title.y = element_text(size = 25))+
  theme(plot.title = element_text(hjust = 0.5, size=30)) + 
  theme(legend.text = element_text(size = 25), 
        legend.title = element_text(size = 25), 
        legend.position="bottom")

ggsave(file=file.path(args$outDIR, "swarm_plots.pdf"), width=60, height=160, dpi=300, limitsize=FALSE)

#Length vs. Reads#
df1=df %>% left_join(ampdata,by = c("Locus" = "amplicon")) %>% select(SampleID,Locus,Reads,ampInsert_length,Pool) %>% data.frame()
p4=ggplot(df1,aes(x=ampInsert_length,y=Reads+0.1,color = Pool)) + ggtitle("Locus Length vs. Reads") + 
  geom_point(alpha=0.9,size=2.5) + 
  scale_y_log10()+
  xlab("Locus Insert Length") + 
  theme_bw() + 
  facet_wrap(~SampleID,ncol=6) + 
  theme(strip.text.x = element_text(size = 25))+
  theme(axis.text.x = element_text(size = 25)) + 
  theme(axis.text.y = element_text(size = 25)) + 
  theme(axis.title.x = element_text(size = 25))+
  theme(axis.title.y = element_text(size = 20))+
  theme(plot.title = element_text(hjust = 0.5, size=30)) + 
  theme(legend.text = element_text(size = 25), 
        legend.title = element_text(size = 25), 
        legend.position="bottom") 

ggsave(file=file.path(args$outDIR, "length_vs_reads.pdf"), width=60, height=200, dpi=300, limitsize=FALSE)

#pdf(paste(outDIR,"/QCplots.pdf",sep=""), onefile = TRUE)
#grid.arrange(p1,p2a,p2b,p3,p4)
#dev.off()

#p=list(p1,p3,p4)
#ml <- marrangeGrob(p, nrow=1, ncol=1)
## non-interactive use, multipage pdf
#ggsave(filename = paste(outDIR,"/QCplots.pdf",sep=""), plot = ml, width = 15, height = 9)


##RMarkdown report##

currentDate <- Sys.Date()
#rmd_file=paste(outDIR,"/QCplots.Rmd",sep="")
rmd_file=file.path(args$outDIR,"QCplots.Rmd")
file.create(rmd_file)
p=list(spikeins,sample_stats,sample_amplicon_stats,loci_stats,p1,p3,p4)

file <- tempfile()
saveRDS(p, file)

c(paste0("---\ntitle: \"QC summary Report\"\nauthor: \"MAD4HATTER\"\ndate: ",
currentDate,
"\noutput: html_document\n---\n")) %>% write_lines(rmd_file)
#c("```{r echo=FALSE, message=FALSE, warning=FALSE}\nplot_list=readRDS(file)\nlapply(plot_list,print)\n```") %>% write_lines(rmd_file,append=T)
index=1
if (!is.null(args$spikein_cutadapt_json)) {
  c(sprintf("```{r echo=FALSE, results=\'asis\', message=FALSE, warning=FALSE}\nplot_list=readRDS(file)\nknitr::kable(plot_list[%d], caption=\"Spikein Sample Statistics\")\n```", index)) %>% write_lines(rmd_file,append=T)
}
index=index+1
c(sprintf("```{r echo=FALSE, results=\'asis\', message=FALSE, warning=FALSE}\nplot_list=readRDS(file)\nknitr::kable(plot_list[%d], caption=\"Cutadapt Sample Statistics\")\n```", index)) %>% write_lines(rmd_file,append=T)
index=index+1
c(sprintf("```{r echo=FALSE, message=FALSE, warning=FALSE}\nplot_list=readRDS(file)\nknitr::kable(plot_list[%d], caption=\"Sample Median Reads per Pool\")\n```", index)) %>% write_lines(rmd_file,append=T)
index=index+1
c(sprintf("```{r echo=FALSE, message=FALSE, warning=FALSE}\nplot_list=readRDS(file)\nknitr::kable(plot_list[%d], caption=\"Sample Number of Loci with 100 Reads or More per Pool\")\n```", index)) %>% write_lines(rmd_file,append=T)
index=index+1
c(sprintf("```{r echo=FALSE, message=FALSE, warning=FALSE}\nplot_list[-c(1:%d)]\n```", index)) %>% write_lines(rmd_file,append=T)
rmarkdown::render(rmd_file, params = list(file=file, output_file = html_document()))
