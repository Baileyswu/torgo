#!/bin/bash

# Copyright 2012  Vassil Panayotov
#           2016  Cristina Espana-Bonet
#           2018  Idiap Research Institute (Author: Enno Hermann)

# Apache 2.0

. ./cmd.sh
. ./path.sh

stage=0
train=true

DYS_SPEAKERS="F01 F03 F04 M01 M02 M03 M04 M05"
CTL_SPEAKERS="FC01 FC02 FC03 MC01 MC02 MC03 MC04"
ALL_SPEAKERS="$DYS_SPEAKERS $CTL_SPEAKERS"

# Speakers to evaluate.
speakers=$ALL_SPEAKERS

# Tests to run.
tests="test_single test_multi"

# Word position dependent phones?
pos_dep_phones=false

# Different (15ms) frame shift for dysarthric speakers?
different_frame_shift=true

# Number of leaves and total gaussians
leaves=1800
gaussians=9000

nj_decode=1

. utils/parse_options.sh

set -euo pipefail

datadir=cdata
split=csplit
exp=cexp
set -x
if [ $stage -le 0 ] && [ "$train" = true ] ; then
    for wav_type in array head; do
        for spk in $speakers; do
            (
            for z in dev test; do
                rm -rdf $exp/tri3_ali_$z/$wav_type/$spk
                mkdir -p $exp/tri3_ali_$z/$wav_type/$spk
                nj=$(cat $split/$wav_type/$spk/$z/spk2utt | wc -l)
                steps/align_fmllr.sh --nj $nj --cmd "$train_cmd" \
                                    $split/$wav_type/$spk/$z data/$spk/lang $exp/tri3/$wav_type/$spk \
                                    $exp/tri3_ali_$z/$wav_type/$spk >& $exp/tri3_ali_$z/$wav_type/$spk/align.log
            done
            )&
        done
    done
    wait;
fi