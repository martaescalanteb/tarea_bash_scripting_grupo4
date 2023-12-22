#! /bin/bash
#SCRATCH=ALL

INPUTDIR=$1
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
echo "PROCESANDO INPUT $I"
echo "==================="
echo ""

cd $INPUTDIR
ls inputdir

echo ""
echo "======================================"
echo "ANALIZANDO LA CALIDAD Y MAPEANDO INPUT"
echo "======================================"
echo ""


# Para el procesado de las muestras hemos decidido utilizar un bucle for que recorre todos los archivos con la terminación fq.gz.
# Con la función grep extraemos el número del nombre del archivo y lo guardamos en una variable i, comprobamos que el numero de muestras se encuentra entre 0 y 9.
# Para cada una de esas muestras realizaremos el análisis de calidad con la función fastqc, haremos el mapeo con bowtie2 y generaremos los archivos .bam con samtools.

for archivo in $INPUTDIR/input_*.fq.gz
do
    i=$(echo "$archivo" | grep -oP '(?<=input_)\d+(?=\.fq\.gz)')

    if [[ $i =~ ^[0-9]+$ ]]
    then
        echo "Procesando archivo: $archivo"
        echo "Número: $i"
        fastqc input_$i.fq.gz
        bowtie2 -x ../../genome/index -U input_$i.fq.gz -S input_$i.sam
        samtools sort -o input_$i.bam input_$i.sam
        rm input_$i.sam

	samtools index input_$i.bam

        echo "Se ha procesado input $i"

  echo ${INPUTDIR}/input_$i.bam >> ../../results/peaklist.txt
	      NUMPROC=$(wc -l ../../results/peaklist.txt | awk '{print($1)}')
    else
        echo "No se pudo extraer un número válido del archivo: $archivo"
    fi
done

echo ""
echo "==================="
echo "MERGE DE LOS INPUTS"
echo "==================="
echo ""

samtools merge input_merged.bam *.bam


# Una vez procesadas todas las muestras la vamos a redirigir al script del peak_calling, siempre y cuando el NUMPROC, es decir, el número de lineas del peaklist, sea igual al doble del número total de muestras (chip + input), pues aparecen duplicadas en la peaklist.

if [ $NUMPROC -eq $((2 * $NUMTOTAL)) ]
then
        echo "Todas las muestras procesadas"
        cd ../..
	cd results
        sbatch --job-name=peak_calling --output=peak_output.txt --error=peak_error.txt $INSDIR/peak_calling.sh $WD/$EXP/results $INSDIR $WD/$EXP/samples/chip $INPUTDIR $TF
fi
