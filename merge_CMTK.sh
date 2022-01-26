#!/bin/bash
#
# 20x 40x brain aligner by Hideo Otsuna
#

export CMTK_WRITE_UNCOMPRESSED=1

InputFilePath1=$1
InputFilePath2=$2
NSLOTS=$3
OUTPUT=$4

end=${InputFilePath1##*/}
num1=$((${#InputFilePath1} - ${#end}))

OUTPUTNAME=${InputFilePath#*/}
OUTPUTNAME=${OUTPUTNAME#*/}
OUTPUTNAME=${OUTPUTNAME#*/}
OUTPUTNAME=${OUTPUTNAME#*/}
OUTPUTNAME=${OUTPUTNAME#*/}
OUTPUTNAME=${OUTPUTNAME#*/}
OUTPUTNAME=${OUTPUTNAME#*/}
OUTPUTNAME=${OUTPUTNAME#*/}
OUTPUTNAME=${OUTPUTNAME#*/}
OUTPUTNAME=${OUTPUTNAME#*/}
OUTPUTNAME=${OUTPUTNAME#*/}
OUTPUTNAME=${OUTPUTNAME#*/}
OUTPUTNAME=${OUTPUTNAME#*/}
OUTPUTNAME=${OUTPUTNAME#*/}


WORK_DIRPRE=${InputFilePath1:0:num1-1}
WORK_DIR=${WORK_DIRPRE}"/"${OUTPUTNAME%.*}

mkdir ${WORK_DIR}
FINALOUTPUT=${WORK_DIRPRE}"/"${OUTPUTNAME%.*}

filename=${OUTPUTNAME%.*}

echo "filename; "$filename
echo "InputFilePath1; "$InputFilePath1
echo "WORK_DIR; "$WORK_DIR
echo "OUTPUTNAME; "$OUTPUTNAME

test=0

if [[ $test == 1 ]]; then
    LSF=0
    MBP=1

    if [  -f "/nrs/scicompsoft/otsuna/Macros/Fiji.appold/ImageJ-linux64" ]; then 
        LSF=1
        CMTK=/nrs/scicompsoft/otsuna/CMTK_new2019
        MACRO_DIR=/nrs/scicompsoft/otsuna/Macros/Merge
        FIJI="/nrs/scicompsoft/otsuna/Macros/Fiji.appold/ImageJ-linux64"
        MBP=0
    fi

    if [[ $MBP == 1 ]]; then
        CMTK=/Applications/Fiji.app/bin/cmtk
        FIJI=/Applications/Fiji_copy.app/Contents/MacOS/ImageJ-macosx
        MACRO_DIR=/Users/otsunah/test/merge_test
    fi

else

# Tools
    CMTK=/opt/CMTK/bin
    FIJI=/opt/Fiji/ImageJ-linux64
    Vaa3D=/opt/Vaa3D/vaa3d
    MACRO_DIR=/opt/aligner/fiji_macros

    OUTPUT=$WORK_DIR"/Output"
    FINALOUTPUT=$WORK_DIR"/FinalOutputs"
    DEBUG_DIR="${OUTPUT}/debug"

    mkdir -p $DEBUG_DIR
fi


# Fiji macros
MERGE1=$MACRO_DIR"/merge_split.ijm"
MERGE2=$MACRO_DIR"/merge_combine.ijm"
SCOREGENERATION=$MACRO_DIR"/Score_Generator_Cluster.ijm"

if [[ ! -d $OUTPUT ]]; then
    mkdir $OUTPUT
fi

if [[ ! -d $FINALOUTPUT ]]; then
    mkdir $FINALOUTPUT
fi

if [[ ! -e $MERGE1 ]]; then
    echo "MERGE1 macro could not be found at $MERGE1"
    exit 1
fi

if [[ ! -e $MERGE2 ]]; then
    echo "MERGE2 macro could not be found at $MERGE2"
    exit 1
fi

if [[ ! -e $FIJI ]]; then
    echo "Fiji cannot be found at $FIJI"
    exit 1
fi

echo "NSLOTS; "$NSLOTS
echo "OUTPUT; "$OUTPUT

# "-------------------Global aligned files----------------------"
ch2_ref_nrrd=$OUTPUT"/C1-2ch.nrrd"
ch3_ref_nrrd=$OUTPUT"/C1-3ch.nrrd"

ch2_sig=$OUTPUT"/C2-2ch.nrrd"
ch2_transformed_sig=$OUTPUT"/C2-2ch_transformed.nrrd"
ch2_transformed_ref=$OUTPUT"/C1-2ch_transformed.nrrd"

ch3_sig1=$OUTPUT"/C2-3ch.nrrd"
ch3_sig2=$OUTPUT"/C3-3ch.nrrd"
mergedOUTPUT=$OUTPUT"/merged.v3draw"

echo "ch2_ref_nrrd "$ch2_ref_nrrd

# "-------------------Deformation fields----------------------"
registered_initial_xform=$OUTPUT"/initial.xform"
registered_affine_xform=$OUTPUT"/affine.xform"

# -------------------------------------------------------------------------------------------


# Alignment score generation
function scoreGen() {
	local _outname="$1"
	local _scoretemp="$2"
	local _result_var="$3"
	
	tempfilename=`basename $_scoretemp`
	tempname=${tempfilename%%.*}
	scorepath="$OUTPUT/${tempname}_Score.property"
	
	if [[ -e $scorepath ]]; then
	echo "Already exists: $scorepath"
	else
	echo "+---------------------------------------------------------------------------------------+"
	echo "| Running Score generation"
	echo "| $FIJI --headless -macro $SCOREGENERATION $OUTPUT/,$_outname,$NSLOTS,$_scoretemp"
	echo "+---------------------------------------------------------------------------------------+"
	
	START=`date '+%F %T'`
	# Expect to take far less than 1 hour
	# Alignment Score generation:ZNCC, does not need Xvfb
	
	if [[ $test == 0 ]]; then
	  $FIJI --headless -macro $SCOREGENERATION $OUTPUT"/",$_outname,$NSLOTS,$_scoretemp >$DEBUG_DIR/scoregen.log 2>&1
	else
	  $FIJI --headless -macro $SCOREGENERATION $OUTPUT"/",$_outname,$NSLOTS,$_scoretemp
	fi
	
	STOP=`date '+%F %T'`
	
	echo "ZNCC JRC2018 score generation start: $START"
	echo "ZNCC JRC2018 score generation stop: $STOP"
	fi
	
	score=`cat $scorepath`
	eval $_result_var="'$score'"
}

# Expect to take far less than 10 min
#timeout --preserve-status 6000m 

if [[ -e ${ch2_ref_nrrd} ]]; then
    echo "Already channels are splited"
else
    echo "+---------------------------------------------------------------------------------------+"
    echo "| Running $MERGE1_1"
    echo "| $FIJI -macro $MERGE1 \"$InputFilePath1,${OUTPUT}.\""
    echo "+---------------------------------------------------------------------------------------+"
    START=`date '+%F %T'`
# Expect to take far less than 1 hour
#timeout --preserve-status 6000m 

    $FIJI --headless -macro $MERGE1 "$InputFilePath1,${OUTPUT}" #>$DEBUG_DIR/preproc.log 2>&1

    STOP=`date '+%F %T'`
    echo "channel split1 start: $START"
    echo "channel split1 stop: $STOP"
    if [[ ${DEBUG_MODE} =~ "debug" ]]; then
        echo "~ Preprocessing output"
        cat $DEBUG_DIR/preproc.log
    fi

    echo "+---------------------------------------------------------------------------------------+"
    echo "| Running $MERGE1_2"
    echo "| $FIJI -macro $MERGE1 \"$InputFilePath2,${OUTPUT}.\""
    echo "+---------------------------------------------------------------------------------------+"
    START=`date '+%F %T'`

    $FIJI --headless -macro $MERGE1 "$InputFilePath2,${OUTPUT}" #>$DEBUG_DIR/preproc.log 2>&1

    STOP=`date '+%F %T'`
    echo "channel split1 start: $START"
    echo "channel split1 stop: $STOP"
    if [[ ${DEBUG_MODE} =~ "debug" ]]; then
        echo "~ Preprocessing output"
        cat $DEBUG_DIR/preproc.log
    fi
fi

# -------------------------------------------------------------------------------------------
if [[ -e ${registered_affine_xform} ]]; then
    echo "Already exists: $registered_affine_xform"
else
    echo " "
    echo "+----------------------------------------------------------------------+"
    echo "| Running CMTK registration"
    echo "| $CMTK/registration --threads $NSLOTS -i -v --dofs 6 --dofs 9 --accuracy 0.8 -o ${registered_affine_xform} ${ch3_ref_nrrd} ${ch2_ref_nrrd} "
    echo "+----------------------------------------------------------------------+"
    START=`date '+%F %T'`
    $CMTK/registration --threads $NSLOTS -i -v --dofs 6 --dofs 9 --accuracy 0.8 -o ${registered_affine_xform} ${ch3_ref_nrrd} ${ch2_ref_nrrd}
    STOP=`date '+%F %T'`
    if [[ ! -e $registered_affine_xform ]]; then
        echo -e "Error: CMTK registration failed"
        exit -1
    fi
    echo "cmtk_registration start: $START"
    echo "cmtk_registration stop: $STOP"

    TEMP=${ch3_ref_nrrd}
    gsig=${ch2_sig}

    $CMTK/reformatx -o "${ch2_transformed_sig}" --floating $gsig $TEMP ${registered_affine_xform}

    echo "ch2-nc82 transformation export"
    export CMTK_WRITE_UNCOMPRESSED=1
    $CMTK/reformatx -o ${ch2_transformed_ref} --floating ${ch2_ref_nrrd} ${ch3_ref_nrrd} ${registered_affine_xform}

fi


scoreGen ${ch2_transformed_ref} ${ch3_ref_nrrd} "Merged_score"

$FIJI --headless -macro ${MERGE2} $OUTPUT"/",${mergedOUTPUT}

#rm $ch2_ref_nrrd
#rm $ch3_ref_nrrd
#rm $ch2_sig
#rm $ch3_sig1
#rm $ch3_sig2
#rm $ch2_transformed_sig
#rm $ch2_transformed_ref

if [[ $test == 0 ]]; then
cp $OUTPUT/*.{png,jpg,log,txt} $DEBUG_DIR
cp -R $OUTPUT/*.xform $DEBUG_DIR

fi
echo "$0 done"
exit 0