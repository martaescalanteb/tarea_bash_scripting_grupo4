args_script <- commandArgs(trailingOnly = T)
res_dir <- as.character(args_script[[1]])
print(res_dir)
ins_dir <- as.character(args_script[[2]])
print(ins_dir)



cat("EXECUTING R SCRIPT")

#Descargamos los paquetes necesarios

library(ChIPseeker) 

library(TxDb.Athaliana.BioMart.plantsmart28) 

txdb <- TxDb.Athaliana.BioMart.plantsmart28 



## Leer fichero de picos
prr5.peaks <- readPeakFile(peakfile = "intersected.narrowPeak",header=FALSE)

## Definir la región promotora entorno al TSS
promoter <- getPromoters(TxDb=txdb,
                         upstream=1000,
                         downstream=1000)

## Asociación  de los picos a genes
prr5.peakAnno <- annotatePeak(peak = prr5.peaks,
                              tssRegion=c(-1000, 1000),
                              TxDb=txdb)

##Pie plot
pdf("cistrome_pieplot.pdf")
plotAnnoPie(prr5.peakAnno)
dev.off()

##Bar plot
pdf("cistrome_barplot.pdf")
plotAnnoBar(prr5.peakAnno)
dev.off()

##Plot de distancia al TSS Transcription Start Site

pdf("cistrome_disttotss.pdf")
plotDistToTSS(prr5.peakAnno,
              title="Distribution of genomic loci relative to TSS",
              ylab = "Genomic Loci (%) (5' -> 3')")
dev.off()


#Determinación del reguloma

## Convertir la anotación a data frame
prr5.annotation <- as.data.frame(prr5.peakAnno)
head(prr5.annotation)

##Extracción de los genes cuyos FT quedan unidos a promotores
target.genes <- prr5.annotation$geneId[prr5.annotation$annotation == "Promoter"]

write(x = target.genes,file = "prr5_target_genes.txt")



# Análisis de enriquecimiento funcional. 
library(clusterProfiler)

library(org.At.tair.db)

library(enrichplot)

prr5.enrich.go <- enrichGO(gene = target.genes,
                           OrgDb         = org.At.tair.db,
                           ont           = "BP",
                           pAdjustMethod = "BH",
                           pvalueCutoff  = 0.05,
                           readable      = FALSE,
                           keyType = "TAIR")

#Representaciones gráficos

pdf("GO_bar.pdf")
barplot(prr5.enrich.go,showCategory = 20)
dev.off()

pdf("GO_dot.pdf")
dotplot(prr5.enrich.go,showCategory = 20)
dev.off()

#Se representan los procesos biologicos enriquecidos y ademas los genes involucrados.

pdf("GO_emapplot.pdf")
emapplot(pairwise_termsim(prr5.enrich.go),showCategory = 20, cex_label_category=0.5)
dev.off()

#Diagrama de red
pdf("GO_cnetplot.pdf")
cnetplot(prr5.enrich.go,showCategory = 20, cex_label_category=0.5, cex_label_gene=0.5)
dev.off()

##Análisis de enriquecimiento metabólico (KEGG):

enrich.kegg <- enrichKEGG(gene = target.genes,organism = "ath",pAdjustMethod = "BH",pvalueCutoff = 0.05)

## Conversión de resultados a data frame:

df.enrich.kegg <- as.data.frame(enrich.kegg)
head(df.enrich.kegg)

## Exportar resultados a fichero CSV:

write.table(df.enrich.kegg,"enrich.kegg.csv")

