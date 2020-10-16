#!/bin/bash

# Copyright 2012  Vassil Panayotov
#           2014  Johns Hopkins University (author: Daniel Povey)
#           2016  Cristina Espana-Bonet
#           2018  Idiap Research Institute (author: Enno Hermann)
# Apache 2.0

# Converts the data into Kaldi's format and makes train/test splits

source path.sh

echo ""
echo "=== Starting initial Torgo data preparation ..."
echo ""

. utils/parse_options.sh

# Utterances to discard
bad_utts=conf/bad_utts
to_cut=conf/to_cut
rm $bad_utts $to_cut

# Look for the necessary information in the original data
echo "--- Looking into the original data ..."
num_users=0
num_sessions=0
num_no_prompts=0
for speaker in $CORPUS/* ; do
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
    tmp=${session#*$OLD_CORPUS/}
    spk=${tmp%/Sess*}
    mic=${waves#*wav_}
    echo "  $spk $ssn $mic"
    gender=${spk:0:1}
    gender=${gender,,}
    for doc in $session/prompts/* ; do
        line=$(cat $doc)
        utt="${doc%.txt}"
        utt=$(basename $utt)
        id="$spk-$ssn-$mic-$utt"
        # The OLD_corpus has incomplete transcriptions. Till solved we remove
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
            shift_time=$(cat $alitxt | grep $utt.wav | awk '{print $2}')
            echo "$array_wav $head_wav $shift_time" >> $to_cut
        fi
    done
done
