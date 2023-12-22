#! /bin/bash
#SCRATCH=ALL

RESDIR=$1
INSDIR=$2
CHIPDIR=$3
INPUTDIR=$4
TF=$5


echo ""
echo "==============="
echo "MODELANDO PICOS"
echo "==============="
echo ""

echo "$TF"


for archivo in $CHIPDIR/chip_*.bam
do
    echo "Procesando archivo: $archivo"
    i=$(echo "$archivo" | grep -oP '(?<=chip_)\d+(?=\.bam)')
    echo "Número extraído: $i"
    if [[ $i =~ ^[0-9]+$ ]]
    then
       	echo "Procesando archivo: $i"
	if [ $TF = "TRUE" ]
        then
        	echo "Es un factor de transcripcion"
        	macs2 callpeak -t $CHIPDIR/chip_$i.bam -c $INPUTDIR/input_merged.bam -f BAM --outdir $RESDIR -n picos_[$i]
	else
		  echo "Es una marca epigenetica"
		macs2 callpeak -t $CHIPDIR/chip_$i.bam -c $INPUTDIR/input_merged.bam -f BAM --outdir $RESDIR -n picos_[$i] --nomodel
	fi
	echo "Se han generado picos $i" 
    else
        echo "No se pudo extraer un número válido del archivo: $archivo"
    fi
done

##Realizamos bucle for a cada muestra chip (las almacena en i usando la función grep) y esto va a generar los distintos archivos .callPeaks distinguiendo con bucles if si es un factor de transcripción o una marca epigenética, en cuyo caso añadimos
## --nomodel al final de la función macs2 callpeak, que indica que no se construya un modelo para el tamaño del fragmento de ADN . Lo tenemos implementado hasta para 9 muestras chip distintas pero esta cifra es modificable según el número de muestras que se estén usando. 



echo ""
echo "============================"
echo "INTERSECCIÓN ENTRE LOS PICOS"
echo "============================"
echo ""

for archivo in $RESDIR/picos_[$i]_peaks.narrowPeak
do

    i=$(echo "$archivo" | grep -oP '(?<=picos_\[)\d+(?=\]_peaks\.narrowPeak)')
    if [[ $i =~ ^[0-9]+$ ]]
    then
        if [ "$i" -ge 2 ]
        then
            echo "Número de archivos: $i"
            echo "El archivo es $archivo"
            bedtools intersect -a $RESDIR/picos_[1]_peaks.narrowPeak -b $archivo > intersected.narrowPeak
            if [ "$i" -gt 2 ]
	    then
                bedtools intersect -a intersected.narrowPeak -b $RESDIR/picos_[$i]_peaks.narrowPeak > temporal_intersected.narrowPeak
                mv temporal_intersected.narrowPeak intersected.narrowPeak
            fi
        else
            echo "No hay más de un archivo de picos presente en el directorio"
        fi
    else
        echo "No se pudo extraer un número válido del archivo: $archivo"
    fi
done

##Realizamos bucle for a cada uno de los peaks.narrowPeak para que nos haga la intersección en caso de que haya 2 o más muestras. Si hay 2, hacemos el bedtools normal.
##Si tenemos más de dos muestras, coge el archivo intersected.narrowPeak (de las dos primeras muestras) y lo coloca como el -a del nuevo bedtools.


echo ""
echo "====================================="
echo "LOS PICOS SE HAN CREADO CORRECTAMENTE"
echo "====================================="
echo ""


echo ""
echo "========================================================="
echo "ENRIQUECIMIENTO DE MOTIVOS DE UNIÓN A PROTEÍNAS POR HOMER"
echo "========================================================="
echo ""

findMotifsGenome.pl intersected.narrowPeak tair10 dnaMotifs -size 100 -len 8


#Realizamos un enriquecimiento de motivos de unión a proteínas mediante la herramienta HOMER.

echo ""
echo "====================="
echo "REDIRIGIMOS A RSTUDIO"
echo "====================="
echo ""


Rscript $INSDIR/chip.R $RESDIR $INSDIR $TF

#Redirigimos el script a Rstudio para continuar con el análisis.
