#!/bin/bash

# Copyright 2012  Vassil Panayotov
#           2014  Johns Hopkins University (author: Daniel Povey)
#           2016  Cristina Espana-Bonet
#           2018  Idiap Research Institute (author: Enno Hermann)
# Apache 2.0

# Converts the data into Kaldi's format and makes train/test splits

# source path.sh

echo ""
echo "=== Starting Cut Torgo data to align between array and head mic ..."
echo ""

. utils/parse_options.sh

# read dataset paths
dataset=$1
dataset_cut=$2

if [ -f $dataset_cut/.done ]; then
    echo "aligned files have already prepared."
    exit 0
fi

rm -rf $dataset_cut

# Utterances to discard
bad_utts=conf/bad_utts
to_cut=conf/to_cut
rm -f $bad_utts $to_cut

pip install soundfile

# Look for the necessary information in the original data
echo "--- Looking into the original data ..."
num_users=0
num_sessions=0
num_no_prompts=0

echo "--- enter $dataset"

for speaker in $dataset/* ; do
    spk=$(basename $speaker)
    global=false  #all the information in any session of a user
    for waves in $speaker/Session*/wav_array* ; do
        info=false  #all the information within a session
        if  [ -d "$waves" ] ; then
            acoustics=true
            transcript="${waves/wav_*Mic/prompts}"
            if  [ -d "$transcript" ] ; then
                transcriptions=true
                info=true
	            global=true
            else
                echo "$waves no prompts"
                ((num_no_prompts++))
            fi
        fi
        if [ "$info" = true ] ; then
            train_sessions[$num_sessions]="$waves"
            ((num_sessions++))
        fi
    done
done

# prepare conf to alignment
for waves in ${train_sessions[@]} ; do
    # get the nomenclature
    session=$(dirname $waves)        
    ssn=$(basename $session)
    tmp=${session#*$dataset/}
    spk=${tmp%/Sess*}
    mic=${waves#*wav_}
    echo "  $spk $ssn $mic"
    gender=${spk:0:1}
    gender=${gender,,}
    cut_folder=$dataset_cut/$spk/$ssn

    mkdir -p $cut_folder/wav_headMic
    mkdir -p $cut_folder/wav_arrayMic
    mkdir -p $cut_folder/prompts

    for doc in $session/prompts/* ; do
        line=$(cat $doc)
        utt="${doc%.txt}"
        utt=$(basename $utt)
        id="$spk-$ssn-$mic-$utt"
        # The dataset has incomplete transcriptions. Till solved we remove
        # transcriptions with comments.
        if [[ $line == *'['*']'* ]] ; then
            echo "$id # includes comments" >> $bad_utts
            continue
        fi
        # Ignore utterances transcribed 'xxx' (discarded recordings).
        if [[ $line == *'xxx'* ]] ; then
            echo "$id # bad utterances ('xxx')" >> $bad_utts
            continue
        fi
        #  Remove transcriptions that are paths to files where descriptions
        #  should be included.
        if [[ $line == *'input/images'* ]] ; then
            echo "$id # untranscribed image description" >> $bad_utts
	        continue
        fi
        # Remove wav only has single view
        if [[ -f $session/wav_head*/$utt.wav ]]; then
            echo "id # wav in array not in head" >> $bad_utts
        fi

        line="$id ${line^^}"
        array_wav="$waves/$utt.wav"
        head_wav="$session/wav_headMic/$utt.wav"
        alitxt="$session/alignment.txt"
        if [ -f $array_wav ] && [ -f $head_wav ] ; then  # Only files with all the associated info are written
            left=$(head -n 1 $alitxt | awk -F\\ '{print $3}')
            if [ $left = "wav_arrayMic" ]; then
                shift_time=$(cat $alitxt | grep $utt.wav | awk '{print int($2)}')
            else
                z=0
                shift_time=$[$z-$(cat $alitxt | grep $utt.wav | awk '{print int($2)}')]
            fi
            cp $session/prompts/$utt.txt $cut_folder/prompts/$utt.txt
            array_wav_cut=$cut_folder/wav_arrayMic/$utt.wav
            head_wav_cut=$cut_folder/wav_headMic/$utt.wav
            # echo "aligning $array_wav $shift_time"
            echo "$array_wav $shift_time $array_wav_cut" >> $to_cut
            (python local/align_wav.py $array_wav $head_wav $shift_time $array_wav_cut $head_wav_cut || exit 1) &
        fi
    done
done
wait

echo "done" >> $dataset_cut/.done