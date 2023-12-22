#! /bin/bash 


if [ $# -ne 1 ]
then
        echo "Number of arguments is: $#"
        echo "Usage chipipe.sh <params.file>"
        echo ""
        echo "params.file: Input file with arguments"
        echo "An example of params.file can be found in the test folder"
        exit
fi

PARAMS=$1

#Bucle if para verificar que sólo se le está dando al script un parámetro de entrada (como es el fichero params.txt).
#En caso afirmativo, se guardará el contenido del fichero en una variable ($1)


echo ""
echo "==================="
echo "CARGANDO PARÁMETROS"
echo "==================="
echo ""


#Lo siguiente es la descarga de los parámetros contenidos en el fichero anterior, guardando cada uno de ellos en una variable
#independiente. Para este paso se usan los comandos grep y awk.


WD=$(grep working_directory $PARAMS | awk '{print($2)}')
echo "Working directory $WD"

INSDIR=$(grep installation_directory  $PARAMS | awk '{print($2)}')
echo "Installation directory: $INSDIR"

EXP=$(grep experiment_name  $PARAMS | awk '{print($2)}')
echo "Experiment name: $EXP"

GENOME=$(grep path_genome $PARAMS | awk '{print($2)}')
echo "Genome path: $GENOME"

ANNOTATION=$(grep path_annotation $PARAMS | awk '{print($2)}')
echo "Annotation path: $ANNOTATION"

INPUT=$(grep path_input $PARAMS | awk '{print($2)}')
echo "Input path: $INPUT"

CHIP=$(grep path_chip $PARAMS | awk '{print($2)}')
echo "Chip path: $CHIP"

NUMINPUT=$(grep number_of_inputs $PARAMS | awk '{print($2)}')
echo "Number of inputs: $NUMINPUT"


NUMCHIP=$(grep number_of_chips $PARAMS | awk '{print($2)}')
echo "Number of chips: $NUMCHIP"


NUMTOTAL=$((NUMINPUT + NUMCHIP))
echo "Total number of inputs and samples is $NUMTOTAL"

TF=$(grep transcription_factor $PARAMS | awk '{print($2)}')
echo "TF: $TF"



echo ""
echo "==================="
echo "PARÁMETROS CARGADOS"
echo "==================="
echo ""


echo ""
echo "=========================="
echo "CREANDO ESPACIO DE TRABAJO"
echo "=========================="
echo ""

#Creamos es espacio de trabajo: se crearán las diferentes carpetas y subcarpetas necesarias para un análisis de datos de ChIP-seq.
#Además, se introducirán y descargarán los datos en sus respectivas carpetas.


cd $WD
mkdir -p $EXP
cd $EXP
mkdir -p genome annotation results samples scripts
cd samples
mkdir -p input

mkdir -p chip

cd ..
cp $GENOME genome/genome.fa
cp $ANNOTATION annotation/annotation.gtf



##ESTRATEGIA PARA QUE PUEDA LEER Y DESCARGARSE DISTINTAS MUESTRAS. Gracias a un bucle for, va a ir copiando en la carpeta chip archivos del directorio de origen (datos) que tengan la estructura *.fq.gz (siendo * cualquier valor numérico).
## Por ejemplo, chip_1.fq.gz. Si no tiene esta estructura, debe ser renombrado el archivo para que funcione correctamente.

cd samples/chip
patron=*.fq.gz
for muestra in "${CHIP[@]}"
do
  for archivo in "$muestra"/$patron
  do
    if [ -n "$archivo" ] &&  [ -e "$archivo" ]
    then
        nombre_muestra=$(basename "$archivo")
        cp "$archivo" .
        echo "Se ha copiado $nombre_muestra."
    else
        echo "Error: La ruta de archivo '$archivo' no es válida"
    fi
  done
done


#Básicamente, la estrategia consiste en la creación de un patrón que nos permita ir buscando las muestras en el directorio de
#origen. Este patrón se basa en la extensión .fq.gz que deben tener las muestras presentes. Lo siguiente es la ejecución de un bucle
#for para ir buscando el patrón asignado e ir copiando y guardando las muestras en el directorio de destino.


#Igual estrategia que la anterior pero para muestras input.

cd ../input
patron=*.fq.gz

for muestra in "${INPUT[@]}"
do
  for archivo in "$muestra"/$patron
  do
    if [ -n "$archivo" ] && [ -e "$archivo" ]
    then
        nombre_muestra=$(basename "$archivo")
        cp "$archivo" .
        echo "Se ha copiado $nombre_muestra."
    else
        echo "Error: la ruta de archivo '$archivo' no es válida"
    fi
  done
done



echo ""
echo "==========================="
echo "ESPACIO DE TRABAJO GENERADO"
echo "==========================="
echo ""


echo ""
echo "======================"
echo "CONSTRUYENDO EL ÍNDICE"
echo "======================"
echo ""

##Contruimos el índice del genoma

cd ../../genome
bowtie2-build genome.fa index

echo ""
echo "============="
echo "ÍNDICE CREADO"
echo "============="
echo ""

#Una vez construido el índice, se redirigen las muestras inputs y chips a los scripts input_proc.sh y chip_proc.sh,
#respectivamente, para realizar el procesamiento de las mismas

cd ..
for ((i=1;i <= $NUMINPUT; i++));
do
	sbatch --job-name=input_proc_$i --output=input_$i.txt --error=err_input_$i.txt $INSDIR/input_proc.sh $WD/$EXP/samples/input $i $INSDIR $WD $EXP $NUMTOTAL $NUMINPUT $NUMCHIP $TF
done

for((i=1; i <= $NUMCHIP; i++))
do
        sbatch --job-name=chip_proc_$i --output=chip_$i.txt --error=err_chip_$i.txt $INSDIR/chip_proc.sh $WD/$EXP/samples/chip $i $INSDIR $WD $EXP $NUMTOTAL $NUMINPUT $NUMCHIP $TF
done
