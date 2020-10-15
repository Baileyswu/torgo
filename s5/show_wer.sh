#!/bin/bash

DYS_SPEAKERS="F01 F03 F04 M01 M02 M03 M04 M05"
CTL_SPEAKERS="FC01 FC02 FC03 MC01 MC02 MC03 MC04"
ALL_SPEAKERS="$DYS_SPEAKERS $CTL_SPEAKERS"

# Speakers to evaluate.
speakers=$ALL_SPEAKERS

mkdir -p res
for model_type in mono tri1 tri2 tri3 sgmm sgmm_mmi_b0.1; do 
    for wav_type in array head; do
    (   
        if [ $model_type == "sgmm_mmi_b0.1" ]; then
            for spk in $speakers; do
                pushd cexp/sgmm_mmi_b0.1/$wav_type/$spk
                ln -s decode_test_multi_it1 ./decode_test_multi
                ln -s decode_test_single_it1 ./decode_test_single
                popd
            done
        fi
        ./local/get_wer_consistence.py cexp/$model_type/$wav_type > res/wer-$model_type-$wav_type.log
    )&
    done
done