#! /bin/bash
#SCRATCH=ALL

CHIPDIR=$1
i=$2
INSDIR=$3
WD=$4
EXP=$5
NUMTOTAL=$6
NUMINPUT=$7
NUMCHIP=$8
TF=$9


echo ""
echo "==================="
echo "PROCESANDO CHIP $i"
echo "==================="
echo ""

cd $CHIPDIR
ls $CHIPDIR

if [ ! -e "$CHIPDIR/chip_$i.fq.gz" ]
then
    echo "Error: El archivo chip_$i.fq.gz no existe en $CHIPDIR"
    exit 1
fi


echo ""
echo "====================================="
echo "ANALIZANDO LA CALIDAD Y MAPEANDO CHIP"
echo "====================================="
echo ""


# Para el procesado de las muestras hemos decidido utilizar un bucle for que recorre todos los archivos con la terminación fq.gz.
# Con la función grep extraemos el número del nombre del archivo y lo guardamos en una variable i, comprobamos que el numero de muestras se encuentra entre 0 y 9.
# Para cada una de esas muestras realizaremos el análisis de calidad con la función fastqc, haremos el mapeo con bowtie2 y generaremos los archivos .bam con samtools.

for archivo in $CHIPDIR/chip_*.fq.gz
do
    i=$(echo "$archivo" | grep -oP '(?<=chip_)\d+(?=\.fq\.gz)')

    if [[ $i =~ ^[0-9]+$ ]]; then
        echo "Procesando archivo: $archivo"
        echo "Número: $i"
        fastqc chip_$i.fq.gz
        bowtie2 -x ../../genome/index -U chip_$i.fq.gz -S chip_$i.sam
        samtools sort -o chip_$i.bam chip_$i.sam
        rm chip_$i.sam

        echo "Se ha procesado chip $i"

  echo ${CHIPDIR}/chip_$i.bam >> ../../results/peaklist.txt
	      NUMPROC=$(wc -l ../../results/peaklist.txt | awk '{print($1)}')
	echo "Número de líneas en peaklist.txt: $NUMPROC"
    else
        echo "No se pudo extraer un número válido del archivo: $archivo"
    fi
done



# Una vez procesadas todas las muestras la vamos a redirigir al script del peak_calling, siempre y cuando el NUMPROC, es decir, el número de lineas del peaklist, sea igual al doble del número total de muestras (chip + input), pues aparecen duplicadas en la peaklist.

if [ $NUMPROC -eq $((2 * $NUMTOTAL)) ]
then
        echo "Todas las muestras procesadas"
        cd ../..
	cd results
        sbatch --job-name=peak_calling --output=peak_output.txt --error=peak_error.txt $INSDIR/peak_calling.sh $WD/$EXP/results $INSDIR $CHIPDIR $WD/$EXP/samples/input $TF
fi
