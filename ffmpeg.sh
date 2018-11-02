#!/bin/bash -x

JSONOUT=/tmp/out
TRANSCODELIST=/tmp/tcodelist

INDIR=$1
OUTDIR=$2

function checkcrop 
{
	FILE=$1
	export crop=`ffmpeg -ss 200 -i $FILE -t 10 -vf cropdetect -f null - 2>&1 | awk '/crop/ { print $NF }' | tail -1`
	echo $crop
}

function numstreams
{
	jq '.[] | length' ${JSONOUT}
}

function codec
{
	jq '.[] | .[0].codec_name' ${JSONOUT}
}

function dumpjson
{
	VIDINFILE=$1
	ffprobe -print_format json -show_streams ${VIDINFILE} 2>&1 >${JSONOUT}
}

function SelectAudioStream
{
	echo "selected"
}

#function figureaudio
#{
	# If DTS-MA add it to map and track list
	# if
#	NUMSTREAMS=numstreams()
#	for stream in [ 1 .. ${NUMSTREAMS} ; do
#		if 
#	done
#}

if [ -e $TRANSCODELIST ]; then
	rm $TRANSCODELIST
fi
find ${INDIR} -iname \*.mkv >> $TRANSCODELIST

cat ${TRANSCODELIST} | while read INFILE ; do
	dumpjson ${INFILE}
	OUTFILE=${OUTDIR}/${INFILE##*/}
	echo "Writing to $OUTFILE"

	CROP=`ffmpeg -ss 200 -i ${INFILE} -t 10 -vf cropdetect -f null - 2>&1 | awk '/crop/ { print $NF }' | tail -1`
	# -y = Force overwirite of output
	# -vf crop=1920:800:0:140 / auto trims movie
	# CHILUK: SEE ffmpeg -h decoder=h264_cuvid | grep -crop and fix CROP arg
	echo ${INFILE}

		# -hwaccel cuvid \
		# -c:v h264_cuvid \
	ffmpeg -y -nostdin \
		-i ${INFILE} \
		-vf ${CROP} \
		-map 0:v:0 -map 0:a -map 0:s \
		-c:v hevc_nvenc -preset slow -rc vbr_hq -level 5.1 \
		-c:a copy \
		-c:s copy \
		${OUTFILE} > /tmp/ffmpeg.out 2> /tmp/ffmpeg.err

	exit
done
